#!/usr/bin/env bash
set -euo pipefail

version_file="$(tr -d '[:space:]' <VERSION)"
if [[ -z "$version_file" ]]; then
  echo "VERSION is empty"
  exit 1
fi

if [[ ! "$version_file" =~ ^[0-9]{2}\.([1-9]|1[0-2])\.([1-9]|[12][0-9]|3[01])$ ]]; then
  echo "VERSION must use YY.M.D calendar format: $version_file"
  exit 1
fi

IFS='.' read -r year month day <<<"$version_file"
normalized_version="$(date -d "20${year}-${month}-${day}" '+%y.%-m.%-d' 2>/dev/null)" || {
  echo "VERSION is not a valid calendar date: $version_file"
  exit 1
}
if [[ "$normalized_version" != "$version_file" ]]; then
  echo "VERSION is not a normalized calendar date: $version_file"
  exit 1
fi

if ! grep -qFx "## $version_file" CHANGELOG.md; then
  echo "CHANGELOG.md is missing version $version_file"
  exit 1
fi

echo "VERSION=$version_file"
