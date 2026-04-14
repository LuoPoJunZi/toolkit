#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUOPO_VENDOR_FILE="$ROOT_DIR/vendor/luopo.sh"
LUOPO_COMPAT_LOADED="${LUOPO_COMPAT_LOADED:-0}"

ensure_luopo_vendor_loaded() {
  if [[ "$LUOPO_COMPAT_LOADED" == "1" ]]; then
    return 0
  fi
  if [[ ! -f "$LUOPO_VENDOR_FILE" ]]; then
    echo "缺少 luopo 兼容层文件: $LUOPO_VENDOR_FILE"
    return 1
  fi

  export KEJILION_LIBRARY_MODE=1
  # shellcheck disable=SC1090
  source "$LUOPO_VENDOR_FILE"
  export ENABLE_STATS="false"
  LUOPO_COMPAT_LOADED="1"
  export LUOPO_COMPAT_LOADED
}

run_luopo_compat_menu() {
  local fn="$1"
  shift || true

  ensure_luopo_vendor_loaded || return 1

  (
    export KEJILION_LIBRARY_MODE=1
    export ENABLE_STATS="false"
    set +e +u
    cd ~ || exit 1
    "$fn" "$@"
  )
}

basic_tools_menu() {
  run_luopo_compat_menu linux_tools
}

bbr_management_menu() {
  run_luopo_compat_menu linux_bbr
}

docker_management_menu() {
  run_luopo_compat_menu linux_docker
}

warp_management_menu() {
  ensure_luopo_vendor_loaded || return 1

  (
    export KEJILION_LIBRARY_MODE=1
    export ENABLE_STATS="false"
    set +e +u
    cd ~ || exit 1
    clear
    send_stats "warp管理"
    install wget
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
    bash menu.sh [option] [lisence/url/token]
  )
}

network_test_suite_menu() {
  run_luopo_compat_menu linux_test
}

oracle_cloud_suite_menu() {
  run_luopo_compat_menu linux_Oracle
}

ldnmp_site_suite_menu() {
  run_luopo_compat_menu linux_ldnmp
}

app_marketplace_menu() {
  run_luopo_compat_menu linux_panel
}

workspace_suite_menu() {
  run_luopo_compat_menu linux_work
}

system_tools_suite_menu() {
  run_luopo_compat_menu linux_Settings
}

cluster_control_suite_menu() {
  run_luopo_compat_menu linux_cluster
}
