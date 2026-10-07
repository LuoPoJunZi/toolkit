#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

luopo_app_marketplace_load_native_apps() {
  if declare -F luopo_app_marketplace_native_docker_app_menu >/dev/null; then
    return 0
  fi

  # shellcheck disable=SC1091
  if ! source "$LUOPO_APP_MARKETPLACE_DIR/native_apps.sh"; then
    echo "应用功能模块加载失败。"
    return 1
  fi
  if ! declare -F luopo_app_marketplace_native_docker_app_menu >/dev/null; then
    echo "应用功能入口未定义。"
    return 1
  fi
}

luopo_app_marketplace_backup_all() {
  local data_dir backup_dir backup_file temporary_file timestamp
  data_dir="${LUOPO_APP_MARKETPLACE_STATE_FILE%/*}"
  backup_dir="$(dirname "$data_dir")"

  if [[ ! -d "$data_dir" ]]; then
    echo "未检测到 $data_dir，暂无应用数据可备份。"
    return 0
  fi

  timestamp="$(date +%Y%m%d%H%M%S)"
  temporary_file="$(mktemp "$backup_dir/.luopo-app-market-${timestamp}.XXXXXX")" || return 1
  backup_file="$backup_dir/luopo-app-market-${timestamp}-${temporary_file##*.}.tar.gz"
  echo "正在备份应用市场数据..."
  if ! tar -czf "$temporary_file" -C "$backup_dir" "$(basename "$data_dir")" || ! mv -- "$temporary_file" "$backup_file"; then
    rm -f -- "$temporary_file"
    echo "备份失败，未保存不完整的备份文件。"
    return 1
  fi
  echo "备份完成: $backup_file"
}

luopo_app_marketplace_restore_all() {
  local backup_file confirm data_dir backup_dir
  data_dir="${LUOPO_APP_MARKETPLACE_STATE_FILE%/*}"
  backup_dir="$(dirname "$data_dir")"
  echo "可用备份文件:"
  luopo_ldnmp_list_files_by_mtime "$backup_dir" 'luopo-app-market-*.tar.gz'
  echo

  read -r -p "回车还原最新备份，输入备份文件路径/文件名还原指定备份，输入0取消: " backup_file || return 0
  [[ "$backup_file" == "0" ]] && return 0

  if [[ -z "$backup_file" ]]; then
    backup_file="$(luopo_ldnmp_latest_file "$backup_dir" 'luopo-app-market-*.tar.gz' || true)"
  elif [[ "$backup_file" != /* ]]; then
    backup_file="$backup_dir/$backup_file"
  fi

  if [[ -z "$backup_file" || ! -f "$backup_file" ]]; then
    echo "未找到备份文件。"
    return 0
  fi

  read -r -p "还原会覆盖 $data_dir 中同名数据，确认继续？(Y/N): " confirm || return 0
  case "$confirm" in
    [Yy])
      if ! tar -tzf "$backup_file" >/dev/null; then
        echo "备份文件不可读取或不完整，未执行还原。"
        return 1
      fi
      if ! tar -xzf "$backup_file" -C "$backup_dir"; then
        echo "还原失败，可能已有部分文件写入，请检查上方错误信息。"
        return 1
      fi
      LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY=0
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
    b | 91)
      luopo_app_marketplace_backup_all
      return 0
      ;;
    r | 92)
      luopo_app_marketplace_restore_all
      return 0
      ;;
  esac

  if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
    luopo_app_marketplace_invalid_choice
    return 0
  fi
  if [[ "$LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY" != "1" ]]; then
    luopo_app_marketplace_refresh_render_cache
  fi
  if [[ -z "${LUOPO_APP_MARKETPLACE_LABELS[$choice]:-}" ]]; then
    luopo_app_marketplace_invalid_choice
    return 0
  fi
  luopo_app_marketplace_load_native_apps || return 0

  case "$choice" in
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
      luopo_app_marketplace_uptime_kuma_menu
      return 0
      ;;
    10)
      luopo_app_marketplace_beszel_menu
      return 0
      ;;
    11)
      luopo_app_marketplace_komari_menu
      return 0
      ;;
    12)
      luopo_app_marketplace_openlist_menu
      return 0
      ;;
    13)
      luopo_app_marketplace_filebrowser_menu
      return 0
      ;;
    14)
      luopo_app_marketplace_dufs_menu
      return 0
      ;;
    15)
      luopo_app_marketplace_syncthing_menu
      return 0
      ;;
    16)
      luopo_app_marketplace_paperless_menu
      return 0
      ;;
    17)
      luopo_app_marketplace_immich_menu
      return 0
      ;;
    18)
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
    *)
      luopo_app_marketplace_invalid_choice
      return 0
      ;;
  esac
}
