@echo off
call "%~dp0build_and_upload_android.bat" debug
exit /b %errorlevel%
