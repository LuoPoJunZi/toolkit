#!/usr/bin/env bash
set -euo pipefail

entry_network_test_suite() {
  entry_run_module "$ROOT_DIR/modules/luopo/network_test/menu.sh" luopo_network_test_menu
}
