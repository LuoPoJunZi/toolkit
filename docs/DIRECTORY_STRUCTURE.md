# Toolkit Directory Structure

This file describes the **current** repository layout after the native module migration.

## Goals

- Keep the entry path small: `toolkit.sh` -> `core/menu.sh` -> `modules/entries.sh`.
- Keep active features in native modules under `modules/luopo/`.
- Keep runtime helpers in `core/` or module-local helper files.
- Keep optional upstream reference snapshots local-only; do not upload `vendor/luopo.sh` to GitHub.
- Keep retired drafts and local memory out of GitHub through `.gitignore`.

## Current Tree

```text
toolkit/
├─ toolkit.sh                         # Entry script and internal command dispatcher
├─ install.sh                         # Remote/local bootstrap installer
├─ .gitignore                         # Shared ignore rules
├─ .editorconfig                      # Editor whitespace and indentation rules
├─ .gitattributes                     # Repository line-ending policy
├─ .shellcheckrc                      # Bash static-analysis policy
├─ README.md
├─ README_en.md
├─ LICENSE
├─ CHANGELOG.md
├─ VERSION
├─ core/
│  ├─ menu.sh                         # Main menu renderer and dispatcher entry
│  ├─ menu_registry.sh                # Main menu registry
│  ├─ menu_dispatcher.sh              # Main menu action dispatcher
│  ├─ ui.sh                           # UI output and prompt helpers
│  ├─ env.sh                          # OS/root checks
│  ├─ logger.sh                       # action/error logs
│  ├─ runtime.sh                      # shared runtime helpers
│  ├─ self_update.sh                  # self-update flow
│  ├─ uninstall.sh                    # toolkit uninstall flow
│  └─ diagnose.sh                     # diagnostics helpers
├─ lang/
│  ├─ zh_CN.sh
│  └─ en_US.sh
├─ modules/
│  ├─ entries.sh                      # Loads all main-menu entry files
│  ├─ entry_*.sh                      # Thin main-menu entry wrappers
│  ├─ system_info.sh                  # 1. system information
│  ├─ system_update.sh                # 2. full system update
│  ├─ system_cleanup.sh               # 3. system cleanup
│  ├─ scripts_hub.sh                  # 4. script hub
│  └─ luopo/
│     ├─ basic_tools/                 # 5. basic tools
│     ├─ bbr_management/              # 6. BBR management
│     ├─ docker/                      # 7. Docker management
│     │  ├─ manager.sh                # Docker menu loader and main menu
│     │  └─ parts/
│     │     ├─ common.sh
│     │     ├─ install_status.sh
│     │     ├─ resources.sh
│     │     └─ daemon_backup.sh
│     ├─ warp_management/             # 8. WARP management
│     ├─ network_test/                # 9. test script suite
│     ├─ ldnmp/                       # 10. LDNMP site builder
│     │  ├─ menu.sh
│     │  ├─ registry.sh
│     │  ├─ actions.sh
│     │  ├─ actions_sites.sh
│     │  ├─ sites/
│     │  │  ├─ environment.sh
│     │  │  ├─ php_cms.sh
│     │  │  └─ apps_static.sh
│     │  ├─ actions_proxy.sh
│     │  ├─ actions_proxy_core.sh
│     │  ├─ actions_stream.sh
│     │  ├─ actions_site_status.sh
│     │  ├─ actions_security.sh
│     │  ├─ actions_optimization.sh
│     │  ├─ actions_maintenance.sh
│     │  ├─ helpers.sh
│     │  ├─ helpers_install.sh
│     │  ├─ helpers_runtime.sh
│     │  └─ helpers_site.sh
│     ├─ app_marketplace/             # 11. app market
│     │  ├─ menu.sh
│     │  ├─ registry.sh
│     │  ├─ actions.sh
│     │  ├─ helpers.sh
│     │  ├─ native_apps.sh            # native app loader
│     │  └─ native/                   # split native app implementations
│     │     ├─ common.sh
│     │     ├─ panels.sh
│     │     ├─ files_media.sh
│     │     ├─ files_media/
│     │     │  ├─ notes_bookmarks.sh
│     │     │  ├─ file_storage_sync.sh
│     │     │  ├─ media_gallery.sh
│     │     │  └─ docs_dev_data.sh
│     │     ├─ network_security.sh
│     │     ├─ network_security/
│     │     │  ├─ dns_search_speed.sh
│     │     │  ├─ cert_remote_access.sh
│     │     │  └─ tunnels.sh
│     │     └─ ai_productivity.sh
│     ├─ workspace/                   # 12. background workspace
│     ├─ system_tools/                # 13. system tools
│     │  ├─ menu.sh
│     │  ├─ registry.sh
│     │  ├─ actions.sh
│     │  ├─ actions_access.sh
│     │  ├─ actions_operations.sh     # operations action loader
│     │  ├─ operations/
│     │  │  ├─ host_schedule.sh
│     │  │  ├─ security_monitoring.sh
│     │  │  ├─ network_env.sh
│     │  │  └─ shell_locale.sh
│     │  ├─ actions_misc.sh           # misc action loader
│     │  ├─ misc/
│     │  │  ├─ maintenance.sh
│     │  │  ├─ backup_file.sh
│     │  │  ├─ sync_remote.sh
│     │  │  ├─ sync_remote/
│     │  │  │  ├─ rsync_tasks.sh
│     │  │  │  └─ ssh_manager.sh
│     │  │  ├─ security_disk_kernel.sh
│     │  │  └─ security_disk_kernel/
│     │  │     ├─ clamav.sh
│     │  │     ├─ disk_manager.sh
│     │  │     └─ reinstall_kernel.sh
│     │  ├─ helpers.sh                # helper loader
│     │  └─ helpers/
│     │     ├─ common.sh
│     │     ├─ access_network.sh
│     │     ├─ ssh_users.sh
│     │     ├─ system_maintenance.sh
│     │     └─ rendering.sh
├─ integrations/
│  ├─ index.json                      # Approved one-click scripts
│  ├─ fetcher.sh                      # Download/cache wrapper
│  ├─ verifier.sh                     # Hash/source verification
│  └─ runners.sh                      # Safe execution wrapper
├─ scripts/
│  ├─ auto-release.sh
│  ├─ check-version-sync.sh
│  ├─ lint.sh
│  ├─ preflight.sh
│  └─ preflight.ps1
├─ tests/
│  └─ smoke_menu.sh
├─ docs/
│  ├─ DIRECTORY_STRUCTURE.md
│  ├─ RUN_CHECKLIST.md
│  ├─ STRUCTURE_OPTIMIZATION_LOG.md
│  ├─ UPSTREAM_ATTRIBUTION.md
│  ├─ VENDOR_DEPENDENCY_AUDIT.md
│  └─ ...
├─ vendor/                            # Optional local-only upstream reference snapshots
├─ data/                              # Runtime state/cache/backups, ignored where generated
└─ logs/                              # Runtime logs, ignored
```

## Active Runtime Path

```text
toolkit.sh
  -> core/menu.sh
     -> core/menu_registry.sh
     -> core/menu_dispatcher.sh
     -> modules/entries.sh
        -> modules/entry_*.sh
           -> modules/luopo/*/menu.sh
```

## Vendor / Legacy Policy

- Active modules must not call:
  - `ensure_luopo_vendor_loaded`
  - `run_luopo_compat_menu`
  - `luopo_*_require_vendor_runtime`
  - module-local `legacy_bridge.sh`
- `modules/compat/` has been removed.
- `vendor/luopo.sh` is local-only and ignored by Git. Attribution is documented in `docs/UPSTREAM_ATTRIBUTION.md`.
- Retired drafts stay local only:
  - `modules/menus/`
  - `modules/extended_menus.sh`
  - `modules/singbox.sh`
  - `LOCAL_SESSION_MEMORY.md`
  - `kejilion_upstream.sh`
  - `vendor/luopo.sh`

## Notes

- `data/state/`, `data/backups/`, `data/cache/`, and `logs/` are runtime-generated and ignored.
- `integrations/index.json` is the source of truth for one-click script definitions.
- Tracked Bash files use two-space indentation and are checked by `bash -n`, ShellCheck, and read-only shfmt validation through `scripts/lint.sh`.
- Shell and documentation files use LF line endings on every platform.
- Main menu numbering is registry-driven and currently reserves:
  - `99` update toolkit
  - `88` uninstall toolkit
  - `0` exit
