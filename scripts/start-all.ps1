param(
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Write-Step($msg) {
    if (-not $Silent) { Write-Host $msg -ForegroundColor Cyan }
}

function Wait-Docker {
    docker info *> $null
    if ($LASTEXITCODE -eq 0) { return $true }

    Write-Step "[1/4] Docker 未运行，正在启动 Docker Desktop ..."
    $exe = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
    if (-not (Test-Path $exe)) {
        Write-Host "找不到 Docker Desktop：$exe" -ForegroundColor Red
        return $false
    }
    Start-Process $exe
    for ($i = 0; $i -lt 36; $i++) {
        Start-Sleep -Seconds 5
        docker info *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Step "      Docker 已就绪（$((($i + 1) * 5)) 秒）"
            return $true
        }
    }
    Write-Host "Docker 启动超时，请手动打开 Docker Desktop 后重试。" -ForegroundColor Red
    return $false
}

function Wait-MySql {
    for ($i = 0; $i -lt 60; $i++) {
        $status = (docker inspect --format '{{.State.Health.Status}}' bounty-mysql 2>$null)
        if ($status -eq 'healthy') { return $true }
        Start-Sleep -Seconds 3
    }
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

Write-Step "[1/4] 检查 Docker ..."
if (-not (Wait-Docker)) { if (-not $Silent) { Read-Host "按回车退出" }; exit 1 }

Write-Step "[2/4] 启动数据库容器（mysql / redis）..."
docker compose up -d | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "容器启动失败，请检查 docker compose 输出。" -ForegroundColor Red
    if (-not $Silent) { Read-Host "按回车退出" }
    exit 1
}

Write-Step "[3/4] 等待 MySQL 就绪 ..."
if (Wait-MySql) {
    Write-Step "      MySQL 已就绪"
} else {
    Write-Host "MySQL 启动超时，可以看日志：docker compose logs mysql" -ForegroundColor Yellow
}

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
