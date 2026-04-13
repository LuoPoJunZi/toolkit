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
source "$ROOT_DIR/modules/kejilion_bridge.sh"
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
        log_action "menu:basic_tools"
        run_action "basic_tools_menu" basic_tools_menu
        ;;
      6)
        log_action "menu:bbr_management"
        run_action "bbr_management_menu" bbr_management_menu
        ;;
      7)
        log_action "menu:docker_management"
        run_action "docker_management_menu" docker_management_menu
        ;;
      8)
        log_action "menu:warp_management"
        run_action "warp_management_menu" warp_management_menu
        ;;
      9)
        log_action "menu:network_test_suite"
        run_action "network_test_suite_menu" network_test_suite_menu
        ;;
      10)
        log_action "menu:oracle_cloud_suite"
        run_action "oracle_cloud_suite_menu" oracle_cloud_suite_menu
        ;;
      11)
        log_action "menu:ldnmp_site_suite"
        run_action "ldnmp_site_suite_menu" ldnmp_site_suite_menu
        ;;
      12)
        log_action "menu:app_marketplace"
        run_action "app_marketplace_menu" app_marketplace_menu
        ;;
      13)
        log_action "menu:workspace_suite"
        run_action "workspace_suite_menu" workspace_suite_menu
        ;;
      14)
        log_action "menu:system_tools_suite"
        run_action "system_tools_suite_menu" system_tools_suite_menu
        ;;
      15)
        log_action "menu:cluster_control_suite"
        run_action "cluster_control_suite_menu" cluster_control_suite_menu
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
