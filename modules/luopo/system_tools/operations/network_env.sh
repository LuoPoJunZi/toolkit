#!/usr/bin/env bash
set -euo pipefail

# Mirror, DNS, network card, log, and environment-variable operations.

luopo_system_tools_switch_mirror_menu() {
  root_use
  while true; do
    clear
    echo "接入 LinuxMirrors 切换系统更新源"
    echo "------------------------"
    echo "1. 中国大陆【默认】"
    echo "2. 中国大陆【教育网】"
    echo "3. 海外地区"
    echo "4. 智能切换更新源"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        send_stats "中国大陆默认源"
        bash <(curl -sSL https://linuxmirrors.cn/main.sh)
        ;;
      2)
        send_stats "中国大陆教育源"
        bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
        ;;
      3)
        send_stats "海外源"
        bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
        ;;
      4)
        send_stats "智能切换更新源"
        bash <(curl -sSL https://linuxmirrors.cn/main.sh)
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_dns_menu() {
  root_use
  send_stats "优化DNS"
  while true; do
    clear
    echo "优化DNS地址"
    echo "------------------------"
    echo "当前DNS地址"
    cat /etc/resolv.conf 2>/dev/null || echo "无法读取 /etc/resolv.conf"
    echo "------------------------"
    echo "1. 国外DNS优化"
    echo "   v4: 1.1.1.1 8.8.8.8"
    echo "   v6: 2606:4700:4700::1111 2001:4860:4860::8888"
    echo "2. 国内DNS优化"
    echo "   v4: 223.5.5.5 183.60.83.19"
    echo "   v6: 2400:3200::1 2400:da00::6666"
    echo "3. 手动编辑DNS配置"
    echo "4. 自动优化DNS配置"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        luopo_system_tools_write_dns "1.1.1.1" "8.8.8.8" "2606:4700:4700::1111" "2001:4860:4860::8888"
        echo "已切换到国外DNS"
        ;;
      2)
        luopo_system_tools_write_dns "223.5.5.5" "183.60.83.19" "2400:3200::1" "2400:da00::6666"
        echo "已切换到国内DNS"
        ;;
      3)
        install nano
        nano /etc/resolv.conf
        ;;
      4)
        auto_optimize_dns
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_network_card_menu() {
  send_stats "网卡管理工具"

  luopo_system_tools_show_nics() {
    echo "================ 当前网卡信息 ================"
    printf "%-18s %-12s %-20s %-26s\n" "网卡名" "状态" "IPv4地址" "MAC地址"
    echo "------------------------------------------------"
    for nic in /sys/class/net/*; do
      [[ -e "$nic" ]] || continue
      local name state ipaddr mac
      name="$(basename "$nic")"
      state="$(cat "$nic/operstate" 2>/dev/null || echo unknown)"
      ipaddr="$(ip -4 addr show "$name" 2>/dev/null | awk '/inet /{print $2}' | head -n1)"
      mac="$(cat "$nic/address" 2>/dev/null || echo N/A)"
      printf "%-18s %-12s %-20s %-26s\n" "$name" "$state" "${ipaddr:-无}" "$mac"
    done
    echo "================================================"
  }

  while true; do
    clear
    luopo_system_tools_show_nics
    echo
    echo "网卡管理菜单"
    echo "------------------------"
    echo "1. 启用网卡"
    echo "2. 禁用网卡"
    echo "3. 查看网卡详细信息"
    echo "4. 刷新网卡信息"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请选择操作: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "请输入要启用的网卡名: " nic
        if ip link show "$nic" >/dev/null 2>&1; then
          ip link set "$nic" up && echo "网卡 $nic 已启用"
        else
          echo "网卡不存在"
        fi
        ;;
      2)
        read -r -p "请输入要禁用的网卡名: " nic
        if ip link show "$nic" >/dev/null 2>&1; then
          ip link set "$nic" down && echo "网卡 $nic 已禁用"
        else
          echo "网卡不存在"
        fi
        ;;
      3)
        read -r -p "请输入要查看的网卡名: " nic
        if ip link show "$nic" >/dev/null 2>&1; then
          echo "========== $nic 详细信息 =========="
          ip addr show "$nic"
          command -v ethtool >/dev/null 2>&1 && ethtool "$nic" 2>/dev/null | head -n 20
        else
          echo "网卡不存在"
        fi
        ;;
      4)
        continue
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_log_menu() {
  send_stats "系统日志管理工具"

  luopo_system_tools_show_log_overview() {
    echo "============= 系统日志概览 ============="
    echo "主机名: $(hostname)"
    echo "系统时间: $(date)"
    echo
    echo "[ /var/log 目录占用 ]"
    du -sh /var/log 2>/dev/null || true
    echo
    echo "[ journal 日志占用 ]"
    journalctl --disk-usage 2>/dev/null || echo "当前系统未启用 journalctl"
    echo "========================================"
  }

  while true; do
    clear
    luopo_system_tools_show_log_overview
    echo
    echo "系统日志管理菜单"
    echo "------------------------"
    echo "1. 查看最近系统日志（journal）"
    echo "2. 查看指定服务日志"
    echo "3. 查看登录/安全日志"
    echo "4. 实时跟踪日志"
    echo "5. 清理旧 journal 日志"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请选择操作: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "查看最近多少行日志？[默认 100]: " lines
        lines="${lines:-100}"
        journalctl -n "$lines" --no-pager 2>/dev/null || echo "当前系统无法读取 journal 日志"
        ;;
      2)
        read -r -p "请输入服务名（如 sshd、nginx）: " svc
        journalctl -u "$svc" -n 100 --no-pager 2>/dev/null || echo "服务不存在或无 journal 日志"
        ;;
      3)
        echo "====== 最近登录日志 ======"
        last -n 10 2>/dev/null || true
        echo
        echo "====== 认证日志 ======"
        if [[ -f /var/log/secure ]]; then
          tail -n 20 /var/log/secure
        elif [[ -f /var/log/auth.log ]]; then
          tail -n 20 /var/log/auth.log
        else
          echo "未找到安全日志文件"
        fi
        ;;
      4)
        echo "1. 系统日志"
        echo "2. 指定服务日志"
        read -r -p "选择跟踪类型: " trace_type
        if [[ "$trace_type" == "1" ]]; then
          journalctl -f
        elif [[ "$trace_type" == "2" ]]; then
          read -r -p "输入服务名: " svc
          journalctl -u "$svc" -f
        else
          echo "无效选择"
        fi
        ;;
      5)
        echo "1. 保留最近 7 天"
        echo "2. 保留最近 3 天"
        echo "3. 限制日志最大 500M"
        read -r -p "请选择清理方式: " clean_choice
        case "$clean_choice" in
          1) journalctl --vacuum-time=7d ;;
          2) journalctl --vacuum-time=3d ;;
          3) journalctl --vacuum-size=500M ;;
          *) echo "无效选项" ;;
        esac
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_env_menu() {
  local bashrc="$HOME/.bashrc"
  local profile="$HOME/.profile"
  send_stats "系统变量管理工具"

  luopo_system_tools_parse_env_file() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    echo
    echo ">>> 来源文件: $file"
    echo "-----------------------------------------------"
    grep -Ev '^\s*#|^\s*$' "$file" \
      | grep -E '^(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=' \
      | while read -r line; do
          local var val
          var="$(echo "$line" | sed -E 's/^(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*).*/\2/')"
          val="$(echo "$line" | sed -E 's/^[^=]+=//')"
          printf "%-20s %s\n" "$var" "$val"
        done
  }

  while true; do
    clear
    echo "系统环境变量管理"
    echo "当前用户: $USER"
    echo "------------------------"
    echo "1. 查看当前常用环境变量"
    echo "2. 查看 ~/.bashrc"
    echo "3. 查看 ~/.profile"
    echo "4. 编辑 ~/.bashrc"
    echo "5. 编辑 ~/.profile"
    echo "6. 重新加载环境变量"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请选择操作: " sub_choice
    case "$sub_choice" in
      1)
        printf "%-20s %s\n" "变量名" "值"
        echo "-----------------------------------------------"
        for var in USER HOME SHELL LANG PWD; do
          printf "%-20s %s\n" "$var" "${!var:-}"
        done
        echo
        echo "PATH:"
        echo "$PATH" | tr ':' '\n' | nl -ba
        luopo_system_tools_parse_env_file "$bashrc"
        luopo_system_tools_parse_env_file "$profile"
        ;;
      2)
        [[ -f "$bashrc" ]] && cat -n "$bashrc" || echo "文件不存在: $bashrc"
        ;;
      3)
        [[ -f "$profile" ]] && cat -n "$profile" || echo "文件不存在: $profile"
        ;;
      4)
        install nano
        nano "$bashrc"
        ;;
      5)
        install nano
        nano "$profile"
        ;;
      6)
        # shellcheck disable=SC1090
        [[ -f "$bashrc" ]] && source "$bashrc"
        # shellcheck disable=SC1090
        [[ -f "$profile" ]] && source "$profile"
        echo "环境变量已重新加载"
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}
