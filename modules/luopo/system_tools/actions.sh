#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_SYSTEM_TOOLS_DIR/../../.." && pwd)"

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

luopo_system_tools_python_version_menu() {
  root_use
  send_stats "py版本管理"
  clear
  echo "python版本管理"
  echo "视频介绍: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
  echo "---------------------------------------"
  echo "该功能可无缝安装 python 官方支持的任何版本。"
  local current_version
  current_version="$(python3 -V 2>&1 | awk '{print $2}')"
  echo -e "当前 python 版本号: ${gl_huang}${current_version:-未检测到}${gl_bai}"
  echo "------------"
  echo "推荐版本:  3.12    3.11    3.10    3.9    3.8    2.7"
  echo "查询更多版本: https://www.python.org/downloads/"
  echo "------------"
  read -r -p "输入你要安装的 python 版本号（输入0退出）: " py_new_v

  if [[ "$py_new_v" == "0" || -z "$py_new_v" ]]; then
    return 0
  fi

  if ! grep -q 'export PYENV_ROOT="\$HOME/.pyenv"' "$HOME/.bashrc" 2>/dev/null; then
    if command -v yum >/dev/null 2>&1; then
      yum update -y && yum install git -y
      yum groupinstall "Development Tools" -y
      yum install openssl-devel bzip2-devel libffi-devel ncurses-devel zlib-devel readline-devel sqlite-devel xz-devel findutils -y
    elif command -v apt >/dev/null 2>&1; then
      apt update -y && apt install git build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev libgdbm-dev libnss3-dev libedit-dev -y
    elif command -v apk >/dev/null 2>&1; then
      apk update && apk add git
      apk add --no-cache bash gcc musl-dev libffi-dev openssl-dev bzip2-dev zlib-dev readline-dev sqlite-dev libc6-compat linux-headers make xz-dev build-base ncurses-dev
    else
      echo "未知的包管理器，无法自动准备 pyenv 编译依赖。"
      press_enter
      return 0
    fi

    curl https://pyenv.run | bash
    cat <<'EOF' >> "$HOME/.bashrc"

export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
  fi

  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    pyenv install "$py_new_v"
    pyenv global "$py_new_v"
    rm -rf /tmp/python-build.* "$(pyenv root)/cache/"*
    echo -e "当前 python 版本号: ${gl_huang}$(python -V 2>&1 | awk '{print $2}')${gl_bai}"
    send_stats "脚本PY版本切换"
  else
    echo "pyenv 安装后仍不可用，请重新连接 SSH 后再试。"
  fi
  press_enter
}

luopo_system_tools_modify_ssh_port_menu() {
  root_use
  send_stats "修改SSH端口"
  while true; do
    clear
    sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
    local current_port
    current_port="$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}' | head -n1)"
    echo -e "当前的 SSH 端口号是: ${gl_huang}${current_port:-22}${gl_bai}"
    echo "------------------------"
    echo "端口号范围 1 到 65535 之间的数字。（输入0退出）"
    read -r -p "请输入新的 SSH 端口号: " new_port
    if [[ "$new_port" == "0" ]]; then
      return 0
    fi
    if [[ "$new_port" =~ ^[0-9]+$ ]] && [[ "$new_port" -ge 1 && "$new_port" -le 65535 ]]; then
      send_stats "SSH端口已修改"
      new_ssh_port "$new_port"
    else
      echo "端口号无效，请输入 1 到 65535 之间的数字。"
      send_stats "输入无效SSH端口"
    fi
    break_end
  done
}

luopo_system_tools_open_all_ports() {
  root_use
  send_stats "开放端口"
  iptables_open
  remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1
  echo "端口已全部开放"
  press_enter
}

luopo_system_tools_disable_root_create_user() {
  root_use
  send_stats "新用户禁用root"
  read -r -p "请输入新用户名（输入0退出）: " new_username
  if [[ "$new_username" == "0" || -z "$new_username" ]]; then
    return 0
  fi

  create_user_with_sshkey "$new_username" true
  if ssh-keygen -l -f "/home/$new_username/.ssh/authorized_keys" >/dev/null 2>&1; then
    passwd -l root >/dev/null 2>&1
    sed -i 's/^[[:space:]]*#\?[[:space:]]*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    restart_ssh
    echo "已创建用户 $new_username，并禁用 root SSH 登录。"
  else
    echo "未检测到新用户 SSH 密钥，已保留 root 登录。"
  fi
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
    4) luopo_system_tools_python_version_menu ;;
    6) luopo_system_tools_modify_ssh_port_menu ;;
    9) luopo_system_tools_disable_root_create_user ;;
    10) luopo_system_tools_network_priority_menu ;;
    11) luopo_system_tools_show_ports ;;
    13) luopo_system_tools_user_management_menu ;;
    18) luopo_system_tools_change_hostname_menu ;;
    19) luopo_system_tools_switch_mirror_menu ;;
    20) luopo_system_tools_crontab_menu ;;
    21) luopo_system_tools_hosts_menu ;;
    22) fail2ban_panel ;;
    23) luopo_system_tools_traffic_shutdown_menu ;;
    5) luopo_system_tools_open_all_ports ;;
    7) set_dns_ui ;;
    8) dd_xitong ;;
    12) luopo_system_tools_swap_menu ;;
    14) luopo_system_tools_generate_credentials ;;
    15) luopo_system_tools_timezone_menu ;;
    16) run_luopo_compat_menu linux_bbr ;;
    17) iptables_panel ;;
    24) sshkey_panel ;;
    25) luopo_system_tools_tg_monitor_menu ;;
    26) luopo_system_tools_fix_openssh ;;
    27) elrepo ;;
    28) Kernel_optimize ;;
    29) clamav ;;
    31) linux_language ;;
    32) shell_bianse ;;
    30) linux_file ;;
    33) linux_trash ;;
    34) linux_backup ;;
    35) ssh_manager ;;
    36) disk_manager ;;
    37) luopo_system_tools_history_menu ;;
    38) rsync_manager ;;
    39) linux_fav ;;
    40) net_menu ;;
    41) log_menu ;;
    42) env_menu ;;
    61) luopo_system_tools_feedback ;;
    66) luopo_system_tools_one_click_tune ;;
    99) server_reboot ;;
    100) luopo_system_tools_privacy_menu ;;
    101) luopo_system_tools_command_help ;;
    102) luopo_system_tools_uninstall_menu ;;
    *) luopo_system_tools_invalid_choice ;;
  esac
  return 0
}

