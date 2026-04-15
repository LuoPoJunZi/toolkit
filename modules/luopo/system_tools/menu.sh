#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_DIR/actions.sh"

luopo_system_tools_menu() {
  luopo_system_tools_bootstrap || return 1
  luopo_system_tools_launch_compat
}
