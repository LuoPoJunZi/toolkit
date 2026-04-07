#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Backward-compatible loader for split menu modules.
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/menus/load.sh"
