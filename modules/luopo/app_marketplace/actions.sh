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
    b|91)
      luopo_app_marketplace_backup_all
      return 0
      ;;
    r|92)
      luopo_app_marketplace_restore_all
      return 0
      ;;
    1)
      luopo_app_marketplace_onepanel_menu
      return 0
      ;;
    2)
      luopo_app_marketplace_npm_menu
      return 0
      ;;
    3)
      luopo_app_marketplace_nezha_menu
      return 0
      ;;
    4)
      luopo_app_marketplace_qinglong_menu
      return 0
      ;;
    5)
      luopo_app_marketplace_safeline_menu
      return 0
      ;;
    6)
      luopo_app_marketplace_portainer_menu
      return 0
      ;;
    7)
      luopo_app_marketplace_dockge_menu
      return 0
      ;;
    8)
      luopo_app_marketplace_vscode_menu
      return 0
      ;;
    9)
      luopo_app_marketplace_beszel_menu
      return 0
      ;;
    10)
      luopo_app_marketplace_komari_menu
      return 0
      ;;
    11)
      luopo_app_marketplace_openlist_menu
      return 0
      ;;
    12)
      luopo_app_marketplace_filebrowser_menu
      return 0
      ;;
    13)
      luopo_app_marketplace_dufs_menu
      return 0
      ;;
    14)
      luopo_app_marketplace_syncthing_menu
      return 0
      ;;
    15)
      luopo_app_marketplace_paperless_menu
      return 0
      ;;
    16)
      luopo_app_marketplace_immich_menu
      return 0
      ;;
    17)
      luopo_app_marketplace_zfile_menu
      return 0
      ;;
    21)
      luopo_app_marketplace_adguardhome_menu
      return 0
      ;;
    22)
      luopo_app_marketplace_searxng_menu
      return 0
      ;;
    23)
      luopo_app_marketplace_myip_menu
      return 0
      ;;
    24)
      luopo_app_marketplace_rustdesk_hbbs_menu
      return 0
      ;;
    25)
      luopo_app_marketplace_rustdesk_hbbr_menu
      return 0
      ;;
    26)
      luopo_app_marketplace_frps_menu
      return 0
      ;;
    27)
      luopo_app_marketplace_frpc_menu
      return 0
      ;;
    28)
      luopo_app_marketplace_ddns_go_menu
      return 0
      ;;
    29)
      luopo_app_marketplace_allinssl_menu
      return 0
      ;;
    30)
      luopo_app_marketplace_bitwarden_menu
      return 0
      ;;
    31)
      luopo_app_marketplace_lucky_menu
      return 0
      ;;
    41)
      luopo_app_marketplace_dify_menu
      return 0
      ;;
    42)
      luopo_app_marketplace_newapi_menu
      return 0
      ;;
    43)
      luopo_app_marketplace_openwebui_menu
      return 0
      ;;
    44)
      luopo_app_marketplace_n8n_menu
      return 0
      ;;
    45)
      luopo_app_marketplace_gpt_load_menu
      return 0
      ;;
    51)
      luopo_app_marketplace_navidrome_menu
      return 0
      ;;
    52)
      luopo_app_marketplace_jellyfin_menu
      return 0
      ;;
    61)
      luopo_app_marketplace_memos_menu
      return 0
      ;;
    62)
      luopo_app_marketplace_linkwarden_menu
      return 0
      ;;
    63)
      luopo_app_marketplace_umami_menu
      return 0
      ;;
    64)
      luopo_app_marketplace_siyuan_menu
      return 0
      ;;
    65)
      luopo_app_marketplace_karakeep_menu
      return 0
      ;;
    66)
      luopo_app_marketplace_it_tools_menu
      return 0
      ;;
    67)
      luopo_app_marketplace_stirling_pdf_menu
      return 0
      ;;
    68)
      luopo_app_marketplace_drawio_menu
      return 0
      ;;
    69)
      luopo_app_marketplace_librespeed_menu
      return 0
      ;;
    71)
      luopo_app_marketplace_gitea_menu
      return 0
      ;;
  esac

  luopo_app_marketplace_invalid_choice
  return 0
}
