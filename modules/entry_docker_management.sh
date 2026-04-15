#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/docker/manager.sh"

entry_docker_management() {
  docker_manager
}

