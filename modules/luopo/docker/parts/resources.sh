#!/usr/bin/env bash
set -euo pipefail

# Docker container, image, network, and volume menus.

container_manager_menu() {
  local choice cid
  while true; do
    clear
    echo "========================================"
    echo "Docker容器管理"
    echo "========================================"
    menu_item "1" "查看容器列表"
    menu_item "2" "启动容器"
    menu_item "3" "停止容器"
    menu_item "4" "重启容器"
    menu_item "5" "查看容器日志(最近100行)"
    menu_item "6" "进入容器Shell"
    menu_item "7" "删除容器"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read -r -p "请输入选择: " choice

    case "$choice" in
      1)
        docker_check_ready && docker ps -a || true
        ;;
      2)
        if docker_check_ready; then
          read -r -p "输入容器名/容器ID: " cid
          docker start "$cid"
        fi
        ;;
      3)
        if docker_check_ready; then
          read -r -p "输入容器名/容器ID: " cid
          docker stop "$cid"
        fi
        ;;
      4)
        if docker_check_ready; then
          read -r -p "输入容器名/容器ID: " cid
          docker restart "$cid"
        fi
        ;;
      5)
        if docker_check_ready; then
          read -r -p "输入容器名/容器ID: " cid
          docker logs --tail 100 "$cid"
        fi
        ;;
      6)
        if docker_check_ready; then
          read -r -p "输入容器名/容器ID: " cid
          docker exec -it "$cid" sh || docker exec -it "$cid" bash || true
        fi
        ;;
      7)
        if docker_check_ready; then
          read -r -p "输入容器名/容器ID: " cid
          read -r -p "确认删除容器 ${cid} ? (y/N): " ans
          if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
            docker rm -f "$cid"
          else
            echo "已取消"
          fi
        fi
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

image_manager_menu() {
  local choice image tar_file
  while true; do
    clear
    echo "========================================"
    echo "Docker镜像管理"
    echo "========================================"
    menu_item "1" "查看镜像列表"
    menu_item "2" "拉取镜像"
    menu_item "3" "删除镜像"
    menu_item "4" "清理悬空镜像"
    menu_item "5" "导出镜像到tar"
    menu_item "6" "从tar导入镜像"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read -r -p "请输入选择: " choice

    case "$choice" in
      1)
        docker_check_ready && docker images || true
        ;;
      2)
        if docker_check_ready; then
          read -r -p "输入镜像名(如 nginx:alpine): " image
          docker pull "$image"
        fi
        ;;
      3)
        if docker_check_ready; then
          read -r -p "输入镜像名/IMAGE ID: " image
          docker rmi "$image"
        fi
        ;;
      4)
        docker_check_ready && docker image prune -f || true
        ;;
      5)
        if docker_check_ready; then
          read -r -p "输入镜像名(如 nginx:alpine): " image
          read -r -p "导出文件路径(如 /root/nginx.tar): " tar_file
          docker save -o "$tar_file" "$image"
          echo "镜像已导出到: $tar_file"
        fi
        ;;
      6)
        if docker_check_ready; then
          read -r -p "输入tar文件路径: " tar_file
          docker load -i "$tar_file"
        fi
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

network_manager_menu() {
  local choice net_name cid
  while true; do
    clear
    echo "========================================"
    echo "Docker网络管理"
    echo "========================================"
    menu_item "1" "查看网络列表"
    menu_item "2" "查看网络详情"
    menu_item "3" "创建桥接网络"
    menu_item "4" "删除网络"
    menu_item "5" "连接容器到网络"
    menu_item "6" "从网络断开容器"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read -r -p "请输入选择: " choice

    case "$choice" in
      1)
        docker_check_ready && docker network ls || true
        ;;
      2)
        if docker_check_ready; then
          read -r -p "输入网络名/NETWORK ID: " net_name
          docker network inspect "$net_name"
        fi
        ;;
      3)
        if docker_check_ready; then
          read -r -p "输入新网络名称: " net_name
          docker network create "$net_name"
        fi
        ;;
      4)
        if docker_check_ready; then
          read -r -p "输入网络名/NETWORK ID: " net_name
          docker network rm "$net_name"
        fi
        ;;
      5)
        if docker_check_ready; then
          read -r -p "输入网络名: " net_name
          read -r -p "输入容器名/容器ID: " cid
          docker network connect "$net_name" "$cid"
        fi
        ;;
      6)
        if docker_check_ready; then
          read -r -p "输入网络名: " net_name
          read -r -p "输入容器名/容器ID: " cid
          docker network disconnect "$net_name" "$cid"
        fi
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

volume_backup() {
  local vol backup_file backup_dir backup_name
  if ! docker_check_ready; then
    return 1
  fi

  read -r -p "输入要备份的卷名: " vol
  read -r -p "备份文件路径(如 /root/${vol}-backup.tar.gz): " backup_file

  backup_dir="$(dirname "$backup_file")"
  backup_name="$(basename "$backup_file")"
  mkdir -p "$backup_dir"

  docker run --rm \
    -v "${vol}:/volume" \
    -v "${backup_dir}:/backup" \
    alpine sh -c "cd /volume && tar czf /backup/${backup_name} ."

  echo "卷备份完成: $backup_file"
}

volume_restore() {
  local vol backup_file backup_dir backup_name ans
  if ! docker_check_ready; then
    return 1
  fi

  read -r -p "输入要还原的卷名: " vol
  read -r -p "输入备份文件路径: " backup_file

  if [[ ! -f "$backup_file" ]]; then
    echo "备份文件不存在: $backup_file"
    return 1
  fi

  read -r -p "还原会覆盖卷内文件，确认继续？(y/N): " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "已取消"
    return 0
  fi

  backup_dir="$(dirname "$backup_file")"
  backup_name="$(basename "$backup_file")"

  docker run --rm \
    -v "${vol}:/volume" \
    -v "${backup_dir}:/backup" \
    alpine sh -c "cd /volume && tar xzf /backup/${backup_name}"

  echo "卷还原完成"
}

volume_manager_menu() {
  local choice vol
  while true; do
    clear
    echo "========================================"
    echo "Docker卷管理"
    echo "========================================"
    menu_item "1" "查看卷列表"
    menu_item "2" "查看卷详情"
    menu_item "3" "创建卷"
    menu_item "4" "删除卷"
    menu_item "5" "清理未使用卷"
    menu_item "6" "备份卷到tar.gz"
    menu_item "7" "从tar.gz还原卷"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read -r -p "请输入选择: " choice

    case "$choice" in
      1)
        docker_check_ready && docker volume ls || true
        ;;
      2)
        if docker_check_ready; then
          read -r -p "输入卷名: " vol
          docker volume inspect "$vol"
        fi
        ;;
      3)
        if docker_check_ready; then
          read -r -p "输入新卷名: " vol
          docker volume create "$vol"
        fi
        ;;
      4)
        if docker_check_ready; then
          read -r -p "输入卷名: " vol
          docker volume rm "$vol"
        fi
        ;;
      5)
        docker_check_ready && docker volume prune -f || true
        ;;
      6)
        volume_backup || true
        ;;
      7)
        volume_restore || true
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
