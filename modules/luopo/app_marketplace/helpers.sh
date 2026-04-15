#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_APP_MARKETPLACE_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/compat/common.sh"

luopo_app_marketplace_bootstrap() {
  ensure_luopo_vendor_loaded
}

