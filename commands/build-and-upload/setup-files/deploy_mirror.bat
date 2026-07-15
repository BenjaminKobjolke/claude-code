@echo off
setlocal
@rem Mirror the whole project to FTP via ftp-sync (up + hash cache).
@rem Excludes come from a .deployignore file in the project root (gitignore syntax).
@rem Requires mirror.ini next to this bat (copy mirror.ini.example, fill in credentials).

set "FTP_SYNC_DIR=D:\GIT\BenjaminKobjolke\ftp-sync"
set "CONFIG_FILE=%~dp0mirror.ini"

if not exist "%CONFIG_FILE%" (
    echo ERROR: mirror.ini not found. Copy mirror.ini.example and fill in credentials.
    pause
    exit /b 1
)
if not exist "%FTP_SYNC_DIR%\main.py" (
    echo ERROR: ftp-sync tool not found at %FTP_SYNC_DIR%
    pause
    exit /b 1
)

echo Syncing to FTP...
cd /d "%FTP_SYNC_DIR%"
uv run main.py "%CONFIG_FILE%"
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Upload failed.
    pause
    exit /b 1
)

echo.
echo Done.
endlocal
