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
LuoPoJunZi VPS Toolkit v${version}
命令行输入luo可快速启动脚本
EOF
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

confirm() {
  local prompt_key="$1"
  read -r -p "$(msg "$prompt_key")" ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}
