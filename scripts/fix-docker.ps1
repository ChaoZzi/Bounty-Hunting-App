# 修复 Docker Desktop：启动它的 Windows 服务
# 需要管理员权限：右键本文件 → 「使用 PowerShell 运行」可能仍不够，
# 请用：开始菜单搜索 PowerShell → 右键「以管理员身份运行」→ 执行下面两行。

$ErrorActionPreference = 'Continue'

Write-Host "1) 启动 Docker Desktop Service ..." -ForegroundColor Cyan
try {
    Start-Service com.docker.service -ErrorAction Stop
    Write-Host "   已启动" -ForegroundColor Green
} catch {
    Write-Host "   失败：$($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   请确认本窗口是以管理员身份运行的。" -ForegroundColor Yellow
}

Write-Host "2) 启动 Docker Desktop ..." -ForegroundColor Cyan
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

Write-Host "3) 等待引擎就绪（最多 3 分钟）..." -ForegroundColor Cyan
for ($i = 0; $i -lt 36; $i++) {
    Start-Sleep -Seconds 5
    docker info *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Docker 已就绪" -ForegroundColor Green
        break
    }
}

docker info --format 'ServerVersion={{.ServerVersion}}' 2>&1

Write-Host ""
Write-Host "完成后回到项目目录双击 start.bat 即可。" -ForegroundColor Cyan
Read-Host "按回车退出"
