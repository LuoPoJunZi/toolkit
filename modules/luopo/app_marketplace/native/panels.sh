#!/usr/bin/env bash
set -euo pipefail

# Panel and operations applications.

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
    "6" \
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
    "4" \
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
    "8" \
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
    "7" \
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
    luopo_app_marketplace_native_add_app_id "3"
  else
    luopo_app_marketplace_native_remove_app_id "3"
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
        luopo_app_marketplace_native_add_app_id "5"
        luopo_app_marketplace_safeline_post_install
        ;;
      2)
        luopo_app_marketplace_native_install_docker_runtime
        luopo_app_marketplace_safeline_update
        luopo_app_marketplace_native_add_app_id "5"
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
        luopo_app_marketplace_native_remove_app_id "5"
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
