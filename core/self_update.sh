#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_URL="${LUOPO_BOOTSTRAP_URL:-https://z.evzzz.com}"

run_bootstrap_update() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "缺少 curl，无法执行远程更新"
    return 1
  fi

  bash <(curl -fsSL "$BOOTSTRAP_URL") || {
    echo "远程更新失败，请稍后重试"
    return 1
  }
  return 0
}

self_update() {
  if ! command -v git >/dev/null 2>&1; then
    run_bootstrap_update
    return $?
  fi

  if ! git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    run_bootstrap_update
    return $?
  fi

  if ! git -C "$ROOT_DIR" diff --quiet || ! git -C "$ROOT_DIR" diff --cached --quiet; then
    echo "检测到本地有未提交修改，为避免覆盖，已中止更新"
    return 1
  fi

  local branch remote_head local_head backup_commit
  branch="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)"
  if [[ "$branch" == "HEAD" ]]; then
    echo "当前是 detached HEAD，无法自动更新"
    return 1
  fi

  if ! git -C "$ROOT_DIR" fetch origin "$branch"; then
    echo "拉取远端信息失败"
    return 1
  fi

  local_head="$(git -C "$ROOT_DIR" rev-parse HEAD)"
  remote_head="$(git -C "$ROOT_DIR" rev-parse "origin/$branch")"

  if [[ "$local_head" == "$remote_head" ]]; then
    echo "当前已是最新版本"
    return 0
  fi

  read -r -p "发现新版本，是否立即更新？(y/N): " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "已取消更新"
    return 0
  fi

  backup_commit="$local_head"
  if git -C "$ROOT_DIR" merge --ff-only "origin/$branch"; then
    echo "更新完成"
    return 0
  fi

  echo "更新失败，正在自动回滚..."
  if git -C "$ROOT_DIR" reset --hard "$backup_commit"; then
    echo "已回滚到更新前版本: $backup_commit"
  else
    echo "自动回滚失败，请手动处理"
  fi
  return 1
}
