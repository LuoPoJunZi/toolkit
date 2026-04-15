#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/bbr_management/menu.sh"

entry_bbr_management() {
  luopo_bbr_management_menu
}

