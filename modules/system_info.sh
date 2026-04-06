#!/usr/bin/env bash
set -euo pipefail

print_kv() {
  local key="$1"
  local value="${2:-N/A}"
  printf '  %-12s : %s\n' "$key" "$value"
}

print_sep() {
  echo "-------------------------------------------------------------------------------"
}

print_head() {
  local title="$1"
  echo "[ $title ]"
}

format_kv() {
  local key="$1"
  local value="$2"
  printf '%-8s : %s' "$key" "${value:-N/A}"
}

print_two_col() {
  local l_key="$1"
  local l_val="$2"
  local r_key="$3"
  local r_val="$4"
  local left right
  left="$(format_kv "$l_key" "$l_val")"
  right="$(format_kv "$r_key" "$r_val")"
  printf '%-37s | %-37s\n' "$left" "$right"
}

print_single_col() {
  local key="$1"
  local value="$2"
  printf '%-8s : %s\n' "$key" "${value:-N/A}"
}

compact_dns() {
  local dns_raw="$1"
  if [[ -z "$dns_raw" || "$dns_raw" == "N/A" ]]; then
    echo "N/A"
    return
  fi

  # shellcheck disable=SC2206
  local items=($dns_raw)
  local count="${#items[@]}"

  if (( count <= 2 )); then
    echo "${items[*]}" | sed 's/ /, /g'
    return
  fi

  echo "${items[0]}, ${items[1]} (+$((count - 2)))"
}

to_cn_uptime() {
  local raw="$1"
  raw="${raw//up /}"
  raw="${raw//weeks/周}"
  raw="${raw//week/周}"
  raw="${raw//days/天}"
  raw="${raw//day/天}"
  raw="${raw//hours/小时}"
  raw="${raw//hour/小时}"
  raw="${raw//minutes/分钟}"
  raw="${raw//minute/分钟}"
  raw="${raw//seconds/秒}"
  raw="${raw//second/秒}"
  raw="${raw//, / }"
  echo "$raw"
}

space_slash() {
  local v="$1"
  echo "${v//\// / }"
}

human_bytes() {
  local bytes="${1:-0}"
  local normalized out
  normalized="$(awk -v b="$bytes" 'BEGIN { if (b=="" || b=="nan") print 0; else printf "%.0f", b+0 }')"

  if command -v numfmt >/dev/null 2>&1; then
    out="$(numfmt --to=iec --suffix=B "$normalized" 2>/dev/null || true)"
    if [[ -n "$out" ]]; then
      echo "$out"
      return
    fi
  fi

  awk -v n="$normalized" 'BEGIN {
    split("B KiB MiB GiB TiB PiB", u, " ");
    i=1;
    while (n>=1024 && i<6) { n=n/1024; i++ }
    if (i==1) printf "%.0f%s\n", n, u[i];
    else printf "%.2f%s\n", n, u[i];
  }'
}

get_os_pretty_name() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${PRETTY_NAME:-${NAME:-Unknown}}"
    return
  fi
  echo "Unknown"
}

get_cpu_model() {
  local model
  model="$(awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null || true)"
  if [[ -n "$model" ]]; then
    echo "$model"
    return
  fi
  echo "Unknown"
}

get_cpu_freq_ghz() {
  local mhz
  mhz="$(awk -F: '/cpu MHz/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null || true)"
  if [[ -n "$mhz" ]]; then
    awk -v m="$mhz" 'BEGIN { printf "%.2f GHz", m/1000 }'
    return
  fi
  echo "N/A"
}

get_cpu_usage_pct() {
  local user1 nice1 sys1 idle1 iowait1 irq1 softirq1 steal1 total1 idle_total1
  local user2 nice2 sys2 idle2 iowait2 irq2 softirq2 steal2 total2 idle_total2
  local total_diff idle_diff

  read -r _ user1 nice1 sys1 idle1 iowait1 irq1 softirq1 steal1 _ < /proc/stat
  total1=$((user1 + nice1 + sys1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
  idle_total1=$((idle1 + iowait1))

  sleep 0.4

  read -r _ user2 nice2 sys2 idle2 iowait2 irq2 softirq2 steal2 _ < /proc/stat
  total2=$((user2 + nice2 + sys2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
  idle_total2=$((idle2 + iowait2))

  total_diff=$((total2 - total1))
  idle_diff=$((idle_total2 - idle_total1))

  if (( total_diff <= 0 )); then
    echo "0%"
    return
  fi

  awk -v t="$total_diff" -v i="$idle_diff" 'BEGIN { printf "%.0f%%", (1 - i/t) * 100 }'
}

get_mem_info() {
  local total used swap_total swap_used mem_pct swap_pct
  read -r total used _ < <(free -m | awk '/^Mem:/ {print $2, $3, $7}')
  read -r swap_total swap_used < <(free -m | awk '/^Swap:/ {print $2, $3}')

  mem_pct="$(awk -v u="$used" -v t="$total" 'BEGIN { if (t>0) printf "%.2f", (u/t)*100; else print "0.00" }')"
  swap_pct="$(awk -v u="$swap_used" -v t="$swap_total" 'BEGIN { if (t>0) printf "%.2f", (u/t)*100; else print "0.00" }')"

  echo "${used}M/${total}M (${mem_pct}%)|${swap_used}M/${swap_total}M (${swap_pct}%)"
}

get_disk_info() {
  df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}'
}

get_conn_counts() {
  local tcp udp
  tcp="$(ss -t -aH 2>/dev/null | wc -l | tr -d ' ')"
  udp="$(ss -u -aH 2>/dev/null | wc -l | tr -d ' ')"
  echo "${tcp}|${udp}"
}

get_network_totals() {
  local rx tx
  read -r rx tx < <(awk -F'[: ]+' 'NR>2 && $1!="lo" {rx+=$3; tx+=$11} END {printf "%.0f %.0f\n", rx+0, tx+0}' /proc/net/dev)
  echo "$(human_bytes "$rx")|$(human_bytes "$tx")"
}

get_cc_algo() {
  local cc qdisc
  cc="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")"
  qdisc="$(sysctl -n net.core.default_qdisc 2>/dev/null || echo "unknown")"
  echo "$cc $qdisc"
}

get_public_ips() {
  local ipv4 ipv6
  ipv4="$(curl -4 -fsS --max-time 3 https://api.ipify.org 2>/dev/null || echo "N/A")"
  ipv6="$(curl -6 -fsS --max-time 3 https://api64.ipify.org 2>/dev/null || echo "N/A")"
  echo "$ipv4|$ipv6"
}

get_dns_servers() {
  awk '/^nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null | xargs echo
}

get_geo_info() {
  local json isp city country
  json="$(curl -fsS --max-time 3 https://ipinfo.io/json 2>/dev/null || true)"
  if [[ -z "$json" ]]; then
    echo "N/A|N/A"
    return
  fi
  isp="$(printf '%s' "$json" | sed -n 's/.*"org"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  city="$(printf '%s' "$json" | sed -n 's/.*"city"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  country="$(printf '%s' "$json" | sed -n 's/.*"country"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  echo "${isp:-N/A}|${country:-N/A} ${city:-}"
}

show_system_info() {
  local hostname os_name kernel cpu_arch cpu_model cpu_cores cpu_freq cpu_usage loadavg conns
  local mem_swap mem_info swap_info disk_info net_totals rx_total tx_total
  local algo ips ipv4 ipv6 dns geo isp location
  local now_str up_human up_cn tcp_count udp_count dns_compact
  local mem_pretty swap_pretty disk_pretty cpu_line flow_line

  hostname="$(hostname 2>/dev/null || echo "N/A")"
  os_name="$(get_os_pretty_name)"
  kernel="$(uname -r 2>/dev/null || echo "N/A")"
  cpu_arch="$(uname -m 2>/dev/null || echo "N/A")"
  cpu_model="$(get_cpu_model)"
  cpu_cores="$(nproc 2>/dev/null || echo "N/A")"
  cpu_freq="$(get_cpu_freq_ghz)"
  cpu_usage="$(get_cpu_usage_pct)"
  loadavg="$(awk '{print $1 ", " $2 ", " $3}' /proc/loadavg 2>/dev/null || echo "N/A")"
  conns="$(get_conn_counts)"

  mem_swap="$(get_mem_info)"
  mem_info="${mem_swap%%|*}"
  swap_info="${mem_swap##*|}"
  disk_info="$(get_disk_info)"

  net_totals="$(get_network_totals)"
  rx_total="${net_totals%%|*}"
  tx_total="${net_totals##*|}"
  rx_total="${rx_total:-N/A}"
  tx_total="${tx_total:-N/A}"

  algo="$(get_cc_algo)"
  ips="$(get_public_ips)"
  ipv4="${ips%%|*}"
  ipv6="${ips##*|}"
  dns="$(get_dns_servers)"

  geo="$(get_geo_info)"
  isp="${geo%%|*}"
  location="${geo##*|}"

  now_str="$(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo "N/A")"
  up_human="$(uptime -p 2>/dev/null | sed 's/^up //' || echo "N/A")"
  up_cn="$(to_cn_uptime "up $up_human")"
  tcp_count="${conns%%|*}"
  udp_count="${conns##*|}"
  dns_compact="$(compact_dns "${dns:-N/A}")"
  mem_pretty="$(space_slash "$mem_info")"
  swap_pretty="$(space_slash "$swap_info")"
  disk_pretty="$(space_slash "$disk_info")"
  cpu_line="${cpu_model} (${cpu_cores}核心 @ ${cpu_freq})"
  flow_line="接收: ${rx_total} | 发送: ${tx_total}"

  print_sep
  print_head "系统信息"
  print_two_col "主机名称" "$hostname" "系统版本" "$os_name"
  print_two_col "内核版本" "$kernel" "运行时长" "$up_cn"
  print_two_col "系统时间" "$now_str" "系统架构" "$cpu_arch"
  print_sep
  print_head "硬件与资源"
  print_single_col "处理器型" "$cpu_line"
  print_two_col "系统负载" "$loadavg" "CPU 占用" "$cpu_usage"
  print_two_col "物理内存" "$mem_pretty" "虚拟内存" "$swap_pretty"
  print_single_col "硬盘占用" "$disk_pretty"
  print_sep
  print_head "网络与位置"
  print_two_col "IPv4地址" "$ipv4" "网络运营" "$isp"
  print_two_col "IPv6地址" "$ipv6" "地理位置" "$location"
  print_two_col "网络连接" "TCP: ${tcp_count} | UDP: ${udp_count}" "网络流量" "$flow_line"
  print_two_col "网络算法" "$algo" "DNS地址" "${dns_compact:-N/A}"
  print_sep
}
