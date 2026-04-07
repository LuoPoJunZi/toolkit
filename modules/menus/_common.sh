#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NODES_FILE="${ROOT_DIR}/data/cluster_nodes.txt"

i18n_get() {
  local key="$1"
  local fallback="$2"
  printf '%s' "${I18N[$key]:-$fallback}"
}

say_ok() {
  local prefix
  prefix="$(i18n_get status_ok_prefix '[OK]')"
  printf '%s %s\n' "$prefix" "$*"
}

say_warn() {
  local prefix
  prefix="$(i18n_get status_warn_prefix '[INFO]')"
  printf '%s %s\n' "$prefix" "$*"
}

say_err() {
  local prefix
  prefix="$(i18n_get status_err_prefix '[ERROR]')"
  printf '%s %s\n' "$prefix" "$*"
}

say_action_failed() {
  local action="$1"
  local reason="$2"
  local fmt
  fmt="$(i18n_get msg_action_failed_fmt '%s failed: %s')"
  say_err "$(printf "$fmt" "$action" "$reason")"
}

menu_wait() {
  echo ""
  press_enter
}

menu_invalid() {
  msg invalid
  menu_wait
}

confirm_or_cancel() {
  local prompt="${1:-$(msg prompt_confirm)}"
  local ans
  read -r -p "$prompt" ans
  if is_yes "$ans"; then
    return 0
  fi
  say_warn "$(i18n_get msg_cancelled 'Cancelled')"
  return 1
}

apt_install() {
  if ! command -v apt-get >/dev/null 2>&1; then
    return 1
  fi
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

apt_install_quiet() {
  if ! command -v apt-get >/dev/null 2>&1; then
    return 1
  fi
  apt-get update -y >/dev/null 2>&1 || true
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" >/dev/null 2>&1 || true
}

apt_upgrade_only() {
  if ! command -v apt-get >/dev/null 2>&1; then
    return 1
  fi
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install --only-upgrade -y "$@"
}

run_logged() {
  local action="$1"
  shift
  log_action "${action}:start"
  if "$@"; then
    log_action "${action}:ok"
    return 0
  fi
  log_error "${action}:failed"
  return 1
}

run_or_report() {
  local action="$1"
  shift
  if "$@"; then
    return 0
  fi
  say_action_failed "$action" "$(i18n_get msg_reason_exec_failed 'execution failed')"
  return 1
}

docker_ensure_container() {
  local name="$1"
  local success_msg="$2"
  local action_name="$3"
  shift 3

  if docker ps --format '{{.Names}}' | grep -qx "$name"; then
    say_ok "$success_msg"
    return 0
  fi

  if docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
    if docker start "$name" >/dev/null 2>&1; then
      say_ok "$success_msg"
      return 0
    fi
    say_action_failed "$action_name" "$(i18n_get msg_reason_exec_failed 'execution failed')"
    return 1
  fi

  if docker run "$@" >/dev/null 2>&1; then
    say_ok "$success_msg"
    return 0
  fi

  say_action_failed "$action_name" "$(i18n_get msg_reason_exec_failed 'execution failed')"
  return 1
}

try_install_pkg() {
  local pkg="$1"
  if command -v "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  apt_install_quiet "$pkg"
}

ensure_docker_ready() {
  if command -v docker >/dev/null 2>&1; then
    return 0
  fi
  say_warn "Docker 未安装，正在自动安装..."
  apt_install_quiet docker.io
  systemctl enable --now docker >/dev/null 2>&1 || true
  if ! command -v docker >/dev/null 2>&1; then
    say_action_failed "Docker" "$(i18n_get msg_reason_install_failed 'install failed')"
    return 1
  fi
  return 0
}

ensure_docker_compose() {
  ensure_docker_ready || return 1
  if docker compose version >/dev/null 2>&1; then
    return 0
  fi
  say_warn "Docker Compose 插件未安装，正在自动安装..."
  if ! apt_install docker-compose-plugin; then
    say_action_failed "Docker Compose 插件安装" "$(i18n_get msg_reason_install_failed 'install failed')"
    return 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    say_action_failed "Docker Compose" "$(i18n_get msg_reason_exec_failed 'execution failed')"
    return 1
  fi
  return 0
}

ensure_cluster_nodes_file() {
  mkdir -p "$(dirname "$CLUSTER_NODES_FILE")"
  touch "$CLUSTER_NODES_FILE"
}

show_file_with_line_no() {
  local file="$1"
  if [[ ! -s "$file" ]]; then
    say_warn "$(i18n_get msg_no_records 'No records')"
    return 0
  fi
  nl -ba "$file"
}

