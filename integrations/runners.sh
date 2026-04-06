#!/usr/bin/env bash
set -euo pipefail

safe_run_script() {
  local file="$1"
  bash "$file"
}
