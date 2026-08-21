#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

is_core_file() {
  local f="$1"
  [[ "$f" =~ ^core/ ]] && return 0
  [[ "$f" =~ ^modules/ ]] && return 0
  [[ "$f" =~ ^integrations/ ]] && return 0
  [[ "$f" =~ ^lang/ ]] && return 0
  [[ "$f" == "toolkit.sh" ]] && return 0
  [[ "$f" == "install.sh" ]] && return 0
  return 1
}

mapfile -t changed_files < <(git diff-tree --no-commit-id --name-only -r HEAD)

core_changed=0
for f in "${changed_files[@]:-}"; do
  if is_core_file "$f"; then
    core_changed=1
  fi
done

# No version release for non-core changes (e.g. docs only)
if [[ "$core_changed" -eq 0 ]]; then
  echo "No core code changes detected, skip auto release."
  echo "SKIP_RELEASE=1" >>"$GITHUB_ENV"
  exit 0
fi

normalize_release_version() {
  local value="$1"
  local year month day normalized

  if [[ ! "$value" =~ ^[0-9]{2}\.([1-9]|1[0-2])\.([1-9]|[12][0-9]|3[01])$ ]]; then
    return 1
  fi

  IFS='.' read -r year month day <<<"$value"
  normalized="$(date -d "20${year}-${month}-${day}" '+%y.%-m.%-d' 2>/dev/null)" || return 1
  [[ "$normalized" == "$value" ]]
}

release_timestamp="$(git show -s --format=%ct HEAD)"
next_version="${LUOPO_RELEASE_VERSION:-$(TZ=Asia/Shanghai date -d "@${release_timestamp}" '+%y.%-m.%-d')}"
if ! normalize_release_version "$next_version"; then
  echo "Invalid calendar release version: $next_version"
  exit 1
fi
next_tag="v${next_version}"

if git rev-parse "$next_tag" >/dev/null 2>&1; then
  echo "Release $next_tag already exists for today, skip duplicate release."
  echo "SKIP_RELEASE=1" >>"$GITHUB_ENV"
  exit 0
fi

latest_tag="$(git tag --merged HEAD --list 'v*' --sort=-creatordate | head -n1 || true)"
if [[ -n "$latest_tag" ]]; then
  log_range="${latest_tag}..HEAD"
else
  log_range="HEAD"
fi

release_notes_file="$ROOT_DIR/.release-notes.md"
if grep -qFx "## $next_version" CHANGELOG.md; then
  {
    echo "## ${next_tag}"
    awk -v version="$next_version" '
      $0 == "## " version { in_section=1; next }
      in_section && /^## / { exit }
      in_section { print }
    ' CHANGELOG.md
  } >"$release_notes_file"
else
  {
    echo "## ${next_tag}"
    echo
    echo "### 主要变化"
    git log --pretty='- %s (%h)' "$log_range"
  } >"$release_notes_file"

  tmp_changelog="$(mktemp)"
  {
    echo "# Changelog"
    echo
    echo "## ${next_version}"
    echo
    echo "### 主要变化"
    git log --pretty='- %s (%h)' "$log_range"
    echo
    tail -n +3 CHANGELOG.md 2>/dev/null || true
  } >"$tmp_changelog"
  mv "$tmp_changelog" CHANGELOG.md
fi

echo "$next_version" >VERSION

git add VERSION CHANGELOG.md
if ! git diff --cached --quiet; then
  git commit -m "chore(release): ${next_tag}"
fi

{
  echo "SKIP_RELEASE=0"
  echo "NEXT_VERSION=$next_version"
  echo "NEXT_TAG=$next_tag"
  echo "RELEASE_NOTES_FILE=$release_notes_file"
} >>"$GITHUB_ENV"
