#!/usr/bin/env bash
set -euo pipefail

luopo_bbr_bootstrap() {
  ensure_luopo_vendor_loaded
}

luopo_bbr_finish() {
  break_end
}

luopo_bbr_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

luopo_bbr_current_algorithms() {
  local congestion_algorithm queue_algorithm
  congestion_algorithm="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"
  queue_algorithm="$(sysctl -n net.core.default_qdisc 2>/dev/null || echo unknown)"
  echo "$congestion_algorithm $queue_algorithm"
}

luopo_bbr_run_external_suite() {
  clear
  send_stats "bbr管理"
  set +e
  install wget
  wget --no-check-certificate -O tcpx.sh "${gh_proxy}raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh"
  chmod +x tcpx.sh
  ./tcpx.sh
  set -e
  return 0
}
