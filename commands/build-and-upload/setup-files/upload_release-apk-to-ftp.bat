@echo off
setlocal enabledelayedexpansion

set "INI=%~dp0release.ini"
if not exist "%INI%" (
    echo ERROR: "%INI%" not found.
    echo Copy release.ini.example to release.ini and fill in the FTP values.
    pause
    exit /b 1
)

set "APK=%~dp0..\build\app\outputs\flutter-apk\app-release.apk"
if not exist "%APK%" (
    echo.
    echo ERROR: APK not found: "%APK%"
    echo Run build_android.bat release first.
    echo.
    pause
    exit /b 1
)

:: Read version from pubspec and build the FTP filename: app_v<version>_<build>.apk
set "VER="
for /f "tokens=2 delims=: " %%a in ('findstr /r "^version:" "%~dp0..\pubspec.yaml"') do set "VER=%%a"
for /f "tokens=1,2 delims=+" %%a in ("!VER!") do (
    set "VNAME=%%a"
    set "VBUILD=%%b"
)
if "!VNAME!"=="" (
    echo ERROR: Could not parse version from pubspec.yaml.
    exit /b 1
)
set "TARGET_APK_NAME=app_v!VNAME!_!VBUILD!.apk"

:: Stage a renamed copy. The staging dir accumulates every released version; ftp-sync runs in
:: no-delete mode (NO_DELETE=true in the ini) so older versioned APKs stay on the FTP.
set "STAGING=%~dp0..\build\publish\release"
if not exist "%STAGING%" mkdir "%STAGING%"
copy /y "%APK%" "%STAGING%\!TARGET_APK_NAME!" >nul
if errorlevel 1 (
    echo ERROR: Failed to stage APK to "%STAGING%\!TARGET_APK_NAME!".
    exit /b 1
)

set "APK_LINK_DIR="
for /f "tokens=1,* delims==" %%a in ('findstr /b /i "APK_LINK_DIR=" "%INI%"') do set "APK_LINK_DIR=%%b"

echo [Upload] Syncing release APK via ftp-sync...
call "%~dp0ftpsync_upload.bat" "%INI%" "%STAGING%" "%~dp0..\build\publish\.ftpsync_release.db"
if errorlevel 1 exit /b 1

echo.
echo Version:     !VER!
echo Uploaded as: !TARGET_APK_NAME!
echo Link:        !APK_LINK_DIR!/!TARGET_APK_NAME!
echo.

endlocal
