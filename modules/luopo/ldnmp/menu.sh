#!/usr/bin/env bash
set -euo pipefail

LUOPO_LDNMP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/actions.sh"

luopo_ldnmp_menu() {
  luopo_ldnmp_bootstrap || return 1
  luopo_ldnmp_launch_compat
}
