#!/usr/bin/env bash
set -euo pipefail

entry_system_info() {
  entry_run_module "$ROOT_DIR/modules/system_info.sh" show_system_info
}
