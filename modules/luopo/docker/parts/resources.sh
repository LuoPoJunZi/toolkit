#!/usr/bin/env bash
set -euo pipefail

# Docker container, image, network, and volume menus.

docker_run_selected_container_action() {
  local title="$1"
  local action="$2"
  local scope="${3:-all}"
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "$title" "没有可操作的容器" docker_container_selection_rows "$scope"; then
    return 0
  fi
  if ! docker "$action" "$DOCKER_SELECTED_VALUE"; then
    echo "容器操作失败: $DOCKER_SELECTED_LABEL"
  fi
}

docker_show_selected_container_logs() {
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要查看日志的容器" "没有可用容器" docker_container_selection_rows all; then
    return 0
  fi
  docker logs --tail 100 "$DOCKER_SELECTED_VALUE" || echo "容器日志读取失败: $DOCKER_SELECTED_LABEL"
}

docker_enter_selected_container() {
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要进入的运行中容器" "没有运行中的容器" docker_container_selection_rows running; then
    return 0
  fi
  docker exec -it "$DOCKER_SELECTED_VALUE" sh \
    || docker exec -it "$DOCKER_SELECTED_VALUE" bash \
    || echo "无法进入容器: $DOCKER_SELECTED_LABEL"
}

docker_remove_selected_container() {
  local container_id container_label
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要删除的容器" "没有可删除的容器" docker_container_selection_rows all; then
    return 0
  fi
  container_id="$DOCKER_SELECTED_VALUE"
  container_label="$DOCKER_SELECTED_LABEL"
  if ! docker_confirm_action "确认强制删除容器 ${container_label}？运行中的容器会先停止"; then
    return 0
  fi
  if docker rm -f "$container_id"; then
    echo "容器已删除: $container_label"
  else
    echo "容器删除失败: $container_label"
  fi
}

container_manager_menu() {
  local choice
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
        if docker_check_ready; then
          docker ps -a || true
        fi
        ;;
      2) docker_run_selected_container_action "选择要启动的容器" start all ;;
      3) docker_run_selected_container_action "选择要停止的运行中容器" stop running ;;
      4) docker_run_selected_container_action "选择要重启的容器" restart all ;;
      5) docker_show_selected_container_logs ;;
      6) docker_enter_selected_container ;;
      7) docker_remove_selected_container ;;
      0) return 0 ;;
      *) echo "无效选项" ;;
    esac
    echo ""
    read -r -p "按回车继续..." _
  done
}

docker_remove_selected_image() {
  local image image_label
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要删除的镜像" "没有可删除的镜像" docker_image_selection_rows; then
    return 0
  fi
  image="$DOCKER_SELECTED_VALUE"
  image_label="$DOCKER_SELECTED_LABEL"
  if ! docker_confirm_action "确认删除镜像 ${image_label}？"; then
    return 0
  fi
  if docker rmi "$image"; then
    echo "镜像已删除: $image_label"
  else
    echo "镜像删除失败，可能仍被容器使用: $image_label"
  fi
}

docker_prune_dangling_images() {
  local image_ids
  if ! docker_check_ready; then
    return 0
  fi
  if ! image_ids="$(docker image ls -q --filter dangling=true)"; then
    echo "悬空镜像读取失败"
    return 0
  fi
  if [[ -z "$image_ids" ]]; then
    echo "没有需要清理的悬空镜像"
    return 0
  fi
  echo "========================================"
  echo "将清理以下悬空镜像"
  echo "========================================"
  docker image ls --filter dangling=true
  echo "========================================"
  if docker_confirm_action "确认清理以上全部悬空镜像？"; then
    docker image prune -f || echo "悬空镜像清理失败"
  fi
}

docker_export_selected_image() {
  local image tar_file
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要导出的镜像" "没有可导出的镜像" docker_image_selection_rows; then
    return 0
  fi
  image="$DOCKER_SELECTED_VALUE"
  read -r -p "导出文件路径(如 /root/nginx.tar): " tar_file
  if [[ -z "$tar_file" ]]; then
    echo "未输入导出文件路径"
    return 0
  fi
  if docker save -o "$tar_file" "$image"; then
    echo "镜像已导出到: $tar_file"
  else
    echo "镜像导出失败: $DOCKER_SELECTED_LABEL"
  fi
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
        if docker_check_ready; then
          docker images || true
        fi
        ;;
      2)
        if docker_check_ready; then
          read -r -p "输入镜像名(如 nginx:alpine): " image
          docker pull "$image"
        fi
        ;;
      3) docker_remove_selected_image ;;
      4) docker_prune_dangling_images ;;
      5) docker_export_selected_image ;;
      6)
        if docker_check_ready; then
          read -r -p "输入tar文件路径: " tar_file
          docker load -i "$tar_file"
        fi
        ;;
      0) return 0 ;;
      *) echo "无效选项" ;;
    esac
    echo ""
    read -r -p "按回车继续..." _
  done
}

docker_inspect_selected_network() {
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要查看的网络" "没有可用网络" docker_network_selection_rows all; then
    return 0
  fi
  docker network inspect "$DOCKER_SELECTED_VALUE" || echo "网络详情读取失败: $DOCKER_SELECTED_LABEL"
}

docker_remove_selected_network() {
  local network_name network_label
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要删除的自定义网络" "没有可删除的自定义网络" docker_network_selection_rows removable; then
    return 0
  fi
  network_name="$DOCKER_SELECTED_VALUE"
  network_label="$DOCKER_SELECTED_LABEL"
  if ! docker_confirm_action "确认删除网络 ${network_label}？"; then
    return 0
  fi
  if docker network rm "$network_name"; then
    echo "网络已删除: $network_label"
  else
    echo "网络删除失败，可能仍有容器连接: $network_label"
  fi
}

docker_connect_container_to_network() {
  local network_name container_id container_label
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择目标网络" "没有可用网络" docker_network_selection_rows all; then
    return 0
  fi
  network_name="$DOCKER_SELECTED_VALUE"
  if ! docker_choose_resource "选择要连接的容器" "没有可用容器" docker_container_selection_rows all; then
    return 0
  fi
  container_id="$DOCKER_SELECTED_VALUE"
  container_label="$DOCKER_SELECTED_LABEL"
  if docker network connect "$network_name" "$container_id"; then
    echo "容器已连接到网络 ${network_name}: $container_label"
  else
    echo "容器连接网络失败，可能已经连接"
  fi
}

docker_disconnect_container_from_network() {
  local network_name container_name container_label
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择目标网络" "没有可用网络" docker_network_selection_rows all; then
    return 0
  fi
  network_name="$DOCKER_SELECTED_VALUE"
  if ! docker_choose_resource "选择要断开的容器" "该网络没有已连接的容器" docker_network_container_selection_rows "$network_name"; then
    return 0
  fi
  container_name="$DOCKER_SELECTED_VALUE"
  container_label="$DOCKER_SELECTED_LABEL"
  if docker network disconnect "$network_name" "$container_name"; then
    echo "容器已从网络 ${network_name} 断开: $container_label"
  else
    echo "容器断开网络失败: $container_label"
  fi
}

network_manager_menu() {
  local choice net_name
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
        if docker_check_ready; then
          docker network ls || true
        fi
        ;;
      2) docker_inspect_selected_network ;;
      3)
        if docker_check_ready; then
          read -r -p "输入新网络名称: " net_name
          docker network create "$net_name"
        fi
        ;;
      4) docker_remove_selected_network ;;
      5) docker_connect_container_to_network ;;
      6) docker_disconnect_container_from_network ;;
      0) return 0 ;;
      *) echo "无效选项" ;;
    esac
    echo ""
    read -r -p "按回车继续..." _
  done
}

volume_backup() {
  local vol backup_file backup_dir backup_name
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要备份的卷" "没有可备份的卷" docker_volume_selection_rows; then
    return 0
  fi
  vol="$DOCKER_SELECTED_VALUE"
  read -r -p "备份文件路径(如 /root/${vol}-backup.tar.gz): " backup_file
  if [[ -z "$backup_file" ]]; then
    echo "未输入备份文件路径"
    return 0
  fi

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
  local vol backup_file backup_dir backup_name
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要还原的目标卷" "没有可还原的目标卷，请先创建卷" docker_volume_selection_rows; then
    return 0
  fi
  vol="$DOCKER_SELECTED_VALUE"
  read -r -p "输入备份文件路径: " backup_file

  if [[ ! -f "$backup_file" ]]; then
    echo "备份文件不存在: $backup_file"
    return 0
  fi

  if ! docker_confirm_action "还原会覆盖卷 ${vol} 内的同名文件，确认继续？"; then
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

docker_inspect_selected_volume() {
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要查看的卷" "没有可用卷" docker_volume_selection_rows; then
    return 0
  fi
  docker volume inspect "$DOCKER_SELECTED_VALUE" || echo "卷详情读取失败: $DOCKER_SELECTED_LABEL"
}

docker_remove_selected_volume() {
  local volume_name volume_label
  if ! docker_check_ready; then
    return 0
  fi
  if ! docker_choose_resource "选择要删除的卷" "没有可删除的卷" docker_volume_selection_rows; then
    return 0
  fi
  volume_name="$DOCKER_SELECTED_VALUE"
  volume_label="$DOCKER_SELECTED_LABEL"
  if ! docker_confirm_action "确认删除卷 ${volume_label}？卷内数据将永久丢失"; then
    return 0
  fi
  if docker volume rm "$volume_name"; then
    echo "卷已删除: $volume_label"
  else
    echo "卷删除失败，可能仍被容器使用: $volume_label"
  fi
}

docker_prune_unused_volumes() {
  local volume_names
  if ! docker_check_ready; then
    return 0
  fi
  if ! volume_names="$(docker volume ls -q --filter dangling=true)"; then
    echo "未使用卷读取失败"
    return 0
  fi
  if [[ -z "$volume_names" ]]; then
    echo "没有需要清理的未使用卷"
    return 0
  fi
  echo "========================================"
  echo "将清理以下未使用卷"
  echo "========================================"
  docker volume ls --filter dangling=true
  echo "========================================"
  if docker_confirm_action "确认清理以上全部未使用卷？卷内数据将永久丢失"; then
    docker volume prune -f || echo "未使用卷清理失败"
  fi
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
        if docker_check_ready; then
          docker volume ls || true
        fi
        ;;
      2) docker_inspect_selected_volume ;;
      3)
        if docker_check_ready; then
          read -r -p "输入新卷名: " vol
          docker volume create "$vol"
        fi
        ;;
      4) docker_remove_selected_volume ;;
      5) docker_prune_unused_volumes ;;
      6) volume_backup ;;
      7) volume_restore ;;
      0) return 0 ;;
      *) echo "无效选项" ;;
    esac
    echo ""
    read -r -p "按回车继续..." _
  done
}
