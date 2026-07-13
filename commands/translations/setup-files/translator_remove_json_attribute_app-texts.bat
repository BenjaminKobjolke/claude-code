d:
cd "d:\GIT\BenjaminKobjolke\GPT-json-translator"

call activate_environment.bat

REM 1st arg <<< EDIT: absolute path to THIS project's i18n / locales folder
REM 2nd arg = %~dp0attributes_to_remove.json  (keys to strip; MUST stay 2nd arg or the remover
REM          opens an interactive picker and hangs). Keep this file next to this .bat in tools/.
REM --exclude-source de.json     -> de.json is a hand-verified source, never stripped
REM --exclude-source modules.json -> optional; only if you use a modules.json manifest, else remove
call .\.venv\Scripts\python.exe json_attribute_remover.py ^
  "D:\GIT\BenjaminKobjolke\your_project\assets\i18n" ^
  "%~dp0attributes_to_remove.json" ^
  --recursive --exclude-source de.json --exclude-source modules.json
pause
