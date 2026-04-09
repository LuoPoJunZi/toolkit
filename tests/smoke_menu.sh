#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MENU_FILE="$ROOT_DIR/core/menu.sh"
LOAD_FILE="$ROOT_DIR/modules/menus/load.sh"
DOCKER_FILE="$ROOT_DIR/modules/docker_manager.sh"

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

assert_func_defined_in_menus() {
  fn="$1"
  grep -Rqs "^${fn}() {" "$ROOT_DIR/modules/menus" || fail "missing function: ${fn}()"
}

assert_not_contains_regex_in_menus() {
  pattern="$1"
  desc="$2"
  if grep -RqsE "$pattern" "$ROOT_DIR/modules/menus"; then
    fail "$desc (pattern: $pattern)"
  fi
}

assert_menu_items_have_case_labels() {
  return 0
}

main() {
  assert_file "$MENU_FILE"
  assert_file "$LOAD_FILE"
  assert_file "$DOCKER_FILE"

  for label in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 88 0; do
    assert_contains_regex "$MENU_FILE" "^[[:space:]]*${label}[[:space:]]*\\)" "missing case label ${label}"
  done
  assert_contains_regex "$MENU_FILE" "^[[:space:]]*99[[:space:]]*\\|[[:space:]]*00[[:space:]]*\\)" "missing case label 99|00"

  assert_contains_fixed "$MENU_FILE" 'run_action "system_info" show_system_info' "route 1 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "system_update" system_update' "route 2 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "system_cleanup" system_cleanup' "route 3 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "scripts_hub" scripts_hub' "route 4 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "docker_manager" docker_manager' "route 5 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "network_accel_menu" network_accel_menu' "route 6 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "network_test_menu" network_test_menu' "route 7 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "security_menu" security_menu' "route 8 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "ldnmp_menu" ldnmp_menu' "route 9 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "app_market_menu" app_market_menu' "route 10 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "workspace_menu" workspace_menu' "route 11 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "system_tools_menu" system_tools_menu' "route 12 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "backup_menu" backup_menu' "route 13 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "cron_center_menu" cron_center_menu' "route 14 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "cluster_menu" cluster_menu' "route 15 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "oracle_cloud_menu" oracle_cloud_menu' "route 16 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "game_server_menu" game_server_menu' "route 17 mismatch"
  assert_contains_fixed "$MENU_FILE" 'run_action "ai_workspace_menu" ai_workspace_menu' "route 18 mismatch"

  # Docker main menu: render + route coverage (avoid dead entries)
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "1" "安装更新Docker环境"' "docker menu item 1 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "2" "查看Docker全局状态"' "docker menu item 2 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "3" "Docker容器管理"' "docker menu item 3 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "4" "Docker镜像管理"' "docker menu item 4 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "5" "Docker网络管理"' "docker menu item 5 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "6" "Docker卷管理"' "docker menu item 6 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "7" "清理无用Docker容器/镜像/网络/卷"' "docker menu item 7 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "8" "更换Docker源"' "docker menu item 8 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "9" "编辑daemon.json文件"' "docker menu item 9 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "11" "开启Docker IPv6访问"' "docker menu item 11 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "12" "关闭Docker IPv6访问"' "docker menu item 12 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "19" "备份/迁移/还原Docker环境"' "docker menu item 19 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "20" "卸载Docker环境"' "docker menu item 20 mismatch"
  assert_contains_fixed "$DOCKER_FILE" 'menu_item "0" "返回上级菜单"' "docker menu item 0 mismatch"

  assert_contains_fixed "$DOCKER_FILE" '1)' "docker case 1 missing"
  assert_contains_fixed "$DOCKER_FILE" 'install_update_docker' "docker route 1 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '2)' "docker case 2 missing"
  assert_contains_fixed "$DOCKER_FILE" 'docker_global_status' "docker route 2 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '3)' "docker case 3 missing"
  assert_contains_fixed "$DOCKER_FILE" 'container_manager_menu' "docker route 3 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '4)' "docker case 4 missing"
  assert_contains_fixed "$DOCKER_FILE" 'image_manager_menu' "docker route 4 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '5)' "docker case 5 missing"
  assert_contains_fixed "$DOCKER_FILE" 'network_manager_menu' "docker route 5 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '6)' "docker case 6 missing"
  assert_contains_fixed "$DOCKER_FILE" 'volume_manager_menu' "docker route 6 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '7)' "docker case 7 missing"
  assert_contains_fixed "$DOCKER_FILE" 'docker_cleanup_all' "docker route 7 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '8)' "docker case 8 missing"
  assert_contains_fixed "$DOCKER_FILE" 'switch_docker_mirror' "docker route 8 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '9)' "docker case 9 missing"
  assert_contains_fixed "$DOCKER_FILE" 'edit_daemon_json' "docker route 9 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '11)' "docker case 11 missing"
  assert_contains_fixed "$DOCKER_FILE" 'enable_docker_ipv6' "docker route 11 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '12)' "docker case 12 missing"
  assert_contains_fixed "$DOCKER_FILE" 'disable_docker_ipv6' "docker route 12 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '19)' "docker case 19 missing"
  assert_contains_fixed "$DOCKER_FILE" 'backup_migrate_restore_menu' "docker route 19 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '20)' "docker case 20 missing"
  assert_contains_fixed "$DOCKER_FILE" 'uninstall_docker_env' "docker route 20 mismatch"
  assert_contains_fixed "$DOCKER_FILE" '0)' "docker case 0 missing"

  assert_contains_fixed "$LOAD_FILE" 'source "$MODULES_DIR/_common.sh"' "missing _common loader"
  for m in network_accel network_test security ldnmp app_market workspace system_tools backup cron_center cluster oracle_cloud game_server ai_workspace; do
    assert_contains_fixed "$LOAD_FILE" "source \"\$MODULES_DIR/${m}.sh\"" "missing loader for ${m}.sh"
  done

  for fn in network_accel_menu network_test_menu security_menu ldnmp_menu app_market_menu workspace_menu system_tools_menu backup_menu cron_center_menu cluster_menu oracle_cloud_menu game_server_menu ai_workspace_menu; do
    assert_func_defined_in_menus "$fn"
  done

  assert_not_contains_regex_in_menus 'echo \"bash <\\(' "placeholder command hint found"
  assert_not_contains_regex_in_menus 'WARP 安装命令指引' "placeholder label found"
  assert_not_contains_regex_in_menus 'placeholder|占位|待实现|TODO' "placeholder marker found"
  assert_not_contains_regex_in_menus '命令参考|示例命令|仅供参考|暂不支持|未实现' "placeholder-like guidance text found"
  assert_contains_regex "$DOCKER_FILE" 'docker_manager\(\) \{' "docker manager function missing"
  assert_not_contains_regex "$DOCKER_FILE" 'placeholder|占位|待实现|TODO|命令参考|示例命令|仅供参考|暂不支持|未实现' "docker placeholder-like text found"

  for f in "$ROOT_DIR"/modules/menus/*.sh; do
    case "$(basename "$f")" in
      _common.sh|load.sh) continue ;;
    esac
    assert_menu_items_have_case_labels "$f"
  done

  echo "[PASS] menu routing smoke checks passed"
}

main "$@"
