#!/usr/bin/env bash
set -euo pipefail

# Security scan, disk, reinstall, and kernel menus.

luopo_system_tools_clamav_freshclam() {
  echo -e "${gl_kjlan:-}正在更新病毒库...${gl_bai:-}"
  docker volume create clam_db >/dev/null 2>&1
  docker run --rm \
    --name luopo-clamav-update \
    --mount source=clam_db,target=/var/lib/clamav \
    clamav/clamav-debian:latest \
    freshclam
}

luopo_system_tools_clamav_scan() {
  local dirs=("$@")
  local mount_args=()
  local scan_args=()
  local dir

  if [[ ${#dirs[@]} -eq 0 ]]; then
    echo "请指定要扫描的目录。"
    return 1
  fi

  for dir in "${dirs[@]}"; do
    if [[ ! -e "$dir" ]]; then
      echo "跳过不存在的目录或文件: $dir"
      continue
    fi
    mount_args+=(--mount "type=bind,source=$dir,target=/mnt/host$dir,readonly")
    scan_args+=("/mnt/host$dir")
  done

  if [[ ${#scan_args[@]} -eq 0 ]]; then
    echo "没有可扫描的有效路径。"
    return 1
  fi

  mkdir -p /home/docker/clamav/log/
  : > /home/docker/clamav/log/scan.log
  echo -e "${gl_kjlan:-}正在扫描: ${dirs[*]}${gl_bai:-}"
  docker run --rm \
    --name luopo-clamav-scan \
    --mount source=clam_db,target=/var/lib/clamav \
    "${mount_args[@]}" \
    -v /home/docker/clamav/log/:/var/log/clamav/ \
    clamav/clamav-debian:latest \
    clamscan -r --log=/var/log/clamav/scan.log "${scan_args[@]}"

  echo -e "${gl_lv:-}扫描完成，病毒报告: ${gl_huang:-}/home/docker/clamav/log/scan.log${gl_bai:-}"
  echo -e "${gl_lv:-}如有病毒，请在 scan.log 中搜索 FOUND 确认位置。${gl_bai:-}"
}

luopo_system_tools_clamav_menu() {
  root_use
  send_stats "病毒扫描管理"

  while true; do
    clear
    echo "ClamAV 病毒扫描工具"
    echo "------------------------"
    echo "开源防病毒工具，可检测病毒、木马、间谍软件、恶意脚本等。"
    echo "扫描通过 Docker 容器执行，不在宿主机长期安装扫描服务。"
    echo "------------------------"
    echo "1. 全盘扫描"
    echo "2. 重要目录扫描"
    echo "3. 自定义目录扫描"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice

    case "$sub_choice" in
      1)
        send_stats "全盘扫描"
        install_docker
        luopo_system_tools_clamav_freshclam
        luopo_system_tools_clamav_scan /
        ;;
      2)
        send_stats "重要目录扫描"
        install_docker
        luopo_system_tools_clamav_freshclam
        luopo_system_tools_clamav_scan /etc /var /usr /home /root
        ;;
      3)
        local directories
        send_stats "自定义目录扫描"
        read -r -p "请输入要扫描的目录，用空格分隔（例如：/etc /var /usr /home /root）: " directories
        install_docker
        luopo_system_tools_clamav_freshclam
        # shellcheck disable=SC2206
        luopo_system_tools_clamav_scan $directories
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

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

luopo_system_tools_reinstall_menu() {
  root_use
  send_stats "重装系统"

  while true; do
    clear
    echo "重装系统"
    echo "--------------------------------"
    echo -e "${gl_hong:-}注意:${gl_bai:-} 重装有失联风险，请提前备份数据并确认服务商支持重装脚本。"
    echo "使用 bin456789/reinstall 项目执行，执行后通常会自动重启。"
    echo "--------------------------------"
    echo "1. Debian 13                  2. Debian 12"
    echo "3. Debian 11                  4. Debian 10"
    echo "--------------------------------"
    echo "11. Ubuntu 24.04              12. Ubuntu 22.04"
    echo "13. Ubuntu 20.04              14. Ubuntu 18.04"
    echo "--------------------------------"
    echo "21. Rocky Linux 9             22. Alma Linux 9"
    echo "23. Oracle Linux 9            24. Fedora Linux"
    echo "--------------------------------"
    echo "31. Alpine Linux              32. Arch Linux"
    echo "41. Windows 11                42. Windows 10"
    echo "--------------------------------"
    echo "0. 返回上一级选单"
    echo "--------------------------------"
    read -r -p "请选择要重装的系统: " sys_choice

    local reinstall_args=()
    local default_note="重装后请按所选脚本提示记录初始账号、密码和端口。"
    case "$sys_choice" in
      1) reinstall_args=(debian 13) ;;
      2) reinstall_args=(debian 12) ;;
      3) reinstall_args=(debian 11) ;;
      4) reinstall_args=(debian 10) ;;
      11) reinstall_args=(ubuntu 24.04) ;;
      12) reinstall_args=(ubuntu 22.04) ;;
      13) reinstall_args=(ubuntu 20.04) ;;
      14) reinstall_args=(ubuntu 18.04) ;;
      21) reinstall_args=(rocky 9) ;;
      22) reinstall_args=(almalinux 9) ;;
      23) reinstall_args=(oracle 9) ;;
      24) reinstall_args=(fedora) ;;
      31) reinstall_args=(alpine) ;;
      32) reinstall_args=(arch) ;;
      41) reinstall_args=(windows 11); default_note="Windows 初始账号/密码以脚本输出为准，请务必截图保存。" ;;
      42) reinstall_args=(windows 10); default_note="Windows 初始账号/密码以脚本输出为准，请务必截图保存。" ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac

    echo "$default_note"
    echo -e "${gl_hong:-}这是高风险操作，会重装系统并导致当前系统数据丢失。${gl_bai:-}"
    read -r -p "如确认继续，请输入 REINSTALL: " confirm
    if [[ "$confirm" != "REINSTALL" ]]; then
      echo "已取消。"
      break_end
      continue
    fi

    cd ~
    curl -fsSL -o reinstall.sh "${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
    chmod +x reinstall.sh
    bash reinstall.sh "${reinstall_args[@]}"
    echo "重装脚本已执行，如脚本未自动重启，请根据输出手动处理。"
    break_end
  done
}

luopo_system_tools_elrepo_menu() {
  root_use
  send_stats "红帽内核管理"

  if ! command -v rpm >/dev/null 2>&1 || ! { command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; }; then
    echo "ELRepo 内核管理仅支持 RHEL/CentOS/Alma/Rocky/Oracle 等红帽系发行版。"
    return 1
  fi

  local rhel_version
  rhel_version="$(rpm -E '%{rhel}' 2>/dev/null || true)"
  if [[ -z "$rhel_version" || "$rhel_version" == "%{rhel}" ]]; then
    echo "无法识别 RHEL 主版本，已取消。"
    return 1
  fi

  while true; do
    clear
    echo "红帽系 ELRepo 内核管理"
    echo "当前内核版本: $(uname -r)"
    echo "------------------------"
    echo "1. 安装/更新 ELRepo kernel-ml"
    echo "2. 卸载 ELRepo kernel-ml"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice

    case "$sub_choice" in
      1)
        read -r -p "确认安装/更新 ELRepo mainline kernel? (y/N): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { echo "已取消。"; break_end; continue; }
        if command -v dnf >/dev/null 2>&1; then
          dnf install -y "https://www.elrepo.org/elrepo-release-${rhel_version}.el${rhel_version}.elrepo.noarch.rpm"
          dnf --enablerepo=elrepo-kernel install -y kernel-ml
        else
          yum install -y "https://www.elrepo.org/elrepo-release-${rhel_version}.el${rhel_version}.elrepo.noarch.rpm"
          yum --enablerepo=elrepo-kernel install -y kernel-ml
        fi
        grub2-set-default 0 2>/dev/null || true
        echo "ELRepo kernel-ml 已安装/更新，建议确认启动项后重启。"
        ;;
      2)
        read -r -p "确认卸载 ELRepo kernel-ml? (y/N): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { echo "已取消。"; break_end; continue; }
        if command -v dnf >/dev/null 2>&1; then
          dnf remove -y 'kernel-ml*' elrepo-release
        else
          yum remove -y 'kernel-ml*' elrepo-release
        fi
        echo "ELRepo kernel-ml 已卸载，重启后生效。"
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_kernel_write_profile() {
  local mode_name="$1"
  local scene="$2"
  local conf="/etc/sysctl.d/99-luopo-optimize.conf"
  local swappiness dirty_ratio dirty_bg overcommit vfs_pressure rmem_max wmem_max tcp_rmem tcp_wmem somaxconn backlog syn_backlog port_range fin_timeout keepalive_time keepalive_intvl keepalive_probes

  case "$scene" in
    high|stream|game)
      swappiness=10; dirty_ratio=15; dirty_bg=5; overcommit=1; vfs_pressure=50
      rmem_max=67108864; wmem_max=67108864; tcp_rmem="4096 262144 67108864"; tcp_wmem="4096 262144 67108864"
      somaxconn=8192; backlog=250000; syn_backlog=8192; port_range="1024 65535"; fin_timeout=10
      keepalive_time=300; keepalive_intvl=30; keepalive_probes=5
      ;;
    web)
      swappiness=10; dirty_ratio=20; dirty_bg=10; overcommit=1; vfs_pressure=50
      rmem_max=33554432; wmem_max=33554432; tcp_rmem="4096 131072 33554432"; tcp_wmem="4096 131072 33554432"
      somaxconn=16384; backlog=10000; syn_backlog=16384; port_range="1024 65535"; fin_timeout=15
      keepalive_time=600; keepalive_intvl=60; keepalive_probes=5
      ;;
    *)
      swappiness=30; dirty_ratio=20; dirty_bg=10; overcommit=0; vfs_pressure=75
      rmem_max=16777216; wmem_max=16777216; tcp_rmem="4096 87380 16777216"; tcp_wmem="4096 65536 16777216"
      somaxconn=4096; backlog=5000; syn_backlog=4096; port_range="1024 49151"; fin_timeout=30
      keepalive_time=600; keepalive_intvl=60; keepalive_probes=5
      ;;
  esac

  cat > "$conf" <<EOF
# 模式: $mode_name | generated by LuoPo VPS Toolkit
vm.swappiness = $swappiness
vm.dirty_ratio = $dirty_ratio
vm.dirty_background_ratio = $dirty_bg
vm.overcommit_memory = $overcommit
vm.vfs_cache_pressure = $vfs_pressure
net.core.rmem_max = $rmem_max
net.core.wmem_max = $wmem_max
net.ipv4.tcp_rmem = $tcp_rmem
net.ipv4.tcp_wmem = $tcp_wmem
net.core.somaxconn = $somaxconn
net.core.netdev_max_backlog = $backlog
net.ipv4.tcp_max_syn_backlog = $syn_backlog
net.ipv4.ip_local_port_range = $port_range
net.ipv4.tcp_fin_timeout = $fin_timeout
net.ipv4.tcp_keepalive_time = $keepalive_time
net.ipv4.tcp_keepalive_intvl = $keepalive_intvl
net.ipv4.tcp_keepalive_probes = $keepalive_probes
EOF
  sysctl -p "$conf"
  echo "$mode_name 已应用。"
}

luopo_system_tools_kernel_restore_defaults() {
  rm -f /etc/sysctl.d/99-luopo-optimize.conf /etc/sysctl.d/99-kejilion-optimize.conf /etc/sysctl.d/99-network-optimize.conf
  sysctl --system >/dev/null 2>&1 || true
  echo "已移除工具写入的内核优化配置。"
}

luopo_system_tools_kernel_optimize_menu() {
  root_use
  while true; do
    local current_mode
    current_mode="$(grep '^# 模式:' /etc/sysctl.d/99-luopo-optimize.conf 2>/dev/null | sed 's/# 模式: //' | awk -F'|' '{print $1}' | xargs || true)"
    clear
    send_stats "Linux内核调优管理"
    echo "Linux系统内核参数优化"
    if [[ -n "$current_mode" ]]; then
      echo -e "当前模式: ${gl_lv:-}${current_mode}${gl_bai:-}"
    else
      echo -e "当前模式: ${gl_hui:-}未优化${gl_bai:-}"
    fi
    echo "------------------------------------------------"
    echo -e "${gl_huang:-}提示:${gl_bai:-} 生产环境请谨慎使用，建议先备份配置。"
    echo "1. 高性能优化模式"
    echo "2. 均衡优化模式"
    echo "3. 网站优化模式"
    echo "4. 直播优化模式"
    echo "5. 游戏服优化模式"
    echo "6. 还原默认设置"
    echo "7. 自动调优（使用外部 network-optimize 脚本）"
    echo "--------------------"
    echo "0. 返回上一级选单"
    echo "--------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1) luopo_system_tools_kernel_write_profile "高性能优化模式" "high" ;;
      2) luopo_system_tools_kernel_write_profile "均衡优化模式" "balanced" ;;
      3) luopo_system_tools_kernel_write_profile "网站优化模式" "web" ;;
      4) luopo_system_tools_kernel_write_profile "直播优化模式" "stream" ;;
      5) luopo_system_tools_kernel_write_profile "游戏服优化模式" "game" ;;
      6) luopo_system_tools_kernel_restore_defaults ;;
      7) curl -sS "${gh_proxy}raw.githubusercontent.com/kejilion/sh/refs/heads/main/network-optimize.sh" | bash ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}
