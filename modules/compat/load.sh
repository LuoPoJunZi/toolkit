#!/usr/bin/env bash
set -euo pipefail

COMPAT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$COMPAT_DIR/common.sh"
# shellcheck disable=SC1091
source "$COMPAT_DIR/docker_management.sh"
# shellcheck disable=SC1091
source "$COMPAT_DIR/warp_management.sh"
# shellcheck disable=SC1091
source "$COMPAT_DIR/oracle_cloud_suite.sh"
# shellcheck disable=SC1091
source "$COMPAT_DIR/ldnmp_site_suite.sh"
# shellcheck disable=SC1091
source "$COMPAT_DIR/app_marketplace.sh"
# shellcheck disable=SC1091
source "$COMPAT_DIR/system_tools_suite.sh"
# shellcheck disable=SC1091
source "$COMPAT_DIR/cluster_control_suite.sh"
