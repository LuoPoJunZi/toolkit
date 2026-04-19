#!/usr/bin/env bash
set -euo pipefail

# Common bootstrap and package-recovery helpers.

luopo_system_tools_bootstrap() {
  return 0
}

root_use() {
  if [[ "$EUID" -ne 0 ]]; then
    echo -e "${gl_huang}提示: ${gl_bai}该功能需要root用户才能运行！"
    break_end
    return 1
  fi
}

check_crontab_installed() {
  if command -v crontab >/dev/null 2>&1; then
    return 0
  fi

  if command -v apt >/dev/null 2>&1; then
    apt update -y
    apt install -y cron
    systemctl enable --now cron 2>/dev/null || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y cronie
    systemctl enable --now crond 2>/dev/null || true
  elif command -v yum >/dev/null 2>&1; then
    yum install -y cronie
    systemctl enable --now crond 2>/dev/null || true
  elif command -v apk >/dev/null 2>&1; then
    apk add dcron
    rc-service dcron start 2>/dev/null || true
    rc-update add dcron default 2>/dev/null || true
  else
    echo "未检测到可用包管理器，无法安装 crontab。"
    return 1
  fi
}

fix_dpkg() {
  pkill -9 -f 'apt|dpkg' >/dev/null 2>&1 || true
  rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
  DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}
