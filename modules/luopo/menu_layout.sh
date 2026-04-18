#!/usr/bin/env bash
set -euo pipefail

luopo_strip_ansi() {
  sed -E 's/\x1B\[[0-9;]*[[:alpha:]]//g'
}

luopo_visible_width() {
  local text="$1"
  local plain bytes ascii non_ascii_bytes non_ascii_chars

  plain="$(printf '%b' "$text" | luopo_strip_ansi)"
  bytes="$(printf '%s' "$plain" | LC_ALL=C wc -c | tr -d '[:space:]')"
  ascii="$(printf '%s' "$plain" | LC_ALL=C tr -cd '\000-\177' | wc -c | tr -d '[:space:]')"
  non_ascii_bytes=$((bytes - ascii))
  # Most LuoPo menu labels are CJK UTF-8 text: 3 bytes, 2 terminal cells.
  non_ascii_chars=$(((non_ascii_bytes + 2) / 3))
  printf '%s\n' "$((ascii + non_ascii_chars * 2))"
}

luopo_print_padded_cell() {
  local text="$1"
  local target_width="${2:-42}"
  local width padding

  printf '%b' "$text"
  width="$(luopo_visible_width "$text")"
  padding=$((target_width - width))
  if [[ "$padding" -gt 0 ]]; then
    printf '%*s' "$padding" ''
  fi
}

luopo_print_two_column_cells() {
  local left="$1"
  local right="$2"
  local left_width="${3:-42}"

  luopo_print_padded_cell "$left" "$left_width"
  printf '  '
  printf '%b\n' "$right"
}
