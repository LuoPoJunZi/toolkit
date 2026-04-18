#!/usr/bin/env bash
set -euo pipefail

LUOPO_WORKSPACE_SECTIONS=(
  "fixed|固定工作区"
  "manage|工作区管理"
)

LUOPO_WORKSPACE_ITEMS=(
  "1|1号工作区|luopo_workspace_open_work1|fixed"
  "2|2号工作区|luopo_workspace_open_work2|fixed"
  "3|3号工作区|luopo_workspace_open_work3|fixed"
  "4|4号工作区|luopo_workspace_open_work4|fixed"
  "5|5号工作区|luopo_workspace_open_work5|fixed"
  "6|6号工作区|luopo_workspace_open_work6|fixed"
  "7|7号工作区|luopo_workspace_open_work7|fixed"
  "8|8号工作区|luopo_workspace_open_work8|fixed"
  "9|9号工作区|luopo_workspace_open_work9|fixed"
  "10|10号工作区|luopo_workspace_open_work10|fixed"
  "21|SSH常驻模式|luopo_workspace_manage_ssh_mode|manage"
  "22|创建/进入工作区|luopo_workspace_enter_custom|manage"
  "23|注入命令到后台工作区|luopo_workspace_inject_command|manage"
  "24|删除指定工作区|luopo_workspace_remove_custom|manage"
)

luopo_workspace_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_WORKSPACE_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_workspace_item_number() {
  local item="$1"
  IFS='|' read -r number _ <<<"$item"
  printf '%s\n' "$number"
}

luopo_workspace_item_label() {
  local item="$1"
  IFS='|' read -r _ label _ <<<"$item"
  printf '%s\n' "$label"
}

luopo_workspace_item_handler() {
  local item="$1"
  IFS='|' read -r _ _ handler _ <<<"$item"
  printf '%s\n' "$handler"
}

luopo_workspace_item_group() {
  local item="$1"
  IFS='|' read -r _ _ _ group <<<"$item"
  printf '%s\n' "$group"
}
