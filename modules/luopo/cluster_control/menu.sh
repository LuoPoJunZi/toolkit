#!/usr/bin/env bash
set -euo pipefail

LUOPO_CLUSTER_CONTROL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_CLUSTER_CONTROL_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_CLUSTER_CONTROL_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_CLUSTER_CONTROL_DIR/actions.sh"

luopo_render_cluster_control_menu() {
  local section section_key section_title item
  echo "========================================"
  echo "服务器集群控制"
  echo "========================================"
  echo "[ 当前服务器 ]"
  luopo_cluster_show_servers
  echo "----------------------------------------"

  for section in "${LUOPO_CLUSTER_SECTIONS[@]}"; do
    IFS='|' read -r section_key section_title <<<"$section"
    echo "[ ${section_title} ]"
    for item in "${LUOPO_CLUSTER_ITEMS[@]}"; do
      if [[ "$(luopo_cluster_item_group "$item")" != "$section_key" ]]; then
        continue
      fi
      printf " %-3s %s\n" "$(luopo_cluster_item_number "$item")." "$(luopo_cluster_item_label "$item")"
    done
    echo "----------------------------------------"
  done

  echo " 0.  返回主菜单"
  echo "========================================"
}

luopo_dispatch_cluster_control_action() {
  local choice="$1"
  local item handler

  if [[ "$choice" == "0" ]]; then
    return 1
  fi

  if ! item="$(luopo_cluster_find_item "$choice")"; then
    luopo_cluster_invalid_choice
    return 0
  fi

  handler="$(luopo_cluster_item_handler "$item")"
  "$handler"
}

luopo_cluster_control_menu() {
  luopo_cluster_bootstrap || return 1

  while true; do
    clear
    send_stats "集群控制中心"
    luopo_render_cluster_control_menu
    read -r -p "请输入你的选择: " sub_choice

    if ! luopo_dispatch_cluster_control_action "$sub_choice"; then
      return 0
    fi
  done
}
