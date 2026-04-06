#!/usr/bin/env bash
set -euo pipefail

is_valid_sha256() {
  local value="$1"
  [[ "$value" =~ ^[A-Fa-f0-9]{64}$ ]]
}

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual
  if ! is_valid_sha256 "$expected"; then
    return 1
  fi
  actual="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]]
}
