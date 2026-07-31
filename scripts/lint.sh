#!/usr/bin/env bash
set -euo pipefail

mapfile -t shell_files < <(git ls-files '*.sh')

if ((${#shell_files[@]} == 0)); then
  echo "No tracked Bash files found."
  exit 0
fi

missing_tools=()
for tool in shellcheck shfmt; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing_tools+=("$tool")
  fi
done

if ((${#missing_tools[@]} > 0)); then
  printf 'Missing required lint tool: %s\n' "${missing_tools[@]}" >&2
  exit 127
fi

bash -n "${shell_files[@]}"
shellcheck "${shell_files[@]}"
shfmt -d -i 2 -ci -bn "${shell_files[@]}"
