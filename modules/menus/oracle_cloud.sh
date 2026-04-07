#!/usr/bin/env bash
set -euo pipefail

oracle_cloud_menu() {
  local choice
  while true; do
    clear
    echo "========================================"
    echo "Oracle Cloud 工具集"
    echo "========================================"
    menu_item "1" "OCI 常见问题诊断"
    menu_item "2" "公网/私网 IP 与路由检查"
    menu_item "3" "网络端口开放检查"
    echo "------------------------"
    menu_item "21" "时间同步检查"
    menu_item "22" "系统资源与温度检查"
    menu_item "23" "云主机 metadata 信息检查"
    menu_item "24" "一键应用 OCI 常用网络优化"
    echo "------------------------"
    menu_item "31" "检查本机防火墙放行状态"
    menu_item "32" "生成安全组放行建议(基于监听端口)"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1)
        echo "系统: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"' 2>/dev/null)"
        echo "内核: $(uname -r)"
        echo "IPv4: $(curl -4 -s ifconfig.me 2>/dev/null || echo N/A)"
        echo "IPv6: $(curl -6 -s ifconfig.me 2>/dev/null || echo N/A)"
        menu_wait
        ;;
      2) ip addr show | grep -E 'inet ' || true; ip route show || true; menu_wait ;;
      3) ss -lntup | grep -E ':22|:80|:443|:3000|:8080' || say_warn "未检测到常用端口监听"; menu_wait ;;
      21) timedatectl status || true; chronyc tracking 2>/dev/null || true; menu_wait ;;
      22) uptime; free -h; df -h; menu_wait ;;
      23) curl -s http://169.254.169.254/opc/v1/instance/ 2>/dev/null | head -n 40 || say_warn "metadata 不可访问"; menu_wait ;;
      24)
        if confirm_or_cancel "确认应用 BBR + FQ 优化？(y/N): "; then
          cat >/etc/sysctl.d/99-luopo-oci-opt.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
          if sysctl --system >/dev/null 2>&1; then
            say_ok "OCI 常用网络优化已应用（如未生效建议重启）"
          else
            say_action_failed "OCI 网络优化" "$(i18n_get msg_reason_exec_failed 'execution failed')"
          fi
        fi
        menu_wait
        ;;
      31)
        say_ok "本机防火墙检查结果："
        command -v ufw >/dev/null 2>&1 && ufw status verbose || say_warn "ufw 未安装"
        command -v nft >/dev/null 2>&1 && { echo "--- nft ruleset (前80行) ---"; nft list ruleset 2>/dev/null | head -n 80; } || say_warn "nft 不可用"
        command -v iptables >/dev/null 2>&1 && { echo "--- iptables INPUT (前80行) ---"; iptables -S INPUT 2>/dev/null | head -n 80; } || say_warn "iptables 不可用"
        menu_wait
        ;;
      32)
        say_ok "建议放行以下监听端口（请在 OCI 安全组按需放行）："
        local ports
        ports="$(ss -lntup 2>/dev/null | awk 'NR>1 {split($5,a,":"); p=a[length(a)]; if(p ~ /^[0-9]+$/) print p}' | sort -n | uniq)"
        if [[ -n "$ports" ]]; then
          awk '{printf "- %s/tcp 或 udp(按服务实际协议)\n",$1}' <<<"$ports"
        else
          say_warn "未检测到监听端口"
        fi
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

