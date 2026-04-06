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
│  ├─ docker_manager.sh            # 6. Docker management
│  └─ singbox.sh                   # self-developed sing-box toolkit
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
