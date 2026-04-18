# Structure Optimization Log

## Purpose
- Record completed structural work locally.
- Prevent repeated refactors and repeated audits.
- Keep the remaining work list explicit after each round.

## Working Rules
- Any structure-level change must be appended here.
- If a module is detached from `ensure_luopo_vendor_loaded`, record it here.
- If shared runtime helpers are extracted from `vendor/luopo.sh`, record them here.
- If a module still depends on vendor for business logic, note that separately from runtime coupling.
- `vendor/luopo.sh` is kept as backup/reference. Structure work should migrate runtime usage into `core/` and `modules/luopo/`, not delete the backup file.

## Progress Timeline

### 2026-04-17 - Round 1
Completed:
- Added vendor dependency audit document:
  - `docs/VENDOR_DEPENDENCY_AUDIT.md`
- Added shared runtime layer:
  - `core/runtime.sh`
- Loaded shared runtime from:
  - `core/menu.sh`
- Extracted first shared runtime helpers from vendor:
  - color variables
  - `send_stats`
  - `install`
  - `remove`
  - `break_end`
- Detached these modules from vendor bootstrap:
  - `basic_tools`
  - `network_test`

Remaining after round:
- `app_marketplace`
- `bbr_management`
- `cluster_control`
- `ldnmp`
- `oracle_cloud`
- `system_tools`
- `warp_management`
- `workspace`

### 2026-04-17 - Round 2
Completed:
- Expanded `core/runtime.sh` with:
  - `install_docker`
  - `tmux_run`
  - `tmux_run_d`
  - `bbr_on`
  - `server_reboot`
  - `add_sshpasswd`
- Detached these modules from vendor bootstrap:
  - `workspace`
  - `bbr_management`
  - `oracle_cloud`

Remaining after round:
- `app_marketplace`
- `cluster_control`
- `ldnmp`
- `system_tools`
- `warp_management`

### 2026-04-17 - Round 3
Completed:
- Detached `warp_management` from vendor bootstrap
- Detached `cluster_control` from vendor bootstrap
- Replaced cluster vendor dependency `run_commands_on_servers` with native helper:
  - `luopo_cluster_run_commands_on_servers`
- Converted `app_marketplace` bootstrap to native path by default
- Added app marketplace native helpers for:
  - IP detection
  - domain prompt
  - container firewall allow/block
  - proxy-domain config removal
- Kept LDNMP reverse-proxy creation as on-demand vendor fallback via wrapper:
  - `luopo_app_marketplace_ldnmp_proxy`

Remaining after round:
- `app_marketplace`
- `ldnmp`
- `system_tools`

### 2026-04-17 - Round 4
Completed:
- Converted `system_tools` bootstrap to native path by default
- Added native `system_tools` helpers for:
  - `root_use`
  - `check_crontab_installed`
  - `prefer_ipv4`
  - `restart_ssh`
  - `current_timezone`
  - `set_timedate`
- Replaced broad bootstrap coupling with narrow on-demand vendor wrapper:
  - `luopo_system_tools_run_vendor_function`
- Kept legacy-heavy operational actions as explicit fallback wrappers instead of deleting backup logic

Remaining after round:
- `ldnmp`
- `app_marketplace` narrow reverse-proxy fallback
- `system_tools` narrow legacy action fallback

### 2026-04-17 - Round 5
Completed:
- Converted `ldnmp` bootstrap to native path by default
- Replaced menu status banner direct vendor call with wrapper:
  - `luopo_ldnmp_render_status_banner`
- Switched `ldnmp` action dispatch to current-shell on-demand vendor loading:
  - `luopo_ldnmp_require_vendor_runtime`
- Kept legacy site-management business logic intact as backup-driven execution path for now

Remaining after round:
- `ldnmp` broad legacy business fallback
- `app_marketplace` narrow reverse-proxy fallback
- `system_tools` narrow legacy action fallback

### 2026-04-17 - Round 6
Completed:
- Split `ldnmp` monolithic action file into focused modules:
  - `actions_sites.sh`
  - `actions_proxy.sh`
  - `actions_maintenance.sh`
- Reduced `actions.sh` to dispatcher/aggregator role
- Synced smoke checks and directory documentation to the new `ldnmp` structure

Remaining after round:
- `ldnmp` broad legacy business fallback
- `app_marketplace` narrow reverse-proxy fallback
- `system_tools` narrow legacy action fallback

### 2026-04-17 - Round 7
Completed:
- Split `system_tools` monolithic action file into focused modules:
  - `actions_access.sh`
  - `actions_operations.sh`
  - `actions_misc.sh`
- Reduced `system_tools/actions.sh` to dispatcher/aggregator role
- Synced smoke checks and directory documentation to the new `system_tools` structure

Remaining after round:
- `ldnmp` broad legacy business fallback
- `app_marketplace` narrow reverse-proxy fallback
- `system_tools` narrow legacy action fallback

### 2026-04-17 - Round 8
Completed:
- Reduced `system_tools` legacy fallback surface by moving these helpers to native implementation:
  - `iptables_open`
  - `new_ssh_port`
  - `add_swap`
  - `create_user_with_sshkey`
  - `auto_optimize_dns`
  - `linux_update`
  - `linux_clean`
  - `f2b_status`
  - `f2b_install_sshd`
  - `k_info`
- Added supporting native helpers:
  - `save_iptables_rules`
  - `fix_dpkg`
  - `luopo_system_tools_write_dns`

Remaining after round:
- `ldnmp` broad legacy business fallback
- `app_marketplace` narrow reverse-proxy fallback
- `system_tools` remaining legacy action fallback:
  - SSH/user creation and SSH-key flows
  - swap / mirror / firewall subpanels
  - DNS UI / reinstall / kernel / language / file-manager class menus

### 2026-04-17 - Round 9
Completed:
- Isolated remaining legacy fallback paths into dedicated bridge files:
  - `modules/luopo/app_marketplace/legacy_bridge.sh`
  - `modules/luopo/ldnmp/legacy_bridge.sh`
  - `modules/luopo/system_tools/legacy_bridge.sh`
- Removed mixed legacy bridge logic from native helper files
- Finalized native-vs-legacy layering:
  - native helpers stay in `helpers.sh`
  - legacy fallback stays in `legacy_bridge.sh`
  - dispatch remains in `actions.sh`

Remaining after round:
- `ldnmp` legacy business logic still broad, but structurally isolated
- `app_marketplace` narrow reverse-proxy fallback structurally isolated
- `system_tools` remaining legacy action fallback structurally isolated

### 2026-04-17 - Round 10
Completed:
- Synchronized `tests/smoke_menu.sh` with the new bridge layering
- Added explicit smoke coverage for:
  - `modules/luopo/app_marketplace/legacy_bridge.sh`
  - `modules/luopo/ldnmp/legacy_bridge.sh`
  - `modules/luopo/system_tools/legacy_bridge.sh`
- Updated assertions so native `helpers.sh` files are checked for:
  - sourcing the dedicated bridge file
  - no longer embedding legacy bridge functions inline
- Corrected `docs/DIRECTORY_STRUCTURE.md` so helper vs bridge responsibilities match the current codebase
- Completed a static boundary check confirming vendor-only functions now live in `legacy_bridge.sh` for the remaining isolated fallback modules

Remaining after round:
- No new structure blockers found
- Remaining work is business-logic migration depth, not menu/bootstrap structure

### 2026-04-17 - Round 11
Completed:
- Migrated the `app_marketplace` reverse-proxy path off its dedicated vendor bridge
- Removed `modules/luopo/app_marketplace/legacy_bridge.sh`
- Rewired app-market proxy creation through native `ldnmp` helper flow
- Started deep extraction of `ldnmp` native site/runtime helpers into `modules/luopo/ldnmp/helpers.sh`
- Replaced several `system_tools` legacy wrapper entry points with native menus:
  - DNS management
  - SSH key management
  - iptables/firewall management
  - fail2ban management

Remaining after round:
- `ldnmp` still has broad legacy business functions, but its common site/proxy skeleton is being pulled local
- `system_tools` still keeps some legacy heavy tools (`dd_xitong`, kernel/file/env/log class menus), though the high-frequency ops path is now more native

## Current Remaining Core Targets
Heavy target left:
- `ldnmp` legacy business actions

Narrow fallback targets still using backup logic on demand:
- `app_marketplace`
- `system_tools`
- `ldnmp`

## Definition of “Done” for Structure Work
- Module no longer requires `ensure_luopo_vendor_loaded` during normal menu bootstrap
- Module runtime dependencies come from `core/` or module-local helpers
- Compat layer is only used for true legacy fallback paths

### 2026-04-18 - Round 12
Completed:
- Reduced `ldnmp` legacy coupling from global action bootstrap to explicit per-action fallback
- Moved common `ldnmp` runtime helpers into native module code:
  - `ldnmp_v`
  - `luopo_ldnmp_render_status_banner`
  - `nginx_http_on`
  - `check_crontab_installed`
  - `save_iptables_rules`
  - `close_port`
  - `block_container_port`
- Removed the status-banner wrapper from `modules/luopo/ldnmp/legacy_bridge.sh`
- Replaced several remaining `system_tools` legacy menus with native module menus:
  - network card / interface helpers
  - log viewing helpers
  - environment variable helpers
  - shell prompt theme helpers
  - system language switching helpers
  - command favorites launcher
  - system backup / restore / delete menu
- Updated smoke assertions so legacy-backed routes are explicit and native routes stay native-first

Remaining after round:
- `ldnmp` still has selected heavy actions that intentionally load the vendor backup on demand
- `system_tools` still has selected heavy wrappers for reinstall/kernel/file/SSH-manager class flows
- `vendor/luopo.sh` remains as the backup/reference layer, not the active primary implementation
