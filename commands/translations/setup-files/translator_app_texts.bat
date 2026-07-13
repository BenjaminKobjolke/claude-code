d:
cd "d:\GIT\BenjaminKobjolke\GPT-json-translator"

call activate_environment.bat

REM <<< EDIT: absolute path to THIS project's i18n / locales folder (contains en.json, subfolders OK)
call .\.venv\Scripts\python.exe json_translator.py "D:\GIT\BenjaminKobjolke\your_project\assets\i18n"  --translate-recursive="en.json" --force

REM Enable once de.json exists as a hand-verified reference (improves all other languages):
REM call .\.venv\Scripts\python.exe json_translator.py "D:\GIT\BenjaminKobjolke\your_project\assets\i18n"  --translate-recursive="en.json" --second-input="de.json" --force

cd %~dp0
