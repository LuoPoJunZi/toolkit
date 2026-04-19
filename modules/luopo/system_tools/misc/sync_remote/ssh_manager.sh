#!/usr/bin/env bash
set -euo pipefail

# SSH connection storage and launcher helpers.

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
