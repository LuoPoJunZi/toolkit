#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_APP_MARKETPLACE_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/ldnmp/helpers.sh"

luopo_app_marketplace_bootstrap() {
  return 0
}

luopo_app_marketplace_ip_address() {
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

luopo_app_marketplace_add_yuming() {
  luopo_app_marketplace_ip_address
  echo -e "先将域名解析到本机IP: ${gl_huang}${ipv4_address:-}  ${ipv6_address:-}${gl_bai}"
  read -r -p "请输入你的IP或者解析过的域名: " yuming
}

luopo_app_marketplace_block_container_port() {
  local container_name_or_id="$1"
  local allowed_ip="$2"
  local container_ip
  container_ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id" 2>/dev/null)"
  [[ -z "$container_ip" ]] && return 1

  install iptables

  if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP >/dev/null 2>&1; then
    iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
  fi
  if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT >/dev/null 2>&1; then
    iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
  fi
  if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT >/dev/null 2>&1; then
    iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
  fi

  if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP >/dev/null 2>&1; then
    iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
  fi
  if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT >/dev/null 2>&1; then
    iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
  fi
  if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT >/dev/null 2>&1; then
    iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
  fi
}

luopo_app_marketplace_clear_container_rules() {
  local container_name_or_id="$1"
  local allowed_ip="$2"
  local container_ip
  container_ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id" 2>/dev/null)"
  [[ -z "$container_ip" ]] && return 1

  install iptables

  iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP >/dev/null 2>&1 || true
  iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT >/dev/null 2>&1 || true
  iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT >/dev/null 2>&1 || true
  iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP >/dev/null 2>&1 || true
  iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT >/dev/null 2>&1 || true
  iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT >/dev/null 2>&1 || true
}

luopo_app_marketplace_delete_proxy_domain() {
  local target_domain="$1"
  rm -f "/home/web/conf.d/${target_domain}.conf"
  rm -f "/home/web/certs/${target_domain}_key.pem"
  rm -f "/home/web/certs/${target_domain}_cert.pem"
  docker exec nginx nginx -s reload >/dev/null 2>&1 || true
}

luopo_app_marketplace_sync_index() {
  clear
  cd ~ || return 1
  install git
  echo -e "${gl_kjlan}正在更新应用列表请稍等……${gl_bai}"
  if [[ ! -d apps/.git ]]; then
    timeout 10s git clone "${gh_proxy}github.com/kejilion/apps.git"
  else
    cd apps || return 1
    timeout 10s git pull "${gh_proxy}github.com/kejilion/apps.git" main >/dev/null 2>&1
  fi
}

luopo_app_marketplace_installed_numbers() {
  if [[ -f /home/docker/appno.txt ]]; then
    cat /home/docker/appno.txt
  fi
}

luopo_app_marketplace_is_installed() {
  local number="$1"
  luopo_app_marketplace_installed_numbers | grep -q "^${number}$"
}

luopo_app_marketplace_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_APP_MARKETPLACE_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_app_marketplace_item_label() {
  local item="$1"
  IFS='|' read -r _ label <<<"$item"
  printf '%s\n' "$label"
}

luopo_app_marketplace_item_number() {
  local item="$1"
  IFS='|' read -r number _ <<<"$item"
  printf '%s\n' "$number"
}

luopo_app_marketplace_render_cell() {
  local key="$1"
  local item color label

  item="$(luopo_app_marketplace_find_item "$key")" || return 1
  label="$(luopo_app_marketplace_item_label "$item")"
  color="$gl_bai"
  if [[ "$key" =~ ^[0-9]+$ ]] && luopo_app_marketplace_is_installed "$key"; then
    color="$gl_lv"
  fi
  printf "%b%-4s %b%s%b" "$gl_kjlan" "${key}." "$color" "$label" "$gl_bai"
}

luopo_app_marketplace_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

