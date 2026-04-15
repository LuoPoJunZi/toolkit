#!/usr/bin/env bash
set -euo pipefail

luopo_warp_launch_menu() {
  clear
  send_stats "warp管理"
  install wget
  set +e
  wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
  bash menu.sh [option] [lisence/url/token]
  set -e
  luopo_warp_finish
}

