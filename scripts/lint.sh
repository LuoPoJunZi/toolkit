#!/usr/bin/env bash
set -euo pipefail

mapfile -t shell_files < <(git ls-files '*.sh')

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${shell_files[@]}" || true
else
  echo "shellcheck not found, skip"
fi

if command -v shfmt >/dev/null 2>&1; then
  shfmt -w "${shell_files[@]}"
else
  echo "shfmt not found, skip"
fi
