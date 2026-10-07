#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/app_marketplace/actions.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/app_marketplace/native/ports.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/app_marketplace/native/common.sh"

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

# Test doubles intercept socket probes; no host ports are used.
# shellcheck disable=SC2329
test_ports() (
  local temporary output port
  temporary="$(mktemp -d)"
  trap 'rm -rf -- "$temporary"' EXIT
  gl_hong='' gl_bai=''
  ss() {
    if [[ ! -f "$temporary/probed" ]]; then
      touch "$temporary/probed"
      printf 'tcp LISTEN 0 128 *:8080 *:*\n'
    fi
  }
  output="$(luopo_app_marketplace_native_prompt_port 8080 <<<$'8080\n8081' 2>"$temporary/errors")" || fail "valid port selection failed"
  [[ "$output" == 8081 ]] || fail "port-conflict diagnostics contaminated the selected port"
  [[ -s "$temporary/errors" ]] || fail "port conflict was not explained"

  ss() { :; }
  output="$(luopo_app_marketplace_native_prompt_port 8080 <<<$'abc\n-1\n65536\n1.5\n999999999999\n00080' 2>"$temporary/errors")" || fail "port validation failed"
  [[ "$output" == 80 ]] || fail "invalid ports were accepted or leading zeros were not normalized"
  for port in 1 65535; do
    output="$(luopo_app_marketplace_native_prompt_port "$port" <<<'')" || fail "default port failed"
    [[ "$output" == "$port" ]] || fail "port boundary was rejected"
  done
  if output="$(luopo_app_marketplace_native_prompt_port 8080 <<<0)"; then
    fail "zero must cancel port selection"
  fi
  [[ -z "$output" ]] || fail "cancel returned a port"
  if output="$(luopo_app_marketplace_native_prompt_port 8080 </dev/null)"; then
    fail "EOF must cancel port selection"
  fi
  [[ -z "$output" ]] || fail "EOF returned a port"

  ss() { return 1; }
  if output="$(luopo_app_marketplace_native_prompt_port 8080 <<<8080 2>"$temporary/errors")"; then
    fail "failed socket inspection was treated as an available port"
  fi
  [[ -z "$output" && -s "$temporary/errors" ]] || fail "socket inspection failure was not reported"

  command() {
    if [[ "$*" == '-v ss' ]]; then
      return 1
    fi
    builtin command "$@"
  }
  netstat() { printf 'tcp 0 0 0.0.0.0:8080 0.0.0.0:* LISTEN\n'; }
  output="$(luopo_app_marketplace_native_prompt_port 8080 <<<$'8080\n18080' 2>"$temporary/errors")" || fail "netstat fallback failed"
  [[ "$output" == 18080 ]] || fail "fallback probe did not match exact ports"
  command() {
    if [[ "$*" == '-v ss' || "$*" == '-v netstat' ]]; then
      return 1
    fi
    builtin command "$@"
  }
  if output="$(luopo_app_marketplace_native_prompt_port 8080 <<<8080 2>"$temporary/errors")"; then
    fail "missing socket tools were silently ignored"
  fi
)

# Replace Docker and data-directory helpers only in this subprocess.
# shellcheck disable=SC2329
test_port_persistence() (
  local temporary port_file output
  temporary="$(mktemp -d)"
  trap 'rm -rf -- "$temporary"' EXIT
  LUOPO_APP_MARKETPLACE_STATE_FILE="$temporary/appno.txt"
  port_file="$(luopo_app_marketplace_native_app_port_file demo)"
  luopo_app_marketplace_native_app_store_port demo 08080 || fail "port saving failed"
  [[ "$(<"$port_file")" == 8080 ]] || fail "saved port was not normalized"
  if luopo_app_marketplace_native_app_store_port demo invalid; then
    fail "invalid port was saved"
  fi
  [[ "$(<"$port_file")" == 8080 ]] || fail "invalid save overwrote the previous port"
  printf 'corrupt\n' >"$port_file"
  docker() {
    [[ "$*" == 'port demo' ]] || fail "unexpected Docker operation in port test: $*"
    printf '80/tcp -> [::]:9090\n80/tcp -> 0.0.0.0:9090\n'
  }
  output="$(luopo_app_marketplace_native_app_effective_port demo)" || fail "corrupt saved-port fallback failed"
  [[ "$output" == 9090 ]] || fail "detected port was not used"
  mv() { return 1; }
  if luopo_app_marketplace_native_app_store_port demo 8081; then
    fail "failed port-file replacement reported success"
  fi
  [[ "$(<"$port_file")" == corrupt ]] || fail "failed port save damaged the old file"
  [[ -z "$(find "$temporary" -name '*.tmp.*' -print)" ]] || fail "failed port save left temporary files"
)

# Dependency preparation is invoked conditionally by the menu, disabling set -e.
# shellcheck disable=SC2329
test_runtime_failure() (
  local temporary dependency_stage output
  temporary="$(mktemp -d)"
  trap 'rm -rf -- "$temporary"' EXIT
  LUOPO_APP_MARKETPLACE_STATE_FILE="$temporary/appno.txt"
  install() { [[ "$dependency_stage" != packages ]]; }
  install_docker() {
    printf 'docker-runtime\n' >>"$temporary/calls"
    [[ "$dependency_stage" != docker ]]
  }
  docker() {
    printf 'daemon\n' >>"$temporary/calls"
    [[ "$dependency_stage" != daemon ]]
  }
  for dependency_stage in packages docker daemon; do
    : >"$temporary/calls"
    if output="$(luopo_app_marketplace_native_install_docker_runtime 2>&1)"; then
      fail "runtime preparation hid failure: $dependency_stage"
    fi
    [[ -n "$output" ]] || fail "runtime failure lacked diagnostics: $dependency_stage"
    if [[ "$dependency_stage" == packages && -s "$temporary/calls" ]]; then
      fail "Docker installation continued after dependency failure"
    fi
    if [[ "$dependency_stage" == docker ]] && grep -qxF daemon "$temporary/calls"; then
      fail "daemon probe continued after Docker installation failure"
    fi
  done
)

# Exact container inspection must not enumerate or regex-match other names.
# shellcheck disable=SC2329
test_container_state() (
  local container_state output
  docker() {
    [[ "$*" == 'inspect --type container demo.app' ]] || fail "container status enumerated unrelated containers"
    [[ "$container_state" == installed ]]
  }
  container_state=installed
  output="$(luopo_app_marketplace_native_app_state demo.app)"
  [[ "$output" == 已安装 ]] || fail "existing container was not recognized"
  container_state=missing
  output="$(luopo_app_marketplace_native_app_state demo.app)"
  [[ "$output" == 未安装 ]] || fail "missing container was marked installed"
)

# Indirect application callbacks record their order instead of mutating Docker.
# shellcheck disable=SC2329
test_application_actions() (
  local temporary stage action mode output expected
  temporary="$(mktemp -d)"
  trap 'rm -rf -- "$temporary"' EXIT
  record() {
    printf '%s\n' "$1" >>"$temporary/calls"
    [[ "$stage" != "$1" ]]
  }
  clear() {
    ((frame_count += 1))
    ((frame_count <= 3)) || fail "application menu kept redrawing after input ended"
  }
  break_end() { :; }
  send_stats() { :; }
  luopo_app_marketplace_bootstrap() { :; }
  luopo_app_marketplace_native_app_state() { printf '未安装\n'; }
  luopo_app_marketplace_native_prompt_port() {
    record prompt || return 1
    printf '8080\n'
  }
  luopo_app_marketplace_native_app_effective_port() { printf '8080\n'; }
  luopo_app_marketplace_native_install_docker_runtime() { record runtime; }
  luopo_app_marketplace_native_app_store_port() { record store; }
  luopo_app_marketplace_native_add_app_id() { record marker; }
  luopo_app_marketplace_native_remove_app_id() { record remove-marker; }
  luopo_app_marketplace_native_app_port_file() { printf '%s/port\n' "$temporary"; }
  luopo_app_marketplace_native_show_access() { record access; }
  docker() {
    [[ "$*" == 'pull demo/image' ]] || fail "unexpected Docker operation: $*"
    record pull
  }
  mock_install() { record install; }
  mock_update() { record update; }
  mock_uninstall() { record uninstall; }
  mock_post() { record post; }
  run_menu() {
    local frame_count=0 image=demo/image
    [[ "$mode" == compose ]] && image=''
    if [[ "$mode" != container ]]; then
      luopo_app_marketplace_native_docker_app_menu 6 Demo demo "$image" 8080 description url mock_install mock_update mock_uninstall mock_post
    else
      luopo_app_marketplace_native_container_action_menu 6 Demo demo description url mock_install mock_update mock_uninstall mock_post
    fi
  }

  for mode in port compose container; do
    for action in 1 2 3; do
      for stage in runtime pull install update store marker uninstall success; do
        : >"$temporary/calls"
        printf '8080\n' >"$temporary/port"
        output="$(run_menu <<<"$action"$'\n0')" || fail "menu did not recover: $mode/$action/$stage"
        if [[ "$mode" == compose ]] && grep -qxF pull "$temporary/calls"; then
          fail "Compose workflow pulled an unrelated single image"
        fi
        if [[ "$action" == 1 || "$action" == 2 ]]; then
          expected=install
          [[ "$action" == 2 ]] && expected=update
          if [[ "$stage" == runtime ]]; then
            if grep -qxF "$expected" "$temporary/calls"; then
              fail "action ran after runtime failure: $mode/$action"
            fi
          fi
          if [[ "$mode" == port && "$action" == 1 && "$stage" == pull ]]; then
            if grep -qxF install "$temporary/calls"; then fail "install ran after image download failure"; fi
          fi
          if [[ "$stage" == "$expected" || "$stage" == runtime || ("$mode" == port && "$action" == 1 && "$stage" == pull) ]]; then
            if grep -qxF marker "$temporary/calls"; then fail "failed action was marked installed"; fi
            [[ "$output" != *'已安装完成'* && "$output" != *'已更新完成'* ]] || fail "failed action reported completion"
          fi
          if [[ "$stage" == marker || ("$mode" != container && "$stage" == store) ]]; then
            if grep -qxF post "$temporary/calls"; then fail "post-install hook ran after persistence failure"; fi
            [[ "$output" != *'已安装完成'* && "$output" != *'已更新完成'* ]] || fail "persistence failure reported completion"
          fi
          if [[ "$mode" != container && "$stage" == store ]] && grep -qxF marker "$temporary/calls"; then
            fail "marker was saved after port configuration failed"
          fi
          if [[ "$stage" == success ]]; then
            grep -qxF "$expected" "$temporary/calls" || fail "successful action was not run"
            grep -qxF marker "$temporary/calls" || fail "successful action did not save state"
            grep -qxF post "$temporary/calls" || fail "successful action did not run its hook"
          fi
        elif [[ "$stage" == uninstall ]]; then
          if grep -qxF remove-marker "$temporary/calls"; then fail "failed uninstall removed installed state"; fi
          [[ -f "$temporary/port" ]] || fail "failed uninstall removed the saved port"
        elif [[ "$stage" == success ]]; then
          grep -qxF remove-marker "$temporary/calls" || fail "successful uninstall kept installed state"
        fi
      done
    done
    stage=success
    output="$(run_menu </dev/null)" || fail "application submenu did not return on EOF"
  done
  mode=port stage=prompt
  : >"$temporary/calls"
  output="$(run_menu <<<$'1\n0')" || fail "port cancellation did not return to the menu"
  [[ "$(<"$temporary/calls")" == prompt ]] || fail "port cancellation changed runtime or state"
)

# Exercise real wrappers so placeholder app names cannot become Docker images.
# shellcheck disable=SC2329
test_compose_wrappers() (
  local app calls=0
  # shellcheck disable=SC1091
  source "$ROOT_DIR/modules/luopo/app_marketplace/native_apps.sh"
  luopo_app_marketplace_native_docker_app_menu() {
    [[ -z "$4" ]] || fail "Compose wrapper passed a standalone image: $app/$4"
    ((calls += 1))
  }
  for app in gitea paperless umami karakeep linkwarden immich dify newapi; do
    "luopo_app_marketplace_${app}_menu" || fail "Compose wrapper failed: $app"
  done
  [[ "$calls" == 8 ]] || fail "Compose wrapper coverage is incomplete"
)

# Backups use an isolated state directory and a failing tar double.
# shellcheck disable=SC2329
test_backup_restore() (
  local temporary output archive archive_mode
  temporary="$(mktemp -d)"
  trap 'rm -rf -- "$temporary"' EXIT
  mkdir -p "$temporary/docker"
  LUOPO_APP_MARKETPLACE_STATE_FILE="$temporary/docker/appno.txt"
  tar() {
    printf '%s\n' "$*" >>"$temporary/calls"
    if [[ "$1" == -czf ]]; then
      printf 'archive\n' >"$2"
    fi
    [[ "$archive_mode" == success || ("$archive_mode" == extract-failed && "$1" == -tzf) ]]
  }
  luopo_ldnmp_list_files_by_mtime() { :; }
  archive_mode=failed
  if output="$(luopo_app_marketplace_backup_all 2>&1)"; then fail "failed backup reported success"; fi
  [[ "$output" != *'备份完成'* ]] || fail "failed backup printed completion"
  [[ -z "$(find "$temporary" \( -name '*tar.gz*' -o -name '.luopo-app-market-*' \) -print)" ]] || fail "failed backup left an archive or temporary file"
  archive_mode=success
  output="$(luopo_app_marketplace_backup_all)" || fail "backup success path failed"
  [[ "$output" == *'备份完成'* ]] || fail "backup completion missing"
  archive="$(find "$temporary" -name '*.tar.gz' -print -quit)"
  [[ -n "$archive" ]] || fail "complete backup was not published"
  archive_mode=failed
  if output="$(luopo_app_marketplace_restore_all <<<"$archive"$'\nY' 2>&1)"; then fail "failed restore reported success"; fi
  [[ "$output" != *'还原完成'* ]] || fail "failed restore printed completion"
  archive_mode=extract-failed
  if output="$(luopo_app_marketplace_restore_all <<<"$archive"$'\nY' 2>&1)"; then fail "failed extraction reported success"; fi
  [[ "$output" != *'还原完成'* && "$output" == *'可能已有部分文件写入'* ]] || fail "partial restore was not explained"
  : >"$temporary/calls"
  output="$(luopo_app_marketplace_restore_all <<<"$archive"$'\nn')" || fail "restore cancellation failed"
  [[ ! -s "$temporary/calls" ]] || fail "cancelled restore extracted an archive"
  output="$(luopo_app_marketplace_restore_all </dev/null)" || fail "restore did not cancel on EOF"
  [[ ! -s "$temporary/calls" ]] || fail "EOF started extraction"
  archive_mode=success
  output="$(luopo_app_marketplace_restore_all <<<"$archive"$'\ny')" || fail "restore success path failed"
  [[ "$output" == *'还原完成'* ]] || fail "restore completion missing"
)

# Real tar round-trips only files created in this temporary directory.
# shellcheck disable=SC2329
test_archive_round_trip() (
  local temporary archive output
  temporary="$(mktemp -d)"
  trap 'rm -rf -- "$temporary"' EXIT
  mkdir -p "$temporary/docker/demo"
  LUOPO_APP_MARKETPLACE_STATE_FILE="$temporary/docker/appno.txt"
  LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY=1
  printf 'original\n' >"$temporary/docker/demo/file with spaces"
  printf '10\n' >"$LUOPO_APP_MARKETPLACE_STATE_FILE"
  luopo_ldnmp_list_files_by_mtime() { :; }
  luopo_app_marketplace_backup_all >/dev/null || fail "real archive creation failed"
  archive="$(find "$temporary" -name '*.tar.gz' -print -quit)"
  printf 'changed\n' >"$temporary/docker/demo/file with spaces"
  luopo_app_marketplace_restore_all <<<"$archive"$'\nY' >/dev/null || fail "real archive restoration failed"
  [[ "$(<"$temporary/docker/demo/file with spaces")" == original ]] || fail "restored archive contents differ"
  [[ "$LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY" == 0 ]] || fail "restore did not invalidate installed-state cache"
  luopo_app_marketplace_backup_all >/dev/null || fail "second backup failed"
  [[ "$(find "$temporary" -name '*.tar.gz' -print | wc -l)" -eq 2 ]] || fail "backup names overwrite each other"
  printf 'corrupt\n' >"$temporary/corrupt.tar.gz"
  printf 'unchanged\n' >"$temporary/docker/demo/file with spaces"
  if output="$(luopo_app_marketplace_restore_all <<<"$temporary/corrupt.tar.gz"$'\nY' 2>&1)"; then
    fail "corrupt archive was accepted"
  fi
  [[ "$(<"$temporary/docker/demo/file with spaces")" == unchanged ]] || fail "corrupt archive changed application data"
  [[ "$output" == *'未执行还原'* ]] || fail "corrupt archive was not explained"
)

test_ports
test_port_persistence
test_runtime_failure
test_container_state
test_application_actions
test_compose_wrappers
test_backup_restore
test_archive_round_trip
printf '[PASS] app-market runtime checks passed\n'
