@echo off
setlocal

cd /d "%~dp0.."

if not exist "pubspec.yaml" (
    echo ERROR: pubspec.yaml not found in "%CD%".
    endlocal
    exit /b 1
)

echo Listing Flutter package upgrades, including major versions...
call fvm flutter pub upgrade --major-versions --dry-run
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" echo ERROR: Major package listing failed.

endlocal & exit /b %EXIT_CODE%
