#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_DIR/native_apps.sh"

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
    20)
      luopo_app_marketplace_portainer_menu
      return 0
      ;;
    22)
      luopo_app_marketplace_uptime_kuma_menu
      return 0
      ;;
    23)
      luopo_app_marketplace_memos_menu
      return 0
      ;;
    29)
      luopo_app_marketplace_searxng_menu
      return 0
      ;;
    67)
      luopo_app_marketplace_ddns_go_menu
      return 0
      ;;
    71)
      luopo_app_marketplace_navidrome_menu
      return 0
      ;;
    79)
      luopo_app_marketplace_beszel_menu
      return 0
      ;;
    83)
      luopo_app_marketplace_komari_menu
      return 0
      ;;
    86)
      luopo_app_marketplace_jellyfin_menu
      return 0
      ;;
    92)
      luopo_app_marketplace_filebrowser_menu
      return 0
      ;;
    109)
      luopo_app_marketplace_zfile_menu
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

