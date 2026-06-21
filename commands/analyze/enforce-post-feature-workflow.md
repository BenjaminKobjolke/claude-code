---
description: Ensure project CLAUDE.md mandates running cli-code-analyzer on changed files after each feature / bugfix, and that tools/analyze_changed_and_new_files.bat exists
---

# Enforce Post-Feature Code Analysis Workflow

This skill audits and installs a post-implementation analysis workflow in the current project:

1. Ensures the project `CLAUDE.md` contains a section instructing that after every new feature, finished plan, or fixed bug, the changed-file analyzer must run and reported issues must be fixed.
2. Ensures `tools/analyze_changed_and_new_files.bat` exists and is correct.
3. Ensures the shared `tools/analyze_code_config.bat` exists (reused with `/analyze:setup`).

It does NOT run the analyzer itself. It only installs the workflow so that you (and future Claude sessions) follow it.

---

## Step 1 — Read project CLAUDE.md

- Locate `CLAUDE.md` at the project root. If it does not exist, create it.
- Search for a section that mandates running the analyzer after **any** of: new feature implemented, plan finished, bug fixed.
- Detection cue: a heading containing "Post-Implementation Code Analysis" (or "Code Analysis" / "After Implementation") AND a reference to `tools/analyze_changed_and_new_files.bat`.

If a matching, complete section already exists: skip to Step 3.

## Step 2 — Add or update the CLAUDE.md section

Append (or replace the incomplete section with) this exact block. Replace `{PROJECT_PATH}` with the absolute project path.

````markdown
## Post-Implementation Code Analysis

After **any** of the following events, you MUST run the changed-file analyzer and fix every reported issue before considering the work complete:

- A new feature has been implemented
- A plan from `claude-plans/` has been finished
- A bug has been fixed

### How to run

```bash
powershell -Command "cd '{PROJECT_PATH}'; cmd /c '.\tools\analyze_changed_and_new_files.bat'"
```

This invokes cli-code-analyzer with `--only-changed`, so it reports only on files new or modified vs git `HEAD` (including untracked, excluding deletes).

### Workflow

1. Run the bat above.
2. Read the reports under `code_analysis_results/`. Reports are **per-rule CSV
   files** (one per tool that found issues), e.g. `flutter_analyze.csv`,
   `dart_analyze.csv`, `dart_code_linter.csv`, `line_count_report.csv`,
   `duplicate_code.csv`, `similar_code.csv`. **There is no `.md` report.** A
   missing CSV means that rule found nothing. If the folder contains only
   `_violations_cache.db` (no `.csv`/`.txt` files), the run was **clean** — the
   bat also prints a short "No ... violations found" line to stdout in that case.
3. Fix every error and warning that applies to your changes.
4. Re-run until clean. Only then mark the feature / plan / bugfix as done.

If the bat does not exist, run `/analyze:enforce-post-feature-workflow` to install it.
````

## Step 3 — Check for the bat files

Verify both exist under `tools/`:

- `tools/analyze_changed_and_new_files.bat`
- `tools/analyze_code_config.bat` (shared config used by all analyzer bats in this project)

If both exist, skip to Step 7.

## Step 4 — If `tools/analyze_code_config.bat` is missing, create the config

First detect project language (same heuristic as `/analyze:setup`):

- **Flutter/Dart**: `pubspec.yaml` in project root
- **C#**: `*.csproj` or `*.sln`
- **Python**: `requirements.txt`, `setup.py`, `pyproject.toml`, or `*.py`
- **PHP**: `composer.json` or `*.php`
- **JavaScript/TypeScript**: `package.json` + `*.ts` / `*.js`
- **Svelte**: `*.svelte`
- **AutoHotkey**: `*.ahk` / `*.ah2` / `*.ahk2`

If multiple match, ask the user which to configure.

Ask the user: "What is the absolute path to your cli-code-analyzer project?" (e.g. `D:\GIT\BenjaminKobjolke\cli-code-analyzer`).

Create `tools/analyze_code_config.example.bat`:

```batch
@echo off
REM Copy this file to analyze_code_config.bat and set your local paths
set CLI_ANALYZER_PATH=D:\GIT\BenjaminKobjolke\cli-code-analyzer
set LANGUAGE=python
```

Then create `tools/analyze_code_config.bat` directly with the values the user provided (so they don't have to copy it manually).

## Step 5 — Create `tools/analyze_changed_and_new_files.bat`

Create the `tools/` folder if missing. Write this file exactly:

```batch
@echo off
if not exist "%~dp0analyze_code_config.bat" (
    echo ERROR: analyze_code_config.bat not found.
    echo Copy analyze_code_config.example.bat to analyze_code_config.bat and set your CLI_ANALYZER_PATH and LANGUAGE.
    exit /b 1
)
call "%~dp0analyze_code_config.bat"
cd /d "%~dp0.."

"%CLI_ANALYZER_PATH%\venv\Scripts\python.exe" "%CLI_ANALYZER_PATH%\main.py" --language %LANGUAGE% --path "." --only-changed --verbosity minimal --output "code_analysis_results" --rules "code_analysis_rules.json"

cd /d "%~dp0"
```

Notes:
- `--only-changed` is the git-aware flag in cli-code-analyzer; defaults `--maxamountoferrors` to 5 internally, so it is intentionally omitted.
- The script writes reports to `code_analysis_results/` and reads rules from `code_analysis_rules.json` in the project root.

## Step 6 — If `code_analysis_rules.json` is missing

Do not duplicate rules-file generation here. Tell the user:

> "`code_analysis_rules.json` is missing. Run `/analyze:setup` (full setup) or `/analyze:check-analyzers` to generate one with sensible defaults for your language."

## Step 7 — Confirm

Print a short summary:

- ✓ / ✗ `CLAUDE.md` section present
- ✓ / ✗ `tools/analyze_changed_and_new_files.bat` present
- ✓ / ✗ `tools/analyze_code_config.bat` present
- ✓ / ✗ `code_analysis_rules.json` present

Plus any next steps:

- "Edit `tools/analyze_code_config.bat` if the auto-detected language or analyzer path is wrong."
- "Run `/analyze:setup` if `code_analysis_rules.json` was missing."

---

## Running batch files from Claude Code (reminder)

Claude Code runs in bash; `.bat` files must be invoked via PowerShell:

```bash
powershell -Command "cd 'D:\path\to\project'; cmd /c '.\tools\analyze_changed_and_new_files.bat'"
```

Use timeout ≥ 600000 ms for projects with many files.
