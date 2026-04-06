#!/usr/bin/env bash
set -euo pipefail

show_system_info() {
  echo "Hostname: $(hostname)"
  echo "Kernel: $(uname -r)"
  echo "Uptime: $(uptime -p 2>/dev/null || true)"
  echo "CPU: $(nproc 2>/dev/null || echo unknown) cores"
  echo "Memory:"
  free -h 2>/dev/null || true
  echo "Disk:"
  df -h / 2>/dev/null || true
}
