#!/usr/bin/env bash
set -euo pipefail

system_update() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y && apt-get upgrade -y
  else
    echo "Unsupported package manager"
    return 1
  fi
}
