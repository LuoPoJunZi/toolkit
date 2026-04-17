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
  ldnmp_Proxy_backend
}

luopo_ldnmp_stream_proxy() {
  stream_panel
}

luopo_ldnmp_site_status() {
  ldnmp_web_status
}

luopo_ldnmp_security() {
  web_security
}

luopo_ldnmp_optimization() {
  web_optimization
}

