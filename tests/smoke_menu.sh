#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MENU_FILE="$ROOT_DIR/core/menu.sh"
BRIDGE_FILE="$ROOT_DIR/modules/luopo_bridge.sh"
VENDOR_FILE="$ROOT_DIR/vendor/luopo.sh"
INSTALL_FILE="$ROOT_DIR/install.sh"
UNINSTALL_FILE="$ROOT_DIR/core/uninstall.sh"

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
  assert_file "$BRIDGE_FILE"
  assert_file "$VENDOR_FILE"
  assert_file "$INSTALL_FILE"
  assert_file "$UNINSTALL_FILE"

  for label in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 88 0; do
    assert_contains_regex "$MENU_FILE" "^[[:space:]]*${label}[[:space:]]*\\)" "missing case label ${label}"
  done
  assert_contains_regex "$MENU_FILE" "^[[:space:]]*99[[:space:]]*\\|[[:space:]]*00[[:space:]]*\\)" "missing case label 99|00"
  if grep -Eq '^[[:space:]]*(16|17|18)[[:space:]]*\)' "$MENU_FILE"; then
    fail "legacy case labels 16/17/18 should not remain in main menu"
  fi

  assert_contains_fixed "$MENU_FILE" 'run_action "system_info" show_system_info' "route 1 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "system_update" system_update' "route 2 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "system_cleanup" system_cleanup' "route 3 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "scripts_hub" scripts_hub' "route 4 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "basic_tools_menu" basic_tools_menu' "route 5 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "bbr_management_menu" bbr_management_menu' "route 6 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "docker_management_menu" docker_management_menu' "route 7 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "warp_management_menu" warp_management_menu' "route 8 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "network_test_suite_menu" network_test_suite_menu' "route 9 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "oracle_cloud_suite_menu" oracle_cloud_suite_menu' "route 10 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "ldnmp_site_suite_menu" ldnmp_site_suite_menu' "route 11 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "app_marketplace_menu" app_marketplace_menu' "route 12 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "workspace_suite_menu" workspace_suite_menu' "route 13 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "system_tools_suite_menu" system_tools_suite_menu' "route 14 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "cluster_control_suite_menu" cluster_control_suite_menu' "route 15 mismatch"

  assert_contains_fixed "$BRIDGE_FILE" 'source "$LUOPO_VENDOR_FILE"' "vendor source missing"
  for fn in ensure_luopo_vendor_loaded run_luopo_compat_menu basic_tools_menu bbr_management_menu docker_management_menu warp_management_menu network_test_suite_menu oracle_cloud_suite_menu ldnmp_site_suite_menu app_marketplace_menu workspace_suite_menu system_tools_suite_menu cluster_control_suite_menu; do
    assert_contains_regex "$BRIDGE_FILE" "^${fn}\\(\\) \\{" "missing bridge function ${fn}"
  done

  assert_contains_fixed "$BRIDGE_FILE" 'bash menu.sh [option] [lisence/url/token]' "warp bridge command mismatch"
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
  assert_contains_fixed "$VENDOR_FILE" 'GitHub Issues: https://github.com/LuoPoJunZi/toolkit/issues' "vendor feedback entry should point to toolkit issues"
  assert_contains_fixed "$VENDOR_FILE" '反馈渠道' "vendor feedback menu label should be adapted"
  assert_contains_fixed "$VENDOR_FILE" '欢迎到仓库提交适配: ${gl_huang}https://github.com/LuoPoJunZi/toolkit${gl_bai}' "vendor app-market contribution hint should be adapted"
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
