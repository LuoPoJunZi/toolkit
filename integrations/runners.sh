#!/usr/bin/env bash
set -euo pipefail

safe_run_script() {
  local file="$1"
  local manual_confirm="${2:-true}"
  if [[ "$manual_confirm" == "true" ]]; then
    read -r -p "确认执行脚本 $file ? (y/N): " ans
    [[ "$ans" == "y" || "$ans" == "Y" ]] || return 0
  fi
  bash "$file"
}
