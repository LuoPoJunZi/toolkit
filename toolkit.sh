#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LANG_CHOICE="${1:-zh}"
if [[ "$LANG_CHOICE" == "en" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/lang/en_US.sh"
else
  # shellcheck disable=SC1091
  source "$ROOT_DIR/lang/zh_CN.sh"
fi
# shellcheck disable=SC1091
source "$ROOT_DIR/core/menu.sh"

main_menu
