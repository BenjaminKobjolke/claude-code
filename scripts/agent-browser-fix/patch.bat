@echo off
REM Patches agent-browser with Windows daemon auto-start fix
REM Run this after npm install -g agent-browser or npm update -g agent-browser
REM Workaround for upstream issue (PR #362)

set "SOURCE=%~dp0agent-browser.js"
set "TARGET=%APPDATA%\npm\node_modules\agent-browser\bin\agent-browser.js"

if not exist "%SOURCE%" (
    echo ERROR: Patched file not found: %SOURCE%
    exit /b 1
)

if not exist "%TARGET%" (
    echo ERROR: agent-browser not installed globally. Run: npm install -g agent-browser
    exit /b 1
)

copy /Y "%SOURCE%" "%TARGET%"
if %ERRORLEVEL% equ 0 (
    echo Patch applied successfully.
    echo Patched: %TARGET%
) else (
    echo ERROR: Failed to copy patch file.
    exit /b 1
)
