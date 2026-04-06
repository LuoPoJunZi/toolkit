#!/usr/bin/env bash
set -euo pipefail

system_cleanup() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get autoremove -y && apt-get autoclean -y
  else
    echo "Unsupported package manager"
    return 1
  fi
}
