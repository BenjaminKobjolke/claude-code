@echo off
:: Shared ftp-sync upload helper.
:: Usage: call ftpsync_upload.bat "<settings.ini>" "<staging_dir>" ["<hash_cache_db>"]
:: The ini is a real ftp-sync settings file (passed straight to the tool). FTP creds, FTP_DIRECTORY,
:: DIRECTION=up and NO_DELETE=true live in its [FTP] section. The kiosk-only key FTPSYNC_DIR lives in
:: a [KIOSK] section (ignored by ftp-sync) and is read here to locate the tool.
::
:: When a hash cache db is given, ftp-sync skips scanning the remote tree (which otherwise walks the
:: whole FTP root and errors on unrelated dirs) and only uploads files whose content changed. The db
:: must live OUTSIDE the staging dir so it is never itself uploaded.

setlocal
set "INI=%~1"
set "STAGING=%~2"
set "HASHDB=%~3"

if "%INI%"=="" (
    echo ERROR: ftpsync_upload.bat requires a settings ini path.
    exit /b 1
)
if "%STAGING%"=="" (
    echo ERROR: ftpsync_upload.bat requires a staging directory.
    exit /b 1
)
if not exist "%INI%" (
    echo ERROR: settings ini not found: "%INI%".
    exit /b 1
)

set "FTPSYNC_DIR="
for /f "tokens=1,* delims==" %%a in ('findstr /b /i "FTPSYNC_DIR=" "%INI%"') do set "FTPSYNC_DIR=%%b"
if "%FTPSYNC_DIR%"=="" (
    echo ERROR: FTPSYNC_DIR not set in "%INI%" ^([KIOSK] section^).
    exit /b 1
)
if not exist "%FTPSYNC_DIR%\main.py" (
    echo ERROR: ftp-sync not found at "%FTPSYNC_DIR%\main.py".
    echo Check out the ftp-sync repo and run its install.bat.
    exit /b 1
)

pushd "%FTPSYNC_DIR%"
if "%HASHDB%"=="" (
    call uv run python main.py "%INI%" --local-dir "%STAGING%"
) else (
    call uv run python main.py "%INI%" --local-dir "%STAGING%" --hash-cache-file "%HASHDB%"
)
set "RC=%errorlevel%"
popd

if not "%RC%"=="0" (
    echo ERROR: ftp-sync upload failed ^(exit code %RC%^).
    exit /b %RC%
)

endlocal
exit /b 0
