#!/usr/bin/env bash
set -euo pipefail

LUOPO_WARP_SECTIONS=(
  "status|状态信息"
  "manage|安装与管理"
  "ops|常用操作"
)

LUOPO_WARP_ITEMS=(
  "1|查看 WARP 状态|luopo_warp_status|status"
  "2|查看当前 IP 与出口信息|luopo_warp_ip_info|status"
  "3|检测 IPv4 / IPv6 连通性|luopo_warp_connectivity_test|status"
  "11|打开 WARP 官方管理脚本|luopo_warp_launch_menu|manage"
  "12|安装 / 更新 WARP|luopo_warp_install_or_update|manage"
  "13|卸载 WARP|luopo_warp_uninstall|manage"
  "21|启动 WARP|luopo_warp_start|ops"
  "22|停止 WARP|luopo_warp_stop|ops"
  "23|重启 WARP|luopo_warp_restart|ops"
  "24|切换 WARP 模式|luopo_warp_mode_menu|ops"
)

luopo_warp_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_WARP_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_warp_item_number() {
  local item="$1"
  IFS='|' read -r number _ <<<"$item"
  printf '%s\n' "$number"
}

luopo_warp_item_label() {
  local item="$1"
  IFS='|' read -r _ label _ <<<"$item"
  printf '%s\n' "$label"
}

luopo_warp_item_handler() {
  local item="$1"
  IFS='|' read -r _ _ handler _ <<<"$item"
  printf '%s\n' "$handler"
}

luopo_warp_item_group() {
  local item="$1"
  IFS='|' read -r _ _ _ group <<<"$item"
  printf '%s\n' "$group"
}
