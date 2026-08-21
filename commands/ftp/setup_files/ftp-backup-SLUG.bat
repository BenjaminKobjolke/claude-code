@echo off
REM Backs up FTP_DIRECTORY via ftp-sync (DIRECTION = down) into %BACKUP_ROOT%\current,
REM then zips a snapshot into %BACKUP_ROOT%\revisions and keeps the newest %KEEP%.
REM Limits: ftp-sync download skip is size-only (same-size edits not re-fetched);
REM files deleted on the server are moved by the tool into current\old\.
REM BACKUP_ROOT\current must match LOCAL_DIRECTORY in config_SLUG_backup.ini.
set "BACKUP_ROOT=BACKUPROOT"
set "CURRENT_DIR=%BACKUP_ROOT%\current"
set "REVISIONS_DIR=%BACKUP_ROOT%\revisions"
set "KEEP=30"

cd /d FTPSYNCDIR
call uv run python main.py "%~dp0config_SLUG_backup.ini"
set "SYNC_EXIT=%ERRORLEVEL%"
cd /d "%~dp0"
if not "%SYNC_EXIT%"=="0" (
    echo FTP sync failed with exit code %SYNC_EXIT% - skipping snapshot.
    exit /b %SYNC_EXIT%
)

if not exist "%REVISIONS_DIR%" mkdir "%REVISIONS_DIR%"

for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmmss"') do set "TS=%%t"

REM Full path: Git Bash GNU tar would parse drive-letter paths as a remote host; bsdtar does not.
"%SystemRoot%\System32\tar.exe" -a -cf "%REVISIONS_DIR%\%TS%.zip" -C "%CURRENT_DIR%" .
if errorlevel 1 (
    echo Snapshot zip failed.
    exit /b 1
)

REM Keep newest %KEEP% revisions. -LiteralPath: path may contain [ ] wildcard chars.
powershell -NoProfile -Command "Get-ChildItem -LiteralPath '%REVISIONS_DIR%' -Filter *.zip | Sort-Object Name -Descending | Select-Object -Skip %KEEP% | Remove-Item -Force"
