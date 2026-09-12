#!/usr/bin/env bash
set -euo pipefail

entry_warp_management() {
  entry_run_module "$ROOT_DIR/modules/luopo/warp_management/menu.sh" luopo_warp_management_menu
}
