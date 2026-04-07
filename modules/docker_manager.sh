#!/usr/bin/env bash
set -euo pipefail

docker_installed() {
  command -v docker >/dev/null 2>&1
}

docker_service_name() {
  if systemctl list-unit-files 2>/dev/null | grep -q "^docker.service"; then
    echo "docker"
    return
  fi
  echo "docker"
}

docker_install() {
  if docker_installed; then
    echo "Docker 已安装"
    return 0
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    echo "当前系统不支持 apt-get，无法自动安装 Docker"
    return 1
  fi

  echo "开始安装 Docker（docker.io）..."
  apt-get update -y
  apt-get install -y docker.io
  systemctl enable docker >/dev/null 2>&1 || true
  systemctl start docker >/dev/null 2>&1 || true
  echo "Docker 安装完成"
}

docker_service_action() {
  local action="$1"
  local service
  service="$(docker_service_name)"

  if command -v systemctl >/dev/null 2>&1; then
    systemctl "$action" "$service"
  else
    service "$service" "$action"
  fi
}

docker_status() {
  local service
  service="$(docker_service_name)"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl status "$service" --no-pager || true
  else
    service "$service" status || true
  fi
}

docker_cleanup() {
  read -r -p "将执行 docker system prune -f，确认继续？(y/N): " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "已取消"
    return 0
  fi
  docker system prune -f
}

docker_check_ready() {
  if docker_installed; then
    return 0
  fi
  echo "Docker 未安装"
  return 1
}

docker_manager() {
  local choice
  while true; do
    clear
    echo "========================================"
    echo "Docker 管理"
    echo "========================================"
    menu_item "1" "安装 Docker"
    menu_item "2" "启动 Docker"
    menu_item "3" "停止 Docker"
    menu_item "4" "重启 Docker"
    menu_item "5" "Docker 状态"
    menu_item "6" "查看容器列表"
    menu_item "7" "查看镜像列表"
    menu_item "8" "查看网络列表"
    menu_item "9" "查看卷列表"
    menu_item "10" "查看指定容器日志"
    menu_item "11" "进入指定容器 Shell"
    menu_item "12" "清理无用资源"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read -r -p "请输入选择: " choice

    case "$choice" in
      1)
        docker_install
        ;;
      2)
        docker_service_action start || true
        ;;
      3)
        docker_service_action stop || true
        ;;
      4)
        docker_service_action restart || true
        ;;
      5)
        docker_status || true
        ;;
      6)
        docker_check_ready && docker ps -a || true
        ;;
      7)
        docker_check_ready && docker images || true
        ;;
      8)
        docker_check_ready && docker network ls || true
        ;;
      9)
        docker_check_ready && docker volume ls || true
        ;;
      10)
        if docker_check_ready; then
          read -r -p "输入容器名/容器ID: " cid
          docker logs --tail 100 "$cid" || true
        fi
        ;;
      11)
        if docker_check_ready; then
          read -r -p "输入容器名/容器ID: " cid
          docker exec -it "$cid" sh || docker exec -it "$cid" bash || true
        fi
        ;;
      12)
        docker_check_ready && docker_cleanup
        ;;
      0)
        return 0
        ;;
      *)
        echo "无效选项"
        ;;
    esac
    echo ""
    read -r -p "按回车继续..." _
  done
}
