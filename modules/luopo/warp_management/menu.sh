#!/usr/bin/env bash
set -euo pipefail

LUOPO_WARP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_WARP_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_WARP_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_WARP_DIR/actions.sh"

luopo_warp_management_menu() {
  luopo_warp_bootstrap || return 1
  luopo_warp_launch_menu
}
