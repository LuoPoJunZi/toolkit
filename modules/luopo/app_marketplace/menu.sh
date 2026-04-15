#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_DIR/actions.sh"

luopo_app_marketplace_menu() {
  luopo_app_marketplace_bootstrap || return 1
  luopo_app_marketplace_launch_compat
}
