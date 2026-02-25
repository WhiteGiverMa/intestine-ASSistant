# 覆盖安装 APK（保留数据）
# Usage: .\install_keep_data.ps1 [-release]

param(
    [switch]$release
)

$ErrorActionPreference = "Stop"

# 自动查找 adb 路径
$adbPaths = @(
    "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "adb.exe"
)

$adb = $null
foreach ($path in $adbPaths) {
    if (Get-Command $path -ErrorAction SilentlyContinue) {
        $adb = $path
        break
    }
}

if (-not $adb) {
    Write-Host "adb not found! Please install Android SDK platform-tools." -ForegroundColor Red
    Write-Host "Or add platform-tools to your PATH." -ForegroundColor Yellow
    exit 1
}

Write-Host "Using adb: $adb" -ForegroundColor Gray

Write-Host "Building APK..." -ForegroundColor Cyan

if ($release) {
    flutter build apk --release
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
} else {
    flutter build apk --debug
    $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
}

if (-not (Test-Path $apkPath)) {
    Write-Host "APK not found at $apkPath" -ForegroundColor Red
    exit 1
}

Write-Host "Installing APK (keeping data)..." -ForegroundColor Cyan

# 获取连接的设备
$devices = & $adb devices | Select-String "\tdevice$" | ForEach-Object { ($_ -split "`t")[0] }

if ($devices.Count -eq 0) {
    Write-Host "No device connected!" -ForegroundColor Red
    exit 1
}

foreach ($device in $devices) {
    Write-Host "Installing to $device..." -ForegroundColor Yellow
    & $adb -s $device install -r $apkPath

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully installed to $device" -ForegroundColor Green
    } else {
        Write-Host "Failed to install to $device" -ForegroundColor Red
    }
}

Write-Host "`nDone! Data has been preserved." -ForegroundColor Green
