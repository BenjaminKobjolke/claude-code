---
description: Setup the release system for this applications
---

Check docs/CREATE_NEW_RELEASE.md if it contains infos how creating new release notes work.
If not ask the user about it.

We need to know which folder the release notes should be created in.
Then check the subfolders how they are named. 
Document the naming structure so that it will be easy to create a new folder.

Within each build folder must be a en.json.
Look at the latest of the existing release folders to figure out the schema of the json.
Write to docs/CREATE_NEW_RELEASE.md how the schema for new files needs to be and in which key the actual release notes information needs to be stored. Also document that only en.json should be created. 

The other languages should be created by a translation tool. 
Check if tools folder contains a bat to do that. If so document that too. Make sure this step is clearly explained in docs/CREATE_NEW_RELEASE.md so it cant be missed.
Otherwhise ask the user if he wants to specify a bat to do that or if he wants to skip that.

You also need to find out how to get the current build number, increment the build number and decrement the build number. There must be bat files for that in the tools folder.
If not figure out how it works in this application and make a plan to create those files.
Then save the information about that to docs/CREATE_NEW_RELEASE.md too.

There should also be an automated way to add the release notes to the final build. It would be great if the release_notes folder could be packaged with the application and not just copied to the release folder. If that feature does not exist create a plan to implement it and suggest that to the user.

## In-app release notes view

Each app MUST have a dedicated view/screen to display release notes. Ask the user where in the app they want the release notes view placed (e.g., settings, about screen, main menu, etc.).

If no release notes view exists, create a plan to implement one following these rules:
- Always show the newest release notes first
- Provide back/forth navigation to view older release notes
- Depending on the type of application, consider using a scrollable view that loads older release notes as the user scrolls down (better for mobile/touch apps)

Document the view location in `docs/CREATE_NEW_RELEASE.md`. If the view already exists, document its location as well.

The actual creating of release notes is not part of this task.
But when you are done you can check [create-release-notes.md](create-release-notes.md) and check if you would be able to create the release notes that way.

When the release notes are created we need to build the actual new version.
Check the tools folder for available bat files. If there are multiple ones ask the user which ones are used for releases. Then also document how to create a new release in  $CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md

When done $CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md should contain:
- how to get the version number
- how to increment the version number
- how to create a new release notes directory and en.json file
- how to actually build a new release
- where the in-app release notes view is located and how it works

## Established conventions (defaults when nothing exists yet)

When a project has no release system, set it up with these conventions (proven in
`pdf-toolkit`). Reusable templates live in
`coding-rules/python_setup_files/` (Python) — copy them instead of reinventing.

- **Release label** = `<version>_<build>` (e.g. `0.1.0_22`).
  - `version` = the project's existing semver source of truth (e.g. `pyproject.toml`
    `[project] version`). Bump by hand.
  - `build` = a plain integer stored in **`build_version.txt`** at the **project root**.
    Get/increment/decrement via `tools/build_get.bat`, `tools/build_increment.bat`,
    `tools/build_decrement.bat`. `tools/version_get.bat` prints the full label.
- **Release notes folder** = `release_notes/<version>_<build>/`, one JSON file per
  locale. Schema:
  ```json
  {"version": "0.1.0", "build": 22, "date": "YYYY-MM-DD", "title": "Headline",
   "notes": ["bullet one", "bullet two"]}
  ```
  The actual release text is the **`notes`** array. Author **only `en.json`**.
- **Translation step is mandatory** and must be impossible to miss: after writing
  `en.json`, run the project's translation bat (ask the user for its path if none
  exists) to generate the other locales from the English source.
- **Bundle `release_notes/` into the build** (don't just copy it beside the exe), so
  the in-app view ships with the binary. For PyInstaller add it (and `build_version.txt`)
  to the spec `datas`, plus `copy_metadata(<pkg>)` so the version is readable when frozen.
- **In-app view** loads all releases, sorts **newest first**, shows the latest first
  with Older/Newer navigation, and falls back to `en.json` when a locale is missing.