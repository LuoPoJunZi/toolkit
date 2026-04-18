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
    "8" \
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
    "10" \
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

luopo_app_marketplace_memos_install() {
  local app_port="$1"
  docker rm -f memos >/dev/null 2>&1 || true
  docker run -d \
    --name memos \
    -p "${app_port}:5230" \
    -v /home/docker/memos:/var/opt/memos \
    --restart=always \
    neosmemo/memos:stable
}

luopo_app_marketplace_memos_update() {
  local app_port="$1"
  docker rm -f memos >/dev/null 2>&1 || true
  docker rmi -f neosmemo/memos:stable >/dev/null 2>&1 || true
  luopo_app_marketplace_memos_install "$app_port"
}

luopo_app_marketplace_memos_uninstall() {
  docker rm -f memos >/dev/null 2>&1 || true
  docker rmi -f neosmemo/memos:stable >/dev/null 2>&1 || true
  rm -rf /home/docker/memos
  echo "应用已卸载"
}

luopo_app_marketplace_memos_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "20" \
    "Memos网页备忘录" \
    "memos" \
    "neosmemo/memos:stable" \
    "8023" \
    "Memos 是一款轻量级、自托管的备忘录中心。" \
    "官网介绍: https://github.com/usememos/memos" \
    "luopo_app_marketplace_memos_install" \
    "luopo_app_marketplace_memos_update" \
    "luopo_app_marketplace_memos_uninstall"
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
    "46" \
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

luopo_app_marketplace_navidrome_install() {
  local app_port="$1"
  mkdir -p /home/docker/navidrome/music /home/docker/navidrome/data
  docker rm -f navidrome >/dev/null 2>&1 || true
  docker run -d \
    --name navidrome \
    --restart=always \
    --user "$(id -u):$(id -g)" \
    -v /home/docker/navidrome/music:/music \
    -v /home/docker/navidrome/data:/data \
    -p "${app_port}:4533" \
    -e ND_LOGLEVEL=info \
    deluan/navidrome:latest
}

luopo_app_marketplace_navidrome_update() {
  local app_port="$1"
  docker rm -f navidrome >/dev/null 2>&1 || true
  docker rmi -f deluan/navidrome:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_navidrome_install "$app_port"
}

luopo_app_marketplace_navidrome_uninstall() {
  docker rm -f navidrome >/dev/null 2>&1 || true
  docker rmi -f deluan/navidrome:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/navidrome
  echo "应用已卸载"
}

luopo_app_marketplace_navidrome_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "48" \
    "Navidrome私有音乐服务器" \
    "navidrome" \
    "deluan/navidrome:latest" \
    "8071" \
    "轻量、高性能的私有音乐流媒体服务器。" \
    "官网介绍: https://www.navidrome.org/" \
    "luopo_app_marketplace_navidrome_install" \
    "luopo_app_marketplace_navidrome_update" \
    "luopo_app_marketplace_navidrome_uninstall"
}

luopo_app_marketplace_beszel_install() {
  local app_port="$1"
  mkdir -p /home/docker/beszel
  docker rm -f beszel >/dev/null 2>&1 || true
  docker run -d \
    --name beszel \
    --restart=always \
    -v /home/docker/beszel:/beszel_data \
    -p "${app_port}:8090" \
    henrygd/beszel
}

luopo_app_marketplace_beszel_update() {
  local app_port="$1"
  docker rm -f beszel >/dev/null 2>&1 || true
  docker rmi -f henrygd/beszel >/dev/null 2>&1 || true
  luopo_app_marketplace_beszel_install "$app_port"
}

luopo_app_marketplace_beszel_uninstall() {
  docker rm -f beszel >/dev/null 2>&1 || true
  docker rmi -f henrygd/beszel >/dev/null 2>&1 || true
  rm -rf /home/docker/beszel
  echo "应用已卸载"
}

luopo_app_marketplace_beszel_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "60" \
    "Beszel服务器监控" \
    "beszel" \
    "henrygd/beszel" \
    "8079" \
    "Beszel 轻量易用的服务器监控工具。" \
    "官网介绍: https://beszel.dev/zh/" \
    "luopo_app_marketplace_beszel_install" \
    "luopo_app_marketplace_beszel_update" \
    "luopo_app_marketplace_beszel_uninstall"
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
    "67" \
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

luopo_app_marketplace_searxng_install() {
  local app_port="$1"
  mkdir -p /home/docker/searxng
  docker rm -f searxng >/dev/null 2>&1 || true
  docker run -d \
    --name searxng \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/searxng:/etc/searxng \
    searxng/searxng
}

luopo_app_marketplace_searxng_update() {
  local app_port="$1"
  docker rm -f searxng >/dev/null 2>&1 || true
  docker rmi -f searxng/searxng >/dev/null 2>&1 || true
  luopo_app_marketplace_searxng_install "$app_port"
}

luopo_app_marketplace_searxng_uninstall() {
  docker rm -f searxng >/dev/null 2>&1 || true
  docker rmi -f searxng/searxng >/dev/null 2>&1 || true
  rm -rf /home/docker/searxng
  echo "应用已卸载"
}

luopo_app_marketplace_searxng_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "23" \
    "searxng聚合搜索站" \
    "searxng" \
    "searxng/searxng" \
    "8029" \
    "searxng 是一个私有、注重隐私的聚合搜索引擎。" \
    "官网介绍: https://docs.searxng.org/" \
    "luopo_app_marketplace_searxng_install" \
    "luopo_app_marketplace_searxng_update" \
    "luopo_app_marketplace_searxng_uninstall"
}

luopo_app_marketplace_komari_install() {
  local app_port="$1"
  mkdir -p /home/docker/komari
  docker rm -f komari >/dev/null 2>&1 || true
  docker run -d \
    --name komari \
    -p "${app_port}:25774" \
    -v /home/docker/komari:/app/data \
    -e ADMIN_USERNAME=admin \
    -e ADMIN_PASSWORD=1212156 \
    -e TZ=Asia/Shanghai \
    --restart=always \
    ghcr.io/komari-monitor/komari:latest
}

luopo_app_marketplace_komari_update() {
  local app_port="$1"
  docker rm -f komari >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/komari-monitor/komari:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_komari_install "$app_port"
}

luopo_app_marketplace_komari_uninstall() {
  docker rm -f komari >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/komari-monitor/komari:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/komari
  echo "应用已卸载"
}

luopo_app_marketplace_komari_post_install() {
  echo "默认账号: admin"
  echo "默认密码: 1212156"
}

luopo_app_marketplace_komari_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "63" \
    "komari服务器监控工具" \
    "komari" \
    "ghcr.io/komari-monitor/komari:latest" \
    "8083" \
    "Komari 是轻量级的自托管服务器监控工具。" \
    "官网介绍: https://github.com/komari-monitor/komari" \
    "luopo_app_marketplace_komari_install" \
    "luopo_app_marketplace_komari_update" \
    "luopo_app_marketplace_komari_uninstall" \
    "luopo_app_marketplace_komari_post_install"
}

luopo_app_marketplace_jellyfin_install() {
  local app_port="$1"
  mkdir -p /home/docker/jellyfin/config /home/docker/jellyfin/cache /home/docker/jellyfin/media
  chmod -R 777 /home/docker/jellyfin
  docker rm -f jellyfin >/dev/null 2>&1 || true
  docker run -d \
    --name jellyfin \
    --user root \
    --volume /home/docker/jellyfin/config:/config \
    --volume /home/docker/jellyfin/cache:/cache \
    --mount type=bind,source=/home/docker/jellyfin/media,target=/media \
    -p "${app_port}:8096" \
    -p 7359:7359/udp \
    --restart=always \
    jellyfin/jellyfin
}

luopo_app_marketplace_jellyfin_update() {
  local app_port="$1"
  docker rm -f jellyfin >/dev/null 2>&1 || true
  docker rmi -f jellyfin/jellyfin >/dev/null 2>&1 || true
  luopo_app_marketplace_jellyfin_install "$app_port"
}

luopo_app_marketplace_jellyfin_uninstall() {
  docker rm -f jellyfin >/dev/null 2>&1 || true
  docker rmi -f jellyfin/jellyfin >/dev/null 2>&1 || true
  rm -rf /home/docker/jellyfin
  echo "应用已卸载"
}

luopo_app_marketplace_jellyfin_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "65" \
    "jellyfin媒体管理系统" \
    "jellyfin" \
    "jellyfin/jellyfin" \
    "8086" \
    "Jellyfin 是一款开源媒体服务器软件。" \
    "官网介绍: https://jellyfin.org/" \
    "luopo_app_marketplace_jellyfin_install" \
    "luopo_app_marketplace_jellyfin_update" \
    "luopo_app_marketplace_jellyfin_uninstall"
}

luopo_app_marketplace_zfile_install() {
  local app_port="$1"
  mkdir -p /home/docker/zfile/db /home/docker/zfile/logs /home/docker/zfile/file
  touch /home/docker/zfile/application.properties
  docker rm -f zfile >/dev/null 2>&1 || true
  docker run -d \
    --name=zfile \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/zfile/db:/root/.zfile-v4/db \
    -v /home/docker/zfile/logs:/root/.zfile-v4/logs \
    -v /home/docker/zfile/file:/data/file \
    -v /home/docker/zfile/application.properties:/root/.zfile-v4/application.properties \
    zhaojun1998/zfile:latest
}

luopo_app_marketplace_zfile_update() {
  local app_port="$1"
  docker rm -f zfile >/dev/null 2>&1 || true
  docker rmi -f zhaojun1998/zfile:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_zfile_install "$app_port"
}

luopo_app_marketplace_zfile_uninstall() {
  docker rm -f zfile >/dev/null 2>&1 || true
  docker rmi -f zhaojun1998/zfile:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/zfile
  echo "应用已卸载"
}

luopo_app_marketplace_zfile_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "83" \
    "ZFile在线网盘" \
    "zfile" \
    "zhaojun1998/zfile:latest" \
    "8109" \
    "ZFile 是适合个人或小团队的在线网盘程序。" \
    "官网介绍: https://github.com/zfile-dev/zfile" \
    "luopo_app_marketplace_zfile_install" \
    "luopo_app_marketplace_zfile_update" \
    "luopo_app_marketplace_zfile_uninstall"
}

luopo_app_marketplace_librespeed_install() {
  local app_port="$1"
  docker rm -f speedtest >/dev/null 2>&1 || true
  docker run -d \
    --name speedtest \
    --restart=always \
    -p "${app_port}:8080" \
    ghcr.io/librespeed/speedtest
}

luopo_app_marketplace_librespeed_update() {
  local app_port="$1"
  docker rm -f speedtest >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/librespeed/speedtest >/dev/null 2>&1 || true
  luopo_app_marketplace_librespeed_install "$app_port"
}

luopo_app_marketplace_librespeed_uninstall() {
  docker rm -f speedtest >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/librespeed/speedtest >/dev/null 2>&1 || true
  echo "应用已卸载"
}

luopo_app_marketplace_librespeed_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "22" \
    "LibreSpeed测速工具" \
    "speedtest" \
    "ghcr.io/librespeed/speedtest" \
    "8028" \
    "LibreSpeed 是用 JavaScript 实现的轻量级测速工具，即开即用。" \
    "官网介绍: https://github.com/librespeed/speedtest" \
    "luopo_app_marketplace_librespeed_install" \
    "luopo_app_marketplace_librespeed_update" \
    "luopo_app_marketplace_librespeed_uninstall"
}

luopo_app_marketplace_stirling_pdf_install() {
  local app_port="$1"
  mkdir -p /home/docker/s-pdf/trainingData /home/docker/s-pdf/extraConfigs /home/docker/s-pdf/logs
  docker rm -f s-pdf >/dev/null 2>&1 || true
  docker run -d \
    --name s-pdf \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/s-pdf/trainingData:/usr/share/tesseract-ocr/5/tessdata \
    -v /home/docker/s-pdf/extraConfigs:/configs \
    -v /home/docker/s-pdf/logs:/logs \
    -e DOCKER_ENABLE_SECURITY=false \
    frooodle/s-pdf:latest
}

luopo_app_marketplace_stirling_pdf_update() {
  local app_port="$1"
  docker rm -f s-pdf >/dev/null 2>&1 || true
  docker rmi -f frooodle/s-pdf:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_stirling_pdf_install "$app_port"
}

luopo_app_marketplace_stirling_pdf_uninstall() {
  docker rm -f s-pdf >/dev/null 2>&1 || true
  docker rmi -f frooodle/s-pdf:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/s-pdf
  echo "应用已卸载"
}

luopo_app_marketplace_stirling_pdf_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "24" \
    "StirlingPDF工具大全" \
    "s-pdf" \
    "frooodle/s-pdf:latest" \
    "8031" \
    "强大的本地托管 PDF 操作工具，支持拆分、合并、转换、压缩等。" \
    "官网介绍: https://github.com/Stirling-Tools/Stirling-PDF" \
    "luopo_app_marketplace_stirling_pdf_install" \
    "luopo_app_marketplace_stirling_pdf_update" \
    "luopo_app_marketplace_stirling_pdf_uninstall"
}

luopo_app_marketplace_drawio_install() {
  local app_port="$1"
  mkdir -p /home/docker/drawio
  docker rm -f drawio >/dev/null 2>&1 || true
  docker run -d \
    --name drawio \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/drawio:/var/lib/drawio \
    jgraph/drawio
}

luopo_app_marketplace_drawio_update() {
  local app_port="$1"
  docker rm -f drawio >/dev/null 2>&1 || true
  docker rmi -f jgraph/drawio >/dev/null 2>&1 || true
  luopo_app_marketplace_drawio_install "$app_port"
}

luopo_app_marketplace_drawio_uninstall() {
  docker rm -f drawio >/dev/null 2>&1 || true
  docker rmi -f jgraph/drawio >/dev/null 2>&1 || true
  rm -rf /home/docker/drawio
  echo "应用已卸载"
}

luopo_app_marketplace_drawio_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "25" \
    "drawio免费的在线图表软件" \
    "drawio" \
    "jgraph/drawio" \
    "8032" \
    "强大的在线图表绘制软件，支持思维导图、拓扑图和流程图。" \
    "官网介绍: https://www.drawio.com/" \
    "luopo_app_marketplace_drawio_install" \
    "luopo_app_marketplace_drawio_update" \
    "luopo_app_marketplace_drawio_uninstall"
}

luopo_app_marketplace_it_tools_install() {
  local app_port="$1"
  docker rm -f it-tools >/dev/null 2>&1 || true
  docker run -d \
    --name it-tools \
    --restart=always \
    -p "${app_port}:80" \
    corentinth/it-tools:latest
}

luopo_app_marketplace_it_tools_update() {
  local app_port="$1"
  docker rm -f it-tools >/dev/null 2>&1 || true
  docker rmi -f corentinth/it-tools:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_it_tools_install "$app_port"
}

luopo_app_marketplace_it_tools_uninstall() {
  docker rm -f it-tools >/dev/null 2>&1 || true
  docker rmi -f corentinth/it-tools:latest >/dev/null 2>&1 || true
  echo "应用已卸载"
}

luopo_app_marketplace_it_tools_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "44" \
    "it-tools工具箱" \
    "it-tools" \
    "corentinth/it-tools:latest" \
    "8064" \
    "面向开发者和 IT 工作者的实用工具合集。" \
    "官网介绍: https://github.com/CorentinTh/it-tools" \
    "luopo_app_marketplace_it_tools_install" \
    "luopo_app_marketplace_it_tools_update" \
    "luopo_app_marketplace_it_tools_uninstall"
}

luopo_app_marketplace_dufs_install() {
  local app_port="$1"
  mkdir -p /home/docker/dufs
  docker rm -f dufs >/dev/null 2>&1 || true
  docker run -d \
    --name dufs \
    --restart=always \
    -v /home/docker/dufs:/data \
    -p "${app_port}:5000" \
    sigoden/dufs /data -A
}

luopo_app_marketplace_dufs_update() {
  local app_port="$1"
  docker rm -f dufs >/dev/null 2>&1 || true
  docker rmi -f sigoden/dufs >/dev/null 2>&1 || true
  luopo_app_marketplace_dufs_install "$app_port"
}

luopo_app_marketplace_dufs_uninstall() {
  docker rm -f dufs >/dev/null 2>&1 || true
  docker rmi -f sigoden/dufs >/dev/null 2>&1 || true
  rm -rf /home/docker/dufs
  echo "应用已卸载"
}

luopo_app_marketplace_dufs_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "68" \
    "Dufs极简静态文件服务器" \
    "dufs" \
    "sigoden/dufs" \
    "8093" \
    "极简静态文件服务器，支持文件上传和下载。" \
    "官网介绍: https://github.com/sigoden/dufs" \
    "luopo_app_marketplace_dufs_install" \
    "luopo_app_marketplace_dufs_update" \
    "luopo_app_marketplace_dufs_uninstall"
}

luopo_app_marketplace_syncthing_install() {
  local app_port="$1"
  mkdir -p /home/docker/syncthing
  docker rm -f syncthing >/dev/null 2>&1 || true
  docker run -d \
    --name=syncthing \
    --hostname=my-syncthing \
    --restart=always \
    -p "${app_port}:8384" \
    -p 22000:22000/tcp \
    -p 22000:22000/udp \
    -p 21027:21027/udp \
    -v /home/docker/syncthing:/var/syncthing \
    syncthing/syncthing:latest
}

luopo_app_marketplace_syncthing_update() {
  local app_port="$1"
  docker rm -f syncthing >/dev/null 2>&1 || true
  docker rmi -f syncthing/syncthing:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_syncthing_install "$app_port"
}

luopo_app_marketplace_syncthing_uninstall() {
  docker rm -f syncthing >/dev/null 2>&1 || true
  docker rmi -f syncthing/syncthing:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/syncthing
  echo "应用已卸载"
}

luopo_app_marketplace_syncthing_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "80" \
    "Syncthing点对点文件同步工具" \
    "syncthing" \
    "syncthing/syncthing:latest" \
    "8100" \
    "开源点对点文件同步工具，完全去中心化。" \
    "官网介绍: https://github.com/syncthing/syncthing" \
    "luopo_app_marketplace_syncthing_install" \
    "luopo_app_marketplace_syncthing_update" \
    "luopo_app_marketplace_syncthing_uninstall"
}

luopo_app_marketplace_npm_install() {
  local app_port="$1"
  mkdir -p /home/docker/npm/data /home/docker/npm/letsencrypt
  docker rm -f npm >/dev/null 2>&1 || true
  docker run -d \
    --name=npm \
    --restart=always \
    -p "${app_port}:81" \
    -p 80:80 \
    -p 443:443 \
    -v /home/docker/npm/data:/data \
    -v /home/docker/npm/letsencrypt:/etc/letsencrypt \
    jc21/nginx-proxy-manager:latest
}

luopo_app_marketplace_npm_update() {
  local app_port="$1"
  docker rm -f npm >/dev/null 2>&1 || true
  docker rmi -f jc21/nginx-proxy-manager:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_npm_install "$app_port"
}

luopo_app_marketplace_npm_uninstall() {
  docker rm -f npm >/dev/null 2>&1 || true
  docker rmi -f jc21/nginx-proxy-manager:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/npm
  echo "应用已卸载"
}

luopo_app_marketplace_npm_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "2" \
    "NginxProxyManager可视化面板" \
    "npm" \
    "jc21/nginx-proxy-manager:latest" \
    "81" \
    "可视化反向代理与证书管理面板。" \
    "官网介绍: https://nginxproxymanager.com/" \
    "luopo_app_marketplace_npm_install" \
    "luopo_app_marketplace_npm_update" \
    "luopo_app_marketplace_npm_uninstall"
}

luopo_app_marketplace_openlist_install() {
  local app_port="$1"
  mkdir -p /home/docker/openlist
  chmod -R 777 /home/docker/openlist
  docker rm -f openlist >/dev/null 2>&1 || true
  docker run -d \
    --name openlist \
    --restart=always \
    -v /home/docker/openlist:/opt/openlist/data \
    -p "${app_port}:5244" \
    openlistteam/openlist:latest-aria2
}

luopo_app_marketplace_openlist_update() {
  local app_port="$1"
  docker rm -f openlist >/dev/null 2>&1 || true
  docker rmi -f openlistteam/openlist:latest-aria2 >/dev/null 2>&1 || true
  luopo_app_marketplace_openlist_install "$app_port"
}

luopo_app_marketplace_openlist_uninstall() {
  docker rm -f openlist >/dev/null 2>&1 || true
  docker rmi -f openlistteam/openlist:latest-aria2 >/dev/null 2>&1 || true
  rm -rf /home/docker/openlist
  echo "应用已卸载"
}

luopo_app_marketplace_openlist_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "3" \
    "OpenList多存储文件列表程序" \
    "openlist" \
    "openlistteam/openlist:latest-aria2" \
    "5244" \
    "支持多种存储后端的文件列表与网盘程序。" \
    "官网介绍: https://github.com/OpenListTeam/OpenList" \
    "luopo_app_marketplace_openlist_install" \
    "luopo_app_marketplace_openlist_update" \
    "luopo_app_marketplace_openlist_uninstall"
}

luopo_app_marketplace_qinglong_install() {
  local app_port="$1"
  mkdir -p /home/docker/qinglong/data
  docker rm -f qinglong >/dev/null 2>&1 || true
  docker run -d \
    --name qinglong \
    --hostname qinglong \
    --restart=always \
    -v /home/docker/qinglong/data:/ql/data \
    -p "${app_port}:5700" \
    whyour/qinglong:latest
}

luopo_app_marketplace_qinglong_update() {
  local app_port="$1"
  docker rm -f qinglong >/dev/null 2>&1 || true
  docker rmi -f whyour/qinglong:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_qinglong_install "$app_port"
}

luopo_app_marketplace_qinglong_uninstall() {
  docker rm -f qinglong >/dev/null 2>&1 || true
  docker rmi -f whyour/qinglong:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/qinglong
  echo "应用已卸载"
}

luopo_app_marketplace_qinglong_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "5" \
    "青龙面板定时任务管理平台" \
    "qinglong" \
    "whyour/qinglong:latest" \
    "5700" \
    "青龙面板是常用的定时任务管理平台。" \
    "官网介绍: https://github.com/whyour/qinglong" \
    "luopo_app_marketplace_qinglong_install" \
    "luopo_app_marketplace_qinglong_update" \
    "luopo_app_marketplace_qinglong_uninstall"
}

luopo_app_marketplace_adguardhome_install() {
  local app_port="$1"
  mkdir -p /home/docker/adguardhome/work /home/docker/adguardhome/conf
  docker rm -f adguardhome >/dev/null 2>&1 || true
  docker run -d \
    --name adguardhome \
    --restart=always \
    -v /home/docker/adguardhome/work:/opt/adguardhome/work \
    -v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
    -p 53:53/tcp \
    -p 53:53/udp \
    -p "${app_port}:3000/tcp" \
    adguard/adguardhome
}

luopo_app_marketplace_adguardhome_update() {
  local app_port="$1"
  docker rm -f adguardhome >/dev/null 2>&1 || true
  docker rmi -f adguard/adguardhome >/dev/null 2>&1 || true
  luopo_app_marketplace_adguardhome_install "$app_port"
}

luopo_app_marketplace_adguardhome_uninstall() {
  docker rm -f adguardhome >/dev/null 2>&1 || true
  docker rmi -f adguard/adguardhome >/dev/null 2>&1 || true
  rm -rf /home/docker/adguardhome
  echo "应用已卸载"
}

luopo_app_marketplace_adguardhome_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "6" \
    "AdGuardHome去广告软件" \
    "adguardhome" \
    "adguard/adguardhome" \
    "8017" \
    "网络级广告拦截与 DNS 管理工具。" \
    "官网介绍: https://github.com/AdguardTeam/AdGuardHome" \
    "luopo_app_marketplace_adguardhome_install" \
    "luopo_app_marketplace_adguardhome_update" \
    "luopo_app_marketplace_adguardhome_uninstall"
}

luopo_app_marketplace_vscode_install() {
  local app_port="$1"
  mkdir -p /home/docker/vscode-web
  docker rm -f vscode-web >/dev/null 2>&1 || true
  docker run -d \
    --name vscode-web \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/vscode-web:/home/coder/.local/share/code-server \
    codercom/code-server
}

luopo_app_marketplace_vscode_update() {
  local app_port="$1"
  docker rm -f vscode-web >/dev/null 2>&1 || true
  docker rmi -f codercom/code-server >/dev/null 2>&1 || true
  luopo_app_marketplace_vscode_install "$app_port"
}

luopo_app_marketplace_vscode_uninstall() {
  docker rm -f vscode-web >/dev/null 2>&1 || true
  docker rmi -f codercom/code-server >/dev/null 2>&1 || true
  rm -rf /home/docker/vscode-web
  echo "应用已卸载"
}

luopo_app_marketplace_vscode_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "9" \
    "VScode网页版" \
    "vscode-web" \
    "codercom/code-server" \
    "8021" \
    "强大的在线代码编辑工具。" \
    "官网介绍: https://github.com/coder/code-server" \
    "luopo_app_marketplace_vscode_install" \
    "luopo_app_marketplace_vscode_update" \
    "luopo_app_marketplace_vscode_uninstall"
}

luopo_app_marketplace_dockge_install() {
  local app_port="$1"
  mkdir -p /home/docker/dockge/data /home/docker/dockge/stacks
  docker rm -f dockge >/dev/null 2>&1 || true
  docker run -d \
    --name dockge \
    --restart=always \
    -p "${app_port}:5001" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /home/docker/dockge/data:/app/data \
    -v /home/docker/dockge/stacks:/home/docker/dockge/stacks \
    -e DOCKGE_STACKS_DIR=/home/docker/dockge/stacks \
    louislam/dockge
}

luopo_app_marketplace_dockge_update() {
  local app_port="$1"
  docker rm -f dockge >/dev/null 2>&1 || true
  docker rmi -f louislam/dockge >/dev/null 2>&1 || true
  luopo_app_marketplace_dockge_install "$app_port"
}

luopo_app_marketplace_dockge_uninstall() {
  docker rm -f dockge >/dev/null 2>&1 || true
  docker rmi -f louislam/dockge >/dev/null 2>&1 || true
  rm -rf /home/docker/dockge
  echo "应用已卸载"
}

luopo_app_marketplace_dockge_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "21" \
    "Dockge容器堆栈管理面板" \
    "dockge" \
    "louislam/dockge" \
    "8027" \
    "可视化 docker-compose 容器堆栈管理面板。" \
    "官网介绍: https://github.com/louislam/dockge" \
    "luopo_app_marketplace_dockge_install" \
    "luopo_app_marketplace_dockge_update" \
    "luopo_app_marketplace_dockge_uninstall"
}

luopo_app_marketplace_myip_install() {
  local app_port="$1"
  docker rm -f myip >/dev/null 2>&1 || true
  docker run -d \
    --name myip \
    --restart=always \
    -p "${app_port}:18966" \
    jason5ng32/myip:latest
}

luopo_app_marketplace_myip_update() {
  local app_port="$1"
  docker rm -f myip >/dev/null 2>&1 || true
  docker rmi -f jason5ng32/myip:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_myip_install "$app_port"
}

luopo_app_marketplace_myip_uninstall() {
  docker rm -f myip >/dev/null 2>&1 || true
  docker rmi -f jason5ng32/myip:latest >/dev/null 2>&1 || true
  echo "应用已卸载"
}

luopo_app_marketplace_myip_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "26" \
    "MyIP工具箱" \
    "myip" \
    "jason5ng32/myip:latest" \
    "8037" \
    "多功能 IP 工具箱，可查看 IP 信息与网络连通性。" \
    "官网介绍: https://github.com/jason5ng32/MyIP" \
    "luopo_app_marketplace_myip_install" \
    "luopo_app_marketplace_myip_update" \
    "luopo_app_marketplace_myip_uninstall"
}

luopo_app_marketplace_bitwarden_install() {
  local app_port="$1"
  mkdir -p /home/docker/bitwarden/data
  docker rm -f bitwarden >/dev/null 2>&1 || true
  docker run -d \
    --name bitwarden \
    --restart=always \
    -p "${app_port}:80" \
    -v /home/docker/bitwarden/data:/data \
    vaultwarden/server
}

luopo_app_marketplace_bitwarden_update() {
  local app_port="$1"
  docker rm -f bitwarden >/dev/null 2>&1 || true
  docker rmi -f vaultwarden/server >/dev/null 2>&1 || true
  luopo_app_marketplace_bitwarden_install "$app_port"
}

luopo_app_marketplace_bitwarden_uninstall() {
  docker rm -f bitwarden >/dev/null 2>&1 || true
  docker rmi -f vaultwarden/server >/dev/null 2>&1 || true
  rm -rf /home/docker/bitwarden
  echo "应用已卸载"
}

luopo_app_marketplace_bitwarden_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "49" \
    "bitwarden密码管理器" \
    "bitwarden" \
    "vaultwarden/server" \
    "8072" \
    "你可以完全控制数据的自托管密码管理器。" \
    "官网介绍: https://bitwarden.com/" \
    "luopo_app_marketplace_bitwarden_install" \
    "luopo_app_marketplace_bitwarden_update" \
    "luopo_app_marketplace_bitwarden_uninstall"
}

luopo_app_marketplace_gpt_load_install() {
  local app_port="$1"
  local app_passwd
  read -r -p "设置 gpt-load 登录密钥（建议 sk- 开头）: " app_passwd
  mkdir -p /home/docker/gpt-load/data
  docker rm -f gpt-load >/dev/null 2>&1 || true
  docker run -d \
    --name gpt-load \
    --restart=always \
    -p "${app_port}:3001" \
    -e AUTH_KEY="${app_passwd}" \
    -v /home/docker/gpt-load/data:/app/data \
    tbphp/gpt-load:latest
}

luopo_app_marketplace_gpt_load_update() {
  local app_port="$1"
  docker rm -f gpt-load >/dev/null 2>&1 || true
  docker rmi -f tbphp/gpt-load:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_gpt_load_install "$app_port"
}

luopo_app_marketplace_gpt_load_uninstall() {
  docker rm -f gpt-load >/dev/null 2>&1 || true
  docker rmi -f tbphp/gpt-load:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/gpt-load
  echo "应用已卸载"
}

luopo_app_marketplace_gpt_load_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "62" \
    "gpt-load高性能AI透明代理" \
    "gpt-load" \
    "tbphp/gpt-load:latest" \
    "8082" \
    "高性能 AI 接口透明代理服务。" \
    "官网介绍: https://www.gpt-load.com/" \
    "luopo_app_marketplace_gpt_load_install" \
    "luopo_app_marketplace_gpt_load_update" \
    "luopo_app_marketplace_gpt_load_uninstall"
}

luopo_app_marketplace_gitea_install() {
  local app_port="$1"
  mkdir -p /home/docker/gitea/gitea /home/docker/gitea/data /home/docker/gitea/postgres
  cd /home/docker/gitea
  curl -fsSL -o docker-compose.yml "${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/gitea-docker-compose.yml"
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_gitea_update() {
  local app_port="$1"
  if [[ -d /home/docker/gitea ]]; then
    cd /home/docker/gitea && docker compose down --rmi all
  fi
  luopo_app_marketplace_gitea_install "$app_port"
}

luopo_app_marketplace_gitea_uninstall() {
  if [[ -d /home/docker/gitea ]]; then
    cd /home/docker/gitea && docker compose down --rmi all
  fi
  rm -rf /home/docker/gitea
  echo "应用已卸载"
}

luopo_app_marketplace_gitea_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "66" \
    "gitea私有代码仓库" \
    "gitea" \
    "gitea" \
    "8091" \
    "轻量私有代码托管平台，提供接近 GitHub 的使用体验。" \
    "官网介绍: https://github.com/go-gitea/gitea" \
    "luopo_app_marketplace_gitea_install" \
    "luopo_app_marketplace_gitea_update" \
    "luopo_app_marketplace_gitea_uninstall"
}

luopo_app_marketplace_paperless_install() {
  local app_port="$1"
  mkdir -p /home/docker/paperless/export /home/docker/paperless/consume
  cd /home/docker/paperless
  curl -fsSL -o docker-compose.yml "${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/docker-compose.postgres-tika.yml"
  curl -fsSL -o docker-compose.env "${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/.env"
  sed -i "s/8000:8000/${app_port}:8000/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_paperless_update() {
  local app_port="$1"
  if [[ -d /home/docker/paperless ]]; then
    cd /home/docker/paperless && docker compose down --rmi all
  fi
  luopo_app_marketplace_paperless_install "$app_port"
}

luopo_app_marketplace_paperless_uninstall() {
  if [[ -d /home/docker/paperless ]]; then
    cd /home/docker/paperless && docker compose down --rmi all
  fi
  rm -rf /home/docker/paperless
  echo "应用已卸载"
}

luopo_app_marketplace_paperless_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "69" \
    "paperless文档管理平台" \
    "paperless-webserver-1" \
    "paperless" \
    "8095" \
    "开源电子文档管理系统，适合纸质文件数字化与归档。" \
    "官网介绍: https://docs.paperless-ngx.com/" \
    "luopo_app_marketplace_paperless_install" \
    "luopo_app_marketplace_paperless_update" \
    "luopo_app_marketplace_paperless_uninstall"
}

luopo_app_marketplace_umami_install() {
  local app_port="$1"
  install git
  rm -rf /home/docker/umami
  mkdir -p /home/docker
  cd /home/docker
  git clone "${gh_proxy}github.com/umami-software/umami.git" umami
  cd /home/docker/umami
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_umami_update() {
  local app_port="$1"
  if [[ -d /home/docker/umami ]]; then
    cd /home/docker/umami && docker compose down --rmi all
    git pull origin main >/dev/null 2>&1 || true
    sed -i "s/[0-9]\\+:3000/${app_port}:3000/g" docker-compose.yml
    docker compose up -d
  else
    luopo_app_marketplace_umami_install "$app_port"
  fi
}

luopo_app_marketplace_umami_uninstall() {
  if [[ -d /home/docker/umami ]]; then
    cd /home/docker/umami && docker compose down --rmi all
  fi
  rm -rf /home/docker/umami
  echo "应用已卸载"
}

luopo_app_marketplace_umami_post_install() {
  echo "初始用户名: admin"
  echo "初始密码: umami"
}

luopo_app_marketplace_umami_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "81" \
    "Umami网站统计工具" \
    "umami-umami-1" \
    "umami" \
    "8103" \
    "开源、轻量、隐私友好的网站分析工具。" \
    "官网介绍: https://github.com/umami-software/umami" \
    "luopo_app_marketplace_umami_install" \
    "luopo_app_marketplace_umami_update" \
    "luopo_app_marketplace_umami_uninstall" \
    "luopo_app_marketplace_umami_post_install"
}

luopo_app_marketplace_siyuan_install() {
  local app_port="$1"
  local app_passwd
  read -r -p "设置思源笔记登录密码: " app_passwd
  mkdir -p /home/docker/siyuan/workspace
  docker rm -f siyuan >/dev/null 2>&1 || true
  docker run -d \
    --name siyuan \
    --restart=always \
    -v /home/docker/siyuan/workspace:/siyuan/workspace \
    -p "${app_port}:6806" \
    -e PUID=1001 \
    -e PGID=1002 \
    b3log/siyuan \
    --workspace=/siyuan/workspace/ \
    --accessAuthCode="${app_passwd}"
}

luopo_app_marketplace_siyuan_update() {
  local app_port="$1"
  docker rm -f siyuan >/dev/null 2>&1 || true
  docker rmi -f b3log/siyuan >/dev/null 2>&1 || true
  luopo_app_marketplace_siyuan_install "$app_port"
}

luopo_app_marketplace_siyuan_uninstall() {
  docker rm -f siyuan >/dev/null 2>&1 || true
  docker rmi -f b3log/siyuan >/dev/null 2>&1 || true
  rm -rf /home/docker/siyuan
  echo "应用已卸载"
}

luopo_app_marketplace_siyuan_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "82" \
    "思源笔记" \
    "siyuan" \
    "b3log/siyuan" \
    "8105" \
    "隐私优先的知识管理系统。" \
    "官网介绍: https://github.com/siyuan-note/siyuan" \
    "luopo_app_marketplace_siyuan_install" \
    "luopo_app_marketplace_siyuan_update" \
    "luopo_app_marketplace_siyuan_uninstall"
}

luopo_app_marketplace_karakeep_install() {
  local app_port="$1"
  install git
  rm -rf /home/docker/karakeep
  mkdir -p /home/docker
  cd /home/docker
  git clone "${gh_proxy}github.com/karakeep-app/karakeep.git" karakeep
  cd /home/docker/karakeep/docker
  cp .env.sample .env
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_karakeep_update() {
  local app_port="$1"
  if [[ -d /home/docker/karakeep/docker ]]; then
    cd /home/docker/karakeep/docker && docker compose down --rmi all
    cd /home/docker/karakeep && git pull origin main >/dev/null 2>&1 || true
    sed -i "s/[0-9]\\+:3000/${app_port}:3000/g" /home/docker/karakeep/docker/docker-compose.yml
    cd /home/docker/karakeep/docker && docker compose up -d
  else
    luopo_app_marketplace_karakeep_install "$app_port"
  fi
}

luopo_app_marketplace_karakeep_uninstall() {
  if [[ -d /home/docker/karakeep/docker ]]; then
    cd /home/docker/karakeep/docker && docker compose down --rmi all
  fi
  rm -rf /home/docker/karakeep
  echo "应用已卸载"
}

luopo_app_marketplace_karakeep_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "84" \
    "Karakeep书签管理" \
    "docker-web-1" \
    "karakeep" \
    "8110" \
    "自托管书签应用，带有 AI 辅助能力。" \
    "官网介绍: https://github.com/karakeep-app/karakeep" \
    "luopo_app_marketplace_karakeep_install" \
    "luopo_app_marketplace_karakeep_update" \
    "luopo_app_marketplace_karakeep_uninstall"
}

luopo_app_marketplace_lucky_install() {
  local app_port="$1"
  mkdir -p /home/docker/lucky/conf
  docker rm -f lucky >/dev/null 2>&1 || true
  docker run -d \
    --name=lucky \
    --restart=always \
    --network host \
    -v /home/docker/lucky/conf:/app/conf \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gdy666/lucky:v2
  echo "正在等待 Lucky 初始化..."
  sleep 10
  docker exec lucky /app/lucky -rSetHttpAdminPort "${app_port}" || true
}

luopo_app_marketplace_lucky_update() {
  local app_port="$1"
  docker rm -f lucky >/dev/null 2>&1 || true
  docker rmi -f gdy666/lucky:v2 >/dev/null 2>&1 || true
  luopo_app_marketplace_lucky_install "$app_port"
}

luopo_app_marketplace_lucky_uninstall() {
  docker rm -f lucky >/dev/null 2>&1 || true
  docker rmi -f gdy666/lucky:v2 >/dev/null 2>&1 || true
  rm -rf /home/docker/lucky
  echo "应用已卸载"
}

luopo_app_marketplace_lucky_post_install() {
  echo "默认账号密码: 666"
}

luopo_app_marketplace_lucky_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "85" \
    "Lucky大内网穿透工具" \
    "lucky" \
    "gdy666/lucky:v2" \
    "8112" \
    "大内网穿透及端口转发管理工具，支持 DDNS、反向代理、WOL 等功能。" \
    "官网介绍: https://github.com/gdy666/lucky" \
    "luopo_app_marketplace_lucky_install" \
    "luopo_app_marketplace_lucky_update" \
    "luopo_app_marketplace_lucky_uninstall" \
    "luopo_app_marketplace_lucky_post_install"
}

luopo_app_marketplace_openwebui_install() {
  local app_port="$1"
  mkdir -p /home/docker/open-webui
  docker rm -f open-webui >/dev/null 2>&1 || true
  docker run -d \
    --name open-webui \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/open-webui:/app/backend/data \
    ghcr.io/open-webui/open-webui:main
}

luopo_app_marketplace_openwebui_update() {
  local app_port="$1"
  docker rm -f open-webui >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/open-webui/open-webui:main >/dev/null 2>&1 || true
  luopo_app_marketplace_openwebui_install "$app_port"
}

luopo_app_marketplace_openwebui_uninstall() {
  docker rm -f open-webui >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/open-webui/open-webui:main >/dev/null 2>&1 || true
  rm -rf /home/docker/open-webui
  echo "应用已卸载"
}

luopo_app_marketplace_openwebui_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "43" \
    "OpenWebUI自托管AI平台" \
    "open-webui" \
    "ghcr.io/open-webui/open-webui:main" \
    "8063" \
    "自托管大语言模型 Web UI，支持各类模型 API 接入。" \
    "官网介绍: https://github.com/open-webui/open-webui" \
    "luopo_app_marketplace_openwebui_install" \
    "luopo_app_marketplace_openwebui_update" \
    "luopo_app_marketplace_openwebui_uninstall"
}

luopo_app_marketplace_n8n_install() {
  local app_port="$1"
  luopo_app_marketplace_add_yuming
  mkdir -p /home/docker/n8n
  chmod -R 777 /home/docker/n8n
  docker rm -f n8n >/dev/null 2>&1 || true
  docker run -d \
    --name n8n \
    --restart=always \
    -p "${app_port}:5678" \
    -v /home/docker/n8n:/home/node/.n8n \
    -e N8N_HOST="${yuming}" \
    -e N8N_PORT=5678 \
    -e N8N_PROTOCOL=https \
    -e WEBHOOK_URL="https://${yuming}/" \
    docker.n8n.io/n8nio/n8n
  luopo_ldnmp_proxy_site "${yuming}" 127.0.0.1 "${app_port}"
  luopo_app_marketplace_block_container_port n8n "$ipv4_address"
}

luopo_app_marketplace_n8n_update() {
  local app_port="$1"
  docker rm -f n8n >/dev/null 2>&1 || true
  docker rmi -f docker.n8n.io/n8nio/n8n >/dev/null 2>&1 || true
  luopo_app_marketplace_n8n_install "$app_port"
}

luopo_app_marketplace_n8n_uninstall() {
  docker rm -f n8n >/dev/null 2>&1 || true
  docker rmi -f docker.n8n.io/n8nio/n8n >/dev/null 2>&1 || true
  rm -rf /home/docker/n8n
  echo "应用已卸载"
}

luopo_app_marketplace_n8n_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "45" \
    "n8n自动化工作流平台" \
    "n8n" \
    "docker.n8n.io/n8nio/n8n" \
    "8065" \
    "强大的自动化工作流平台，适合自动化编排与 webhook 流程。" \
    "官网介绍: https://github.com/n8n-io/n8n" \
    "luopo_app_marketplace_n8n_install" \
    "luopo_app_marketplace_n8n_update" \
    "luopo_app_marketplace_n8n_uninstall"
}

luopo_app_marketplace_allinssl_install() {
  local app_port="$1"
  mkdir -p /home/docker/allinssl/data
  docker rm -f allinssl >/dev/null 2>&1 || true
  docker run -d \
    --name allinssl \
    --restart=always \
    -p "${app_port}:8888" \
    -v /home/docker/allinssl/data:/www/allinssl/data \
    -e ALLINSSL_USER=allinssl \
    -e ALLINSSL_PWD=allinssldocker \
    -e ALLINSSL_URL=allinssl \
    allinssl/allinssl:latest
}

luopo_app_marketplace_allinssl_update() {
  local app_port="$1"
  docker rm -f allinssl >/dev/null 2>&1 || true
  docker rmi -f allinssl/allinssl:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_allinssl_install "$app_port"
}

luopo_app_marketplace_allinssl_uninstall() {
  docker rm -f allinssl >/dev/null 2>&1 || true
  docker rmi -f allinssl/allinssl:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/allinssl
  echo "应用已卸载"
}

luopo_app_marketplace_allinssl_post_install() {
  echo "安全入口: /allinssl"
  echo "用户名: allinssl"
  echo "密码: allinssldocker"
}

luopo_app_marketplace_allinssl_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "47" \
    "AllinSSL证书管理平台" \
    "allinssl" \
    "allinssl/allinssl:latest" \
    "8068" \
    "开源免费的 SSL 证书自动化管理平台。" \
    "官网介绍: https://allinssl.com" \
    "luopo_app_marketplace_allinssl_install" \
    "luopo_app_marketplace_allinssl_update" \
    "luopo_app_marketplace_allinssl_uninstall" \
    "luopo_app_marketplace_allinssl_post_install"
}

luopo_app_marketplace_immich_install() {
  local app_port="$1"
  install git openssl wget
  mkdir -p /home/docker/immich_server
  cd /home/docker/immich_server
  wget -O docker-compose.yml "${gh_proxy}github.com/immich-app/immich/releases/latest/download/docker-compose.yml"
  wget -O .env "${gh_proxy}github.com/immich-app/immich/releases/latest/download/example.env"
  sed -i "s/2283:2283/${app_port}:2283/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_immich_update() {
  local app_port="$1"
  if [[ -d /home/docker/immich_server ]]; then
    cd /home/docker/immich_server && docker compose down --rmi all
  fi
  luopo_app_marketplace_immich_install "$app_port"
}

luopo_app_marketplace_immich_uninstall() {
  if [[ -d /home/docker/immich_server ]]; then
    cd /home/docker/immich_server && docker compose down --rmi all
  fi
  rm -rf /home/docker/immich_server
  echo "应用已卸载"
}

luopo_app_marketplace_immich_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "64" \
    "immich图片视频管理器" \
    "immich_server" \
    "immich" \
    "8085" \
    "高性能自托管照片和视频管理解决方案。" \
    "官网介绍: https://github.com/immich-app/immich" \
    "luopo_app_marketplace_immich_install" \
    "luopo_app_marketplace_immich_update" \
    "luopo_app_marketplace_immich_uninstall"
}

luopo_app_marketplace_onepanel_state() {
  command -v 1pctl >/dev/null 2>&1 && echo "已安装" || echo "未安装"
}

luopo_app_marketplace_onepanel_menu() {
  local choice state
  luopo_app_marketplace_bootstrap || return 1
  while true; do
    clear
    state="$(luopo_app_marketplace_onepanel_state)"
    echo "1Panel新一代管理面板 ${state}"
    echo "现代化 Linux 服务器运维管理面板。"
    echo "官网介绍: https://github.com/1Panel-dev/1Panel"
    echo
    echo "------------------------"
    echo "1. 安装/更新          2. 查看面板信息      3. 修改面板密码"
    echo "4. 查看服务状态       5. 查看服务日志      6. 卸载"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        install bash curl
        bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"
        luopo_app_marketplace_native_add_app_id "1"
        ;;
      2)
        if command -v 1pctl >/dev/null 2>&1; then
          1pctl user-info
        else
          echo "未检测到 1Panel，请先安装。"
        fi
        ;;
      3)
        if command -v 1pctl >/dev/null 2>&1; then
          1pctl update password
        else
          echo "未检测到 1Panel。"
        fi
        ;;
      4)
        systemctl status 1panel --no-pager -l 2>/dev/null || systemctl status 1panel.service --no-pager -l 2>/dev/null || echo "未检测到 1Panel systemd 服务。"
        ;;
      5)
        journalctl -u 1panel -n 80 --no-pager 2>/dev/null || journalctl -u 1panel.service -n 80 --no-pager 2>/dev/null || echo "未检测到 1Panel 日志。"
        ;;
      6)
        if command -v 1pctl >/dev/null 2>&1; then
          1pctl uninstall
        else
          echo "未检测到 1Panel。"
        fi
        luopo_app_marketplace_native_remove_app_id "1"
        ;;
      0) return 0 ;;
      *) echo "无效的输入!" ;;
    esac
    break_end
  done
}

luopo_app_marketplace_nezha_install() {
  install curl unzip jq
  curl -sL "${gh_proxy}raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh" -o /tmp/nezha.sh
  chmod +x /tmp/nezha.sh
  /tmp/nezha.sh
}

luopo_app_marketplace_nezha_refresh_record() {
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "nezha-dashboard"; then
    luopo_app_marketplace_native_add_app_id "4"
  else
    luopo_app_marketplace_native_remove_app_id "4"
  fi
}

luopo_app_marketplace_nezha_menu() {
  local choice state
  luopo_app_marketplace_bootstrap || return 1
  while true; do
    clear
    state="$(luopo_app_marketplace_native_app_state "nezha-dashboard")"
    echo "哪吒探针VPS监控面板 ${state}"
    echo "轻量服务器监控面板，支持多节点状态、告警与流量监控。"
    echo "官网介绍: https://github.com/nezhahq/nezha"
    echo
    echo "------------------------"
    echo "1. 运行官方安装/管理脚本"
    echo "2. 查看容器状态"
    echo "3. 查看 Dashboard 日志"
    echo "4. 查看 Agent 日志"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_nezha_install
        luopo_app_marketplace_nezha_refresh_record
        ;;
      2)
        docker ps -a --filter name=nezha --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        ;;
      3)
        docker logs --tail 80 nezha-dashboard 2>/dev/null || echo "未检测到 nezha-dashboard 容器。"
        ;;
      4)
        docker logs --tail 80 nezha-agent 2>/dev/null || echo "未检测到 nezha-agent 容器。"
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

luopo_app_marketplace_safeline_install() {
  bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
  docker exec safeline-mgt resetadmin || true
}

luopo_app_marketplace_safeline_update() {
  bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
}

luopo_app_marketplace_safeline_uninstall() {
  if [[ -d /data/safeline ]]; then
    cd /data/safeline && docker compose down --rmi all
  fi
  rm -rf /data/safeline
  echo "应用已卸载"
}

luopo_app_marketplace_safeline_post_install() {
  echo "如需重置管理员密码，可进入容器后执行: docker exec safeline-mgt resetadmin"
}

luopo_app_marketplace_safeline_menu() {
  local choice state
  luopo_app_marketplace_bootstrap || return 1
  while true; do
    clear
    state="$(luopo_app_marketplace_native_app_state "safeline-mgt")"
    echo "雷池WAF防火墙面板 ${state}"
    echo "雷池 SafeLine 社区版 Web 应用防火墙。"
    echo "官网介绍: https://github.com/chaitin/SafeLine"
    echo
    echo "------------------------"
    echo "1. 安装              2. 更新            3. 重置管理员密码"
    echo "4. 查看容器状态       5. 查看管理日志      6. 卸载"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_safeline_install
        luopo_app_marketplace_native_add_app_id "7"
        luopo_app_marketplace_safeline_post_install
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_safeline_update
        luopo_app_marketplace_native_add_app_id "7"
        ;;
      3)
        docker exec safeline-mgt resetadmin 2>/dev/null || echo "未检测到 safeline-mgt 容器。"
        ;;
      4)
        docker ps -a --filter name=safeline --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        ;;
      5)
        docker logs --tail 80 safeline-mgt 2>/dev/null || echo "未检测到 safeline-mgt 容器。"
        ;;
      6)
        luopo_app_marketplace_safeline_uninstall
        luopo_app_marketplace_native_remove_app_id "7"
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

luopo_app_marketplace_rustdesk_hbbs_install() {
  mkdir -p /home/docker/hbbs/data
  docker rm -f hbbs >/dev/null 2>&1 || true
  docker run -d \
    --name hbbs \
    --restart=always \
    --network host \
    -v /home/docker/hbbs/data:/root \
    rustdesk/rustdesk-server hbbs
}

luopo_app_marketplace_rustdesk_hbbs_update() {
  docker rm -f hbbs >/dev/null 2>&1 || true
  docker rmi -f rustdesk/rustdesk-server >/dev/null 2>&1 || true
  luopo_app_marketplace_rustdesk_hbbs_install
}

luopo_app_marketplace_rustdesk_hbbs_uninstall() {
  docker rm -f hbbs >/dev/null 2>&1 || true
  docker rmi -f rustdesk/rustdesk-server >/dev/null 2>&1 || true
  rm -rf /home/docker/hbbs
  echo "应用已卸载"
}

luopo_app_marketplace_rustdesk_hbbs_post_install() {
  echo "RustDesk 服务端日志:"
  docker logs hbbs 2>/dev/null || true
}

luopo_app_marketplace_rustdesk_hbbs_menu() {
  local choice state
  luopo_app_marketplace_bootstrap || return 1
  while true; do
    clear
    state="$(luopo_app_marketplace_native_app_state "hbbs")"
    echo "RustDesk远程桌面服务端 ${state}"
    echo "RustDesk ID 注册服务器，建议与中继端配套使用。"
    echo "官网介绍: https://github.com/rustdesk/rustdesk-server"
    echo
    echo "------------------------"
    echo "1. 安装              2. 更新            3. 查看公钥"
    echo "4. 查看容器状态       5. 查看服务日志      6. 卸载"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_rustdesk_hbbs_install
        luopo_app_marketplace_native_add_app_id "27"
        luopo_app_marketplace_rustdesk_hbbs_post_install
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_rustdesk_hbbs_update
        luopo_app_marketplace_native_add_app_id "27"
        ;;
      3)
        if [[ -f /home/docker/hbbs/data/id_ed25519.pub ]]; then
          cat /home/docker/hbbs/data/id_ed25519.pub
        else
          echo "未找到 RustDesk 公钥文件。"
        fi
        ;;
      4)
        docker ps -a --filter name=hbbs --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        ;;
      5)
        docker logs --tail 80 hbbs 2>/dev/null || echo "未检测到 hbbs 容器。"
        ;;
      6)
        luopo_app_marketplace_rustdesk_hbbs_uninstall
        luopo_app_marketplace_native_remove_app_id "27"
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

luopo_app_marketplace_rustdesk_hbbr_install() {
  mkdir -p /home/docker/hbbr/data
  docker rm -f hbbr >/dev/null 2>&1 || true
  docker run -d \
    --name hbbr \
    --restart=always \
    --network host \
    -v /home/docker/hbbr/data:/root \
    rustdesk/rustdesk-server hbbr
}

luopo_app_marketplace_rustdesk_hbbr_update() {
  docker rm -f hbbr >/dev/null 2>&1 || true
  docker rmi -f rustdesk/rustdesk-server >/dev/null 2>&1 || true
  luopo_app_marketplace_rustdesk_hbbr_install
}

luopo_app_marketplace_rustdesk_hbbr_uninstall() {
  docker rm -f hbbr >/dev/null 2>&1 || true
  docker rmi -f rustdesk/rustdesk-server >/dev/null 2>&1 || true
  rm -rf /home/docker/hbbr
  echo "应用已卸载"
}

luopo_app_marketplace_rustdesk_hbbr_menu() {
  local choice state
  luopo_app_marketplace_bootstrap || return 1
  while true; do
    clear
    state="$(luopo_app_marketplace_native_app_state "hbbr")"
    echo "RustDesk远程桌面中继端 ${state}"
    echo "RustDesk 中继服务器，用于改善远程桌面连接质量。"
    echo "官网介绍: https://github.com/rustdesk/rustdesk-server"
    echo
    echo "------------------------"
    echo "1. 安装              2. 更新            3. 查看容器状态"
    echo "4. 查看服务日志       5. 卸载"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_rustdesk_hbbr_install
        luopo_app_marketplace_native_add_app_id "28"
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_rustdesk_hbbr_update
        luopo_app_marketplace_native_add_app_id "28"
        ;;
      3)
        docker ps -a --filter name=hbbr --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        ;;
      4)
        docker logs --tail 80 hbbr 2>/dev/null || echo "未检测到 hbbr 容器。"
        ;;
      5)
        luopo_app_marketplace_rustdesk_hbbr_uninstall
        luopo_app_marketplace_native_remove_app_id "28"
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

luopo_app_marketplace_frps_write_config() {
  local token dashboard_user dashboard_pwd
  token="$(openssl rand -hex 16)"
  dashboard_user="admin"
  dashboard_pwd="$(openssl rand -hex 8)"
  mkdir -p /home/frp
  cat > /home/frp/frps.toml <<EOF
[common]
bind_port = 8055
authentication_method = token
token = ${token}
dashboard_port = 8056
dashboard_user = ${dashboard_user}
dashboard_pwd = ${dashboard_pwd}
EOF
  echo "FRP 服务端 token: ${token}"
  echo "Dashboard 用户名: ${dashboard_user}"
  echo "Dashboard 密码: ${dashboard_pwd}"
}

luopo_app_marketplace_frps_install() {
  install openssl
  [[ -f /home/frp/frps.toml ]] || luopo_app_marketplace_frps_write_config
  docker rm -f frps >/dev/null 2>&1 || true
  docker run -d \
    --name frps \
    --restart=always \
    --network host \
    -v /home/frp/frps.toml:/frp/frps.toml \
    kjlion/frp:alpine /frp/frps -c /frp/frps.toml
  open_port 8055 8056 || true
}

luopo_app_marketplace_frps_update() {
  docker rm -f frps >/dev/null 2>&1 || true
  docker rmi -f kjlion/frp:alpine >/dev/null 2>&1 || true
  luopo_app_marketplace_frps_install
}

luopo_app_marketplace_frps_uninstall() {
  docker rm -f frps >/dev/null 2>&1 || true
  docker rmi -f kjlion/frp:alpine >/dev/null 2>&1 || true
  rm -f /home/frp/frps.toml
  rmdir /home/frp 2>/dev/null || true
  echo "应用已卸载"
}

luopo_app_marketplace_frps_menu() {
  local choice state
  luopo_app_marketplace_bootstrap || return 1
  while true; do
    clear
    state="$(luopo_app_marketplace_native_app_state "frps")"
    echo "FRP内网穿透服务端 ${state}"
    echo "FRP 服务端，默认监听 8055，Dashboard 端口 8056。"
    echo "官网介绍: https://github.com/fatedier/frp"
    echo
    echo "------------------------"
    echo "1. 安装              2. 更新            3. 查看配置"
    echo "4. 重新生成配置       5. 查看容器状态      6. 查看服务日志"
    echo "7. 卸载"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_frps_install
        luopo_app_marketplace_native_add_app_id "29"
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_frps_update
        luopo_app_marketplace_native_add_app_id "29"
        ;;
      3)
        [[ -f /home/frp/frps.toml ]] && cat /home/frp/frps.toml || echo "未找到 /home/frp/frps.toml"
        ;;
      4)
        rm -f /home/frp/frps.toml
        luopo_app_marketplace_frps_write_config
        luopo_app_marketplace_frps_update
        luopo_app_marketplace_native_add_app_id "29"
        ;;
      5)
        docker ps -a --filter name=frps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        ;;
      6)
        docker logs --tail 80 frps 2>/dev/null || echo "未检测到 frps 容器。"
        ;;
      7)
        luopo_app_marketplace_frps_uninstall
        luopo_app_marketplace_native_remove_app_id "29"
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

luopo_app_marketplace_frpc_write_config() {
  local server_addr token
  read -r -p "请输入 FRP 服务端 IP/域名: " server_addr
  read -r -p "请输入 FRP 服务端 token: " token
  mkdir -p /home/frp
  cat > /home/frp/frpc.toml <<EOF
[common]
server_addr = ${server_addr}
server_port = 8055
authentication_method = token
token = ${token}
EOF
}

luopo_app_marketplace_frpc_install() {
  [[ -f /home/frp/frpc.toml ]] || luopo_app_marketplace_frpc_write_config
  docker rm -f frpc >/dev/null 2>&1 || true
  docker run -d \
    --name frpc \
    --restart=always \
    --network host \
    -v /home/frp/frpc.toml:/frp/frpc.toml \
    kjlion/frp:alpine /frp/frpc -c /frp/frpc.toml
}

luopo_app_marketplace_frpc_update() {
  docker rm -f frpc >/dev/null 2>&1 || true
  docker rmi -f kjlion/frp:alpine >/dev/null 2>&1 || true
  luopo_app_marketplace_frpc_install
}

luopo_app_marketplace_frpc_uninstall() {
  docker rm -f frpc >/dev/null 2>&1 || true
  docker rmi -f kjlion/frp:alpine >/dev/null 2>&1 || true
  rm -f /home/frp/frpc.toml
  rmdir /home/frp 2>/dev/null || true
  echo "应用已卸载"
}

luopo_app_marketplace_frpc_menu() {
  local choice state
  luopo_app_marketplace_bootstrap || return 1
  while true; do
    clear
    state="$(luopo_app_marketplace_native_app_state "frpc")"
    echo "FRP内网穿透客户端 ${state}"
    echo "FRP 客户端，连接服务端后可配置内网穿透规则。"
    echo "官网介绍: https://github.com/fatedier/frp"
    echo
    echo "------------------------"
    echo "1. 安装              2. 更新            3. 查看配置"
    echo "4. 重新生成配置       5. 查看容器状态      6. 查看服务日志"
    echo "7. 卸载"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_frpc_install
        luopo_app_marketplace_native_add_app_id "40"
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_frpc_update
        luopo_app_marketplace_native_add_app_id "40"
        ;;
      3)
        [[ -f /home/frp/frpc.toml ]] && cat /home/frp/frpc.toml || echo "未找到 /home/frp/frpc.toml"
        ;;
      4)
        rm -f /home/frp/frpc.toml
        luopo_app_marketplace_frpc_write_config
        luopo_app_marketplace_frpc_update
        luopo_app_marketplace_native_add_app_id "40"
        ;;
      5)
        docker ps -a --filter name=frpc --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        ;;
      6)
        docker logs --tail 80 frpc 2>/dev/null || echo "未检测到 frpc 容器。"
        ;;
      7)
        luopo_app_marketplace_frpc_uninstall
        luopo_app_marketplace_native_remove_app_id "40"
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

luopo_app_marketplace_dify_install() {
  local app_port="$1"
  install git
  luopo_app_marketplace_native_repo_sync "${gh_proxy}github.com/langgenius/dify.git" /home/docker/dify
  cd /home/docker/dify/docker
  [[ -f .env ]] || cp .env.example .env
  luopo_app_marketplace_native_set_env_value .env EXPOSE_NGINX_PORT "${app_port}"
  luopo_app_marketplace_native_set_env_value .env EXPOSE_NGINX_SSL_PORT "8858"
  docker compose up -d
  chown -R 1001:1001 /home/docker/dify/docker/volumes/app/storage 2>/dev/null || true
  chmod -R 755 /home/docker/dify/docker/volumes/app/storage 2>/dev/null || true
}

luopo_app_marketplace_dify_update() {
  local app_port="$1"
  luopo_app_marketplace_dify_install "$app_port"
  cd /home/docker/dify/docker
  docker compose pull || true
  docker compose up -d --remove-orphans
}

luopo_app_marketplace_dify_uninstall() {
  if [[ -d /home/docker/dify/docker ]]; then
    cd /home/docker/dify/docker && docker compose down --rmi all
  fi
  rm -rf /home/docker/dify
  echo "应用已卸载"
}

luopo_app_marketplace_dify_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "41" \
    "Dify大模型知识库" \
    "docker-nginx-1" \
    "dify" \
    "8058" \
    "开源 LLM 应用开发平台，支持知识库、工作流与 Agent。" \
    "官网介绍: https://github.com/langgenius/dify" \
    "luopo_app_marketplace_dify_install" \
    "luopo_app_marketplace_dify_update" \
    "luopo_app_marketplace_dify_uninstall"
}

luopo_app_marketplace_newapi_install() {
  local app_port="$1"
  install git
  luopo_app_marketplace_native_repo_sync "${gh_proxy}github.com/Calcium-Ion/new-api.git" /home/docker/new-api
  cd /home/docker/new-api
  sed -i \
    -e "s/- \"3000:3000\"/- \"${app_port}:3000\"/g" \
    -e 's/container_name: redis/container_name: redis-new-api/g' \
    -e 's/container_name: mysql/container_name: mysql-new-api/g' \
    docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_newapi_update() {
  local app_port="$1"
  luopo_app_marketplace_newapi_install "$app_port"
  cd /home/docker/new-api
  docker compose pull || true
  docker compose up -d --remove-orphans
}

luopo_app_marketplace_newapi_uninstall() {
  if [[ -d /home/docker/new-api ]]; then
    cd /home/docker/new-api && docker compose down --rmi all
  fi
  rm -rf /home/docker/new-api
  echo "应用已卸载"
}

luopo_app_marketplace_newapi_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "42" \
    "NewAPI大模型资产管理" \
    "new-api" \
    "calciumion/new-api" \
    "8059" \
    "OpenAI API 分发与额度管理面板。" \
    "官网介绍: https://github.com/Calcium-Ion/new-api" \
    "luopo_app_marketplace_newapi_install" \
    "luopo_app_marketplace_newapi_update" \
    "luopo_app_marketplace_newapi_uninstall"
}

luopo_app_marketplace_linkwarden_install() {
  local app_port="$1"
  local admin_password nextauth_secret postgres_password
  install curl openssl
  mkdir -p /home/docker/linkwarden
  cd /home/docker/linkwarden
  curl -fsSL "${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml" -o docker-compose.yml
  if [[ ! -f .env ]]; then
    curl -fsSL "${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample" -o .env
    admin_password="$(openssl rand -hex 8)"
    nextauth_secret="$(openssl rand -base64 32)"
    postgres_password="$(openssl rand -base64 16)"
    luopo_app_marketplace_native_set_env_value .env NEXTAUTH_SECRET "${nextauth_secret}"
    luopo_app_marketplace_native_set_env_value .env POSTGRES_PASSWORD "${postgres_password}"
    luopo_app_marketplace_native_set_env_value .env ADMIN_EMAIL "admin@example.com"
    luopo_app_marketplace_native_set_env_value .env ADMIN_PASSWORD "${admin_password}"
  else
    admin_password=""
  fi
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  luopo_app_marketplace_native_set_env_value .env NEXTAUTH_URL "http://localhost:${app_port}"
  luopo_app_marketplace_native_set_env_value .env NEXT_PUBLIC_CREDENTIALS_ENABLED "true"
  docker compose up -d
  if [[ -n "$admin_password" ]]; then
    echo "默认管理员: admin@example.com"
    echo "默认密码: ${admin_password}"
  else
    echo "已保留现有 Linkwarden 配置与管理员凭据。"
  fi
}

luopo_app_marketplace_linkwarden_update() {
  local app_port="$1"
  luopo_app_marketplace_linkwarden_install "$app_port"
  cd /home/docker/linkwarden
  docker compose pull || true
  docker compose up -d --remove-orphans
}

luopo_app_marketplace_linkwarden_uninstall() {
  if [[ -d /home/docker/linkwarden ]]; then
    cd /home/docker/linkwarden && docker compose down --rmi all
  fi
  rm -rf /home/docker/linkwarden
  echo "应用已卸载"
}

luopo_app_marketplace_linkwarden_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "61" \
    "linkwarden书签管理" \
    "linkwarden-linkwarden-1" \
    "linkwarden" \
    "8080" \
    "团队与个人书签归档管理工具。" \
    "官网介绍: https://github.com/linkwarden/linkwarden" \
    "luopo_app_marketplace_linkwarden_install" \
    "luopo_app_marketplace_linkwarden_update" \
    "luopo_app_marketplace_linkwarden_uninstall"
}
