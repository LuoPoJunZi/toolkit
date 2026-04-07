#!/usr/bin/env bash
set -euo pipefail

network_accel_menu() {
  local choice
  while true; do
    clear
    echo "========================================"
    echo "网络加速管理"
    echo "========================================"
    menu_item "1" "查看当前拥塞控制算法"
    menu_item "2" "一键启用 BBR + FQ"
    menu_item "3" "查看网络内核参数"
    menu_item "4" "查看网络接口与路由"
    echo "------------------------"
    menu_item "21" "WARP 一键安装"
    menu_item "22" "WARP 状态检查"
    menu_item "23" "开启 TCP Fast Open"
    menu_item "24" "关闭 TCP Fast Open"
    echo "------------------------"
    menu_item "31" "IPv4/IPv6 出口检测"
    menu_item "32" "查看网络连接统计"
    menu_item "33" "重置为系统默认网络优化"
    menu_item "34" "重启网络服务"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1) sysctl net.ipv4.tcp_congestion_control net.core.default_qdisc 2>/dev/null || say_warn "当前系统不支持读取"; menu_wait ;;
      2)
        cat >/etc/sysctl.d/99-luopo-bbr.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
        if sysctl --system >/dev/null 2>&1; then
          say_ok "已应用 BBR + FQ（如未生效建议重启）"
        else
          say_action_failed "BBR + FQ 应用" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      3) sysctl -a 2>/dev/null | grep -E 'tcp_congestion_control|default_qdisc|tcp_fastopen|somaxconn' || say_warn "未读取到相关参数"; menu_wait ;;
      4) ip addr show; ip route show; menu_wait ;;
      21)
        if ! confirm_or_cancel "确认安装并启动 WARP 管理脚本？(y/N): "; then
          menu_wait
          continue
        fi
        if run_remote_bash_script "https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh" "WARP 安装"; then
          say_ok "WARP 管理脚本执行完成"
        fi
        menu_wait
        ;;
      22) command -v warp-cli >/dev/null 2>&1 && warp-cli status || say_warn "未检测到 warp-cli"; menu_wait ;;
      23)
        cat >/etc/sysctl.d/99-luopo-fastopen.conf <<'EOF'
net.ipv4.tcp_fastopen=3
EOF
        if sysctl --system >/dev/null 2>&1; then
          say_ok "TCP Fast Open 已启用"
        else
          say_action_failed "TCP Fast Open 启用" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      24)
        rm -f /etc/sysctl.d/99-luopo-fastopen.conf
        if sysctl --system >/dev/null 2>&1; then
          say_ok "TCP Fast Open 配置已移除"
        else
          say_action_failed "TCP Fast Open 配置移除" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      31) echo "IPv4: $(curl -4 -s ifconfig.me 2>/dev/null || echo N/A)"; echo "IPv6: $(curl -6 -s ifconfig.me 2>/dev/null || echo N/A)"; menu_wait ;;
      32) ss -s; menu_wait ;;
      33)
        rm -f /etc/sysctl.d/99-luopo-bbr.conf /etc/sysctl.d/99-luopo-fastopen.conf
        if sysctl --system >/dev/null 2>&1; then
          say_ok "已恢复默认优化项"
        else
          say_action_failed "恢复默认网络优化" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      34)
        if systemctl restart networking 2>/dev/null || systemctl restart NetworkManager 2>/dev/null; then
          say_ok "网络服务重启完成"
        else
          say_action_failed "网络服务重启" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

