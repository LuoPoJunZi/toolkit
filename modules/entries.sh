#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$MODULE_DIR/entry_system_info.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_system_update.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_system_cleanup.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_scripts_hub.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_basic_tools.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_bbr_management.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_docker_management.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_warp_management.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_network_test_suite.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_oracle_cloud_suite.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_ldnmp_site_suite.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_app_marketplace.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_workspace_suite.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_system_tools_suite.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_cluster_control_suite.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_uninstall.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_self_update.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_exit.sh"
