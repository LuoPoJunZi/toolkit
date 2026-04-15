#!/usr/bin/env bash
set -euo pipefail

LUOPO_NETWORK_TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_NETWORK_TEST_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_NETWORK_TEST_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_NETWORK_TEST_DIR/actions.sh"

luopo_render_network_test_menu() {
  echo "测试脚本合集"
  echo "------------------------"

  local section section_key section_title item
  for section in "${LUOPO_NETWORK_TEST_SECTIONS[@]}"; do
    IFS='|' read -r section_key section_title <<<"$section"
    echo "$section_title"
    for item in "${LUOPO_NETWORK_TEST_ITEMS[@]}"; do
      if [[ "$(luopo_network_test_item_group "$item")" != "$section_key" ]]; then
        continue
      fi
      printf "%-4s %s\n" "$(luopo_network_test_item_number "$item")." "$(luopo_network_test_item_label "$item")"
    done
    echo "------------------------"
  done

  echo "0.   返回主菜单"
  echo "------------------------"
}

luopo_dispatch_network_test_action() {
  local choice="$1"
  local item handler

  if [[ "$choice" == "0" ]]; then
    return 1
  fi

  if ! item="$(luopo_network_test_find_item "$choice")"; then
    luopo_network_test_invalid_choice
    return 0
  fi

  handler="$(luopo_network_test_item_handler "$item")"
  "$handler"
}

luopo_network_test_menu() {
  luopo_network_test_bootstrap || return 1

  while true; do
    clear
    luopo_render_network_test_menu
    read -r -p "请输入你的选择: " sub_choice

    if ! luopo_dispatch_network_test_action "$sub_choice"; then
      return 0
    fi
  done
}
