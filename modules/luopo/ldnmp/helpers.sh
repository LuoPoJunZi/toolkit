#!/usr/bin/env bash
set -euo pipefail

LUOPO_LDNMP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_LDNMP_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/compat/common.sh"

luopo_ldnmp_bootstrap() {
  ensure_luopo_vendor_loaded
}

luopo_ldnmp_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_LDNMP_ITEMS[@]}"; do
    IFS='|' read -r number _ _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_ldnmp_item_label() {
  local item="$1"
  IFS='|' read -r _ label _ <<<"$item"
  printf '%s\n' "$label"
}

luopo_ldnmp_render_cell() {
  local key="$1"
  local item label
  item="$(luopo_ldnmp_find_item "$key")" || return 1
  label="$(luopo_ldnmp_item_label "$item")"
  printf "%b%-4s %b%s%b" "$gl_huang" "${key}." "$gl_bai" "$label" "$gl_bai"
}

luopo_ldnmp_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

