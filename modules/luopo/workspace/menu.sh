#!/usr/bin/env bash
set -euo pipefail

LUOPO_WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_WORKSPACE_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_WORKSPACE_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_WORKSPACE_DIR/actions.sh"

luopo_render_workspace_menu() {
  echo "后台工作区"
  echo "系统将为你提供可以后台常驻运行的工作区，你可以用来执行长时间的任务"
  echo "即使你断开SSH，工作区中的任务也不会中断，后台常驻任务。"
  echo "提示: 进入工作区后使用Ctrl+b再单独按d，退出工作区！"
  echo "------------------------"
  echo "当前已存在的工作区列表"
  echo "------------------------"
  luopo_workspace_list_sessions
  echo "------------------------"

  local section section_key section_title item
  for section in "${LUOPO_WORKSPACE_SECTIONS[@]}"; do
    IFS='|' read -r section_key section_title <<<"$section"
    for item in "${LUOPO_WORKSPACE_ITEMS[@]}"; do
      if [[ "$(luopo_workspace_item_group "$item")" != "$section_key" ]]; then
        continue
      fi
      printf "%-4s %s\n" "$(luopo_workspace_item_number "$item")." "$(luopo_workspace_item_label "$item")"
    done
    echo "------------------------"
  done

  echo "0.   返回主菜单"
  echo "------------------------"
}

luopo_dispatch_workspace_action() {
  local choice="$1"
  local item handler

  if [[ "$choice" == "0" ]]; then
    return 1
  fi

  if ! item="$(luopo_workspace_find_item "$choice")"; then
    luopo_workspace_invalid_choice
    return 0
  fi

  handler="$(luopo_workspace_item_handler "$item")"
  "$handler"
}

luopo_workspace_menu() {
  luopo_workspace_bootstrap || return 1

  while true; do
    clear
    send_stats "后台工作区"
    luopo_render_workspace_menu
    read -r -p "请输入你的选择: " sub_choice

    if ! luopo_dispatch_workspace_action "$sub_choice"; then
      return 0
    fi
  done
}
