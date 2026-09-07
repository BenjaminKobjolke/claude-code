---
description: Upgrade the project to uv
---

Upgrade this project to uv and apply our coding rules.

The rules moved into the coding-rules plugin — run `/coding-rules:apply` for
`CODING_RULES.md` + the `CLAUDE.md` pointer instead of copying rule files by hand.
Source rules and the setup-file templates live at
`D:\GIT\BenjaminKobjolke\claude-coding-rules\plugins\coding-rules\rules\`
(`COMMON_RULES.md`, `PYTHON_RULES.md`, `python_setup_files/`).

Migration checklist:

1. `pyproject.toml` — direct deps only (drop transitive pins from `requirements.txt`, and
   drop packages nothing imports), `requires-python = ">=3.11,<3.13"`, dev group with
   `ruff`, `mypy`, `pytest`. Applications set `[tool.uv] package = false` so uv does not
   try to build a wheel from a non-package `src/` layout.
2. CUDA torch is not on PyPI — pin the index explicitly, or `uv lock` silently resolves
   the CPU build:
   ```toml
   [tool.uv.sources]
   torch = { index = "pytorch-cu118" }
   [[tool.uv.index]]
   name = "pytorch-cu118"
   url = "https://download.pytorch.org/whl/cu118"
   explicit = true
   ```
   Verify with `grep 'source = ' uv.lock` and a `torch.cuda.is_available()` smoke run.
3. `uv lock` + `uv sync --all-extras`.
4. Copy the bats from `python_setup_files/` (`install.bat`, `update.bat`,
   `tools/run_tests.bat`, `tools/run_integration_tests.bat`), retitle them, and write
   `start.bat` (rules require it in the root). Delete the pip-era `run.bat`,
   `activate_environment.bat`, `requirements.txt`, and the old `venv/`.
5. Delete a legacy `.clinerules` if it mandates pip/venv/requirements.txt — it will tell the
   next agent to undo the migration.
6. `uv run ruff check --fix`, `uv run ruff format`, then fix what is left by hand.
7. `uv run mypy src/` — do NOT pin `python_version` in `[tool.mypy]`. A pin below the
   interpreter uv resolved makes mypy reject the installed numpy stubs with
   `Type statement is only supported in Python 3.12 and greater`.
8. Tests are mandatory: `tests/unit/` + `tests/integration/`; point `tools/run_tests.bat`
   at `tests/unit`. Integration tests that shell out to an external binary should
   `pytest.mark.skipif(shutil.which("ffmpeg") is None, ...)`.
9. Update `README.md` (uv install/run/test) and add `coding-rules.json` to `.gitignore` —
   it stores a machine-specific `pluginRoot`.

Gotchas:

- Ruff's formatter explodes a multi-line `subprocess.run([...])` command into one token per
  line. `shlex.split("ffmpeg -y -i ...")` stays readable and does not trip `SIM905` the way
  `"...".split()` does.
- Writing `"\r\n"` through `Path.write_text` on Windows produces `\r\r\n` (text mode adds its
  own translation). Use `write_bytes`, or write `\n` and let text mode convert.
