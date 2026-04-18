#!/usr/bin/env bash
set -euo pipefail

root_use() {
  if [[ "$EUID" -ne 0 ]]; then
    echo -e "${gl_huang}提示: ${gl_bai}该功能需要root用户才能运行！"
    break_end
    return 1
  fi
}

ldnmp_install_status_one() {
  if docker inspect php >/dev/null 2>&1; then
    clear
    send_stats "无法再次安装LDNMP环境"
    echo -e "${gl_huang}提示: ${gl_bai}建站环境已安装。无需再次安装！"
    break_end
    return 1
  fi
}

luopo_ldnmp_stop_port_owner() {
  local port="$1"
  local containers pids pid

  containers="$(docker ps --filter "publish=$port" --format "{{.ID}}" 2>/dev/null || true)"
  if [[ -n "$containers" ]]; then
    docker stop $containers >/dev/null 2>&1 || true
    return 0
  fi

  install lsof
  pids="$(lsof -t -i:"$port" 2>/dev/null || true)"
  for pid in $pids; do
    kill -9 "$pid" >/dev/null 2>&1 || true
  done
}

check_port() {
  luopo_ldnmp_stop_port_owner 80
  luopo_ldnmp_stop_port_owner 443
}

check_disk_space() {
  local required_gb="$1"
  local path="${2:-/}"
  local required_space_mb available_space_mb

  mkdir -p "$path"
  required_space_mb=$((required_gb * 1024))
  available_space_mb="$(df -m "$path" | awk 'NR==2 {print $4}')"

  if [[ -n "$available_space_mb" && "$available_space_mb" -lt "$required_space_mb" ]]; then
    echo -e "${gl_huang}提示: ${gl_bai}磁盘空间不足！"
    echo "当前可用空间: $((available_space_mb / 1024))G"
    echo "最小需求空间: ${required_gb}G"
    echo "无法继续安装，请清理磁盘空间后重试。"
    send_stats "磁盘空间不足"
    return 1
  fi
}

luopo_ldnmp_add_swap() {
  local size_mb="${1:-1024}"
  [[ -f /swapfile ]] && return 0
  fallocate -l "${size_mb}M" /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count="$size_mb"
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile >/dev/null
  grep -q '^/swapfile ' /etc/fstab 2>/dev/null || echo '/swapfile none swap sw 0 0' >> /etc/fstab
}

check_swap() {
  local swap_total
  swap_total="$(free -m | awk 'NR==3{print $2}')"
  [[ "${swap_total:-0}" -gt 0 ]] || luopo_ldnmp_add_swap 1024
}

prefer_ipv4() {
  if [[ -w /etc/gai.conf ]] && ! grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null; then
    echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
  fi
  send_stats "已切换为 IPv4 优先"
}

auto_optimize_dns() {
  return 0
}

install_dependency() {
  check_port
  check_swap
  prefer_ipv4
  auto_optimize_dns
  install wget unzip tar jq grep openssl curl
}

default_server_ssl() {
  install openssl
  mkdir -p /home/web/certs

  if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
      -keyout /home/web/certs/default_server.key \
      -out /home/web/certs/default_server.crt \
      -days 5475 \
      -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
  else
    openssl genpkey -algorithm Ed25519 -out /home/web/certs/default_server.key
    openssl req -x509 \
      -key /home/web/certs/default_server.key \
      -out /home/web/certs/default_server.crt \
      -days 5475 \
      -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
  fi

  openssl rand -out /home/web/certs/ticket12.key 48
  openssl rand -out /home/web/certs/ticket13.key 80
}

install_ldnmp_conf() {
  mkdir -p /home/web/html /home/web/mysql /home/web/certs /home/web/conf.d /home/web/stream.d /home/web/redis /home/web/log/nginx /home/web/letsencrypt
  touch /home/web/docker-compose.yml

  wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
  wget -O /home/web/conf.d/default.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf"
  default_server_ssl

  wget -O /home/web/docker-compose.yml "${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml"
  dbrootpasswd="$(openssl rand -base64 16)"
  dbuse="$(openssl rand -hex 4)"
  dbusepasswd="$(openssl rand -base64 8)"

  sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml
}

update_docker_compose_with_db_creds() {
  [[ -f /home/web/docker-compose.yml ]] || install_ldnmp_conf
  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

  if ! grep -q "letsencrypt" /home/web/docker-compose.yml; then
    wget -O /home/web/docker-compose.yml "${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml"
    dbrootpasswd="$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')"
    dbuse="$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')"
    dbusepasswd="$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')"
    sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
    sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
    sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml
  fi

  if grep -q "kjlion/nginx:alpine" /home/web/docker-compose1.yml; then
    sed -i 's|kjlion/nginx:alpine|nginx:alpine|g' /home/web/docker-compose.yml >/dev/null 2>&1
    sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml >/dev/null 2>&1
  fi
}

fix_phpfpm_conf() {
  local container_name="$1"
  docker exec "$container_name" sh -c "mkdir -p /run/$container_name && chmod 777 /run/$container_name" >/dev/null 2>&1 || return 0
  docker exec "$container_name" sh -c "grep -q '^\\[global\\]' /usr/local/etc/php-fpm.d/www.conf || sed -i '1i [global]\\ndaemonize = no' /usr/local/etc/php-fpm.d/www.conf"
  docker exec "$container_name" sh -c "sed -i '/^listen =/d' /usr/local/etc/php-fpm.d/www.conf"
  docker exec "$container_name" sh -c "printf '\\nlisten = /run/$container_name/php-fpm.sock\\nlisten.owner = www-data\\nlisten.group = www-data\\nlisten.mode = 0777\\n' >> /usr/local/etc/php-fpm.d/www.conf"
  docker exec "$container_name" sh -c "rm -f /usr/local/etc/php-fpm.d/zz-docker.conf"
  find /home/web/conf.d/ -type f -name "*.conf" -exec sed -i "s#fastcgi_pass ${container_name}:9000;#fastcgi_pass unix:/run/${container_name}/php-fpm.sock;#g" {} \; 2>/dev/null || true
}

install_ldnmp() {
  update_docker_compose_with_db_creds
  cd /home/web && docker compose up -d
  sleep 1
  check_crontab_installed || true
  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab - 2>/dev/null || true
  { crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf'; } | crontab - 2>/dev/null || true

  fix_phpfpm_conf php
  fix_phpfpm_conf php74

  wget -O /home/custom_mysql_config.cnf "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf" >/dev/null 2>&1 || true
  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/ >/dev/null 2>&1 || true
  rm -f /home/custom_mysql_config.cnf

  restart_ldnmp
  sleep 2
  clear
  echo "LDNMP环境安装完毕"
  echo "------------------------"
  ldnmp_v
}

install_certbot() {
  cd ~ || return 1
  curl -sS -O "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh"
  chmod +x auto_cert_renewal.sh
  check_crontab_installed || return 0
  local cron_job="0 0 * * * ~/auto_cert_renewal.sh"
  crontab -l 2>/dev/null | grep -vF "$cron_job" | crontab - 2>/dev/null || true
  { crontab -l 2>/dev/null; echo "$cron_job"; } | crontab - 2>/dev/null || true
  echo "续签任务已更新"
}

nginx_upgrade() {
  local ldnmp_pods="nginx"
  cd /home/web/ || return 1
  docker rm -f "$ldnmp_pods" >/dev/null 2>&1 || true
  docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs -r docker rmi >/dev/null 2>&1 || true
  docker images --filter=reference="${ldnmp_pods}*" -q | xargs -r docker rmi >/dev/null 2>&1 || true
  docker compose up -d --force-recreate "$ldnmp_pods"
  check_crontab_installed || true
  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab - 2>/dev/null || true
  { crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf'; } | crontab - 2>/dev/null || true
  docker exec nginx chown -R nginx:nginx /var/www/html >/dev/null 2>&1 || true
  docker exec nginx mkdir -p /var/cache/nginx/proxy /var/cache/nginx/fastcgi >/dev/null 2>&1 || true
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy /var/cache/nginx/fastcgi >/dev/null 2>&1 || true
  docker restart "$ldnmp_pods" >/dev/null 2>&1 || true
  send_stats "更新$ldnmp_pods"
  echo "更新${ldnmp_pods}完成"
}

patch_wp_url() {
  local home_url="$1"
  local site_url="$2"
  local target_dir="/home/web/html"

  find "$target_dir" -type f -name "wp-config-sample.php" 2>/dev/null | while read -r file; do
    sed -i "/define(['\"]WP_HOME['\"].*/d" "$file"
    sed -i "/define(['\"]WP_SITEURL['\"].*/d" "$file"
    awk -v insert="define('WP_HOME', '$home_url');\ndefine('WP_SITEURL', '$site_url');" '
      /Happy publishing/ { print insert }
      { print }
    ' "$file" > "$file.tmp" && mv -f "$file.tmp" "$file"
  done
}
