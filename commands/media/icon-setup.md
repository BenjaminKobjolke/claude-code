---
description: Scaffold AI icon generation for a project — create create_app_icon.json + .bat in tools/create_media, generate the icon via ai-image-creator, convert to the project's icon format, and wire the app to use it
---

Stand up icon generation for the current project. The **ai-image-creator** repo
generates a PNG from a prompt; this command scaffolds the per-project config,
runs it once, converts the PNG to the project's target format, and wires the app
to actually use the icon.

## Prerequisites (one-time, machine-wide)

- **ai-image-creator** cloned (default `D:\GIT\BenjaminKobjolke\ai-image-creator`),
  its `install.bat` run, and its `.env` holding a valid `OPENAI_API_KEY`.
  The key stays in ai-image-creator's `.env` — never copy it into a project.

## 1. Gather inputs (ask the user)

- **ai-image-creator path** — default `D:\GIT\BenjaminKobjolke\ai-image-creator`.
- **Icon description** — the prompt (draft one from the app's purpose if they have none).
- **Target icon format** — infer from the project, confirm with the user:
  | Project type | Runtime icon | Packaged/build icon |
  |---|---|---|
  | PySide6/PyQt/Tkinter + PyInstaller (Windows) | `.png` via `QIcon` | `.ico` |
  | Electron | `.png` | `.ico` (win) + `.icns` (mac) |
  | Flutter / Android | PNG set (`flutter_launcher_icons`) | — |
  | Web / favicon | `.png` / `.svg` | `.ico` |
  | macOS app | — | `.icns` |

## 2. Scaffold `tools/create_media/`

Create the folder in the current project and copy both templates from this
command's `setup-files/`:
- `create_app_icon.json`
- `create_app_icon.bat`

Then replace the placeholders:
- **`create_app_icon.json`** — `REPLACE_PROJECT_DIR` → the project's absolute path
  (use forward slashes; e.g. `D:/GIT/.../myapp`). Set the `prompt`. Set `output`
  `path` to where the icon lives (default `<project>/assets/icon.png`; match the
  project's convention). `reference_images` are optional and resolve **relative to
  ai-image-creator's** dir — leave `[]` or point at its `examples/media/*.png` for
  style matching.
- **`create_app_icon.bat`** — set `PROJECT` (backslash absolute path) and `AIC`.
  Edit the final conversion line for the target format (the template comments list
  the .ico / Pillow multi-size / PNG-only / .icns options). Delete the conversion
  line entirely if the target is just PNG.

## 3. Generate + convert (first run)

Run the bat (needs ai-image-creator's key). It cd's into ai-image-creator, calls
`start.bat` with the JSON, writes the PNG to the project, then converts:

```
<project>\tools\create_media\create_app_icon.bat
```

Confirm the PNG (and converted file, if any) appear at the configured paths.
If the user already has an icon PNG, skip generation — just place it at the
`output.path` and run only the conversion line.

## 4. Wire the app to use the icon

Make the app actually load it — per project type:

- **PySide6/PyQt** — after `app = QApplication(...)`:
  `app.setWindowIcon(QIcon(str(icon_png)))`, existence-guarded. Resolve the path
  with the project's frozen-safe idiom (e.g. `Path(__file__).resolve().parent / "assets" / "icon.png"`).
- **PyInstaller build** — add `--icon assets\icon.ico` and, if the runtime loads a
  bundled PNG, `--add-data "assets;assets"` so the file ships in the onefile.
- **Electron** — `BrowserWindow({ icon })` + electron-builder `build.win.icon` / `build.mac.icon`.
- **Flutter** — configure `flutter_launcher_icons` and run it.
- **Web** — link the favicon in HTML `<head>`.

Match the project's existing resource-path conventions rather than inventing new ones.

## 5. Verify

- Run the app → the window/taskbar (or browser tab) shows the icon.
- If it packages, build and confirm the exe/app-bundle icon.

## Daily use

To regenerate later (edited prompt, new style), use **`/media:icon-update`** — it
just re-runs the bat (generate + convert). The wiring from step 4 stays.

## Notes

- After editing this command or its templates, run `tools/sync_commands_to_codex.bat`
  in the claude-code repo to propagate to Codex as `~/.codex/skills/media-icon-setup/SKILL.md`.
