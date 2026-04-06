# Toolkit v1 PRD (Draft)

## Positioning

- Name: `toolkit`
- Target user: beginner Linux webmasters
- Supported OS: Ubuntu / Debian
- Interaction: pure menu only

## v1 Functional Scope

1. System information query
2. System update
3. System cleanup
4. One-click scripts hub (third-party integrations)
5. Docker management
6. Script self-update (`00`)
7. Exit script (`0`)

## Non-Functional Requirements

- Chinese/English bilingual
- Logs: operation log + error log
- One-click diagnostics collection
- Prefer rollback for high-risk operations
- Security for integrations:
  - source review
  - pinned version
  - SHA256 check
  - manual confirmation
- Distribution: bash one-liner style
- Versioning: semantic versioning
- CI: shellcheck + shfmt + basic smoke test

## Acceptance Criteria

- Menu loads on Ubuntu/Debian with root privileges
- Options `1/2/3/4/6/00/0` are callable
- Scripts hub loads enabled items from `integrations/index.json`
- Scripts hub verifies SHA256 before execution
- Logs are written to `logs/action.log` and `logs/error.log`
- `bash toolkit.sh en` switches to English labels
