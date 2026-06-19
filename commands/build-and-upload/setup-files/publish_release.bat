@echo off
REM Publish a built release artifact (exe/zip) over FTP via the release-tool.
REM Backend B of /build-and-upload:setup. Reads tools\publish_settings.ini.
REM
REM Edit the three values below:
REM   ARTIFACT      - path to the built file to upload (relative to this bat's tools\ folder)
REM   PREV_VERSION  - the previously released version, used to name the backup folder
REM                   when publish_settings.ini has subfolder_naming = version
REM Tip: add --dry-run to the command line to preview without uploading.
setlocal
set "RELEASE_TOOL_DIR=D:\GIT\BenjaminKobjolke\release-tool"
set "ARTIFACT=%~dp0..\<App>.exe"
set "CONFIG=%~dp0publish_settings.ini"
set "PREV_VERSION=0.0.0"

if not exist "%RELEASE_TOOL_DIR%\pyproject.toml" (
    echo [publish] release-tool not found at %RELEASE_TOOL_DIR%
    echo [publish] Check out https://github.com/BenjaminKobjolke and run its install, or fix RELEASE_TOOL_DIR.
    exit /b 1
)

cd /d "%RELEASE_TOOL_DIR%"
call uv run python -m release_tool "%ARTIFACT%" "%CONFIG%" --previous-version %PREV_VERSION% --verbose
set EXITCODE=%ERRORLEVEL%
cd /d "%~dp0"
endlocal & exit /b %EXITCODE%
