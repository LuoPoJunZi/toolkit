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
    render_banner
    echo "------------------------"
    msg menu_1
    msg menu_2
    msg menu_3
    msg menu_4
    msg menu_5
    echo "------------------------"
    msg menu_00
    msg menu_88
    echo "------------------------"
    msg menu_0
    echo ""
    read -r -p "$(msg prompt_select)" choice
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
        press_enter
        ;;
      5)
        log_action "menu:docker_manager"
        run_action "docker_manager" docker_manager
        press_enter
        ;;
      00)
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
