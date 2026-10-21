@echo off
setlocal
REM Machine-specific paths are kept out of git: config.bat is a local copy of config_example.bat.
if not exist "%~dp0config.bat" (
    echo ERROR: tools\config.bat not found. Copy tools\config_example.bat to tools\config.bat and adjust it.
    endlocal & exit /b 1
)
call "%~dp0config.bat"
if not exist "%GPT_JSON_TRANSLATOR_DIR%\json_translator.py" (
    echo ERROR: GPT_JSON_TRANSLATOR_DIR in tools\config.bat is not a GPT-json-translator checkout: "%GPT_JSON_TRANSLATOR_DIR%"
    endlocal & exit /b 1
)
set "TOOLS_DIR=%~dp0"
pushd "%GPT_JSON_TRANSLATOR_DIR%"

call activate_environment.bat

REM 1st arg <<< EDIT: absolute path to THIS project's i18n / locales folder
REM 2nd arg = %TOOLS_DIR%attributes_to_remove.json  (keys to strip; MUST stay 2nd arg or the remover
REM          opens an interactive picker and hangs). Keep this file next to this .bat in tools/.
REM --exclude-source de.json     -> de.json is a hand-verified source, never stripped
REM --exclude-source modules.json -> optional; only if you use a modules.json manifest, else remove
call .\.venv\Scripts\python.exe json_attribute_remover.py ^
  "D:\GIT\BenjaminKobjolke\your_project\assets\i18n" ^
  "%TOOLS_DIR%attributes_to_remove.json" ^
  --recursive --exclude-source de.json --exclude-source modules.json
set "RC=%errorlevel%"
popd
if not defined TICKETS_WATCHER_COMMAND_RUN pause
endlocal & exit /b %RC%
