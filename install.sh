#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-/opt/luopo-toolkit}"
BIN_PATH="/usr/local/bin/z"
AUTO_LAUNCH="${AUTO_LAUNCH:-1}"
REPO_ARCHIVE_URL="${LUOPO_REPO_ARCHIVE_URL:-https://codeload.github.com/LuoPoJunZi/toolkit/tar.gz/refs/heads/main}"
SOURCE_DIR="$SCRIPT_DIR"
BOOTSTRAP_TMP_DIR=""

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "请使用 root 运行安装脚本"
    exit 1
  fi
}

ensure_source_tree() {
  if [[ -f "$SOURCE_DIR/toolkit.sh" ]]; then
    return 0
  fi

  bootstrap_source_tree
}

bootstrap_source_tree() {
  local archive_file extracted_dir

  if ! command -v curl >/dev/null 2>&1; then
    echo "缺少 curl，无法执行远程引导安装"
    exit 1
  fi
  if ! command -v tar >/dev/null 2>&1; then
    echo "缺少 tar，无法解压项目源码包"
    exit 1
  fi

  BOOTSTRAP_TMP_DIR="$(mktemp -d)"
  archive_file="$BOOTSTRAP_TMP_DIR/toolkit.tar.gz"

  echo "正在拉取 LuoPo VPS Toolkit 项目文件..."
  if ! curl -fsSL "$REPO_ARCHIVE_URL" -o "$archive_file"; then
    echo "下载项目源码包失败: $REPO_ARCHIVE_URL"
    exit 1
  fi

  if ! tar -xzf "$archive_file" -C "$BOOTSTRAP_TMP_DIR"; then
    echo "解压项目源码包失败"
    exit 1
  fi

  extracted_dir="$(find "$BOOTSTRAP_TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "$extracted_dir" || ! -f "$extracted_dir/toolkit.sh" ]]; then
    echo "项目源码包内容不完整，未找到 toolkit.sh"
    exit 1
  fi

  SOURCE_DIR="$extracted_dir"
}

cleanup_bootstrap_tmp() {
  if [[ -n "$BOOTSTRAP_TMP_DIR" && -d "$BOOTSTRAP_TMP_DIR" ]]; then
    rm -rf "$BOOTSTRAP_TMP_DIR"
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
    --exclude="kejilion_upstream.sh" \
    --exclude="vendor/luopo.sh" \
    -C "$SOURCE_DIR" -cf - . | tar -C "$INSTALL_DIR" -xf -

  find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
}

install_launchers() {
  cat >"$BIN_PATH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec bash "$INSTALL_DIR/toolkit.sh" "\$@"
EOF
  chmod +x "$BIN_PATH"
  rm -f /usr/local/bin/k /usr/bin/k
}

main() {
  trap cleanup_bootstrap_tmp EXIT
  require_root
  ensure_source_tree
  sync_project_files
  install_launchers

  if [[ "$AUTO_LAUNCH" == "1" && -e /dev/tty ]]; then
    bash "$INSTALL_DIR/toolkit.sh" </dev/tty >/dev/tty 2>/dev/tty
  fi
}

main "$@"
