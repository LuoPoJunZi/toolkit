#!/usr/bin/env bash
set -euo pipefail

# Network, security, certificate, and tunnel applications.

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
    "28" \
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
    "22" \
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
    "69" \
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
    "21" \
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
    "23" \
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
    "31" \
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
    "29" \
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
        luopo_app_marketplace_native_add_app_id "24"
        luopo_app_marketplace_rustdesk_hbbs_post_install
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_rustdesk_hbbs_update
        luopo_app_marketplace_native_add_app_id "24"
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
        luopo_app_marketplace_native_remove_app_id "24"
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
        luopo_app_marketplace_native_add_app_id "25"
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_rustdesk_hbbr_update
        luopo_app_marketplace_native_add_app_id "25"
        ;;
      3)
        docker ps -a --filter name=hbbr --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        ;;
      4)
        docker logs --tail 80 hbbr 2>/dev/null || echo "未检测到 hbbr 容器。"
        ;;
      5)
        luopo_app_marketplace_rustdesk_hbbr_uninstall
        luopo_app_marketplace_native_remove_app_id "25"
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
        luopo_app_marketplace_native_add_app_id "26"
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_frps_update
        luopo_app_marketplace_native_add_app_id "26"
        ;;
      3)
        [[ -f /home/frp/frps.toml ]] && cat /home/frp/frps.toml || echo "未找到 /home/frp/frps.toml"
        ;;
      4)
        rm -f /home/frp/frps.toml
        luopo_app_marketplace_frps_write_config
        luopo_app_marketplace_frps_update
        luopo_app_marketplace_native_add_app_id "26"
        ;;
      5)
        docker ps -a --filter name=frps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        ;;
      6)
        docker logs --tail 80 frps 2>/dev/null || echo "未检测到 frps 容器。"
        ;;
      7)
        luopo_app_marketplace_frps_uninstall
        luopo_app_marketplace_native_remove_app_id "26"
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
        luopo_app_marketplace_native_add_app_id "27"
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_frpc_update
        luopo_app_marketplace_native_add_app_id "27"
        ;;
      3)
        [[ -f /home/frp/frpc.toml ]] && cat /home/frp/frpc.toml || echo "未找到 /home/frp/frpc.toml"
        ;;
      4)
        rm -f /home/frp/frpc.toml
        luopo_app_marketplace_frpc_write_config
        luopo_app_marketplace_frpc_update
        luopo_app_marketplace_native_add_app_id "27"
        ;;
      5)
        docker ps -a --filter name=frpc --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
        ;;
      6)
        docker logs --tail 80 frpc 2>/dev/null || echo "未检测到 frpc 容器。"
        ;;
      7)
        luopo_app_marketplace_frpc_uninstall
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
