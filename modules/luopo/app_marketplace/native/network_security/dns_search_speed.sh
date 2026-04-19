#!/usr/bin/env bash
set -euo pipefail

# DNS, search, speed-test, ad-blocking, and IP toolbox applications.

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
