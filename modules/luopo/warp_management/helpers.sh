#!/usr/bin/env bash
set -euo pipefail

LUOPO_WARP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_WARP_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/compat/common.sh"

luopo_warp_bootstrap() {
  ensure_luopo_vendor_loaded
}

luopo_warp_finish() {
  press_enter
}

