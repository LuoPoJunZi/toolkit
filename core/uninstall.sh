#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="/opt/luopo-toolkit"
LAUNCHER="/usr/local/bin/z"

uninstall_toolkit() {
  local ans
  echo "即将完全卸载 LuoPo VPS Toolkit。"
  echo "将删除目录: $INSTALL_DIR"
  echo "将删除命令: $LAUNCHER"
  read -r -p "确认继续？此操作不可恢复 (y/N): " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "已取消卸载"
    return 0
  fi

  rm -f "$LAUNCHER"
  rm -f /usr/local/bin/k /usr/bin/k

  if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
  fi

  if [[ -d "$ROOT_DIR" && "$ROOT_DIR" != "$INSTALL_DIR" ]]; then
    echo "当前运行目录不是标准安装目录，未删除: $ROOT_DIR"
  fi

  echo "卸载完成"
  echo "已删除: $LAUNCHER"
  echo "已删除: $INSTALL_DIR"
  echo "脚本即将退出"
  exit 0
}
