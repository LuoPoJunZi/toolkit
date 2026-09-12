#!/usr/bin/env bash
set -euo pipefail

entry_system_update() {
  entry_run_module "$ROOT_DIR/modules/system_update.sh" system_update
}
