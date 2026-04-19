#!/usr/bin/env bash
set -euo pipefail

# Standalone app and static-site installation actions.

luopo_ldnmp_install_bitwarden() {
  clear
  local webname="Bitwarden"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  add_yuming

  mkdir -p "/home/web/html/$yuming/bitwarden/data"
  docker rm -f bitwarden >/dev/null 2>&1 || true
  docker run -d \
    --name bitwarden \
    --restart=always \
    -p 3280:80 \
    -v "/home/web/html/$yuming/bitwarden/data:/data" \
    vaultwarden/server

  local duankou=3280
  luopo_ldnmp_proxy_site "$yuming" 127.0.0.1 "$duankou"
}

luopo_ldnmp_install_halo() {
  clear
  local webname="Halo"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  add_yuming

  mkdir -p "/home/web/html/$yuming/.halo2"
  docker rm -f halo >/dev/null 2>&1 || true
  docker run -d \
    --name halo \
    --restart=always \
    -p 8010:8090 \
    -v "/home/web/html/$yuming/.halo2:/root/.halo2" \
    halohub/halo:2

  local duankou=8010
  luopo_ldnmp_proxy_site "$yuming" 127.0.0.1 "$duankou"
}

luopo_ldnmp_install_ai_prompt_generator() {
  clear
  local webname="AI绘画提示词生成器"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  add_yuming
  nginx_install_status || return 1
  install_ssltls || return 1
  certs_status || return 1

  wget -O "/home/web/conf.d/$yuming.conf" "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf"
  sed -i "s/yuming.com/$yuming/g" "/home/web/conf.d/$yuming.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"
  wget "${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/ai_prompt_generator.zip"
  unzip "$(ls -t ./*.zip | head -1)"
  rm -f ./*.zip

  docker exec nginx chown -R nginx:nginx /var/www/html
  docker exec nginx nginx -s reload
  nginx_web_on
}

luopo_ldnmp_custom_static_site() {
  clear
  local webname="静态站点"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  luopo_ldnmp_prepare_static_site || return 1

  wget -O "/home/web/conf.d/$yuming.conf" "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf"
  sed -i "s/yuming.com/$yuming/g" "/home/web/conf.d/$yuming.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"

  clear
  echo -e "[${gl_huang}1/2${gl_bai}] 上传静态源码"
  echo "-------------"
  echo "目前只允许上传 zip 格式源码包，请将源码包放到 /home/web/html/${yuming} 目录下"
  read -r -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载: " url_download

  if [[ -n "$url_download" ]]; then
    wget "$url_download"
  fi

  local latest_zip
  latest_zip="$(ls -t ./*.zip 2>/dev/null | head -1)"
  if [[ -n "$latest_zip" ]]; then
    unzip "$latest_zip"
    rm -f "$latest_zip"
  else
    echo "未检测到 zip 源码包，将继续配置站点目录。"
  fi

  clear
  echo -e "[${gl_huang}2/2${gl_bai}] index.html 所在路径"
  echo "-------------"
  find "$(realpath .)" -name "index.html" -print | xargs -r -I {} dirname {}
  read -r -p "请输入 index.html 的路径，类似 /home/web/html/$yuming/index/: " index_lujing

  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" "/home/web/conf.d/$yuming.conf"
  sed -i "s#/home/web/#/var/www/#g" "/home/web/conf.d/$yuming.conf"

  docker exec nginx chown -R nginx:nginx /var/www/html
  docker exec nginx nginx -s reload
  nginx_web_on
}
