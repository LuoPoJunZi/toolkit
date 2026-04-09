#!/usr/bin/env bash
set -euo pipefail

DAEMON_JSON="/etc/docker/daemon.json"

service_action() {
  local action="$1"
  local svc="$2"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl "$action" "$svc" >/dev/null 2>&1
  else
    service "$svc" "$action" >/dev/null 2>&1
  fi
}

docker_installed() {
  command -v docker >/dev/null 2>&1
}

docker_compose_version() {
  if docker compose version >/dev/null 2>&1; then
    docker compose version
    return
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose version --short 2>/dev/null | awk '{print "Docker Compose version " $0}'
    return
  fi
  echo "Docker Compose version N/A"
}

count_by_command() {
  local out
  out="$($@ 2>/dev/null || true)"
  if [[ -z "$out" ]]; then
    echo "0"
    return
  fi
  printf '%s\n' "$out" | sed '/^$/d' | wc -l | tr -d ' '
}

get_docker_counts() {
  if ! docker_installed; then
    echo "未安装|0|0|0|0"
    return
  fi

  local c i n v
  c="$(count_by_command docker ps -a -q)"
  i="$(count_by_command docker images -q)"
  n="$(count_by_command docker network ls -q)"
  v="$(count_by_command docker volume ls -q)"
  echo "已安装|${c}|${i}|${n}|${v}"
}

print_docker_overview() {
  local info state c i n v
  info="$(get_docker_counts)"
  state="${info%%|*}"
  info="${info#*|}"
  c="${info%%|*}"
  info="${info#*|}"
  i="${info%%|*}"
  info="${info#*|}"
  n="${info%%|*}"
  v="${info##*|}"

  echo "环境${state}  容器: ${c}  镜像: ${i}  网络: ${n}  卷: ${v}"
}

docker_check_ready() {
  if ! docker_installed; then
    echo "Docker 未安装，请先执行 '1. 安装更新Docker环境'"
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Docker 服务未就绪，请先启动 Docker 服务"
    return 1
  fi
  return 0
}

ensure_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "当前系统不支持 apt-get，暂不支持自动安装/卸载 Docker"
    return 1
  fi
  return 0
}

install_update_docker() {
  if ! ensure_apt; then
    return 1
  fi

  echo "开始安装/更新 Docker 环境..."
  apt-get update -y
  apt-get install -y docker.io containerd runc
  apt-get install -y docker-compose-plugin || apt-get install -y docker-compose || true

  service_action enable docker || true
  service_action start docker || true

  echo "Docker 环境安装/更新完成"
}

docker_global_status() {
  if ! docker_check_ready; then
    return 1
  fi

  echo "Docker版本"
  docker version --format 'Docker version {{.Server.Version}}' 2>/dev/null || docker version 2>/dev/null || true
  docker_compose_version
  echo

  echo "Docker镜像: $(count_by_command docker images -q)"
  docker images 2>/dev/null || true
  echo

  echo "Docker容器: $(count_by_command docker ps -a -q)"
  docker ps -a 2>/dev/null || true
  echo

  echo "Docker卷: $(count_by_command docker volume ls -q)"
  docker volume ls 2>/dev/null || true
  echo

  echo "Docker网络: $(count_by_command docker network ls -q)"
  docker network ls 2>/dev/null || true
}

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

docker_cleanup_all() {
  if ! docker_check_ready; then
    return 1
  fi

  read -r -p "将执行 docker system prune -a --volumes -f，确认继续？(y/N): " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "已取消"
    return 0
  fi
  docker system prune -a --volumes -f
}

ensure_daemon_json() {
  mkdir -p /etc/docker
  if [[ ! -f "$DAEMON_JSON" || ! -s "$DAEMON_JSON" ]]; then
    echo '{}' > "$DAEMON_JSON"
    return
  fi
  if ! jq empty "$DAEMON_JSON" >/dev/null 2>&1; then
    local backup_path
    backup_path="${DAEMON_JSON}.bak.$(date +%Y%m%d_%H%M%S)"
    cp -a "$DAEMON_JSON" "$backup_path"
    echo "检测到 daemon.json 非法，已备份到: $backup_path"
    echo '{}' > "$DAEMON_JSON"
  fi
}

ensure_jq_installed() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  if ! ensure_apt; then
    return 1
  fi
  echo "缺少 jq，正在安装..."
  apt-get update -y
  apt-get install -y jq
}

apply_daemon_jq_filter() {
  local backup_path tmp

  if ! ensure_jq_installed; then
    return 1
  fi

  ensure_daemon_json
  backup_path="${DAEMON_JSON}.bak.$(date +%Y%m%d_%H%M%S)"
  cp -a "$DAEMON_JSON" "$backup_path"

  tmp="$(mktemp)"
  if ! jq "$@" "$DAEMON_JSON" > "$tmp"; then
    rm -f "$tmp"
    echo "daemon.json 修改失败"
    return 1
  fi
  mv "$tmp" "$DAEMON_JSON"

  if service_action restart docker; then
    echo "配置已生效"
    return 0
  fi

  echo "Docker 重启失败，回滚到修改前配置"
  cp -a "$backup_path" "$DAEMON_JSON"
  service_action restart docker
  return 1
}

switch_docker_mirror() {
  local choice mirror
  echo "可选镜像源:"
  echo "1) DaoCloud: https://docker.m.daocloud.io"
  echo "2) 1Panel: https://docker.1panel.live"
  echo "3) 腾讯云: https://mirror.ccs.tencentyun.com"
  echo "4) 自定义镜像源"
  echo "5) 清空镜像源"
  read -r -p "请选择: " choice

  case "$choice" in
    1) mirror="https://docker.m.daocloud.io" ;;
    2) mirror="https://docker.1panel.live" ;;
    3) mirror="https://mirror.ccs.tencentyun.com" ;;
    4) read -r -p "请输入自定义镜像源URL: " mirror ;;
    5)
      apply_daemon_jq_filter 'del(."registry-mirrors")'
      return $?
      ;;
    *)
      echo "无效选项"
      return 1
      ;;
  esac

  apply_daemon_jq_filter --arg mirror "$mirror" '."registry-mirrors" = [$mirror]'
}

edit_daemon_json() {
  mkdir -p /etc/docker
  [[ -f "$DAEMON_JSON" ]] || echo '{}' > "$DAEMON_JSON"

  if command -v nano >/dev/null 2>&1; then
    nano "$DAEMON_JSON"
  else
    vi "$DAEMON_JSON"
  fi

  if service_action restart docker; then
    echo "Docker 已重启并应用配置"
  else
    echo "Docker 重启失败，请检查 $DAEMON_JSON"
    return 1
  fi
}

enable_docker_ipv6() {
  apply_daemon_jq_filter '.ipv6 = true | ."fixed-cidr-v6" = "fd00:dead:beef::/48"'
}

disable_docker_ipv6() {
  apply_daemon_jq_filter 'del(.ipv6, ."fixed-cidr-v6")'
}

backup_docker_metadata() {
  local out_dir ts
  if ! docker_check_ready; then
    return 1
  fi

  ts="$(date +%Y%m%d_%H%M%S)"
  out_dir="/root/docker-backups/metadata-${ts}"

  mkdir -p "$out_dir"
  docker ps -a > "${out_dir}/containers.txt" 2>/dev/null || true
  docker images > "${out_dir}/images.txt" 2>/dev/null || true
  docker network ls > "${out_dir}/networks.txt" 2>/dev/null || true
  docker volume ls > "${out_dir}/volumes.txt" 2>/dev/null || true
  cp -a /etc/docker "${out_dir}/etc-docker" 2>/dev/null || true

  echo "元数据备份完成: $out_dir"
}

export_all_images() {
  local images out_file
  if ! docker_check_ready; then
    return 1
  fi

  images="$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -v '<none>' || true)"
  if [[ -z "$images" ]]; then
    echo "没有可导出的镜像"
    return 0
  fi

  read -r -p "导出文件路径(如 /root/docker-backups/all-images.tar): " out_file
  mkdir -p "$(dirname "$out_file")"

  # shellcheck disable=SC2086
  docker save -o "$out_file" $images
  echo "镜像导出完成: $out_file"
}

import_images_from_tar() {
  local in_file
  if ! docker_check_ready; then
    return 1
  fi
  read -r -p "输入镜像tar文件路径: " in_file
  if [[ ! -f "$in_file" ]]; then
    echo "文件不存在: $in_file"
    return 1
  fi
  docker load -i "$in_file"
}

backup_docker_data_dir() {
  local out_file ans tar_ok
  local -a backup_targets
  if ! docker_installed; then
    echo "Docker 未安装"
    return 1
  fi

  read -r -p "备份文件路径(如 /root/docker-backups/docker-data.tar.gz): " out_file
  read -r -p "将临时停止Docker进行打包，确认继续？(y/N): " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "已取消"
    return 0
  fi

  mkdir -p "$(dirname "$out_file")"
  service_action stop docker || true
  service_action stop containerd || true

  backup_targets=()
  [[ -d /var/lib/docker ]] && backup_targets+=("/var/lib/docker")
  [[ -d /var/lib/containerd ]] && backup_targets+=("/var/lib/containerd")
  [[ -d /etc/docker ]] && backup_targets+=("/etc/docker")

  if (( ${#backup_targets[@]} == 0 )); then
    service_action start containerd || true
    service_action start docker || true
    echo "未找到可备份的 Docker 目录"
    return 1
  fi

  if tar -czf "$out_file" "${backup_targets[@]}" 2>/dev/null; then
    tar_ok="1"
  else
    tar_ok="0"
  fi

  service_action start containerd || true
  service_action start docker || true

  if [[ "$tar_ok" == "1" ]]; then
    echo "数据目录备份完成: $out_file"
    return 0
  fi
  echo "数据目录备份失败，请检查磁盘空间与权限"
  return 1
}

restore_docker_data_dir() {
  local in_file confirm_text
  read -r -p "输入备份包路径: " in_file
  if [[ ! -f "$in_file" ]]; then
    echo "文件不存在: $in_file"
    return 1
  fi
  if ! tar -tzf "$in_file" >/dev/null 2>&1; then
    echo "备份包不可读取或已损坏: $in_file"
    return 1
  fi

  echo "高风险操作：将覆盖 /var/lib/docker /var/lib/containerd /etc/docker"
  read -r -p "输入 RESTORE 确认继续: " confirm_text
  if [[ "$confirm_text" != "RESTORE" ]]; then
    echo "已取消"
    return 0
  fi

  service_action stop docker || true
  service_action stop containerd || true
  rm -rf /var/lib/docker /var/lib/containerd /etc/docker
  tar -xzf "$in_file" -C /
  service_action start containerd || true
  service_action start docker || true
  echo "Docker 数据还原完成"
}

backup_migrate_restore_menu() {
  local choice
  while true; do
    clear
    echo "========================================"
    echo "备份/迁移/还原Docker环境"
    echo "========================================"
    menu_item "1" "备份Docker元数据(容器/镜像/网络/卷/配置)"
    menu_item "2" "导出全部镜像为tar"
    menu_item "3" "从tar导入镜像"
    menu_item "4" "备份Docker数据目录(/var/lib/docker)"
    menu_item "5" "还原Docker数据目录"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read -r -p "请输入选择: " choice

    case "$choice" in
      1)
        backup_docker_metadata
        ;;
      2)
        export_all_images
        ;;
      3)
        import_images_from_tar
        ;;
      4)
        backup_docker_data_dir
        ;;
      5)
        restore_docker_data_dir
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

uninstall_docker_env() {
  local ans
  if ! ensure_apt; then
    return 1
  fi

  read -r -p "将卸载 Docker 并删除全部数据，确认继续？(y/N): " ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "已取消"
    return 0
  fi

  service_action stop docker || true
  service_action stop containerd || true

  apt-get purge -y docker.io docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose || true
  apt-get autoremove -y

  rm -rf /var/lib/docker /var/lib/containerd /etc/docker
  rm -f /etc/apt/sources.list.d/docker.list
  rm -f /usr/share/keyrings/docker-archive-keyring.gpg

  echo "Docker 环境卸载完成"
}

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
        ;;
      4)
        image_manager_menu
        ;;
      5)
        network_manager_menu
        ;;
      6)
        volume_manager_menu
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
    read -r -p "按任意键继续..." _
  done
}
