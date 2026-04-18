#!/usr/bin/env bash
set -euo pipefail

LUOPO_LDNMP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/../menu_layout.sh"
# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/actions.sh"

luopo_render_ldnmp_menu() {
  local row left right
  echo "LDNMP建站"
  luopo_ldnmp_render_status_banner
  echo -e "${gl_huang}------------------------"
  for row in "${LUOPO_LDNMP_LAYOUT[@]}"; do
    if [[ "$row" == "---" ]]; then
      echo -e "${gl_huang}------------------------"
      continue
    fi
    IFS='|' read -r left right <<<"$row"
    if [[ -n "${right:-}" ]]; then
      luopo_print_two_column_cells "$(luopo_ldnmp_render_cell "$left")" "$(luopo_ldnmp_render_cell "$right")" 40
    else
      luopo_ldnmp_render_cell "$left"
      printf '\n'
    fi
  done
  echo -e "${gl_huang}------------------------"
  echo -e "${gl_huang}0.   ${gl_bai}返回主菜单"
  echo -e "${gl_huang}------------------------${gl_bai}"
}

luopo_ldnmp_menu() {
  luopo_ldnmp_bootstrap || return 1
  while true; do
    clear
    luopo_render_ldnmp_menu
    read -r -p "请输入你的选择: " sub_choice
    if ! luopo_ldnmp_dispatch_choice "$sub_choice"; then
      return 0
    fi
  done
}
