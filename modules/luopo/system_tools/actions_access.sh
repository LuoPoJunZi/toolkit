#!/usr/bin/env bash
set -euo pipefail

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

luopo_system_tools_iptables_menu() {
  root_use
  install iptables
  save_iptables_rules || true
  while true; do
    clear
    echo "高级防火墙管理"
    echo "------------------------"
    iptables -L INPUT
    echo
    echo "1. 开放指定端口"
    echo "2. 关闭指定端口"
    echo "3. 开放所有端口"
    echo "4. 关闭所有端口"
    echo "5. IP白名单"
    echo "6. IP黑名单"
    echo "7. 清除指定IP规则"
    echo "11. 允许PING"
    echo "12. 禁止PING"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "请输入开放的端口号（可空格分隔多个）: " o_port
        [[ -n "$o_port" ]] && open_port $o_port
        ;;
      2)
        read -r -p "请输入关闭的端口号（可空格分隔多个）: " c_port
        [[ -n "$c_port" ]] && close_port $c_port
        ;;
      3)
        luopo_system_tools_open_all_ports
        continue
        ;;
      4)
        current_port="$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}' | head -n1)"
        iptables -F
        iptables -X
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A FORWARD -i lo -j ACCEPT
        [[ -n "$current_port" ]] && iptables -A INPUT -p tcp --dport "$current_port" -j ACCEPT
        save_iptables_rules || true
        echo "已关闭所有端口，仅保留当前 SSH 端口访问"
        ;;
      5)
        read -r -p "请输入放行的IP或CIDR: " o_ip
        [[ -n "$o_ip" ]] || { echo "IP不能为空"; press_enter; continue; }
        iptables -D INPUT -s "$o_ip" -j DROP >/dev/null 2>&1 || true
        iptables -C INPUT -s "$o_ip" -j ACCEPT >/dev/null 2>&1 || iptables -I INPUT 1 -s "$o_ip" -j ACCEPT
        save_iptables_rules || true
        echo "已放行 $o_ip"
        ;;
      6)
        read -r -p "请输入封禁的IP或CIDR: " c_ip
        [[ -n "$c_ip" ]] || { echo "IP不能为空"; press_enter; continue; }
        iptables -D INPUT -s "$c_ip" -j ACCEPT >/dev/null 2>&1 || true
        iptables -C INPUT -s "$c_ip" -j DROP >/dev/null 2>&1 || iptables -I INPUT 1 -s "$c_ip" -j DROP
        save_iptables_rules || true
        echo "已封禁 $c_ip"
        ;;
      7)
        read -r -p "请输入要清除的IP或CIDR: " d_ip
        [[ -n "$d_ip" ]] || { echo "IP不能为空"; press_enter; continue; }
        iptables -D INPUT -s "$d_ip" -j ACCEPT >/dev/null 2>&1 || true
        iptables -D INPUT -s "$d_ip" -j DROP >/dev/null 2>&1 || true
        save_iptables_rules || true
        echo "已清除 $d_ip 相关规则"
        ;;
      11)
        iptables -C INPUT -p icmp --icmp-type echo-request -j ACCEPT >/dev/null 2>&1 || iptables -I INPUT 1 -p icmp --icmp-type echo-request -j ACCEPT
        save_iptables_rules || true
        echo "已允许PING"
        ;;
      12)
        iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT >/dev/null 2>&1 || true
        iptables -C INPUT -p icmp --icmp-type echo-request -j DROP >/dev/null 2>&1 || iptables -I INPUT 1 -p icmp --icmp-type echo-request -j DROP
        save_iptables_rules || true
        echo "已禁止PING"
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

luopo_system_tools_sshkey_menu() {
  root_use
  send_stats "用户密钥登录"
  while true; do
    clear
    local real_status
    real_status="$(grep -i '^PubkeyAuthentication' /etc/ssh/sshd_config 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    if [[ "$real_status" =~ yes ]]; then
      echo -e "用户密钥登录模式 ${gl_lv}已启用${gl_bai}"
    else
      echo -e "用户密钥登录模式 ${gl_hui}未启用${gl_bai}"
    fi
    echo "进阶玩法: https://github.com/LuoPoJunZi/toolkit"
    echo "------------------------------------------------"
    echo "1. 生成新密钥对"
    echo "2. 手动输入已有公钥"
    echo "3. 从GitHub导入已有公钥"
    echo "4. 从URL导入已有公钥"
    echo "5. 编辑公钥文件"
    echo "6. 查看本机密钥"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1) add_sshkey ;;
      2) import_sshkey ;;
      3) fetch_github_ssh_keys ;;
      4)
        read -r -p "请输入您的远端公钥URL： " keys_url
        fetch_remote_ssh_keys "$keys_url"
        ;;
      5)
        install nano
        nano "$HOME/.ssh/authorized_keys"
        ;;
      6)
        echo "------------------------"
        echo "公钥信息"
        cat "$HOME/.ssh/authorized_keys" 2>/dev/null || echo "未找到 authorized_keys"
        echo "------------------------"
        echo "私钥信息"
        cat "$HOME/.ssh/sshkey" 2>/dev/null || echo "未找到 sshkey"
        echo "------------------------"
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
