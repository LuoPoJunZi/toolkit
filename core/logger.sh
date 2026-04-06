#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTION_LOG="$ROOT_DIR/logs/action.log"
ERROR_LOG="$ROOT_DIR/logs/error.log"

mkdir -p "$(dirname "$ACTION_LOG")"

log_action() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >>"$ACTION_LOG"
}

log_error() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >>"$ERROR_LOG"
}
