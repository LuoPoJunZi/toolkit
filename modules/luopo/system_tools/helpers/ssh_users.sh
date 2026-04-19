#!/usr/bin/env bash
set -euo pipefail

# SSH key and user table helpers.

sshkey_on() {
  sed -i \
    -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
    -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
    -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
    -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' \
    /etc/ssh/sshd_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/* 2>/dev/null || true
  restart_ssh
  echo -e "${gl_lv}用户密钥登录模式已开启，已关闭密码登录模式，重连将会生效${gl_bai}"
}

add_sshkey() {
  chmod 700 "$HOME"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  touch "$HOME/.ssh/authorized_keys"

  ssh-keygen -t ed25519 -C "luopo@toolkit" -f "$HOME/.ssh/sshkey" -N ""
  cat "$HOME/.ssh/sshkey.pub" >> "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"

  luopo_system_tools_ip_address
  echo -e "私钥信息已生成，务必复制保存，可保存成 ${gl_huang}${ipv4_address:-server}_ssh.key${gl_bai} 文件，用于后续 SSH 登录"
  echo "--------------------------------"
  cat "$HOME/.ssh/sshkey"
  echo "--------------------------------"

  sshkey_on
}

import_sshkey() {
  local public_key="${1:-}"
  local base_dir="${2:-$HOME}"
  local ssh_dir="${base_dir}/.ssh"
  local auth_keys="${ssh_dir}/authorized_keys"

  if [[ -z "$public_key" ]]; then
    read -r -p "请输入您的SSH公钥内容（通常以 'ssh-rsa' 或 'ssh-ed25519' 开头）: " public_key
  fi

  [[ -n "$public_key" ]] || { echo "错误：未输入公钥内容。"; return 1; }
  [[ "$public_key" =~ ^ssh-(rsa|ed25519|ecdsa) ]] || { echo "错误：看起来不像合法的 SSH 公钥。"; return 1; }

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
  touch "$auth_keys"
  if grep -Fxq "$public_key" "$auth_keys" 2>/dev/null; then
    echo "该公钥已存在，无需重复添加"
    return 0
  fi

  echo "$public_key" >> "$auth_keys"
  chmod 600 "$auth_keys"
  sshkey_on
}

fetch_remote_ssh_keys() {
  local keys_url="${1:-}"
  local base_dir="${2:-$HOME}"
  local ssh_dir="${base_dir}/.ssh"
  local authorized_keys="${ssh_dir}/authorized_keys"
  local temp_file added

  if [[ -z "$keys_url" ]]; then
    read -r -p "请输入您的远端公钥URL： " keys_url
  fi

  temp_file="$(mktemp)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --connect-timeout 10 "$keys_url" -o "$temp_file" || { rm -f "$temp_file"; echo "错误：无法从 URL 下载公钥"; return 1; }
  elif command -v wget >/dev/null 2>&1; then
    wget -q --timeout=10 -O "$temp_file" "$keys_url" || { rm -f "$temp_file"; echo "错误：无法从 URL 下载公钥"; return 1; }
  else
    rm -f "$temp_file"
    echo "错误：系统中未找到 curl 或 wget，无法下载公钥"
    return 1
  fi

  [[ -s "$temp_file" ]] || { rm -f "$temp_file"; echo "错误：下载到的文件为空"; return 1; }

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
  touch "$authorized_keys"
  chmod 600 "$authorized_keys"
  cp "$authorized_keys" "${authorized_keys}.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

  added=0
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    [[ "$line" =~ ^ssh-(rsa|ed25519|ecdsa) ]] || continue
    if ! grep -Fxq "$line" "$authorized_keys" 2>/dev/null; then
      echo "$line" >> "$authorized_keys"
      added=$((added + 1))
    fi
  done < "$temp_file"
  rm -f "$temp_file"

  if (( added > 0 )); then
    echo "成功添加 ${added} 条新的公钥到 ${authorized_keys}"
    sshkey_on
  else
    echo "没有新的公钥需要添加（可能已全部存在）"
  fi
}

fetch_github_ssh_keys() {
  local username="${1:-}"
  local base_dir="${2:-$HOME}"
  [[ -n "$username" ]] || read -r -p "请输入您的 GitHub 用户名（username，不含 @）： " username
  [[ -n "$username" ]] || { echo "错误：GitHub 用户名不能为空"; return 1; }
  fetch_remote_ssh_keys "https://github.com/${username}.keys" "$base_dir"
}

create_user_with_sshkey() {
  local new_username="$1"
  local is_sudo="${2:-false}"
  local sshkey_vl

  [[ -n "$new_username" ]] || { echo "用法：create_user_with_sshkey <用户名>"; return 1; }
  id "$new_username" >/dev/null 2>&1 && { echo "用户 $new_username 已存在"; return 1; }

  useradd -m -s /bin/bash "$new_username" || return 1

  echo "导入公钥范例："
  echo "  - URL：      https://github.com/torvalds.keys"
  echo "  - GitHub：   github:torvalds"
  echo "  - 直接粘贴： ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
  read -r -p "请导入 ${new_username} 的公钥: " sshkey_vl

  case "$sshkey_vl" in
    http://*|https://*)
      send_stats "从 URL 导入 SSH 公钥"
      fetch_remote_ssh_keys "$sshkey_vl" "/home/$new_username"
      ;;
    github:*)
      send_stats "从 GitHub 导入 SSH 公钥"
      fetch_github_ssh_keys "${sshkey_vl#github:}" "/home/$new_username"
      ;;
    ssh-rsa*|ssh-ed25519*|ssh-ecdsa*)
      send_stats "公钥直接导入"
      import_sshkey "$sshkey_vl" "/home/$new_username"
      ;;
    *)
      echo "错误：未知参数 '$sshkey_vl'"
      userdel -r "$new_username" >/dev/null 2>&1 || true
      return 1
      ;;
  esac

  chown -R "$new_username:$new_username" "/home/$new_username/.ssh" 2>/dev/null || true
  install sudo
  if [[ "$is_sudo" == "true" ]]; then
    cat > "/etc/sudoers.d/$new_username" <<EOF
$new_username ALL=(ALL) NOPASSWD:ALL
EOF
    chmod 440 "/etc/sudoers.d/$new_username"
  fi

  sed -i '/^\s*#\?\s*UsePAM\s\+/d' /etc/ssh/sshd_config
  echo 'UsePAM yes' >> /etc/ssh/sshd_config
  passwd -l "$new_username" >/dev/null 2>&1 || true
  restart_ssh
  echo "用户 $new_username 创建完成"
}

luopo_system_tools_print_user_table() {
  echo "用户列表"
  echo "----------------------------------------------------------------------------"
  printf "%-24s %-34s %-20s %-10s\n" "用户名" "主目录" "用户组" "sudo权限"
  while IFS=: read -r username _ _ _ _ _ homedir _; do
    local groups sudo_status
    groups="$(groups "$username" 2>/dev/null | cut -d : -f 2 | xargs)"
    if sudo -n -lU "$username" 2>/dev/null | grep -q "(ALL) \(NOPASSWD: \)\?ALL"; then
      sudo_status="Yes"
    else
      sudo_status="No"
    fi
    printf "%-24s %-34s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
  done < /etc/passwd
}
