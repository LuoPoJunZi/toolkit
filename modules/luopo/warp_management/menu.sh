#!/usr/bin/env bash
set -euo pipefail

LUOPO_WARP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_WARP_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_WARP_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_WARP_DIR/actions.sh"

luopo_render_warp_menu() {
  local section section_key section_title item
  echo "========================================"
  echo "WARP管理"
  echo "========================================"
  for section in "${LUOPO_WARP_SECTIONS[@]}"; do
    IFS='|' read -r section_key section_title <<<"$section"
    echo "[ ${section_title} ]"
    for item in "${LUOPO_WARP_ITEMS[@]}"; do
      if [[ "$(luopo_warp_item_group "$item")" != "$section_key" ]]; then
        continue
      fi
      printf " %-3s %s\n" "$(luopo_warp_item_number "$item")." "$(luopo_warp_item_label "$item")"
    done
    echo "----------------------------------------"
  done
  echo " 0.  返回主菜单"
  echo "========================================"
}

luopo_warp_management_menu() {
  luopo_warp_bootstrap || return 1

  while true; do
    clear
    luopo_render_warp_menu
    read -r -p "请输入你的选择: " sub_choice
    if ! luopo_warp_dispatch_choice "$sub_choice"; then
      return 0
    fi
    echo
    read -r -p "按回车继续..." _
  done
}
