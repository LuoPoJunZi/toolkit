#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MENU_FILE="$ROOT_DIR/core/menu.sh"
LOAD_FILE="$ROOT_DIR/modules/menus/load.sh"

fail() {
  echo "[FAIL] $*"
  exit 1
}

assert_file() {
  local file="$1"
  [[ -f "$file" ]] || fail "missing file: $file"
}

assert_contains_fixed() {
  local file="$1"
  local text="$2"
  local desc="$3"
  grep -Fq "$text" "$file" || fail "$desc (missing: $text)"
}

assert_contains_regex() {
  local file="$1"
  local pattern="$2"
  local desc="$3"
  grep -Eq "$pattern" "$file" || fail "$desc (pattern: $pattern)"
}

assert_func_defined_in_menus() {
  local fn="$1"
  grep -Rqs "^${fn}() {" "$ROOT_DIR/modules/menus" || fail "missing function: ${fn}()"
}

assert_not_contains_regex_in_menus() {
  local pattern="$1"
  local desc="$2"
  if grep -RqsE "$pattern" "$ROOT_DIR/modules/menus"; then
    fail "$desc (pattern: $pattern)"
  fi
}

assert_menu_items_have_case_labels() {
  local file="$1"
  local -a menu_nums case_nums missing
  local n

  mapfile -t menu_nums < <(
    grep -oE 'menu_item "[0-9]+"' "$file" | grep -oE '[0-9]+' | sort -n -u
  )

  mapfile -t case_nums < <(
    grep -oE '^[[:space:]]*[0-9]+(\|[0-9]+)*\)' "$file" \
      | sed -E 's/[[:space:]]//g; s/\)//g' \
      | tr '|' '\n' \
      | sort -n -u
  )

  for n in "${menu_nums[@]}"; do
    if ! printf '%s\n' "${case_nums[@]}" | grep -qx "$n"; then
      missing+=("$n")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    fail "menu item missing case labels in $(basename "$file"): ${missing[*]}"
  fi
}

main() {
  assert_file "$MENU_FILE"
  assert_file "$LOAD_FILE"

  for label in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 88 0; do
    assert_contains_regex "$MENU_FILE" "^[[:space:]]*${label}\\)" "missing case label ${label}"
  done
  assert_contains_fixed "$MENU_FILE" "99|00)" "missing case label 99|00"

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

  assert_contains_fixed "$LOAD_FILE" 'source "$MODULES_DIR/_common.sh"' "missing _common loader"
  for m in network_accel network_test security ldnmp app_market workspace system_tools backup cron_center cluster oracle_cloud game_server ai_workspace; do
    assert_contains_fixed "$LOAD_FILE" "source \"\$MODULES_DIR/${m}.sh\"" "missing loader for ${m}.sh"
  done

  for fn in \
    network_accel_menu network_test_menu security_menu ldnmp_menu \
    app_market_menu workspace_menu system_tools_menu backup_menu \
    cron_center_menu cluster_menu oracle_cloud_menu game_server_menu ai_workspace_menu; do
    assert_func_defined_in_menus "$fn"
  done

  assert_not_contains_regex_in_menus 'echo \"bash <\\(' "placeholder command hint found"
  assert_not_contains_regex_in_menus 'WARP 安装命令指引' "placeholder label found"
  assert_not_contains_regex_in_menus 'placeholder|占位|待实现|TODO' "placeholder marker found"
  assert_not_contains_regex_in_menus '命令参考|示例命令|仅供参考|暂不支持|未实现' "placeholder-like guidance text found"

  for f in "$ROOT_DIR"/modules/menus/*.sh; do
    case "$(basename "$f")" in
      _common.sh|load.sh) continue ;;
    esac
    assert_menu_items_have_case_labels "$f"
  done

  echo "[PASS] menu routing smoke checks passed"
}

main "$@"
