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
