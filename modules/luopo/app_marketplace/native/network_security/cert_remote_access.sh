#!/usr/bin/env bash
set -euo pipefail

# Certificate management and remote desktop access applications.

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
