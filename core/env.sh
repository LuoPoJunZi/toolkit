#!/usr/bin/env bash
set -euo pipefail

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "Please run as root"
    exit 1
  fi
}

detect_os() {
  if [[ ! -f /etc/os-release ]]; then
    echo "unsupported"
    return 1
  fi
  . /etc/os-release
  case "${ID:-}" in
    ubuntu|debian)
      echo "$ID"
      ;;
    *)
      echo "unsupported"
      return 1
      ;;
  esac
}
