# 一键打包 APK
# 用法：右键「使用 PowerShell 运行」，或：powershell -ExecutionPolicy Bypass -File build-apk.ps1
#       powershell -File build-apk.ps1 -ApiBase http://192.168.1.23:8080

param(
    [string]$ApiBase = ""
)

$ErrorActionPreference = 'Stop'

$env:JAVA_HOME        = 'C:\Program Files\Java\jdk-21'
$env:ANDROID_HOME     = 'D:\dev\android-sdk'
$env:ANDROID_SDK_ROOT = 'D:\dev\android-sdk'
$env:PUB_HOSTED_URL              = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL    = 'https://storage.flutter-io.cn'
$env:PATH = "D:\dev\flutter\bin;D:\dev\flutter\bin\cache\dart-sdk\bin;D:\dev\android-sdk\platform-tools;$env:PATH"

$root = Split-Path -Parent $PSScriptRoot
$app  = Join-Path $root 'app'

if (-not (Test-Path 'D:\dev\flutter\bin\flutter.bat')) {
    Write-Host "Flutter 还没装好：D:\dev\flutter" -ForegroundColor Red
    exit 1
}

# 没传地址就自动探测本机局域网 IPv4
if (-not $ApiBase) {
    try {
        $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop |
                 Sort-Object RouteMetric | Select-Object -First 1
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $route.InterfaceIndex -ErrorAction Stop |
               Where-Object { $_.IPAddress -notlike '169.254.*' } |
               Select-Object -First 1).IPAddress
        if ($ip) { $ApiBase = "http://${ip}:8080" }
    } catch { }
}

if (-not $ApiBase) {
    Write-Host "无法自动识别局域网 IP，请手动指定：" -ForegroundColor Yellow
    Write-Host "  .\build-apk.ps1 -ApiBase http://192.168.1.23:8080" -ForegroundColor Yellow
    exit 1
}

Write-Host "接口地址：$ApiBase" -ForegroundColor Cyan
Write-Host "开始构建（首次会比较慢）..." -ForegroundColor Cyan

Push-Location $app
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get 失败" }

    & flutter build apk --release --split-per-abi --dart-define=API_BASE=$ApiBase
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk 失败" }
} finally {
    Pop-Location
}

$apk = Join-Path $app 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
if (Test-Path $apk) {
    $size = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host ""
    Write-Host "构建成功：$apk  ($size MB)" -ForegroundColor Green
    Write-Host ""
    Write-Host "装到手机（数据线）:" -ForegroundColor Yellow
    Write-Host "  adb install -r `"$apk`"" -ForegroundColor Yellow
    Write-Host "或把文件发给手机（微信文件传输助手）手动安装。" -ForegroundColor Yellow
} else {
    Write-Host "没找到产物，请检查上面的输出。" -ForegroundColor Red
}

Read-Host "按回车退出"
