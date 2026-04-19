#!/usr/bin/env bash
set -euo pipefail

# Timezone, DNS, update, cleanup, and Fail2ban helpers.

current_timezone() {
  if grep -q 'Alpine' /etc/issue 2>/dev/null; then
    date +"%Z %z"
  elif command -v timedatectl >/dev/null 2>&1; then
    timedatectl | awk '/Time zone/ {print $3}'
  elif [[ -f /etc/timezone ]]; then
    cat /etc/timezone
  else
    echo "UTC"
  fi
}

set_timedate() {
  local shiqu="$1"
  if grep -q 'Alpine' /etc/issue 2>/dev/null; then
    install tzdata
    cp "/usr/share/zoneinfo/${shiqu}" /etc/localtime
    hwclock --systohc 2>/dev/null || true
  elif command -v timedatectl >/dev/null 2>&1; then
    timedatectl set-timezone "${shiqu}"
  else
    ln -sf "/usr/share/zoneinfo/${shiqu}" /etc/localtime
    echo "${shiqu}" > /etc/timezone
  fi
}

luopo_system_tools_write_dns() {
  local dns1_ipv4="$1"
  local dns2_ipv4="$2"
  local dns1_ipv6="${3:-}"
  local dns2_ipv6="${4:-}"
  local resolv_conf="/etc/resolv.conf"

  cp -f "$resolv_conf" "${resolv_conf}.bak.$(date +%s)" 2>/dev/null || true
  {
    echo "nameserver $dns1_ipv4"
    echo "nameserver $dns2_ipv4"
    [[ -n "$dns1_ipv6" ]] && echo "nameserver $dns1_ipv6"
    [[ -n "$dns2_ipv6" ]] && echo "nameserver $dns2_ipv6"
  } > "$resolv_conf"
}

auto_optimize_dns() {
  local country dns1_ipv4 dns2_ipv4 dns1_ipv6 dns2_ipv6
  country="$(curl -s --max-time 5 ipinfo.io/country | tr -d '\r\n')"

  if [[ "$country" == "CN" ]]; then
    dns1_ipv4="223.5.5.5"
    dns2_ipv4="183.60.83.19"
    dns1_ipv6="2400:3200::1"
    dns2_ipv6="2400:da00::6666"
  else
    dns1_ipv4="1.1.1.1"
    dns2_ipv4="8.8.8.8"
    dns1_ipv6="2606:4700:4700::1111"
    dns2_ipv6="2001:4860:4860::8888"
  fi

  luopo_system_tools_write_dns "$dns1_ipv4" "$dns2_ipv4" "$dns1_ipv6" "$dns2_ipv6"
  echo "DNS 已优化为: $dns1_ipv4 $dns2_ipv4 ${dns1_ipv6:-} ${dns2_ipv6:-}"
  send_stats "DNS 已自动优化"
}

linux_update() {
  echo -e "${gl_kjlan}正在系统更新...${gl_bai}"
  if command -v dnf >/dev/null 2>&1; then
    dnf -y update
  elif command -v yum >/dev/null 2>&1; then
    yum -y update
  elif command -v apt >/dev/null 2>&1; then
    fix_dpkg
    DEBIAN_FRONTEND=noninteractive apt update -y
    DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
  elif command -v apk >/dev/null 2>&1; then
    apk update && apk upgrade
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Syu --noconfirm
  elif command -v zypper >/dev/null 2>&1; then
    zypper refresh
    zypper update -y
  elif command -v opkg >/dev/null 2>&1; then
    opkg update
  else
    echo "未知的包管理器!"
  fi
}

linux_clean() {
  echo -e "${gl_kjlan}正在系统清理...${gl_bai}"
  if command -v dnf >/dev/null 2>&1; then
    rpm --rebuilddb
    dnf autoremove -y
    dnf clean all
    dnf makecache
  elif command -v yum >/dev/null 2>&1; then
    rpm --rebuilddb
    yum autoremove -y
    yum clean all
    yum makecache
  elif command -v apt >/dev/null 2>&1; then
    fix_dpkg
    apt autoremove --purge -y
    apt clean -y
    apt autoclean -y
  elif command -v apk >/dev/null 2>&1; then
    apk cache clean
    rm -rf /var/log/* /var/cache/apk/* /tmp/* /var/tmp/* 2>/dev/null || true
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Sc --noconfirm
  elif command -v zypper >/dev/null 2>&1; then
    zypper clean --all
  fi

  journalctl --rotate >/dev/null 2>&1 || true
  journalctl --vacuum-time=1s >/dev/null 2>&1 || true
  journalctl --vacuum-size=500M >/dev/null 2>&1 || true
}

f2b_status() {
  fail2ban-client reload >/dev/null 2>&1 || true
  sleep 1
  fail2ban-client status
}

f2b_install_sshd() {
  docker rm -f fail2ban >/dev/null 2>&1 || true
  install fail2ban
  systemctl enable --now fail2ban 2>/dev/null || service fail2ban start 2>/dev/null || true

  if command -v dnf >/dev/null 2>&1; then
    mkdir -p /etc/fail2ban/jail.d/
    curl -sS -o /etc/fail2ban/jail.d/centos-ssh.conf "${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/centos-ssh.conf"
  fi

  if command -v apt >/dev/null 2>&1; then
    install rsyslog
    systemctl enable --now rsyslog 2>/dev/null || service rsyslog start 2>/dev/null || true
  fi
}

luopo_system_tools_fail2ban_status_label() {
  if command -v fail2ban-client >/dev/null 2>&1 && fail2ban-client ping >/dev/null 2>&1; then
    printf '%b已安装%b' "$gl_lv" "$gl_bai"
  else
    printf '%b未安装%b' "$gl_hui" "$gl_bai"
  fi
}
