$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host ""
Write-Host "正在停止悬赏平台 ..." -ForegroundColor Cyan

& "$PSScriptRoot\stop-backend.ps1"

docker compose down | Out-Null
Write-Host "容器已停止" -ForegroundColor Green
Write-Host ""
Write-Host "已全部停止。" -ForegroundColor Green
Start-Sleep -Seconds 2
