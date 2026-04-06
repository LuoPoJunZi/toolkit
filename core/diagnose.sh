#!/usr/bin/env bash
set -euo pipefail

collect_diagnostics() {
  local out="/tmp/toolkit-diagnostics-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$out" \
    /etc/os-release \
    /var/log/syslog \
    /var/log/messages \
    2>/dev/null || true
  echo "Diagnostics: $out"
}
