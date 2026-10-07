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
source "$ROOT_DIR/core/runtime.sh"
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

render_main_menu() {
  local version title item number label_key group
  version="$(get_toolkit_version)"
  title="$(msg title_main_fmt "$version")"

  echo "========================================"
  color_text 36 "$title"
  echo
  echo "========================================"
  for item in "${MENU_ITEMS[@]}"; do
    IFS='|' read -r number label_key _ _ _ group <<<"$item"
    [[ "$group" == "primary" ]] || continue
    menu_item_message "$number" "$label_key"
  done
  echo "----------------------------------------"
  for item in "${MENU_ITEMS[@]}"; do
    IFS='|' read -r number label_key _ _ _ group <<<"$item"
    [[ "$group" == "secondary" ]] || continue
    menu_item_message "$number" "$label_key"
  done
  echo "========================================"
}

main_menu() {
  local choice
  require_root
  detect_os >/dev/null

  while true; do
    clear
    render_main_menu
    read_menu_choice choice || return 0
    if [[ "$choice" == "00" ]]; then
      choice="99"
    fi
    dispatch_menu_action "$choice"
  done
}
