#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/workspace/menu.sh"

entry_workspace_suite() {
  luopo_workspace_menu
}

