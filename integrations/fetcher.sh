#!/usr/bin/env bash
set -euo pipefail

fetch_script_to_cache() {
  local url="$1"
  local out="$2"
  curl -fsSL "$url" -o "$out"
}
