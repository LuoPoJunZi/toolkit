#!/usr/bin/env bash
set -euo pipefail

# ClamAV update and scan menu.

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
