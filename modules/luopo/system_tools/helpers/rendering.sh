#!/usr/bin/env bash
set -euo pipefail

# Menu rendering and display helpers.

k_info() {
  send_stats "z命令参考用例"
  echo "-------------------"
  echo "视频介绍: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
  echo "以下是 z 命令参考用例："
  echo "启动脚本            z"
  echo "安装软件包          z install nano wget | z add nano wget | z 安装 nano wget"
  echo "卸载软件包          z remove nano wget | z del nano wget | z uninstall nano wget | z 卸载 nano wget"
  echo "更新系统            z update | z 更新"
  echo "清理系统垃圾        z clean | z 清理"
  echo "重装系统面板        z dd | z 重装"
  echo "bbr3控制面板        z bbr3 | z bbrv3"
  echo "内核调优面板        z nhyh | z 内核优化"
  echo "设置虚拟内存        z swap 2048"
  echo "设置虚拟时区        z time Asia/Shanghai | z 时区 Asia/Shanghai"
  echo "系统回收站          z trash | z hsz | z 回收站"
  echo "系统备份功能        z backup | z bf | z 备份"
  echo "ssh远程连接工具     z ssh | z 远程连接"
  echo "rsync远程同步工具   z rsync | z 远程同步"
  echo "硬盘管理工具        z disk | z 硬盘管理"
  echo "内网穿透（服务端）  z frps"
  echo "内网穿透（客户端）  z frpc"
  echo "软件启动            z start sshd | z 启动 sshd"
  echo "软件停止            z stop sshd | z 停止 sshd"
  echo "软件重启            z restart sshd | z 重启 sshd"
  echo "软件状态查看        z status sshd | z 状态 sshd"
  echo "软件开机启动        z enable docker | z autostart docker | z 开机启动 docker"
  echo "域名证书申请        z ssl"
  echo "域名证书到期查询    z ssl ps"
  echo "docker管理平面      z docker"
  echo "docker环境安装      z docker install | z docker 安装"
  echo "docker容器管理      z docker ps | z docker 容器"
  echo "docker镜像管理      z docker img | z docker 镜像"
  echo "LDNMP站点管理       z web"
  echo "LDNMP缓存清理       z web cache"
}

luopo_system_tools_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_SYSTEM_TOOLS_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_system_tools_item_label() {
  local item="$1"
  IFS='|' read -r _ label <<<"$item"
  printf '%s\n' "$label"
}

luopo_system_tools_render_cell() {
  local key="$1"
  local item label
  item="$(luopo_system_tools_find_item "$key")" || return 1
  label="$(luopo_system_tools_item_label "$item")"
  printf "%b%-4s %b%s%b" "$gl_kjlan" "${key}." "$gl_bai" "$label" "$gl_bai"
}

luopo_system_tools_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

luopo_system_tools_current_swap_info() {
  free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}'
}

luopo_system_tools_print_generated_credentials() {
  local i first_name_index last_name_index user_name password uuid username
  local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
  local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

  echo "随机用户名"
  echo "------------------------"
  for i in {1..5}; do
    username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
    echo "随机用户名 $i: $username"
  done

  echo
  echo "随机姓名"
  echo "------------------------"
  for i in {1..5}; do
    first_name_index=$((RANDOM % ${#first_names[@]}))
    last_name_index=$((RANDOM % ${#last_names[@]}))
    user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
    echo "随机用户姓名 $i: $user_name"
  done

  echo
  echo "随机UUID"
  echo "------------------------"
  for i in {1..5}; do
    uuid="$(cat /proc/sys/kernel/random/uuid)"
    echo "随机UUID $i: $uuid"
  done

  echo
  echo "16位随机密码"
  echo "------------------------"
  for i in {1..5}; do
    password="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)"
    echo "随机密码 $i: $password"
  done
}
