#!/usr/bin/env bash
set -euo pipefail

# Docker daemon configuration, IPv6, backup, migration, and restore menus.

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
