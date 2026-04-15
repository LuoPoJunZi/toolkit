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
  echo "甲骨文云脚本合集"
  echo "------------------------"
  local item
  for item in "${LUOPO_ORACLE_CLOUD_ITEMS[@]}"; do
    printf "%-4s %s\n" "$(luopo_oracle_cloud_item_number "$item")." "$(luopo_oracle_cloud_item_label "$item")"
    case "$(luopo_oracle_cloud_item_number "$item")" in
      2|6)
        echo "------------------------"
        ;;
    esac
  done
  echo "0.   返回主菜单"
  echo "------------------------"
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
    echo "甲骨文云脚本合集"
    echo "------------------------"
    echo "1.   安装闲置机器活跃脚本"
    echo "2.   卸载闲置机器活跃脚本"
    echo "------------------------"
    echo "3.   DD重装系统脚本"
    echo "4.   R探长开机脚本"
    echo "5.   开启ROOT密码登录模式"
    echo "6.   IPV6恢复工具"
    echo "------------------------"
    echo "0.   返回主菜单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice

    if ! luopo_dispatch_oracle_cloud_action "$sub_choice"; then
      return 0
    fi
  done
}
