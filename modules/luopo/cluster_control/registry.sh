#!/usr/bin/env bash
set -euo pipefail

LUOPO_CLUSTER_SECTIONS=(
  "servers|服务器列表管理"
  "tasks|批量执行任务"
)

LUOPO_CLUSTER_ITEMS=(
  "1|添加服务器|luopo_cluster_add_server|servers"
  "2|删除服务器|luopo_cluster_remove_server|servers"
  "3|编辑服务器|luopo_cluster_edit_server|servers"
  "4|备份集群|luopo_cluster_backup|servers"
  "5|还原集群|luopo_cluster_restore|servers"
  "11|安装LuoPo脚本|luopo_cluster_install_toolkit|tasks"
  "12|更新系统|luopo_cluster_update_system|tasks"
  "13|清理系统|luopo_cluster_clean_system|tasks"
  "14|安装docker|luopo_cluster_install_docker|tasks"
  "15|安装BBR3|luopo_cluster_install_bbr3|tasks"
  "16|设置1G虚拟内存|luopo_cluster_set_swap|tasks"
  "17|设置时区到上海|luopo_cluster_set_timezone|tasks"
  "18|开放所有端口|luopo_cluster_open_ports|tasks"
  "19|自定义指令|luopo_cluster_custom_command|tasks"
)

luopo_cluster_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_CLUSTER_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_cluster_item_number() {
  local item="$1"
  IFS='|' read -r number _ <<<"$item"
  printf '%s\n' "$number"
}

luopo_cluster_item_label() {
  local item="$1"
  IFS='|' read -r _ label _ <<<"$item"
  printf '%s\n' "$label"
}

luopo_cluster_item_handler() {
  local item="$1"
  IFS='|' read -r _ _ handler _ <<<"$item"
  printf '%s\n' "$handler"
}

luopo_cluster_item_group() {
  local item="$1"
  IFS='|' read -r _ _ _ group <<<"$item"
  printf '%s\n' "$group"
}
