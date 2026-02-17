# atlas-llm-local-work

This repository is a local Codex skill workspace.

It keeps skill sources under `.codex/skill-sources/` (Git-backed), and exposes ready-to-use skills at `.codex/skills/` via links so Codex can load them directly.

On `git pull`/checkout, repository hooks run the sync scripts to:

- update skill source submodules to their tracked branch heads
- refresh links in `.codex/skills/`

This is configured to work on both:

- Windows (PowerShell script)
- Linux/WSL2 (bash script)

## Clone Setup

After cloning, run one bootstrap command:

- Windows:
  `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/bootstrap.ps1`
- Linux/WSL2:
  `bash scripts/bootstrap.sh`

This configures Git hooks, initializes submodules, and syncs `.codex/skills/`.

## Add External Skills

Add a skill from a GitHub tree URL:

- Windows:
  `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/add-skill.ps1 -Url "https://github.com/<owner>/<repo>/tree/<ref>/<path>"`
- Linux/WSL2:
  `bash scripts/add-skill.sh "https://github.com/<owner>/<repo>/tree/<ref>/<path>"`

Optional explicit skill name:

- Windows: add `-Name "<skill-name>"`
- Linux/WSL2: add a second argument `"<skill-name>"`

## Skills TOC

Skill entries are defined in:

`scripts/skills-map.txt`

That file is the source of truth for which skills are exposed in `.codex/skills/`.
