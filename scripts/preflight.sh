#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

git diff --check

mapfile -t tracked_shell_files < <(git ls-files -- '*.sh')
shell_files=()
for file in "${tracked_shell_files[@]}"; do
  if [[ -f "$file" ]]; then
    shell_files+=("$file")
  fi
done

if ((${#shell_files[@]} > 0)); then
  bash -n "${shell_files[@]}"
fi

if command -v shellcheck >/dev/null 2>&1 && command -v shfmt >/dev/null 2>&1; then
  bash scripts/lint.sh
else
  echo "shellcheck/shfmt not found; local lint skipped (CI still enforces it)."
fi

bash scripts/check-version-sync.sh
bash tests/smoke_menu.sh
