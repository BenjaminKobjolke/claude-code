---
description: Setup the release notes system
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

The actual creating of release notes is not part of this task.
But when you are done you can check [create-release-notes.md](create-release-notes.md) and check if you would be able to create the release notes that way.

When the release notes are created we need to build the actual new version.
Check the tools folder for available bat files. If there are multiple ones ask the user which ones are used for releases. Then also document how to create a new release in  $CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md

When done $CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md should contain:
- how to get the version number
- how to increment the version number
- how to create a new release notes directory and en.json file
- how to actually build a new release