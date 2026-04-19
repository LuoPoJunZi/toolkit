#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_NETWORK_SECURITY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/network_security"

# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_NETWORK_SECURITY_DIR/dns_search_speed.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_NETWORK_SECURITY_DIR/cert_remote_access.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_NETWORK_SECURITY_DIR/tunnels.sh"
