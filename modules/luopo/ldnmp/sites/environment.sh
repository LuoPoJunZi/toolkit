#!/usr/bin/env bash
set -euo pipefail

# LDNMP environment and nginx-only installation actions.

luopo_ldnmp_install_all() {
  cd ~ || return 1
  send_stats "安装LDNMP环境"
  root_use || return 1
  clear
  echo -e "${gl_huang}LDNMP环境未安装，开始安装LDNMP环境...${gl_bai}"
  check_disk_space 3 /home || return 1
  ldnmp_install_status_one
  install_dependency
  install_docker
  install_certbot
  install_ldnmp_conf
  install_ldnmp
}

luopo_ldnmp_install_nginx_only() {
  cd ~ || return 1
  send_stats "安装nginx环境"
  root_use || return 1
  clear
  echo -e "${gl_huang}nginx未安装，开始安装nginx环境...${gl_bai}"
  ldnmp_install_status_one
  install_dependency
  install_docker
  install_certbot
  install_ldnmp_conf
  nginx_upgrade
  clear
  local nginx_version
  nginx_version="$(docker exec nginx nginx -v 2>&1 | grep -oP 'nginx/\K[0-9]+\.[0-9]+\.[0-9]+' || true)"
  echo "nginx已安装完成"
  echo -e "当前版本: ${gl_huang}v${nginx_version:-N/A}${gl_bai}"
  echo
}
