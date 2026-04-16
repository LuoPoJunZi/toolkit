#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MENU_FILE="$ROOT_DIR/core/menu.sh"
COMPAT_LOAD_FILE="$ROOT_DIR/modules/compat/load.sh"
COMPAT_COMMON_FILE="$ROOT_DIR/modules/compat/common.sh"
LUOPO_NETWORK_TEST_MENU_FILE="$ROOT_DIR/modules/luopo/network_test/menu.sh"
LUOPO_NETWORK_TEST_REGISTRY_FILE="$ROOT_DIR/modules/luopo/network_test/registry.sh"
LUOPO_NETWORK_TEST_ACTIONS_FILE="$ROOT_DIR/modules/luopo/network_test/actions.sh"
LUOPO_NETWORK_TEST_HELPERS_FILE="$ROOT_DIR/modules/luopo/network_test/helpers.sh"
LUOPO_BASIC_TOOLS_MENU_FILE="$ROOT_DIR/modules/luopo/basic_tools/menu.sh"
LUOPO_BASIC_TOOLS_REGISTRY_FILE="$ROOT_DIR/modules/luopo/basic_tools/registry.sh"
LUOPO_BASIC_TOOLS_ACTIONS_FILE="$ROOT_DIR/modules/luopo/basic_tools/actions.sh"
LUOPO_BASIC_TOOLS_HELPERS_FILE="$ROOT_DIR/modules/luopo/basic_tools/helpers.sh"
LUOPO_BBR_MENU_FILE="$ROOT_DIR/modules/luopo/bbr_management/menu.sh"
LUOPO_BBR_ACTIONS_FILE="$ROOT_DIR/modules/luopo/bbr_management/actions.sh"
LUOPO_BBR_HELPERS_FILE="$ROOT_DIR/modules/luopo/bbr_management/helpers.sh"
LUOPO_ORACLE_CLOUD_MENU_FILE="$ROOT_DIR/modules/luopo/oracle_cloud/menu.sh"
LUOPO_ORACLE_CLOUD_REGISTRY_FILE="$ROOT_DIR/modules/luopo/oracle_cloud/registry.sh"
LUOPO_ORACLE_CLOUD_ACTIONS_FILE="$ROOT_DIR/modules/luopo/oracle_cloud/actions.sh"
LUOPO_ORACLE_CLOUD_HELPERS_FILE="$ROOT_DIR/modules/luopo/oracle_cloud/helpers.sh"
LUOPO_WORKSPACE_MENU_FILE="$ROOT_DIR/modules/luopo/workspace/menu.sh"
LUOPO_WORKSPACE_REGISTRY_FILE="$ROOT_DIR/modules/luopo/workspace/registry.sh"
LUOPO_WORKSPACE_ACTIONS_FILE="$ROOT_DIR/modules/luopo/workspace/actions.sh"
LUOPO_WORKSPACE_HELPERS_FILE="$ROOT_DIR/modules/luopo/workspace/helpers.sh"
LUOPO_CLUSTER_MENU_FILE="$ROOT_DIR/modules/luopo/cluster_control/menu.sh"
LUOPO_CLUSTER_REGISTRY_FILE="$ROOT_DIR/modules/luopo/cluster_control/registry.sh"
LUOPO_CLUSTER_ACTIONS_FILE="$ROOT_DIR/modules/luopo/cluster_control/actions.sh"
LUOPO_CLUSTER_HELPERS_FILE="$ROOT_DIR/modules/luopo/cluster_control/helpers.sh"
LUOPO_DOCKER_MANAGER_FILE="$ROOT_DIR/modules/luopo/docker/manager.sh"
LUOPO_APP_MARKET_MENU_FILE="$ROOT_DIR/modules/luopo/app_marketplace/menu.sh"
LUOPO_APP_MARKET_REGISTRY_FILE="$ROOT_DIR/modules/luopo/app_marketplace/registry.sh"
LUOPO_APP_MARKET_ACTIONS_FILE="$ROOT_DIR/modules/luopo/app_marketplace/actions.sh"
LUOPO_APP_MARKET_HELPERS_FILE="$ROOT_DIR/modules/luopo/app_marketplace/helpers.sh"
LUOPO_APP_MARKET_NATIVE_APPS_FILE="$ROOT_DIR/modules/luopo/app_marketplace/native_apps.sh"
LUOPO_WARP_MENU_FILE="$ROOT_DIR/modules/luopo/warp_management/menu.sh"
LUOPO_WARP_REGISTRY_FILE="$ROOT_DIR/modules/luopo/warp_management/registry.sh"
LUOPO_WARP_ACTIONS_FILE="$ROOT_DIR/modules/luopo/warp_management/actions.sh"
LUOPO_WARP_HELPERS_FILE="$ROOT_DIR/modules/luopo/warp_management/helpers.sh"
LUOPO_SYSTEM_TOOLS_MENU_FILE="$ROOT_DIR/modules/luopo/system_tools/menu.sh"
LUOPO_SYSTEM_TOOLS_REGISTRY_FILE="$ROOT_DIR/modules/luopo/system_tools/registry.sh"
LUOPO_SYSTEM_TOOLS_ACTIONS_FILE="$ROOT_DIR/modules/luopo/system_tools/actions.sh"
LUOPO_SYSTEM_TOOLS_HELPERS_FILE="$ROOT_DIR/modules/luopo/system_tools/helpers.sh"
LUOPO_LDNMP_MENU_FILE="$ROOT_DIR/modules/luopo/ldnmp/menu.sh"
LUOPO_LDNMP_REGISTRY_FILE="$ROOT_DIR/modules/luopo/ldnmp/registry.sh"
LUOPO_LDNMP_ACTIONS_FILE="$ROOT_DIR/modules/luopo/ldnmp/actions.sh"
LUOPO_LDNMP_HELPERS_FILE="$ROOT_DIR/modules/luopo/ldnmp/helpers.sh"
VENDOR_FILE="$ROOT_DIR/vendor/luopo.sh"
INSTALL_FILE="$ROOT_DIR/install.sh"
UNINSTALL_FILE="$ROOT_DIR/core/uninstall.sh"
REGISTRY_FILE="$ROOT_DIR/core/menu_registry.sh"
DISPATCHER_FILE="$ROOT_DIR/core/menu_dispatcher.sh"
ENTRIES_LOAD_FILE="$ROOT_DIR/modules/entries.sh"

fail() {
  echo "::error title=smoke_menu::$*"
  echo "[FAIL] $*"
  exit 1
}

assert_file() {
  file="$1"
  [[ -f "$file" ]] || fail "missing file: $file"
}

assert_contains_fixed() {
  file="$1"
  text="$2"
  desc="$3"
  grep -Fq "$text" "$file" || fail "$desc (missing: $text)"
}

assert_contains_regex() {
  file="$1"
  pattern="$2"
  desc="$3"
  grep -Eq "$pattern" "$file" || fail "$desc (pattern: $pattern)"
}

assert_not_contains_fixed() {
  file="$1"
  text="$2"
  desc="$3"
  if grep -Fq "$text" "$file"; then
    fail "$desc (unexpected: $text)"
  fi
}

main() {
  assert_file "$MENU_FILE"
  assert_file "$COMPAT_LOAD_FILE"
  assert_file "$COMPAT_COMMON_FILE"
  assert_file "$LUOPO_NETWORK_TEST_MENU_FILE"
  assert_file "$LUOPO_NETWORK_TEST_REGISTRY_FILE"
  assert_file "$LUOPO_NETWORK_TEST_ACTIONS_FILE"
  assert_file "$LUOPO_NETWORK_TEST_HELPERS_FILE"
  assert_file "$LUOPO_BASIC_TOOLS_MENU_FILE"
  assert_file "$LUOPO_BASIC_TOOLS_REGISTRY_FILE"
  assert_file "$LUOPO_BASIC_TOOLS_ACTIONS_FILE"
  assert_file "$LUOPO_BASIC_TOOLS_HELPERS_FILE"
  assert_file "$LUOPO_BBR_MENU_FILE"
  assert_file "$LUOPO_BBR_ACTIONS_FILE"
  assert_file "$LUOPO_BBR_HELPERS_FILE"
  assert_file "$LUOPO_ORACLE_CLOUD_MENU_FILE"
  assert_file "$LUOPO_ORACLE_CLOUD_REGISTRY_FILE"
  assert_file "$LUOPO_ORACLE_CLOUD_ACTIONS_FILE"
  assert_file "$LUOPO_ORACLE_CLOUD_HELPERS_FILE"
  assert_file "$LUOPO_WORKSPACE_MENU_FILE"
  assert_file "$LUOPO_WORKSPACE_REGISTRY_FILE"
  assert_file "$LUOPO_WORKSPACE_ACTIONS_FILE"
  assert_file "$LUOPO_WORKSPACE_HELPERS_FILE"
  assert_file "$LUOPO_CLUSTER_MENU_FILE"
  assert_file "$LUOPO_CLUSTER_REGISTRY_FILE"
  assert_file "$LUOPO_CLUSTER_ACTIONS_FILE"
  assert_file "$LUOPO_CLUSTER_HELPERS_FILE"
  assert_file "$LUOPO_DOCKER_MANAGER_FILE"
  assert_file "$LUOPO_APP_MARKET_MENU_FILE"
  assert_file "$LUOPO_APP_MARKET_REGISTRY_FILE"
  assert_file "$LUOPO_APP_MARKET_ACTIONS_FILE"
  assert_file "$LUOPO_APP_MARKET_HELPERS_FILE"
  assert_file "$LUOPO_APP_MARKET_NATIVE_APPS_FILE"
  assert_file "$LUOPO_WARP_MENU_FILE"
  assert_file "$LUOPO_WARP_REGISTRY_FILE"
  assert_file "$LUOPO_WARP_ACTIONS_FILE"
  assert_file "$LUOPO_WARP_HELPERS_FILE"
  assert_file "$LUOPO_SYSTEM_TOOLS_MENU_FILE"
  assert_file "$LUOPO_SYSTEM_TOOLS_REGISTRY_FILE"
  assert_file "$LUOPO_SYSTEM_TOOLS_ACTIONS_FILE"
  assert_file "$LUOPO_SYSTEM_TOOLS_HELPERS_FILE"
  assert_file "$LUOPO_LDNMP_MENU_FILE"
  assert_file "$LUOPO_LDNMP_REGISTRY_FILE"
  assert_file "$LUOPO_LDNMP_ACTIONS_FILE"
  assert_file "$LUOPO_LDNMP_HELPERS_FILE"
  assert_file "$VENDOR_FILE"
  assert_file "$INSTALL_FILE"
  assert_file "$UNINSTALL_FILE"
  assert_file "$REGISTRY_FILE"
  assert_file "$DISPATCHER_FILE"
  assert_file "$ENTRIES_LOAD_FILE"

  for label in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 99 88 0; do
    assert_contains_fixed "$REGISTRY_FILE" "\"${label}|menu_label_${label}" "missing menu registry item ${label}"
  done

  assert_contains_fixed "$MENU_FILE" 'source "$ROOT_DIR/core/menu_registry.sh"' "menu should load registry"
  assert_contains_fixed "$MENU_FILE" 'source "$ROOT_DIR/core/menu_dispatcher.sh"' "menu should load dispatcher"
  assert_contains_fixed "$MENU_FILE" 'source "$ROOT_DIR/modules/entries.sh"' "menu should load entry handlers"
  assert_contains_fixed "$MENU_FILE" 'source "$ROOT_DIR/modules/compat/load.sh"' "menu should load compat handlers"
  assert_not_contains_fixed "$MENU_FILE" 'source "$ROOT_DIR/modules/luopo_bridge.sh"' "menu should not source legacy bridge"
  assert_not_contains_fixed "$MENU_FILE" 'source "$ROOT_DIR/modules/features/load.sh"' "menu should not source legacy features loader"
  assert_contains_fixed "$MENU_FILE" 'for item in "${MENU_ITEMS[@]}"; do' "menu should render items from registry"
  assert_contains_fixed "$MENU_FILE" 'dispatch_menu_action "$choice"' "menu should dispatch choices via dispatcher"
  assert_contains_fixed "$MENU_FILE" 'if [[ "$choice" == "00" ]]; then' "menu should remap 00 to 99"

  assert_contains_fixed "$DISPATCHER_FILE" 'entry_exit' "dispatcher should support exit handler"
  assert_contains_fixed "$DISPATCHER_FILE" 'run_action "$action_name" "$handler"' "dispatcher should execute handler via run_action"
  assert_contains_fixed "$DISPATCHER_FILE" 'if [[ "$pause_mode" == "press_enter" ]]; then' "dispatcher should honor pause mode"

  for feature_file in \
    entry_system_info.sh \
    entry_system_update.sh \
    entry_system_cleanup.sh \
    entry_scripts_hub.sh \
    entry_basic_tools.sh \
    entry_bbr_management.sh \
    entry_docker_management.sh \
    entry_warp_management.sh \
    entry_network_test_suite.sh \
    entry_oracle_cloud_suite.sh \
    entry_ldnmp_site_suite.sh \
    entry_app_marketplace.sh \
    entry_workspace_suite.sh \
    entry_system_tools_suite.sh \
    entry_cluster_control_suite.sh \
    entry_uninstall.sh \
    entry_self_update.sh \
    entry_exit.sh; do
    assert_contains_fixed "$ENTRIES_LOAD_FILE" "$feature_file" "entries loader missing $feature_file"
  done

  assert_contains_fixed "$ROOT_DIR/modules/entry_basic_tools.sh" 'source "$ROOT_DIR/modules/luopo/basic_tools/menu.sh"' "basic tools entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_basic_tools.sh" 'luopo_basic_tools_menu' "basic tools entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_BASIC_TOOLS_MENU_FILE" '^luopo_basic_tools_menu\(\) \{' "missing LuoPo basic tools menu entry"
  assert_contains_regex "$LUOPO_BASIC_TOOLS_REGISTRY_FILE" '^LUOPO_BASIC_TOOLS_ITEMS=\(' "missing LuoPo basic tools registry"
  assert_contains_regex "$LUOPO_BASIC_TOOLS_ACTIONS_FILE" '^luopo_basic_tools_install_curl\(\) \{' "missing LuoPo basic tools action"
  assert_contains_regex "$LUOPO_BASIC_TOOLS_HELPERS_FILE" '^luopo_basic_tools_detect_package_manager\(\) \{' "missing LuoPo basic tools helper"
  assert_contains_fixed "$ROOT_DIR/modules/entry_bbr_management.sh" 'source "$ROOT_DIR/modules/luopo/bbr_management/menu.sh"' "bbr entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_bbr_management.sh" 'luopo_bbr_management_menu' "bbr entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_BBR_MENU_FILE" '^luopo_bbr_management_menu\(\) \{' "missing LuoPo bbr menu entry"
  assert_contains_regex "$LUOPO_BBR_ACTIONS_FILE" '^luopo_bbr_enable_alpine\(\) \{' "missing LuoPo bbr action"
  assert_contains_regex "$LUOPO_BBR_HELPERS_FILE" '^luopo_bbr_current_algorithms\(\) \{' "missing LuoPo bbr helper"
  assert_contains_fixed "$ROOT_DIR/modules/entry_docker_management.sh" 'source "$ROOT_DIR/modules/luopo/docker/manager.sh"' "docker entry should source LuoPo docker manager"
  assert_contains_fixed "$ROOT_DIR/modules/entry_docker_management.sh" 'docker_manager' "docker entry should call native docker manager"
  assert_contains_regex "$LUOPO_DOCKER_MANAGER_FILE" '^docker_manager\(\) \{' "missing LuoPo docker manager entry"
  assert_contains_fixed "$ROOT_DIR/modules/entry_warp_management.sh" 'source "$ROOT_DIR/modules/luopo/warp_management/menu.sh"' "warp entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_warp_management.sh" 'luopo_warp_management_menu' "warp entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_WARP_MENU_FILE" '^luopo_warp_management_menu\(\) \{' "missing LuoPo warp menu entry"
  assert_contains_regex "$LUOPO_WARP_REGISTRY_FILE" '^LUOPO_WARP_ITEMS=\(' "missing LuoPo warp registry"
  assert_contains_regex "$LUOPO_WARP_ACTIONS_FILE" '^luopo_warp_launch_menu\(\) \{' "missing LuoPo warp action"
  assert_contains_regex "$LUOPO_WARP_HELPERS_FILE" '^luopo_warp_bootstrap\(\) \{' "missing LuoPo warp helper"
  assert_contains_fixed "$ROOT_DIR/modules/entry_network_test_suite.sh" 'source "$ROOT_DIR/modules/luopo/network_test/menu.sh"' "network test entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_network_test_suite.sh" 'luopo_network_test_menu' "network test entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_NETWORK_TEST_MENU_FILE" '^luopo_network_test_menu\(\) \{' "missing LuoPo network test menu entry"
  assert_contains_regex "$LUOPO_NETWORK_TEST_REGISTRY_FILE" '^LUOPO_NETWORK_TEST_ITEMS=\(' "missing LuoPo network test registry"
  assert_contains_regex "$LUOPO_NETWORK_TEST_ACTIONS_FILE" '^luopo_network_test_chatgpt_unlock\(\) \{' "missing LuoPo network test action"
  assert_contains_regex "$LUOPO_NETWORK_TEST_HELPERS_FILE" '^luopo_network_test_run_shell\(\) \{' "missing LuoPo network test helper"
  assert_contains_fixed "$ROOT_DIR/modules/entry_oracle_cloud_suite.sh" 'source "$ROOT_DIR/modules/luopo/oracle_cloud/menu.sh"' "oracle cloud entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_oracle_cloud_suite.sh" 'luopo_oracle_cloud_menu' "oracle cloud entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_ORACLE_CLOUD_MENU_FILE" '^luopo_oracle_cloud_menu\(\) \{' "missing LuoPo oracle cloud menu entry"
  assert_contains_regex "$LUOPO_ORACLE_CLOUD_REGISTRY_FILE" '^LUOPO_ORACLE_CLOUD_ITEMS=\(' "missing LuoPo oracle cloud registry"
  assert_contains_regex "$LUOPO_ORACLE_CLOUD_ACTIONS_FILE" '^luopo_oracle_cloud_install_lookbusy\(\) \{' "missing LuoPo oracle cloud action"
  assert_contains_regex "$LUOPO_ORACLE_CLOUD_HELPERS_FILE" '^luopo_oracle_cloud_run_shell\(\) \{' "missing LuoPo oracle cloud helper"
  assert_contains_fixed "$ROOT_DIR/modules/entry_ldnmp_site_suite.sh" 'source "$ROOT_DIR/modules/luopo/ldnmp/menu.sh"' "ldnmp entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_ldnmp_site_suite.sh" 'luopo_ldnmp_menu' "ldnmp entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_LDNMP_MENU_FILE" '^luopo_ldnmp_menu\(\) \{' "missing LuoPo ldnmp menu entry"
  assert_contains_regex "$LUOPO_LDNMP_REGISTRY_FILE" '^LUOPO_LDNMP_ITEMS=\(' "missing LuoPo ldnmp registry"
  assert_contains_regex "$LUOPO_LDNMP_ACTIONS_FILE" '^luopo_ldnmp_launch_compat\(\) \{' "missing LuoPo ldnmp action"
  assert_contains_regex "$LUOPO_LDNMP_HELPERS_FILE" '^luopo_ldnmp_bootstrap\(\) \{' "missing LuoPo ldnmp helper"
  assert_contains_fixed "$ROOT_DIR/modules/entry_workspace_suite.sh" 'source "$ROOT_DIR/modules/luopo/workspace/menu.sh"' "workspace entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_workspace_suite.sh" 'luopo_workspace_menu' "workspace entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_WORKSPACE_MENU_FILE" '^luopo_workspace_menu\(\) \{' "missing LuoPo workspace menu entry"
  assert_contains_regex "$LUOPO_WORKSPACE_REGISTRY_FILE" '^LUOPO_WORKSPACE_ITEMS=\(' "missing LuoPo workspace registry"
  assert_contains_regex "$LUOPO_WORKSPACE_ACTIONS_FILE" '^luopo_workspace_manage_ssh_mode\(\) \{' "missing LuoPo workspace action"
  assert_contains_regex "$LUOPO_WORKSPACE_HELPERS_FILE" '^luopo_workspace_run_named_session\(\) \{' "missing LuoPo workspace helper"
  assert_contains_fixed "$ROOT_DIR/modules/entry_cluster_control_suite.sh" 'source "$ROOT_DIR/modules/luopo/cluster_control/menu.sh"' "cluster entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_cluster_control_suite.sh" 'luopo_cluster_control_menu' "cluster entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_CLUSTER_MENU_FILE" '^luopo_cluster_control_menu\(\) \{' "missing LuoPo cluster menu entry"
  assert_contains_regex "$LUOPO_CLUSTER_REGISTRY_FILE" '^LUOPO_CLUSTER_ITEMS=\(' "missing LuoPo cluster registry"
  assert_contains_regex "$LUOPO_CLUSTER_ACTIONS_FILE" '^luopo_cluster_install_toolkit\(\) \{' "missing LuoPo cluster action"
  assert_contains_regex "$LUOPO_CLUSTER_HELPERS_FILE" '^luopo_cluster_bootstrap\(\) \{' "missing LuoPo cluster helper"
  assert_contains_fixed "$ROOT_DIR/modules/entry_app_marketplace.sh" 'source "$ROOT_DIR/modules/luopo/app_marketplace/menu.sh"' "app market entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_app_marketplace.sh" 'luopo_app_marketplace_menu' "app market entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_APP_MARKET_MENU_FILE" '^luopo_app_marketplace_menu\(\) \{' "missing LuoPo app market menu entry"
  assert_contains_regex "$LUOPO_APP_MARKET_REGISTRY_FILE" '^LUOPO_APP_MARKETPLACE_ITEMS=\(' "missing LuoPo app market registry"
  assert_contains_regex "$LUOPO_APP_MARKET_REGISTRY_FILE" '^LUOPO_APP_MARKETPLACE_LAYOUT=\(' "missing LuoPo app market layout registry"
  assert_contains_regex "$LUOPO_APP_MARKET_ACTIONS_FILE" '^luopo_app_marketplace_dispatch_choice\(\) \{' "missing LuoPo app market dispatch action"
  assert_contains_regex "$LUOPO_APP_MARKET_HELPERS_FILE" '^luopo_app_marketplace_bootstrap\(\) \{' "missing LuoPo app market helper"
  assert_contains_regex "$LUOPO_APP_MARKET_HELPERS_FILE" '^luopo_app_marketplace_sync_index\(\) \{' "missing LuoPo app market sync helper"
  assert_contains_regex "$LUOPO_APP_MARKET_HELPERS_FILE" '^luopo_app_marketplace_render_cell\(\) \{' "missing LuoPo app market render helper"
  assert_contains_regex "$LUOPO_APP_MARKET_MENU_FILE" '^luopo_render_app_marketplace_menu\(\) \{' "missing LuoPo app market render menu"
  assert_contains_fixed "$LUOPO_APP_MARKET_MENU_FILE" 'read -r -p "请输入你的选择: " sub_choice' "app market should read choice in LuoPo menu"
  assert_contains_fixed "$LUOPO_APP_MARKET_ACTIONS_FILE" 'run_luopo_compat_menu linux_panel "$choice"' "app market dispatch should pass choice into compat backend"
  assert_contains_fixed "$LUOPO_APP_MARKET_ACTIONS_FILE" 'luopo_app_marketplace_portainer_menu' "app market dispatch should route portainer natively"
  assert_contains_fixed "$LUOPO_APP_MARKET_ACTIONS_FILE" 'luopo_app_marketplace_uptime_kuma_menu' "app market dispatch should route uptime kuma natively"
  assert_contains_fixed "$LUOPO_APP_MARKET_ACTIONS_FILE" 'luopo_app_marketplace_ddns_go_menu' "app market dispatch should route ddns-go natively"
  assert_contains_fixed "$LUOPO_APP_MARKET_ACTIONS_FILE" 'luopo_app_marketplace_filebrowser_menu' "app market dispatch should route filebrowser natively"
  assert_contains_regex "$LUOPO_APP_MARKET_NATIVE_APPS_FILE" '^luopo_app_marketplace_native_docker_app_menu\(\) \{' "missing native docker app menu helper"
  assert_contains_regex "$LUOPO_APP_MARKET_NATIVE_APPS_FILE" '^luopo_app_marketplace_portainer_menu\(\) \{' "missing native portainer menu"
  assert_contains_regex "$LUOPO_APP_MARKET_NATIVE_APPS_FILE" '^luopo_app_marketplace_uptime_kuma_menu\(\) \{' "missing native uptime kuma menu"
  assert_contains_regex "$LUOPO_APP_MARKET_NATIVE_APPS_FILE" '^luopo_app_marketplace_ddns_go_menu\(\) \{' "missing native ddns-go menu"
  assert_contains_regex "$LUOPO_APP_MARKET_NATIVE_APPS_FILE" '^luopo_app_marketplace_filebrowser_menu\(\) \{' "missing native filebrowser menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_system_tools_suite.sh" 'source "$ROOT_DIR/modules/luopo/system_tools/menu.sh"' "system tools entry should source LuoPo menu"
  assert_contains_fixed "$ROOT_DIR/modules/entry_system_tools_suite.sh" 'luopo_system_tools_menu' "system tools entry should call LuoPo menu"
  assert_contains_regex "$LUOPO_SYSTEM_TOOLS_MENU_FILE" '^luopo_system_tools_menu\(\) \{' "missing LuoPo system tools menu entry"
  assert_contains_regex "$LUOPO_SYSTEM_TOOLS_REGISTRY_FILE" '^LUOPO_SYSTEM_TOOLS_ITEMS=\(' "missing LuoPo system tools registry"
  assert_contains_regex "$LUOPO_SYSTEM_TOOLS_ACTIONS_FILE" '^luopo_system_tools_launch_compat\(\) \{' "missing LuoPo system tools action"
  assert_contains_regex "$LUOPO_SYSTEM_TOOLS_HELPERS_FILE" '^luopo_system_tools_bootstrap\(\) \{' "missing LuoPo system tools helper"

  assert_contains_fixed "$COMPAT_COMMON_FILE" 'source "$LUOPO_VENDOR_FILE"' "vendor source missing"
  for fn in ensure_luopo_vendor_loaded run_luopo_compat_menu; do
    assert_contains_regex "$COMPAT_COMMON_FILE" "^${fn}\\(\\) \\{" "missing compat core function ${fn}"
  done
  assert_contains_fixed "$COMPAT_LOAD_FILE" 'source "$COMPAT_DIR/common.sh"' "compat loader should source shared common bridge"
  assert_not_contains_fixed "$COMPAT_LOAD_FILE" 'ldnmp_site_suite.sh' "compat loader should no longer source ldnmp shim"
  assert_not_contains_fixed "$COMPAT_LOAD_FILE" 'system_tools_suite.sh' "compat loader should no longer source system tools shim"
  assert_not_contains_fixed "$COMPAT_LOAD_FILE" 'warp_management.sh' "compat loader should no longer source warp shim"
  assert_not_contains_fixed "$COMPAT_LOAD_FILE" 'app_marketplace.sh' "compat loader should no longer source app market shim"

  assert_contains_fixed "$LUOPO_WARP_ACTIONS_FILE" 'bash menu.sh [option] [lisence/url/token]' "warp native command mismatch"
  assert_not_contains_fixed "$INSTALL_FILE" 'K_COMPAT_PATH="/usr/local/bin/k"' "install should not define k compatibility launcher"
  assert_contains_fixed "$INSTALL_FILE" 'rm -f /usr/local/bin/k /usr/bin/k' "install should cleanup legacy k launchers"
  assert_contains_fixed "$INSTALL_FILE" 'REPO_ARCHIVE_URL="${LUOPO_REPO_ARCHIVE_URL:-https://codeload.github.com/LuoPoJunZi/toolkit/tar.gz/refs/heads/main}"' "install should support remote bootstrap archive"
  assert_contains_fixed "$INSTALL_FILE" 'bootstrap_source_tree() {' "install bootstrap function missing"
  assert_contains_fixed "$INSTALL_FILE" 'SOURCE_DIR="$extracted_dir"' "install should switch to downloaded source tree"
  assert_contains_fixed "$UNINSTALL_FILE" 'rm -f /usr/local/bin/k /usr/bin/k' "uninstall should cleanup legacy k launchers"
  assert_contains_fixed "$VENDOR_FILE" 'ENABLE_STATS="false"' "vendor telemetry should be disabled"
  assert_contains_fixed "$VENDOR_FILE" 'if [ -z "${KEJILION_LIBRARY_MODE:-}" ]; then' "vendor library guard missing"
  assert_contains_fixed "$VENDOR_FILE" 'if [ -n "${KEJILION_LIBRARY_MODE:-}" ]; then' "vendor main-menu exit bridge missing"
  assert_contains_fixed "$VENDOR_FILE" '安装LuoPo脚本' "vendor cluster install label should be adapted"
  assert_contains_fixed "$VENDOR_FILE" '卸载LuoPo脚本' "vendor uninstall label should be adapted"
  assert_contains_fixed "$VENDOR_FILE" '欢迎使用LuoPo VPS Toolkit' "vendor welcome text should use LuoPo branding"
  assert_contains_fixed "$VENDOR_FILE" 'LuoPo VPS Toolkit v$sh_v' "vendor mirrored main title should use LuoPo branding"
  assert_contains_fixed "$VENDOR_FILE" '命令行输入${gl_huang}z${gl_kjlan}可快速启动脚本${gl_bai}' "vendor mirrored main quick-start hint should use z"
  assert_contains_fixed "$VENDOR_FILE" 'z命令高级用法' "vendor system tools help label should use z"
  assert_contains_fixed "$VENDOR_FILE" '以下是 z 命令参考用例：' "vendor command help should use z examples"
  assert_contains_fixed "$VENDOR_FILE" '快捷启动命令        请统一使用 z' "vendor command help should only mention z"
  assert_contains_fixed "$VENDOR_FILE" '🦞 OPENCLAW 管理工具 by LuoPo 🦞' "vendor openclaw header should use LuoPo branding"
  assert_contains_fixed "$VENDOR_FILE" '💡 终端执行 \033[1;33mz claw\033[0m 快速进入菜单' "vendor openclaw quick entry should use z"
  assert_contains_fixed "$VENDOR_FILE" 'LuoPo 项目入口' "vendor affiliate page should point to LuoPo project links"
  assert_not_contains_fixed "$VENDOR_FILE" '第三方应用列表' "vendor app market should not print third-party app list footer"
  assert_contains_fixed "$VENDOR_FILE" 'GitHub Issues: https://github.com/LuoPoJunZi/toolkit/issues' "vendor feedback entry should point to toolkit issues"
  assert_contains_fixed "$VENDOR_FILE" '反馈渠道' "vendor feedback menu label should be adapted"
  assert_contains_fixed "$VENDOR_FILE" 'run_commands_on_servers "z update"' "cluster update should use z"
  assert_contains_fixed "$VENDOR_FILE" 'run_commands_on_servers "z docker install"' "cluster docker install should use z"
  assert_contains_fixed "$VENDOR_FILE" '当前 LuoPo VPS Toolkit 兼容层已默认关闭统计采集。' "privacy page text should be adapted"
  assert_contains_fixed "$VENDOR_FILE" '快捷启动命令已设置' "shortcut message should be adapted"
  assert_contains_fixed "$VENDOR_FILE" '卸载LuoPo VPS Toolkit' "vendor uninstall heading should be adapted"
  if grep -Fq 'ipv4优先${gl_bai}}' "$VENDOR_FILE"; then
    fail "vendor contains stale ipv4 display typo"
  fi

  for fn in linux_tools linux_bbr linux_docker linux_test linux_Oracle linux_ldnmp linux_panel linux_work linux_Settings linux_cluster; do
    assert_contains_regex "$VENDOR_FILE" "^${fn}\\(\\) \\{" "missing vendor function ${fn}"
  done

  echo "[PASS] menu routing smoke checks passed"
}

main "$@"
