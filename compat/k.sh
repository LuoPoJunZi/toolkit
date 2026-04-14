#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export KEJILION_LIBRARY_MODE=1
# shellcheck disable=SC1091
source "$ROOT_DIR/vendor/luopo.sh"
export ENABLE_STATS="false"
set +e +u

if [ "$#" -eq 0 ]; then
  exec bash "$ROOT_DIR/toolkit.sh"
else
  case $1 in
    install|add|安装)
      shift
      send_stats "安装软件"
      install "$@"
      ;;
    remove|del|uninstall|卸载)
      shift
      send_stats "卸载软件"
      remove "$@"
      ;;
    update|更新)
      linux_update
      ;;
    clean|清理)
      linux_clean
      ;;
    dd|重装)
      dd_xitong
      ;;
    bbr3|bbrv3)
      bbrv3
      ;;
    nhyh|内核优化)
      Kernel_optimize
      ;;
    trash|hsz|回收站)
      linux_trash
      ;;
    backup|bf|备份)
      linux_backup
      ;;
    ssh|远程连接)
      ssh_manager
      ;;
    rsync|远程同步)
      rsync_manager
      ;;
    rsync_run)
      shift
      send_stats "定时rsync同步"
      run_task "$@"
      ;;
    disk|硬盘管理)
      disk_manager
      ;;
    wp|wordpress)
      shift
      ldnmp_wp "$@"
      ;;
    fd|rp|反代)
      shift
      ldnmp_Proxy "$@"
      find_container_by_host_port "$port"
      if [ -z "$docker_name" ]; then
        close_port "$port"
        echo "已阻止IP+端口访问该服务"
      else
        ip_address
        close_port "$port"
        block_container_port "$docker_name" "$ipv4_address"
      fi
      ;;
    loadbalance|负载均衡)
      ldnmp_Proxy_backend
      ;;
    stream|L4负载均衡)
      ldnmp_Proxy_backend_stream
      ;;
    swap)
      shift
      send_stats "快速设置虚拟内存"
      add_swap "$@"
      ;;
    time|时区)
      shift
      send_stats "快速设置时区"
      set_timedate "$@"
      ;;
    iptables_open)
      iptables_open
      ;;
    frps)
      frps_panel
      ;;
    frpc)
      frpc_panel
      ;;
    打开端口|dkdk)
      shift
      open_port "$@"
      ;;
    关闭端口|gbdk)
      shift
      close_port "$@"
      ;;
    放行IP|fxip)
      shift
      allow_ip "$@"
      ;;
    阻止IP|zzip)
      shift
      block_ip "$@"
      ;;
    防火墙|fhq)
      iptables_panel
      ;;
    命令收藏夹|fav)
      linux_fav
      ;;
    status|状态)
      shift
      send_stats "软件状态查看"
      status "$@"
      ;;
    start|启动)
      shift
      send_stats "软件启动"
      start "$@"
      ;;
    stop|停止)
      shift
      send_stats "软件暂停"
      stop "$@"
      ;;
    restart|重启)
      shift
      send_stats "软件重启"
      restart "$@"
      ;;
    enable|autostart|开机启动)
      shift
      send_stats "软件开机自启"
      enable "$@"
      ;;
    ssl)
      shift
      if [ "$1" = "ps" ]; then
        send_stats "查看证书状态"
        ssl_ps
      elif [ -z "$1" ]; then
        add_ssl
        send_stats "快速申请证书"
      elif [ -n "$1" ]; then
        add_ssl "$1"
        send_stats "快速申请证书"
      else
        k_info
      fi
      ;;
    docker)
      shift
      case $1 in
        install|安装)
          send_stats "快捷安装docker"
          install_docker
          ;;
        ps|容器)
          send_stats "快捷容器管理"
          docker_ps
          ;;
        img|镜像)
          send_stats "快捷镜像管理"
          docker_image
          ;;
        *)
          linux_docker
          ;;
      esac
      ;;
    web)
      shift
      if [ "$1" = "cache" ]; then
        web_cache
      elif [ "$1" = "sec" ]; then
        web_security
      elif [ "$1" = "opt" ]; then
        web_optimization
      elif [ -z "$1" ]; then
        ldnmp_web_status
      else
        k_info
      fi
      ;;
    app)
      shift
      send_stats "应用$@"
      linux_panel "$@"
      ;;
    claw|oc|OpenClaw)
      moltbot_menu
      ;;
    info)
      linux_info
      ;;
    fail2ban|f2b)
      fail2ban_panel
      ;;
    sshkey)
      shift
      case "$1" in
        "")
          send_stats "SSHKey 交互菜单"
          sshkey_panel
          ;;
        github)
          shift
          send_stats "从 GitHub 导入 SSH 公钥"
          fetch_github_ssh_keys "$1"
          ;;
        http://*|https://*)
          send_stats "从 URL 导入 SSH 公钥"
          fetch_remote_ssh_keys "$1"
          ;;
        ssh-rsa*|ssh-ed25519*|ssh-ecdsa*)
          send_stats "公钥直接导入"
          import_sshkey "$1"
          ;;
        *)
          echo "错误：未知参数 '$1'"
          echo "用法："
          echo "  k sshkey                  进入交互菜单"
          echo "  k sshkey \"<pubkey>\"     直接导入 SSH 公钥"
          echo "  k sshkey <url>            从 URL 导入 SSH 公钥"
          echo "  k sshkey github <user>    从 GitHub 导入 SSH 公钥"
          ;;
      esac
      ;;
    *)
      k_info
      ;;
  esac
fi
