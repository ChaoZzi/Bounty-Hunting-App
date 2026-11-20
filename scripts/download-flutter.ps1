# 并行分段下载 Flutter SDK（单线程被限速到 100KB/s，改 8 线程分段）
$ErrorActionPreference = 'Continue'

$url = 'https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.50.0-stable.zip'
$dst = 'D:\dev\flutter.zip'
$tmp = 'D:\dev\fparts'
$n   = 8

New-Item -ItemType Directory -Force $tmp | Out-Null
Get-ChildItem $tmp -File -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Output "读取文件大小..."
$head = & curl.exe -sIL --max-time 60 $url
$lenLine = ($head | Select-String -Pattern '^content-length:\s*(\d+)' | Select-Object -Last 1)
if (-not $lenLine) { Write-Output "拿不到 Content-Length"; exit 1 }
$len = [int64]$lenLine.Matches[0].Groups[1].Value
Write-Output ("总大小 {0:N0} MB" -f ($len / 1MB))

$chunk = [int64][math]::Ceiling($len / $n)
$procs = @()
for ($i = 0; $i -lt $n; $i++) {
    $start = $i * $chunk
    $end   = [math]::Min($start + $chunk - 1, $len - 1)
    $out   = Join-Path $tmp ("part{0:D2}" -f $i)
    $curlArgs = @('-s', '--fail', '--retry', '20', '--retry-delay', '3',
                  '-r', "$start-$end", '-o', $out, $url)
    $procs += Start-Process -FilePath 'curl.exe' -ArgumentList $curlArgs -PassThru -NoNewWindow
    Write-Output ("启动分片 {0}: {1}-{2}" -f $i, $start, $end)
}

$sw = [Diagnostics.Stopwatch]::StartNew()
while (($procs | Where-Object { -not $_.HasExited }).Count -gt 0) {
    Start-Sleep -Seconds 15
    $done = (Get-ChildItem $tmp -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $el = [math]::Max($sw.Elapsed.TotalSeconds, 1)
    Write-Output ("  已下载 {0:N0} / {1:N0} MB  ({2:N2} MB/s)" -f ($done/1MB), ($len/1MB), (($done/1MB)/$el))
}

Start-Sleep -Seconds 2
$parts = Get-ChildItem $tmp -File | Sort-Object Name
$total = ($parts | Measure-Object Length -Sum).Sum
Write-Output ("分片合计 {0:N0} MB / 期望 {1:N0} MB" -f ($total/1MB), ($len/1MB))
if ($total -ne $len) {
    Write-Output "分片大小不符，停止"
    exit 1
}

Write-Output "合并分片..."
$quoted = ($parts | ForEach-Object { '"' + $_.FullName + '"' }) -join '+'
$cmdLine = "copy /b $quoted `"$dst`""
& cmd.exe /c $cmdLine | Out-Null

if (-not (Test-Path $dst) -or (Get-Item $dst).Length -ne $len) {
    Write-Output "copy 合并结果不符，改用 .NET 流合并"
    $out = [IO.File]::Create($dst)
    foreach ($p in $parts) {
        $in = [IO.File]::OpenRead($p.FullName)
        $in.CopyTo($out)
        $in.Close()
    }
    $out.Close()
}

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Output ("合并完成 {0:N0} MB" -f ((Get-Item $dst).Length/1MB))
