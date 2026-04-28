@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "HVIGORW=D:\software\deveco\DevEco Studio\tools\hvigor\bin\hvigorw.bat"
set "DEVECO_SDK_HOME=D:\software\deveco\DevEco Studio\sdk"
set "OHOS_BASE_SDK_HOME=D:\software\deveco\DevEco Studio\sdk\default\openharmony"

if not exist "%HVIGORW%" (
  echo ERROR: hvigorw not found at:
  echo   %HVIGORW%
  exit /b 1
)

pushd "%PROJECT_DIR%"
set "DEVECO_SDK_HOME=%DEVECO_SDK_HOME%"
set "OHOS_BASE_SDK_HOME=%OHOS_BASE_SDK_HOME%"
call "%HVIGORW%" assembleHap --no-daemon %*
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b %EXIT_CODE%
