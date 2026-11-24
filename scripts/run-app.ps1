# ============================================================================
#  一键启动 Flutter 客户端
# ----------------------------------------------------------------------------
#  解决两个长期痛点：
#    1. 服务器地址老是变（WiFi / adb reverse / 换网），每次要手动改
#    2. flutter run 忘了带 --dart-define，装上去连 10.0.2.2 连不上
#
#  用法：
#    .\run-app.ps1                 自动探测 IP，热重载开发
#    .\run-app.ps1 -Reverse        走 USB 反向代理（不需要同一 WiFi）
#    .\run-app.ps1 -Release        打 release 包而不是 run
#    .\run-app.ps1 -ApiBase http://192.168.31.200:8080   手动指定
#    .\run-app.ps1 -DryRun         只打印将要执行的命令，不真跑
# ============================================================================

param(
    [string]$ApiBase = '',
    [switch]$Reverse,
    [switch]$Release,
    [switch]$DryRun,
    [string]$Device = ''
)

$ErrorActionPreference = 'Stop'

$root   = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $root 'app'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host $msg -ForegroundColor Green }
function Write-Warn2($msg){ Write-Host $msg -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host $msg -ForegroundColor Red }

# ----------------------------------------------------------------------------
# 1. 补齐环境变量（新开终端可能没继承到）
# ----------------------------------------------------------------------------
foreach ($name in @('JAVA_HOME', 'ANDROID_HOME', 'ANDROID_SDK_ROOT', 'PUB_CACHE')) {
    if (-not (Test-Path "env:$name")) {
        $v = [Environment]::GetEnvironmentVariable($name, 'User')
        if ($v) { Set-Item "env:$name" $v }
    }
}
if ($env:ANDROID_HOME) { $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME }

$env:PUB_HOSTED_URL           = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'

# flutter / adb 不在 PATH 就补上
$need = @()
if (-not (Get-Command flutter -ErrorAction SilentlyContinue) -and (Test-Path 'D:\dev\flutter\bin')) {
    $need += 'D:\dev\flutter\bin'
    $need += 'D:\dev\flutter\bin\cache\dart-sdk\bin'
}
if ($env:ANDROID_HOME -and (Test-Path (Join-Path $env:ANDROID_HOME 'platform-tools'))) {
    $need += (Join-Path $env:ANDROID_HOME 'platform-tools')
}
if ($need.Count -gt 0) { $env:PATH = ($need -join ';') + ';' + $env:PATH }

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Err "找不到 flutter 命令，请确认 D:\dev\flutter\bin 存在"
    exit 1
}

# ----------------------------------------------------------------------------
# 2. 探测局域网 IP
# ----------------------------------------------------------------------------
function Get-LanIp {
    $candidates = @()
    foreach ($addr in (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue)) {
        if ($addr.IPAddress -like '127.*' -or $addr.IPAddress -like '169.254.*') { continue }

        # 只保留"有默认路由"的网卡，排除 VMware / Hyper-V / WSL 这类虚拟网卡
        $hasRoute = Get-NetRoute -InterfaceIndex $addr.InterfaceIndex `
                                  -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue
        if (-not $hasRoute) { continue }

        $candidates += $addr.IPAddress
    }

    # 家用路由器最常见的就是 192.168.x.x，其次 10.x.x.x
    foreach ($prefix in @('192.168.', '10.', '172.')) {
        $hit = $candidates | Where-Object { $_ -like "$prefix*" } | Select-Object -First 1
        if ($hit) { return $hit }
    }
    return ($candidates | Select-Object -First 1)
}

# ----------------------------------------------------------------------------
# 3. 决定服务器地址
# ----------------------------------------------------------------------------
$adb = $null
if ($env:ANDROID_HOME) {
    $maybe = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
    if (Test-Path $maybe) { $adb = $maybe }
}

if (-not $ApiBase) {
    if ($Reverse) {
        $ApiBase = 'http://127.0.0.1:8080'
    } else {
        $ip = Get-LanIp
        if (-not $ip) {
            Write-Err "探测不到局域网 IP，请用 -ApiBase 手动指定"
            exit 1
        }
        $ApiBase = "http://${ip}:8080"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "  Flutter 客户端启动" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "  接口地址:  $ApiBase" -ForegroundColor White
Write-Host "  模式:      $(if ($Release) { '打 release 包' } elseif ($Reverse) { 'USB 反向代理' } else { '热重载开发' })" -ForegroundColor White
Write-Host ""

# ----------------------------------------------------------------------------
# 4. 检查后端是否在线（不通只警告，不阻断）
# ----------------------------------------------------------------------------
$healthUrl = "$ApiBase/api/v1/health"

try {
    $h = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 3
    if ($h.data.db -eq 'up') {
        Write-Ok "  后端在线，数据库正常"
    } else {
        Write-Warn2 "  后端在线，但数据库异常（db=$($h.data.db)）"
    }
} catch {
    Write-Warn2 "  后端没响应：$ApiBase"
    Write-Warn2 "  先双击 start.bat 启动服务，否则 App 会提示'连不上服务器'"
}

# ----------------------------------------------------------------------------
# 5. adb reverse
# ----------------------------------------------------------------------------
if ($Reverse -and -not $DryRun) {
    if (-not $adb) {
        Write-Err "  -Reverse 需要 adb，但没找到 ANDROID_HOME/platform-tools/adb.exe"
        exit 1
    }
    Write-Step "  建立 USB 端口转发 ..."
    & $adb reverse tcp:8080 tcp:8080 | Out-Null
    & $adb reverse --list | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
}

# ----------------------------------------------------------------------------
# 6. 检查设备
# ----------------------------------------------------------------------------
if (-not $Release) {
    if (-not $adb) {
        Write-Err "  找不到 adb，无法确认设备连接"
        exit 1
    }
    $devices = (& $adb devices) | Select-Object -Skip 1 | Where-Object { $_ -match '\sdevice$' }
    if (-not $devices) {
        Write-Err "  没有已授权的 Android 设备"
        Write-Host "  排查：" -ForegroundColor DarkGray
        Write-Host "    1. 手机是否插好、开发者选项里 USB 调试是否打开" -ForegroundColor DarkGray
        Write-Host "    2. 手机上是否点了'允许 USB 调试'" -ForegroundColor DarkGray
        Write-Host "    3. adb devices 看是否显示 unauthorized" -ForegroundColor DarkGray
        exit 1
    }
    Write-Ok "  已连接设备：$($devices.Count) 台"
}

# ----------------------------------------------------------------------------
# 7. 执行
# ----------------------------------------------------------------------------
Set-Location $appDir

if (-not (Test-Path (Join-Path $appDir 'pubspec.yaml'))) {
    Write-Err "  在 $appDir 找不到 pubspec.yaml"
    exit 1
}

$defineArg = "--dart-define=API_BASE=$ApiBase"

if ($Release) {
    $cliArgs = @('build', 'apk', '--release', '--split-per-abi', $defineArg)
} else {
    $cliArgs = @('run', $defineArg)
    if ($Device) { $cliArgs += @('-d', $Device) }
}
$cmdText = "flutter $($cliArgs -join ' ')"

if ($DryRun) {
    Write-Host ""
    Write-Step "  [DryRun] 将在 $appDir 执行："
    Write-Host "    $cmdText" -ForegroundColor White
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Step "  执行：$cmdText"
Write-Host ""

& flutter @cliArgs
$code = $LASTEXITCODE

if ($Release) {
    $apk = Join-Path $appDir 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
    if (Test-Path $apk) {
        Write-Host ""
        Write-Ok "  构建成功：$apk（$([math]::Round((Get-Item $apk).Length/1MB,1)) MB）"
        Write-Host "  安装到手机：" -ForegroundColor DarkGray
        Write-Host "    adb install -r `"$apk`"" -ForegroundColor DarkGray
    }
}

exit $code
