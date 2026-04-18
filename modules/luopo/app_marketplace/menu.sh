#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_DIR/../menu_layout.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_DIR/actions.sh"

luopo_render_app_marketplace_menu() {
  echo "应用市场"
  echo -e "${gl_kjlan}-------------------------${gl_bai}"

  local row left right
  for row in "${LUOPO_APP_MARKETPLACE_LAYOUT[@]}"; do
    if [[ "$row" == "---" ]]; then
      echo -e "${gl_kjlan}-------------------------${gl_bai}"
      continue
    fi

    IFS='|' read -r left right <<<"$row"
    if [[ -n "${right:-}" ]]; then
      luopo_print_two_column_cells "$(luopo_app_marketplace_render_cell "$left")" "$(luopo_app_marketplace_render_cell "$right")" 44
    else
      luopo_app_marketplace_render_cell "$left"
      echo
    fi
  done

  echo -e "${gl_kjlan}-------------------------${gl_bai}"
  luopo_print_two_column_cells "$(luopo_app_marketplace_render_cell "b")" "$(luopo_app_marketplace_render_cell "r")" 44
  echo -e "${gl_kjlan}------------------------${gl_bai}"
  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
  echo -e "${gl_kjlan}------------------------${gl_bai}"
}

luopo_app_marketplace_menu() {
  luopo_app_marketplace_bootstrap || return 1
  luopo_app_marketplace_sync_index || return 1

  while true; do
    clear
    luopo_render_app_marketplace_menu
    read -r -p "请输入你的选择: " sub_choice
    if ! luopo_app_marketplace_dispatch_choice "$sub_choice"; then
      return 0
    fi
  done
}
