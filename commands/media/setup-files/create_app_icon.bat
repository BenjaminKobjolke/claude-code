@echo off
REM Generate the app icon via the ai-image-creator project, then convert the PNG
REM to this project's icon format. Needs ai-image-creator's .env OpenAI key set.
setlocal
REM <<< EDIT: absolute path to THIS project
set PROJECT=REPLACE_PROJECT_DIR
REM <<< EDIT: absolute path to the ai-image-creator repo
set AIC=REPLACE_AIC_DIR

REM cd so uv resolves ai-image-creator AND the JSON's relative reference_images resolve.
REM Call by full path — bare "call start.bat" fails when the bat is invoked from PowerShell.
cd /d "%AIC%"
call "%AIC%\start.bat" "%PROJECT%\tools\create_media\create_app_icon.json"
if errorlevel 1 exit /b 1

REM <<< EDIT: convert the PNG to this project's target icon format.
REM Default: a Windows .ico written with the project's own PySide6 (no extra dep).
REM   - Pillow multi-size:  uv run --project "%PROJECT%" python -c "from PIL import Image; Image.open(r'%PROJECT%\assets\icon.png').save(r'%PROJECT%\assets\icon.ico', sizes=[(16,16),(32,32),(48,48),(256,256)])"
REM   - PNG only (web/Flutter/Android): delete the line below, the PNG is the target.
REM   - macOS .icns: use iconutil / a .iconset (not shown here).
uv run --project "%PROJECT%" python -c "from PySide6.QtGui import QImage; QImage(r'%PROJECT%\assets\icon.png').save(r'%PROJECT%\assets\icon.ico')"
