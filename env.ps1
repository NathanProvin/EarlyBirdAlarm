# Activate the project-local toolchain for this terminal session only (like `.venv\Scripts\activate`).
# Usage:  . .\env.ps1
$tools = Join-Path $PSScriptRoot ".tools"
$env:JAVA_HOME = "$tools\jdk"
$env:ANDROID_HOME = "$tools\android-sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:PUB_CACHE = "$tools\pub-cache"
$env:Path = "$tools\flutter\bin;$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:Path"
Write-Host "Early Bird toolchain active (Flutter, JDK 17, Android SDK from .tools/)"
