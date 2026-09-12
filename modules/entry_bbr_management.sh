#!/usr/bin/env bash
set -euo pipefail

entry_bbr_management() {
  entry_run_module "$ROOT_DIR/modules/luopo/bbr_management/menu.sh" luopo_bbr_management_menu
}
