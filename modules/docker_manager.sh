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

docker_manager() {
  local choice
  while true; do
    clear
    echo "========================================"
    echo "Docker 管理"
    echo "========================================"
    printf " %-2s %-16s %-2s %-16s\n" "1." "安装 Docker" "5." "Docker 状态"
    printf " %-2s %-16s %-2s %-16s\n" "2." "启动 Docker" "6." "查看容器列表"
    printf " %-2s %-16s %-2s %-16s\n" "3." "停止 Docker" "7." "查看镜像列表"
    printf " %-2s %-16s %-2s %-16s\n" "4." "重启 Docker" "8." "清理无用资源"
    echo "----------------------------------------"
    printf " %-2s %-16s\n" "0." "返回上级"
    echo "========================================"
    read -r -p "请输入选择: " choice

    case "$choice" in
      1)
        docker_install
        ;;
      2)
        docker_service_action start
        ;;
      3)
        docker_service_action stop
        ;;
      4)
        docker_service_action restart
        ;;
      5)
        docker_status
        ;;
      6)
        if docker_installed; then
          docker ps -a
        else
          echo "Docker 未安装"
        fi
        ;;
      7)
        if docker_installed; then
          docker images
        else
          echo "Docker 未安装"
        fi
        ;;
      8)
        if docker_installed; then
          docker_cleanup
        else
          echo "Docker 未安装"
        fi
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
