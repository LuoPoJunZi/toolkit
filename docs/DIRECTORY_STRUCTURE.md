# Toolkit Directory Structure

This file describes the **current** repository layout after the native module migration.

## Goals

- Keep the entry path small: `toolkit.sh` -> `core/menu.sh` -> `modules/entries.sh`.
- Keep active features in native modules under `modules/luopo/`.
- Keep runtime helpers in `core/` or module-local helper files.
- Keep `vendor/luopo.sh` as upstream attribution, audit trail, and emergency reference only.
- Keep retired drafts and local memory out of GitHub through `.gitignore`.

## Current Tree

```text
toolkit/
├─ toolkit.sh                         # Entry script and internal command dispatcher
├─ install.sh                         # Remote/local bootstrap installer
├─ .gitignore                         # Shared ignore rules
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
│  ├─ rollback.sh                     # rollback helpers
│  ├─ diagnose.sh                     # diagnostics helpers
│  └─ mirrors.sh                      # mirror helpers
├─ lang/
│  ├─ zh_CN.sh
│  └─ en_US.sh
├─ modules/
│  ├─ entries.sh                      # Loads all main-menu entry files
│  ├─ entry_*.sh                      # Thin main-menu entry wrappers
│  ├─ system_info.sh                  # 1. system information
│  ├─ system_update.sh                # 2. full system update
│  ├─ system_cleanup.sh               # 3. system cleanup
│  ├─ scripts_hub.sh                  # 4. one-click script hub
│  └─ luopo/
│     ├─ basic_tools/                 # 5. basic tools
│     ├─ bbr_management/              # 6. BBR management
│     ├─ docker/                      # 7. Docker management
│     ├─ warp_management/             # 8. WARP management
│     ├─ network_test/                # 9. test script suite
│     ├─ oracle_cloud/                # 10. Oracle Cloud tools
│     ├─ ldnmp/                       # 11. LDNMP site builder
│     │  ├─ menu.sh
│     │  ├─ registry.sh
│     │  ├─ actions.sh
│     │  ├─ actions_sites.sh
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
│     ├─ app_marketplace/             # 12. app market
│     ├─ workspace/                   # 13. background workspace
│     ├─ system_tools/                # 14. system tools
│     │  ├─ menu.sh
│     │  ├─ registry.sh
│     │  ├─ actions.sh
│     │  ├─ actions_access.sh
│     │  ├─ actions_operations.sh
│     │  ├─ actions_misc.sh
│     │  └─ helpers.sh
│     └─ cluster_control/             # 15. server cluster control
├─ integrations/
│  ├─ index.json                      # Approved one-click scripts
│  ├─ fetcher.sh                      # Download/cache wrapper
│  ├─ verifier.sh                     # Hash/source verification
│  └─ runners.sh                      # Safe execution wrapper
├─ scripts/
│  ├─ auto-release.sh
│  ├─ check-version-sync.sh
│  └─ lint.sh
├─ tests/
│  └─ smoke_menu.sh
├─ docs/
│  ├─ DIRECTORY_STRUCTURE.md
│  ├─ RUN_CHECKLIST.md
│  ├─ STRUCTURE_OPTIMIZATION_LOG.md
│  ├─ UPSTREAM_ATTRIBUTION.md
│  ├─ VENDOR_DEPENDENCY_AUDIT.md
│  └─ ...
├─ vendor/
│  └─ luopo.sh                        # Upstream reference/backup, not active runtime
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
- `vendor/luopo.sh` remains tracked for attribution, source comparison, and emergency reference.
- Retired drafts stay local only:
  - `modules/menus/`
  - `modules/extended_menus.sh`
  - `modules/singbox.sh`
  - `LOCAL_SESSION_MEMORY.md`
  - `kejilion_upstream.sh`

## Notes

- `data/state/`, `data/backups/`, `data/cache/`, and `logs/` are runtime-generated and ignored.
- `integrations/index.json` is the source of truth for one-click script definitions.
- Main menu numbering is registry-driven and currently reserves:
  - `99` update toolkit
  - `88` uninstall toolkit
  - `0` exit
