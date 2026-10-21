@echo off
REM Generates non-English release-notes locales from each en.json under the
REM release-notes folder, using GPT-json-translator. Recursive mode skips folders
REM that already have translations, so re-running is safe.
REM
REM SETUP per project:
REM   1. Set NOTES_REL below to the release-notes folder, relative to this bat
REM      (this bat lives in tools\). Examples: ..\assets\release_notes  (Flutter)
REM      or ..\static\release-notes  (web).
REM   2. Optionally pin LANGS to restrict target locales (e.g. "de" or
REM      "de-DE,fr-FR"). Leave empty to use the translator's settings.ini.
REM   3. The translator checkout path comes from tools\config.bat (gitignored,
REM      copy of config_example.bat): set GPT_JSON_TRANSLATOR_DIR there.

setlocal

set "NOTES_REL=..\assets\release_notes"
set "LANGS="
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

REM Resolve the release-notes dir to an absolute path from this bat's location.
set "NOTES_DIR=%~dp0%NOTES_REL%"
for %%I in ("%NOTES_DIR%") do set "NOTES_DIR=%%~fI"

set "LANG_ARG="
if not "%LANGS%"=="" set "LANG_ARG=--languages=%LANGS%"

pushd "%GPT_JSON_TRANSLATOR_DIR%"

call .\.venv\Scripts\python.exe json_translator.py "%NOTES_DIR%" --translate-recursive="en.json" %LANG_ARG%
set "RC=%errorlevel%"

popd
endlocal & exit /b %RC%
