#!/usr/bin/env bash
set -euo pipefail

# Root, SSH, firewall, swap, and IP helpers.

prefer_ipv4() {
  grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
  echo "已切换为 IPv4 优先"
  send_stats "已切换为 IPv4 优先"
}

restart_ssh() {
  systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null || service sshd restart 2>/dev/null || true
}

save_iptables_rules() {
  mkdir -p /etc/iptables
  touch /etc/iptables/rules.v4
  iptables-save > /etc/iptables/rules.v4
  check_crontab_installed || return 1
  crontab -l 2>/dev/null | grep -v 'iptables-restore' | crontab - >/dev/null 2>&1 || true
  { crontab -l 2>/dev/null; echo '@reboot iptables-restore < /etc/iptables/rules.v4'; } | crontab - >/dev/null 2>&1
}

iptables_open() {
  install iptables
  save_iptables_rules || true

  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -F

  if command -v ip6tables >/dev/null 2>&1; then
    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -F
  fi
}

open_port() {
  local ports=("$@")
  [[ ${#ports[@]} -gt 0 ]] || { echo "请提供至少一个端口号"; return 1; }

  install iptables

  for port in "${ports[@]}"; do
    iptables -D INPUT -p tcp --dport "$port" -j DROP >/dev/null 2>&1 || true
    iptables -D INPUT -p udp --dport "$port" -j DROP >/dev/null 2>&1 || true

    if ! iptables -C INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1; then
      iptables -I INPUT 1 -p tcp --dport "$port" -j ACCEPT
    fi
    if ! iptables -C INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1; then
      iptables -I INPUT 1 -p udp --dport "$port" -j ACCEPT
    fi
  done

  save_iptables_rules || true
  send_stats "已打开端口"
}

close_port() {
  local ports=("$@")
  [[ ${#ports[@]} -gt 0 ]] || { echo "请提供至少一个端口号"; return 1; }

  install iptables

  for port in "${ports[@]}"; do
    iptables -D INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true
    iptables -D INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true

    if ! iptables -C INPUT -p tcp --dport "$port" -j DROP >/dev/null 2>&1; then
      iptables -I INPUT 1 -p tcp --dport "$port" -j DROP
    fi
    if ! iptables -C INPUT -p udp --dport "$port" -j DROP >/dev/null 2>&1; then
      iptables -I INPUT 1 -p udp --dport "$port" -j DROP
    fi
  done

  iptables -D INPUT -i lo -j ACCEPT >/dev/null 2>&1 || true
  iptables -D FORWARD -i lo -j ACCEPT >/dev/null 2>&1 || true
  iptables -I INPUT 1 -i lo -j ACCEPT
  iptables -I FORWARD 1 -i lo -j ACCEPT

  save_iptables_rules || true
  send_stats "已关闭端口"
}

correct_ssh_config() {
  local sshd_config="/etc/ssh/sshd_config"

  if grep -Eq "^\s*PasswordAuthentication\s+no" "$sshd_config"; then
    sed -i \
      -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
      -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
      -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
      -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' \
      "$sshd_config"
  else
    sed -i \
      -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin yes/' \
      -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication yes/' \
      -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
      "$sshd_config"
  fi

  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/* 2>/dev/null || true
}

new_ssh_port() {
  local new_port="$1"

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
  sed -i '/^\s*#\?\s*Port\s\+/d' /etc/ssh/sshd_config
  echo "Port $new_port" >> /etc/ssh/sshd_config

  correct_ssh_config
  restart_ssh
  open_port "$new_port"
  remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1 || true

  echo "SSH 端口已修改为: $new_port"
  sleep 1
}

add_swap() {
  local new_swap="$1"
  local swap_partitions
  swap_partitions="$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')"

  for partition in $swap_partitions; do
    swapoff "$partition" >/dev/null 2>&1 || true
    wipefs -a "$partition" >/dev/null 2>&1 || true
    mkswap -f "$partition" >/dev/null 2>&1 || true
  done

  swapoff /swapfile >/dev/null 2>&1 || true
  rm -f /swapfile

  fallocate -l "${new_swap}M" /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile

  sed -i '/\/swapfile/d' /etc/fstab
  echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

  if [[ -f /etc/alpine-release ]]; then
    mkdir -p /etc/local.d
    echo "nohup swapon /swapfile" > /etc/local.d/swap.start
    chmod +x /etc/local.d/swap.start
    rc-update add local >/dev/null 2>&1 || true
  fi

  echo -e "虚拟内存大小已调整为${gl_huang}${new_swap}${gl_bai}M"
}

luopo_system_tools_ip_address() {
  local public_ip isp_info
  public_ip="$(curl -s --max-time 3 https://ipinfo.io/ip && echo)"
  isp_info="$(curl -s --max-time 3 http://ipinfo.io/org)"

  if echo "$isp_info" | grep -Eiq 'CHINANET|mobile|unicom|telecom'; then
    ipv4_address="$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || hostname -I 2>/dev/null | awk '{print $1}')"
  else
    ipv4_address="$public_ip"
  fi
}
