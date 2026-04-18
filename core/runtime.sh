#!/usr/bin/env bash
set -euo pipefail

gl_lv='\033[32m'
gl_hong='\033[31m'
gl_huang='\033[33m'
gl_hui='\033[90m'
gl_bai='\033[0m'
gl_kjlan='\033[96m'

gh_proxy="${gh_proxy:-https://}"

send_stats() {
  log_action "stats:$*"
  return 0
}

install() {
  if [[ $# -eq 0 ]]; then
    echo "未提供软件包参数!"
    return 1
  fi

  local package
  for package in "$@"; do
    if command -v "$package" >/dev/null 2>&1; then
      continue
    fi

    echo -e "${gl_kjlan}正在安装 $package...${gl_bai}"
    if command -v dnf >/dev/null 2>&1; then
      dnf -y update
      dnf install -y epel-release
      dnf install -y "$package"
    elif command -v yum >/dev/null 2>&1; then
      yum -y update
      yum install -y epel-release
      yum install -y "$package"
    elif command -v apt >/dev/null 2>&1; then
      apt update -y
      apt install -y "$package"
    elif command -v apk >/dev/null 2>&1; then
      apk update
      apk add "$package"
    elif command -v pacman >/dev/null 2>&1; then
      pacman -Syu --noconfirm
      pacman -S --noconfirm "$package"
    elif command -v zypper >/dev/null 2>&1; then
      zypper refresh
      zypper install -y "$package"
    elif command -v opkg >/dev/null 2>&1; then
      opkg update
      opkg install "$package"
    elif command -v pkg >/dev/null 2>&1; then
      pkg update
      pkg install -y "$package"
    else
      echo "未知的包管理器!"
      return 1
    fi
  done
}

remove() {
  if [[ $# -eq 0 ]]; then
    echo "未提供软件包参数!"
    return 1
  fi

  local package
  for package in "$@"; do
    echo -e "${gl_kjlan}正在卸载 $package...${gl_bai}"
    if command -v dnf >/dev/null 2>&1; then
      dnf remove -y "$package"
    elif command -v yum >/dev/null 2>&1; then
      yum remove -y "$package"
    elif command -v apt >/dev/null 2>&1; then
      apt purge -y "$package"
    elif command -v apk >/dev/null 2>&1; then
      apk del "$package"
    elif command -v pacman >/dev/null 2>&1; then
      pacman -Rns --noconfirm "$package"
    elif command -v zypper >/dev/null 2>&1; then
      zypper remove -y "$package"
    elif command -v opkg >/dev/null 2>&1; then
      opkg remove "$package"
    elif command -v pkg >/dev/null 2>&1; then
      pkg delete -y "$package"
    else
      echo "未知的包管理器!"
      return 1
    fi
  done
}

break_end() {
  press_enter
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    return 0
  fi

  echo -e "${gl_kjlan}正在安装 docker 环境...${gl_bai}"
  install curl
  curl -fsSL https://get.docker.com | sh

  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now docker 2>/dev/null || true
  fi
}

tmux_run() {
  if [[ -z "${SESSION_NAME:-}" ]]; then
    echo "未设置 tmux 会话名"
    return 1
  fi

  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux attach-session -t "$SESSION_NAME"
  else
    tmux new -s "$SESSION_NAME"
  fi
}

tmux_run_d() {
  if [[ -z "${tmuxd:-}" ]]; then
    echo "未设置后台 tmux 命令"
    return 1
  fi

  local base_name="tmuxd"
  local tmuxd_id=1
  while tmux has-session -t "${base_name}-${tmuxd_id}" 2>/dev/null; do
    tmuxd_id=$((tmuxd_id + 1))
  done

  tmux new -d -s "${base_name}-${tmuxd_id}" "$tmuxd"
}

bbr_on() {
  local conf="/etc/sysctl.d/99-luopo-bbr.conf"
  mkdir -p /etc/sysctl.d
  {
    echo "net.core.default_qdisc=fq"
    echo "net.ipv4.tcp_congestion_control=bbr"
  } > "$conf"

  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf 2>/dev/null || true
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf 2>/dev/null || true
  sysctl -p "$conf" >/dev/null 2>&1 || sysctl --system >/dev/null 2>&1
}

server_reboot() {
  local rboot
  read -r -p "$(printf "${gl_huang}提示: ${gl_bai}现在重启服务器吗？(Y/N): ")" rboot
  case "$rboot" in
    [Yy])
      echo "已重启"
      reboot
      ;;
    *)
      echo "已取消"
      ;;
  esac
}

add_sshpasswd() {
  local target_user="${1:-}"

  send_stats "设置密码登录模式"
  echo "设置密码登录模式"

  if [[ -z "$target_user" ]]; then
    read -r -p "请输入要修改密码的用户名（默认 root）: " target_user
  fi
  target_user="${target_user:-root}"

  if ! id "$target_user" >/dev/null 2>&1; then
    echo "错误：用户 $target_user 不存在"
    return 1
  fi

  passwd "$target_user"

  if [[ "$target_user" == "root" ]]; then
    sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
  fi
  sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/* 2>/dev/null || true

  if command -v systemctl >/dev/null 2>&1; then
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
  else
    service ssh restart 2>/dev/null || service sshd restart 2>/dev/null || true
  fi

  echo "已开启密码登录模式"
}
