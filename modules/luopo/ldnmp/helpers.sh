#!/usr/bin/env bash
set -euo pipefail

LUOPO_LDNMP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_LDNMP_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/ldnmp/legacy_bridge.sh"

luopo_ldnmp_bootstrap() {
  return 0
}

luopo_ldnmp_ip_address() {
  local public_ip isp_info
  public_ip="$(curl -s --max-time 3 https://ipinfo.io/ip && echo)"
  isp_info="$(curl -s --max-time 3 http://ipinfo.io/org)"

  if echo "$isp_info" | grep -Eiq 'CHINANET|mobile|unicom|telecom'; then
    ipv4_address="$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || hostname -I 2>/dev/null | awk '{print $1}')"
  else
    ipv4_address="$public_ip"
  fi
  ipv6_address="$(curl -s --max-time 1 https://v6.ipinfo.io/ip && echo)"
}

luopo_ldnmp_delete_site() {
  local target_domain="$1"
  local target_db
  [[ -n "$target_domain" ]] || return 0

  rm -rf "/home/web/html/$target_domain" >/dev/null 2>&1 || true
  rm -f "/home/web/conf.d/$target_domain.conf" >/dev/null 2>&1 || true
  rm -f "/home/web/certs/${target_domain}_key.pem" >/dev/null 2>&1 || true
  rm -f "/home/web/certs/${target_domain}_cert.pem" >/dev/null 2>&1 || true

  if [[ -f /home/web/docker-compose.yml ]] && docker inspect mysql >/dev/null 2>&1; then
    target_db="$(echo "$target_domain" | sed -e 's/[^A-Za-z0-9]/_/g')"
    dbrootpasswd="$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')"
    [[ -n "${dbrootpasswd:-}" ]] && docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${target_db};" >/dev/null 2>&1 || true
  fi

  docker exec nginx nginx -s reload >/dev/null 2>&1 || true
}

repeat_add_yuming() {
  if [[ -n "${yuming:-}" && -e "/home/web/conf.d/$yuming.conf" ]]; then
    send_stats "域名重复使用"
    luopo_ldnmp_delete_site "$yuming"
  fi
}

add_yuming() {
  luopo_ldnmp_ip_address
  echo -e "先将域名解析到本机IP: ${gl_huang}${ipv4_address:-}  ${ipv6_address:-}${gl_bai}"
  read -r -p "请输入你的IP或者解析过的域名: " yuming
}

luopo_ldnmp_check_ip_and_get_access_port() {
  local target_domain="$1"
  local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
  local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

  access_port=""
  if [[ "$target_domain" =~ $ipv4_pattern || "$target_domain" =~ $ipv6_pattern ]]; then
    read -r -p "请输入访问/监听端口，回车默认使用 80: " access_port
    access_port="${access_port:-80}"
  fi
}

luopo_ldnmp_update_nginx_listen_port() {
  local target_domain="$1"
  local target_port="$2"
  local conf="/home/web/conf.d/${target_domain}.conf"
  [[ -n "$target_port" ]] || return 0
  [[ -f "$conf" ]] || return 1

  sed -i '/^[[:space:]]*listen[[:space:]]\+/d' "$conf"
  sed -i "/server {/a\\
    listen ${target_port};\\
    listen [::]:${target_port};
" "$conf"
}

add_db() {
  dbname="$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')"
  dbrootpasswd="$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')"
  dbuse="$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')"
  dbusepasswd="$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')"
  docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";" >/dev/null 2>&1
}

restart_ldnmp() {
  docker exec nginx chown -R nginx:nginx /var/www/html >/dev/null 2>&1 || true
  docker exec nginx mkdir -p /var/cache/nginx/proxy >/dev/null 2>&1 || true
  docker exec nginx mkdir -p /var/cache/nginx/fastcgi >/dev/null 2>&1 || true
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy >/dev/null 2>&1 || true
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi >/dev/null 2>&1 || true
  docker exec php chown -R www-data:www-data /var/www/html >/dev/null 2>&1 || true
  docker exec php74 chown -R www-data:www-data /var/www/html >/dev/null 2>&1 || true
  cd /home/web && docker compose restart
}

install_ssltls() {
  local cert_dir="/etc/letsencrypt/live/$yuming"
  local file_path="${cert_dir}/fullchain.pem"
  local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
  local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

  docker stop nginx >/dev/null 2>&1 || true
  cd ~ || return 1

  if [[ ! -f "$file_path" ]]; then
    mkdir -p "$cert_dir"
    if [[ "$yuming" =~ $ipv4_pattern || "$yuming" =~ $ipv6_pattern ]]; then
      install openssl
      if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
        openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout "${cert_dir}/privkey.pem" -out "${cert_dir}/fullchain.pem" -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
      else
        openssl genpkey -algorithm Ed25519 -out "${cert_dir}/privkey.pem"
        openssl req -x509 -key "${cert_dir}/privkey.pem" -out "${cert_dir}/fullchain.pem" -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
      fi
    else
      install_docker
      docker run --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d "$yuming" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa
    fi
  fi

  mkdir -p /home/web/certs
  cp "${cert_dir}/fullchain.pem" "/home/web/certs/${yuming}_cert.pem" >/dev/null 2>&1
  cp "${cert_dir}/privkey.pem" "/home/web/certs/${yuming}_key.pem" >/dev/null 2>&1
  docker start nginx >/dev/null 2>&1 || true
}

certs_status() {
  sleep 1
  if [[ -f "/etc/letsencrypt/live/$yuming/fullchain.pem" ]]; then
    send_stats "域名证书申请成功"
    return 0
  fi

  send_stats "域名证书申请失败"
  echo -e "${gl_hong}注意: ${gl_bai}证书申请失败，请检查域名解析、80/443端口和网络环境后重试。"
  return 1
}

ldnmp_install_status() {
  if ! docker inspect php >/dev/null 2>&1; then
    send_stats "请先安装LDNMP环境"
    ldnmp_install_all
  fi
}

nginx_install_status() {
  if ! docker inspect nginx >/dev/null 2>&1; then
    send_stats "请先安装nginx环境"
    nginx_install_all
  fi
}

ldnmp_web_on() {
  clear
  echo "您的 $webname 搭建好了！"
  echo "https://$yuming"
  echo "------------------------"
  echo "$webname 安装信息如下: "
}

nginx_web_on() {
  local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
  local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'
  clear
  echo "您的 $webname 搭建好了！"

  if [[ "$yuming" =~ $ipv4_pattern || "$yuming" =~ $ipv6_pattern ]]; then
    [[ -n "${access_port:-}" ]] && mv "/home/web/conf.d/${yuming}.conf" "/home/web/conf.d/${yuming}_${access_port}.conf"
    echo "http://$yuming:${access_port:-80}"
  elif grep -q '^[[:space:]]*#.*if (\$scheme = http)' "/home/web/conf.d/$yuming.conf" 2>/dev/null; then
    echo "http://$yuming"
  else
    echo "https://$yuming"
  fi
}

luopo_ldnmp_write_domain_conf() {
  local template_url="$1"
  wget -O /home/web/conf.d/map.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf"
  wget -O "/home/web/conf.d/$yuming.conf" "$template_url"
  sed -i "s/yuming.com/$yuming/g" "/home/web/conf.d/$yuming.conf"
}

luopo_ldnmp_prepare_php_site() {
  add_yuming
  repeat_add_yuming
  ldnmp_install_status || return 1
  install_ssltls || return 1
  certs_status || return 1
  add_db || return 1
}

luopo_ldnmp_prepare_static_site() {
  add_yuming
  repeat_add_yuming
  nginx_install_status || return 1
  install_ssltls || return 1
  certs_status || return 1
}

luopo_ldnmp_proxy_site() {
  local target_domain="${1:-}"
  local reverseproxy="${2:-}"
  local port="${3:-}"

  clear
  webname="反向代理-IP+端口"
  yuming="$target_domain"

  send_stats "安装$webname"
  echo "开始部署 $webname"
  [[ -n "$yuming" ]] || add_yuming
  luopo_ldnmp_check_ip_and_get_access_port "$yuming"

  if [[ -z "$reverseproxy" ]]; then
    read -r -p "请输入你的反代IP (回车默认本机IP 127.0.0.1): " reverseproxy
    reverseproxy="${reverseproxy:-127.0.0.1}"
  fi
  [[ -n "$port" ]] || read -r -p "请输入你的反代端口: " port

  nginx_install_status || return 1
  install_ssltls || return 1
  certs_status || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf"
  backend="$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)"
  sed -i "s/backend_yuming_com/backend_$backend/g" "/home/web/conf.d/$yuming.conf"

  reverseproxy_port="$reverseproxy:$port"
  upstream_servers=""
  for server in $reverseproxy_port; do
    upstream_servers="${upstream_servers}    server $server;\\n"
  done
  sed -i "s/# 动态添加/$upstream_servers/g" "/home/web/conf.d/$yuming.conf"
  sed -i '/remote_addr/d' "/home/web/conf.d/$yuming.conf"

  luopo_ldnmp_update_nginx_listen_port "$yuming" "${access_port:-}"
  nginx_http_on
  docker exec nginx nginx -s reload >/dev/null 2>&1 || true
  nginx_web_on
}

find_container_by_host_port() {
  local target_port="$1"
  docker_name="$(docker ps --format '{{.ID}} {{.Names}}' | while read -r id name; do
    if docker port "$id" 2>/dev/null | grep -q ":$target_port"; then
      echo "$name"
      break
    fi
  done)"
}

check_docker_image_update() {
  local container_name="$1"
  local country container_info container_created full_image_name container_created_ts
  local api_url remote_date remote_ts image_repo image_tag repo_path
  update_status=""

  country="$(curl -s --max-time 2 ipinfo.io/country)"
  [[ "$country" == "CN" ]] && return 0

  container_info="$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)"
  [[ -n "$container_info" ]] || return 0

  container_created="$(echo "$container_info" | cut -d',' -f1)"
  full_image_name="$(echo "$container_info" | cut -d',' -f2)"
  container_created_ts="$(date -d "$container_created" +%s 2>/dev/null)"

  if [[ "$full_image_name" == ghcr.io* ]]; then
    repo_path="$(echo "$full_image_name" | sed 's/ghcr.io\///' | cut -d':' -f1)"
    api_url="https://api.github.com/repos/$repo_path/releases/latest"
    remote_date="$(curl -s "$api_url" | jq -r '.published_at' 2>/dev/null)"
  else
    image_repo="${full_image_name%%:*}"
    image_tag="${full_image_name##*:}"
    [[ "$image_repo" == "$image_tag" ]] && image_tag="latest"
    [[ "$image_repo" != */* ]] && image_repo="library/$image_repo"
    api_url="https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag"
    remote_date="$(curl -s "$api_url" | jq -r '.last_updated' 2>/dev/null)"
  fi

  if [[ -n "$remote_date" && "$remote_date" != "null" ]]; then
    remote_ts="$(date -d "$remote_date" +%s 2>/dev/null)"
    if [[ -n "$container_created_ts" && -n "$remote_ts" && "$container_created_ts" -lt "$remote_ts" ]]; then
      update_status="${gl_huang}发现新版本!${gl_bai}"
    fi
  fi
}

luopo_ldnmp_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_LDNMP_ITEMS[@]}"; do
    IFS='|' read -r number _ _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_ldnmp_item_label() {
  local item="$1"
  IFS='|' read -r _ label _ <<<"$item"
  printf '%s\n' "$label"
}

luopo_ldnmp_render_cell() {
  local key="$1"
  local item label
  item="$(luopo_ldnmp_find_item "$key")" || return 1
  label="$(luopo_ldnmp_item_label "$item")"
  printf "%b%-4s %b%s%b" "$gl_huang" "${key}." "$gl_bai" "$label" "$gl_bai"
}

luopo_ldnmp_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

