# Toolkit v1 Directory Structure

## Goals
- Keep architecture minimal and maintainable
- Support Ubuntu/Debian first
- Pure menu interaction
- Integrate third-party scripts safely (source review, pinned version, hash check, manual confirm)
- Include logging, diagnostics, and rollback hooks
- Chinese/English bilingual support

## Proposed Tree
```text
toolkit/
├─ toolkit.sh                      # Entry script (menu launcher)
├─ install.sh                      # Quick installer/bootstrap
├─ .gitignore
├─ README.md
├─ LICENSE
├─ CHANGELOG.md
├─ VERSION
├─ docs/
│  ├─ DIRECTORY_STRUCTURE.md       # This file
│  ├─ PRD_V1.md                    # Product requirements (next step)
│  ├─ SECURITY_POLICY.md           # Script trust & execution policy
│  ├─ THIRD_PARTY_SCRIPTS.md       # Whitelist and source declarations
│  ├─ INTEGRATIONS_INDEX_SPEC.md   # integration index schema
│  ├─ BORROWING_STRATEGY.md        # intentional reference notes
│  └─ FAQ.md
├─ lang/
│  ├─ zh_CN.sh                     # Chinese i18n strings
│  └─ en_US.sh                     # English i18n strings
├─ core/
│  ├─ menu.sh                      # Main menu and routing
│  ├─ ui.sh                        # UI output, prompts, confirmations
│  ├─ env.sh                       # OS checks, dependency checks
│  ├─ logger.sh                    # action/error logs
│  ├─ self_update.sh               # script self-update (git-based)
│  ├─ rollback.sh                  # rollback metadata and restore flow
│  ├─ diagnose.sh                  # collect diagnostics package
│  └─ mirrors.sh                   # CN mirrors and fallback logic
├─ modules/
│  ├─ system_info.sh               # 1. system information
│  ├─ system_update.sh             # 2. system update
│  ├─ system_cleanup.sh            # 3. system cleanup
│  ├─ scripts_hub.sh               # 4. one-click script integrations
│  ├─ entries.sh                   # unified loader for menu entry files
│  ├─ entry_system_info.sh         # main-menu entry: system information
│  ├─ entry_system_update.sh       # main-menu entry: system update
│  ├─ entry_system_cleanup.sh      # main-menu entry: system cleanup
│  ├─ entry_scripts_hub.sh         # main-menu entry: script hub
│  ├─ entry_basic_tools.sh         # main-menu entry: basic tools
│  ├─ entry_bbr_management.sh      # main-menu entry: BBR management
│  ├─ entry_docker_management.sh   # main-menu entry: Docker management
│  ├─ entry_warp_management.sh     # main-menu entry: WARP management
│  ├─ entry_network_test_suite.sh  # main-menu entry: network tests
│  ├─ entry_oracle_cloud_suite.sh  # main-menu entry: Oracle Cloud tools
│  ├─ entry_ldnmp_site_suite.sh    # main-menu entry: LDNMP
│  ├─ entry_app_marketplace.sh     # main-menu entry: app market
│  ├─ entry_workspace_suite.sh     # main-menu entry: workspace
│  ├─ entry_system_tools_suite.sh  # main-menu entry: system tools
│  ├─ entry_cluster_control_suite.sh # main-menu entry: cluster control
│  ├─ entry_uninstall.sh           # main-menu entry: uninstall
│  ├─ entry_self_update.sh         # main-menu entry: self update
│  ├─ entry_exit.sh                # main-menu entry: exit
│  ├─ compat/                      # upstream-compatible shims still in use
│  │  ├─ load.sh                   # compatibility loader
│  │  ├─ common.sh                 # shared compat helpers
│  │  ├─ warp_management.sh        # 8. WARP management
│  │  ├─ ldnmp_site_suite.sh       # 11. LDNMP site suite
│  │  ├─ app_marketplace.sh        # 12. app marketplace
│  │  └─ system_tools_suite.sh     # 14. system tools
│  └─ luopo/                       # LuoPo native menu implementations
│     ├─ basic_tools/              # 5. basic tools
│     ├─ bbr_management/           # 6. BBR management
│     ├─ docker/                   # 7. Docker management
│     ├─ network_test/             # 9. test script suite
│     ├─ oracle_cloud/             # 10. Oracle Cloud tools
│     ├─ workspace/                # 13. background workspace
│     └─ cluster_control/          # 15. cluster control
├─ integrations/
│  ├─ index.json                   # approved third-party scripts index
│  ├─ fetcher.sh                   # download/cache wrapper
│  ├─ verifier.sh                  # hash/version/source verification
│  └─ runners.sh                   # safe run wrapper + manual confirm
├─ data/
│  ├─ state/                       # runtime state (non-git)
│  ├─ backups/                     # generated backups (non-git)
│  └─ cache/                       # downloaded scripts cache (non-git)
├─ logs/
│  ├─ action.log                   # operation log (non-git)
│  └─ error.log                    # error log (non-git)
├─ tests/
│  ├─ shell/                       # shell unit/integration tests
│  ├─ fixtures/
│  └─ smoke_menu.sh
├─ scripts/
│  ├─ check-version-sync.sh
│  ├─ lint.sh                      # shellcheck + shfmt
│  └─ release.sh
└─ .github/
   └─ workflows/
      ├─ ci.yml                    # shellcheck/shfmt/tests
      └─ release.yml
```

## Notes
- `data/`, `logs/` should be ignored by git.
- Third-party scripts are never executed directly from random URLs.
- `integrations/index.json` is the single source of truth for approved scripts.
- Menu numbering should reserve:
  - `00` script self-update
  - `0` exit
