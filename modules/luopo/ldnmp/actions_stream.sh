#!/usr/bin/env bash
set -euo pipefail

luopo_ldnmp_stream_proxy() {
  root_use || return 1
  nginx_install_status || return 1
  mkdir -p /home/web/stream.d

  while true; do
    clear
    echo "Stream四层代理转发"
    echo "------------------------"
    luopo_ldnmp_stream_list
    echo "------------------------"
    echo "1. 添加 TCP 转发"
    echo "2. 添加 UDP 转发"
    echo "3. 删除转发规则"
    echo "4. 重载 Nginx"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1) luopo_ldnmp_stream_add tcp ;;
      2) luopo_ldnmp_stream_add udp ;;
      3) luopo_ldnmp_stream_delete ;;
      4) docker exec nginx nginx -s reload && echo "Nginx 已重载" ;;
      0) return 0 ;;
      *) luopo_ldnmp_invalid_choice; continue ;;
    esac
    break_end
  done
}

luopo_ldnmp_stream_list() {
  if [[ ! -d /home/web/stream.d ]] || [[ -z "$(ls -A /home/web/stream.d 2>/dev/null)" ]]; then
    echo "暂无转发规则"
    return 0
  fi
  printf "%-24s %-8s %-18s %-24s\n" "服务名" "协议" "监听端口" "后端地址"
  local conf name proto listen backend
  for conf in /home/web/stream.d/*.conf; do
    [[ -f "$conf" ]] || continue
    name="$(basename "$conf" .conf)"
    proto="$(grep -qi 'udp' "$conf" && echo udp || echo tcp)"
    listen="$(grep -Po 'listen\s+\K[^;]+' "$conf" | head -1)"
    backend="$(grep -Po 'server\s+\K[^;]+' "$conf" | head -1)"
    printf "%-24s %-8s %-18s %-24s\n" "$name" "$proto" "$listen" "$backend"
  done
}

luopo_ldnmp_stream_add() {
  local proto="$1"
  local name listen_port backend
  read -r -p "服务名（英文/数字/横线）: " name
  read -r -p "本机监听端口: " listen_port
  read -r -p "后端地址 IP:端口: " backend
  [[ "$name" =~ ^[A-Za-z0-9_-]+$ && -n "$listen_port" && -n "$backend" ]] || { echo "输入不完整或服务名不合法"; return 1; }

  local listen_directive
  listen_directive="listen ${listen_port};"
  [[ "$proto" == "udp" ]] && listen_directive="listen ${listen_port} udp;"

  cat > "/home/web/stream.d/${name}.conf" <<EOF
upstream ${name}_backend {
    server ${backend};
}

server {
    ${listen_directive}
    proxy_pass ${name}_backend;
}
EOF
  docker exec nginx nginx -s reload >/dev/null 2>&1 || true
  echo "Stream 转发规则已添加: $name"
}

luopo_ldnmp_stream_delete() {
  local name
  read -r -p "请输入要删除的服务名: " name
  [[ -n "$name" ]] || return 0
  rm -f "/home/web/stream.d/${name}.conf"
  docker exec nginx nginx -s reload >/dev/null 2>&1 || true
  echo "Stream 转发规则已删除: $name"
}
