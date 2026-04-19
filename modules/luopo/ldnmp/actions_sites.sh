#!/usr/bin/env bash
set -euo pipefail

LUOPO_LDNMP_SITES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sites"

# shellcheck disable=SC1091
source "$LUOPO_LDNMP_SITES_DIR/environment.sh"
# shellcheck disable=SC1091
source "$LUOPO_LDNMP_SITES_DIR/php_cms.sh"
# shellcheck disable=SC1091
source "$LUOPO_LDNMP_SITES_DIR/apps_static.sh"
