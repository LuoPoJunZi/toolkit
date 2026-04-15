#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/network_test/menu.sh"

entry_network_test_suite() {
  luopo_network_test_menu
}

