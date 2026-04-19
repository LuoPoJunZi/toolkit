#!/usr/bin/env bash
set -euo pipefail

LUOPO_DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LUOPO_DOCKER_PARTS_DIR="$LUOPO_DOCKER_DIR/parts"

# shellcheck disable=SC1091
source "$LUOPO_DOCKER_PARTS_DIR/common.sh"
# shellcheck disable=SC1091
source "$LUOPO_DOCKER_PARTS_DIR/install_status.sh"
# shellcheck disable=SC1091
source "$LUOPO_DOCKER_PARTS_DIR/resources.sh"
# shellcheck disable=SC1091
source "$LUOPO_DOCKER_PARTS_DIR/daemon_backup.sh"

docker_manager() {
  local choice
  while true; do
    clear
    echo "Docker管理"
    echo "------------------------"
    print_docker_overview
    echo "------------------------"
    menu_item "1" "安装更新Docker环境"
    echo "------------------------"
    menu_item "2" "查看Docker全局状态"
    echo "------------------------"
    menu_item "3" "Docker容器管理"
    menu_item "4" "Docker镜像管理"
    menu_item "5" "Docker网络管理"
    menu_item "6" "Docker卷管理"
    echo "------------------------"
    menu_item "7" "清理无用Docker容器/镜像/网络/卷"
    echo "------------------------"
    menu_item "8" "更换Docker源"
    menu_item "9" "编辑daemon.json文件"
    echo "------------------------"
    menu_item "11" "开启Docker IPv6访问"
    menu_item "12" "关闭Docker IPv6访问"
    echo "------------------------"
    menu_item "19" "备份/迁移/还原Docker环境"
    menu_item "20" "卸载Docker环境"
    echo "------------------------"
    menu_item "0" "返回上级菜单"
    echo "------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1)
        install_update_docker
        ;;
      2)
        docker_global_status
        ;;
      3)
        container_manager_menu
        continue
        ;;
      4)
        image_manager_menu
        continue
        ;;
      5)
        network_manager_menu
        continue
        ;;
      6)
        volume_manager_menu
        continue
        ;;
      7)
        docker_cleanup_all
        ;;
      8)
        switch_docker_mirror
        ;;
      9)
        edit_daemon_json
        ;;
      11)
        enable_docker_ipv6
        ;;
      12)
        disable_docker_ipv6
        ;;
      19)
        backup_migrate_restore_menu
        continue
        ;;
      20)
        uninstall_docker_env
        ;;
      0)
        return 0
        ;;
      *)
        echo "无效选项"
        ;;
    esac

    echo ""
    read -r -p "按回车继续..." _
  done
}
