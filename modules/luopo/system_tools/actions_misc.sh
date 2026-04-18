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
      bash <(curl -sSL https://linuxmirrors.cn/main.sh)
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

luopo_system_tools_trash_menu() {
  root_use
  send_stats "系统回收站"

  local bashrc_profile="/root/.bashrc"
  local trash_dir="$HOME/.local/share/Trash/files"

  while true; do
    local trash_status
    if grep -q "alias rm='trash-put'" "$bashrc_profile" 2>/dev/null; then
      trash_status="${gl_lv:-}已启用${gl_bai:-}"
    else
      trash_status="${gl_hui:-}未启用${gl_bai:-}"
    fi

    clear
    echo -e "当前回收站 ${trash_status}"
    echo "启用后 rm 删除的文件会先进入回收站，降低误删风险。"
    echo "------------------------------------------------"
    if [[ -d "$trash_dir" ]]; then
      ls -l --color=auto "$trash_dir" 2>/dev/null || echo "回收站为空"
    else
      echo "回收站为空"
    fi
    echo "------------------------"
    echo "1. 启用回收站"
    echo "2. 关闭回收站"
    echo "3. 还原内容到当前用户主目录"
    echo "4. 清空回收站"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "输入你的选择: " choice

    case "$choice" in
      1)
        install trash-cli
        sed -i '/alias rm=/d' "$bashrc_profile"
        echo "alias rm='trash-put'" >> "$bashrc_profile"
        echo "回收站已启用。重新登录 SSH 后别名生效。"
        ;;
      2)
        sed -i '/alias rm=/d' "$bashrc_profile"
        echo "alias rm='rm -i'" >> "$bashrc_profile"
        echo "回收站已关闭。重新登录 SSH 后别名生效。"
        ;;
      3)
        read -r -p "输入要还原的文件名: " file_to_restore
        if [[ -z "$file_to_restore" ]]; then
          echo "文件名不能为空。"
        elif [[ -e "$trash_dir/$file_to_restore" ]]; then
          mv "$trash_dir/$file_to_restore" "$HOME/"
          echo "$file_to_restore 已还原到 $HOME。"
        else
          echo "文件不存在。"
        fi
        ;;
      4)
        read -r -p "确认清空回收站？(y/N): " confirm
        case "$confirm" in
          [Yy])
            if command -v trash-empty >/dev/null 2>&1; then
              trash-empty
            else
              rm -rf "$trash_dir"/*
            fi
            echo "回收站已清空。"
            ;;
          *) echo "已取消。" ;;
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

luopo_system_tools_file_menu() {
  root_use
  send_stats "文件管理器"

  while true; do
    clear
    echo "文件管理器"
    echo "------------------------"
    echo "当前路径"
    pwd
    echo "------------------------"
    ls --color=auto -x 2>/dev/null || true
    echo "------------------------"
    echo "1.  进入目录           2.  创建目录             3.  修改目录权限         4.  重命名目录"
    echo "5.  删除目录           6.  返回上一级目录"
    echo "------------------------"
    echo "11. 创建文件           12. 编辑文件             13. 修改文件权限         14. 重命名文件"
    echo "15. 删除文件"
    echo "------------------------"
    echo "21. 压缩文件目录       22. 解压文件目录         23. 移动文件目录         24. 复制文件目录"
    echo "25. 传文件至其他服务器"
    echo "------------------------"
    echo "0.  返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        read -r -p "请输入目录名: " dirname
        cd "$dirname" 2>/dev/null || echo "无法进入目录"
        ;;
      2)
        read -r -p "请输入要创建的目录名: " dirname
        [[ -n "$dirname" ]] && mkdir -p "$dirname" && echo "目录已创建" || echo "创建失败"
        ;;
      3)
        read -r -p "请输入目录名: " dirname
        read -r -p "请输入权限 (如 755): " perm
        [[ -d "$dirname" && "$perm" =~ ^[0-7]{3,4}$ ]] && chmod "$perm" "$dirname" && echo "权限已修改" || echo "修改失败"
        ;;
      4)
        read -r -p "请输入当前目录名: " current_name
        read -r -p "请输入新目录名: " new_name
        [[ -d "$current_name" && -n "$new_name" ]] && mv "$current_name" "$new_name" && echo "目录已重命名" || echo "重命名失败"
        ;;
      5)
        read -r -p "请输入要删除的目录名: " dirname
        if [[ -z "$dirname" || ! -d "$dirname" ]]; then
          echo "目录不存在。"
        else
          read -r -p "确认删除目录 $dirname ? (y/N): " confirm
          [[ "$confirm" =~ ^[Yy]$ ]] && rm -rf -- "$dirname" && echo "目录已删除" || echo "已取消"
        fi
        ;;
      6)
        cd ..
        ;;
      11)
        read -r -p "请输入要创建的文件名: " filename
        [[ -n "$filename" ]] && touch "$filename" && echo "文件已创建" || echo "创建失败"
        ;;
      12)
        read -r -p "请输入要编辑的文件名: " filename
        if [[ -n "$filename" ]]; then
          install nano
          nano "$filename"
        else
          echo "文件名不能为空。"
        fi
        ;;
      13)
        read -r -p "请输入文件名: " filename
        read -r -p "请输入权限 (如 644): " perm
        [[ -f "$filename" && "$perm" =~ ^[0-7]{3,4}$ ]] && chmod "$perm" "$filename" && echo "权限已修改" || echo "修改失败"
        ;;
      14)
        read -r -p "请输入当前文件名: " current_name
        read -r -p "请输入新文件名: " new_name
        [[ -f "$current_name" && -n "$new_name" ]] && mv "$current_name" "$new_name" && echo "文件已重命名" || echo "重命名失败"
        ;;
      15)
        read -r -p "请输入要删除的文件名: " filename
        if [[ -z "$filename" || ! -f "$filename" ]]; then
          echo "文件不存在。"
        else
          read -r -p "确认删除文件 $filename ? (y/N): " confirm
          [[ "$confirm" =~ ^[Yy]$ ]] && rm -f -- "$filename" && echo "文件已删除" || echo "已取消"
        fi
        ;;
      21)
        read -r -p "请输入要压缩的文件/目录名: " name
        if [[ -e "$name" ]]; then
          install tar
          tar -czvf "$name.tar.gz" "$name" && echo "已压缩为 $name.tar.gz" || echo "压缩失败"
        else
          echo "文件或目录不存在。"
        fi
        ;;
      22)
        read -r -p "请输入要解压的文件名 (.tar.gz): " filename
        if [[ -f "$filename" ]]; then
          install tar
          tar -xzvf "$filename" && echo "已解压 $filename" || echo "解压失败"
        else
          echo "压缩文件不存在。"
        fi
        ;;
      23)
        read -r -p "请输入要移动的文件或目录路径: " src_path
        read -r -p "请输入目标路径: " dest_path
        [[ -e "$src_path" && -n "$dest_path" ]] && mv "$src_path" "$dest_path" && echo "已移动到 $dest_path" || echo "移动失败"
        ;;
      24)
        read -r -p "请输入要复制的文件或目录路径: " src_path
        read -r -p "请输入目标路径: " dest_path
        [[ -e "$src_path" && -n "$dest_path" ]] && cp -r "$src_path" "$dest_path" && echo "已复制到 $dest_path" || echo "复制失败"
        ;;
      25)
        local file_to_transfer remote_ip remote_user remote_port remote_password scp_cmd
        read -r -p "请输入要传送的文件路径: " file_to_transfer
        if [[ ! -f "$file_to_transfer" ]]; then
          echo "错误: 文件不存在。"
          break_end
          continue
        fi
        read -r -p "请输入远端服务器IP: " remote_ip
        read -r -p "请输入远端服务器用户名 [默认root]: " remote_user
        read -r -p "请输入登录端口 [默认22]: " remote_port
        remote_user="${remote_user:-root}"
        remote_port="${remote_port:-22}"
        if [[ -z "$remote_ip" ]]; then
          echo "远端服务器IP不能为空。"
          break_end
          continue
        fi
        read -r -s -p "请输入远端服务器密码（留空则使用 SSH Key）: " remote_password
        echo
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$remote_ip" >/dev/null 2>&1 || true
        if [[ -n "$remote_password" ]]; then
          install sshpass
          sshpass -p "$remote_password" scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/"
        else
          scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/"
        fi
        echo "传输命令已执行，请检查上方输出确认结果。"
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

luopo_system_tools_rsync_config_file() {
  printf '%s\n' "$HOME/.rsync_tasks"
}

luopo_system_tools_rsync_key_dir() {
  printf '%s\n' "$HOME/.ssh/luopo_rsync"
}

luopo_system_tools_rsync_list_tasks() {
  local config_file="$1"
  echo "已保存的同步任务:"
  echo "---------------------------------"
  if [[ ! -s "$config_file" ]]; then
    echo "暂无任务"
  else
    awk -F'|' '{printf "%d. %s (%s -> %s@%s:%s)\n", NR, $1, $2, $3, $4, $5}' "$config_file"
  fi
  echo "---------------------------------"
}

luopo_system_tools_rsync_list_schedules() {
  echo "当前定时任务:"
  echo "---------------------------------"
  crontab -l 2>/dev/null | grep "luopo_rsync_run" || echo "暂无定时任务"
  echo "---------------------------------"
}

luopo_system_tools_rsync_add_task() {
  local config_file="$1"
  local key_dir="$2"
  local name local_path remote_user remote_host remote_path port mode options auth_method secret key_file password

  send_stats "添加新同步任务"
  echo "创建新同步任务示例："
  echo "  - 任务名称: backup_www"
  echo "  - 本地目录: /var/www"
  echo "  - 远程用户: root"
  echo "  - 远程地址: 192.168.1.100"
  echo "  - 远程目录: /backup/www"
  echo "---------------------------------"
  read -r -p "请输入任务名称: " name
  read -r -p "请输入本地目录: " local_path
  read -r -p "请输入远程用户名 [默认root]: " remote_user
  read -r -p "请输入远程服务器IP/域名: " remote_host
  read -r -p "请输入远程目录: " remote_path
  read -r -p "请输入 SSH 端口 [默认22]: " port
  remote_user="${remote_user:-root}"
  port="${port:-22}"

  if [[ -z "$name" || -z "$local_path" || -z "$remote_host" || -z "$remote_path" ]]; then
    echo "任务名称、本地目录、远程地址、远程目录不能为空。"
    return 1
  fi

  echo "请选择认证方式:"
  echo "1. SSH 密码"
  echo "2. SSH 私钥文件"
  read -r -p "请选择 (1/2): " auth_choice
  case "$auth_choice" in
    1)
      read -r -s -p "请输入 SSH 密码: " password
      echo
      auth_method="password"
      secret="$password"
      ;;
    2)
      mkdir -p "$key_dir"
      read -r -p "请输入私钥文件路径（留空则粘贴保存为专用密钥）: " key_file
      if [[ -z "$key_file" ]]; then
        key_file="$key_dir/${name}_sync.key"
        echo "请粘贴私钥内容，输入单独一行 EOF 结束："
        : > "$key_file"
        while IFS= read -r line; do
          [[ "$line" == "EOF" ]] && break
          printf '%s\n' "$line" >> "$key_file"
        done
      fi
      if [[ ! -f "$key_file" ]]; then
        echo "私钥文件不存在。"
        return 1
      fi
      chmod 600 "$key_file"
      auth_method="key"
      secret="$key_file"
      ;;
    *)
      echo "无效认证方式。"
      return 1
      ;;
  esac

  echo "请选择同步模式:"
  echo "1. 标准模式 (-avz)"
  echo "2. 删除目标多余文件 (-avz --delete)"
  read -r -p "请选择 (1/2): " mode
  case "$mode" in
    2) options="-avz --delete" ;;
    *) options="-avz" ;;
  esac

  install rsync
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$name" "$local_path" "$remote_user" "$remote_host" "$remote_path" "$port" "$options" "$auth_method" "$secret" >> "$config_file"
  echo "任务已保存。"
}

luopo_system_tools_rsync_delete_task() {
  local config_file="$1"
  local key_dir="$2"
  local num task name local_path remote_user remote_host remote_path port options auth_method secret

  send_stats "删除同步任务"
  luopo_system_tools_rsync_list_tasks "$config_file"
  read -r -p "请输入要删除的任务编号: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  task="$(sed -n "${num}p" "$config_file" 2>/dev/null || true)"
  if [[ -z "$task" ]]; then
    echo "未找到对应任务。"
    return 1
  fi

  IFS='|' read -r name local_path remote_user remote_host remote_path port options auth_method secret <<< "$task"
  read -r -p "确认删除任务 $name ? (y/N): " confirm
  case "$confirm" in
    [Yy])
      if [[ "$auth_method" == "key" && "$secret" == "$key_dir"* ]]; then
        rm -f -- "$secret"
      fi
      sed -i "${num}d" "$config_file"
      echo "任务已删除。"
      ;;
    *) echo "已取消。" ;;
  esac
}

luopo_system_tools_rsync_run_task() {
  local direction="${1:-push}"
  local num="${2:-}"
  local config_file
  local task name local_path remote_user remote_host remote_path port options auth_method secret
  local source_path destination_path ssh_options

  config_file="$(luopo_system_tools_rsync_config_file)"
  if [[ -z "$num" ]]; then
    luopo_system_tools_rsync_list_tasks "$config_file"
    read -r -p "请输入要执行的任务编号: " num
  fi
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  task="$(sed -n "${num}p" "$config_file" 2>/dev/null || true)"
  if [[ -z "$task" ]]; then
    echo "未找到对应任务。"
    return 1
  fi

  IFS='|' read -r name local_path remote_user remote_host remote_path port options auth_method secret <<< "$task"
  ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

  if [[ "$direction" == "pull" ]]; then
    echo "正在拉取同步到本地: $remote_user@$remote_host:$remote_path -> $local_path"
    source_path="$remote_user@$remote_host:$remote_path"
    destination_path="$local_path"
  else
    echo "正在推送同步到远端: $local_path -> $remote_user@$remote_host:$remote_path"
    source_path="$local_path"
    destination_path="$remote_user@$remote_host:$remote_path"
  fi

  install rsync
  if [[ "$auth_method" == "password" ]]; then
    install sshpass
    sshpass -p "$secret" rsync $options -e "ssh $ssh_options" "$source_path" "$destination_path"
  else
    if [[ ! -f "$secret" ]]; then
      echo "密钥文件不存在: $secret"
      return 1
    fi
    chmod 600 "$secret"
    rsync $options -e "ssh -i $secret $ssh_options" "$source_path" "$destination_path"
  fi
}

luopo_system_tools_rsync_schedule_task() {
  local num interval random_minute cron_time root_dir cron_job

  send_stats "添加同步定时任务"
  luopo_system_tools_rsync_list_tasks "$(luopo_system_tools_rsync_config_file)"
  read -r -p "请输入要定时同步的任务编号: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  echo "请选择定时执行间隔："
  echo "1. 每小时执行一次"
  echo "2. 每天执行一次"
  echo "3. 每周执行一次"
  read -r -p "请输入选项 (1/2/3): " interval

  random_minute="$(awk 'BEGIN{srand(); print int(rand()*60)}')"
  case "$interval" in
    1) cron_time="$random_minute * * * *" ;;
    2) cron_time="$random_minute 0 * * *" ;;
    3) cron_time="$random_minute 0 * * 1" ;;
    *)
      echo "无效选项。"
      return 1
      ;;
  esac

  check_crontab_installed
  root_dir="${ROOT_DIR:-/opt/luopo-toolkit}"
  cron_job="$cron_time bash \"$root_dir/toolkit.sh\" rsync_run \"$num\" # luopo_rsync_run:$num"
  if crontab -l 2>/dev/null | grep -q "luopo_rsync_run:$num"; then
    echo "该任务的定时同步已存在。"
    return 1
  fi
  (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
  echo "定时任务已创建: $cron_job"
}

luopo_system_tools_rsync_delete_schedule() {
  local num tmp_file

  send_stats "删除同步定时任务"
  luopo_system_tools_rsync_list_schedules
  read -r -p "请输入要删除定时任务的编号: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  tmp_file="$(mktemp)"
  crontab -l 2>/dev/null | grep -v "luopo_rsync_run:$num" > "$tmp_file" || true
  crontab "$tmp_file"
  rm -f "$tmp_file"
  echo "已删除任务编号 $num 的定时任务。"
}

luopo_system_tools_rsync_menu() {
  local config_file key_dir

  config_file="$(luopo_system_tools_rsync_config_file)"
  key_dir="$(luopo_system_tools_rsync_key_dir)"
  mkdir -p "$(dirname "$config_file")" "$key_dir"
  touch "$config_file"

  while true; do
    clear
    echo "Rsync 远程同步工具"
    echo "远程目录之间同步，支持增量同步。"
    echo "---------------------------------"
    luopo_system_tools_rsync_list_tasks "$config_file"
    echo
    luopo_system_tools_rsync_list_schedules
    echo
    echo "1. 创建新任务"
    echo "2. 删除任务"
    echo "3. 执行本地同步到远端"
    echo "4. 执行远端同步到本地"
    echo "5. 创建定时任务"
    echo "6. 删除定时任务"
    echo "---------------------------------"
    echo "0. 返回上一级选单"
    echo "---------------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1) luopo_system_tools_rsync_add_task "$config_file" "$key_dir" ;;
      2) luopo_system_tools_rsync_delete_task "$config_file" "$key_dir" ;;
      3) luopo_system_tools_rsync_run_task push ;;
      4) luopo_system_tools_rsync_run_task pull ;;
      5) luopo_system_tools_rsync_schedule_task ;;
      6) luopo_system_tools_rsync_delete_schedule ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_clamav_freshclam() {
  echo -e "${gl_kjlan:-}正在更新病毒库...${gl_bai:-}"
  docker volume create clam_db >/dev/null 2>&1
  docker run --rm \
    --name luopo-clamav-update \
    --mount source=clam_db,target=/var/lib/clamav \
    clamav/clamav-debian:latest \
    freshclam
}

luopo_system_tools_clamav_scan() {
  local dirs=("$@")
  local mount_args=()
  local scan_args=()
  local dir

  if [[ ${#dirs[@]} -eq 0 ]]; then
    echo "请指定要扫描的目录。"
    return 1
  fi

  for dir in "${dirs[@]}"; do
    if [[ ! -e "$dir" ]]; then
      echo "跳过不存在的目录或文件: $dir"
      continue
    fi
    mount_args+=(--mount "type=bind,source=$dir,target=/mnt/host$dir,readonly")
    scan_args+=("/mnt/host$dir")
  done

  if [[ ${#scan_args[@]} -eq 0 ]]; then
    echo "没有可扫描的有效路径。"
    return 1
  fi

  mkdir -p /home/docker/clamav/log/
  : > /home/docker/clamav/log/scan.log
  echo -e "${gl_kjlan:-}正在扫描: ${dirs[*]}${gl_bai:-}"
  docker run --rm \
    --name luopo-clamav-scan \
    --mount source=clam_db,target=/var/lib/clamav \
    "${mount_args[@]}" \
    -v /home/docker/clamav/log/:/var/log/clamav/ \
    clamav/clamav-debian:latest \
    clamscan -r --log=/var/log/clamav/scan.log "${scan_args[@]}"

  echo -e "${gl_lv:-}扫描完成，病毒报告: ${gl_huang:-}/home/docker/clamav/log/scan.log${gl_bai:-}"
  echo -e "${gl_lv:-}如有病毒，请在 scan.log 中搜索 FOUND 确认位置。${gl_bai:-}"
}

luopo_system_tools_clamav_menu() {
  root_use
  send_stats "病毒扫描管理"

  while true; do
    clear
    echo "ClamAV 病毒扫描工具"
    echo "------------------------"
    echo "开源防病毒工具，可检测病毒、木马、间谍软件、恶意脚本等。"
    echo "扫描通过 Docker 容器执行，不在宿主机长期安装扫描服务。"
    echo "------------------------"
    echo "1. 全盘扫描"
    echo "2. 重要目录扫描"
    echo "3. 自定义目录扫描"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice

    case "$sub_choice" in
      1)
        send_stats "全盘扫描"
        install_docker
        luopo_system_tools_clamav_freshclam
        luopo_system_tools_clamav_scan /
        ;;
      2)
        send_stats "重要目录扫描"
        install_docker
        luopo_system_tools_clamav_freshclam
        luopo_system_tools_clamav_scan /etc /var /usr /home /root
        ;;
      3)
        local directories
        send_stats "自定义目录扫描"
        read -r -p "请输入要扫描的目录，用空格分隔（例如：/etc /var /usr /home /root）: " directories
        install_docker
        luopo_system_tools_clamav_freshclam
        # shellcheck disable=SC2206
        luopo_system_tools_clamav_scan $directories
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

luopo_system_tools_ssh_config_file() {
  printf '%s\n' "$HOME/.ssh_connections"
}

luopo_system_tools_ssh_key_dir() {
  printf '%s\n' "$HOME/.ssh/ssh_manager_keys"
}

luopo_system_tools_ssh_list_connections() {
  local config_file="$1"
  echo "已保存的连接:"
  echo "------------------------"
  if [[ ! -s "$config_file" ]]; then
    echo "暂无连接"
  else
    awk -F'|' '{printf "%d. %s (%s@%s:%s)\n", NR, $1, $3, $2, $4}' "$config_file"
  fi
  echo "------------------------"
}

luopo_system_tools_ssh_add_connection() {
  local config_file="$1"
  local key_dir="$2"
  local name host user port auth_choice auth_method secret password key_file line

  send_stats "添加新连接"
  echo "创建新连接示例："
  echo "  - 连接名称: my_server"
  echo "  - IP地址: 192.168.1.100"
  echo "  - 用户名: root"
  echo "  - 端口: 22"
  echo "------------------------"
  read -r -p "请输入连接名称: " name
  read -r -p "请输入IP地址/域名: " host
  read -r -p "请输入用户名 [默认root]: " user
  read -r -p "请输入端口号 [默认22]: " port
  user="${user:-root}"
  port="${port:-22}"

  if [[ -z "$name" || -z "$host" ]]; then
    echo "连接名称和地址不能为空。"
    return 1
  fi

  echo "请选择认证方式:"
  echo "1. SSH 密码"
  echo "2. SSH 私钥文件"
  read -r -p "请选择 (1/2): " auth_choice
  case "$auth_choice" in
    1)
      read -r -s -p "请输入 SSH 密码: " password
      echo
      auth_method="password"
      secret="$password"
      ;;
    2)
      mkdir -p "$key_dir"
      read -r -p "请输入私钥文件路径（留空则粘贴保存为专用密钥）: " key_file
      if [[ -z "$key_file" ]]; then
        key_file="$key_dir/${name}.key"
        echo "请粘贴私钥内容，输入单独一行 EOF 结束："
        : > "$key_file"
        while IFS= read -r line; do
          [[ "$line" == "EOF" ]] && break
          printf '%s\n' "$line" >> "$key_file"
        done
      fi
      if [[ ! -f "$key_file" ]]; then
        echo "私钥文件不存在。"
        return 1
      fi
      chmod 600 "$key_file"
      auth_method="key"
      secret="$key_file"
      ;;
    *)
      echo "无效认证方式。"
      return 1
      ;;
  esac

  printf '%s|%s|%s|%s|%s|%s\n' "$name" "$host" "$user" "$port" "$auth_method" "$secret" >> "$config_file"
  echo "连接已保存。"
}

luopo_system_tools_ssh_use_connection() {
  local config_file="$1"
  local num connection name host user port auth_method secret

  send_stats "使用连接"
  luopo_system_tools_ssh_list_connections "$config_file"
  read -r -p "请输入要使用的连接编号: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  connection="$(sed -n "${num}p" "$config_file" 2>/dev/null || true)"
  if [[ -z "$connection" ]]; then
    echo "未找到对应连接。"
    return 1
  fi

  IFS='|' read -r name host user port auth_method secret <<< "$connection"
  echo "正在连接到 $name ($user@$host:$port)..."
  if [[ "$auth_method" == "key" ]]; then
    if [[ ! -f "$secret" ]]; then
      echo "密钥文件不存在: $secret"
      return 1
    fi
    chmod 600 "$secret"
    ssh -o StrictHostKeyChecking=no -i "$secret" -p "$port" "$user@$host"
  else
    install sshpass
    sshpass -p "$secret" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$host"
  fi
}

luopo_system_tools_ssh_delete_connection() {
  local config_file="$1"
  local key_dir="$2"
  local num connection name host user port auth_method secret

  send_stats "删除连接"
  luopo_system_tools_ssh_list_connections "$config_file"
  read -r -p "请输入要删除的连接编号: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  connection="$(sed -n "${num}p" "$config_file" 2>/dev/null || true)"
  if [[ -z "$connection" ]]; then
    echo "未找到对应连接。"
    return 1
  fi

  IFS='|' read -r name host user port auth_method secret <<< "$connection"
  read -r -p "确认删除连接 $name ? (y/N): " confirm
  case "$confirm" in
    [Yy])
      if [[ "$auth_method" == "key" && "$secret" == "$key_dir"* ]]; then
        rm -f -- "$secret"
      fi
      sed -i "${num}d" "$config_file"
      echo "连接已删除。"
      ;;
    *) echo "已取消。" ;;
  esac
}

luopo_system_tools_ssh_manager_menu() {
  local config_file key_dir

  send_stats "ssh远程连接工具"
  config_file="$(luopo_system_tools_ssh_config_file)"
  key_dir="$(luopo_system_tools_ssh_key_dir)"
  mkdir -p "$(dirname "$config_file")" "$key_dir"
  chmod 700 "$key_dir"
  touch "$config_file"

  while true; do
    clear
    echo "SSH 远程连接工具"
    echo "可以通过 SSH 连接到其他 Linux 系统"
    echo "------------------------"
    luopo_system_tools_ssh_list_connections "$config_file"
    echo "1. 创建新连接"
    echo "2. 使用连接"
    echo "3. 删除连接"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice
    case "$choice" in
      1) luopo_system_tools_ssh_add_connection "$config_file" "$key_dir" ;;
      2) luopo_system_tools_ssh_use_connection "$config_file" ;;
      3) luopo_system_tools_ssh_delete_connection "$config_file" "$key_dir" ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_disk_list_partitions() {
  echo "可用的硬盘分区："
  lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -vE 'sr|loop' || true
}

luopo_system_tools_disk_list_mounted() {
  echo "已挂载的分区："
  df -h | grep -vE 'tmpfs|udev|overlay' || true
}

luopo_system_tools_disk_mount_partition() {
  local partition device mount_point uuid fstype

  send_stats "挂载分区"
  read -r -p "请输入要挂载的分区名称（例如 sda1）: " partition
  device="/dev/$partition"
  mount_point="/mnt/$partition"

  if [[ -z "$partition" || ! -b "$device" ]]; then
    echo "分区不存在。"
    return 1
  fi
  if findmnt -rn -S "$device" >/dev/null 2>&1; then
    echo "分区已经挂载。"
    return 1
  fi

  uuid="$(blkid -s UUID -o value "$device" 2>/dev/null || true)"
  fstype="$(blkid -s TYPE -o value "$device" 2>/dev/null || true)"
  if [[ -z "$uuid" || -z "$fstype" ]]; then
    echo "无法获取 UUID 或文件系统类型。"
    return 1
  fi

  mkdir -p "$mount_point"
  if ! mount "$device" "$mount_point"; then
    echo "分区挂载失败。"
    rmdir "$mount_point" 2>/dev/null || true
    return 1
  fi

  echo "分区已挂载到 $mount_point"
  if grep -qE "UUID=$uuid|[[:space:]]$mount_point[[:space:]]" /etc/fstab 2>/dev/null; then
    echo "/etc/fstab 中已存在该分区记录，跳过写入。"
    return 0
  fi
  printf 'UUID=%s %s %s defaults,nofail 0 2\n' "$uuid" "$mount_point" "$fstype" >> /etc/fstab
  echo "已写入 /etc/fstab，实现持久化挂载。"
}

luopo_system_tools_disk_unmount_partition() {
  local partition device mount_point

  send_stats "卸载分区"
  read -r -p "请输入要卸载的分区名称（例如 sda1）: " partition
  device="/dev/$partition"
  if [[ -z "$partition" || ! -b "$device" ]]; then
    echo "分区不存在。"
    return 1
  fi

  mount_point="$(findmnt -rn -S "$device" -o TARGET 2>/dev/null || true)"
  if [[ -z "$mount_point" ]]; then
    echo "分区未挂载。"
    return 1
  fi

  if umount "$device"; then
    echo "分区卸载成功: $mount_point"
    rmdir "$mount_point" 2>/dev/null || true
  else
    echo "分区卸载失败。"
  fi
}

luopo_system_tools_disk_format_partition() {
  local partition device fs_choice fs_type confirm

  send_stats "格式化分区"
  read -r -p "请输入要格式化的分区名称（例如 sda1）: " partition
  device="/dev/$partition"
  if [[ -z "$partition" || ! -b "$device" ]]; then
    echo "分区不存在。"
    return 1
  fi
  if findmnt -rn -S "$device" >/dev/null 2>&1; then
    echo "分区已经挂载，请先卸载。"
    return 1
  fi

  echo "请选择文件系统类型："
  echo "1. ext4"
  echo "2. xfs"
  echo "3. ntfs"
  echo "4. vfat"
  read -r -p "请输入你的选择: " fs_choice
  case "$fs_choice" in
    1) fs_type="ext4" ;;
    2) fs_type="xfs" ;;
    3) fs_type="ntfs" ;;
    4) fs_type="vfat" ;;
    *)
      echo "无效的选择。"
      return 1
      ;;
  esac

  echo "危险操作：格式化会清空 $device 上的所有数据。"
  read -r -p "如确认格式化，请输入 FORMAT: " confirm
  if [[ "$confirm" != "FORMAT" ]]; then
    echo "操作已取消。"
    return 0
  fi

  if ! command -v "mkfs.$fs_type" >/dev/null 2>&1; then
    case "$fs_type" in
      xfs) install xfsprogs ;;
      ntfs) install ntfs-3g ;;
      vfat) install dosfstools ;;
      ext4) install e2fsprogs ;;
    esac
  fi
  if ! command -v "mkfs.$fs_type" >/dev/null 2>&1; then
    echo "未找到 mkfs.$fs_type，无法格式化。"
    return 1
  fi
  echo "正在格式化 $device 为 $fs_type ..."
  "mkfs.$fs_type" "$device"
}

luopo_system_tools_disk_check_partition() {
  local partition device

  send_stats "检查分区状态"
  read -r -p "请输入要检查的分区名称（例如 sda1）: " partition
  device="/dev/$partition"
  if [[ -z "$partition" || ! -b "$device" ]]; then
    echo "分区不存在。"
    return 1
  fi
  fsck "$device"
}

luopo_system_tools_disk_manager_menu() {
  root_use
  send_stats "硬盘管理功能"

  while true; do
    clear
    echo "硬盘分区管理"
    echo -e "${gl_huang:-}高风险功能：请勿对系统盘或生产数据盘随意操作。${gl_bai:-}"
    echo "------------------------"
    luopo_system_tools_disk_list_partitions
    echo "------------------------"
    echo "1. 挂载分区"
    echo "2. 卸载分区"
    echo "3. 查看已挂载分区"
    echo "4. 格式化分区"
    echo "5. 检查分区状态"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice
    case "$choice" in
      1) luopo_system_tools_disk_mount_partition ;;
      2) luopo_system_tools_disk_unmount_partition ;;
      3) luopo_system_tools_disk_list_mounted ;;
      4) luopo_system_tools_disk_format_partition ;;
      5) luopo_system_tools_disk_check_partition ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_reinstall_menu() {
  root_use
  send_stats "重装系统"

  while true; do
    clear
    echo "重装系统"
    echo "--------------------------------"
    echo -e "${gl_hong:-}注意:${gl_bai:-} 重装有失联风险，请提前备份数据并确认服务商支持重装脚本。"
    echo "使用 bin456789/reinstall 项目执行，执行后通常会自动重启。"
    echo "--------------------------------"
    echo "1. Debian 13                  2. Debian 12"
    echo "3. Debian 11                  4. Debian 10"
    echo "--------------------------------"
    echo "11. Ubuntu 24.04              12. Ubuntu 22.04"
    echo "13. Ubuntu 20.04              14. Ubuntu 18.04"
    echo "--------------------------------"
    echo "21. Rocky Linux 9             22. Alma Linux 9"
    echo "23. Oracle Linux 9            24. Fedora Linux"
    echo "--------------------------------"
    echo "31. Alpine Linux              32. Arch Linux"
    echo "41. Windows 11                42. Windows 10"
    echo "--------------------------------"
    echo "0. 返回上一级选单"
    echo "--------------------------------"
    read -r -p "请选择要重装的系统: " sys_choice

    local reinstall_args=()
    local default_note="重装后请按所选脚本提示记录初始账号、密码和端口。"
    case "$sys_choice" in
      1) reinstall_args=(debian 13) ;;
      2) reinstall_args=(debian 12) ;;
      3) reinstall_args=(debian 11) ;;
      4) reinstall_args=(debian 10) ;;
      11) reinstall_args=(ubuntu 24.04) ;;
      12) reinstall_args=(ubuntu 22.04) ;;
      13) reinstall_args=(ubuntu 20.04) ;;
      14) reinstall_args=(ubuntu 18.04) ;;
      21) reinstall_args=(rocky 9) ;;
      22) reinstall_args=(almalinux 9) ;;
      23) reinstall_args=(oracle 9) ;;
      24) reinstall_args=(fedora) ;;
      31) reinstall_args=(alpine) ;;
      32) reinstall_args=(arch) ;;
      41) reinstall_args=(windows 11); default_note="Windows 初始账号/密码以脚本输出为准，请务必截图保存。" ;;
      42) reinstall_args=(windows 10); default_note="Windows 初始账号/密码以脚本输出为准，请务必截图保存。" ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac

    echo "$default_note"
    echo -e "${gl_hong:-}这是高风险操作，会重装系统并导致当前系统数据丢失。${gl_bai:-}"
    read -r -p "如确认继续，请输入 REINSTALL: " confirm
    if [[ "$confirm" != "REINSTALL" ]]; then
      echo "已取消。"
      break_end
      continue
    fi

    cd ~
    curl -fsSL -o reinstall.sh "${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
    chmod +x reinstall.sh
    bash reinstall.sh "${reinstall_args[@]}"
    echo "重装脚本已执行，如脚本未自动重启，请根据输出手动处理。"
    break_end
  done
}

luopo_system_tools_elrepo_menu() {
  root_use
  send_stats "红帽内核管理"

  if ! command -v rpm >/dev/null 2>&1 || ! { command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; }; then
    echo "ELRepo 内核管理仅支持 RHEL/CentOS/Alma/Rocky/Oracle 等红帽系发行版。"
    return 1
  fi

  local rhel_version
  rhel_version="$(rpm -E '%{rhel}' 2>/dev/null || true)"
  if [[ -z "$rhel_version" || "$rhel_version" == "%{rhel}" ]]; then
    echo "无法识别 RHEL 主版本，已取消。"
    return 1
  fi

  while true; do
    clear
    echo "红帽系 ELRepo 内核管理"
    echo "当前内核版本: $(uname -r)"
    echo "------------------------"
    echo "1. 安装/更新 ELRepo kernel-ml"
    echo "2. 卸载 ELRepo kernel-ml"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice

    case "$sub_choice" in
      1)
        read -r -p "确认安装/更新 ELRepo mainline kernel? (y/N): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { echo "已取消。"; break_end; continue; }
        if command -v dnf >/dev/null 2>&1; then
          dnf install -y "https://www.elrepo.org/elrepo-release-${rhel_version}.el${rhel_version}.elrepo.noarch.rpm"
          dnf --enablerepo=elrepo-kernel install -y kernel-ml
        else
          yum install -y "https://www.elrepo.org/elrepo-release-${rhel_version}.el${rhel_version}.elrepo.noarch.rpm"
          yum --enablerepo=elrepo-kernel install -y kernel-ml
        fi
        grub2-set-default 0 2>/dev/null || true
        echo "ELRepo kernel-ml 已安装/更新，建议确认启动项后重启。"
        ;;
      2)
        read -r -p "确认卸载 ELRepo kernel-ml? (y/N): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { echo "已取消。"; break_end; continue; }
        if command -v dnf >/dev/null 2>&1; then
          dnf remove -y 'kernel-ml*' elrepo-release
        else
          yum remove -y 'kernel-ml*' elrepo-release
        fi
        echo "ELRepo kernel-ml 已卸载，重启后生效。"
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

luopo_system_tools_kernel_write_profile() {
  local mode_name="$1"
  local scene="$2"
  local conf="/etc/sysctl.d/99-luopo-optimize.conf"
  local swappiness dirty_ratio dirty_bg overcommit vfs_pressure rmem_max wmem_max tcp_rmem tcp_wmem somaxconn backlog syn_backlog port_range fin_timeout keepalive_time keepalive_intvl keepalive_probes

  case "$scene" in
    high|stream|game)
      swappiness=10; dirty_ratio=15; dirty_bg=5; overcommit=1; vfs_pressure=50
      rmem_max=67108864; wmem_max=67108864; tcp_rmem="4096 262144 67108864"; tcp_wmem="4096 262144 67108864"
      somaxconn=8192; backlog=250000; syn_backlog=8192; port_range="1024 65535"; fin_timeout=10
      keepalive_time=300; keepalive_intvl=30; keepalive_probes=5
      ;;
    web)
      swappiness=10; dirty_ratio=20; dirty_bg=10; overcommit=1; vfs_pressure=50
      rmem_max=33554432; wmem_max=33554432; tcp_rmem="4096 131072 33554432"; tcp_wmem="4096 131072 33554432"
      somaxconn=16384; backlog=10000; syn_backlog=16384; port_range="1024 65535"; fin_timeout=15
      keepalive_time=600; keepalive_intvl=60; keepalive_probes=5
      ;;
    *)
      swappiness=30; dirty_ratio=20; dirty_bg=10; overcommit=0; vfs_pressure=75
      rmem_max=16777216; wmem_max=16777216; tcp_rmem="4096 87380 16777216"; tcp_wmem="4096 65536 16777216"
      somaxconn=4096; backlog=5000; syn_backlog=4096; port_range="1024 49151"; fin_timeout=30
      keepalive_time=600; keepalive_intvl=60; keepalive_probes=5
      ;;
  esac

  cat > "$conf" <<EOF
# 模式: $mode_name | generated by LuoPo VPS Toolkit
vm.swappiness = $swappiness
vm.dirty_ratio = $dirty_ratio
vm.dirty_background_ratio = $dirty_bg
vm.overcommit_memory = $overcommit
vm.vfs_cache_pressure = $vfs_pressure
net.core.rmem_max = $rmem_max
net.core.wmem_max = $wmem_max
net.ipv4.tcp_rmem = $tcp_rmem
net.ipv4.tcp_wmem = $tcp_wmem
net.core.somaxconn = $somaxconn
net.core.netdev_max_backlog = $backlog
net.ipv4.tcp_max_syn_backlog = $syn_backlog
net.ipv4.ip_local_port_range = $port_range
net.ipv4.tcp_fin_timeout = $fin_timeout
net.ipv4.tcp_keepalive_time = $keepalive_time
net.ipv4.tcp_keepalive_intvl = $keepalive_intvl
net.ipv4.tcp_keepalive_probes = $keepalive_probes
EOF
  sysctl -p "$conf"
  echo "$mode_name 已应用。"
}

luopo_system_tools_kernel_restore_defaults() {
  rm -f /etc/sysctl.d/99-luopo-optimize.conf /etc/sysctl.d/99-kejilion-optimize.conf /etc/sysctl.d/99-network-optimize.conf
  sysctl --system >/dev/null 2>&1 || true
  echo "已移除工具写入的内核优化配置。"
}

luopo_system_tools_kernel_optimize_menu() {
  root_use
  while true; do
    local current_mode
    current_mode="$(grep '^# 模式:' /etc/sysctl.d/99-luopo-optimize.conf 2>/dev/null | sed 's/# 模式: //' | awk -F'|' '{print $1}' | xargs || true)"
    clear
    send_stats "Linux内核调优管理"
    echo "Linux系统内核参数优化"
    if [[ -n "$current_mode" ]]; then
      echo -e "当前模式: ${gl_lv:-}${current_mode}${gl_bai:-}"
    else
      echo -e "当前模式: ${gl_hui:-}未优化${gl_bai:-}"
    fi
    echo "------------------------------------------------"
    echo -e "${gl_huang:-}提示:${gl_bai:-} 生产环境请谨慎使用，建议先备份配置。"
    echo "1. 高性能优化模式"
    echo "2. 均衡优化模式"
    echo "3. 网站优化模式"
    echo "4. 直播优化模式"
    echo "5. 游戏服优化模式"
    echo "6. 还原默认设置"
    echo "7. 自动调优（使用外部 network-optimize 脚本）"
    echo "--------------------"
    echo "0. 返回上一级选单"
    echo "--------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1) luopo_system_tools_kernel_write_profile "高性能优化模式" "high" ;;
      2) luopo_system_tools_kernel_write_profile "均衡优化模式" "balanced" ;;
      3) luopo_system_tools_kernel_write_profile "网站优化模式" "web" ;;
      4) luopo_system_tools_kernel_write_profile "直播优化模式" "stream" ;;
      5) luopo_system_tools_kernel_write_profile "游戏服优化模式" "game" ;;
      6) luopo_system_tools_kernel_restore_defaults ;;
      7) curl -sS "${gh_proxy}raw.githubusercontent.com/kejilion/sh/refs/heads/main/network-optimize.sh" | bash ;;
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
