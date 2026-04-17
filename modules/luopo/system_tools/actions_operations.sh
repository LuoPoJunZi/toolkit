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

luopo_system_tools_fix_openssh() {
