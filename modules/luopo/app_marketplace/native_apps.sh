#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_NATIVE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LUOPO_APP_MARKETPLACE_NATIVE_MODULE_DIR="$LUOPO_APP_MARKETPLACE_NATIVE_DIR/native"

# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_NATIVE_MODULE_DIR/common.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_NATIVE_MODULE_DIR/panels.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_NATIVE_MODULE_DIR/files_media.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_NATIVE_MODULE_DIR/network_security.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_NATIVE_MODULE_DIR/ai_productivity.sh"
