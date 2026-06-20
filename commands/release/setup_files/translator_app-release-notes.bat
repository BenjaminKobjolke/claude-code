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
REM   3. Adjust TRANSLATOR_DIR if the GPT-json-translator checkout moves.

setlocal

set "NOTES_REL=..\assets\release_notes"
set "LANGS="
set "TRANSLATOR_DIR=D:\GIT\BenjaminKobjolke\GPT-json-translator"

REM Resolve the release-notes dir to an absolute path from this bat's location.
set "NOTES_DIR=%~dp0%NOTES_REL%"
for %%I in ("%NOTES_DIR%") do set "NOTES_DIR=%%~fI"

set "LANG_ARG="
if not "%LANGS%"=="" set "LANG_ARG=--languages=%LANGS%"

pushd "%TRANSLATOR_DIR%" || (
    echo ERROR: translator not found at "%TRANSLATOR_DIR%"
    endlocal & exit /b 1
)

call .\.venv\Scripts\python.exe json_translator.py "%NOTES_DIR%" --translate-recursive="en.json" %LANG_ARG%
set "RC=%errorlevel%"

popd
endlocal & exit /b %RC%
