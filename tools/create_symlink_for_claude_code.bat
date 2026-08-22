@echo off
setlocal EnableExtensions

rem Links this repo's commands\ folder into Claude Code's user config so every
rem command here shows up as a slash command (/<category>:<name>).
rem The repo stays the source of truth - Claude just reads through the link.

set "SOURCE=%~dp0.."
for %%I in ("%SOURCE%") do set "SOURCE=%%~fI"
set "TARGET=%USERPROFILE%\.claude\commands"

if not exist "%SOURCE%\commands\" (
    echo ERROR: source folder not found: %SOURCE%\commands
    exit /b 1
)

if not exist "%USERPROFILE%\.claude\" mkdir "%USERPROFILE%\.claude"

if exist "%TARGET%" call :remove_existing_link
if errorlevel 1 exit /b 1

echo Linking %TARGET%
echo      -^> %SOURCE%\commands

rem Symlinks need admin rights or Developer Mode; junctions do not and behave
rem the same for a local folder. Try the symlink first, fall back to a junction.
mklink /D "%TARGET%" "%SOURCE%\commands" >nul 2>&1
if not errorlevel 1 (
    echo Created symlink.
    goto :done
)
mklink /J "%TARGET%" "%SOURCE%\commands" >nul 2>&1
if not errorlevel 1 (
    echo Created junction ^(no admin rights needed^).
    goto :done
)
echo ERROR: could not create the link.
echo Run this script as administrator, or enable Windows Developer Mode.
exit /b 1

:done
echo Done. Restart Claude Code to pick up the commands.
exit /b 0

rem ---------------------------------------------------------------------------
rem Removes %TARGET% only when it is a symlink or junction. A real folder is
rem left alone - deleting one could throw away commands that already live there.
:remove_existing_link
set "ATTR="
for %%I in ("%TARGET%") do set "ATTR=%%~aI"
echo %ATTR% | findstr /C:"l" >nul
if errorlevel 1 (
    echo ERROR: %TARGET% already exists and is a real folder, not a link.
    echo Move or delete it yourself, then run this script again.
    exit /b 1
)
echo Removing existing link: %TARGET%
rmdir "%TARGET%"
if exist "%TARGET%" (
    echo ERROR: could not remove %TARGET%
    exit /b 1
)
exit /b 0
