#!/usr/bin/env bash
set -euo pipefail

luopo_ldnmp_optimization() {
  root_use || return 1
  while true; do
    clear
    echo "优化LDNMP环境"
    echo "------------------------"
    echo "1. 标准模式"
    echo "2. 高性能模式"
    echo "3. 开启 gzip 压缩"
    echo "4. 关闭 gzip 压缩"
    echo "5. 开启 brotli/zstd 提示"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1) luopo_ldnmp_apply_performance_profile standard ;;
      2) luopo_ldnmp_apply_performance_profile high ;;
      3) luopo_ldnmp_toggle_nginx_gzip on ;;
      4) luopo_ldnmp_toggle_nginx_gzip off ;;
      5) echo "当前镜像未保证内置 brotli/zstd 模块，建议优先使用 gzip 或自定义 Nginx 镜像。" ;;
      0) return 0 ;;
      *) luopo_ldnmp_invalid_choice; continue ;;
    esac
    break_end
  done
}

luopo_ldnmp_toggle_nginx_gzip() {
  local state="$1"
  local conf="/home/web/nginx.conf"
  [[ -f "$conf" ]] || { echo "未找到 $conf"; return 1; }
  if grep -q 'gzip[[:space:]]\+' "$conf"; then
    sed -i "s/^[[:space:]]*gzip[[:space:]].*/    gzip ${state};/" "$conf"
  else
    sed -i "/http[[:space:]]*{/a\\    gzip ${state};" "$conf"
  fi
  docker exec nginx nginx -s reload >/dev/null 2>&1 || true
  echo "gzip 已设置为: $state"
}

luopo_ldnmp_apply_performance_profile() {
  local mode="$1"
  local conf="/home/web/nginx.conf"
  local cpu_cores connections php_conf mysql_conf
  [[ -f "$conf" ]] || { echo "未找到 $conf"; return 1; }
  cpu_cores="$(nproc 2>/dev/null || echo 1)"
  if [[ "$mode" == "high" ]]; then
    connections=$((2048 * cpu_cores))
    php_conf="www.conf"
    mysql_conf="custom_mysql_config.cnf"
  else
    connections=$((1024 * cpu_cores))
    php_conf="www-1.conf"
    mysql_conf="custom_mysql_config-1.cnf"
  fi
  sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" "$conf"
  sed -i "s/worker_connections.*/worker_connections ${connections};/" "$conf"
  wget -O /home/www.conf "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/${php_conf}" >/dev/null 2>&1 || true
  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf >/dev/null 2>&1 || true
  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf >/dev/null 2>&1 || true
  rm -f /home/www.conf
  wget -O /home/custom_mysql_config.cnf "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/${mysql_conf}" >/dev/null 2>&1 || true
  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/ >/dev/null 2>&1 || true
  rm -f /home/custom_mysql_config.cnf
  fix_phpfpm_conf php
  fix_phpfpm_conf php74
  cd /home/web && docker compose restart
  echo "LDNMP环境已设置为 ${mode} 模式"
}
