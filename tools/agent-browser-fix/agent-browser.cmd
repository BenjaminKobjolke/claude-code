@ECHO off
REM Runs the patched node wrapper so the Windows daemon pre-start happens (see patch.bat)
IF EXIST "%~dp0node.exe" (
  "%~dp0node.exe" "%~dp0node_modules\agent-browser\bin\agent-browser.js" %*
) ELSE (
  node "%~dp0node_modules\agent-browser\bin\agent-browser.js" %*
)
