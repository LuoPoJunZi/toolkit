#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

COMMAND="${1:-}"
if [[ "$COMMAND" == "rsync_run" ]]; then
  shift || true
  LANG_CHOICE="zh"
else
  LANG_CHOICE="${1:-zh}"
fi
if [[ "$LANG_CHOICE" == "en" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/lang/en_US.sh"
else
  # shellcheck disable=SC1091
  source "$ROOT_DIR/lang/zh_CN.sh"
fi
# shellcheck disable=SC1091
source "$ROOT_DIR/core/menu.sh"

if [[ "$COMMAND" == "rsync_run" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/modules/luopo/system_tools/menu.sh"
  luopo_system_tools_rsync_run_task push "${1:-}"
  exit 0
fi

main_menu
