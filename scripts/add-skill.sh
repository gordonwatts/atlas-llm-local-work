#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <github-tree-url> [skill-name]" >&2
  exit 1
fi

url="$1"
name_override="${2:-}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
map_file="$repo_root/scripts/skills-map.txt"

if [[ ! "$url" =~ ^https://github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)$ ]]; then
  echo "Unsupported URL format. Expected https://github.com/<owner>/<repo>/tree/<ref>/<path>" >&2
  exit 1
fi

owner="${BASH_REMATCH[1]}"
repo="${BASH_REMATCH[2]}"
ref="${BASH_REMATCH[3]}"
skill_path="${BASH_REMATCH[4]}"
skill_path="${skill_path#/}"
skill_path="${skill_path%/}"

repo_url="https://github.com/$owner/$repo.git"
submodule_key="$owner-$repo"
skill_name="${name_override:-${skill_path##*/}}"

if [[ ! -d "$repo_root/.git" ]]; then
  echo "Not a git repository root: $repo_root" >&2
  exit 1
fi

submodule_name=""
submodule_rel_path=""
if [[ -f "$repo_root/.gitmodules" ]]; then
  while IFS= read -r line; do
    key="${line%% *}"
    value="${line#* }"
    if [[ "$value" == "$repo_url" ]]; then
      name="${key#submodule.}"
      name="${name%.url}"
      existing_path="$(git -C "$repo_root" config -f .gitmodules --get "submodule.$name.path" || true)"
      if [[ -n "$existing_path" ]]; then
        submodule_name="$name"
        submodule_rel_path="$existing_path"
        break
      fi
    fi
  done < <(git -C "$repo_root" config -f .gitmodules --get-regexp '^submodule\..*\.url$' || true)
fi

if [[ -z "$submodule_rel_path" ]]; then
  submodule_name="$submodule_key"
  submodule_rel_path=".codex/skill-sources/$submodule_key"
fi

source_rel="$submodule_rel_path/$skill_path"
source_path="$repo_root/$source_rel"

if [[ ! -e "$repo_root/$submodule_rel_path" ]]; then
  git -C "$repo_root" submodule add --name "$submodule_key" --branch "$ref" "$repo_url" "$submodule_rel_path"
fi

git -C "$repo_root" config -f .gitmodules "submodule.$submodule_name.branch" "$ref"
git -C "$repo_root" submodule sync -- "$submodule_rel_path"
git -C "$repo_root" submodule update --init --remote "$submodule_rel_path"

if [[ ! -e "$source_path" ]]; then
  echo "Skill path not found in source repo: $source_rel" >&2
  exit 1
fi

touch "$map_file"
tmp_file="$(mktemp)"
found=0

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"
  trimmed="${line#"${line%%[![:space:]]*}"}"
  if [[ -z "$trimmed" || "${trimmed:0:1}" == "#" ]]; then
    printf "%s\n" "$line" >>"$tmp_file"
    continue
  fi

  current_name="${trimmed%%[[:space:]]*}"
  if [[ "$current_name" == "$skill_name" ]]; then
    printf "%s %s\n" "$skill_name" "$source_rel" >>"$tmp_file"
    found=1
  else
    printf "%s\n" "$line" >>"$tmp_file"
  fi
done <"$map_file"

if [[ $found -eq 0 ]]; then
  printf "%s %s\n" "$skill_name" "$source_rel" >>"$tmp_file"
fi

mv "$tmp_file" "$map_file"

bash "$repo_root/scripts/sync-skills.sh"

echo "Added skill '$skill_name' from $url"
