#!/usr/bin/env bash
set -euo pipefail

version_file="$(cat VERSION | tr -d '[:space:]')"
if [[ -z "$version_file" ]]; then
  echo "VERSION is empty"
  exit 1
fi

echo "VERSION=$version_file"
