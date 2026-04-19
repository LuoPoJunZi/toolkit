#!/usr/bin/env bash
set -euo pipefail

# File manager, object-list, static-file, and sync applications.

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
    "13" \
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
    "18" \
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
    "14" \
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
    "15" \
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
    "12" \
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
