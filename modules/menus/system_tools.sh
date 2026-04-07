#!/usr/bin/env bash
set -euo pipefail

system_tools_menu() {
  local choice tz hn
  while true; do
    clear
    echo "========================================"
    echo "系统工具"
    echo "========================================"
    menu_item "1" "查看/设置时区"
    menu_item "2" "查看/设置主机名"
    menu_item "3" "Swap 管理"
    menu_item "4" "端口占用查询"
    echo "------------------------"
    menu_item "21" "常用工具安装（curl/wget/jq）"
    menu_item "22" "查看最近登录记录"
    menu_item "23" "修改系统 DNS"
    menu_item "24" "系统重启"
    echo "------------------------"
    menu_item "31" "查看磁盘分区信息"
    menu_item "32" "查看系统用户列表"
    menu_item "33" "查看网卡信息"
    menu_item "34" "刷新系统时间同步"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1)
        timedatectl status || true
        read -r -p "输入要设置的时区(留空跳过): " tz
        if [[ -n "$tz" ]]; then
          if timedatectl set-timezone "$tz"; then
            say_ok "时区已设置"
          else
            say_action_failed "时区设置" "$(i18n_get msg_reason_exec_failed 'execution failed')"
          fi
        fi
        menu_wait
        ;;
      2)
        hostnamectl status || true
        read -r -p "输入新主机名(留空跳过): " hn
        if [[ -n "$hn" ]]; then
          if hostnamectl set-hostname "$hn"; then
            say_ok "主机名已设置"
          else
            say_action_failed "主机名设置" "$(i18n_get msg_reason_exec_failed 'execution failed')"
          fi
        fi
        menu_wait
        ;;
      3)
        swapon --show || true
        read -r -p "输入要创建的 swap 大小(MB, 留空跳过): " size_mb
        if [[ -n "${size_mb:-}" ]]; then
          fallocate -l "${size_mb}M" /swapfile || dd if=/dev/zero of=/swapfile bs=1M count="$size_mb"
          chmod 600 /swapfile
          mkswap /swapfile
          swapon /swapfile
          grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
          say_ok "Swap 已创建并启用"
        fi
        menu_wait
        ;;
      4) ss -lntup; menu_wait ;;
      21)
        if apt_install curl wget jq; then
          say_ok "常用工具安装完成"
        else
          say_action_failed "常用工具安装" "$(i18n_get msg_reason_install_failed 'install failed')"
        fi
        menu_wait
        ;;
      22) last -n 20 || true; menu_wait ;;
      23)
        read -r -p "输入主 DNS (如 1.1.1.1): " dns1
        read -r -p "输入备 DNS (可空): " dns2
        if [[ -z "$dns1" ]]; then
          say_warn "主 DNS 不能为空"
          menu_wait
          continue
        fi
        {
          [[ -n "$dns1" ]] && echo "nameserver $dns1"
          [[ -n "$dns2" ]] && echo "nameserver $dns2"
        } >/etc/resolv.conf
        say_ok "DNS 已更新"
        menu_wait
        ;;
      24)
        if confirm_or_cancel "确认重启系统？(y/N): "; then
          log_action "system_tools:reboot"
          reboot
        fi
        ;;
      31) lsblk -f; menu_wait ;;
      32) cut -d: -f1 /etc/passwd; menu_wait ;;
      33) ip -br a; menu_wait ;;
      34)
        if timedatectl set-ntp true >/dev/null 2>&1; then
          say_ok "已刷新系统时间同步"
        else
          say_action_failed "时间同步刷新" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        timedatectl status || true
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

