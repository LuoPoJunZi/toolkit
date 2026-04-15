#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/app_marketplace/menu.sh"

entry_app_marketplace() {
  luopo_app_marketplace_menu
}

