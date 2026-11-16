"""Ask which Claude command categories to install."""

import json
import os
import subprocess
import sys
import tempfile
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from unittest.mock import patch

from command_categories import (
    CATEGORIES_FILE,
    COMMANDS_DIR,
    SELECTION_FILE,
    list_categories,
    load_descriptions,
    load_selection,
    save_selection,
    selected_categories,
)


def is_link(path):
    """Return whether a path is a symbolic link or a Windows junction."""
    path = Path(path)
    return path.is_symlink() or (
        hasattr(path, "is_junction") and path.is_junction()
    )


def link_dir(source, target):
    """Create a directory symlink, falling back to a Windows junction."""
    source = Path(source).resolve()
    target = Path(target)
    try:
        target.symlink_to(source, target_is_directory=True)
    except OSError:
        if os.name != "nt":
            raise
        result = subprocess.run(
            ["cmd", "/c", "mklink", "/J", str(target), str(source)],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode:
            detail = (result.stderr or result.stdout).strip()
            raise OSError(detail or f"could not create directory junction: {target}")


def remove_link(path):
    """Remove one directory link without traversing or deleting its target."""
    path = Path(path)
    if path.is_symlink():
        path.unlink()
    else:
        path.rmdir()


def apply_links(selected, commands_dir=COMMANDS_DIR, install_dir=None):
    """Apply selected category links while preserving real user directories."""
    commands_dir = Path(commands_dir).resolve()
    install_dir = (
        Path.home() / ".claude" / "commands"
        if install_dir is None
        else Path(install_dir)
    )
    available = list_categories(commands_dir)
    selected = set(selected) & set(available)
    installed = 0
    removed = 0

    if is_link(install_dir):
        if install_dir.resolve() == commands_dir:
            remove_link(install_dir)
        else:
            print(f"Warning: preserving unrelated link at {install_dir}")
            return installed, removed
    elif install_dir.exists() and not install_dir.is_dir():
        print(f"Warning: preserving non-directory path at {install_dir}")
        return installed, removed

    install_dir.mkdir(parents=True, exist_ok=True)
    for category in available:
        target = install_dir / category
        source = commands_dir / category
        if is_link(target):
            if category in selected and target.resolve() == source.resolve():
                continue
            remove_link(target)
            if category not in selected:
                removed += 1
                continue
        elif target.exists():
            print(f"Warning: preserving user path at {target}")
            continue

        if category in selected:
            link_dir(source, target)
            installed += 1
    return installed, removed


def ask(prompt, input_fn=None):
    """Read one answer and signal the watcher immediately before input()."""
    if os.environ.get("TICKETS_WATCHER_COMMAND_RUN") == "1":
        print("::tw-input-line::", flush=True)
    reader = input if input_fn is None else input_fn
    return reader(prompt)


def ask_yes_no(prompt, default=True, input_fn=None):
    """Ask a yes/no question, using the supplied answer when input is empty."""
    suffix = "[Y/n]" if default else "[y/N]"
    while True:
        answer = ask(f"{prompt} {suffix} ", input_fn).strip().lower()
        if not answer:
            return default
        if answer in {"y", "yes"}:
            return True
        if answer in {"n", "no"}:
            return False
        print("Please answer y or n.")


def choose(categories, descriptions, current_selection=None, input_fn=None):
    """Prompt for each category, defaulting to saved choices or all on first run."""
    selected = []
    for category in categories:
        default = current_selection is None or category in current_selection
        prompt = f"{category}: {descriptions[category]}"
        if ask_yes_no(prompt, default, input_fn):
            selected.append(category)
    return selected


def self_test():
    categories = ["analyze", "git"]
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        descriptions_file = root / "categories.json"
        descriptions_file.write_text(
            json.dumps({"analyze": "Review code.", "git": "Manage Git."}),
            encoding="utf-8",
        )
        assert load_descriptions(categories, descriptions_file) == {
            "analyze": "Review code.", "git": "Manage Git."
        }
        assert_value_error(lambda: load_descriptions(
            categories, root / "missing-descriptions.json"
        ))
        descriptions_file.write_text('{"analyze": "Review code."}', encoding="utf-8")
        assert_value_error(lambda: load_descriptions(categories, descriptions_file))
        descriptions_file.write_text(
            json.dumps({"analyze": "Review code.", "git": "Manage Git."}),
            encoding="utf-8",
        )

        selection_file = root / "installed_categories.json"
        assert load_selection(selection_file) is None
        assert selected_categories(categories, selection_file) == categories
        save_selection(["git"], selection_file)
        assert load_selection(selection_file) == ["git"]
        assert selected_categories(categories, selection_file) == ["git"]
        selection_file.write_text('{"categories": ["git", "git"]}', encoding="utf-8")
        assert_value_error(lambda: load_selection(selection_file))
        selection_file.write_text("not JSON", encoding="utf-8")
        assert_value_error(lambda: load_selection(selection_file))
        commands_dir = root / "commands"
        for category in categories:
            category_dir = commands_dir / category
            category_dir.mkdir(parents=True)
            (category_dir / "command.md").write_text(category, encoding="utf-8")
        install_dir = root / "claude" / "commands"
        install_dir.parent.mkdir(parents=True)
        link_dir(commands_dir, install_dir)
        assert is_link(install_dir)
        assert apply_links(categories, commands_dir, install_dir) == (2, 0)
        assert install_dir.is_dir() and not is_link(install_dir)
        assert is_link(install_dir / "analyze")
        assert is_link(install_dir / "git")
        assert (install_dir / "analyze" / "command.md").read_text(
            encoding="utf-8"
        ) == "analyze"
        assert apply_links(["git"], commands_dir, install_dir) == (0, 1)
        assert not (install_dir / "analyze").exists()
        assert is_link(install_dir / "git")
        assert (commands_dir / "analyze" / "command.md").is_file()
        preserved_dir = install_dir / "analyze"
        preserved_dir.mkdir()
        marker_file = preserved_dir / "user-file.txt"
        marker_file.write_text("keep", encoding="utf-8")
        with patch(__name__ + ".print") as print_mock:
            assert apply_links(categories, commands_dir, install_dir) == (0, 0)
        assert marker_file.read_text(encoding="utf-8") == "keep"
        assert any(
            "preserv" in str(call).lower() for call in print_mock.call_args_list
        )

    for watcher_mode, expected_marker in (("1", True), ("0", False)):
        output = StringIO()
        with patch.dict(
            os.environ, {"TICKETS_WATCHER_COMMAND_RUN": watcher_mode}, clear=False
        ):
            with patch("builtins.input", return_value="y"):
                with redirect_stdout(output):
                    ask("Continue?")
        assert ("::tw-input-line::" in output.getvalue()) is expected_marker

    answers = iter(("", "n"))
    assert ask_yes_no("First?", default=True, input_fn=lambda _: next(answers)) is True
    assert (
        ask_yes_no("Second?", default=True, input_fn=lambda _: next(answers))
        is False
    )
    answers = iter(("maybe", "yes"))
    assert ask_yes_no("Retry?", default=False, input_fn=lambda _: next(answers)) is True
    prompts = []
    selected = choose(
        categories,
        {"analyze": "Review code.", "git": "Manage Git."},
        ["git"],
        input_fn=lambda prompt: prompts.append(prompt) or "",
    )
    assert (
        len(prompts) == 2
        and "Review code." in prompts[0]
        and "Manage Git." in prompts[1]
    )
    assert "[y/N]" in prompts[0] and "[Y/n]" in prompts[1]
    assert selected == ["git"]

    output = StringIO()
    with patch.multiple(
        __name__,
        list_categories=lambda *_: categories,
        load_descriptions=lambda *_: {},
        load_selection=lambda *_: None,
        choose=lambda *_: ["git"],
        save_selection=lambda *_: None,
        apply_links=lambda *_: (1, 0),
    ):
        with patch(__name__ + ".ask_yes_no", return_value=False) as sync_prompt:
            with redirect_stdout(output):
                assert main() == 0
        sync_prompt.assert_called_once_with("Sync to Codex now?", default=True)
    assert "Installed 1 category link(s); removed 0." in output.getvalue()

    with patch("builtins.print"):
        with patch(
            __name__ + ".list_categories",
            side_effect=ValueError("bad categories"),
        ):
            assert main() == 1
        with patch(__name__ + ".list_categories", side_effect=OSError("unavailable")):
            assert main() == 1
    print("self-test OK")


def assert_value_error(callback):
    """Assert one callback rejects invalid input."""
    try:
        callback()
    except ValueError:
        return
    raise AssertionError("expected ValueError")


def main():
    """Install selected category links and optionally sync Codex skills."""
    try:
        categories = list_categories(COMMANDS_DIR)
        descriptions = load_descriptions(categories, CATEGORIES_FILE)
        current_selection = load_selection(SELECTION_FILE)
        selected = choose(categories, descriptions, current_selection)
        save_selection(selected, SELECTION_FILE)
        installed, removed = apply_links(selected, COMMANDS_DIR)
    except (OSError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(f"Installed {installed} category link(s); removed {removed}.")
    print("Restart Claude Code to load the command changes.")
    if ask_yes_no("Sync to Codex now?", default=True):
        from sync_commands_to_codex import sync

        sync()
    else:
        print("Skipped Codex sync.")
    return 0


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
    else:
        raise SystemExit(main())
