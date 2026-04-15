#!/usr/bin/env bash
set -euo pipefail

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
