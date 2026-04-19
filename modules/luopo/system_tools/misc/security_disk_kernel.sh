#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_SECURITY_DISK_KERNEL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/security_disk_kernel"

# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_SECURITY_DISK_KERNEL_DIR/clamav.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_SECURITY_DISK_KERNEL_DIR/disk_manager.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_SECURITY_DISK_KERNEL_DIR/reinstall_kernel.sh"
