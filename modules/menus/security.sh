#!/usr/bin/env bash
set -euo pipefail

security_menu() {
  local choice
  while true; do
    clear
    echo "========================================"
    echo "安全与防护"
    echo "========================================"
    menu_item "1" "SSH 安全检查"
    menu_item "2" "防火墙状态检查"
    menu_item "3" "安装/查看 Fail2ban"
    menu_item "4" "常见高危端口监听检查"
    echo "------------------------"
    menu_item "21" "Root 登录策略检查"
    menu_item "22" "一键关闭 SSH 密码登录"
    menu_item "23" "UFW 初始化（放行 22/80/443）"
    menu_item "24" "查看最近 SSH 登录失败日志"
    echo "------------------------"
    menu_item "31" "系统账户与 sudo 权限检查"
    menu_item "32" "一键开启内核 SYN 防护"
    menu_item "33" "查看近期系统认证日志"
    menu_item "34" "安装并运行 rkhunter 快速检查"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1) grep -E '^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|Port)' /etc/ssh/sshd_config 2>/dev/null || say_warn "未读取到 sshd_config"; menu_wait ;;
      2)
        command -v ufw >/dev/null 2>&1 && ufw status verbose || say_warn "未安装 ufw"
        command -v nft >/dev/null 2>&1 && { echo "--- nft ruleset (前80行) ---"; nft list ruleset 2>/dev/null | head -n 80; } || true
        menu_wait
        ;;
      3)
        if ! command -v fail2ban-client >/dev/null 2>&1; then
          if ! apt_install fail2ban; then
            say_action_failed "Fail2ban 安装" "$(i18n_get msg_reason_install_failed 'install failed')"
            menu_wait
            continue
          fi
        fi
        systemctl enable fail2ban >/dev/null 2>&1 || true
        systemctl restart fail2ban >/dev/null 2>&1 || true
        fail2ban-client status 2>/dev/null || say_warn "fail2ban 未运行"
        menu_wait
        ;;
      4) ss -lntup | grep -E ':21|:23|:3389|:5900|:3306' || say_warn "未发现常见高危端口监听"; menu_wait ;;
      21) grep -E '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null || say_warn "未设置（通常为默认策略）"; menu_wait ;;
      22)
        if grep -q '^PasswordAuthentication' /etc/ssh/sshd_config 2>/dev/null; then
          sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        else
          echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
        fi
        if systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null; then
          say_ok "SSH 密码登录已关闭，请确保密钥可用。"
        else
          say_action_failed "SSH 服务重启" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      23)
        if ! apt_install ufw; then
          say_action_failed "UFW 安装" "$(i18n_get msg_reason_install_failed 'install failed')"
          menu_wait
          continue
        fi
        if ufw allow 22/tcp >/dev/null 2>&1 && ufw allow 80/tcp >/dev/null 2>&1 && ufw allow 443/tcp >/dev/null 2>&1; then
          yes | ufw enable >/dev/null 2>&1 || true
          ufw status verbose || true
          say_ok "UFW 初始化完成"
        else
          say_action_failed "UFW 初始化" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      24)
        journalctl -u ssh --since "24 hours ago" 2>/dev/null | grep -Ei 'Failed|Invalid|error' | tail -n 50 || true
        journalctl -u sshd --since "24 hours ago" 2>/dev/null | grep -Ei 'Failed|Invalid|error' | tail -n 50 || true
        menu_wait
        ;;
      31)
        echo "--- 可登录用户 ---"
        awk -F: '$7 !~ /(nologin|false)$/ {print $1":"$7}' /etc/passwd
        echo "--- sudo 组成员 ---"
        getent group sudo 2>/dev/null || true
        menu_wait
        ;;
      32)
        cat >/etc/sysctl.d/99-luopo-sec.conf <<'EOF'
net.ipv4.tcp_syncookies=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
EOF
        if sysctl --system >/dev/null 2>&1; then
          say_ok "内核 SYN 防护参数已应用"
        else
          say_action_failed "内核 SYN 防护" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      33)
        tail -n 100 /var/log/auth.log 2>/dev/null || journalctl -u ssh --no-pager -n 100 2>/dev/null || true
        menu_wait
        ;;
      34)
        try_install_pkg rkhunter
        rkhunter --check --sk --rwo 2>/dev/null | tail -n 80 || say_warn "rkhunter 检查完成/不可用"
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

