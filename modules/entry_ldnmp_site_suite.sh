#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/ldnmp/menu.sh"

entry_ldnmp_site_suite() {
  luopo_ldnmp_menu
}

