$ErrorActionPreference = 'Stop'
$env:PUB_CACHE = 'D:\tools\pub-cache'
Push-Location (Join-Path $PSScriptRoot 'workout_ai')
try {
    & D:/tools/flutter-sdk/bin/flutter.bat --no-version-check run -d web-server --web-hostname 127.0.0.1 --web-port 8080
} finally {
    Pop-Location
}
