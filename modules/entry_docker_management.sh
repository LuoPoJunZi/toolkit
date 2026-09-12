#!/usr/bin/env bash
set -euo pipefail

entry_docker_management() {
  entry_run_module "$ROOT_DIR/modules/luopo/docker/manager.sh" docker_manager
}
