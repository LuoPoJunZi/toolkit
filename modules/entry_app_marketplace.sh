#!/usr/bin/env bash
set -euo pipefail

entry_app_marketplace() {
  entry_run_module "$ROOT_DIR/modules/luopo/app_marketplace/menu.sh" luopo_app_marketplace_menu
}
