#!/usr/bin/env bash
set -euo pipefail

mapfile -t tracked_shell_files < <(git ls-files -- '*.sh')
shell_files=()
for file in "${tracked_shell_files[@]}"; do
  if [[ -f "$file" ]]; then
    shell_files+=("$file")
  fi
done

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

for file in "${shell_files[@]}"; do
  bash -n "$file"
done
shellcheck "${shell_files[@]}"
shfmt -d -i 2 -ci -bn "${shell_files[@]}"
