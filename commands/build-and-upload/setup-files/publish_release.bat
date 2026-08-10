@echo off
REM Publish a built release artifact (exe/zip) over FTP via the release-tool.
REM Backend B of /build-and-upload:setup. Reads tools\publish_settings.ini.
REM
REM Edit ARTIFACT below (path to the built file to upload).
REM Previous version (for the backup folder when subfolder_naming = version) comes
REM from %1 if given, else tools\previous_version.txt written by release_create.bat.
REM Empty => the tool falls back to timestamp-named backups.
REM Tip: add --dry-run to the command line to preview without uploading.
setlocal
set "RELEASE_TOOL_DIR=D:\GIT\BenjaminKobjolke\release-tool"
set "ARTIFACT=%~dp0..\<App>.exe"
set "CONFIG=%~dp0publish_settings.ini"
set "PREV_VERSION=%~1"
if not defined PREV_VERSION if exist "%~dp0previous_version.txt" set /p "PREV_VERSION="<"%~dp0previous_version.txt"

if not exist "%RELEASE_TOOL_DIR%\pyproject.toml" (
    echo [publish] release-tool not found at %RELEASE_TOOL_DIR%
    echo [publish] Check out https://github.com/BenjaminKobjolke and run its install, or fix RELEASE_TOOL_DIR.
    exit /b 1
)

cd /d "%RELEASE_TOOL_DIR%"
call uv run python -m release_tool "%ARTIFACT%" "%CONFIG%" --previous-version "%PREV_VERSION%" --verbose
set EXITCODE=%ERRORLEVEL%
cd /d "%~dp0"
endlocal & exit /b %EXITCODE%
