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
source "$ROOT_DIR/modules/compat/load.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/entries.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/core/menu_registry.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/core/menu_dispatcher.sh"
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
    local item label_key group
    for item in "${MENU_ITEMS[@]}"; do
      group="$(menu_item_group "$item")"
      if [[ "$group" != "primary" ]]; then
        continue
      fi
      label_key="$(menu_item_label_key "$item")"
      menu_item "$(menu_item_number "$item")" "$(msg "$label_key")"
    done
    echo "----------------------------------------"
    for item in "${MENU_ITEMS[@]}"; do
      group="$(menu_item_group "$item")"
      if [[ "$group" != "secondary" ]]; then
        continue
      fi
      label_key="$(menu_item_label_key "$item")"
      menu_item "$(menu_item_number "$item")" "$(msg "$label_key")"
    done
    echo "========================================"
    read_menu_choice choice
    if [[ "$choice" == "00" ]]; then
      choice="99"
    fi
    dispatch_menu_action "$choice"
  done
}
