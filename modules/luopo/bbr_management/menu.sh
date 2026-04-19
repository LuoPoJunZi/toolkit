#!/usr/bin/env bash
set -euo pipefail

LUOPO_BBR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_BBR_DIR/helpers.sh"
# shellcheck disable=SC1091
source "$LUOPO_BBR_DIR/actions.sh"

luopo_bbr_management_menu() {
  luopo_bbr_bootstrap || return 1

  if [[ ! -f /etc/alpine-release ]]; then
    luopo_bbr_run_external_suite
    return 0
  fi

  while true; do
    clear
    echo "========================================"
    echo "BBR管理"
    echo "========================================"
    echo "[ 当前状态 ]"
    echo "当前TCP阻塞算法: $(luopo_bbr_current_algorithms)"
    echo "----------------------------------------"
    echo "[ BBRv3 管理 ]"
    echo " 1.  开启BBRv3"
    echo " 2.  关闭BBRv3（会重启）"
    echo "----------------------------------------"
    echo " 0.  返回主菜单"
    echo "========================================"
    read -r -p "请输入你的选择: " sub_choice

    case "$sub_choice" in
      1)
        luopo_bbr_enable_alpine
        ;;
      2)
        luopo_bbr_disable_alpine
        ;;
      0)
        return 0
        ;;
      *)
        luopo_bbr_invalid_choice
        ;;
    esac
  done
}
