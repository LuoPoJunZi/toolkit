#!/usr/bin/env bash
set -euo pipefail

# File, sync, media, and personal-data applications.

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
  docker rm -f memos >/dev/null 2>&1 || true
  docker rmi -f neosmemo/memos:stable >/dev/null 2>&1 || true
  luopo_app_marketplace_memos_install "$app_port"
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
  docker rm -f navidrome >/dev/null 2>&1 || true
  docker rmi -f deluan/navidrome:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_navidrome_install "$app_port"
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
  docker rm -f jellyfin >/dev/null 2>&1 || true
  docker rmi -f jellyfin/jellyfin >/dev/null 2>&1 || true
  luopo_app_marketplace_jellyfin_install "$app_port"
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
  docker rm -f bitwarden >/dev/null 2>&1 || true
  docker rmi -f vaultwarden/server >/dev/null 2>&1 || true
  luopo_app_marketplace_bitwarden_install "$app_port"
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
  cd /home/docker/gitea
  curl -fsSL -o docker-compose.yml "${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/gitea-docker-compose.yml"
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_gitea_update() {
  local app_port="$1"
  if [[ -d /home/docker/gitea ]]; then
    cd /home/docker/gitea && docker compose down --rmi all
  fi
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
  cd /home/docker/paperless
  curl -fsSL -o docker-compose.yml "${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/docker-compose.postgres-tika.yml"
  curl -fsSL -o docker-compose.env "${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/.env"
  sed -i "s/8000:8000/${app_port}:8000/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_paperless_update() {
  local app_port="$1"
  if [[ -d /home/docker/paperless ]]; then
    cd /home/docker/paperless && docker compose down --rmi all
  fi
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
  rm -rf /home/docker/umami
  mkdir -p /home/docker
  cd /home/docker
  git clone "${gh_proxy}github.com/umami-software/umami.git" umami
  cd /home/docker/umami
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_umami_update() {
  local app_port="$1"
  if [[ -d /home/docker/umami ]]; then
    cd /home/docker/umami && docker compose down --rmi all
    git pull origin main >/dev/null 2>&1 || true
    sed -i "s/[0-9]\\+:3000/${app_port}:3000/g" docker-compose.yml
    docker compose up -d
  else
    luopo_app_marketplace_umami_install "$app_port"
  fi
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

luopo_app_marketplace_siyuan_install() {
  local app_port="$1"
  local app_passwd
  read -r -p "设置思源笔记登录密码: " app_passwd
  mkdir -p /home/docker/siyuan/workspace
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
  docker rm -f siyuan >/dev/null 2>&1 || true
  docker rmi -f b3log/siyuan >/dev/null 2>&1 || true
  luopo_app_marketplace_siyuan_install "$app_port"
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
  rm -rf /home/docker/karakeep
  mkdir -p /home/docker
  cd /home/docker
  git clone "${gh_proxy}github.com/karakeep-app/karakeep.git" karakeep
  cd /home/docker/karakeep/docker
  cp .env.sample .env
  sed -i "s/3000:3000/${app_port}:3000/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_karakeep_update() {
  local app_port="$1"
  if [[ -d /home/docker/karakeep/docker ]]; then
    cd /home/docker/karakeep/docker && docker compose down --rmi all
    cd /home/docker/karakeep && git pull origin main >/dev/null 2>&1 || true
    sed -i "s/[0-9]\\+:3000/${app_port}:3000/g" /home/docker/karakeep/docker/docker-compose.yml
    cd /home/docker/karakeep/docker && docker compose up -d
  else
    luopo_app_marketplace_karakeep_install "$app_port"
  fi
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
    "karakeep" \
    "8110" \
    "自托管书签应用，带有 AI 辅助能力。" \
    "官网介绍: https://github.com/karakeep-app/karakeep" \
    "luopo_app_marketplace_karakeep_install" \
    "luopo_app_marketplace_karakeep_update" \
    "luopo_app_marketplace_karakeep_uninstall"
}

luopo_app_marketplace_immich_install() {
  local app_port="$1"
  install git openssl wget
  mkdir -p /home/docker/immich_server
  cd /home/docker/immich_server
  wget -O docker-compose.yml "${gh_proxy}github.com/immich-app/immich/releases/latest/download/docker-compose.yml"
  wget -O .env "${gh_proxy}github.com/immich-app/immich/releases/latest/download/example.env"
  sed -i "s/2283:2283/${app_port}:2283/g" docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_immich_update() {
  local app_port="$1"
  if [[ -d /home/docker/immich_server ]]; then
    cd /home/docker/immich_server && docker compose down --rmi all
  fi
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

luopo_app_marketplace_linkwarden_install() {
  local app_port="$1"
  local admin_password nextauth_secret postgres_password
  install curl openssl
  mkdir -p /home/docker/linkwarden
  cd /home/docker/linkwarden
  curl -fsSL "${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml" -o docker-compose.yml
  if [[ ! -f .env ]]; then
    curl -fsSL "${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample" -o .env
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
  docker compose up -d
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
  cd /home/docker/linkwarden
  docker compose pull || true
  docker compose up -d --remove-orphans
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
    "linkwarden" \
    "8080" \
    "团队与个人书签归档管理工具。" \
    "官网介绍: https://github.com/linkwarden/linkwarden" \
    "luopo_app_marketplace_linkwarden_install" \
    "luopo_app_marketplace_linkwarden_update" \
    "luopo_app_marketplace_linkwarden_uninstall"
}
