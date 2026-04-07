#!/usr/bin/env bash
set -euo pipefail

network_test_menu() {
  local choice target
  while true; do
    clear
    echo "========================================"
    echo "网络测试工具"
    echo "========================================"
    menu_item "1" "基础连通性测试 (Ping)"
    menu_item "2" "路由追踪 (Traceroute)"
    menu_item "3" "MTR 质量测试"
    menu_item "4" "DNS 解析测试"
    echo "------------------------"
    menu_item "21" "TLS 证书链检测"
    menu_item "22" "常见端口连通性检测"
    menu_item "23" "下载测速（100MB 文件）"
    menu_item "24" "本机网络质量汇总"
    echo "------------------------"
    menu_item "31" "一键测速脚本（hyperspeed）"
    menu_item "32" "回程测试脚本（nexttrace）"
    menu_item "33" "IPv4/IPv6 连通性快速检测"
    menu_item "34" "DNS 延迟测试 (dig)"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1)
        read -r -p "输入目标域名/IP(默认 1.1.1.1): " target
        target="${target:-1.1.1.1}"
        ping -c 4 "$target" || say_warn "Ping 失败"
        menu_wait
        ;;
      2)
        try_install_pkg traceroute
        read -r -p "输入目标域名/IP(默认 1.1.1.1): " target
        target="${target:-1.1.1.1}"
        traceroute "$target" 2>/dev/null || say_warn "traceroute 不可用"
        menu_wait
        ;;
      3)
        try_install_pkg mtr
        read -r -p "输入目标域名/IP(默认 1.1.1.1): " target
        target="${target:-1.1.1.1}"
        mtr -r -c 10 "$target" 2>/dev/null || say_warn "mtr 不可用"
        menu_wait
        ;;
      4)
        read -r -p "输入域名(默认 github.com): " target
        target="${target:-github.com}"
        getent ahosts "$target" || say_warn "DNS 查询失败"
        menu_wait
        ;;
      21)
        read -r -p "输入域名(默认 github.com): " target
        target="${target:-github.com}"
        echo | openssl s_client -connect "${target}:443" -servername "$target" 2>/dev/null | openssl x509 -noout -issuer -subject -dates || say_warn "检测失败"
        menu_wait
        ;;
      22)
        read -r -p "输入目标主机(默认 127.0.0.1): " target
        target="${target:-127.0.0.1}"
        for p in 22 80 443 8080 8443; do
          timeout 2 bash -c "cat < /dev/null > /dev/tcp/${target}/${p}" 2>/dev/null && echo "${target}:${p} open" || echo "${target}:${p} closed"
        done
        menu_wait
        ;;
      23)
        if ! curl -L -o /dev/null -w '下载速度: %{speed_download} bytes/s\n总耗时: %{time_total}s\n' https://speed.cloudflare.com/__down?bytes=100000000; then
          say_action_failed "下载测速" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      24)
        echo "=== 接口 ==="
        ip -br a
        echo "=== 路由 ==="
        ip route
        echo "=== 连接统计 ==="
        ss -s
        menu_wait
        ;;
      31)
        if ! bash <(curl -Lso- https://bench.im/hyperspeed); then
          say_action_failed "hyperspeed 测速脚本" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      32)
        if ! bash <(curl -Ls https://raw.githubusercontent.com/nxtrace/NTrace-core/main/nt_install.sh); then
          say_action_failed "nexttrace 回程测试脚本" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      33)
        ping -c 2 1.1.1.1 >/dev/null 2>&1 && echo "IPv4: OK" || echo "IPv4: FAIL"
        ping -6 -c 2 2606:4700:4700::1111 >/dev/null 2>&1 && echo "IPv6: OK" || echo "IPv6: FAIL"
        menu_wait
        ;;
      34)
        try_install_pkg dnsutils
        dig +stats github.com 2>/dev/null | tail -n 5 || say_warn "dig 不可用"
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

