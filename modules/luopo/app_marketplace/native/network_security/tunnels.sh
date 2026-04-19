#!/usr/bin/env bash
set -euo pipefail

# FRP tunnel server/client applications.

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
