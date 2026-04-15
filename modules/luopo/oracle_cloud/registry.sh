#!/usr/bin/env bash
set -euo pipefail

LUOPO_ORACLE_CLOUD_ITEMS=(
  "1|安装闲置机器活跃脚本|luopo_oracle_cloud_install_lookbusy"
  "2|卸载闲置机器活跃脚本|luopo_oracle_cloud_remove_lookbusy"
  "3|DD重装系统脚本|luopo_oracle_cloud_dd_reinstall"
  "4|R探长开机脚本|luopo_oracle_cloud_r_helper"
  "5|开启ROOT密码登录模式|luopo_oracle_cloud_enable_root_password"
  "6|IPV6恢复工具|luopo_oracle_cloud_restore_ipv6"
)

luopo_oracle_cloud_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_ORACLE_CLOUD_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_oracle_cloud_item_number() {
  local item="$1"
  IFS='|' read -r number _ <<<"$item"
  printf '%s\n' "$number"
}

luopo_oracle_cloud_item_label() {
  local item="$1"
  IFS='|' read -r _ label _ <<<"$item"
  printf '%s\n' "$label"
}

luopo_oracle_cloud_item_handler() {
  local item="$1"
  IFS='|' read -r _ _ handler <<<"$item"
  printf '%s\n' "$handler"
}
