#!/usr/bin/env bash
set -euo pipefail

luopo_ldnmp_launch_compat() {
  run_luopo_compat_menu linux_ldnmp
}

luopo_ldnmp_install_all() {
  ldnmp_install_status_one
  ldnmp_install_all
}

luopo_ldnmp_install_wordpress() {
  ldnmp_wp
}

luopo_ldnmp_install_nginx_only() {
  ldnmp_install_status_one
  nginx_install_all
}

luopo_ldnmp_reverse_proxy_ip_port() {
  ldnmp_Proxy
}

luopo_ldnmp_reverse_proxy_load_balance() {
  ldnmp_Proxy_backend
}

luopo_ldnmp_stream_proxy() {
  stream_panel
}

luopo_ldnmp_site_status() {
  ldnmp_web_status
}

luopo_ldnmp_security() {
  web_security
}

luopo_ldnmp_optimization() {
  web_optimization
}

luopo_ldnmp_dispatch_choice() {
  local choice="$1"
  case "$choice" in
    0) return 1 ;;
    1) luopo_ldnmp_install_all ;;
    2) luopo_ldnmp_install_wordpress ;;
    21) luopo_ldnmp_install_nginx_only ;;
    23) luopo_ldnmp_reverse_proxy_ip_port ;;
    28) luopo_ldnmp_reverse_proxy_load_balance ;;
    29) luopo_ldnmp_stream_proxy ;;
    31) luopo_ldnmp_site_status ;;
    35) luopo_ldnmp_security ;;
    36) luopo_ldnmp_optimization ;;
    *)
      echo "该功能当前仍使用兼容实现，正在切换..."
      press_enter
      luopo_ldnmp_launch_compat
      ;;
  esac
  return 0
}

