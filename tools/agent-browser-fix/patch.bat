@echo off
REM Patches agent-browser with Windows daemon auto-start fix
REM Run this after npm install -g agent-browser or npm update -g agent-browser
REM Workaround for upstream issue (PR #362)
REM Replaces the PowerShell and cmd launchers because npm points them at the native exe,
REM which skips the patched Node wrapper's daemon pre-start.

set "SOURCE=%~dp0agent-browser.js"
set "NPM_DIR=%APPDATA%\npm"
set "TARGET=%NPM_DIR%\node_modules\agent-browser\bin\agent-browser.js"
set "CMD_SOURCE=%~dp0agent-browser.cmd"
set "PS1_SOURCE=%~dp0agent-browser.ps1"

if not exist "%SOURCE%" (
    echo ERROR: Patched file not found: %SOURCE%
    exit /b 1
)

if not exist "%TARGET%" (
    echo ERROR: agent-browser not installed globally. Run: npm install -g agent-browser
    exit /b 1
)

if not exist "%CMD_SOURCE%" (
    echo ERROR: Launcher file not found: %CMD_SOURCE%
    exit /b 1
)

if not exist "%PS1_SOURCE%" (
    echo ERROR: Launcher file not found: %PS1_SOURCE%
    exit /b 1
)

copy /Y "%SOURCE%" "%TARGET%"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy patch file.
    exit /b 1
)

copy /Y "%CMD_SOURCE%" "%NPM_DIR%\agent-browser.cmd"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy cmd launcher.
    exit /b 1
)

copy /Y "%PS1_SOURCE%" "%NPM_DIR%\agent-browser.ps1"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to copy PowerShell launcher.
    exit /b 1
)

echo Patch applied successfully.
echo Patched: %TARGET%
echo Patched: %NPM_DIR%\agent-browser.cmd
echo Patched: %NPM_DIR%\agent-browser.ps1
exit /b 0
