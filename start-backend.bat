@echo off
setlocal

set "ROOT=%~dp0"
set "BACKEND=%ROOT%backend"
set "LOGDIR=%ROOT%presentation_output\run_logs"
set "WATCHER=%ROOT%ensure-emulator-backend-link.ps1"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

if exist "%WATCHER%" (
  powershell -NoProfile -Command "$current = $PID; if (-not (Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $current -and $_.CommandLine -like '*ensure-emulator-backend-link.ps1*' })) { Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%WATCHER%""' }"
)

cd /d "%BACKEND%"

if not exist node_modules (
  echo Installing backend dependencies...
  npm install
)

powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort 5200 -State Listen -ErrorAction SilentlyContinue) { exit 0 } exit 1" >nul 2>nul
if not errorlevel 1 (
  echo Backend is already running at http://127.0.0.1:5200
  exit /b 0
)

echo Starting backend at http://127.0.0.1:5200
powershell -NoProfile -Command "Start-Process -FilePath 'node' -ArgumentList 'src/index.js' -WorkingDirectory '%BACKEND%' -WindowStyle Hidden -RedirectStandardOutput '%LOGDIR%\backend.current.log' -RedirectStandardError '%LOGDIR%\backend.current.err.log'"
powershell -NoProfile -Command "Start-Sleep -Seconds 2; $p = Start-Process -FilePath 'curl.exe' -ArgumentList '--max-time','5','--silent','--fail','http://127.0.0.1:5200/api/health' -NoNewWindow -Wait -PassThru; if ($p.ExitCode -eq 0) { Write-Host 'Backend started and health check passed: http://127.0.0.1:5200'; exit 0 } else { Write-Host 'Backend health check failed'; exit 1 }"
