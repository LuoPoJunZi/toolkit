#!/usr/bin/env bash
set -euo pipefail

luopo_system_tools_fix_openssh() {
  root_use
  send_stats "修复SSH高危漏洞"
  cd ~
  curl -sS -O "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/upgrade_openssh9.8p1.sh"
  chmod +x "$HOME/upgrade_openssh9.8p1.sh"
  "$HOME/upgrade_openssh9.8p1.sh"
  rm -f "$HOME/upgrade_openssh9.8p1.sh"
}

luopo_system_tools_one_click_tune() {
  root_use
  send_stats "一条龙调优"
  echo "一条龙系统调优"
  echo "------------------------------------------------"
  echo "将对以下内容进行操作与优化"
  echo "1. 优化系统更新源，更新系统到最新"
  echo "2. 清理系统垃圾文件"
  echo -e "3. 设置虚拟内存${gl_huang}1G${gl_bai}"
  echo -e "4. 设置SSH端口号为${gl_huang}5522${gl_bai}"
  echo "5. 启动 fail2ban 防御 SSH 暴力破解"
  echo "6. 开放所有端口"
  echo -e "7. 开启${gl_huang}BBR${gl_bai}加速"
  echo -e "8. 设置时区到${gl_huang}上海${gl_bai}"
  echo "9. 自动优化 DNS 地址"
  echo -e "10. 设置网络为${gl_huang}IPv4 优先${gl_bai}"
  echo "11. 安装基础工具 docker wget sudo tar unzip socat btop nano vim"
  echo "12. Linux 系统内核参数优化"
  echo "------------------------------------------------"
  read -r -p "确定一键保养吗？(Y/N): " choice
  case "$choice" in
    [Yy])
      clear
      send_stats "一条龙调优启动"
      echo "------------------------------------------------"
      switch_mirror false false
      linux_update
      echo -e "[${gl_lv}OK${gl_bai}] 1/12. 更新系统到最新"

      echo "------------------------------------------------"
      linux_clean
      echo -e "[${gl_lv}OK${gl_bai}] 2/12. 清理系统垃圾文件"

      echo "------------------------------------------------"
      add_swap 1024
      echo -e "[${gl_lv}OK${gl_bai}] 3/12. 设置虚拟内存${gl_huang}1G${gl_bai}"

      echo "------------------------------------------------"
      new_ssh_port 5522
      echo -e "[${gl_lv}OK${gl_bai}] 4/12. 设置SSH端口号为${gl_huang}5522${gl_bai}"

      echo "------------------------------------------------"
      f2b_install_sshd
      cd ~
      f2b_status
      echo -e "[${gl_lv}OK${gl_bai}] 5/12. 启动 fail2ban 防御 SSH 暴力破解"

      echo "------------------------------------------------"
      iptables_open
      echo -e "[${gl_lv}OK${gl_bai}] 6/12. 开放所有端口"

      echo "------------------------------------------------"
      bbr_on
      echo -e "[${gl_lv}OK${gl_bai}] 7/12. 开启${gl_huang}BBR${gl_bai}加速"

      echo "------------------------------------------------"
      set_timedate Asia/Shanghai
      echo -e "[${gl_lv}OK${gl_bai}] 8/12. 设置时区到${gl_huang}上海${gl_bai}"

      echo "------------------------------------------------"
      auto_optimize_dns
      echo -e "[${gl_lv}OK${gl_bai}] 9/12. 自动优化 DNS 地址"

      echo "------------------------------------------------"
      prefer_ipv4
      echo -e "[${gl_lv}OK${gl_bai}] 10/12. 设置网络为${gl_huang}IPv4 优先${gl_bai}"

      echo "------------------------------------------------"
      install_docker
      install wget sudo tar unzip socat btop nano vim
      echo -e "[${gl_lv}OK${gl_bai}] 11/12. 安装基础工具"

      echo "------------------------------------------------"
      curl -sS "${gh_proxy}raw.githubusercontent.com/kejilion/sh/refs/heads/main/network-optimize.sh" | bash
      echo -e "[${gl_lv}OK${gl_bai}] 12/12. Linux 系统内核参数优化"
      echo -e "${gl_lv}一条龙系统调优已完成${gl_bai}"
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

luopo_system_tools_history_menu() {
  clear
  send_stats "命令行历史记录"
  local history_file=""
  for file in "$HOME/.bash_history" "$HOME/.ash_history" "$HOME/.zsh_history" "$HOME/.local/share/fish/fish_history"; do
    if [[ -f "$file" ]]; then
      history_file="$file"
      break
    fi
  done

  if [[ -n "$history_file" ]]; then
    echo "历史记录文件: $history_file"
    echo "------------------------"
    cat -n "$history_file"
  else
    echo "未找到可用的历史记录文件"
  fi
  press_enter
}

luopo_system_tools_command_favorites() {
  clear
  send_stats "命令收藏夹"
  echo "正在启动命令收藏夹安装/管理脚本..."
  bash <(curl -fsSL "${gh_proxy}raw.githubusercontent.com/byJoey/cmdbox/refs/heads/main/install.sh")
}

luopo_system_tools_backup_list() {
  local backup_dir="$1"
  echo "可用备份："
  if compgen -G "$backup_dir/*.tar.gz" >/dev/null; then
    local file
    for file in "$backup_dir"/*.tar.gz; do
      basename "$file"
    done
  else
    echo "暂无备份"
  fi
}

luopo_system_tools_backup_create() {
  local backup_dir="$1"
  local input
  local backup_paths=()
  local valid_paths=()
  local timestamp
  local prefix=""
  local backup_name

  echo "创建备份示例："
  echo "  - 备份单个目录: /var/www"
  echo "  - 备份多个目录: /etc /home /var/log"
  echo "  - 直接回车将使用默认目录 (/etc /usr /home)"
  read -r -p "请输入要备份的目录（多个目录用空格分隔，直接回车则使用默认目录）: " input

  if [[ -z "$input" ]]; then
    backup_paths=(/etc /usr /home)
  else
    # shellcheck disable=SC2206
    backup_paths=($input)
  fi

  for path in "${backup_paths[@]}"; do
    if [[ ! -e "$path" ]]; then
      echo "跳过不存在的路径: $path"
      continue
    fi
    valid_paths+=("$path")
    prefix+="$(basename "$path")_"
  done

  prefix="${prefix%_}"
  if [[ -z "$prefix" ]]; then
    echo "没有可备份的有效路径。"
    return 1
  fi

  timestamp="$(date +"%Y%m%d%H%M%S")"
  backup_name="${prefix}_${timestamp}.tar.gz"

  echo "您选择的备份目录为："
  for path in "${valid_paths[@]}"; do
    echo "- $path"
  done

  install tar
  echo "正在创建备份 $backup_name..."
  tar -czvf "$backup_dir/$backup_name" "${valid_paths[@]}"
  echo "备份创建成功: $backup_dir/$backup_name"
}

luopo_system_tools_backup_restore() {
  local backup_dir="$1"
  local backup_name

  luopo_system_tools_backup_list "$backup_dir"
  read -r -p "请输入要恢复的备份文件名: " backup_name
  if [[ -z "$backup_name" || ! -f "$backup_dir/$backup_name" ]]; then
    echo "备份文件不存在。"
    return 1
  fi

  read -r -p "确认恢复到系统根目录 / ? 此操作会覆盖同名文件 (y/N): " confirm
  case "$confirm" in
    [Yy])
      echo "正在恢复备份 $backup_name..."
      tar -xzvf "$backup_dir/$backup_name" -C /
      echo "备份恢复成功。"
      ;;
    *)
      echo "已取消恢复。"
      ;;
  esac
}

luopo_system_tools_backup_delete() {
  local backup_dir="$1"
  local backup_name

  luopo_system_tools_backup_list "$backup_dir"
  read -r -p "请输入要删除的备份文件名: " backup_name
  if [[ -z "$backup_name" || ! -f "$backup_dir/$backup_name" ]]; then
    echo "备份文件不存在。"
    return 1
  fi

  read -r -p "确认删除 $backup_name ? (y/N): " confirm
  case "$confirm" in
    [Yy])
      rm -f "$backup_dir/$backup_name"
      echo "备份删除成功。"
      ;;
    *)
      echo "已取消删除。"
      ;;
  esac
}

luopo_system_tools_backup_menu() {
  root_use
  send_stats "系统备份功能"

  local backup_dir="/backups"
  mkdir -p "$backup_dir"

  while true; do
    clear
    echo "系统备份功能"
    echo "备份目录: $backup_dir"
    echo "------------------------"
    luopo_system_tools_backup_list "$backup_dir"
    echo "------------------------"
    echo "1. 创建备份"
    echo "2. 恢复备份"
    echo "3. 删除备份"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1) luopo_system_tools_backup_create "$backup_dir" ;;
      2) luopo_system_tools_backup_restore "$backup_dir" ;;
      3) luopo_system_tools_backup_delete "$backup_dir" ;;
      0) return 0 ;;
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
