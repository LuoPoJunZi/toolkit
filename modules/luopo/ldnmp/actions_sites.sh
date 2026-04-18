#!/usr/bin/env bash
set -euo pipefail

luopo_ldnmp_install_all() {
  cd ~ || return 1
  send_stats "安装LDNMP环境"
  root_use || return 1
  clear
  echo -e "${gl_huang}LDNMP环境未安装，开始安装LDNMP环境...${gl_bai}"
  check_disk_space 3 /home || return 1
  ldnmp_install_status_one
  install_dependency
  install_docker
  install_certbot
  install_ldnmp_conf
  install_ldnmp
}

luopo_ldnmp_install_wordpress() {
  clear
  webname="WordPress"
  yuming="${1:-}"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  [[ -n "$yuming" ]] || add_yuming
  repeat_add_yuming
  ldnmp_install_status || return 1
  install_ssltls || return 1
  certs_status || return 1
  add_db || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"
  wget -O latest.zip "${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/wp-latest.zip"
  unzip -o latest.zip
  rm -f latest.zip
  echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379'); define('WP_REDIS_MAXTTL', 86400); define('WP_CACHE_KEY_SALT', '${yuming}_');" >> "/home/web/html/$yuming/wordpress/wp-config-sample.php"
  sed -i "s|database_name_here|$dbname|g" "/home/web/html/$yuming/wordpress/wp-config-sample.php"
  sed -i "s|username_here|$dbuse|g" "/home/web/html/$yuming/wordpress/wp-config-sample.php"
  sed -i "s|password_here|$dbusepasswd|g" "/home/web/html/$yuming/wordpress/wp-config-sample.php"
  sed -i "s|localhost|mysql|g" "/home/web/html/$yuming/wordpress/wp-config-sample.php"
  patch_wp_url "https://$yuming" "https://$yuming"
  cp "/home/web/html/$yuming/wordpress/wp-config-sample.php" "/home/web/html/$yuming/wordpress/wp-config.php"

  restart_ldnmp
  nginx_web_on
}

luopo_ldnmp_install_discuz() {
  clear
  local webname="Discuz论坛"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  luopo_ldnmp_prepare_php_site || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"
  wget -O latest.zip "${gh_proxy}github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20250901.zip"
  unzip -o latest.zip
  rm -f latest.zip

  restart_ldnmp
  ldnmp_web_on
  echo "数据库地址: mysql"
  echo "数据库名: $dbname"
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
  echo "表前缀: discuz_"
}

luopo_ldnmp_install_kodbox() {
  clear
  local webname="可道云桌面"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  luopo_ldnmp_prepare_php_site || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"
  wget -O latest.zip "${gh_proxy}github.com/kalcaddle/kodbox/archive/refs/tags/1.50.02.zip"
  unzip -o latest.zip
  rm -f latest.zip

  local extracted_dir
  extracted_dir="$(find "/home/web/html/$yuming" -maxdepth 1 -type d -name 'kodbox*' ! -name kodbox | head -1)"
  if [[ -n "$extracted_dir" ]]; then
    rm -rf "/home/web/html/$yuming/kodbox"
    mv "$extracted_dir" "/home/web/html/$yuming/kodbox"
  fi

  restart_ldnmp
  ldnmp_web_on
  echo "数据库地址: mysql"
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
  echo "数据库名: $dbname"
  echo "redis主机: redis"
}

luopo_ldnmp_install_maccms() {
  clear
  local webname="苹果CMS"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  luopo_ldnmp_prepare_php_site || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"
  wget -O maccms10.zip "${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip"
  unzip -o maccms10.zip
  local maccms_dir
  maccms_dir="$(find . -maxdepth 1 -type d -name 'maccms10-*' | head -1)"
  if [[ -n "$maccms_dir" ]]; then
    cp -a "$maccms_dir"/. .
    rm -rf "$maccms_dir"
  fi
  rm -f maccms10.zip

  cd "/home/web/html/$yuming/template/"
  wget -O DYXS2.zip "${gh_proxy}github.com/kejilion/Website_source_code/raw/main/DYXS2.zip"
  unzip -o DYXS2.zip
  rm -f DYXS2.zip

  cp "/home/web/html/$yuming/template/DYXS2/asset/admin/Dyxs2.php" "/home/web/html/$yuming/application/admin/controller"
  cp "/home/web/html/$yuming/template/DYXS2/asset/admin/dycms.html" "/home/web/html/$yuming/application/admin/view/system"
  [[ -f "/home/web/html/$yuming/admin.php" ]] && mv -f "/home/web/html/$yuming/admin.php" "/home/web/html/$yuming/vip.php"
  wget -O "/home/web/html/$yuming/application/extra/maccms.php" "${gh_proxy}raw.githubusercontent.com/kejilion/Website_source_code/main/maccms.php"

  restart_ldnmp
  ldnmp_web_on
  echo "数据库地址: mysql"
  echo "数据库端口: 3306"
  echo "数据库名: $dbname"
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
  echo "数据库前缀: mac_"
  echo "------------------------"
  echo "安装成功后登录后台地址"
  echo "https://$yuming/vip.php"
}

luopo_ldnmp_install_dujiaoka() {
  clear
  local webname="独角数卡"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  luopo_ldnmp_prepare_php_site || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"
  wget -O dujiaoka.tar.gz "${gh_proxy}github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz"
  tar -zxvf dujiaoka.tar.gz
  rm -f dujiaoka.tar.gz

  restart_ldnmp
  ldnmp_web_on
  echo "数据库地址: mysql"
  echo "数据库端口: 3306"
  echo "数据库名: $dbname"
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
  echo
  echo "redis地址: redis"
  echo "redis密码: 默认不填写"
  echo "redis端口: 6379"
  echo
  echo "网站url: https://$yuming"
  echo "后台登录路径: /admin"
  echo "------------------------"
  echo "用户名: admin"
  echo "密码: admin"
  echo "------------------------"
  echo "登录时右上角如果出现红色 error0，请使用如下命令:"
  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"
}

luopo_ldnmp_install_flarum() {
  clear
  local webname="Flarum论坛"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  luopo_ldnmp_prepare_php_site || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf"
  nginx_http_on

  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini
  mkdir -p "/home/web/html/$yuming"

  docker exec php sh -c "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\""
  docker exec php sh -c "php composer-setup.php"
  docker exec php sh -c "php -r \"unlink('composer-setup.php');\""
  docker exec php sh -c "mv composer.phar /usr/local/bin/composer"

  docker exec php composer create-project flarum/flarum "/var/www/html/$yuming"
  docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum-lang/chinese-simplified"
  docker exec php sh -c "cd /var/www/html/$yuming && composer require 'flarum/extension-manager:*'"
  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/polls fof/sitemap fof/oauth 'fof/best-answer:*' fof/upload fof/gamification 'fof/byobu:*' v17development/flarum-seo clarkwinkelmann/flarum-ext-emojionearea"

  restart_ldnmp
  ldnmp_web_on
  echo "数据库地址: mysql"
  echo "数据库名: $dbname"
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
  echo "表前缀: flarum_"
  echo "管理员信息自行设置"
}

luopo_ldnmp_install_typecho() {
  clear
  local webname="Typecho"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  luopo_ldnmp_prepare_php_site || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"
  wget -O latest.zip "${gh_proxy}github.com/typecho/typecho/releases/latest/download/typecho.zip"
  unzip -o latest.zip
  rm -f latest.zip

  restart_ldnmp
  clear
  ldnmp_web_on
  echo "数据库前缀: typecho_"
  echo "数据库地址: mysql"
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
  echo "数据库名: $dbname"
}

luopo_ldnmp_install_linkstack() {
  clear
  local webname="LinkStack"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  luopo_ldnmp_prepare_php_site || return 1

  wget -O /home/web/conf.d/map.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf"
  wget -O "/home/web/conf.d/$yuming.conf" "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/refs/heads/main/index_php.conf"
  sed -i "s|/var/www/html/yuming.com/|/var/www/html/yuming.com/linkstack|g" "/home/web/conf.d/$yuming.conf"
  sed -i "s|yuming.com|$yuming|g" "/home/web/conf.d/$yuming.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"
  wget -O latest.zip "${gh_proxy}github.com/linkstackorg/linkstack/releases/latest/download/linkstack.zip"
  unzip -o latest.zip
  rm -f latest.zip

  restart_ldnmp
  clear
  ldnmp_web_on
  echo "数据库地址: mysql"
  echo "数据库端口: 3306"
  echo "数据库名: $dbname"
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
}

luopo_ldnmp_custom_dynamic_site() {
  clear
  local webname="PHP动态站点"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  luopo_ldnmp_prepare_php_site || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/index_php.conf"
  nginx_http_on

  mkdir -p "/home/web/html/$yuming"
  cd "/home/web/html/$yuming"

  clear
  echo -e "[${gl_huang}1/6${gl_bai}] 上传 PHP 源码"
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
  echo -e "[${gl_huang}2/6${gl_bai}] index.php 所在路径"
  echo "-------------"
  find "$(realpath .)" -name "index.php" -print | xargs -r -I {} dirname {}
  read -r -p "请输入 index.php 的路径，类似 /home/web/html/$yuming/wordpress/: " index_lujing

  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" "/home/web/conf.d/$yuming.conf"
  sed -i "s#/home/web/#/var/www/#g" "/home/web/conf.d/$yuming.conf"

  clear
  echo -e "[${gl_huang}3/6${gl_bai}] 请选择 PHP 版本"
  echo "-------------"
  local PHP_Version="php"
  read -r -p "1. php最新版 | 2. php7.4 : " pho_v
  case "$pho_v" in
    2)
      sed -i "s#php:9000#php74:9000#g" "/home/web/conf.d/$yuming.conf"
      PHP_Version="php74"
      ;;
    *)
      PHP_Version="php"
      ;;
  esac

  clear
  echo -e "[${gl_huang}4/6${gl_bai}] 安装指定扩展"
  echo "-------------"
  echo "已经安装的扩展"
  docker exec php php -m
  read -r -p "输入需要安装的扩展名称，如 SourceGuardian imap ftp 等。直接回车将跳过安装: " php_extensions
  if [[ -n "$php_extensions" ]]; then
    docker exec "$PHP_Version" install-php-extensions $php_extensions
  fi

  clear
  echo -e "[${gl_huang}5/6${gl_bai}] 编辑站点配置"
  echo "-------------"
  echo "即将打开站点配置，可按需设置伪静态等内容。"
  install nano
  nano "/home/web/conf.d/$yuming.conf"

  clear
  echo -e "[${gl_huang}6/6${gl_bai}] 数据库管理"
  echo "-------------"
  read -r -p "1. 我搭建新站        2. 我搭建老站有数据库备份: " use_db
  case "$use_db" in
    2)
      echo "数据库备份必须是 .gz 结尾的压缩包。请放到 /home/ 目录下，支持宝塔/1Panel 备份数据导入。"
      read -r -p "也可以输入下载链接，远程下载备份数据，直接回车将跳过远程下载: " url_download_db

      cd /home/
      if [[ -n "$url_download_db" ]]; then
        wget "$url_download_db"
      fi

      local latest_gz latest_sql dbrootpasswd
      latest_gz="$(ls -t ./*.gz 2>/dev/null | head -1)"
      if [[ -n "$latest_gz" ]]; then
        gunzip "$latest_gz"
        latest_sql="$(ls -t ./*.sql 2>/dev/null | head -1)"
        if [[ -n "$latest_sql" ]]; then
          dbrootpasswd="$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')"
          docker exec -i mysql mysql -u root -p"$dbrootpasswd" "$dbname" < "$latest_sql"
          echo "数据库导入的表数据"
          docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
          rm -f "$latest_sql"
          echo "数据库导入完成"
        else
          echo "未找到可导入的 SQL 文件。"
        fi
      else
        echo "未找到 .gz 数据库备份。"
      fi
      ;;
  esac

  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini
  restart_ldnmp
  ldnmp_web_on
  local prefix
  prefix="web$(shuf -i 10-99 -n 1)_"
  echo "数据库地址: mysql"
  echo "数据库名: $dbname"
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
  echo "表前缀: $prefix"
  echo "管理员登录信息自行设置"
}

luopo_ldnmp_install_nginx_only() {
  cd ~ || return 1
  send_stats "安装nginx环境"
  root_use || return 1
  clear
  echo -e "${gl_huang}nginx未安装，开始安装nginx环境...${gl_bai}"
  ldnmp_install_status_one
  install_dependency
  install_docker
  install_certbot
  install_ldnmp_conf
  nginx_upgrade
  clear
  local nginx_version
  nginx_version="$(docker exec nginx nginx -v 2>&1 | grep -oP 'nginx/\K[0-9]+\.[0-9]+\.[0-9]+' || true)"
  echo "nginx已安装完成"
  echo -e "当前版本: ${gl_huang}v${nginx_version:-N/A}${gl_bai}"
  echo
}


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

