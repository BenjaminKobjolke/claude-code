cd /d D:\GIT\BenjaminKobjolke\ftp-sync
call uv run python main.py "%~dp0config_SLUG.ini"
cd %~dp0
