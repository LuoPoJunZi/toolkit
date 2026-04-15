#!/usr/bin/env bash
set -euo pipefail

luopo_oracle_cloud_install_lookbusy() {
  clear
  echo "活跃脚本: CPU占用10-20% 内存占用20%"
  if ! luopo_oracle_cloud_confirm "确定安装吗？(Y/N): "; then
    luopo_oracle_cloud_finish
    return 0
  fi

  install_docker

  local DEFAULT_CPU_CORE=1
  local DEFAULT_CPU_UTIL="10-20"
  local DEFAULT_MEM_UTIL=20
  local DEFAULT_SPEEDTEST_INTERVAL=120

  read -r -p "请输入CPU核心数 [默认: $DEFAULT_CPU_CORE]: " cpu_core
  cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}
  read -r -p "请输入CPU占用百分比范围（例如10-20） [默认: $DEFAULT_CPU_UTIL]: " cpu_util
  cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}
  read -r -p "请输入内存占用百分比 [默认: $DEFAULT_MEM_UTIL]: " mem_util
  mem_util=${mem_util:-$DEFAULT_MEM_UTIL}
  read -r -p "请输入Speedtest间隔时间（秒） [默认: $DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
  speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

  clear
  send_stats "甲骨文云安装活跃脚本"
  set +e
  docker run -d --name=lookbusy --restart=always \
    -e TZ=Asia/Shanghai \
    -e CPU_UTIL="$cpu_util" \
    -e CPU_CORE="$cpu_core" \
    -e MEM_UTIL="$mem_util" \
    -e SPEEDTEST_INTERVAL="$speedtest_interval" \
    fogforest/lookbusy
  set -e
  luopo_oracle_cloud_finish
  return 0
}

luopo_oracle_cloud_remove_lookbusy() {
  luopo_oracle_cloud_run_shell "甲骨文云卸载活跃脚本" 'docker rm -f lookbusy 2>/dev/null || true; docker rmi fogforest/lookbusy 2>/dev/null || true'
}

luopo_oracle_cloud_dd_reinstall() {
  clear
  echo "重装系统"
  echo "--------------------------------"
  echo "注意: 重装有风险失联，不放心者慎用。重装预计花费15分钟，请提前备份数据。"
  if ! luopo_oracle_cloud_confirm "确定继续吗？(Y/N): "; then
    echo "已取消"
    luopo_oracle_cloud_finish
    return 0
  fi

  local xitong=""
  while true; do
    read -r -p "请选择要重装的系统:  1. Debian12 | 2. Ubuntu20.04 : " sys_choice
    case "$sys_choice" in
      1)
        xitong="-d 12"
        break
        ;;
      2)
        xitong="-u 20.04"
        break
        ;;
      *)
        echo "无效的选择，请重新输入。"
        ;;
    esac
  done

  read -r -p "请输入你重装后的密码: " vpspasswd
  clear
  send_stats "甲骨文云重装系统脚本"
  set +e
  install wget
  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p "$vpspasswd" -port 22
  set -e
  luopo_oracle_cloud_finish
  return 0
}

luopo_oracle_cloud_r_helper() {
  luopo_oracle_cloud_run_shell "R探长开机脚本" "bash <(wget -qO- ${gh_proxy}github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh)"
}

luopo_oracle_cloud_enable_root_password() {
  clear
  add_sshpasswd
  luopo_oracle_cloud_finish
  return 0
}

luopo_oracle_cloud_restore_ipv6() {
  clear
  send_stats "ipv6修复"
  set +e
  bash <(curl -L -s jhb.ovh/jb/v6.sh)
  echo "该功能由jhb大神提供，感谢他！"
  set -e
  luopo_oracle_cloud_finish
  return 0
}
