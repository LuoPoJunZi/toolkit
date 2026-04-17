#!/usr/bin/env bash
set -euo pipefail

luopo_oracle_cloud_bootstrap() {
  return 0
}

luopo_oracle_cloud_finish() {
  break_end
}

luopo_oracle_cloud_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

luopo_oracle_cloud_run_shell() {
  local stat_name="$1"
  local command="$2"

  clear
  send_stats "$stat_name"
  set +e
  eval "$command"
  set -e
  luopo_oracle_cloud_finish
  return 0
}

luopo_oracle_cloud_confirm() {
  local prompt="$1"
  read -r -p "$prompt" choice
  [[ "$choice" == "Y" || "$choice" == "y" ]]
}
