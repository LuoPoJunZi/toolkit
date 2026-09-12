#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_APP_MARKETPLACE_DIR/../../.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT_DIR/modules/luopo/ldnmp/helpers.sh"

LUOPO_APP_MARKETPLACE_STATE_FILE="/home/docker/appno.txt"

declare -A LUOPO_APP_MARKETPLACE_LEGACY_IDS=(
  [3]="4"
  [4]="5"
  [5]="7"
  [6]="8"
  [7]="21"
  [8]="9"
  [9]="10"
  [10]="60"
  [11]="63"
  [12]="3"
  [13]="67"
  [14]="68"
  [15]="80"
  [16]="69"
  [17]="64"
  [18]="83"
  [21]="6"
  [22]="23"
  [23]="26"
  [24]="27"
  [25]="28"
  [26]="29"
  [27]="30"
  [28]="45"
  [29]="46"
  [30]="48"
  [31]="85"
  [41]="40"
  [42]="41"
  [43]="42"
  [45]="62"
  [51]="47"
  [52]="65"
  [61]="20"
  [62]="61"
  [63]="81"
  [64]="82"
  [65]="84"
  [66]="43"
  [67]="24"
  [68]="25"
  [69]="22"
  [71]="66"
)
declare -A LUOPO_APP_MARKETPLACE_LABELS=()
declare -A LUOPO_APP_MARKETPLACE_INSTALLED_IDS=()
LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY=0

luopo_app_marketplace_bootstrap() {
  return 0
}

luopo_app_marketplace_ip_address() {
  local public_ip isp_info

  public_ip="$(curl -fsS --max-time 3 https://ipinfo.io/ip || true)"
  isp_info="$(curl -fsS --max-time 3 https://ipinfo.io/org || true)"

  if echo "$isp_info" | grep -Eiq 'CHINANET|mobile|unicom|telecom'; then
    ipv4_address="$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || hostname -I 2>/dev/null | awk '{print $1}')"
  else
    ipv4_address="$public_ip"
  fi
  ipv6_address="$(curl -6 -fsS --max-time 2 https://api64.ipify.org || true)"
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

luopo_app_marketplace_refresh_render_cache() {
  local item number label
  LUOPO_APP_MARKETPLACE_LABELS=()
  LUOPO_APP_MARKETPLACE_INSTALLED_IDS=()

  for item in "${LUOPO_APP_MARKETPLACE_ITEMS[@]}"; do
    IFS='|' read -r number label <<<"$item"
    LUOPO_APP_MARKETPLACE_LABELS["$number"]="$label"
  done

  if [[ -f "$LUOPO_APP_MARKETPLACE_STATE_FILE" ]]; then
    while IFS= read -r number || [[ -n "$number" ]]; do
      [[ "$number" =~ ^[0-9]+$ ]] || continue
      LUOPO_APP_MARKETPLACE_INSTALLED_IDS["$number"]=1
    done <"$LUOPO_APP_MARKETPLACE_STATE_FILE"
  fi

  LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY=1
}

luopo_app_marketplace_is_installed() {
  local number="$1"
  local legacy_number
  if [[ "$LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY" != "1" ]]; then
    luopo_app_marketplace_refresh_render_cache
  fi
  if [[ -n "${LUOPO_APP_MARKETPLACE_INSTALLED_IDS[$number]+x}" ]]; then
    return 0
  fi

  legacy_number="${LUOPO_APP_MARKETPLACE_LEGACY_IDS[$number]:-}"
  [[ -n "$legacy_number" && -n "${LUOPO_APP_MARKETPLACE_INSTALLED_IDS[$legacy_number]+x}" ]]
}

luopo_app_marketplace_render_cell() {
  local key="$1"
  local color label

  if [[ "$LUOPO_APP_MARKETPLACE_RENDER_CACHE_READY" != "1" ]]; then
    luopo_app_marketplace_refresh_render_cache
  fi
  label="${LUOPO_APP_MARKETPLACE_LABELS[$key]:-}"
  [[ -n "$label" ]] || return 1
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
