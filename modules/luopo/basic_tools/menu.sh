#!/usr/bin/env bash
set -euo pipefail

LUOPO_BASIC_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_BASIC_TOOLS_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_BASIC_TOOLS_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_BASIC_TOOLS_DIR/actions.sh"

luopo_render_basic_tools_menu() {
  local section section_key section_title item number label group
  echo "========================================"
  echo "基础工具"
  echo "========================================"
  echo "使用包管理器: $(luopo_basic_tools_detect_package_manager)"
  luopo_basic_tools_print_status_table
  echo "----------------------------------------"

  for section in "${LUOPO_BASIC_TOOLS_SECTIONS[@]}"; do
    IFS='|' read -r section_key section_title <<<"$section"
    echo "[ ${section_title} ]"
    for item in "${LUOPO_BASIC_TOOLS_ITEMS[@]}"; do
      IFS='|' read -r number label _ group <<<"$item"
      [[ "$group" == "$section_key" ]] || continue
      menu_item "$number" "$label"
    done
    echo "----------------------------------------"
  done

  echo " 0.  返回主菜单"
  echo "========================================"
}

luopo_dispatch_basic_tools_action() {
  local choice="$1"
  local item handler

  if [[ "$choice" == "0" ]]; then
    return 1
  fi

  if ! item="$(luopo_basic_tools_find_item "$choice")"; then
    luopo_basic_tools_invalid_choice
    return 0
  fi

  IFS='|' read -r _ _ handler _ <<<"$item"
  "$handler"
}

luopo_basic_tools_menu() {
  luopo_basic_tools_bootstrap || return 1

  while true; do
    clear
    luopo_render_basic_tools_menu
    read -r -p "请输入你的选择: " sub_choice || return 0

    if ! luopo_dispatch_basic_tools_action "$sub_choice"; then
      return 0
    fi
  done
}
