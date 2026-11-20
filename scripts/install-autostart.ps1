# 注册开机自启：登录 Windows 后自动拉起 Docker 与悬赏平台服务
# 用法：右键「使用 PowerShell 运行」

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$bat  = Join-Path $root 'start-silent.bat'

if (-not (Test-Path $bat)) {
    Write-Host "找不到 $bat" -ForegroundColor Red
    exit 1
}

$taskName = 'BountyAppServer'

$action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument "/c `"$bat`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName $taskName `
    -Action $action -Trigger $trigger -Settings $settings `
    -Description '登录后自动启动悬赏平台本地服务（Docker + MySQL + Redis + 后端）' `
    -Force | Out-Null

Write-Host "已注册计划任务：$taskName" -ForegroundColor Green
Write-Host "下次登录 Windows 会自动启动服务。" -ForegroundColor Green
Write-Host ""
Write-Host "取消自启：" -ForegroundColor Yellow
Write-Host "  Unregister-ScheduledTask -TaskName $taskName -Confirm:`$false"
