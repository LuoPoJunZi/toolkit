#!/usr/bin/env bash
set -euo pipefail

LUOPO_CLUSTER_DIR="${HOME}/cluster"
LUOPO_CLUSTER_SERVERS_FILE="${LUOPO_CLUSTER_DIR}/servers.py"

luopo_cluster_bootstrap() {
  ensure_luopo_vendor_loaded || return 1
  mkdir -p "$LUOPO_CLUSTER_DIR"
  if [[ ! -f "$LUOPO_CLUSTER_SERVERS_FILE" ]]; then
    cat >"$LUOPO_CLUSTER_SERVERS_FILE" <<'EOF'
servers = [

]
EOF
  fi
}

luopo_cluster_finish() {
  break_end
}

luopo_cluster_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

luopo_cluster_show_servers() {
  cat "$LUOPO_CLUSTER_SERVERS_FILE"
}

luopo_cluster_open_editor() {
  install nano
  nano "$LUOPO_CLUSTER_SERVERS_FILE"
}
