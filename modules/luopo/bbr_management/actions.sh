#!/usr/bin/env bash
set -euo pipefail

luopo_bbr_enable_alpine() {
  clear
  send_stats "alpine开启bbr3"
  set +e
  bbr_on
  set -e
  luopo_bbr_finish
  return 0
}

luopo_bbr_disable_alpine() {
  clear
  send_stats "alpine关闭bbr3"
  set +e
  sed -i '/net.ipv4.tcp_congestion_control=/d' /etc/sysctl.conf
  sysctl -p
  set -e
  server_reboot
  return 0
}
