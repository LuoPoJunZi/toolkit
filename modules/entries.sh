#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

entry_load_module() {
  local module_path="$1"
  local handler="$2"

  if declare -F "$handler" >/dev/null; then
    return 0
  fi
  if [[ ! -r "$module_path" ]]; then
    echo "功能模块不存在或不可读: $module_path"
    return 1
  fi

  # Paths come from repository-owned entry wrappers.
  # shellcheck disable=SC1090
  if ! source "$module_path"; then
    echo "功能模块加载失败: $module_path"
    return 1
  fi
  if ! declare -F "$handler" >/dev/null; then
    echo "功能入口未定义: $handler"
    return 1
  fi
}

entry_run_module() {
  local module_path="$1"
  local handler="$2"
  shift 2

  entry_load_module "$module_path" "$handler" || return 1
  "$handler" "$@"
}

# shellcheck disable=SC1091
source "$MODULE_DIR/entry_system_info.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_system_update.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_system_cleanup.sh"
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
source "$MODULE_DIR/entry_ldnmp_site_suite.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_app_marketplace.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_workspace_suite.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_system_tools_suite.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_uninstall.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_self_update.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/entry_exit.sh"
