#!/usr/bin/env bash
set -euo pipefail

luopo_ldnmp_security() {
  root_use || return 1
  while true; do
    clear
    echo "LDNMP环境防护"
    echo "------------------------"
    if command -v fail2ban-client >/dev/null 2>&1; then
      fail2ban-client status 2>/dev/null || true
    else
      echo "Fail2ban: 未安装"
    fi
    echo "------------------------"
    echo "1. 安装/更新 Fail2ban 防护"
    echo "2. 查看 SSH 拦截记录"
    echo "3. 查看 Nginx 拦截记录"
    echo "4. 实时查看 Fail2ban 日志"
    echo "5. 清除所有拉黑 IP"
    echo "9. 卸载 Fail2ban"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1) luopo_ldnmp_fail2ban_install ;;
      2) fail2ban-client status sshd 2>/dev/null || echo "未检测到 sshd jail" ;;
      3) fail2ban-client status nginx-docker-cc 2>/dev/null || fail2ban-client status 2>/dev/null || true ;;
      4) tail -f /var/log/fail2ban.log ;;
      5) luopo_ldnmp_fail2ban_unban_all ;;
      9) remove fail2ban; systemctl disable --now fail2ban 2>/dev/null || true ;;
      0) return 0 ;;
      *) luopo_ldnmp_invalid_choice; continue ;;
    esac
    break_end
  done
}

luopo_ldnmp_fail2ban_install() {
  install fail2ban curl wget
  mkdir -p /etc/fail2ban/filter.d /etc/fail2ban/jail.d
  curl -fsSL "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf" -o /etc/fail2ban/filter.d/fail2ban-nginx-cc.conf || true
  cat > /etc/fail2ban/jail.d/luopo-nginx-docker-cc.conf <<'EOF'
[nginx-docker-cc]
enabled = true
filter = fail2ban-nginx-cc
logpath = /home/web/log/nginx/access.log
maxretry = 300
findtime = 60
bantime = 3600
EOF
  systemctl enable --now fail2ban 2>/dev/null || service fail2ban restart 2>/dev/null || true
  fail2ban-client reload 2>/dev/null || true
  echo "Fail2ban 防护已安装/更新"
}

luopo_ldnmp_fail2ban_unban_all() {
  command -v fail2ban-client >/dev/null 2>&1 || { echo "Fail2ban 未安装"; return 0; }
  local jail
  for jail in $(fail2ban-client status 2>/dev/null | awk -F: '/Jail list/ {gsub(/,/, " "); print $2}'); do
    fail2ban-client unban --all "$jail" >/dev/null 2>&1 || true
  done
  echo "已清除 Fail2ban 拉黑 IP"
}
