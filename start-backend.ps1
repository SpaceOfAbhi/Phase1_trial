$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    if (-not (Test-Path -LiteralPath '.venv/Scripts/python.exe')) {
        throw 'Create the Python environment first; see docs/running.md.'
    }
    & .venv/Scripts/python.exe -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
} finally {
    Pop-Location
}
