#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/oracle_cloud/menu.sh"

entry_oracle_cloud_suite() {
  luopo_oracle_cloud_menu
}

