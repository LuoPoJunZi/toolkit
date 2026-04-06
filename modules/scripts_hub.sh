#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/integrations/fetcher.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/integrations/verifier.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/integrations/runners.sh"

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "缺少 jq，安装命令: apt-get update && apt-get install -y jq"
    return 1
  fi
}

list_enabled_scripts() {
  jq -r '.scripts[] | select(.enabled == true) | [.id, .name] | @tsv' "$ROOT_DIR/integrations/index.json"
}

run_integration_script() {
  local script_id="$1"
  local index_file="$ROOT_DIR/integrations/index.json"
  local source_url pinned_version sha256 manual_confirm
  local cache_file display_name

  source_url="$(jq -r --arg id "$script_id" '.scripts[] | select(.id == $id) | .source' "$index_file")"
  pinned_version="$(jq -r --arg id "$script_id" '.scripts[] | select(.id == $id) | .pinned_version' "$index_file")"
  sha256="$(jq -r --arg id "$script_id" '.scripts[] | select(.id == $id) | .sha256' "$index_file")"
  manual_confirm="$(jq -r --arg id "$script_id" '.scripts[] | select(.id == $id) | .manual_confirm' "$index_file")"
  display_name="$(jq -r --arg id "$script_id" '.scripts[] | select(.id == $id) | .name' "$index_file")"

  if [[ -z "$source_url" || "$source_url" == "null" ]]; then
    echo "脚本源地址无效: $script_id"
    log_error "scripts_hub:invalid_source:$script_id"
    return 1
  fi

  mkdir -p "$ROOT_DIR/data/cache"
  cache_file="$ROOT_DIR/data/cache/${script_id}-${pinned_version}.sh"

  echo "已选择: $display_name"
  echo "开始下载: $source_url"
  fetch_script_to_cache "$source_url" "$cache_file"
  chmod +x "$cache_file"

  if [[ -z "$sha256" ]]; then
    echo "SHA256 为空: $script_id"
    echo "已按安全策略阻止执行，请先在 integrations/index.json 中填写 sha256"
    log_error "scripts_hub:sha256_missing:$script_id"
    return 1
  fi

  if ! verify_sha256 "$cache_file" "$sha256"; then
    echo "SHA256 校验失败: $script_id"
    log_error "scripts_hub:sha256_failed:$script_id"
    return 1
  fi

  echo "SHA256 校验通过"
  safe_run_script "$cache_file" "$manual_confirm"
}

scripts_hub() {
  local index_file="$ROOT_DIR/integrations/index.json"
  local entries choice selected_id
  local i=1

  if ! require_jq; then
    return 1
  fi

  if [[ ! -f "$index_file" ]]; then
    echo "脚本索引文件不存在: $index_file"
    return 1
  fi

  mapfile -t entries < <(list_enabled_scripts)
  if [[ "${#entries[@]}" -eq 0 ]]; then
    echo "暂无可用脚本"
    return 0
  fi

  echo "一键脚本列表:"
  for entry in "${entries[@]}"; do
    echo "[$i] $(awk -F$'\t' '{print $2}' <<<"$entry")"
    ((i++))
  done
  echo "[0] 返回上级菜单"

  read -r -p "请输入脚本编号: " choice
  if [[ "$choice" == "0" ]]; then
    return 0
  fi
  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "无效选项"
    return 1
  fi
  if (( choice < 1 || choice > ${#entries[@]} )); then
    echo "选项超出范围"
    return 1
  fi

  selected_id="$(awk -F$'\t' '{print $1}' <<<"${entries[$((choice - 1))]}")"
  log_action "scripts_hub:run:$selected_id"
  run_integration_script "$selected_id"
}
