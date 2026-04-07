#!/usr/bin/env bash
set -euo pipefail

MODULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Common helpers
# shellcheck disable=SC1091
source "$MODULES_DIR/_common.sh"

# Menu groups 6~18
# shellcheck disable=SC1091
source "$MODULES_DIR/network_accel.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/network_test.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/security.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/ldnmp.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/app_market.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/workspace.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/system_tools.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/backup.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/cron_center.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/cluster.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/oracle_cloud.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/game_server.sh"
# shellcheck disable=SC1091
source "$MODULES_DIR/ai_workspace.sh"
