#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_DIR/native_apps.sh"

luopo_app_marketplace_backup_all() {
  mkdir -p /home
  local backup_file="/home/luopo-app-market-$(date +%Y%m%d%H%M%S).tar.gz"

  if [[ ! -d /home/docker ]]; then
    echo "未检测到 /home/docker，暂无应用数据可备份。"
    return 0
  fi

  echo "正在备份应用市场数据..."
  tar -czf "$backup_file" -C /home docker
  echo "备份完成: $backup_file"
}

luopo_app_marketplace_restore_all() {
  echo "可用备份文件:"
  ls -lt /home/luopo-app-market-*.tar.gz 2>/dev/null | awk '{print $NF}' || true
  echo

  local backup_file
  read -r -p "回车还原最新备份，输入备份文件路径/文件名还原指定备份，输入0取消: " backup_file
  [[ "$backup_file" == "0" ]] && return 0

  if [[ -z "$backup_file" ]]; then
    backup_file="$(ls -t /home/luopo-app-market-*.tar.gz 2>/dev/null | head -1)"
  elif [[ "$backup_file" != /* ]]; then
    backup_file="/home/$backup_file"
  fi

  if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
    echo "未找到备份文件。"
    return 0
  fi

  read -r -p "还原会覆盖 /home/docker 中同名数据，确认继续？(y/N): " confirm
  case "$confirm" in
    [Yy])
      mkdir -p /home
      tar -xzf "$backup_file" -C /home
      echo "还原完成: $backup_file"
      ;;
    *)
      echo "已取消"
      ;;
  esac
}

luopo_app_marketplace_dispatch_choice() {
  local choice="$1"

  case "$choice" in
    0)
      return 1
      ;;
    b)
      luopo_app_marketplace_backup_all
      return 0
      ;;
    r)
      luopo_app_marketplace_restore_all
      return 0
      ;;
    20)
      luopo_app_marketplace_portainer_menu
      return 0
      ;;
    22)
      luopo_app_marketplace_uptime_kuma_menu
      return 0
      ;;
    23)
      luopo_app_marketplace_memos_menu
      return 0
      ;;
    28)
      luopo_app_marketplace_librespeed_menu
      return 0
      ;;
    29)
      luopo_app_marketplace_searxng_menu
      return 0
      ;;
    31)
      luopo_app_marketplace_stirling_pdf_menu
      return 0
      ;;
    32)
      luopo_app_marketplace_drawio_menu
      return 0
      ;;
    64)
      luopo_app_marketplace_it_tools_menu
      return 0
      ;;
    67)
      luopo_app_marketplace_ddns_go_menu
      return 0
      ;;
    71)
      luopo_app_marketplace_navidrome_menu
      return 0
      ;;
    79)
      luopo_app_marketplace_beszel_menu
      return 0
      ;;
    83)
      luopo_app_marketplace_komari_menu
      return 0
      ;;
    86)
      luopo_app_marketplace_jellyfin_menu
      return 0
      ;;
    92)
      luopo_app_marketplace_filebrowser_menu
      return 0
      ;;
    93)
      luopo_app_marketplace_dufs_menu
      return 0
      ;;
    100)
      luopo_app_marketplace_syncthing_menu
      return 0
      ;;
    109)
      luopo_app_marketplace_zfile_menu
      return 0
      ;;
  esac

  if [[ "$choice" =~ ^[0-9]+$ ]] && luopo_app_marketplace_find_item "$choice" >/dev/null; then
    run_luopo_compat_menu linux_panel "$choice"
    return 0
  fi

  luopo_app_marketplace_invalid_choice
  return 0
}

