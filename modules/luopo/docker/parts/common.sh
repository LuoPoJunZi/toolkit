#!/usr/bin/env bash
set -euo pipefail

DAEMON_JSON="/etc/docker/daemon.json"

# Shared Docker manager helpers.

service_action() {
  local action="$1"
  local svc="$2"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl "$action" "$svc" >/dev/null 2>&1
  else
    service "$svc" "$action" >/dev/null 2>&1
  fi
}

docker_installed() {
  command -v docker >/dev/null 2>&1
}

docker_compose_version() {
  if docker compose version >/dev/null 2>&1; then
    docker compose version
    return
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose version --short 2>/dev/null | awk '{print "Docker Compose version " $0}'
    return
  fi
  echo "Docker Compose version N/A"
}

count_by_command() {
  local out
  out="$($@ 2>/dev/null || true)"
  if [[ -z "$out" ]]; then
    echo "0"
    return
  fi
  printf '%s\n' "$out" | sed '/^$/d' | wc -l | tr -d ' '
}

get_docker_counts() {
  if ! docker_installed; then
    echo "未安装|0|0|0|0"
    return
  fi

  local c i n v
  c="$(count_by_command docker ps -a -q)"
  i="$(count_by_command docker images -q)"
  n="$(count_by_command docker network ls -q)"
  v="$(count_by_command docker volume ls -q)"
  echo "已安装|${c}|${i}|${n}|${v}"
}

print_docker_overview() {
  local info state c i n v
  info="$(get_docker_counts)"
  state="${info%%|*}"
  info="${info#*|}"
  c="${info%%|*}"
  info="${info#*|}"
  i="${info%%|*}"
  info="${info#*|}"
  n="${info%%|*}"
  v="${info##*|}"

  echo "环境${state}  容器: ${c}  镜像: ${i}  网络: ${n}  卷: ${v}"
}

docker_check_ready() {
  if ! docker_installed; then
    echo "Docker 未安装，请先执行 '1. 安装更新Docker环境'"
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Docker 服务未就绪，请先启动 Docker 服务"
    return 1
  fi
  return 0
}

ensure_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "当前系统不支持 apt-get，暂不支持自动安装/卸载 Docker"
    return 1
  fi
  return 0
}
