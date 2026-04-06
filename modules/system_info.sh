#!/usr/bin/env bash
set -euo pipefail

print_kv() {
  local key="$1"
  local value="${2:-N/A}"
  printf '%-14s %s\n' "${key}:" "$value"
}

human_bytes() {
  local bytes="${1:-0}"
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec-i --suffix=B "$bytes"
    return
  fi
  echo "${bytes}B"
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
  read -r rx tx < <(awk -F'[: ]+' 'NR>2 && $1!="lo" {rx+=$3; tx+=$11} END {print rx+0, tx+0}' /proc/net/dev)
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
  local now_str up_human

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

  echo "正在查询系统信息……"
  echo "系统信息查询"
  echo "-------------"
  print_kv "主机名" "$hostname"
  print_kv "系统版本" "$os_name"
  print_kv "Linux版本" "$kernel"
  echo "-------------"
  print_kv "CPU架构" "$cpu_arch"
  print_kv "CPU型号" "$cpu_model"
  print_kv "CPU核心数" "$cpu_cores"
  print_kv "CPU频率" "$cpu_freq"
  echo "-------------"
  print_kv "CPU占用" "$cpu_usage"
  print_kv "系统负载" "$loadavg"
  print_kv "TCP|UDP连接数" "$conns"
  print_kv "物理内存" "$mem_info"
  print_kv "虚拟内存" "$swap_info"
  print_kv "硬盘占用" "$disk_info"
  echo "-------------"
  print_kv "总接收" "$rx_total"
  print_kv "总发送" "$tx_total"
  echo "-------------"
  print_kv "网络算法" "$algo"
  echo "-------------"
  print_kv "运营商" "$isp"
  print_kv "IPv4地址" "$ipv4"
  print_kv "IPv6地址" "$ipv6"
  print_kv "DNS地址" "${dns:-N/A}"
  print_kv "地理位置" "${location:-N/A}"
  print_kv "系统时间" "$now_str"
  echo "-------------"
  print_kv "运行时长" "$up_human"
  echo
  echo "操作完成"
}
