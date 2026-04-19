#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_SYNC_REMOTE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync_remote"

# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_SYNC_REMOTE_DIR/rsync_tasks.sh"
# shellcheck disable=SC1091
source "$LUOPO_SYSTEM_TOOLS_SYNC_REMOTE_DIR/ssh_manager.sh"
