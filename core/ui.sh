#!/usr/bin/env bash
set -euo pipefail

get_toolkit_version() {
  local base_dir version_file
  base_dir="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  version_file="$base_dir/VERSION"
  if [[ -f "$version_file" ]]; then
    tr -d '[:space:]' <"$version_file"
    return
  fi
  echo "dev"
}

render_banner() {
  local version
  version="$(get_toolkit_version)"
  cat <<EOF
LuoPo VPS Toolkit v${version}
命令行输入z可快速启动脚本
EOF
}

supports_color() {
  [[ -t 1 ]] || return 1
  command -v tput >/dev/null 2>&1 || return 1
  [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]
}

color_text() {
  local color="$1"
  shift
  local text="$*"
  if supports_color; then
    printf '\033[%sm%s\033[0m' "$color" "$text"
    return
  fi
  printf '%s' "$text"
}

msg() {
  local key="$1"
  shift || true
  local value="${I18N[$key]:-}"
  if [[ -z "$value" ]]; then
    echo "$key $*"
    return
  fi
  printf '%s\n' "$(printf "$value" "$@")"
}

press_enter() {
  read -r -p "$(msg prompt_press_enter)" _
}

read_menu_choice() {
  local __var_name="$1"
  local __prompt="${2:-$(msg prompt_select)}"
  local __input
  read -r -p "$__prompt" __input
  printf -v "$__var_name" '%s' "$__input"
}

is_yes() {
  local ans="${1:-}"
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

confirm() {
  local prompt_key="$1"
  read -r -p "$(msg "$prompt_key")" ans
  is_yes "$ans"
}

# Unified single-column menu item renderer.
# Ensures the first character after "." is vertically aligned.
menu_item() {
  local number="$1"
  shift
  local text="$*"
  printf " %-3s %s\n" "${number}." "$text"
}
