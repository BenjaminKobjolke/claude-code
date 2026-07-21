---
description: Regenerate the app icon — run tools/create_media/create_app_icon.bat (generate via ai-image-creator + convert to the target format), then verify the app picks it up
---

Regenerate this project's icon. Setup already ran (**`/media:icon-setup`**), so
the config, generator bat, and app wiring exist. This just re-runs generation and
conversion.

## 1. Locate the bat

`<project>/tools/create_media/create_app_icon.bat`. If it is missing, the project
was never set up — run **`/media:icon-setup`** first.

## 2. Optional: adjust the prompt

If the user wants a different icon, edit the `prompt` (and/or `reference_images`,
`size`) in `tools/create_media/create_app_icon.json` before running. Otherwise
run as-is to re-roll the same prompt.

## 3. Run it

The bat cd's into ai-image-creator, generates the PNG into the project, then
converts to the target format. Needs ai-image-creator's `.env` OpenAI key.

```
<project>\tools\create_media\create_app_icon.bat
```

Check the tool output for the saved PNG path and confirm both the PNG and the
converted file (`.ico`/etc.) updated at their configured paths.

## 4. Verify

Run the app → the new icon shows in the window/taskbar (or browser tab). Rebuild
if the packaged exe/app-bundle icon needs refreshing. The wiring itself does not
change — only the image files were replaced.

## Notes

- After editing this command, run `tools/sync_commands_to_codex.bat` in the
  claude-code repo to propagate to Codex as `~/.codex/skills/media-icon-update/SKILL.md`.
