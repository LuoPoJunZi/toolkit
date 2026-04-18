#!/usr/bin/env bash
set -euo pipefail

ldnmp_v() {
  local nginx_version mysql_version php_version redis_version dbrootpasswd

  nginx_version="$(docker exec nginx nginx -v 2>&1 | grep -oP 'nginx/\K[0-9]+\.[0-9]+\.[0-9]+' || true)"
  echo -n -e "nginx : ${gl_huang}v${nginx_version:-N/A}${gl_bai}"

  dbrootpasswd="$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')"
  if [[ -n "$dbrootpasswd" ]]; then
    mysql_version="$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e 'SELECT VERSION();' 2>/dev/null | tail -n 1 || true)"
  fi
  echo -n -e "            mysql : ${gl_huang}v${mysql_version:-N/A}${gl_bai}"

  php_version="$(docker exec php php -v 2>/dev/null | grep -oP 'PHP \K[0-9]+\.[0-9]+\.[0-9]+' || true)"
  echo -n -e "            php : ${gl_huang}v${php_version:-N/A}${gl_bai}"

  redis_version="$(docker exec redis redis-server -v 2>&1 | grep -oP 'v=+\K[0-9]+\.[0-9]+' || true)"
  echo -e "            redis : ${gl_huang}v${redis_version:-N/A}${gl_bai}"
  echo "------------------------"
  echo
}

luopo_ldnmp_render_status_banner() {
  local cert_count db_count dbrootpasswd
  cert_count="$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l | tr -d '[:space:]')"
  db_count="0"

  dbrootpasswd="$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')"
  if [[ -n "$dbrootpasswd" ]] && docker inspect mysql >/dev/null 2>&1; then
    db_count="$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e 'SHOW DATABASES;' 2>/dev/null | grep -Ev 'Database|information_schema|mysql|performance_schema|sys' | wc -l | tr -d '[:space:]')"
  fi

  if command -v docker >/dev/null 2>&1 && docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
    echo -e "${gl_huang}------------------------"
    echo -e "${gl_lv}环境已安装${gl_bai}  站点: ${gl_lv}${cert_count}${gl_bai}  数据库: ${gl_lv}${db_count}${gl_bai}"
  fi
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

ip_address() {
  luopo_ldnmp_ip_address
}

check_crontab_installed() {
  if command -v crontab >/dev/null 2>&1; then
    return 0
  fi

  if command -v apt >/dev/null 2>&1; then
    apt update -y
    apt install -y cron
    systemctl enable --now cron 2>/dev/null || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y cronie
    systemctl enable --now crond 2>/dev/null || true
  elif command -v yum >/dev/null 2>&1; then
    yum install -y cronie
    systemctl enable --now crond 2>/dev/null || true
  elif command -v apk >/dev/null 2>&1; then
    apk add dcron
    rc-service dcron start 2>/dev/null || true
    rc-update add dcron default 2>/dev/null || true
  else
    echo "未检测到可用包管理器，无法安装 crontab。"
    return 1
  fi
}

save_iptables_rules() {
  mkdir -p /etc/iptables
  touch /etc/iptables/rules.v4
  iptables-save > /etc/iptables/rules.v4
  check_crontab_installed || return 0
  crontab -l 2>/dev/null | grep -v 'iptables-restore' | crontab - >/dev/null 2>&1 || true
  { crontab -l 2>/dev/null; echo '@reboot iptables-restore < /etc/iptables/rules.v4'; } | crontab - >/dev/null 2>&1 || true
}

close_port() {
  local ports=("$@")
  [[ ${#ports[@]} -gt 0 ]] || { echo "请提供至少一个端口号"; return 1; }

  install iptables
  for port in "${ports[@]}"; do
    iptables -D INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true
    iptables -D INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true
    iptables -C INPUT -p tcp --dport "$port" -j DROP >/dev/null 2>&1 || iptables -I INPUT 1 -p tcp --dport "$port" -j DROP
    iptables -C INPUT -p udp --dport "$port" -j DROP >/dev/null 2>&1 || iptables -I INPUT 1 -p udp --dport "$port" -j DROP
  done

  iptables -D INPUT -i lo -j ACCEPT >/dev/null 2>&1 || true
  iptables -D FORWARD -i lo -j ACCEPT >/dev/null 2>&1 || true
  iptables -I INPUT 1 -i lo -j ACCEPT
  iptables -I FORWARD 1 -i lo -j ACCEPT
  save_iptables_rules || true
  send_stats "已关闭端口"
}

block_container_port() {
  local container_name_or_id="$1"
  local allowed_ip="$2"
  local container_ip

  container_ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id" 2>/dev/null)"
  [[ -n "$container_ip" ]] || return 1

  install iptables
  iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT >/dev/null 2>&1 || iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
  iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT >/dev/null 2>&1 || iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
  iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT >/dev/null 2>&1 || iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
  iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP >/dev/null 2>&1 || iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
  iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT >/dev/null 2>&1 || iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
  iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT >/dev/null 2>&1 || iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
  iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP >/dev/null 2>&1 || iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP

  echo "已阻止IP+端口访问该服务"
  save_iptables_rules || true
}
