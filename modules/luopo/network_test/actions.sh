#!/usr/bin/env bash
set -euo pipefail

luopo_network_test_chatgpt_unlock() {
  luopo_network_test_run_shell "ChatGPT解锁状态检测" 'bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)'
}

luopo_network_test_region_unlock() {
  luopo_network_test_run_shell "Region流媒体解锁测试" 'bash <(curl -L -s check.unlock.media)'
}

luopo_network_test_yeahwu_unlock() {
  luopo_network_test_run_shell "yeahwu流媒体解锁检测" "install wget; wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash"
}

luopo_network_test_xykt_quality() {
  luopo_network_test_run_shell "xykt_IP质量体检脚本" 'bash <(curl -Ls IP.Check.Place)'
}

luopo_network_test_besttrace() {
  luopo_network_test_run_shell "besttrace三网回程延迟路由测试" 'install wget; wget -qO- git.io/besttrace | bash'
}

luopo_network_test_mtr_trace() {
  luopo_network_test_run_shell "mtr_trace三网回程线路测试" "curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash"
}

luopo_network_test_superspeed() {
  luopo_network_test_run_shell "Superspeed三网测速" 'bash <(curl -Lso- https://git.io/superspeed_uxh)'
}

luopo_network_test_nxtrace_fast() {
  luopo_network_test_run_shell "nxtrace快速回程测试脚本" 'curl nxtrace.org/nt | bash; nexttrace --fast-trace --tcp'
}

luopo_network_test_nxtrace_ip() {
  clear
  send_stats "nxtrace指定IP回程测试脚本"
  luopo_network_test_print_target_ip_reference
  read -r -p "输入一个指定IP: " testip
  if [[ -z "${testip:-}" ]]; then
    echo "未输入指定IP"
    luopo_network_test_finish
    return 0
  fi
  set +e
  eval "curl nxtrace.org/nt | bash; nexttrace \"$testip\""
  set -e
  luopo_network_test_finish
  return 0
}

luopo_network_test_ludashi() {
  luopo_network_test_run_shell "ludashi2020三网线路测试" "curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh"
}

luopo_network_test_iabc_speedtest() {
  luopo_network_test_run_shell "i-abc多功能测速脚本" "bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)"
}

luopo_network_test_netquality() {
  luopo_network_test_run_shell "网络质量测试脚本" 'bash <(curl -sL Net.Check.Place)'
}

luopo_network_test_yabs() {
  luopo_network_test_run_shell "yabs性能测试" 'check_swap; curl -sL yabs.sh | bash -s -- -i -5'
}

luopo_network_test_gb5_cpu() {
  luopo_network_test_run_shell "icu/gb5 CPU性能测试脚本" 'check_swap; bash <(curl -sL bash.icu/gb5)'
}

luopo_network_test_bench() {
  luopo_network_test_run_shell "bench性能测试" 'curl -Lso- bench.sh | bash'
}

luopo_network_test_spiritysdx() {
  luopo_network_test_run_shell "spiritysdx融合怪测评" "curl -L ${gh_proxy}github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh"
}

luopo_network_test_nodequality() {
  luopo_network_test_run_shell "nodequality融合怪测评" 'bash <(curl -sL https://run.NodeQuality.com)'
}
