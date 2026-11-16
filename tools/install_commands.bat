@echo off
setlocal
pushd "%~dp0"
if errorlevel 1 exit /b %errorlevel%

python install_commands.py %*
set "RESULT=%ERRORLEVEL%"

popd
exit /b %RESULT%
