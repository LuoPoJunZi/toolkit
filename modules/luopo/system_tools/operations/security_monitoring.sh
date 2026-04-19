#!/usr/bin/env bash
set -euo pipefail

# Traffic guard, Telegram monitoring, and Fail2ban operations.

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
