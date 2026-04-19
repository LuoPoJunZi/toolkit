#!/usr/bin/env bash
set -euo pipefail

# Shared native app-market helpers.

luopo_app_marketplace_native_app_state() {
  local container_name="$1"
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$container_name"; then
    printf '%s\n' "已安装"
  else
    printf '%s\n' "未安装"
  fi
}

luopo_app_marketplace_native_app_port_file() {
  local container_name="$1"
  printf '/home/docker/%s_port.conf\n' "$container_name"
}

luopo_app_marketplace_native_app_saved_port() {
  local container_name="$1"
  local port_file
  port_file="$(luopo_app_marketplace_native_app_port_file "$container_name")"
  if [[ -f "$port_file" ]]; then
    cat "$port_file"
  fi
}

luopo_app_marketplace_native_app_detect_port() {
  local container_name="$1"
  docker port "$container_name" 2>/dev/null | head -n1 | awk -F'[:]' '/->/ {print $NF; exit}'
}

luopo_app_marketplace_native_app_effective_port() {
  local container_name="$1"
  local saved_port detected_port
  saved_port="$(luopo_app_marketplace_native_app_saved_port "$container_name" || true)"
  if [[ -n "$saved_port" ]]; then
    printf '%s\n' "$saved_port"
    return 0
  fi

  detected_port="$(luopo_app_marketplace_native_app_detect_port "$container_name" || true)"
  if [[ -n "$detected_port" ]]; then
    printf '%s\n' "$detected_port"
    return 0
  fi

  return 1
}

luopo_app_marketplace_native_app_store_port() {
  local container_name="$1"
  local port="$2"
  mkdir -p /home/docker
  printf '%s\n' "$port" > "$(luopo_app_marketplace_native_app_port_file "$container_name")"
}

luopo_app_marketplace_native_add_app_id() {
  local app_id="$1"
  local legacy_app_id
  mkdir -p /home/docker
  touch /home/docker/appno.txt
  while IFS= read -r legacy_app_id; do
    [[ -z "$legacy_app_id" ]] && continue
    sed -i "/\b${legacy_app_id}\b/d" /home/docker/appno.txt
  done < <(luopo_app_marketplace_legacy_numbers "$app_id")
  grep -qxF "$app_id" /home/docker/appno.txt || printf '%s\n' "$app_id" >> /home/docker/appno.txt
}

luopo_app_marketplace_native_remove_app_id() {
  local app_id="$1"
  local legacy_app_id
  if [[ -f /home/docker/appno.txt ]]; then
    sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
    while IFS= read -r legacy_app_id; do
      [[ -z "$legacy_app_id" ]] && continue
      sed -i "/\b${legacy_app_id}\b/d" /home/docker/appno.txt
    done < <(luopo_app_marketplace_legacy_numbers "$app_id")
  fi
}

luopo_app_marketplace_native_prompt_port() {
  local default_port="$1"
  local selected_port
  while true; do
    read -r -p "输入应用对外服务端口，回车默认使用${default_port}端口: " selected_port
    selected_port="${selected_port:-$default_port}"
    if ss -tuln | grep -q ":${selected_port} "; then
      echo -e "${gl_hong}错误: ${gl_bai}端口 ${selected_port} 已被占用，请更换一个端口"
    else
      printf '%s\n' "$selected_port"
      return 0
    fi
  done
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
  install jq
  install_docker
  mkdir -p /home/docker
}

luopo_app_marketplace_native_repo_sync() {
  local repo_url="$1"
  local target_dir="$2"

  if [[ -d "${target_dir}/.git" ]]; then
    git -C "$target_dir" fetch --depth 1 origin
    git -C "$target_dir" reset --hard FETCH_HEAD
  else
    rm -rf "$target_dir"
    git clone --depth 1 "$repo_url" "$target_dir"
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
    printf '%s=%s\n' "$key" "$value" >> "$env_file"
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
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        app_port="$(luopo_app_marketplace_native_prompt_port "$default_port")"
        luopo_app_marketplace_native_install_docker_runtime
        "$install_fn" "$app_port"
        luopo_app_marketplace_native_app_store_port "$container_name" "$app_port"
        luopo_app_marketplace_native_add_app_id "$app_id"
        clear
        echo "${app_name} 已安装完成"
        luopo_app_marketplace_native_show_access "$container_name" "$app_port"
        if [[ -n "$post_install_fn" ]]; then
          "$post_install_fn"
        fi
        send_stats "安装${app_name}"
        ;;
      2)
        app_port="$(luopo_app_marketplace_native_app_effective_port "$container_name" || true)"
        if [[ -z "$app_port" ]]; then
          app_port="$default_port"
        fi
        luopo_app_marketplace_native_install_docker_runtime
        "$update_fn" "$app_port"
        luopo_app_marketplace_native_app_store_port "$container_name" "$app_port"
        luopo_app_marketplace_native_add_app_id "$app_id"
        clear
        echo "${app_name} 已更新完成"
        luopo_app_marketplace_native_show_access "$container_name" "$app_port"
        if [[ -n "$post_install_fn" ]]; then
          "$post_install_fn"
        fi
        send_stats "更新${app_name}"
        ;;
      3)
        "$uninstall_fn"
        rm -f "$(luopo_app_marketplace_native_app_port_file "$container_name")"
        luopo_app_marketplace_native_remove_app_id "$app_id"
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
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        luopo_app_marketplace_native_install_docker_runtime
        "$install_fn"
        luopo_app_marketplace_native_add_app_id "$app_id"
        [[ -n "$post_fn" ]] && "$post_fn"
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        "$update_fn"
        luopo_app_marketplace_native_add_app_id "$app_id"
        [[ -n "$post_fn" ]] && "$post_fn"
        ;;
      3)
        "$uninstall_fn"
        luopo_app_marketplace_native_remove_app_id "$app_id"
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
