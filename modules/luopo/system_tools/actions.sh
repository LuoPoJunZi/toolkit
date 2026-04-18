#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_SYSTEM_TOOLS_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/bbr_management/menu.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_DIR/actions_access.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_DIR/actions_operations.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_DIR/actions_misc.sh"

luopo_system_tools_dispatch_choice() {
  local choice="$1"
  case "$choice" in
    0) return 1 ;;
    1) luopo_system_tools_set_shortcut ;;
    2) luopo_system_tools_change_login_password ;;
    3) add_sshpasswd ;;
    4) luopo_system_tools_python_version_menu ;;
    6) luopo_system_tools_modify_ssh_port_menu ;;
    9) luopo_system_tools_disable_root_create_user ;;
    10) luopo_system_tools_network_priority_menu ;;
    11) luopo_system_tools_show_ports ;;
    13) luopo_system_tools_user_management_menu ;;
    18) luopo_system_tools_change_hostname_menu ;;
    19) luopo_system_tools_switch_mirror_menu ;;
    20) luopo_system_tools_crontab_menu ;;
    21) luopo_system_tools_hosts_menu ;;
    22) luopo_system_tools_fail2ban_menu ;;
    23) luopo_system_tools_traffic_shutdown_menu ;;
    5) luopo_system_tools_open_all_ports ;;
    7) luopo_system_tools_dns_menu ;;
    8) luopo_system_tools_reinstall_menu ;;
    12) luopo_system_tools_swap_menu ;;
    14) luopo_system_tools_generate_credentials ;;
    15) luopo_system_tools_timezone_menu ;;
    16) luopo_bbr_management_menu ;;
    17) luopo_system_tools_iptables_menu ;;
    24) luopo_system_tools_sshkey_menu ;;
    25) luopo_system_tools_tg_monitor_menu ;;
    26) luopo_system_tools_fix_openssh ;;
    27) luopo_system_tools_elrepo_menu ;;
    28) luopo_system_tools_kernel_optimize_menu ;;
    29) luopo_system_tools_clamav_menu ;;
    31) luopo_system_tools_language_menu ;;
    32) luopo_system_tools_shell_theme_menu ;;
    30) luopo_system_tools_file_menu ;;
    33) luopo_system_tools_trash_menu ;;
    34) luopo_system_tools_backup_menu ;;
    35) luopo_system_tools_ssh_manager_menu ;;
    36) luopo_system_tools_disk_manager_menu ;;
    37) luopo_system_tools_history_menu ;;
    38) luopo_system_tools_rsync_menu ;;
    39) luopo_system_tools_command_favorites ;;
    40) luopo_system_tools_network_card_menu ;;
    41) luopo_system_tools_log_menu ;;
    42) luopo_system_tools_env_menu ;;
    61) luopo_system_tools_feedback ;;
    62) luopo_system_tools_one_click_tune ;;
    63) server_reboot ;;
    64) luopo_system_tools_privacy_menu ;;
    65) luopo_system_tools_command_help ;;
    66) luopo_system_tools_uninstall_menu ;;
    *) luopo_system_tools_invalid_choice ;;
  esac
  return 0
}

