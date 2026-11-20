# 启动后端（后台运行，日志写到 logs\app.log）
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$jar  = Join-Path $root 'server\bounty-boot\target\bounty-app.jar'
$logDir = Join-Path $root 'logs'
New-Item -ItemType Directory -Force $logDir | Out-Null

if (-not (Test-Path $jar)) {
    Write-Host "找不到 $jar，请先执行：cd server && mvn -DskipTests package" -ForegroundColor Red
    exit 1
}

$running = Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue |
           Where-Object { $_.CommandLine -like '*bounty-app.jar*' }
if ($running) {
    Write-Host "后端已在运行（PID $($running.ProcessId)）" -ForegroundColor Yellow
    exit 0
}

Start-Process -FilePath 'java' `
    -ArgumentList @('-jar', "`"$jar`"", '--spring.profiles.active=local') `
    -WorkingDirectory $root `
    -RedirectStandardOutput (Join-Path $logDir 'app.log') `
    -RedirectStandardError  (Join-Path $logDir 'app.err') `
    -WindowStyle Hidden

Write-Host "后端已启动，日志：logs\app.log" -ForegroundColor Green
Write-Host "查看日志：Get-Content logs\app.log -Wait -Tail 30" -ForegroundColor DarkGray
