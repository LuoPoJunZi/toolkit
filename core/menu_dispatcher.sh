#!/usr/bin/env bash
set -euo pipefail

dispatch_menu_action() {
  local choice="$1"
  local item action_name handler pause_mode

  if ! item="$(find_menu_item "$choice")"; then
    msg invalid
    press_enter
    return 0
  fi

  IFS='|' read -r _ _ handler action_name pause_mode _ <<<"$item"

  if [[ "$handler" == "entry_exit" ]]; then
    entry_exit
    return 0
  fi

  log_action "menu:${action_name}"
  run_action "$action_name" "$handler"

  if [[ "$pause_mode" == "press_enter" ]]; then
    press_enter
  fi
}
