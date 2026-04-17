#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_SYSTEM_TOOLS_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/compat/common.sh"

luopo_system_tools_run_vendor_function() {
  local fn="$1"
  shift || true

  bash -lc '
    ROOT_DIR="$1"
    fn="$2"
    shift 2
    source "$ROOT_DIR/modules/compat/common.sh"
    ensure_luopo_vendor_loaded || exit 1
    cd ~ || exit 1
    "$fn" "$@"
  ' _ "$ROOT_DIR" "$fn" "$@"
}

switch_mirror() { luopo_system_tools_run_vendor_function switch_mirror "$@"; }
dd_xitong() { luopo_system_tools_run_vendor_function dd_xitong "$@"; }
elrepo() { luopo_system_tools_run_vendor_function elrepo "$@"; }
Kernel_optimize() { luopo_system_tools_run_vendor_function Kernel_optimize "$@"; }
clamav() { luopo_system_tools_run_vendor_function clamav "$@"; }
linux_language() { luopo_system_tools_run_vendor_function linux_language "$@"; }
shell_bianse() { luopo_system_tools_run_vendor_function shell_bianse "$@"; }
linux_file() { luopo_system_tools_run_vendor_function linux_file "$@"; }
linux_trash() { luopo_system_tools_run_vendor_function linux_trash "$@"; }
linux_backup() { luopo_system_tools_run_vendor_function linux_backup "$@"; }
ssh_manager() { luopo_system_tools_run_vendor_function ssh_manager "$@"; }
disk_manager() { luopo_system_tools_run_vendor_function disk_manager "$@"; }
rsync_manager() { luopo_system_tools_run_vendor_function rsync_manager "$@"; }
linux_fav() { luopo_system_tools_run_vendor_function linux_fav "$@"; }
net_menu() { luopo_system_tools_run_vendor_function net_menu "$@"; }
log_menu() { luopo_system_tools_run_vendor_function log_menu "$@"; }
env_menu() { luopo_system_tools_run_vendor_function env_menu "$@"; }
