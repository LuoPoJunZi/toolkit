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

run_integration_script() {
  local script_id="$1"
  local index_file="$ROOT_DIR/integrations/index.json"
  local source_url pinned_version sha256
  local cache_file

  source_url="$(jq -r --arg id "$script_id" '.scripts[] | select(.id == $id) | .source' "$index_file")"
  pinned_version="$(jq -r --arg id "$script_id" '.scripts[] | select(.id == $id) | .pinned_version' "$index_file")"
  sha256="$(jq -r --arg id "$script_id" '.scripts[] | select(.id == $id) | .sha256' "$index_file")"

  if [[ -z "$source_url" || "$source_url" == "null" ]]; then
    echo "脚本源地址无效: $script_id"
    log_error "scripts_hub:invalid_source:$script_id"
    return 1
  fi

  mkdir -p "$ROOT_DIR/data/cache"
  cache_file="$ROOT_DIR/data/cache/${script_id}-${pinned_version}.sh"

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

  safe_run_script "$cache_file"
}

scripts_hub() {
  local index_file="$ROOT_DIR/integrations/index.json"
  local choice selected_id
  local -a selected_ids
  local -a self_entries
  local -a third_entries
  local i

  if ! require_jq; then
    return 1
  fi

  if [[ ! -f "$index_file" ]]; then
    echo "脚本索引文件不存在: $index_file"
    return 1
  fi

  mapfile -t self_entries < <(jq -r '.scripts[] | select(.enabled == true and (.tags | index("self-project"))) | [.id, .name] | @tsv' "$index_file")
  mapfile -t third_entries < <(jq -r '.scripts[] | select(.enabled == true and ((.tags | index("self-project")) | not)) | [.id, .name] | @tsv' "$index_file")

  if [[ "${#self_entries[@]}" -eq 0 && "${#third_entries[@]}" -eq 0 ]]; then
    echo "暂无可用脚本"
    return 0
  fi

  echo "========================================"
  echo "一键脚本中心"
  echo "========================================"

  i=1
  if [[ "${#self_entries[@]}" -gt 0 ]]; then
    for entry in "${self_entries[@]}"; do
      selected_ids+=("$(awk -F$'\t' '{print $1}' <<<"$entry")")
      printf " %-3s %s\n" "${i}." "【落魄】$(awk -F$'\t' '{print $2}' <<<"$entry")"
      ((i++))
    done
  fi

  if [[ "${#third_entries[@]}" -gt 0 ]]; then
    for entry in "${third_entries[@]}"; do
      selected_ids+=("$(awk -F$'\t' '{print $1}' <<<"$entry")")
      printf " %-3s %s\n" "${i}." "【第三方】$(awk -F$'\t' '{print $2}' <<<"$entry")"
      ((i++))
    done
  fi

  echo "----------------------------------------"
  menu_item "0" "返回上级菜单"
  echo "========================================"

  read -r -p "请输入脚本编号: " choice
  if [[ "$choice" == "0" ]]; then
    return 0
  fi
  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "无效选项"
    return 1
  fi
  if (( choice < 1 || choice > ${#selected_ids[@]} )); then
    echo "选项超出范围"
    return 1
  fi

  selected_id="${selected_ids[$((choice - 1))]}"
  log_action "scripts_hub:run:$selected_id"
  run_integration_script "$selected_id"
}
