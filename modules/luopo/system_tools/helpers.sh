#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_SYSTEM_TOOLS_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/compat/common.sh"

luopo_system_tools_bootstrap() {
  ensure_luopo_vendor_loaded
}

luopo_system_tools_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_SYSTEM_TOOLS_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_system_tools_item_label() {
  local item="$1"
  IFS='|' read -r _ label <<<"$item"
  printf '%s\n' "$label"
}

luopo_system_tools_render_cell() {
  local key="$1"
  local item label
  item="$(luopo_system_tools_find_item "$key")" || return 1
  label="$(luopo_system_tools_item_label "$item")"
  printf "%b%-4s %b%s%b" "$gl_kjlan" "${key}." "$gl_bai" "$label" "$gl_bai"
}

luopo_system_tools_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

luopo_system_tools_current_swap_info() {
  free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}'
}

luopo_system_tools_print_generated_credentials() {
  local i first_name_index last_name_index user_name password uuid username
  local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
  local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

  echo "随机用户名"
  echo "------------------------"
  for i in {1..5}; do
    username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
    echo "随机用户名 $i: $username"
  done

  echo
  echo "随机姓名"
  echo "------------------------"
  for i in {1..5}; do
    first_name_index=$((RANDOM % ${#first_names[@]}))
    last_name_index=$((RANDOM % ${#last_names[@]}))
    user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
    echo "随机用户姓名 $i: $user_name"
  done

  echo
  echo "随机UUID"
  echo "------------------------"
  for i in {1..5}; do
    uuid="$(cat /proc/sys/kernel/random/uuid)"
    echo "随机UUID $i: $uuid"
  done

  echo
  echo "16位随机密码"
  echo "------------------------"
  for i in {1..5}; do
    password="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)"
    echo "随机密码 $i: $password"
  done
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

