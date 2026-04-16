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

