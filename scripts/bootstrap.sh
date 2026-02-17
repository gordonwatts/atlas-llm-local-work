#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

git -C "$repo_root" config core.hooksPath .githooks
git -C "$repo_root" submodule update --init --recursive

bash "$repo_root/scripts/sync-skills.sh"

echo "Bootstrap complete"
