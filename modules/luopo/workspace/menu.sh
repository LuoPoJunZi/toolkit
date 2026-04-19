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
  local section section_key section_title item
  echo "========================================"
  echo "后台工作区"
  echo "========================================"
  echo "说明: 后台工作区可长期运行任务，断开 SSH 后任务仍会继续。"
  echo "提示: 进入工作区后按 Ctrl+b，再按 d，可退出工作区。"
  echo
  echo "[ 当前工作区 ]"
  luopo_workspace_list_sessions
  echo "----------------------------------------"

  for section in "${LUOPO_WORKSPACE_SECTIONS[@]}"; do
    IFS='|' read -r section_key section_title <<<"$section"
    echo "[ ${section_title} ]"
    for item in "${LUOPO_WORKSPACE_ITEMS[@]}"; do
      if [[ "$(luopo_workspace_item_group "$item")" != "$section_key" ]]; then
        continue
      fi
      printf " %-3s %s\n" "$(luopo_workspace_item_number "$item")." "$(luopo_workspace_item_label "$item")"
    done
    echo "----------------------------------------"
  done

  echo " 0.  返回主菜单"
  echo "========================================"
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
