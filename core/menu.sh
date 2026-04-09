#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/core/ui.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/core/env.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/core/logger.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/core/self_update.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/core/uninstall.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/system_info.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/system_update.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/system_cleanup.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/scripts_hub.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/docker_manager.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/singbox.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/menus/load.sh"
run_action() {
  local action_name="$1"
  shift
  if ! "$@"; then
    log_error "action_failed:$action_name"
    echo "Action failed: $action_name"
  fi
}

main_menu() {
  require_root
  detect_os >/dev/null

  while true; do
    clear
    local version title
    version="$(get_toolkit_version)"
    title="LuoPo VPS Toolkit v${version} (快捷启动: z)"

    echo "========================================"
    color_text 36 "$title"
    echo
    echo "========================================"
    menu_item "1" "$(msg menu_label_1)"
    menu_item "2" "$(msg menu_label_2)"
    menu_item "3" "$(msg menu_label_3)"
    menu_item "4" "$(msg menu_label_4)"
    menu_item "5" "$(msg menu_label_5)"
    menu_item "6" "$(msg menu_label_6)"
    menu_item "7" "$(msg menu_label_7)"
    menu_item "8" "$(msg menu_label_8)"
    menu_item "9" "$(msg menu_label_9)"
    menu_item "10" "$(msg menu_label_10)"
    menu_item "11" "$(msg menu_label_11)"
    menu_item "12" "$(msg menu_label_12)"
    menu_item "13" "$(msg menu_label_13)"
    menu_item "14" "$(msg menu_label_14)"
    menu_item "15" "$(msg menu_label_15)"
    menu_item "16" "$(msg menu_label_16)"
    menu_item "17" "$(msg menu_label_17)"
    menu_item "18" "$(msg menu_label_18)"
    echo "----------------------------------------"
    menu_item "99" "$(msg menu_label_99)"
    menu_item "88" "$(msg menu_label_88)"
    menu_item "0" "$(msg menu_label_0)"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1)
        log_action "menu:system_info"
        run_action "system_info" show_system_info
        press_enter
        ;;
      2)
        log_action "menu:system_update"
        run_action "system_update" system_update
        press_enter
        ;;
      3)
        log_action "menu:system_cleanup"
        run_action "system_cleanup" system_cleanup
        press_enter
        ;;
      4)
        log_action "menu:scripts_hub"
        run_action "scripts_hub" scripts_hub
        ;;
      5)
        log_action "menu:docker_manager"
        run_action "docker_manager" docker_manager
        ;;
      6)
        log_action "menu:network_accel"
        run_action "network_accel_menu" network_accel_menu
        ;;
      7)
        log_action "menu:network_test"
        run_action "network_test_menu" network_test_menu
        ;;
      8)
        log_action "menu:security"
        run_action "security_menu" security_menu
        ;;
      9)
        log_action "menu:ldnmp"
        run_action "ldnmp_menu" ldnmp_menu
        ;;
      10)
        log_action "menu:app_market"
        run_action "app_market_menu" app_market_menu
        ;;
      11)
        log_action "menu:workspace"
        run_action "workspace_menu" workspace_menu
        ;;
      12)
        log_action "menu:system_tools"
        run_action "system_tools_menu" system_tools_menu
        ;;
      13)
        log_action "menu:backup"
        run_action "backup_menu" backup_menu
        ;;
      14)
        log_action "menu:cron_center"
        run_action "cron_center_menu" cron_center_menu
        ;;
      15)
        log_action "menu:cluster"
        run_action "cluster_menu" cluster_menu
        ;;
      16)
        log_action "menu:oracle_cloud"
        run_action "oracle_cloud_menu" oracle_cloud_menu
        ;;
      17)
        log_action "menu:game_server"
        run_action "game_server_menu" game_server_menu
        ;;
      18)
        log_action "menu:ai_workspace"
        run_action "ai_workspace_menu" ai_workspace_menu
        ;;
      99|00)
        log_action "menu:self_update"
        run_action "self_update" self_update
        press_enter
        ;;
      88)
        log_action "menu:uninstall"
        run_action "uninstall_toolkit" uninstall_toolkit
        ;;
      0)
        msg bye
        exit 0
        ;;
      *)
        msg invalid
        press_enter
        ;;
    esac
  done
}
