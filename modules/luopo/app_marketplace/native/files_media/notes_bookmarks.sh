#!/usr/bin/env bash
set -euo pipefail

# Notes, bookmarks, and personal knowledge applications.

luopo_app_marketplace_memos_install() {
  local app_port="$1"
  docker rm -f memos >/dev/null 2>&1 || true
  docker run -d \
    --name memos \
    -p "${app_port}:5230" \
    -v /home/docker/memos:/var/opt/memos \
    --restart=always \
    neosmemo/memos:stable
}

luopo_app_marketplace_memos_update() {
  local app_port="$1"
  luopo_app_marketplace_native_update_container \
    "neosmemo/memos:stable" \
    luopo_app_marketplace_memos_install \
    "$app_port"
}

luopo_app_marketplace_memos_uninstall() {
  docker rm -f memos >/dev/null 2>&1 || true
  docker rmi -f neosmemo/memos:stable >/dev/null 2>&1 || true
  rm -rf /home/docker/memos
  echo "应用已卸载"
}

luopo_app_marketplace_memos_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "61" \
    "Memos网页备忘录" \
    "memos" \
    "neosmemo/memos:stable" \
    "8023" \
    "Memos 是一款轻量级、自托管的备忘录中心。" \
    "官网介绍: https://github.com/usememos/memos" \
    "luopo_app_marketplace_memos_install" \
    "luopo_app_marketplace_memos_update" \
    "luopo_app_marketplace_memos_uninstall"
}

luopo_app_marketplace_siyuan_install() {
  local app_port="$1"
  local app_passwd="${2:-}"
  local auth_file="/home/docker/siyuan/access_auth_code"

  if [[ -z "$app_passwd" && -f "$auth_file" ]]; then
    app_passwd="$(cat "$auth_file")"
  fi
  if [[ -z "$app_passwd" ]]; then
    app_passwd="$(luopo_app_marketplace_native_container_arg siyuan "--accessAuthCode=" || true)"
  fi
  if [[ -z "$app_passwd" ]]; then
    read -r -p "设置思源笔记登录密码: " app_passwd
  fi
  if [[ -z "$app_passwd" ]]; then
    echo "登录密码不能为空"
    return 1
  fi

  mkdir -p /home/docker/siyuan/workspace
  printf '%s\n' "$app_passwd" >"$auth_file"
  chmod 600 "$auth_file"
  docker rm -f siyuan >/dev/null 2>&1 || true
  docker run -d \
    --name siyuan \
    --restart=always \
    -v /home/docker/siyuan/workspace:/siyuan/workspace \
    -p "${app_port}:6806" \
    -e PUID=1001 \
    -e PGID=1002 \
    b3log/siyuan \
    --workspace=/siyuan/workspace/ \
    --accessAuthCode="${app_passwd}"
}

luopo_app_marketplace_siyuan_update() {
  local app_port="$1"
  luopo_app_marketplace_native_update_container \
    "b3log/siyuan" \
    luopo_app_marketplace_siyuan_install \
    "$app_port"
}

luopo_app_marketplace_siyuan_uninstall() {
  docker rm -f siyuan >/dev/null 2>&1 || true
  docker rmi -f b3log/siyuan >/dev/null 2>&1 || true
  rm -rf /home/docker/siyuan
  echo "应用已卸载"
}

luopo_app_marketplace_siyuan_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "64" \
    "思源笔记" \
    "siyuan" \
    "b3log/siyuan" \
    "8105" \
    "隐私优先的知识管理系统。" \
    "官网介绍: https://github.com/siyuan-note/siyuan" \
    "luopo_app_marketplace_siyuan_install" \
    "luopo_app_marketplace_siyuan_update" \
    "luopo_app_marketplace_siyuan_uninstall"
}

luopo_app_marketplace_karakeep_install() {
  local app_port="$1"
  install git
  luopo_app_marketplace_native_repo_sync "${gh_proxy}github.com/karakeep-app/karakeep.git" /home/docker/karakeep || return 1
  cd /home/docker/karakeep/docker || return 1
  [[ -f .env ]] || cp .env.sample .env
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  docker compose pull || return 1
  docker compose up -d --remove-orphans || return 1
}

luopo_app_marketplace_karakeep_update() {
  local app_port="$1"
  luopo_app_marketplace_karakeep_install "$app_port"
}

luopo_app_marketplace_karakeep_uninstall() {
  if [[ -d /home/docker/karakeep/docker ]]; then
    cd /home/docker/karakeep/docker && docker compose down --rmi all
  fi
  rm -rf /home/docker/karakeep
  echo "应用已卸载"
}

luopo_app_marketplace_karakeep_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "65" \
    "Karakeep书签管理" \
    "docker-web-1" \
    "" \
    "8110" \
    "自托管书签应用，带有 AI 辅助能力。" \
    "官网介绍: https://github.com/karakeep-app/karakeep" \
    "luopo_app_marketplace_karakeep_install" \
    "luopo_app_marketplace_karakeep_update" \
    "luopo_app_marketplace_karakeep_uninstall"
}

luopo_app_marketplace_linkwarden_install() {
  local app_port="$1"
  local admin_password nextauth_secret postgres_password
  install curl openssl
  mkdir -p /home/docker/linkwarden
  cd /home/docker/linkwarden || return 1
  curl -fsSL "${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml" -o docker-compose.yml || return 1
  if [[ ! -f .env ]]; then
    curl -fsSL "${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample" -o .env || return 1
    admin_password="$(openssl rand -hex 8)"
    nextauth_secret="$(openssl rand -base64 32)"
    postgres_password="$(openssl rand -base64 16)"
    luopo_app_marketplace_native_set_env_value .env NEXTAUTH_SECRET "${nextauth_secret}"
    luopo_app_marketplace_native_set_env_value .env POSTGRES_PASSWORD "${postgres_password}"
    luopo_app_marketplace_native_set_env_value .env ADMIN_EMAIL "admin@example.com"
    luopo_app_marketplace_native_set_env_value .env ADMIN_PASSWORD "${admin_password}"
  else
    admin_password=""
  fi
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  luopo_app_marketplace_native_set_env_value .env NEXTAUTH_URL "http://localhost:${app_port}"
  luopo_app_marketplace_native_set_env_value .env NEXT_PUBLIC_CREDENTIALS_ENABLED "true"
  docker compose pull || return 1
  docker compose up -d --remove-orphans || return 1
  if [[ -n "$admin_password" ]]; then
    echo "默认管理员: admin@example.com"
    echo "默认密码: ${admin_password}"
  else
    echo "已保留现有 Linkwarden 配置与管理员凭据。"
  fi
}

luopo_app_marketplace_linkwarden_update() {
  local app_port="$1"
  luopo_app_marketplace_linkwarden_install "$app_port"
}

luopo_app_marketplace_linkwarden_uninstall() {
  if [[ -d /home/docker/linkwarden ]]; then
    cd /home/docker/linkwarden && docker compose down --rmi all
  fi
  rm -rf /home/docker/linkwarden
  echo "应用已卸载"
}

luopo_app_marketplace_linkwarden_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "62" \
    "linkwarden书签管理" \
    "linkwarden-linkwarden-1" \
    "" \
    "8080" \
    "团队与个人书签归档管理工具。" \
    "官网介绍: https://github.com/linkwarden/linkwarden" \
    "luopo_app_marketplace_linkwarden_install" \
    "luopo_app_marketplace_linkwarden_update" \
    "luopo_app_marketplace_linkwarden_uninstall"
}
