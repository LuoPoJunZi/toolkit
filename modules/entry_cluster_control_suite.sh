#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/cluster_control/menu.sh"

entry_cluster_control_suite() {
  luopo_cluster_control_menu
}

