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

REM <<< EDIT: absolute path to THIS project's i18n / locales folder (contains en.json, subfolders OK)
call .\.venv\Scripts\python.exe json_translator.py "D:\GIT\BenjaminKobjolke\your_project\assets\i18n"  --translate-recursive="en.json" --force

REM Enable once de.json exists as a hand-verified reference (improves all other languages):
REM call .\.venv\Scripts\python.exe json_translator.py "D:\GIT\BenjaminKobjolke\your_project\assets\i18n"  --translate-recursive="en.json" --second-input="de.json" --force

set "RC=%errorlevel%"
popd
endlocal & exit /b %RC%
