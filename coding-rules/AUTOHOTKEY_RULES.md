# AutoHotkey Rules (v1)

See `COMMON_RULES.md` for rules that apply to all languages. The rules below add the
AutoHotkey-specific guidance. They target **AutoHotkey v1.x** (the version these tools are
written in); where v2 behaves differently it is flagged inline with a **v2 note**.

---

## Single-Instance Toggle — Run Once Starts, Run Again Exits

This is the headline rule for any script that keeps running (persistent hotkey scripts, tray
tools, watchers): **launching it the first time starts it; launching it again exits the running
instance.** No second copy ever runs in parallel, and the same shortcut both starts and stops it.

Implement it with the shared `SingleInstance.ahk` library (COM active-object based), not with
AHK's built-in `#SingleInstance`:

```autohotkey
#NoEnv
SendMode Input
#SingleInstance off          ; toggle is handled by the library, NOT by AHK
#Persistent
SetWorkingDir %A_ScriptDir%

#Include %A_ScriptDir%\_libraries\SingleInstance.ahk

class MaximizeObject {
    __New() {
        ; startup work — runs only on the first launch
    }
    IsActive() {
        return true
    }
    Quit() {
        ; shutdown work — runs when a second launch finds this instance
        ExitApp
    }
}

CheckSingleInstance("{B8E2A3F7-9D4C-4A1E-8F5B-6C7D8E9F0A1B}", "MaximizeObject")
```

How it works:

- Each script defines a class with `__New()` (startup), `IsActive()` (returns `true`), and
  `Quit()` (shutdown + `ExitApp`).
- `CheckSingleInstance(GUID, "ClassName")` looks for an already-registered COM object under the
  GUID. If found, it calls that instance's `Quit()` and exits — so the **second** launch tells
  the **first** to shut down, and both processes end. If none is found, it constructs and
  registers the object, and the script keeps running.
- Every script MUST use its **own unique GUID**. Reusing another script's GUID makes the two
  scripts kill each other. Generate a fresh one per script.

Why: a single shortcut becomes an on/off toggle, duplicate instances can't fight over the same
hotkeys or resources, and shutdown is centralized in `Quit()`.

**v2 note:** `new %Class%()`, `ComObjActive`, and `VarSetCapacity` in the library are v1-only.
A v2 port needs a rewrite. For simple cases that only need "no duplicates" (without the
relaunch-to-exit behavior), v2's `#SingleInstance Force` plus a named mutex is enough.

---

## Standard Script Header

Start every script with the same directives so behavior is predictable:

```autohotkey
#NoEnv                       ; recommended for performance and compatibility
SendMode Input               ; faster, more reliable Send
#SingleInstance off          ; the library owns instance handling (see above)
#Persistent                  ; keep running after the auto-execute section
SetWorkingDir %A_ScriptDir%  ; relative paths resolve against the script, not the caller
```

`#Persistent` is required for hotkey/tray scripts so they don't exit after the auto-execute
section. One-shot scripts (do a job and quit) omit `#Persistent` and the single-instance block.

**v2 note:** `#NoEnv` and `SendMode Input` are defaults in v2 and can be dropped; `SetWorkingDir
A_ScriptDir` loses the `%...%`.

---

## Project Structure

```
my-ahk-tools/
├── _libraries/             # shared code, #Include'd by scripts (underscore sorts to top)
│   ├── SingleInstance.ahk
│   └── Log.ahk
├── maximize.ahk            # one script = one responsibility
├── downloads_launcher.ahk
├── settings.ini            # machine-specific paths/values (not hardcoded in scripts)
├── docs/
│   └── MAXIMIZE.md
└── README.md
```

Scripts live at the root; shared helpers live in `_libraries\`. The underscore prefix keeps the
library folder at the top of the listing.

---

## Reuse via `#Include`

Shared logic belongs in `_libraries\` and is pulled in with an `%A_ScriptDir%`-anchored include:

```autohotkey
#Include %A_ScriptDir%\_libraries\SingleInstance.ahk
```

Never copy-paste a helper function between scripts — extract it into `_libraries\` and include it
in both. This is the AutoHotkey form of the common **DRY** rule.

---

## Tray Menu Convention

Persistent scripts get a consistent tray menu — strip the standard items, then offer Reload and
Exit:

```autohotkey
Menu, tray, NoStandard
Menu, tray, add                 ; separator
Menu, tray, add, Reload, TrayReload
Menu, tray, add, Exit, TrayExit

TrayReload:
    Reload
return

TrayExit:
    ExitApp
return
```

Pair this with an `OnExit` handler that **revokes the single-instance registration** before the
process dies, so a later relaunch starts cleanly instead of finding a stale slot:

```autohotkey
OnExit("Revoke")

Revoke(ExitReason, ExitCode) {
    global ActiveObject
    ObjRegisterActive(ActiveObject, "")   ; unregister the COM active object
}
```

---

## Configuration over Hardcoded Paths

Do not bake machine-specific paths or values into scripts (e.g. `E:\downloads`, a 7-Zip install
path). Read them from a `settings.ini` next to the script at startup:

```autohotkey
IniRead, DownloadsDir, %A_ScriptDir%\settings.ini, Paths, DownloadsDir, E:\downloads
```

Keep the per-script GUID as a clearly labelled constant near the top of the file. This is the
AutoHotkey form of the common **String Constants** / centralized-configuration rule: one place to
change a value, and the script is portable to another machine by editing the `.ini` only.

---

## Logging Strategy

Don't scatter `MsgBox` calls for debugging. Use a single logger module in `_libraries\` (e.g.
`Log.ahk`) that writes to a file and is gated by one `debug` flag, so logging has a single
off switch — the AutoHotkey form of the common **centralized-logger** rule:

```autohotkey
; _libraries\Log.ahk
Log(msg) {
    global DebugEnabled
    if (!DebugEnabled)
        return
    FileAppend, % A_Now . "  " . msg . "`n", %A_ScriptDir%\log.txt
}
```

Reserve `MsgBox` for genuine user-facing prompts (confirmations, errors the user must see), not
for tracing what the script is doing.

---

## Naming & File Length

The common rules apply directly:

- **Max 300 lines per file** — split a growing script into modules under `_libraries\` and
  `#Include` them.
- **Descriptive names** for functions, labels, and hotkey handlers (`MoveWindowTo`, not `mw`).
- **One script = one responsibility.** A script that maximizes windows does not also launch
  downloads; that's a second script with its own GUID.

---

## Project Setup Scripts

Copy the setup files from:
`D:\GIT\BenjaminKobjolke\claude-code\coding-rules\autohotkey_setup_files`

### _libraries/SingleInstance.ahk

The COM-based single-instance library (`ObjRegisterActive` + `CheckSingleInstance`). Drop it into
the project's `_libraries\` folder and `#Include` it — this is what powers the run-once-starts,
run-again-exits toggle.

### template.ahk

A skeleton script with the standard header, the `#Include`, a sample single-instance class, a
placeholder GUID, the tray menu, and the `OnExit`/revoke handler. Copy it, rename it, replace the
GUID and class name, and add hotkeys — the fastest correct starting point for a new script.
