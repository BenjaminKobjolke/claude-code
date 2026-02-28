@echo off

cd "%~dp0.."
:: Check for admin privileges, auto-elevate if needed
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:: Prompt for target project folder
set /p "TARGET_DIR=Enter project folder path (e.g., D:\GIT\your-awesome-app\): "

:: Validate input
if "%TARGET_DIR%"=="" (
    echo Error: No path provided.
    pause
    exit /b 1
)

:: Check if target directory exists
if not exist "%TARGET_DIR%" (
    echo Error: Directory "%TARGET_DIR%" does not exist.
    pause
    exit /b 1
)

:: Set symlink target path
set "HOOKS_DIR=%TARGET_DIR%\hooks"

:: Check if hooks folder already exists
if exist "%HOOKS_DIR%" (
    echo Error: "%HOOKS_DIR%" already exists.
    echo Please remove it first if you want to create a symlink.
    pause
    exit /b 1
)

:: Get project root directory (parent of tools/)
set "CURRENT_DIR=%~dp0.."
pushd "%CURRENT_DIR%"
set "CURRENT_DIR=%CD%"
popd

:: Create symlink
mklink /D "%HOOKS_DIR%" "%CURRENT_DIR%"

if %errorlevel% equ 0 (
    echo Symlink created successfully:
    echo   %HOOKS_DIR% -^> %CURRENT_DIR%
) else (
    echo Failed to create symlink.
)

cd "%~dp0"
