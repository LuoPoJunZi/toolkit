#!/usr/bin/env bash
set -euo pipefail

LUOPO_BASIC_TOOLS=(
  curl wget sudo socat htop iftop unzip tar tmux ffmpeg
  btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders
  vim nano git
)

luopo_basic_tools_bootstrap() {
  ensure_luopo_vendor_loaded
}

luopo_basic_tools_finish() {
  break_end
}

luopo_basic_tools_detect_package_manager() {
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v apk >/dev/null 2>&1; then
    echo "apk"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  elif command -v opkg >/dev/null 2>&1; then
    echo "opkg"
  elif command -v pkg >/dev/null 2>&1; then
    echo "pkg"
  else
    echo "unknown"
  fi
}

luopo_basic_tools_print_status_table() {
  local left right
  local i
  for ((i=0; i<${#LUOPO_BASIC_TOOLS[@]}; i+=2)); do
    if command -v "${LUOPO_BASIC_TOOLS[i]}" >/dev/null 2>&1; then
      left=$(printf "已安装 %-12s" "${LUOPO_BASIC_TOOLS[i]}")
    else
      left=$(printf "未安装 %-12s" "${LUOPO_BASIC_TOOLS[i]}")
    fi

    if [[ -n "${LUOPO_BASIC_TOOLS[i+1]:-}" ]]; then
      if command -v "${LUOPO_BASIC_TOOLS[i+1]}" >/dev/null 2>&1; then
        right=$(printf "已安装 %-12s" "${LUOPO_BASIC_TOOLS[i+1]}")
      else
        right=$(printf "未安装 %-12s" "${LUOPO_BASIC_TOOLS[i+1]}")
      fi
      printf "%-32s %s\n" "$left" "$right"
    else
      printf "%s\n" "$left"
    fi
  done
}

luopo_basic_tools_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

luopo_basic_tools_run_shell() {
  local stat_name="$1"
  local command="$2"

  clear
  send_stats "$stat_name"
  set +e
  eval "$command"
  set -e
  luopo_basic_tools_finish
  return 0
}

luopo_basic_tools_install_and_show() {
  local package_name="$1"
  local stat_name="$2"
  local command="$3"
  luopo_basic_tools_run_shell "$stat_name" "install $package_name; clear; $command"
}
