#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
map_file="$repo_root/scripts/skills-map.txt"
skills_dir="$repo_root/.codex/skills"

if [[ ! -f "$map_file" ]]; then
  echo "Missing skill map: $map_file" >&2
  exit 1
fi

git -C "$repo_root" submodule update --init --remote .codex/skill-sources/atlas-skills
mkdir -p "$skills_dir"

while read -r name source_rel; do
  if [[ -z "${name:-}" ]] || [[ "${name:0:1}" == "#" ]]; then
    continue
  fi

  source_path="$repo_root/$source_rel"
  dest_path="$skills_dir/$name"

  if [[ ! -e "$source_path" ]]; then
    echo "Source skill path not found: $source_path" >&2
    exit 1
  fi

  rm -rf "$dest_path"
  ln -s "$source_path" "$dest_path"
  echo "Linked $name -> $source_path"
done < "$map_file"