#!/usr/bin/env bash
set -euo pipefail

entry_workspace_suite() {
  entry_run_module "$ROOT_DIR/modules/luopo/workspace/menu.sh" luopo_workspace_menu
}
