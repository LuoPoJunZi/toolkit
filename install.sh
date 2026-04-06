#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-/opt/luopo-toolkit}"
BIN_PATH="/usr/local/bin/z"
AUTO_LAUNCH="${AUTO_LAUNCH:-1}"

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "请使用 root 运行安装脚本"
    exit 1
  fi
}

ensure_source_tree() {
  if [[ ! -f "$SCRIPT_DIR/toolkit.sh" ]]; then
    echo "未找到 toolkit.sh，请在项目目录内执行: bash install.sh"
    exit 1
  fi
}

sync_project_files() {
  mkdir -p "$INSTALL_DIR"
  tar \
    --exclude=".git" \
    --exclude="data/state" \
    --exclude="data/backups" \
    --exclude="data/cache" \
    --exclude="logs" \
    --exclude="LOCAL_SESSION_MEMORY.md" \
    -C "$SCRIPT_DIR" -cf - . | tar -C "$INSTALL_DIR" -xf -

  find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
}

install_launcher() {
  cat >"$BIN_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec bash "$INSTALL_DIR/toolkit.sh" "\$@"
EOF
  chmod +x "$BIN_PATH"
}

main() {
  require_root
  ensure_source_tree
  sync_project_files
  install_launcher

  if [[ "$AUTO_LAUNCH" == "1" && -e /dev/tty ]]; then
    bash "$INSTALL_DIR/toolkit.sh" </dev/tty >/dev/tty 2>/dev/tty
  fi
}

main "$@"
