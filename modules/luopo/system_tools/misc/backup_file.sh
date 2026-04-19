#!/usr/bin/env bash
set -euo pipefail

# Backup, safe-trash, and file-manager menus.

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
