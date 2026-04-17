# Vendor Dependency Audit

## Purpose
- Track which `modules/luopo/*` modules still depend on the legacy vendor runtime.
- Separate **shared runtime dependencies** from **module-specific business dependencies**.
- Provide a concrete execution order for `P1: 去 Vendor 运行时依赖`.
- Keep `vendor/luopo.sh` as backup/reference while migrating active runtime paths into native modules.

## Current Snapshot
- `modules/compat/` currently contains:
  - `common.sh`
  - `load.sh`
- `core/runtime.sh` now exists and already absorbs the first shared runtime slice:
  - color variables
  - `send_stats`
  - `install`
  - `remove`
  - `break_end`
  - `install_docker`
  - `tmux_run`
  - `tmux_run_d`
  - `bbr_on`
  - `server_reboot`
  - `add_sshpasswd`
- No native module now requires `ensure_luopo_vendor_loaded` for normal bootstrap.
- `app_marketplace` now uses native bootstrap by default and its reverse-proxy creation path has also been moved onto native `ldnmp` helpers.
- `system_tools` now uses native bootstrap by default and only keeps a narrow on-demand fallback wrapper for legacy-heavy operational actions.
- `ldnmp` now uses native bootstrap by default and keeps a broad current-shell on-demand fallback for legacy site-management actions.
- Remaining fallback logic is now isolated in dedicated `legacy_bridge.sh` files instead of being mixed into native helper files, except `app_marketplace` which no longer needs its own bridge.
- `docker` is already comparatively isolated and does not rely on a `helpers.sh` bootstrap.
- `basic_tools` and `network_test` have already been detached from vendor bootstrap.
- `workspace`, `bbr_management`, and `oracle_cloud` have now also been detached from vendor bootstrap.
- `cluster_control` and `warp_management` have now also been detached from vendor bootstrap.

## Dependency Layers

### Layer A: Shared Runtime Dependencies
These are not business features. They are the common runtime pieces repeatedly borrowed from the vendor layer.

Confirmed recurring dependencies:
- `ensure_luopo_vendor_loaded`
- `press_enter`
- `break_end`
- `send_stats`
- `install`
- `remove`
- `gh_proxy`
- color variables such as:
  - `gl_kjlan`
  - `gl_huang`
  - `gl_bai`
  - `gl_lv`

Practical meaning:
- Many modules only keep vendor around for these helper/runtime utilities.
- This is the best first extraction target because it unlocks multiple modules at once.

Recommended destination:
- `core/runtime.sh` or split into:
  - `core/ui_runtime.sh`
  - `core/package_manager.sh`
  - `core/stats.sh`
  - `core/colors.sh`

### Layer B: Shared Infrastructure Dependencies
These are used across multiple modules but are more operational than UI/runtime.

Observed recurring dependencies:
- `install_docker`
- `add_yuming`
- `ip_address`
- `ldnmp_Proxy`
- `repeat_add_yuming`
- `restart_ldnmp`
- `check_crontab_installed`
- `root_use`
- `server_reboot`
- `iptables_open`

Practical meaning:
- These functions should not live in the monolithic vendor file long-term.
- They are candidates for migration into reusable domain helpers.

Recommended destination:
- `core/docker_runtime.sh`
- `core/network_runtime.sh`
- `core/cron_runtime.sh`
- `modules/luopo/ldnmp/shared.sh`

## Module-by-Module Audit

### app_marketplace
Status:
- Native bootstrap path is active by default
- Has substantial native implementation already

Still vendor-backed or vendor-influenced:
- Shared runtime: `press_enter`, `break_end`, `send_stats`, `install`, color variables, `gh_proxy`
- Infra/business helpers used inside native app flows:
  - `install_docker`
  - native wrappers now cover:
    - `add_yuming`
    - `ip_address`
    - container firewall allow/block
    - proxy-domain config removal
  - remaining on-demand vendor fallback:
    - `ldnmp_Proxy`

Assessment:
- Structurally advanced.
- No longer requires vendor for normal bootstrap.
- Still depends on a narrow vendor fallback when creating LDNMP reverse proxies.

Priority:
- `P1-A` narrowed to reverse-proxy fallback removal

### basic_tools
Status:
- Mostly native menu/actions
- Dependency is mostly runtime-level
- Bootstrap dependency removed

Confirmed dependency shape:
- Shared runtime only:
  - `press_enter`
  - `break_end`
  - `send_stats`
  - `install`
  - `remove`

Assessment:
- Easy win.
- Likely one of the first modules that can fully stop calling `ensure_luopo_vendor_loaded`.
- Completed for bootstrap/runtime coupling in the current phase.

Priority:
- `P1-1` done

### bbr_management
Status:
- Small module
- Partly native, partly legacy capability reuse
- Bootstrap dependency removed

Confirmed direct dependencies:
- Shared runtime:
  - `break_end`
  - `press_enter`
  - `send_stats`
  - `install`
  - `gh_proxy`
- Business/vendor:
  - `bbr_on`
  - `server_reboot`

Assessment:
- Shared runtime extraction is easy.
- True decoupling still requires replacing `bbr_on` and reboot flow.
- Completed for bootstrap/runtime coupling in the current phase.

Priority:
- `P1-3` done

### cluster_control
Status:
- Native menu/actions exist
- Bootstrap dependency removed

Confirmed direct dependencies:
- Shared runtime:
  - `break_end`
  - `press_enter`
  - `send_stats`
  - `install`
- Likely business dependency:
  - `run_commands_on_servers`

Assessment:
- Moderate effort.
- Runtime part is easy; remote execution abstraction needs its own extraction.
- Completed for bootstrap/runtime coupling in the current phase.

Priority:
- `P1-6` done

### ldnmp
Status:
- Largest remaining structural debt
- Native bootstrap path is active by default
- Business actions still lean heavily on legacy implementation via current-shell on-demand loading

Confirmed direct dependencies include:
- `ldnmp_install_status_one`
- `ldnmp_install_all`
- `ldnmp_wp`
- `add_yuming`
- `repeat_add_yuming`
- `ldnmp_install_status`
- `install_ssltls`
- `certs_status`
- `add_db`
- `nginx_http_on`
- `restart_ldnmp`
- `ldnmp_web_on`
- `nginx_install_all`
- `ldnmp_Proxy`
- `ip_address`
- `nginx_install_status`
- `nginx_web_on`
- `ldnmp_Proxy_backend`
- `stream_panel`
- `ldnmp_web_status`
- `web_security`
- `web_optimization`
- `check_crontab_installed`
- `root_use`
- `install_dependency`
- `install_docker`
- `install_certbot`
- `install_ldnmp`
- `ldnmp_v`
- `nginx_upgrade`
- `break_end`

Assessment:
- This is the heaviest vendor-dependent module in the project.
- Bootstrap coupling is no longer the blocker.
- Remaining work is business-action extraction, not another menu/bootstrap refactor.
- Internal structure is now split into site installs, proxy/site operations, and maintenance flows.

Priority:
- `P1-8` narrowed to legacy business fallback reduction

### network_test
Status:
- Menu and shell wrapping are native
- Actual test actions are mostly shell commands
- Bootstrap dependency removed

Confirmed dependency shape:
- Shared runtime:
  - `break_end`
  - `press_enter`
  - `send_stats`
- No major deep business dependency found in helpers

Assessment:
- Another easy win once Layer A is extracted.
- Completed for bootstrap/runtime coupling in the current phase.

Priority:
- `P1-2` done

### oracle_cloud
Status:
- Native menu/actions exist
- Still relies on a few vendor operational helpers
- Bootstrap dependency removed

Confirmed dependencies:
- Shared runtime:
  - `break_end`
  - `send_stats`
  - `gh_proxy`
- Business/vendor:
  - `install_docker`
  - `add_sshpasswd`

Assessment:
- Moderate effort.
- Mostly blocked by extracting a few infra helpers.
- Completed for bootstrap/runtime coupling in the current phase.

Priority:
- `P1-5` done

### system_tools
Status:
- Native bootstrap path is active by default
- Still aggregates many legacy operational actions through an explicit on-demand wrapper

Confirmed direct dependencies include:
- Shared runtime:
  - `break_end`
  - `press_enter`
  - `send_stats`
  - `install`
- Native helpers now local to module:
  - `root_use`
  - `restart_ssh`
  - `prefer_ipv4`
  - `check_crontab_installed`
  - `current_timezone`
  - `set_timedate`
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
- Remaining on-demand vendor fallback actions:
  - SSH/user actions
  - swap/mirror/firewall actions
  - package/security/file/log/env helper menus

Assessment:
- Structurally no longer blocked by vendor bootstrap.
- Active path is now native-first.
- Remaining work is action-by-action extraction, not another bootstrap refactor.
- Internal structure is now split into access actions, operational actions, and misc/maintenance actions.

Priority:
- `P1-7` narrowed to legacy action fallback reduction

### warp_management
Status:
- Native menu shell exists
- Bootstrap dependency removed

Confirmed dependency shape:
- Shared runtime bootstrap removed
- Current native path is mostly:
  - `send_stats`
  - `install`
  - external WARP menu launch

Assessment:
- Completed for bootstrap/runtime coupling in the current phase.

Priority:
- `P1-9` done

### workspace
Status:
- Native menu/actions exist
- Business logic is thin but still uses legacy tmux helpers
- Bootstrap dependency removed

Confirmed dependencies:
- Shared runtime:
  - `break_end`
  - `press_enter`
  - `send_stats`
  - `install`
- Business/vendor:
  - `tmux_run`
  - `tmux_run_d`

Assessment:
- Good medium-sized migration target.
- Could be fully decoupled after extracting a small tmux runtime helper.
- Completed for bootstrap/runtime coupling in the current phase.

Priority:
- `P1-4` done

## Priority Order for P1
Recommended execution order:

1. Extract Layer A shared runtime
   - `press_enter`
   - `break_end`
   - `send_stats`
   - `install`
   - `remove`
   - color variables
   - `gh_proxy`
2. Remove vendor bootstrap from easy modules:
   - `basic_tools`
   - `network_test`
3. Migrate small business dependencies:
   - `bbr_management`
   - `workspace`
4. Extract shared infra helpers:
   - Docker install helper
   - domain/proxy helpers
   - cron helpers
   - reboot/ssh helpers
5. Migrate medium modules:
   - `oracle_cloud`
   - `cluster_control`
6. Split and migrate broad modules:
   - `system_tools`
   - `ldnmp`
7. Finalize `warp_management`

## Completion Definition
`P1` can be considered complete when:
- No `modules/luopo/*/helpers.sh` requires `ensure_luopo_vendor_loaded` for normal bootstrap
- `modules/compat/load.sh` is no longer required for normal native module execution
- Vendor loading is limited to explicit legacy fallback paths only

## Notes
- This audit is intentionally pragmatic, not a perfect parser-generated truth table.
- The goal is migration planning, not formal static analysis.
- If a module still runs but no longer needs vendor bootstrap, update this file together with the code.
