#!/usr/bin/env bash
set -euo pipefail

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck toolkit.sh core/*.sh modules/*.sh integrations/*.sh scripts/*.sh || true
else
  echo "shellcheck not found, skip"
fi

if command -v shfmt >/dev/null 2>&1; then
  shfmt -w toolkit.sh core/*.sh modules/*.sh integrations/*.sh scripts/*.sh
else
  echo "shfmt not found, skip"
fi
