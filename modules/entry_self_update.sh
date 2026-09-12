#!/usr/bin/env bash
set -euo pipefail

entry_self_update() {
  entry_run_module "$ROOT_DIR/core/self_update.sh" self_update
}
