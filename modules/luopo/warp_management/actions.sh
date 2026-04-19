#!/usr/bin/env bash
set -euo pipefail

luopo_warp_launch_menu() {
  clear
  send_stats "warp管理"
  install wget
  set +e
  wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
  bash menu.sh [option] [lisence/url/token]
  set -e
}

luopo_warp_status() {
  echo "WARP 状态信息"
  echo "----------------------------------------"
  if command -v warp-cli >/dev/null 2>&1; then
    warp-cli status || true
  else
    echo "未检测到 warp-cli。"
  fi

  if systemctl list-unit-files 2>/dev/null | grep -q '^warp-svc'; then
    echo
    systemctl --no-pager --full status warp-svc 2>/dev/null | sed -n '1,12p' || true
  fi
}

luopo_warp_ip_info() {
  echo "当前 IP 与出口信息"
  echo "----------------------------------------"
  if command -v curl >/dev/null 2>&1; then
    echo "IPv4: $(curl -4 -fsSL --max-time 8 https://ip.sb 2>/dev/null || echo N/A)"
    echo "IPv6: $(curl -6 -fsSL --max-time 8 https://ip.sb 2>/dev/null || echo N/A)"
    echo
    curl -fsSL --max-time 10 https://ipinfo.io 2>/dev/null || true
  else
    echo "缺少 curl，无法查询公网 IP。"
  fi
}

luopo_warp_connectivity_test() {
  echo "IPv4 / IPv6 连通性检测"
  echo "----------------------------------------"
  if command -v ping >/dev/null 2>&1; then
    ping -4 -c 3 1.1.1.1 || true
    echo
    ping -6 -c 3 2606:4700:4700::1111 || true
  else
    echo "缺少 ping，无法检测连通性。"
  fi
}

luopo_warp_install_or_update() {
  echo "将打开 WARP 官方管理脚本，请在脚本内选择安装或更新。"
  luopo_warp_launch_menu
}

luopo_warp_uninstall() {
  echo "将打开 WARP 官方管理脚本，请在脚本内选择卸载。"
  luopo_warp_launch_menu
}

luopo_warp_start() {
  if command -v warp-cli >/dev/null 2>&1; then
    warp-cli connect || true
  elif systemctl list-unit-files 2>/dev/null | grep -q '^warp-svc'; then
    systemctl start warp-svc || true
  else
    echo "未检测到本机 WARP 服务，请先使用官方管理脚本安装。"
  fi
}

luopo_warp_stop() {
  if command -v warp-cli >/dev/null 2>&1; then
    warp-cli disconnect || true
  elif systemctl list-unit-files 2>/dev/null | grep -q '^warp-svc'; then
    systemctl stop warp-svc || true
  else
    echo "未检测到本机 WARP 服务。"
  fi
}

luopo_warp_restart() {
  if systemctl list-unit-files 2>/dev/null | grep -q '^warp-svc'; then
    systemctl restart warp-svc || true
  elif command -v warp-cli >/dev/null 2>&1; then
    warp-cli disconnect || true
    sleep 2
    warp-cli connect || true
  else
    echo "未检测到本机 WARP 服务。"
  fi
}

luopo_warp_mode_menu() {
  local choice
  if ! command -v warp-cli >/dev/null 2>&1; then
    echo "未检测到 warp-cli，无法直接切换模式。"
    echo "你可以打开官方管理脚本进行模式切换。"
    return 0
  fi

  echo "切换 WARP 模式"
  echo "----------------------------------------"
  echo "1. warp"
  echo "2. doh"
  echo "3. proxy"
  echo "----------------------------------------"
  echo "0. 返回"
  echo "========================================"
  read -r -p "请输入你的选择: " choice
  case "$choice" in
    1) warp-cli mode warp || true ;;
    2) warp-cli mode doh || true ;;
    3) warp-cli mode proxy || true ;;
    0) return 0 ;;
    *) echo "无效选项" ;;
  esac
}

luopo_warp_dispatch_choice() {
  local choice="$1"
  local item handler

  if [[ "$choice" == "0" ]]; then
    return 1
  fi

  if ! item="$(luopo_warp_find_item "$choice")"; then
    echo "无效选项"
    return 0
  fi

  handler="$(luopo_warp_item_handler "$item")"
  "$handler"
}
