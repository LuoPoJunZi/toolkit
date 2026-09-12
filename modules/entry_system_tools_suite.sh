#!/usr/bin/env bash
set -euo pipefail

entry_system_tools_suite() {
  entry_run_module "$ROOT_DIR/modules/luopo/system_tools/menu.sh" luopo_system_tools_menu
}
