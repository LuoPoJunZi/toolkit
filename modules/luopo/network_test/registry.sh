#!/usr/bin/env bash
set -euo pipefail

LUOPO_NETWORK_TEST_SECTIONS=(
  "ip_unlock|IP及解锁状态检测"
  "route|网络线路测速"
  "hardware|硬件性能测试"
  "benchmark|综合性测试"
)

LUOPO_NETWORK_TEST_ITEMS=(
  "1|ChatGPT 解锁状态检测|luopo_network_test_chatgpt_unlock|ip_unlock"
  "2|Region 流媒体解锁测试|luopo_network_test_region_unlock|ip_unlock"
  "3|yeahwu 流媒体解锁检测|luopo_network_test_yeahwu_unlock|ip_unlock"
  "4|xykt IP质量体检脚本 ★|luopo_network_test_xykt_quality|ip_unlock"
  "11|besttrace 三网回程延迟路由测试|luopo_network_test_besttrace|route"
  "12|mtr_trace 三网回程线路测试|luopo_network_test_mtr_trace|route"
  "13|Superspeed 三网测速|luopo_network_test_superspeed|route"
  "14|nxtrace 快速回程测试脚本|luopo_network_test_nxtrace_fast|route"
  "15|nxtrace 指定IP回程测试脚本|luopo_network_test_nxtrace_ip|route"
  "16|ludashi2020 三网线路测试|luopo_network_test_ludashi|route"
  "17|i-abc 多功能测速脚本|luopo_network_test_iabc_speedtest|route"
  "18|NetQuality 网络质量体检脚本 ★|luopo_network_test_netquality|route"
  "21|yabs 性能测试|luopo_network_test_yabs|hardware"
  "22|icu/gb5 CPU性能测试脚本|luopo_network_test_gb5_cpu|hardware"
  "31|bench 性能测试|luopo_network_test_bench|benchmark"
  "32|spiritysdx 融合怪测评 ★|luopo_network_test_spiritysdx|benchmark"
  "33|nodequality 融合怪测评 ★|luopo_network_test_nodequality|benchmark"
)

luopo_network_test_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_NETWORK_TEST_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_network_test_item_number() {
  local item="$1"
  IFS='|' read -r number _ <<<"$item"
  printf '%s\n' "$number"
}

luopo_network_test_item_label() {
  local item="$1"
  IFS='|' read -r _ label _ <<<"$item"
  printf '%s\n' "$label"
}

luopo_network_test_item_handler() {
  local item="$1"
  IFS='|' read -r _ _ handler _ <<<"$item"
  printf '%s\n' "$handler"
}

luopo_network_test_item_group() {
  local item="$1"
  IFS='|' read -r _ _ _ group <<<"$item"
  printf '%s\n' "$group"
}
