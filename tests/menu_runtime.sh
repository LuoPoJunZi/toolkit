#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/lang/zh_CN.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/core/menu.sh"

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  exit 1
}

assert_menu_rows() {
  local output="$1"
  shift
  local line item number label expected
  local -a rows=()

  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]+[0-9]+\. ]]; then
      rows+=("$line")
    fi
  done <<<"$output"
  ((${#rows[@]} == $#)) || fail "menu row count differs from its registry"

  local index=0
  for item in "$@"; do
    IFS='|' read -r number label _ <<<"$item"
    printf -v expected ' %-3s %s' "${number}." "$label"
    [[ "${rows[index]}" == "$expected" ]] || fail "unexpected menu row: ${rows[index]}"
    ((index += 1))
  done
}

test_main_menu() (
  local language item number label_key output version
  local -a expected_rows=()
  version="$(get_toolkit_version)"

  for language in zh_CN en_US; do
    # shellcheck disable=SC1090
    source "$ROOT_DIR/lang/$language.sh"
    output="$(render_main_menu)" || fail "main-menu rendering failed"
    [[ "$output" == *"$(msg title_main_fmt "$version")"* ]] || fail "localized title is missing"
    expected_rows=()
    for item in "${MENU_ITEMS[@]}"; do
      IFS='|' read -r number label_key _ <<<"$item"
      expected_rows+=("$number|${I18N[$label_key]}")
    done
    assert_menu_rows "$output" "${expected_rows[@]}"
  done

  output="$(msg title_main_fmt 'test-version')"
  [[ "$output" == 'LuoPo VPS Toolkit vtest-version (Quick start: z)' ]] || fail "translation formatting changed"
)

# These test doubles are called indirectly by the main-menu dispatcher.
# shellcheck disable=SC2329
test_main_dispatch() (
  local output
  log_action() { printf 'ACTION=%s\n' "$1"; }
  log_error() { printf 'ERROR=%s\n' "$1"; }
  press_enter() { printf 'PAUSE\n'; }
  entry_system_info() { printf 'OVERVIEW\n'; }
  entry_basic_tools() { printf 'TOOLS\n'; }
  entry_exit() { printf 'EXIT\n'; }

  output="$(dispatch_menu_action 1)" || fail "overview dispatch failed"
  [[ "$output" == $'ACTION=menu:system_info\nOVERVIEW\nPAUSE' ]] || fail "overview route or pause changed"
  output="$(dispatch_menu_action 4)" || fail "tools dispatch failed"
  [[ "$output" == $'ACTION=menu:luopo_basic_tools_menu\nTOOLS' ]] || fail "submenu route should not add a pause"
  output="$(dispatch_menu_action 0)" || fail "exit dispatch failed"
  [[ "$output" == 'EXIT' ]] || fail "exit route changed"
  output="$(dispatch_menu_action unknown)" || fail "invalid-choice handling failed"
  [[ "$output" == *"$(msg invalid)"*$'\nPAUSE' ]] || fail "invalid choice should display a message and pause"

  entry_system_info() { return 1; }
  output="$(dispatch_menu_action 1)" || fail "failed action should return to the menu"
  [[ "$output" == *'ERROR=action_failed:system_info'* ]] || fail "failed action was not logged"
)

# The app-menu loop calls this terminal double dynamically.
# shellcheck disable=SC2329
test_app_marketplace() (
  local state_file declaration output frame_count=0
  clear() {
    ((frame_count += 1))
    ((frame_count <= 1)) || fail "app market kept redrawing after input ended"
  }
  state_file="$(mktemp)"
  trap 'rm -f -- "$state_file"' EXIT
  printf '%s\n' 60 ignored >"$state_file"

  if declare -F luopo_app_marketplace_menu >/dev/null; then
    fail "app market was eagerly loaded"
  fi
  entry_load_module "$ROOT_DIR/modules/luopo/app_marketplace/menu.sh" luopo_app_marketplace_menu || fail "app-market lazy loading failed"
  for declaration in LUOPO_APP_MARKETPLACE_LEGACY_IDS LUOPO_APP_MARKETPLACE_LABELS LUOPO_APP_MARKETPLACE_INSTALLED_IDS; do
    output="$(declare -p "$declaration")" || fail "array vanished after loading: $declaration"
    [[ "$output" == 'declare -A '* ]] || fail "cache must remain associative: $declaration"
  done
  [[ "${LUOPO_APP_MARKETPLACE_LEGACY_IDS[10]}" == 60 ]] || fail "legacy ID mapping vanished"
  LUOPO_APP_MARKETPLACE_STATE_FILE="$state_file"
  luopo_app_marketplace_refresh_render_cache || fail "cache refresh failed"
  luopo_app_marketplace_is_installed 10 || fail "legacy installed ID was not recognized"
  if luopo_app_marketplace_is_installed 11; then
    fail "uninstalled app was marked installed"
  fi
  [[ "${LUOPO_APP_MARKETPLACE_LABELS[10]}" == 'Beszel服务器监控' ]] || fail "app label changed"
  LUOPO_APP_MARKETPLACE_LABELS[10]=sentinel
  entry_load_module "$ROOT_DIR/modules/luopo/app_marketplace/menu.sh" luopo_app_marketplace_menu || fail "repeat loading failed"
  [[ "${LUOPO_APP_MARKETPLACE_LABELS[10]}" == sentinel ]] || fail "repeat loading reset the cache"
  luopo_render_app_marketplace_menu >/dev/null || fail "app-market rendering failed"

  if declare -F luopo_app_marketplace_native_docker_app_menu >/dev/null; then
    fail "rendering eagerly loaded native apps"
  fi
  luopo_app_marketplace_menu </dev/null >/dev/null || fail "app market should return on EOF"
  if luopo_app_marketplace_dispatch_choice 0; then
    fail "return choice lost its control signal"
  fi
  luopo_app_marketplace_load_native_apps || fail "native app loading failed"
  luopo_app_marketplace_native_valid_port 65535 || fail "native port helpers were not loaded"
  luopo_app_marketplace_native_add_app_id 10 || fail "app marker write failed"
  [[ "$LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY" == 0 ]] || fail "marker write did not invalidate the cache"
  grep -qxF 10 "$state_file" || fail "current ID was not saved"
  if grep -qxF 60 "$state_file"; then
    fail "legacy ID was not migrated"
  fi
  luopo_app_marketplace_is_installed 10 || fail "updated state was not refreshed"
  luopo_app_marketplace_native_remove_app_id 10 || fail "app marker removal failed"
  if luopo_app_marketplace_is_installed 10; then
    fail "removed app is still marked installed"
  fi
)

# Rendering uses these doubles instead of inspecting host packages or tmux.
# shellcheck disable=SC2329
test_submenus() (
  local output frame_count=0
  clear() {
    ((frame_count += 1))
    ((frame_count <= 1)) || fail "menu kept redrawing after input ended"
  }

  entry_load_module "$ROOT_DIR/modules/luopo/basic_tools/menu.sh" luopo_basic_tools_menu || fail "tools lazy loading failed"
  # Sourcing modules defines the host probes; replace them after loading.
  luopo_basic_tools_detect_package_manager() { printf 'test-packages\n'; }
  luopo_basic_tools_print_status_table() { :; }
  output="$(luopo_render_basic_tools_menu)" || fail "tools rendering failed"
  assert_menu_rows "$output" "${LUOPO_BASIC_TOOLS_ITEMS[@]}" '0|返回主菜单'
  luopo_basic_tools_menu </dev/null >/dev/null || fail "tools should return on EOF"

  entry_load_module "$ROOT_DIR/modules/luopo/network_test/menu.sh" luopo_network_test_menu || fail "network-test lazy loading failed"
  output="$(luopo_render_network_test_menu)" || fail "network-test rendering failed"
  assert_menu_rows "$output" "${LUOPO_NETWORK_TEST_ITEMS[@]}" '0|返回主菜单'
  frame_count=0
  luopo_network_test_menu </dev/null >/dev/null || fail "network-test menu should return on EOF"

  entry_load_module "$ROOT_DIR/modules/luopo/warp_management/menu.sh" luopo_warp_management_menu || fail "WARP lazy loading failed"
  output="$(luopo_render_warp_menu)" || fail "WARP rendering failed"
  assert_menu_rows "$output" "${LUOPO_WARP_ITEMS[@]}" '0|返回主菜单'
  frame_count=0
  luopo_warp_management_menu </dev/null >/dev/null || fail "WARP menu should return on EOF"

  entry_load_module "$ROOT_DIR/modules/luopo/workspace/menu.sh" luopo_workspace_menu || fail "workspace lazy loading failed"
  luopo_workspace_list_sessions() { :; }
  output="$(luopo_render_workspace_menu)" || fail "workspace rendering failed"
  assert_menu_rows "$output" "${LUOPO_WORKSPACE_ITEMS[@]}" '0|返回主菜单'
  frame_count=0
  luopo_workspace_menu </dev/null >/dev/null || fail "workspace should return on EOF"
)

# Root/OS/terminal probes are replaced only inside this test subprocess.
# shellcheck disable=SC2329
test_input_end() (
  local answer=unchanged frame_count=0
  require_root() { :; }
  detect_os() { :; }
  clear() {
    ((frame_count += 1))
    ((frame_count <= 1)) || fail "main menu kept redrawing after input ended"
  }
  if read_menu_choice answer </dev/null; then
    fail "menu input should report EOF"
  fi
  [[ "$answer" == unchanged ]] || fail "EOF overwrote the destination variable"
  main_menu </dev/null >/dev/null || fail "main menu should exit cleanly on EOF"
)

test_main_menu
test_main_dispatch
test_app_marketplace
test_submenus
test_input_end
printf '[PASS] menu runtime checks passed\n'
