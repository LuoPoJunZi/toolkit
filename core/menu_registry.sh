#!/usr/bin/env bash
set -euo pipefail

MENU_ITEMS=(
  "1|menu_label_1|entry_system_info|system_info|press_enter|primary"
  "2|menu_label_2|entry_system_update|system_update|press_enter|primary"
  "3|menu_label_3|entry_system_cleanup|system_cleanup|press_enter|primary"
  "4|menu_label_4|entry_scripts_hub|scripts_hub|none|primary"
  "5|menu_label_5|entry_basic_tools|basic_tools_menu|none|primary"
  "6|menu_label_6|entry_bbr_management|bbr_management_menu|none|primary"
  "7|menu_label_7|entry_docker_management|docker_management_menu|none|primary"
  "8|menu_label_8|entry_warp_management|luopo_warp_management_menu|none|primary"
  "9|menu_label_9|entry_network_test_suite|network_test_suite_menu|none|primary"
  "10|menu_label_10|entry_oracle_cloud_suite|oracle_cloud_suite_menu|none|primary"
  "11|menu_label_11|entry_ldnmp_site_suite|ldnmp_site_suite_menu|none|primary"
  "12|menu_label_12|entry_app_marketplace|luopo_app_marketplace_menu|none|primary"
  "13|menu_label_13|entry_workspace_suite|workspace_suite_menu|none|primary"
  "14|menu_label_14|entry_system_tools_suite|system_tools_suite_menu|none|primary"
  "15|menu_label_15|entry_cluster_control_suite|cluster_control_suite_menu|none|primary"
  "99|menu_label_99|entry_self_update|self_update|press_enter|secondary"
  "88|menu_label_88|entry_uninstall|uninstall_toolkit|none|secondary"
  "0|menu_label_0|entry_exit|entry_exit|none|secondary"
)

find_menu_item() {
  local choice="$1"
  local item
  for item in "${MENU_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

menu_item_number() {
  local item="$1"
  IFS='|' read -r number _ <<<"$item"
  printf '%s\n' "$number"
}

menu_item_label_key() {
  local item="$1"
  IFS='|' read -r _ label_key _ <<<"$item"
  printf '%s\n' "$label_key"
}

menu_item_handler() {
  local item="$1"
  IFS='|' read -r _ _ handler _ <<<"$item"
  printf '%s\n' "$handler"
}

menu_item_action_name() {
  local item="$1"
  IFS='|' read -r _ _ _ action_name _ <<<"$item"
  printf '%s\n' "$action_name"
}

menu_item_pause_mode() {
  local item="$1"
  IFS='|' read -r _ _ _ _ pause_mode _ <<<"$item"
  printf '%s\n' "$pause_mode"
}

menu_item_group() {
  local item="$1"
  IFS='|' read -r _ _ _ _ _ group <<<"$item"
  printf '%s\n' "$group"
}

