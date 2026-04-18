#!/usr/bin/env bash
set -euo pipefail

luopo_ldnmp_reverse_proxy_ip_port() {
  luopo_ldnmp_proxy_site
  find_container_by_host_port "$port"
  if [[ -z "${docker_name:-}" ]]; then
    close_port "$port"
    echo "已阻止 IP+端口访问该服务"
  else
    ip_address
    close_port "$port"
    block_container_port "$docker_name" "$ipv4_address"
  fi
}

luopo_ldnmp_redirect_site() {
  clear
  local webname="站点重定向"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  add_yuming
  read -r -p "请输入跳转域名: " reverseproxy
  nginx_install_status
  install_ssltls
  certs_status

  wget -O "/home/web/conf.d/$yuming.conf" "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf"
  sed -i "s/yuming.com/$yuming/g" "/home/web/conf.d/$yuming.conf"
  sed -i "s/baidu.com/$reverseproxy/g" "/home/web/conf.d/$yuming.conf"
  nginx_http_on
  docker exec nginx nginx -s reload
  nginx_web_on
}

luopo_ldnmp_reverse_proxy_domain() {
  clear
  local webname="反向代理-域名"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  add_yuming
  echo -e "域名格式: ${gl_huang}google.com${gl_bai}"
  read -r -p "请输入你的反代域名: " fandai_yuming
  nginx_install_status
  install_ssltls
  certs_status

  wget -O "/home/web/conf.d/$yuming.conf" "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-domain.conf"
  sed -i "s/yuming.com/$yuming/g" "/home/web/conf.d/$yuming.conf"
  sed -i "s|fandaicom|$fandai_yuming|g" "/home/web/conf.d/$yuming.conf"
  nginx_http_on
  docker exec nginx nginx -s reload
  nginx_web_on
}

luopo_ldnmp_reverse_proxy_load_balance() {
  clear
  webname="反向代理-负载均衡"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  add_yuming
  luopo_ldnmp_check_ip_and_get_access_port "$yuming"

  local reverseproxy_port backend upstream_servers server
  read -r -p "请输入多个后端 IP+端口，用空格隔开（例如 127.0.0.1:3000 127.0.0.1:3002）: " reverseproxy_port
  [[ -n "$reverseproxy_port" ]] || { echo "后端地址不能为空"; return 1; }

  nginx_install_status || return 1
  install_ssltls || return 1
  certs_status || return 1

  luopo_ldnmp_write_domain_conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf"
  backend="$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)"
  sed -i "s/backend_yuming_com/backend_$backend/g" "/home/web/conf.d/$yuming.conf"
  upstream_servers=""
  for server in $reverseproxy_port; do
    upstream_servers="${upstream_servers}    server $server;\\n"
  done
  sed -i "s/# 动态添加/$upstream_servers/g" "/home/web/conf.d/$yuming.conf"
  luopo_ldnmp_update_nginx_listen_port "$yuming" "${access_port:-}"
  nginx_http_on
  docker exec nginx nginx -s reload >/dev/null 2>&1 || true
  nginx_web_on
}
