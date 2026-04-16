#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_SYSTEM_TOOLS_DIR/../../.." && pwd)"

luopo_system_tools_launch_compat() {
  run_luopo_compat_menu linux_Settings
}

luopo_system_tools_set_shortcut() {
  while true; do
    clear
    read -r -p "请输入你的快捷按键（输入0退出）: " kuaijiejian
    if [[ "$kuaijiejian" == "0" ]]; then
      return 0
    fi

    find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/z" && rm -f {}' \;
    if [[ "$kuaijiejian" != "z" ]]; then
      ln -sf /usr/local/bin/z "/usr/local/bin/$kuaijiejian"
    fi
    ln -sf /usr/local/bin/z "/usr/bin/$kuaijiejian" >/dev/null 2>&1
    echo "快捷启动命令已设置"
    send_stats "快捷启动命令已设置"
    break_end
  done
}

luopo_system_tools_change_login_password() {
  clear
  send_stats "设置你的登录密码"
  echo "设置你的登录密码"
  passwd
}

luopo_system_tools_open_all_ports() {
  root_use
  send_stats "开放端口"
  iptables_open
  remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1
  echo "端口已全部开放"
  press_enter
}

luopo_system_tools_swap_menu() {
  root_use
  send_stats "设置虚拟内存"
  while true; do
    clear
    echo "设置虚拟内存"
    echo -e "当前虚拟内存: ${gl_huang}$(luopo_system_tools_current_swap_info)${gl_bai}"
    echo "------------------------"
    echo "1. 分配1024M         2. 分配2048M         3. 分配4096M         4. 自定义大小"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice

    case "$sub_choice" in
      1) add_swap 1024 ;;
      2) add_swap 2048 ;;
      3) add_swap 4096 ;;
      4)
        read -r -p "请输入虚拟内存大小（单位 M）: " custom_swap
        if [[ "$custom_swap" =~ ^[0-9]+$ ]] && [[ "$custom_swap" -gt 0 ]]; then
          add_swap "$custom_swap"
        else
          echo "请输入有效的数字"
          press_enter
          continue
        fi
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

luopo_system_tools_network_priority_menu() {
  root_use
  while true; do
    clear
    send_stats "网络优先级切换"
    echo "切换优先 ipv4/ipv6"
    echo "------------------------"
    echo "1. IPv4 优先"
    echo "2. IPv6 优先"
    echo "3. IPv6 修复工具"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        prefer_ipv4
        ;;
      2)
        rm -f /etc/gai.conf
        echo "已切换为 IPv6 优先"
        send_stats "已切换为 IPv6 优先"
        ;;
      3)
        bash <(curl -L -s jhb.ovh/jb/v6.sh)
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

luopo_system_tools_show_ports() {
  clear
  send_stats "查看端口占用状态"
  ss -tulnape
  press_enter
}

luopo_system_tools_user_management_menu() {
  root_use
  while true; do
    clear
    send_stats "用户管理"
    luopo_system_tools_print_user_table
    echo
    echo "账户操作"
    echo "------------------------"
    echo "1. 创建普通用户"
    echo "2. 创建高级用户"
    echo "3. 赋予 sudo 权限"
    echo "4. 移除 sudo 权限"
    echo "5. 删除用户"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "请输入新用户名: " new_username
        [[ -n "$new_username" ]] || { echo "用户名不能为空"; press_enter; continue; }
        create_user_with_sshkey "$new_username" false
        ;;
      2)
        read -r -p "请输入新用户名: " new_username
        [[ -n "$new_username" ]] || { echo "用户名不能为空"; press_enter; continue; }
        create_user_with_sshkey "$new_username" true
        ;;
      3)
        read -r -p "请输入用户名: " username
        [[ -n "$username" ]] || { echo "用户名不能为空"; press_enter; continue; }
        if id "$username" >/dev/null 2>&1; then
          echo "$username ALL=(ALL:ALL) ALL" > "/etc/sudoers.d/$username"
          chmod 440 "/etc/sudoers.d/$username"
          echo "已赋予 $username sudo 权限"
        else
          echo "用户不存在"
        fi
        ;;
      4)
        read -r -p "请输入用户名: " username
        [[ -n "$username" ]] || { echo "用户名不能为空"; press_enter; continue; }
        rm -f "/etc/sudoers.d/$username"
        sed -i "/^$username .*ALL$/d" /etc/sudoers
        echo "已移除 $username sudo 权限"
        ;;
      5)
        read -r -p "请输入要删除的用户名: " username
        [[ -n "$username" ]] || { echo "用户名不能为空"; press_enter; continue; }
        if id "$username" >/dev/null 2>&1; then
          userdel -r "$username"
          echo "用户 $username 已删除"
        else
          echo "用户不存在"
        fi
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

luopo_system_tools_generate_credentials() {
  clear
  send_stats "用户信息生成器"
  luopo_system_tools_print_generated_credentials
  press_enter
}

luopo_system_tools_timezone_menu() {
  root_use
  send_stats "换时区"
  while true; do
    clear
    echo "系统时间信息"
    echo "当前系统时区: $(current_timezone)"
    echo "当前系统时间: $(date +"%Y-%m-%d %H:%M:%S")"
    echo "------------------------"
    echo " 1. 上海        2. 香港        3. 东京        4. 首尔        5. 新加坡"
    echo " 6. 加尔各答    7. 迪拜        8. 悉尼        9. 曼谷"
    echo "11. 伦敦       12. 巴黎       13. 柏林       14. 莫斯科      15. 阿姆斯特丹"
    echo "16. 马德里"
    echo "21. 洛杉矶     22. 纽约       23. 温哥华     24. 墨西哥城    25. 圣保罗"
    echo "26. 布宜诺斯艾利斯"
    echo "31. UTC"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice

    case "$sub_choice" in
      1) set_timedate Asia/Shanghai ;;
      2) set_timedate Asia/Hong_Kong ;;
      3) set_timedate Asia/Tokyo ;;
      4) set_timedate Asia/Seoul ;;
      5) set_timedate Asia/Singapore ;;
      6) set_timedate Asia/Kolkata ;;
      7) set_timedate Asia/Dubai ;;
      8) set_timedate Australia/Sydney ;;
      9) set_timedate Asia/Bangkok ;;
      11) set_timedate Europe/London ;;
      12) set_timedate Europe/Paris ;;
      13) set_timedate Europe/Berlin ;;
      14) set_timedate Europe/Moscow ;;
      15) set_timedate Europe/Amsterdam ;;
      16) set_timedate Europe/Madrid ;;
      21) set_timedate America/Los_Angeles ;;
      22) set_timedate America/New_York ;;
      23) set_timedate America/Vancouver ;;
      24) set_timedate America/Mexico_City ;;
      25) set_timedate America/Sao_Paulo ;;
      26) set_timedate America/Argentina/Buenos_Aires ;;
      31) set_timedate UTC ;;
      0) return 0 ;;
      *) luopo_system_tools_invalid_choice; continue ;;
    esac
    break_end
  done
}

luopo_system_tools_feedback() {
  clear
  send_stats "反馈渠道"
  echo "欢迎反馈 LuoPo VPS Toolkit 的使用建议与问题。"
  echo "GitHub Issues: https://github.com/LuoPoJunZi/toolkit/issues"
  echo "GitHub Discussions: https://github.com/LuoPoJunZi/toolkit/discussions"
  press_enter
}

luopo_system_tools_privacy_menu() {
  root_use
  while true; do
    clear
    local status_message="${gl_hui}已禁用统计采集${gl_bai}"
    echo "隐私与安全"
    echo "当前 LuoPo VPS Toolkit 兼容层已默认关闭统计采集。"
    echo "此页面仅保留状态说明，不会向外部开启数据上报。"
    echo "------------------------------------------------"
    echo -e "当前状态: $status_message"
    echo "--------------------"
    echo "1. 查看当前状态"
    echo "2. 保持关闭"
    echo "0. 返回上一级选单"
    echo "--------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        echo "当前版本默认关闭统计采集，无需额外处理。"
        ;;
      2)
        echo "统计采集保持关闭。"
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    press_enter
  done
}

luopo_system_tools_command_help() {
  clear
  k_info
  press_enter
}

luopo_system_tools_uninstall_menu() {
  # shellcheck disable=SC1091
  source "$ROOT_DIR/core/uninstall.sh"
  uninstall_toolkit
}

luopo_system_tools_dispatch_choice() {
  local choice="$1"
  case "$choice" in
    0) return 1 ;;
    1) luopo_system_tools_set_shortcut ;;
    2) luopo_system_tools_change_login_password ;;
    3) add_sshpasswd ;;
    10) luopo_system_tools_network_priority_menu ;;
    11) luopo_system_tools_show_ports ;;
    13) luopo_system_tools_user_management_menu ;;
    18) luopo_system_tools_change_hostname_menu ;;
    19) luopo_system_tools_switch_mirror_menu ;;
    20) luopo_system_tools_crontab_menu ;;
    21) luopo_system_tools_hosts_menu ;;
    22) fail2ban_panel ;;
    5) luopo_system_tools_open_all_ports ;;
    7) set_dns_ui ;;
    8) dd_xitong ;;
    12) luopo_system_tools_swap_menu ;;
    14) luopo_system_tools_generate_credentials ;;
    15) luopo_system_tools_timezone_menu ;;
    16) run_luopo_compat_menu linux_bbr ;;
    17) iptables_panel ;;
    24) sshkey_panel ;;
    30) linux_file ;;
    33) linux_trash ;;
    34) linux_backup ;;
    35) ssh_manager ;;
    36) disk_manager ;;
    38) rsync_manager ;;
    61) luopo_system_tools_feedback ;;
    99) server_reboot ;;
    100) luopo_system_tools_privacy_menu ;;
    101) luopo_system_tools_command_help ;;
    102) luopo_system_tools_uninstall_menu ;;
    *)
      echo "该功能当前仍使用兼容实现，正在切换..."
      press_enter
      luopo_system_tools_launch_compat
      ;;
  esac
  return 0
}

