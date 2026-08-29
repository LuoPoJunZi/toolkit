#!/usr/bin/env bash
set -euo pipefail

# Password, code, document, and analytics applications.

luopo_app_marketplace_bitwarden_install() {
  local app_port="$1"
  mkdir -p /home/docker/bitwarden/data
  docker rm -f bitwarden >/dev/null 2>&1 || true
  docker run -d \
    --name bitwarden \
    --restart=always \
    -p "${app_port}:80" \
    -v /home/docker/bitwarden/data:/data \
    vaultwarden/server
}

luopo_app_marketplace_bitwarden_update() {
  local app_port="$1"
  luopo_app_marketplace_native_update_container \
    "vaultwarden/server" \
    luopo_app_marketplace_bitwarden_install \
    "$app_port"
}

luopo_app_marketplace_bitwarden_uninstall() {
  docker rm -f bitwarden >/dev/null 2>&1 || true
  docker rmi -f vaultwarden/server >/dev/null 2>&1 || true
  rm -rf /home/docker/bitwarden
  echo "应用已卸载"
}

luopo_app_marketplace_bitwarden_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "30" \
    "bitwarden密码管理器" \
    "bitwarden" \
    "vaultwarden/server" \
    "8072" \
    "你可以完全控制数据的自托管密码管理器。" \
    "官网介绍: https://bitwarden.com/" \
    "luopo_app_marketplace_bitwarden_install" \
    "luopo_app_marketplace_bitwarden_update" \
    "luopo_app_marketplace_bitwarden_uninstall"
}

luopo_app_marketplace_gitea_install() {
  local app_port="$1"
  mkdir -p /home/docker/gitea/gitea /home/docker/gitea/data /home/docker/gitea/postgres
  cd /home/docker/gitea || return 1
  curl -fsSL -o docker-compose.yml "${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/gitea-docker-compose.yml" || return 1
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  docker compose pull || return 1
  docker compose up -d --remove-orphans || return 1
}

luopo_app_marketplace_gitea_update() {
  local app_port="$1"
  luopo_app_marketplace_gitea_install "$app_port"
}

luopo_app_marketplace_gitea_uninstall() {
  if [[ -d /home/docker/gitea ]]; then
    cd /home/docker/gitea && docker compose down --rmi all
  fi
  rm -rf /home/docker/gitea
  echo "应用已卸载"
}

luopo_app_marketplace_gitea_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "71" \
    "gitea私有代码仓库" \
    "gitea" \
    "gitea" \
    "8091" \
    "轻量私有代码托管平台，提供接近 GitHub 的使用体验。" \
    "官网介绍: https://github.com/go-gitea/gitea" \
    "luopo_app_marketplace_gitea_install" \
    "luopo_app_marketplace_gitea_update" \
    "luopo_app_marketplace_gitea_uninstall"
}

luopo_app_marketplace_paperless_install() {
  local app_port="$1"
  mkdir -p /home/docker/paperless/export /home/docker/paperless/consume
  cd /home/docker/paperless || return 1
  curl -fsSL -o docker-compose.yml "${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/docker-compose.postgres-tika.yml" || return 1
  if [[ ! -f docker-compose.env ]]; then
    curl -fsSL -o docker-compose.env "${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/.env" || return 1
  fi
  sed -i "s/8000:8000/${app_port}:8000/g" docker-compose.yml
  docker compose pull || return 1
  docker compose up -d --remove-orphans || return 1
}

luopo_app_marketplace_paperless_update() {
  local app_port="$1"
  luopo_app_marketplace_paperless_install "$app_port"
}

luopo_app_marketplace_paperless_uninstall() {
  if [[ -d /home/docker/paperless ]]; then
    cd /home/docker/paperless && docker compose down --rmi all
  fi
  rm -rf /home/docker/paperless
  echo "应用已卸载"
}

luopo_app_marketplace_paperless_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "16" \
    "paperless文档管理平台" \
    "paperless-webserver-1" \
    "paperless" \
    "8095" \
    "开源电子文档管理系统，适合纸质文件数字化与归档。" \
    "官网介绍: https://docs.paperless-ngx.com/" \
    "luopo_app_marketplace_paperless_install" \
    "luopo_app_marketplace_paperless_update" \
    "luopo_app_marketplace_paperless_uninstall"
}

luopo_app_marketplace_umami_install() {
  local app_port="$1"
  install git
  luopo_app_marketplace_native_repo_sync "${gh_proxy}github.com/umami-software/umami.git" /home/docker/umami || return 1
  cd /home/docker/umami || return 1
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  docker compose pull || return 1
  docker compose up -d --remove-orphans || return 1
}

luopo_app_marketplace_umami_update() {
  local app_port="$1"
  luopo_app_marketplace_umami_install "$app_port"
}

luopo_app_marketplace_umami_uninstall() {
  if [[ -d /home/docker/umami ]]; then
    cd /home/docker/umami && docker compose down --rmi all
  fi
  rm -rf /home/docker/umami
  echo "应用已卸载"
}

luopo_app_marketplace_umami_post_install() {
  echo "初始用户名: admin"
  echo "初始密码: umami"
}

luopo_app_marketplace_umami_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "63" \
    "Umami网站统计工具" \
    "umami-umami-1" \
    "umami" \
    "8103" \
    "开源、轻量、隐私友好的网站分析工具。" \
    "官网介绍: https://github.com/umami-software/umami" \
    "luopo_app_marketplace_umami_install" \
    "luopo_app_marketplace_umami_update" \
    "luopo_app_marketplace_umami_uninstall" \
    "luopo_app_marketplace_umami_post_install"
}
