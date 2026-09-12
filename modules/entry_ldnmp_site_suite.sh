#!/usr/bin/env bash
set -euo pipefail

entry_ldnmp_site_suite() {
  entry_run_module "$ROOT_DIR/modules/luopo/ldnmp/menu.sh" luopo_ldnmp_menu
}
