@echo off
:: Shared build script. Usage: call build_android.bat [debug|release]
:: Sets APK_PATH on success.

setlocal

set "BUILD_MODE=release"
if /i "%~1"=="debug" set "BUILD_MODE=debug"

:: Flutter 3.44+ writes both debug and release APKs to build\app\outputs\flutter-apk\.
set "FLUTTER_APK=%~dp0..\build\app\outputs\flutter-apk"
set "TARGET_DIR=%FLUTTER_APK%"
if "%BUILD_MODE%"=="debug" (
    set "APK_PATH=%FLUTTER_APK%\app-debug.apk"
) else (
    set "APK_PATH=%FLUTTER_APK%\app-release.apk"
)

for %%I in ("%APK_PATH%") do set "APK_PATH=%%~fI"
for %%I in ("%TARGET_DIR%") do set "TARGET_DIR=%%~fI"

echo [Build 1/4] Incrementing build number...
call "%~dp0build_number_increment.bat"
if errorlevel 1 (
    echo ERROR: Failed to increment build number.
    exit /b 1
)
echo.

echo [Build 2/4] Cleaning existing APKs from %TARGET_DIR% ...
if exist "%TARGET_DIR%" del /q "%TARGET_DIR%\*.apk" 2>nul
echo.

echo [Build 3/4] Building Android %BUILD_MODE% APK...
pushd "%~dp0.."
if "%BUILD_MODE%"=="debug" (
    call fvm flutter build apk --debug
) else (
    call fvm flutter build apk --release
)
set "BUILD_RC=%errorlevel%"
popd
if not "%BUILD_RC%"=="0" (
    echo.
    echo ERROR: Build failed ^(exit code %BUILD_RC%^).
    exit /b %BUILD_RC%
)
echo.

echo [Build 4/4] Verifying build...
if not exist "%APK_PATH%" (
    echo.
    echo ERROR: APK not found at "%APK_PATH%"
    exit /b 1
)
call :report_size "%APK_PATH%"
echo.

endlocal & set "APK_PATH=%APK_PATH%"
exit /b 0

:report_size
set "APK_SIZE=%~z1"
if not defined APK_SIZE set "APK_SIZE=0"
set /a "APK_SIZE_MB=APK_SIZE / 1048576"
echo    APK: %~f1  (%APK_SIZE_MB% MB)
exit /b 0
