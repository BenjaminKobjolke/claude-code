@echo off
setlocal enabledelayedexpansion

set "BUILD_MODE=release"
if /i "%~1"=="debug" set "BUILD_MODE=debug"

echo ========================================
if "%BUILD_MODE%"=="debug" (
    echo Build and Upload Android Debug APK
) else (
    echo Build and Upload Android Release APK
)
echo ========================================
echo.

call "%~dp0build_android.bat" %BUILD_MODE%
if errorlevel 1 (
    echo.
    echo ERROR: Build failed.
    exit /b 1
)

echo [Upload] Uploading to FTP...
if "%BUILD_MODE%"=="debug" (
    call "%~dp0upload_debug-apk-to-ftp.bat"
) else (
    call "%~dp0upload_release-apk-to-ftp.bat"
)
if errorlevel 1 (
    echo.
    echo ERROR: Upload failed.
    exit /b 1
)

set "VERSION=Unknown"
for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" "%~dp0..\pubspec.yaml"') do set "VERSION=%%a"

echo.
echo ========================================
echo Build and upload completed.
echo Version: %VERSION%
echo ========================================
echo.
endlocal
