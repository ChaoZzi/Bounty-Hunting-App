# 停止后端（只杀 bounty-app.jar 那个 java 进程，不影响 IDEA 等其他 Java 程序）
$procs = Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue |
         Where-Object { $_.CommandLine -like '*bounty-app.jar*' }

if (-not $procs) {
    Write-Host "后端没有在运行" -ForegroundColor DarkGray
    exit 0
}

foreach ($p in $procs) {
    try {
        Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop
        Write-Host "已停止 PID $($p.ProcessId)" -ForegroundColor Green
    } catch {
        Write-Host "停止失败：$($_.Exception.Message)" -ForegroundColor Red
    }
}
