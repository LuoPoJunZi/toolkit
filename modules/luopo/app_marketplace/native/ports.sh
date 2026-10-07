#!/usr/bin/env bash
set -euo pipefail

luopo_app_marketplace_native_valid_port() {
  [[ "$1" =~ ^[0-9]{1,5}$ ]] || return 1
  ((10#$1 >= 1 && 10#$1 <= 65535))
}

luopo_app_marketplace_native_app_port_file() {
  printf '%s/%s_port.conf\n' "${LUOPO_APP_MARKETPLACE_STATE_FILE%/*}" "$1"
}

luopo_app_marketplace_native_app_saved_port() {
  local port_file
  port_file="$(luopo_app_marketplace_native_app_port_file "$1")"
  if [[ -f "$port_file" ]]; then
    cat "$port_file"
  fi
}

luopo_app_marketplace_native_app_detect_port() {
  docker port "$1" 2>/dev/null | awk -F: '/->/ && !found {print $NF; found=1}'
}

luopo_app_marketplace_native_app_effective_port() {
  local port
  port="$(luopo_app_marketplace_native_app_saved_port "$1" || true)"
  if ! luopo_app_marketplace_native_valid_port "$port"; then
    port="$(luopo_app_marketplace_native_app_detect_port "$1" || true)"
  fi
  luopo_app_marketplace_native_valid_port "$port" || return 1
  printf '%s\n' "$((10#$port))"
}

luopo_app_marketplace_native_app_store_port() {
  local port="$2" port_file temporary_file
  luopo_app_marketplace_native_valid_port "$port" || return 1
  port_file="$(luopo_app_marketplace_native_app_port_file "$1")"
  mkdir -p "$(dirname "$port_file")" || return 1
  temporary_file="$(mktemp "${port_file}.tmp.XXXXXX")" || return 1
  if ! printf '%s\n' "$((10#$port))" >"$temporary_file" || ! mv -f -- "$temporary_file" "$port_file"; then
    rm -f -- "$temporary_file"
    return 1
  fi
}

luopo_app_marketplace_native_prompt_port() {
  local default_port="$1" selected_port listeners local_address busy
  while true; do
    read -r -p "输入应用对外服务端口，回车默认${default_port}，输入0取消: " selected_port || return 1
    [[ "$selected_port" == 0 ]] && return 1
    selected_port="${selected_port:-$default_port}"
    if ! luopo_app_marketplace_native_valid_port "$selected_port"; then
      printf '端口必须为 1-65535 之间的整数，请重新输入。\n' >&2
      continue
    fi
    selected_port="$((10#$selected_port))"
    busy=0
    if command -v ss >/dev/null 2>&1; then
      if ! listeners="$(ss -H -lntu "sport = :$selected_port" 2>/dev/null)"; then
        printf '无法读取端口占用情况，已取消安装。\n' >&2
        return 1
      fi
      [[ -n "$listeners" ]] && busy=1
    elif command -v netstat >/dev/null 2>&1; then
      if ! listeners="$(netstat -lntu 2>/dev/null)"; then
        printf '无法读取端口占用情况，已取消安装。\n' >&2
        return 1
      fi
      while read -r _ _ _ local_address _; do
        if [[ "${local_address##*:}" == "$selected_port" ]]; then
          busy=1
          break
        fi
      done <<<"$listeners"
    else
      printf '未找到 ss 或 netstat，无法检查端口；请先安装 iproute2 或 net-tools。\n' >&2
      return 1
    fi
    if [[ "$busy" == 1 ]]; then
      # The caller captures stdout as the port, so diagnostics must use stderr.
      printf '端口 %s 已被占用，请更换一个端口。\n' "$selected_port" >&2
      continue
    fi
    printf '%s\n' "$selected_port"
    return 0
  done
}
