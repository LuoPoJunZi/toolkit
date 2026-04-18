#!/usr/bin/env bash
set -euo pipefail

LUOPO_WARP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_WARP_DIR/../../.." && pwd)"

luopo_warp_bootstrap() {
  return 0
}

luopo_warp_finish() {
  press_enter
}

