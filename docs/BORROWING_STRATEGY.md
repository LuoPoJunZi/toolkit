# Borrowing Strategy (Intentional Reference)

References:
- https://github.com/kejilion/sh
- https://github.com/eooce/ssh_tool

What we intentionally borrow:
- Simple one-command bootstrap experience (bash entry)
- Menu-driven UX for beginners
- Practical module grouping (system + docker + service scripts)
- Fast operation-first style

What we intentionally do differently:
- Stricter third-party script policy with pinned version + hash + manual confirmation
- Clear integration index as single source of truth (`integrations/index.json`)
- Built-in logs and diagnostics baseline
- Better maintainability via modular folders (`core/`, `modules/`, `integrations/`)
- Bilingual string dictionaries (`lang/`) instead of hardcoding all text in one big script

## 2026-10-07 Review

Source reviewed: [kejilion.sh 4.5.11 at commit 6beba294](https://github.com/kejilion/sh/blob/6beba29450a31525fd38d02a36487841934febf3/kejilion.sh).

The review focused on interactive menus, application markers, installation ports, and the KPanel application adapter. This is a source comparison, not an upstream script import.

- Upstream `kpanel_app_update_marker` uses a temporary file followed by replacement, with explicit error propagation. Its concurrency adapter also serializes shared marker writes with `flock`. These are useful references for a later app-state persistence pass.
- Upstream application adapters check container identity and installation ports before operations. Rechecking live resources is useful when another terminal or a management panel may change them.
- LuoPo keeps its maintained local app catalog, numbered resource selectors, consistent single-column menus, and lightweight feature loading.
- This iteration fixes the lifetime of associative arrays loaded inside functions, removes repeated field-extraction subshells from menu rendering, and tests menu behavior through the actual lazy loader.

The second iteration extracts native port validation and atomic port-file saving, replaces container-list matching with exact inspection, and adds explicit failure handling plus backup/restore regression tests. Compose applications retain ownership of their image-set downloads.

Candidate follow-up work: app marker identity/migration, atomic shared-marker persistence/concurrency, and application-specific error propagation. Introduce these in focused changes with failure-path tests, preserving existing installation parameters and app data.
