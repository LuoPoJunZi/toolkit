#!/usr/bin/env bash
set -euo pipefail

# Shared native app-market helpers.

luopo_app_marketplace_native_app_state() {
  local container_name="$1"
  if docker inspect --type container "$container_name" >/dev/null 2>&1; then
    printf '%s\n' "已安装"
  else
    printf '%s\n' "未安装"
  fi
}

luopo_app_marketplace_native_add_app_id() {
  local app_id="$1"
  local legacy_app_id
  LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY=0
  mkdir -p "$(dirname "$LUOPO_APP_MARKETPLACE_STATE_FILE")" || return 1
  touch "$LUOPO_APP_MARKETPLACE_STATE_FILE" || return 1
  legacy_app_id="${LUOPO_APP_MARKETPLACE_LEGACY_IDS[$app_id]:-}"
  if [[ -n "$legacy_app_id" ]]; then
    sed -i "/^${legacy_app_id}$/d" "$LUOPO_APP_MARKETPLACE_STATE_FILE" || return 1
  fi
  grep -qxF "$app_id" "$LUOPO_APP_MARKETPLACE_STATE_FILE" || printf '%s\n' "$app_id" >>"$LUOPO_APP_MARKETPLACE_STATE_FILE" || return 1
}

luopo_app_marketplace_native_remove_app_id() {
  local app_id="$1"
  local legacy_app_id
  LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY=0
  if [[ -f "$LUOPO_APP_MARKETPLACE_STATE_FILE" ]]; then
    sed -i "/^${app_id}$/d" "$LUOPO_APP_MARKETPLACE_STATE_FILE" || return 1
    legacy_app_id="${LUOPO_APP_MARKETPLACE_LEGACY_IDS[$app_id]:-}"
    if [[ -n "$legacy_app_id" ]]; then
      sed -i "/^${legacy_app_id}$/d" "$LUOPO_APP_MARKETPLACE_STATE_FILE" || return 1
    fi
  fi
}

luopo_app_marketplace_native_show_access() {
  local container_name="$1"
  local app_port="$2"

  echo "------------------------"
  echo "访问地址:"
  luopo_app_marketplace_ip_address

  if [[ -n "${ipv4_address:-}" ]]; then
    echo "http://${ipv4_address}:${app_port}"
  fi
  if [[ -n "${ipv6_address:-}" ]]; then
    echo "http://[${ipv6_address}]:${app_port}"
  fi

  local search_pattern1="${ipv4_address:-}:${app_port}"
  local search_pattern2="127.0.0.1:${app_port}"
  local file
  for file in /home/web/conf.d/*; do
    if [[ -f "$file" ]] && { grep -q "$search_pattern1" "$file" 2>/dev/null || grep -q "$search_pattern2" "$file" 2>/dev/null; }; then
      echo "https://$(basename "$file" | sed 's/\.conf$//')"
    fi
  done
}

luopo_app_marketplace_native_install_docker_runtime() {
  if ! install jq; then
    echo "应用依赖安装失败，已停止操作。"
    return 1
  fi
  if ! install_docker; then
    echo "Docker 安装失败，已停止操作。"
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Docker 服务不可用，请检查服务状态后重试。"
    return 1
  fi
  mkdir -p "${LUOPO_APP_MARKETPLACE_STATE_FILE%/*}" || return 1
}

luopo_app_marketplace_native_update_container() {
  local image_name="$1"
  local install_fn="$2"
  shift 2

  docker pull "$image_name" || return 1
  "$install_fn" "$@" || return 1
}

luopo_app_marketplace_native_container_env() {
  local container_name="$1"
  local env_name="$2"

  docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$container_name" 2>/dev/null \
    | awk -F= -v name="$env_name" '$1 == name {sub(/^[^=]*=/, ""); print; exit}'
}

luopo_app_marketplace_native_container_arg() {
  local container_name="$1"
  local arg_prefix="$2"

  docker inspect --format '{{range .Config.Cmd}}{{println .}}{{end}}' "$container_name" 2>/dev/null \
    | awk -v prefix="$arg_prefix" 'index($0, prefix) == 1 {print substr($0, length(prefix) + 1); exit}'
}

luopo_app_marketplace_native_repo_sync() {
  local repo_url="$1"
  local target_dir="$2"

  if [[ -d "${target_dir}/.git" ]]; then
    git -C "$target_dir" fetch --depth 1 origin || return 1
    git -C "$target_dir" reset --hard FETCH_HEAD || return 1
  else
    rm -rf "$target_dir"
    git clone --depth 1 "$repo_url" "$target_dir" || return 1
  fi
}

luopo_app_marketplace_native_set_env_value() {
  local env_file="$1"
  local key="$2"
  local value="$3"
  local escaped_value
  escaped_value="$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')"

  if grep -q "^${key}=" "$env_file" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${escaped_value}|" "$env_file"
  else
    printf '%s=%s\n' "$key" "$value" >>"$env_file"
  fi
}

luopo_app_marketplace_native_proxy_add() {
  local container_name="$1"
  local app_port="$2"
  echo "${container_name} 域名访问设置"
  luopo_app_marketplace_add_yuming
  luopo_ldnmp_proxy_site "${yuming}" 127.0.0.1 "${app_port}"
  luopo_app_marketplace_block_container_port "$container_name" "$ipv4_address"
}

luopo_app_marketplace_native_proxy_remove() {
  local container_name="$1"
  local app_port="$2"
  echo "${container_name} 域名访问删除"
  install jq
  local conf_file target_domain
  conf_file="$(grep -rlE "127\.0\.0\.1:${app_port}|${ipv4_address:-}:${app_port}" /home/web/conf.d 2>/dev/null | head -n1 || true)"
  if [[ -z "$conf_file" ]]; then
    echo "未找到与 ${container_name} 关联的反向代理域名"
    return 0
  fi
  target_domain="$(basename "$conf_file" .conf)"
  luopo_app_marketplace_delete_proxy_domain "$target_domain"
  luopo_app_marketplace_clear_container_rules "$container_name" "$ipv4_address"
  echo "已删除域名访问: ${target_domain}"
}

luopo_app_marketplace_native_ip_allow() {
  local container_name="$1"
  luopo_app_marketplace_clear_container_rules "$container_name" "$ipv4_address"
  echo "已允许 ${container_name} 的 IP+端口访问"
}

luopo_app_marketplace_native_ip_block() {
  local container_name="$1"
  luopo_app_marketplace_block_container_port "$container_name" "$ipv4_address"
  echo "已阻止 ${container_name} 的 IP+端口访问"
}

luopo_app_marketplace_native_docker_app_menu() {
  local app_id="$1"
  local app_name="$2"
  local container_name="$3"
  # Compose installers pull their own image set and pass an empty image here.
  local image_name="$4"
  local default_port="$5"
  local description="$6"
  local url="$7"
  local install_fn="$8"
  local update_fn="$9"
  local uninstall_fn="${10}"
  local post_install_fn="${11:-}"
  local choice app_port state

  luopo_app_marketplace_bootstrap || return 1
  while true; do
    clear
    state="$(luopo_app_marketplace_native_app_state "$container_name")"
    echo "${app_name} ${state}"
    echo "$description"
    echo "$url"
    if [[ "$state" == "已安装" ]]; then
      app_port="$(luopo_app_marketplace_native_app_effective_port "$container_name" || true)"
      if [[ -n "$app_port" ]]; then
        luopo_app_marketplace_native_show_access "$container_name" "$app_port"
      fi
    fi
    echo
    echo "------------------------"
    echo "1. 安装              2. 更新            3. 卸载"
    echo "------------------------"
    echo "5. 添加域名访问      6. 删除域名访问"
    echo "7. 允许IP+端口访问   8. 阻止IP+端口访问"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice || return 0

    case "$choice" in
      1)
        app_port="$(luopo_app_marketplace_native_prompt_port "$default_port")" || continue
        if ! luopo_app_marketplace_native_install_docker_runtime; then
          break_end
          continue
        fi
        if [[ -n "$image_name" ]] && ! docker pull "$image_name"; then
          echo "${app_name} 镜像下载失败，未执行安装。"
          break_end
          continue
        fi
        if ! "$install_fn" "$app_port"; then
          echo "${app_name} 安装失败，请检查上方错误信息。"
          break_end
          continue
        fi
        if ! luopo_app_marketplace_native_app_store_port "$container_name" "$app_port" || ! luopo_app_marketplace_native_add_app_id "$app_id"; then
          echo "${app_name} 已执行安装，但状态保存失败，请检查目录权限。"
          break_end
          continue
        fi
        clear
        echo "${app_name} 已安装完成"
        luopo_app_marketplace_native_show_access "$container_name" "$app_port"
        if [[ -n "$post_install_fn" ]] && ! "$post_install_fn"; then
          echo "安装后操作失败，请检查上方错误信息。"
        fi
        send_stats "安装${app_name}"
        ;;
      2)
        app_port="$(luopo_app_marketplace_native_app_effective_port "$container_name" || true)"
        if [[ -z "$app_port" ]]; then
          app_port="$default_port"
        fi
        if ! luopo_app_marketplace_native_install_docker_runtime; then
          break_end
          continue
        fi
        if ! "$update_fn" "$app_port"; then
          echo "${app_name} 更新失败，原有应用状态已尽量保留。"
          break_end
          continue
        fi
        if ! luopo_app_marketplace_native_app_store_port "$container_name" "$app_port" || ! luopo_app_marketplace_native_add_app_id "$app_id"; then
          echo "${app_name} 已执行更新，但状态保存失败，请检查目录权限。"
          break_end
          continue
        fi
        clear
        echo "${app_name} 已更新完成"
        luopo_app_marketplace_native_show_access "$container_name" "$app_port"
        if [[ -n "$post_install_fn" ]] && ! "$post_install_fn"; then
          echo "更新后操作失败，请检查上方错误信息。"
        fi
        send_stats "更新${app_name}"
        ;;
      3)
        if ! "$uninstall_fn"; then
          echo "${app_name} 卸载失败，保留安装记录。"
          break_end
          continue
        fi
        if ! rm -f "$(luopo_app_marketplace_native_app_port_file "$container_name")" || ! luopo_app_marketplace_native_remove_app_id "$app_id"; then
          echo "${app_name} 卸载状态清理失败，请检查目录权限。"
          break_end
          continue
        fi
        send_stats "卸载${app_name}"
        ;;
      5)
        app_port="$(luopo_app_marketplace_native_app_effective_port "$container_name" || true)"
        if [[ -z "$app_port" ]]; then
          echo "应用尚未安装，无法添加域名访问"
        else
          luopo_app_marketplace_native_proxy_add "$container_name" "$app_port"
        fi
        ;;
      6)
        app_port="$(luopo_app_marketplace_native_app_effective_port "$container_name" || true)"
        if [[ -z "$app_port" ]]; then
          echo "应用尚未安装，无法删除域名访问"
        else
          luopo_app_marketplace_native_proxy_remove "$container_name" "$app_port"
        fi
        ;;
      7)
        luopo_app_marketplace_native_ip_allow "$container_name"
        ;;
      8)
        luopo_app_marketplace_native_ip_block "$container_name"
        ;;
      0)
        return 0
        ;;
      *)
        echo "无效的输入!"
        ;;
    esac
    break_end
  done
}

luopo_app_marketplace_native_container_action_menu() {
  local app_id="$1"
  local app_name="$2"
  local container_name="$3"
  local description="$4"
  local url="$5"
  local install_fn="$6"
  local update_fn="$7"
  local uninstall_fn="$8"
  local post_fn="${9:-}"
  local choice state

  luopo_app_marketplace_bootstrap || return 1
  while true; do
    clear
    state="$(luopo_app_marketplace_native_app_state "$container_name")"
    echo "${app_name} ${state}"
    echo "$description"
    echo "$url"
    echo
    echo "------------------------"
    echo "1. 安装              2. 更新            3. 卸载"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice || return 0

    case "$choice" in
      1)
        if ! luopo_app_marketplace_native_install_docker_runtime; then
          break_end
          continue
        fi
        if ! "$install_fn"; then
          echo "${app_name} 安装失败，请检查上方错误信息。"
          break_end
          continue
        fi
        if ! luopo_app_marketplace_native_add_app_id "$app_id"; then
          echo "${app_name} 已执行安装，但状态保存失败，请检查目录权限。"
          break_end
          continue
        fi
        if [[ -n "$post_fn" ]] && ! "$post_fn"; then
          echo "安装后操作失败，请检查上方错误信息。"
        fi
        ;;
      2)
        if ! luopo_app_marketplace_native_install_docker_runtime; then
          break_end
          continue
        fi
        if ! "$update_fn"; then
          echo "${app_name} 更新失败，原有应用状态已尽量保留。"
          break_end
          continue
        fi
        if ! luopo_app_marketplace_native_add_app_id "$app_id"; then
          echo "${app_name} 已执行更新，但状态保存失败，请检查目录权限。"
          break_end
          continue
        fi
        if [[ -n "$post_fn" ]] && ! "$post_fn"; then
          echo "更新后操作失败，请检查上方错误信息。"
        fi
        ;;
      3)
        if ! "$uninstall_fn"; then
          echo "${app_name} 卸载失败，保留安装记录。"
          break_end
          continue
        fi
        if ! luopo_app_marketplace_native_remove_app_id "$app_id"; then
          echo "${app_name} 卸载状态清理失败，请检查目录权限。"
          break_end
          continue
        fi
        ;;
      0)
        return 0
        ;;
      *)
        echo "无效的输入!"
        ;;
    esac
    break_end
  done
}
