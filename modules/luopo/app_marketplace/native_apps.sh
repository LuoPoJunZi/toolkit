#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_NATIVE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  mkdir -p /home/docker
  touch /home/docker/appno.txt
  grep -qxF "$app_id" /home/docker/appno.txt || printf '%s\n' "$app_id" >> /home/docker/appno.txt
}

luopo_app_marketplace_native_remove_app_id() {
  local app_id="$1"
  if [[ -f /home/docker/appno.txt ]]; then
    sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
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
  ip_address

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

luopo_app_marketplace_native_proxy_add() {
  local container_name="$1"
  local app_port="$2"
  echo "${container_name} 域名访问设置"
  add_yuming
  ldnmp_Proxy "${yuming}" 127.0.0.1 "${app_port}"
  block_container_port "$container_name" "$ipv4_address"
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
  web_del "$target_domain"
  clear_container_rules "$container_name" "$ipv4_address"
  echo "已删除域名访问: ${target_domain}"
}

luopo_app_marketplace_native_ip_allow() {
  local container_name="$1"
  clear_container_rules "$container_name" "$ipv4_address"
  echo "已允许 ${container_name} 的 IP+端口访问"
}

luopo_app_marketplace_native_ip_block() {
  local container_name="$1"
  block_container_port "$container_name" "$ipv4_address"
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

luopo_app_marketplace_portainer_install() {
  local app_port="$1"
  docker rm -f portainer >/dev/null 2>&1 || true
  docker run -d \
    --name portainer \
    -p "${app_port}:9000" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /home/docker/portainer:/data \
    --restart=always \
    portainer/portainer
}

luopo_app_marketplace_portainer_update() {
  local app_port="$1"
  docker rm -f portainer >/dev/null 2>&1 || true
  docker rmi -f portainer/portainer >/dev/null 2>&1 || true
  luopo_app_marketplace_portainer_install "$app_port"
}

luopo_app_marketplace_portainer_uninstall() {
  docker rm -f portainer >/dev/null 2>&1 || true
  docker rmi -f portainer/portainer >/dev/null 2>&1 || true
  rm -rf /home/docker/portainer
  echo "应用已卸载"
}

luopo_app_marketplace_portainer_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "20" \
    "portainer容器管理面板" \
    "portainer" \
    "portainer/portainer" \
    "8020" \
    "portainer 是一个轻量级的 Docker 容器管理面板" \
    "官网介绍: https://www.portainer.io/" \
    "luopo_app_marketplace_portainer_install" \
    "luopo_app_marketplace_portainer_update" \
    "luopo_app_marketplace_portainer_uninstall"
}

luopo_app_marketplace_uptime_kuma_install() {
  local app_port="$1"
  docker rm -f uptime-kuma >/dev/null 2>&1 || true
  docker run -d \
    --name uptime-kuma \
    -p "${app_port}:3001" \
    -v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
    --restart=always \
    louislam/uptime-kuma:latest
}

luopo_app_marketplace_uptime_kuma_update() {
  local app_port="$1"
  docker rm -f uptime-kuma >/dev/null 2>&1 || true
  docker rmi -f louislam/uptime-kuma:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_uptime_kuma_install "$app_port"
}

luopo_app_marketplace_uptime_kuma_uninstall() {
  docker rm -f uptime-kuma >/dev/null 2>&1 || true
  docker rmi -f louislam/uptime-kuma:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/uptime-kuma
  echo "应用已卸载"
}

luopo_app_marketplace_uptime_kuma_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "22" \
    "UptimeKuma监控工具" \
    "uptime-kuma" \
    "louislam/uptime-kuma:latest" \
    "8022" \
    "Uptime Kuma 易于使用的自托管监控工具" \
    "官网介绍: https://github.com/louislam/uptime-kuma" \
    "luopo_app_marketplace_uptime_kuma_install" \
    "luopo_app_marketplace_uptime_kuma_update" \
    "luopo_app_marketplace_uptime_kuma_uninstall"
}

luopo_app_marketplace_ddns_go_install() {
  local app_port="$1"
  docker rm -f ddns-go >/dev/null 2>&1 || true
  docker run -d \
    --name ddns-go \
    --restart=always \
    -p "${app_port}:9876" \
    -v /home/docker/ddns-go:/root \
    jeessy/ddns-go
}

luopo_app_marketplace_ddns_go_update() {
  local app_port="$1"
  docker rm -f ddns-go >/dev/null 2>&1 || true
  docker rmi -f jeessy/ddns-go >/dev/null 2>&1 || true
  luopo_app_marketplace_ddns_go_install "$app_port"
}

luopo_app_marketplace_ddns_go_uninstall() {
  docker rm -f ddns-go >/dev/null 2>&1 || true
  docker rmi -f jeessy/ddns-go >/dev/null 2>&1 || true
  rm -rf /home/docker/ddns-go
  echo "应用已卸载"
}

luopo_app_marketplace_ddns_go_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "67" \
    "ddns-go动态DNS管理工具" \
    "ddns-go" \
    "jeessy/ddns-go" \
    "8067" \
    "自动将公网 IP（IPv4/IPv6）实时更新到各大 DNS 服务商，实现动态域名解析。" \
    "官网介绍: https://github.com/jeessy2/ddns-go" \
    "luopo_app_marketplace_ddns_go_install" \
    "luopo_app_marketplace_ddns_go_update" \
    "luopo_app_marketplace_ddns_go_uninstall"
}

luopo_app_marketplace_filebrowser_install() {
  local app_port="$1"
  docker rm -f filebrowser >/dev/null 2>&1 || true
  docker run -d \
    --name filebrowser \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/filebrowser/data:/data \
    -v /home/docker/filebrowser/config:/config \
    -e FB_BASEURL=/filebrowser \
    hurlenko/filebrowser
}

luopo_app_marketplace_filebrowser_update() {
  local app_port="$1"
  docker rm -f filebrowser >/dev/null 2>&1 || true
  docker rmi -f hurlenko/filebrowser >/dev/null 2>&1 || true
  luopo_app_marketplace_filebrowser_install "$app_port"
}

luopo_app_marketplace_filebrowser_uninstall() {
  docker rm -f filebrowser >/dev/null 2>&1 || true
  docker rmi -f hurlenko/filebrowser >/dev/null 2>&1 || true
  rm -rf /home/docker/filebrowser
  echo "应用已卸载"
}

luopo_app_marketplace_filebrowser_post_install() {
  echo "查看日志命令: docker logs filebrowser"
}

luopo_app_marketplace_filebrowser_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "92" \
    "FileBrowser文件管理器" \
    "filebrowser" \
    "hurlenko/filebrowser" \
    "8092" \
    "基于 Web 的文件管理器，适合做轻量文件浏览与管理。" \
    "官网介绍: https://filebrowser.org/" \
    "luopo_app_marketplace_filebrowser_install" \
    "luopo_app_marketplace_filebrowser_update" \
    "luopo_app_marketplace_filebrowser_uninstall" \
    "luopo_app_marketplace_filebrowser_post_install"
}
