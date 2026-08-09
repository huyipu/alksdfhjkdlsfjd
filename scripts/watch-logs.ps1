# 天龙亿旧 - 日志查看脚本
# 用法: .\watch-logs.ps1 [-Clear] [-Tag <tag>]
#   -Clear  : 先清空日志再查看
#   -Tag    : 过滤指定标签 (默认不过滤)

param(
    [switch]$Clear,
    [string]$Tag = ""
)

# 查找 adb
$adb = $null
$candidates = @(
    "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "${env:ProgramFiles(x86)}\Android\android-sdk\platform-tools\adb.exe",
    "D:\work\work\tools\android-sdk\platform-tools\adb.exe"
)

foreach ($c in $candidates) {
    if (Test-Path $c) {
        $adb = $c
        break
    }
}

if (-not $adb) {
    $adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
}

if (-not $adb) {
    Write-Host "错误: 找不到 adb.exe" -ForegroundColor Red
    Write-Host "请确保 Android SDK 已安装，或设置 ANDROID_SDK_ROOT 环境变量" -ForegroundColor Yellow
    exit 1
}

Write-Host "使用 adb: $adb" -ForegroundColor DarkGray

# 设备检查
$devices = & $adb devices | Select-String -Pattern "^\S+\tdevice$"
if (-not $devices) {
    Write-Host "错误: 没有检测到已连接的 Android 设备" -ForegroundColor Red
    Write-Host "请连接手机并开启 USB 调试" -ForegroundColor Yellow
    exit 1
}

Write-Host "检测到设备:" -ForegroundColor Green
$devices | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }

# 包名 - 自动从 build.gradle.kts 的唯一配置点读取，改包名无需动这里
$gradleFile = Join-Path $PSScriptRoot "..\android\app\build.gradle.kts"
$packageName = "com.xxddtt.twoapp"  # 兜底默认值
if (Test-Path $gradleFile) {
    $m = Select-String -Path $gradleFile -Pattern 'val appId = "([^"]+)"' | Select-Object -First 1
    if ($m) { $packageName = $m.Matches[0].Groups[1].Value }
}

# 清空日志
if ($Clear) {
    Write-Host "正在清空日志缓冲区..." -ForegroundColor Yellow
    & $adb logcat -c
    Start-Sleep -Milliseconds 500
}

# 构建过滤参数
# 默认过滤: flutter标签 + AndroidRuntime(崩溃) + MainActivity + 包名相关
$filterArgs = @("logcat", "-v", "color", "-v", "time")

if ($Tag) {
    # 只过滤指定标签
    $filterArgs += "$Tag:D"
    $filterArgs += "*:S"
} else {
    # 默认过滤模式 - 同时显示多个关键标签
    $filterArgs += "flutter:D"
    $filterArgs += "AndroidRuntime:E"
    $filterArgs += "MainActivity:D"
    $filterArgs += "ActivityManager:W"
    $filterArgs += "DEBUG:E"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  开始查看日志 - 按 Ctrl+C 停止" -ForegroundColor Green
Write-Host "  包名: $packageName" -ForegroundColor Green
if ($Clear) { Write-Host "  已清空历史日志" -ForegroundColor Green }
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

& $adb @filterArgs
