#!/usr/bin/env bash
set -euo pipefail

LUOPO_LDNMP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/actions_sites.sh"
# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/actions_proxy.sh"
# shellcheck disable=SC1091
source "$LUOPO_LDNMP_DIR/actions_maintenance.sh"

luopo_ldnmp_dispatch_choice() {
  local choice="$1"
  case "$choice" in
    0) return 1 ;;
    1) luopo_ldnmp_install_all ;;
    2) luopo_ldnmp_install_wordpress ;;
    3) luopo_ldnmp_install_discuz ;;
    4) luopo_ldnmp_install_kodbox ;;
    5) luopo_ldnmp_install_maccms ;;
    6) luopo_ldnmp_install_dujiaoka ;;
    7) luopo_ldnmp_install_flarum ;;
    8) luopo_ldnmp_install_typecho ;;
    9) luopo_ldnmp_install_linkstack ;;
    20) luopo_ldnmp_custom_dynamic_site ;;
    21) luopo_ldnmp_install_nginx_only ;;
    22) luopo_ldnmp_redirect_site ;;
    23) luopo_ldnmp_reverse_proxy_ip_port ;;
    24) luopo_ldnmp_reverse_proxy_domain ;;
    25) luopo_ldnmp_install_bitwarden ;;
    26) luopo_ldnmp_install_halo ;;
    27) luopo_ldnmp_install_ai_prompt_generator ;;
    28) luopo_ldnmp_reverse_proxy_load_balance ;;
    29) luopo_ldnmp_stream_proxy ;;
    30) luopo_ldnmp_custom_static_site ;;
    31) luopo_ldnmp_site_status ;;
    32) luopo_ldnmp_backup_all ;;
    33) luopo_ldnmp_scheduled_remote_backup ;;
    34) luopo_ldnmp_restore_all ;;
    35) luopo_ldnmp_security ;;
    36) luopo_ldnmp_optimization ;;
    37) luopo_ldnmp_update_menu ;;
    38) luopo_ldnmp_uninstall ;;
    *)
      luopo_ldnmp_invalid_choice
      ;;
  esac
  return 0
}

