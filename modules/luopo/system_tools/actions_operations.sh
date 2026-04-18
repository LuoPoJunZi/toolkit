#!/usr/bin/env bash
set -euo pipefail

luopo_system_tools_change_hostname_menu() {
  root_use
  while true; do
    clear
    echo "当前主机名: $(hostname)"
    echo "------------------------"
    echo "1. 修改主机名"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "请输入新的主机名: " new_hostname
        [[ -n "$new_hostname" ]] || { echo "主机名不能为空"; press_enter; continue; }
        if command -v hostnamectl >/dev/null 2>&1; then
          hostnamectl set-hostname "$new_hostname"
        else
          hostname "$new_hostname"
          echo "$new_hostname" > /etc/hostname
        fi
        if grep -q '^127\.0\.1\.1' /etc/hosts 2>/dev/null; then
          sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $new_hostname/" /etc/hosts
        else
          echo "127.0.1.1 $new_hostname" >> /etc/hosts
        fi
        echo "主机名已更新为: $new_hostname"
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
        switch_mirror false false
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

luopo_system_tools_crontab_menu() {
  root_use
  check_crontab_installed
  while true; do
    clear
    echo "当前定时任务列表"
    echo "------------------------"
    crontab -l 2>/dev/null || echo "暂无定时任务"
    echo "------------------------"
    echo "1. 添加每月任务"
    echo "2. 添加每周任务"
    echo "3. 添加每日任务"
    echo "4. 添加每小时任务"
    echo "5. 删除含关键字的任务"
    echo "6. 编辑当前任务"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "请输入日期 (1-31): " cron_day
        read -r -p "请输入时间 (HH:MM): " cron_time
        read -r -p "请输入任务命令: " cron_command
        IFS=: read -r cron_hour cron_minute <<<"$cron_time"
        (crontab -l 2>/dev/null; echo "$cron_minute $cron_hour $cron_day * * $cron_command") | crontab -
        ;;
      2)
        read -r -p "请输入星期几 (0-6, 0=周日): " cron_weekday
        read -r -p "请输入时间 (HH:MM): " cron_time
        read -r -p "请输入任务命令: " cron_command
        IFS=: read -r cron_hour cron_minute <<<"$cron_time"
        (crontab -l 2>/dev/null; echo "$cron_minute $cron_hour * * $cron_weekday $cron_command") | crontab -
        ;;
      3)
        read -r -p "请输入时间 (HH:MM): " cron_time
        read -r -p "请输入任务命令: " cron_command
        IFS=: read -r cron_hour cron_minute <<<"$cron_time"
        (crontab -l 2>/dev/null; echo "$cron_minute $cron_hour * * * $cron_command") | crontab -
        ;;
      4)
        read -r -p "请输入分钟 (0-59): " cron_minute
        read -r -p "请输入任务命令: " cron_command
        (crontab -l 2>/dev/null; echo "$cron_minute * * * * $cron_command") | crontab -
        ;;
      5)
        read -r -p "请输入要删除任务的关键字: " cron_keyword
        [[ -n "$cron_keyword" ]] || { echo "关键字不能为空"; press_enter; continue; }
        crontab -l 2>/dev/null | grep -v "$cron_keyword" | crontab -
        echo "已删除包含关键字的定时任务"
        ;;
      6)
        crontab -e
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

luopo_system_tools_hosts_menu() {
  root_use
  while true; do
    clear
    echo "本机 host 解析列表"
    echo "如果你在这里添加解析匹配，将不再使用动态解析了"
    cat /etc/hosts
    echo
    echo "操作"
    echo "------------------------"
    echo "1. 添加新的解析"
    echo "2. 删除解析地址"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "请输入新的解析记录，格式: 110.25.5.33 example.com : " addhost
        [[ -n "$addhost" ]] || { echo "解析记录不能为空"; press_enter; continue; }
        echo "$addhost" >> /etc/hosts
        send_stats "本地host解析新增"
        echo "已添加解析记录"
        ;;
      2)
        read -r -p "请输入要删除的关键字或域名: " delhost
        [[ -n "$delhost" ]] || { echo "删除关键字不能为空"; press_enter; continue; }
        sed -i "/$delhost/d" /etc/hosts
        send_stats "本地host解析删除"
        echo "已删除匹配记录"
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

luopo_system_tools_traffic_shutdown_menu() {
  root_use
  while true; do
    clear
    echo "限流自动关机"
    echo "------------------------"
    echo "1. 开启限流关机功能"
    echo "2. 停用限流关机功能"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        echo "如果实际服务器就 100G 流量，可设置阈值为 95G，提前关机以免溢出。"
        read -r -p "请输入进站流量阈值（单位 G，默认100G）: " rx_threshold_gb
        rx_threshold_gb="${rx_threshold_gb:-100}"
        read -r -p "请输入出站流量阈值（单位 G，默认100G）: " tx_threshold_gb
        tx_threshold_gb="${tx_threshold_gb:-100}"
        read -r -p "请输入流量重置日期（默认每月1日重置）: " reset_day
        reset_day="${reset_day:-1}"
        curl -Ss -o "$HOME/Limiting_Shut_down.sh" "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/Limiting_Shut_down1.sh"
        chmod +x "$HOME/Limiting_Shut_down.sh"
        sed -i "s/110/$rx_threshold_gb/g" "$HOME/Limiting_Shut_down.sh"
        sed -i "s/120/$tx_threshold_gb/g" "$HOME/Limiting_Shut_down.sh"
        check_crontab_installed
        crontab -l 2>/dev/null | grep -v '~/Limiting_Shut_down.sh' | crontab -
        (crontab -l 2>/dev/null; echo "* * * * * ~/Limiting_Shut_down.sh") | crontab -
        crontab -l 2>/dev/null | grep -v 'reboot' | crontab -
        (crontab -l 2>/dev/null; echo "0 1 $reset_day * * reboot") | crontab -
        echo "限流关机已设置"
        send_stats "限流关机已设置"
        ;;
      2)
        check_crontab_installed
        crontab -l 2>/dev/null | grep -v '~/Limiting_Shut_down.sh' | crontab -
        crontab -l 2>/dev/null | grep -v 'reboot' | crontab -
        rm -f "$HOME/Limiting_Shut_down.sh"
        echo "已关闭限流关机功能"
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

luopo_system_tools_tg_monitor_menu() {
  root_use
  send_stats "电报预警"
  echo "TG-bot监控预警功能"
  echo "视频介绍: https://youtu.be/vLL-eb3Z_TY"
  echo "------------------------------------------------"
  echo "你需要配置 TG 机器人 API 和接收预警的用户 ID。"
  echo "可实现 CPU、内存、硬盘、流量、SSH 登录的实时监控预警。"
  echo -e "${gl_hui}- 关于流量，重启服务器将重新计算 -${gl_bai}"
  read -r -p "确定继续吗？(Y/N): " choice
  case "$choice" in
    [Yy])
      send_stats "电报预警启用"
      cd ~
      install nano tmux bc jq
      check_crontab_installed
      if [[ -f "$HOME/TG-check-notify.sh" ]]; then
        chmod +x "$HOME/TG-check-notify.sh"
        nano "$HOME/TG-check-notify.sh"
      else
        curl -sS -O "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-check-notify.sh"
        chmod +x "$HOME/TG-check-notify.sh"
        nano "$HOME/TG-check-notify.sh"
      fi
      tmux kill-session -t TG-check-notify >/dev/null 2>&1
      tmux new -d -s TG-check-notify "$HOME/TG-check-notify.sh"
      crontab -l 2>/dev/null | grep -v '~/TG-check-notify.sh' | crontab -
      (crontab -l 2>/dev/null; echo "@reboot tmux new -d -s TG-check-notify '~/TG-check-notify.sh'") | crontab -
      curl -sS -O "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-SSH-check-notify.sh" >/dev/null 2>&1
      sed -i "3i$(grep '^TELEGRAM_BOT_TOKEN=' "$HOME/TG-check-notify.sh")" TG-SSH-check-notify.sh >/dev/null 2>&1
      sed -i "4i$(grep '^CHAT_ID=' "$HOME/TG-check-notify.sh")" TG-SSH-check-notify.sh
      chmod +x "$HOME/TG-SSH-check-notify.sh"
      if ! grep -q 'bash ~/TG-SSH-check-notify.sh' "$HOME/.profile" >/dev/null 2>&1; then
        echo 'bash ~/TG-SSH-check-notify.sh' >> "$HOME/.profile"
        if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
          echo 'source ~/.profile' >> "$HOME/.bashrc"
        fi
      fi
      echo "TG-bot预警系统已启动"
      echo -e "${gl_hui}你还可以将 root 目录中的 TG-check-notify.sh 预警文件放到其他机器上直接使用。${gl_bai}"
      ;;
    [Nn])
      echo "已取消"
      ;;
    *)
      echo "无效的选择，请输入 Y 或 N。"
      ;;
  esac
  press_enter
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

luopo_system_tools_fail2ban_menu() {
  root_use
  send_stats "ssh防御"
  while true; do
    clear
    echo -e "SSH防御程序 $(luopo_system_tools_fail2ban_status_label)"
    echo "fail2ban 是一个 SSH 防止暴力破解工具"
    echo "官网介绍: ${gh_proxy}github.com/fail2ban/fail2ban"
    echo "------------------------"
    echo "1. 安装防御程序"
    echo "2. 查看SSH拦截记录"
    echo "3. 日志实时监控"
    echo "4. 查看运行状态"
    echo "5. 编辑配置文件（nano）"
    echo "9. 卸载防御程序"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        f2b_install_sshd
        f2b_status
        ;;
      2)
        if command -v fail2ban-client >/dev/null 2>&1; then
          fail2ban-client status sshd 2>/dev/null || fail2ban-client status
        else
          echo "未安装 fail2ban"
        fi
        ;;
      3)
        tail -n 80 /var/log/fail2ban.log 2>/dev/null || echo "未找到 /var/log/fail2ban.log"
        ;;
      4)
        if command -v fail2ban-client >/dev/null 2>&1; then
          fail2ban-client status
        else
          echo "未安装 fail2ban"
        fi
        ;;
      5)
        install nano
        mkdir -p /etc/fail2ban
        nano /etc/fail2ban/jail.local
        ;;
      9)
        remove fail2ban
        rm -rf /etc/fail2ban
        echo "Fail2Ban防御程序已卸载"
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

luopo_system_tools_apply_shell_theme() {
  local ps1_line="$1"
  local target_file

  if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    target_file="$HOME/.bashrc"
  else
    target_file="$HOME/.profile"
  fi

  touch "$target_file"
  sed -i '/^PS1=/d' "$target_file"
  if [[ -n "$ps1_line" ]]; then
    printf '%s\n' "$ps1_line" >> "$target_file"
  fi

  echo -e "${gl_lv:-}变更完成。重新连接 SSH 后可查看变化！${gl_bai:-}"
  hash -r
}

luopo_system_tools_shell_theme_menu() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "请使用 root 权限运行此功能。"
    return 1
  fi

  send_stats "命令行美化工具"

  while true; do
    clear
    echo "命令行美化工具"
    echo "------------------------"
    echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai:-}#"
    echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai:-}#"
    echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai:-}#"
    echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai:-}#"
    echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai:-}#"
    echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai:-}#"
    echo "7. root localhost ~ #"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "输入你的选择: " choice

    local ps1_line=""
    case "$choice" in
      1) ps1_line="PS1='\\[\\033[1;32m\\]\\u\\[\\033[0m\\]@\\[\\033[1;34m\\]\\h\\[\\033[0m\\] \\[\\033[1;31m\\]\\w\\[\\033[0m\\] # '" ;;
      2) ps1_line="PS1='\\[\\033[1;35m\\]\\u\\[\\033[0m\\]@\\[\\033[1;36m\\]\\h\\[\\033[0m\\] \\[\\033[1;33m\\]\\w\\[\\033[0m\\] # '" ;;
      3) ps1_line="PS1='\\[\\033[1;31m\\]\\u\\[\\033[0m\\]@\\[\\033[1;32m\\]\\h\\[\\033[0m\\] \\[\\033[1;34m\\]\\w\\[\\033[0m\\] # '" ;;
      4) ps1_line="PS1='\\[\\033[1;36m\\]\\u\\[\\033[0m\\]@\\[\\033[1;33m\\]\\h\\[\\033[0m\\] \\[\\033[1;37m\\]\\w\\[\\033[0m\\] # '" ;;
      5) ps1_line="PS1='\\[\\033[1;37m\\]\\u\\[\\033[0m\\]@\\[\\033[1;31m\\]\\h\\[\\033[0m\\] \\[\\033[1;32m\\]\\w\\[\\033[0m\\] # '" ;;
      6) ps1_line="PS1='\\[\\033[1;33m\\]\\u\\[\\033[0m\\]@\\[\\033[1;34m\\]\\h\\[\\033[0m\\] \\[\\033[1;35m\\]\\w\\[\\033[0m\\] # '" ;;
      7) ps1_line="" ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac

    luopo_system_tools_apply_shell_theme "$ps1_line"
    break_end
  done
}

luopo_system_tools_apply_locale() {
  local locale_name="$1"
  local locale_label="$2"

  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "请使用 root 权限运行此功能。"
    return 1
  fi

  if command -v locale-gen >/dev/null 2>&1; then
    if [[ -f /etc/locale.gen ]] && ! grep -q "^${locale_name} UTF-8" /etc/locale.gen; then
      echo "${locale_name} UTF-8" >> /etc/locale.gen
    fi
    locale-gen "$locale_name" >/dev/null 2>&1 || locale-gen >/dev/null 2>&1 || true
  fi

  if command -v localectl >/dev/null 2>&1; then
    localectl set-locale "LANG=${locale_name}" 2>/dev/null || true
  fi

  if [[ -f /etc/default/locale || -d /etc/default ]]; then
    printf 'LANG=%s\nLC_ALL=%s\n' "$locale_name" "$locale_name" > /etc/default/locale
  fi

  if [[ -f /etc/locale.conf || -d /etc ]]; then
    printf 'LANG=%s\n' "$locale_name" > /etc/locale.conf
  fi

  export LANG="$locale_name"
  export LC_ALL="$locale_name"
  echo "已切换到${locale_label}。重新登录 SSH 后生效更完整。"
}

luopo_system_tools_language_menu() {
  send_stats "切换系统语言"

  while true; do
    clear
    echo "系统语言切换"
    echo "当前系统语言: ${LANG:-未知}"
    echo "------------------------"
    echo "1. 英文"
    echo "2. 简体中文"
    echo "3. 繁体中文"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "输入你的选择: " choice

    case "$choice" in
      1) luopo_system_tools_apply_locale "en_US.UTF-8" "英文" ;;
      2) luopo_system_tools_apply_locale "zh_CN.UTF-8" "简体中文" ;;
      3) luopo_system_tools_apply_locale "zh_TW.UTF-8" "繁体中文" ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_fix_openssh() {
