@echo off
setlocal enabledelayedexpansion

set "INI=%~dp0debug.ini"
if not exist "%INI%" (
    echo ERROR: "%INI%" not found.
    echo Copy debug.ini.example to debug.ini and fill in the FTP values.
    pause
    exit /b 1
)

set "APK=%~dp0..\build\app\outputs\flutter-apk\app-debug.apk"
if not exist "%APK%" (
    echo.
    echo ERROR: APK not found: "%APK%"
    echo Run build_android.bat debug first.
    echo.
    pause
    exit /b 1
)

:: Stage under the fixed debug name (unchanged). ftp-sync runs in no-delete mode, so the debug
:: APK and the versioned release APKs coexist on the FTP without clobbering each other.
set "TARGET_APK_NAME=kiosk-locker-debug.apk"
set "STAGING=%~dp0..\build\publish\debug"
if not exist "%STAGING%" mkdir "%STAGING%"
copy /y "%APK%" "%STAGING%\%TARGET_APK_NAME%" >nul
if errorlevel 1 (
    echo ERROR: Failed to stage APK to "%STAGING%\%TARGET_APK_NAME%".
    exit /b 1
)

set "APK_LINK_DIR="
for /f "tokens=1,* delims==" %%a in ('findstr /b /i "APK_LINK_DIR=" "%INI%"') do set "APK_LINK_DIR=%%b"

echo [Upload] Syncing debug APK via ftp-sync...
call "%~dp0ftpsync_upload.bat" "%INI%" "%STAGING%" "%~dp0..\build\publish\.ftpsync_debug.db"
if errorlevel 1 exit /b 1

set "VERSION=Unknown"
for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" "%~dp0..\pubspec.yaml"') do set "VERSION=%%a"

echo.
echo Version:     %VERSION%
echo Uploaded as: %TARGET_APK_NAME%
echo Link:        %APK_LINK_DIR%/%TARGET_APK_NAME%
echo.

endlocal
