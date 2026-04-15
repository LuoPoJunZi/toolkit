#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/basic_tools/menu.sh"

entry_basic_tools() {
  luopo_basic_tools_menu
}

