#!/usr/bin/env bash
set -euo pipefail

LUOPO_ORACLE_CLOUD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_ORACLE_CLOUD_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_ORACLE_CLOUD_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_ORACLE_CLOUD_DIR/actions.sh"

luopo_render_oracle_cloud_menu() {
  local item number
  echo "========================================"
  echo "甲骨文云脚本合集"
  echo "========================================"
  echo "[ 保活与系统 ]"
  for item in "${LUOPO_ORACLE_CLOUD_ITEMS[@]}"; do
    number="$(luopo_oracle_cloud_item_number "$item")"
    case "$number" in
      1|2|3|4)
        printf " %-3s %s\n" "${number}." "$(luopo_oracle_cloud_item_label "$item")"
        ;;
    esac
  done
  echo "----------------------------------------"
  echo "[ 账户与网络 ]"
  for item in "${LUOPO_ORACLE_CLOUD_ITEMS[@]}"; do
    number="$(luopo_oracle_cloud_item_number "$item")"
    case "$number" in
      5|6)
        printf " %-3s %s\n" "${number}." "$(luopo_oracle_cloud_item_label "$item")"
        ;;
    esac
  done
  echo "----------------------------------------"
  echo " 0.  返回主菜单"
  echo "========================================"
}

luopo_dispatch_oracle_cloud_action() {
  local choice="$1"
  local item handler
  if [[ "$choice" == "0" ]]; then
    return 1
  fi
  if ! item="$(luopo_oracle_cloud_find_item "$choice")"; then
    luopo_oracle_cloud_invalid_choice
    return 0
  fi
  handler="$(luopo_oracle_cloud_item_handler "$item")"
  "$handler"
}

luopo_oracle_cloud_menu() {
  luopo_oracle_cloud_bootstrap || return 1

  while true; do
    clear
    luopo_render_oracle_cloud_menu
    read -r -p "请输入你的选择: " sub_choice

    if ! luopo_dispatch_oracle_cloud_action "$sub_choice"; then
      return 0
    fi
  done
}
