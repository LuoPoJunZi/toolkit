#!/usr/bin/env bash
set -euo pipefail

version_file="$(tr -d '[:space:]' <VERSION)"
if [[ -z "$version_file" ]]; then
  echo "VERSION is empty"
  exit 1
fi

if [[ ! "$version_file" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must use semantic version format: $version_file"
  exit 1
fi

if ! grep -qFx "## $version_file" CHANGELOG.md; then
  echo "CHANGELOG.md is missing version $version_file"
  exit 1
fi

echo "VERSION=$version_file"
