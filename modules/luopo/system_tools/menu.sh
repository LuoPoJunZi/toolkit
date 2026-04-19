#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_DIR/registry.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_DIR/actions.sh"

luopo_render_system_tools_menu() {
  echo "========================================"
  echo "系统工具"
  echo "========================================"

  local row left title
  for row in "${LUOPO_SYSTEM_TOOLS_LAYOUT[@]}"; do
    if [[ "$row" == "---" ]]; then
      echo -e "${gl_kjlan}----------------------------------------${gl_bai}"
      continue
    fi
    if [[ "$row" == "##|"* ]]; then
      IFS='|' read -r _ title <<<"$row"
      echo -e "${gl_kjlan}[ ${title} ]${gl_bai}"
      continue
    fi

    IFS='|' read -r left _ <<<"$row"
    luopo_system_tools_render_cell "$left"
    printf '\n'
  done

  echo -e "${gl_kjlan}----------------------------------------${gl_bai}"
  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
  echo "========================================"
}

luopo_system_tools_menu() {
  luopo_system_tools_bootstrap || return 1

  while true; do
    clear
    luopo_render_system_tools_menu
    read -r -p "请输入你的选择: " sub_choice
    if ! luopo_system_tools_dispatch_choice "$sub_choice"; then
      return 0
    fi
  done
}
