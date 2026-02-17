---
name: repo-skill-installer
description: Add a Codex skill from a GitHub tree URL into this repository's cross-platform skill workspace. Use when the user asks to add/install/include a skill from a URL and make it available in .codex/skills on both Windows and Linux/WSL.
---

# Repo Skill Installer

Install external skills into this repository by updating submodules, updating the skill map, and syncing links.

## Workflow

1. Use the user-provided GitHub tree URL in the form `https://github.com/<owner>/<repo>/tree/<ref>/<path>`.
2. Derive the skill name from the last path segment unless the user provides an explicit name.
3. Run one command based on environment:
   - Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/add-skill.ps1 -Url "<url>" [-Name "<skill-name>"]`
   - Linux/WSL: `bash scripts/add-skill.sh "<url>" ["<skill-name>"]`
4. Verify the result:
   - Ensure `scripts/skills-map.txt` has the new entry.
   - Ensure `.codex/skills/<skill-name>` exists and points to the mapped source path.
   - Ensure `.gitmodules` contains a source submodule for the source repository when needed.
5. Summarize created or changed files and suggest committing.

## Notes

- Keep `scripts/skills-map.txt` as the source of truth for exposed skills.
- Preserve cross-platform behavior by using the provided add/sync scripts instead of manual edits.
