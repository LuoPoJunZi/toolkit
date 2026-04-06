#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

latest_tag="$(git tag --list 'v*' --sort=-v:refname | head -n1 || true)"
has_latest_tag=1
if [[ -z "$latest_tag" ]]; then
  has_latest_tag=0
  if [[ -f VERSION ]]; then
    base_version="$(tr -d '[:space:]' < VERSION)"
    if [[ "$base_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      latest_tag="v${base_version}"
    else
      latest_tag="v0.0.0"
    fi
  else
    latest_tag="v0.0.0"
  fi
fi

latest_version="${latest_tag#v}"
IFS='.' read -r major minor patch <<<"$latest_version"
major="${major:-0}"
minor="${minor:-0}"
patch="${patch:-0}"

next_patch=$((patch + 1))
next_version="${major}.${minor}.${next_patch}"
next_tag="v${next_version}"

if git rev-parse "$next_tag" >/dev/null 2>&1; then
  echo "Tag $next_tag already exists, skip."
  exit 0
fi

log_range="${latest_tag}..HEAD"
if [[ "$has_latest_tag" -eq 0 ]]; then
  log_range="HEAD"
fi

release_notes_file="$ROOT_DIR/.release-notes.md"
{
  echo "## ${next_tag}"
  echo
  echo "Auto-generated release."
  echo
  echo "### Changes"
  git log --pretty='- %s (%h)' $log_range
} >"$release_notes_file"

echo "$next_version" > VERSION

tmp_changelog="$(mktemp)"
{
  echo "# Changelog"
  echo
  echo "## ${next_version}"
  echo "- Auto release: ${next_tag}"
  git log --pretty='- %s (%h)' $log_range
  echo
  tail -n +3 CHANGELOG.md 2>/dev/null || true
} >"$tmp_changelog"
mv "$tmp_changelog" CHANGELOG.md

git add VERSION CHANGELOG.md
git commit -m "chore(release): ${next_tag}"

echo "NEXT_VERSION=$next_version" >> "$GITHUB_ENV"
echo "NEXT_TAG=$next_tag" >> "$GITHUB_ENV"
echo "RELEASE_NOTES_FILE=$release_notes_file" >> "$GITHUB_ENV"
