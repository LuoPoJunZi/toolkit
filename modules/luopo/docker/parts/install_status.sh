#!/usr/bin/env bash
set -euo pipefail

# Docker installation, status, cleanup, and uninstall actions.

install_update_docker() {
  if ! ensure_apt; then
    return 1
  fi

  echo "开始安装/更新 Docker 环境..."
  apt-get update -y
  apt-get install -y docker.io containerd runc
  apt-get install -y docker-compose-plugin || apt-get install -y docker-compose || true

  service_action enable docker || true
  service_action start docker || true

  echo "Docker 环境安装/更新完成"
}

docker_global_status() {
  if ! docker_check_ready; then
    return 1
  fi

  echo "Docker版本"
  docker version --format 'Docker version {{.Server.Version}}' 2>/dev/null || docker version 2>/dev/null || true
  docker_compose_version
  echo

  echo "Docker镜像: $(count_by_command docker images -q)"
  docker images 2>/dev/null || true
  echo

  echo "Docker容器: $(count_by_command docker ps -a -q)"
  docker ps -a 2>/dev/null || true
  echo

  echo "Docker卷: $(count_by_command docker volume ls -q)"
  docker volume ls 2>/dev/null || true
  echo

  echo "Docker网络: $(count_by_command docker network ls -q)"
  docker network ls 2>/dev/null || true
}

docker_cleanup_all() {
  if ! docker_check_ready; then
    return 1
  fi

  read -r -p "将执行 docker system prune -a --volumes -f，确认继续？(y/N): " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "已取消"
    return 0
  fi
  docker system prune -a --volumes -f
}

uninstall_docker_env() {
  local ans
  if ! ensure_apt; then
    return 1
  fi

  read -r -p "将卸载 Docker 并删除全部数据，确认继续？(y/N): " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "已取消"
    return 0
  fi

  service_action stop docker || true
  service_action stop containerd || true

  apt-get purge -y docker.io docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose || true
  apt-get autoremove -y

  rm -rf /var/lib/docker /var/lib/containerd /etc/docker
  rm -f /etc/apt/sources.list.d/docker.list
  rm -f /usr/share/keyrings/docker-archive-keyring.gpg

  echo "Docker 环境卸载完成"
}
