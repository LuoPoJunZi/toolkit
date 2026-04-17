#!/usr/bin/env bash
set -euo pipefail

luopo_network_test_bootstrap() {
  return 0
}

luopo_network_test_finish() {
  break_end
}

luopo_network_test_run() {
  local stat_name="$1"
  shift

  clear
  send_stats "$stat_name"
  set +e
  "$@"
  set -e
  luopo_network_test_finish
  return 0
}

luopo_network_test_run_shell() {
  local stat_name="$1"
  local command="$2"

  clear
  send_stats "$stat_name"
  set +e
  eval "$command"
  set -e
  luopo_network_test_finish
  return 0
}

luopo_network_test_print_target_ip_reference() {
  cat <<'EOF'
可参考的IP列表
------------------------
北京电信: 219.141.136.12
北京联通: 202.106.50.1
北京移动: 221.179.155.161
上海电信: 202.96.209.133
上海联通: 210.22.97.1
上海移动: 211.136.112.200
广州电信: 58.60.188.222
广州联通: 210.21.196.6
广州移动: 120.196.165.24
成都电信: 61.139.2.69
成都联通: 119.6.6.6
成都移动: 211.137.96.205
湖南电信: 36.111.200.100
湖南联通: 42.48.16.100
湖南移动: 39.134.254.6
------------------------
EOF
}

luopo_network_test_invalid_choice() {
  echo "无效的输入!"
  press_enter
}
