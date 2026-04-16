#!/usr/bin/env bash
set -euo pipefail

luopo_app_marketplace_launch_compat() {
  run_luopo_compat_menu linux_panel
}

luopo_app_marketplace_dispatch_choice() {
  local choice="$1"

  case "$choice" in
    0)
      return 1
      ;;
    b|r)
      run_luopo_compat_menu linux_panel "$choice"
      return 0
      ;;
  esac

  if [[ "$choice" =~ ^[0-9]+$ ]] && luopo_app_marketplace_find_item "$choice" >/dev/null; then
    run_luopo_compat_menu linux_panel "$choice"
    return 0
  fi

  luopo_app_marketplace_invalid_choice
  return 0
}

