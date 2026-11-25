param(
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Write-Step($msg) {
    if (-not $Silent) { Write-Host $msg -ForegroundColor Cyan }
}

function Test-Port($port) {
    try {
        $c = New-Object Net.Sockets.TcpClient
        $c.Connect('127.0.0.1', $port)
        $c.Close()
        return $true
    } catch { return $false }
}

function Wait-Port($port, $timeoutSec = 180) {
    for ($i = 0; $i -lt [int]($timeoutSec / 3); $i++) {
        if (Test-Port $port) { return $true }
        Start-Sleep -Seconds 3
    }
    return $false
}

function Wait-Docker {
    docker info *> $null
    if ($LASTEXITCODE -eq 0) { return $true }

    Write-Step "      Docker 未运行，正在启动 Docker Desktop ..."
    $exe = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
    if (-not (Test-Path $exe)) {
        Write-Host "找不到 Docker Desktop：$exe" -ForegroundColor Red
        return $false
    }
    Start-Process $exe
    for ($i = 0; $i -lt 36; $i++) {
        Start-Sleep -Seconds 5
        docker info *> $null
        if ($LASTEXITCODE -eq 0) { return $true }
    }
    Write-Host "Docker 启动超时，请手动打开 Docker Desktop 后重试。" -ForegroundColor Red
    return $false
}

# ---------------- 开始 ----------------

if (-not $Silent) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    Write-Host "   悬赏平台 - 本地服务启动" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor DarkGray
    Write-Host ""
}

# --- [1/4] 数据库：优先本机原生 PostgreSQL，其次 Docker ---
$pgService = Get-Service -Name 'postgresql*' -ErrorAction SilentlyContinue | Select-Object -First 1

if ($pgService) {
    Write-Step "[1/4] 本机 PostgreSQL 服务（$($pgService.Name)）..."
    if ($pgService.Status -ne 'Running') {
        Write-Step "      服务未运行，尝试启动 ..."
        Start-Service $pgService.Name -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        (Get-Service $pgService.Name).Refresh()
        if ((Get-Service $pgService.Name).Status -ne 'Running') {
            Write-Host "无法启动 $($pgService.Name)，请以管理员身份运行本脚本，或在「服务」里手动启动。" -ForegroundColor Red
            if (-not $Silent) { Read-Host "按回车退出" }
            exit 1
        }
    }
} else {
    Write-Step "[1/4] 未发现本机 PostgreSQL 服务，改用 Docker 容器 ..."
    if (-not (Wait-Docker)) { if (-not $Silent) { Read-Host "按回车退出" }; exit 1 }
    docker compose up -d | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "容器启动失败，请检查 docker compose 输出。" -ForegroundColor Red
        if (-not $Silent) { Read-Host "按回车退出" }
        exit 1
    }
    Write-Host "      注意：容器版 PostgreSQL 映射在 5433，" -ForegroundColor Yellow
    Write-Host "            application-local.yml 的 url 端口要改成 5433。" -ForegroundColor Yellow
}

# --- [2/4] 等 PostgreSQL 端口就绪 ---
Write-Step "[2/4] 等待 PostgreSQL 就绪 ..."
$pgPort = if ($pgService) { 5432 } else { 5433 }
if (Wait-Port $pgPort) {
    Write-Step "      PostgreSQL 已就绪（$pgPort）"
} else {
    Write-Host "PostgreSQL 启动超时（端口 $pgPort 未监听）。" -ForegroundColor Red
    if (-not $Silent) { Read-Host "按回车退出" }
    exit 1
}

# --- [3/4] Redis：没监听就用 Docker 起 bounty-redis ---
# 注意：Redis 和 PostgreSQL 是两条独立的路。
# 本机装了 PostgreSQL 时上面会跳过 docker compose，所以 Redis 必须在这里单独保证，
# 否则登录、验证码、Token 全部会报「服务开小差了」。
Write-Step "[3/4] 检查 Redis ..."
if (Wait-Port 6380 3) {
    Write-Step "      Redis 已就绪（6380）"
} else {
    Write-Step "      Redis 未运行，尝试用 Docker 启动 bounty-redis ..."
    if (Wait-Docker) {
        docker compose up -d redis | Out-Null
        if (Wait-Port 6380 30) {
            Write-Step "      Redis 已就绪（6380）"
        } else {
            Write-Host "      Redis 启动失败：登录/验证码/Token 会报「服务开小差了」。" -ForegroundColor Red
            Write-Host "      排查：docker compose logs redis" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "      Docker 不可用，且本机没有 Redis。登录会失败。" -ForegroundColor Red
    }
}

# --- [4/4] 启动后端 ---
Write-Step "[4/4] 启动后端 ..."
& "$PSScriptRoot\start-backend.ps1"

# 等后端起来
if (-not $Silent) {
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Seconds 2
        try {
            $h = Invoke-RestMethod 'http://127.0.0.1:8080/api/v1/health' -TimeoutSec 3
            if ($h.data.db -eq 'up') { Write-Host "      后端已就绪，数据库连接正常" -ForegroundColor Green; break }
        } catch { }
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    Write-Host "   访问地址" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor DarkGray
    Write-Host "   健康检查   http://127.0.0.1:8080/api/v1/health" -ForegroundColor White
    Write-Host "   管理后台   http://127.0.0.1:5173  （先 cd admin 再 npm run dev）" -ForegroundColor White
    Write-Host ""
    Write-Host "   手机访问（必须连同一个 WiFi）：" -ForegroundColor White
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -like '192.168.*' -or $_.IPAddress -like '10.*' } |
        ForEach-Object { Write-Host "      http://$($_.IPAddress):8080" -ForegroundColor Green }

    Write-Host ""
    Write-Host "   后端日志：logs\app.log" -ForegroundColor DarkGray
    Write-Host "   停止服务：stop.bat" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "按回车退出"
}
