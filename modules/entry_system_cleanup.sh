#!/usr/bin/env bash
set -euo pipefail

entry_system_cleanup() {
  entry_run_module "$ROOT_DIR/modules/system_cleanup.sh" system_cleanup
}
