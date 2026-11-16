"""Load command categories, their descriptions, and the per-machine selection."""

import json
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
REPO_DIR = TOOLS_DIR.parent
COMMANDS_DIR = REPO_DIR / "commands"
CATEGORIES_FILE = COMMANDS_DIR / "categories.json"
SELECTION_FILE = TOOLS_DIR / "installed_categories.json"


def list_categories(commands_dir=COMMANDS_DIR):
    """Return sorted folders that contain at least one command Markdown file."""
    root = Path(commands_dir)
    if not root.is_dir():
        raise ValueError(f"commands directory not found: {root}")
    return sorted(
        folder.name
        for folder in root.iterdir()
        if folder.is_dir()
        and any(path.name != "CLAUDE.md" for path in folder.glob("*.md"))
    )


def load_descriptions(categories=None, descriptions_file=CATEGORIES_FILE):
    """Load descriptions and fail when an installed category has no description."""
    path = Path(descriptions_file)
    try:
        descriptions = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        message = f"could not load category descriptions from {path}: {error}"
        raise ValueError(message) from error
    if not isinstance(descriptions, dict) or any(
        not isinstance(name, str)
        or not isinstance(description, str)
        or not description.strip()
        for name, description in descriptions.items()
    ):
        raise ValueError(
            f"category descriptions in {path} must map names to non-empty strings"
        )

    required = list_categories() if categories is None else list(categories)
    missing = sorted(set(required) - descriptions.keys())
    if missing:
        raise ValueError(f"missing descriptions for categories: {', '.join(missing)}")
    return descriptions


def load_selection(selection_file=SELECTION_FILE):
    """Return the saved category list, or None when no selection exists yet."""
    path = Path(selection_file)
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        message = f"could not load category selection from {path}: {error}"
        raise ValueError(message) from error
    if not isinstance(data, dict) or set(data) != {"categories"}:
        raise ValueError(
            f"category selection in {path} must contain only a categories list"
        )
    categories = data["categories"]
    if (
        not isinstance(categories, list)
        or any(not isinstance(category, str) or not category for category in categories)
        or len(categories) != len(set(categories))
    ):
        raise ValueError(
            f"categories in {path} must be a list of unique non-empty names"
        )
    return categories


def save_selection(categories, selection_file=SELECTION_FILE):
    """Validate and save selected category names in a stable order."""
    if (
        not isinstance(categories, (list, tuple, set))
        or any(not isinstance(category, str) or not category for category in categories)
        or len(categories) != len(set(categories))
    ):
        raise ValueError("categories must contain unique non-empty names")
    path = Path(selection_file)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps({"categories": sorted(categories)}, indent=2) + "\n",
        encoding="utf-8",
    )


def selected_categories(categories=None, selection_file=SELECTION_FILE):
    """Return selected names that still exist, defaulting to all available names."""
    available = list_categories() if categories is None else list(categories)
    selection = load_selection(selection_file)
    if selection is None:
        return available
    selected = set(selection)
    return [category for category in available if category in selected]
