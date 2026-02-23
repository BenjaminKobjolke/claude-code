---
description: Generate plain URLs to view commits on the remote hosting platform
---

Generate plain URLs to view commits on the remote hosting platform.

## Input

`$ARGUMENTS` can be:

1. **Empty** — default to HEAD.
2. **Commit hashes** — one or more, separated by spaces or commas.
3. **Natural language** — e.g., "last 5 commits", "today's commits", "commits since yesterday". Interpret the intent and use the appropriate git command to resolve the hashes (e.g., `git log -5 --format="%H"`, `git log --since="yesterday" --format="%H"`).

To distinguish: if all non-empty segments look like hex strings (4+ hex chars), treat them as commit hashes. Otherwise, interpret as natural language.

## Procedure

1. Resolve the list of commit hashes from the input (see above).

2. Get the remote URL:
   ```bash
   git remote get-url origin
   ```

3. Parse the remote URL into a base web URL:
   - SSH format `git@host:owner/repo.git` -> `https://host/owner/repo`
   - HTTPS format `https://host/owner/repo.git` -> `https://host/owner/repo`
   - HTTPS with port `https://host:port/owner/repo.git` -> `https://host:port/owner/repo`
   - Strip trailing `.git` if present
   - Preserve custom ports (e.g., `:3030`) in the URL

4. For each commit hash:
   - Resolve to short form via `git rev-parse --short <hash>`
   - Construct the commit URL based on the platform:

   | Platform | URL pattern |
   |----------|-------------|
   | GitHub (`github.com`) | `{base}/commit/{hash}` |
   | GitLab (`gitlab.com` or self-hosted) | `{base}/-/commit/{hash}` |
   | Bitbucket (`bitbucket.org`) | `{base}/commits/{hash}` |
   | Azure DevOps (`dev.azure.com`) | `{base}/commit/{hash}` |
   | Gitea / Forgejo (self-hosted) | `{base}/commit/{hash}` |
   | Default (unknown host) | `{base}/commit/{hash}` |

5. Output each URL on its own line. No markdown formatting, no extra text.
