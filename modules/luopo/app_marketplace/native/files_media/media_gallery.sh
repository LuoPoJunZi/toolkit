#!/usr/bin/env bash
set -euo pipefail

# Private music, video, and photo-gallery applications.

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
  luopo_app_marketplace_native_update_container \
    "deluan/navidrome:latest" \
    luopo_app_marketplace_navidrome_install \
    "$app_port"
}

luopo_app_marketplace_navidrome_uninstall() {
  docker rm -f navidrome >/dev/null 2>&1 || true
  docker rmi -f deluan/navidrome:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/navidrome
  echo "应用已卸载"
}

luopo_app_marketplace_navidrome_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "51" \
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
  luopo_app_marketplace_native_update_container \
    "jellyfin/jellyfin" \
    luopo_app_marketplace_jellyfin_install \
    "$app_port"
}

luopo_app_marketplace_jellyfin_uninstall() {
  docker rm -f jellyfin >/dev/null 2>&1 || true
  docker rmi -f jellyfin/jellyfin >/dev/null 2>&1 || true
  rm -rf /home/docker/jellyfin
  echo "应用已卸载"
}

luopo_app_marketplace_jellyfin_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "52" \
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

luopo_app_marketplace_immich_install() {
  local app_port="$1"
  install git openssl wget
  mkdir -p /home/docker/immich_server
  cd /home/docker/immich_server || return 1
  wget -O docker-compose.yml "${gh_proxy}github.com/immich-app/immich/releases/latest/download/docker-compose.yml" || return 1
  if [[ ! -f .env ]]; then
    wget -O .env "${gh_proxy}github.com/immich-app/immich/releases/latest/download/example.env" || return 1
  fi
  sed -i "s/2283:2283/${app_port}:2283/g" docker-compose.yml
  docker compose pull || return 1
  docker compose up -d --remove-orphans || return 1
}

luopo_app_marketplace_immich_update() {
  local app_port="$1"
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
    "17" \
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
