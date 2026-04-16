#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_APP_MARKETPLACE_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/compat/common.sh"

luopo_app_marketplace_bootstrap() {
  ensure_luopo_vendor_loaded
}

luopo_app_marketplace_sync_index() {
  clear
  cd ~ || return 1
  install git
  echo -e "${gl_kjlan}正在更新应用列表请稍等……${gl_bai}"
  if [[ ! -d apps/.git ]]; then
    timeout 10s git clone "${gh_proxy}github.com/kejilion/apps.git"
  else
    cd apps || return 1
    timeout 10s git pull "${gh_proxy}github.com/kejilion/apps.git" main >/dev/null 2>&1
  fi
}

luopo_app_marketplace_installed_numbers() {
  if [[ -f /home/docker/appno.txt ]]; then
    cat /home/docker/appno.txt
  fi
}

luopo_app_marketplace_is_installed() {
  local number="$1"
  luopo_app_marketplace_installed_numbers | grep -q "^${number}$"
}

luopo_app_marketplace_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_APP_MARKETPLACE_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_app_marketplace_item_label() {
  local item="$1"
  IFS='|' read -r _ label <<<"$item"
  printf '%s\n' "$label"
}

luopo_app_marketplace_item_number() {
  local item="$1"
  IFS='|' read -r number _ <<<"$item"
  printf '%s\n' "$number"
}

luopo_app_marketplace_render_cell() {
  local key="$1"
  local item color label

  item="$(luopo_app_marketplace_find_item "$key")" || return 1
  label="$(luopo_app_marketplace_item_label "$item")"
  color="$gl_bai"
  if [[ "$key" =~ ^[0-9]+$ ]] && luopo_app_marketplace_is_installed "$key"; then
    color="$gl_lv"
  fi
  printf "%b%-4s %b%s%b" "$gl_kjlan" "${key}." "$color" "$label" "$gl_bai"
}

luopo_app_marketplace_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

