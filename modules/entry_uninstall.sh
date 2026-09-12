#!/usr/bin/env bash
set -euo pipefail

entry_uninstall() {
  entry_run_module "$ROOT_DIR/core/uninstall.sh" uninstall_toolkit
}
