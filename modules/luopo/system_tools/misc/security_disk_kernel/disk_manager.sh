#!/usr/bin/env bash
set -euo pipefail

# Disk partition, mount, format, and health menu.

luopo_system_tools_disk_list_partitions() {
  echo "可用的硬盘分区："
  lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -vE 'sr|loop' || true
}

luopo_system_tools_disk_list_mounted() {
  echo "已挂载的分区："
  df -h | grep -vE 'tmpfs|udev|overlay' || true
}

luopo_system_tools_disk_mount_partition() {
  local partition device mount_point uuid fstype

  send_stats "挂载分区"
  read -r -p "请输入要挂载的分区名称（例如 sda1）: " partition
  device="/dev/$partition"
  mount_point="/mnt/$partition"

  if [[ -z "$partition" || ! -b "$device" ]]; then
    echo "分区不存在。"
    return 1
  fi
  if findmnt -rn -S "$device" >/dev/null 2>&1; then
    echo "分区已经挂载。"
    return 1
  fi

  uuid="$(blkid -s UUID -o value "$device" 2>/dev/null || true)"
  fstype="$(blkid -s TYPE -o value "$device" 2>/dev/null || true)"
  if [[ -z "$uuid" || -z "$fstype" ]]; then
    echo "无法获取 UUID 或文件系统类型。"
    return 1
  fi

  mkdir -p "$mount_point"
  if ! mount "$device" "$mount_point"; then
    echo "分区挂载失败。"
    rmdir "$mount_point" 2>/dev/null || true
    return 1
  fi

  echo "分区已挂载到 $mount_point"
  if grep -qE "UUID=$uuid|[[:space:]]$mount_point[[:space:]]" /etc/fstab 2>/dev/null; then
    echo "/etc/fstab 中已存在该分区记录，跳过写入。"
    return 0
  fi
  printf 'UUID=%s %s %s defaults,nofail 0 2\n' "$uuid" "$mount_point" "$fstype" >> /etc/fstab
  echo "已写入 /etc/fstab，实现持久化挂载。"
}

luopo_system_tools_disk_unmount_partition() {
  local partition device mount_point

  send_stats "卸载分区"
  read -r -p "请输入要卸载的分区名称（例如 sda1）: " partition
  device="/dev/$partition"
  if [[ -z "$partition" || ! -b "$device" ]]; then
    echo "分区不存在。"
    return 1
  fi

  mount_point="$(findmnt -rn -S "$device" -o TARGET 2>/dev/null || true)"
  if [[ -z "$mount_point" ]]; then
    echo "分区未挂载。"
    return 1
  fi

  if umount "$device"; then
    echo "分区卸载成功: $mount_point"
    rmdir "$mount_point" 2>/dev/null || true
  else
    echo "分区卸载失败。"
  fi
}

luopo_system_tools_disk_format_partition() {
  local partition device fs_choice fs_type confirm

  send_stats "格式化分区"
  read -r -p "请输入要格式化的分区名称（例如 sda1）: " partition
  device="/dev/$partition"
  if [[ -z "$partition" || ! -b "$device" ]]; then
    echo "分区不存在。"
    return 1
  fi
  if findmnt -rn -S "$device" >/dev/null 2>&1; then
    echo "分区已经挂载，请先卸载。"
    return 1
  fi

  echo "请选择文件系统类型："
  echo "1. ext4"
  echo "2. xfs"
  echo "3. ntfs"
  echo "4. vfat"
  read -r -p "请输入你的选择: " fs_choice
  case "$fs_choice" in
    1) fs_type="ext4" ;;
    2) fs_type="xfs" ;;
    3) fs_type="ntfs" ;;
    4) fs_type="vfat" ;;
    *)
      echo "无效的选择。"
      return 1
      ;;
  esac

  echo "危险操作：格式化会清空 $device 上的所有数据。"
  read -r -p "如确认格式化，请输入 FORMAT: " confirm
  if [[ "$confirm" != "FORMAT" ]]; then
    echo "操作已取消。"
    return 0
  fi

  if ! command -v "mkfs.$fs_type" >/dev/null 2>&1; then
    case "$fs_type" in
      xfs) install xfsprogs ;;
      ntfs) install ntfs-3g ;;
      vfat) install dosfstools ;;
      ext4) install e2fsprogs ;;
    esac
  fi
  if ! command -v "mkfs.$fs_type" >/dev/null 2>&1; then
    echo "未找到 mkfs.$fs_type，无法格式化。"
    return 1
  fi
  echo "正在格式化 $device 为 $fs_type ..."
  "mkfs.$fs_type" "$device"
}

luopo_system_tools_disk_check_partition() {
  local partition device

  send_stats "检查分区状态"
  read -r -p "请输入要检查的分区名称（例如 sda1）: " partition
  device="/dev/$partition"
  if [[ -z "$partition" || ! -b "$device" ]]; then
    echo "分区不存在。"
    return 1
  fi
  fsck "$device"
}

luopo_system_tools_disk_manager_menu() {
  root_use
  send_stats "硬盘管理功能"

  while true; do
    clear
    echo "硬盘分区管理"
    echo -e "${gl_huang:-}高风险功能：请勿对系统盘或生产数据盘随意操作。${gl_bai:-}"
    echo "------------------------"
    luopo_system_tools_disk_list_partitions
    echo "------------------------"
    echo "1. 挂载分区"
    echo "2. 卸载分区"
    echo "3. 查看已挂载分区"
    echo "4. 格式化分区"
    echo "5. 检查分区状态"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice
    case "$choice" in
      1) luopo_system_tools_disk_mount_partition ;;
      2) luopo_system_tools_disk_unmount_partition ;;
      3) luopo_system_tools_disk_list_mounted ;;
      4) luopo_system_tools_disk_format_partition ;;
      5) luopo_system_tools_disk_check_partition ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}
