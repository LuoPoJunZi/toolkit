#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/system_tools/menu.sh"

entry_system_tools_suite() {
  luopo_system_tools_menu
}

