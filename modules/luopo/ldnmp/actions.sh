#!/usr/bin/env bash
set -euo pipefail

luopo_ldnmp_launch_compat() {
  run_luopo_compat_menu linux_ldnmp
}

luopo_ldnmp_install_all() {
  ldnmp_install_status_one
  ldnmp_install_all
}

luopo_ldnmp_install_wordpress() {
  ldnmp_wp
}

luopo_ldnmp_install_nginx_only() {
  ldnmp_install_status_one
  nginx_install_all
}

luopo_ldnmp_reverse_proxy_ip_port() {
  ldnmp_Proxy
  find_container_by_host_port "$port"
  if [[ -z "${docker_name:-}" ]]; then
    close_port "$port"
    echo "已阻止 IP+端口访问该服务"
  else
    ip_address
    close_port "$port"
    block_container_port "$docker_name" "$ipv4_address"
  fi
}

luopo_ldnmp_redirect_site() {
  clear
  local webname="站点重定向"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  add_yuming
  read -r -p "请输入跳转域名: " reverseproxy
  nginx_install_status
  install_ssltls
  certs_status

  wget -O "/home/web/conf.d/$yuming.conf" "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf"
  sed -i "s/yuming.com/$yuming/g" "/home/web/conf.d/$yuming.conf"
  sed -i "s/baidu.com/$reverseproxy/g" "/home/web/conf.d/$yuming.conf"
  nginx_http_on
  docker exec nginx nginx -s reload
  nginx_web_on
}

luopo_ldnmp_reverse_proxy_domain() {
  clear
  local webname="反向代理-域名"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  add_yuming
  echo -e "域名格式: ${gl_huang}google.com${gl_bai}"
  read -r -p "请输入你的反代域名: " fandai_yuming
  nginx_install_status
  install_ssltls
  certs_status

  wget -O "/home/web/conf.d/$yuming.conf" "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-domain.conf"
  sed -i "s/yuming.com/$yuming/g" "/home/web/conf.d/$yuming.conf"
  sed -i "s|fandaicom|$fandai_yuming|g" "/home/web/conf.d/$yuming.conf"
  nginx_http_on
  docker exec nginx nginx -s reload
  nginx_web_on
}

luopo_ldnmp_reverse_proxy_load_balance() {
  ldnmp_Proxy_backend
}

luopo_ldnmp_stream_proxy() {
  stream_panel
}

luopo_ldnmp_site_status() {
  ldnmp_web_status
}

luopo_ldnmp_security() {
  web_security
}

luopo_ldnmp_optimization() {
  web_optimization
}

luopo_ldnmp_backup_all() {
  clear
  send_stats "LDNMP环境备份"
  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
  echo -e "${gl_kjlan}正在备份 $backup_filename ...${gl_bai}"
  cd /home/ && tar czvf "$backup_filename" web

  while true; do
    clear
    echo "备份文件已创建: /home/$backup_filename"
    read -r -p "要传送备份数据到远程服务器吗？(Y/N): " choice
    case "$choice" in
      [Yy])
        kj_ssh_read_host_port "请输入远端服务器IP:  " "目标服务器SSH端口 [默认22]: " "22"
        local remote_ip="$KJ_SSH_HOST"
        local target_port="$KJ_SSH_PORT"
        local latest_tar
        latest_tar="$(ls -t /home/*.tar.gz 2>/dev/null | head -1)"
        if [[ -n "$latest_tar" ]]; then
          ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
          sleep 2
          scp -P "$target_port" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
          echo "文件已传送至远程服务器 home 目录。"
        else
          echo "未找到要传送的文件。"
        fi
        break
        ;;
      [Nn])
        break
        ;;
      *)
        echo "无效的选择，请输入 Y 或 N。"
        ;;
    esac
  done
}

luopo_ldnmp_scheduled_remote_backup() {
  clear
  send_stats "定时远程备份"
  read -r -p "输入远程服务器IP: " useip
  read -r -p "输入远程服务器密码: " usepasswd
  cd ~
  wget -O "${useip}_beifen.sh" "${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh" >/dev/null 2>&1
  chmod +x "${useip}_beifen.sh"
  sed -i "s/0.0.0.0/$useip/g" "${useip}_beifen.sh"
  sed -i "s/123456/$usepasswd/g" "${useip}_beifen.sh"

  echo "------------------------"
  echo "1. 每周备份                 2. 每天备份"
  read -r -p "请输入你的选择: " dingshi
  case "$dingshi" in
    1)
      check_crontab_installed
      read -r -p "选择每周备份的星期几 (0-6，0代表星期日): " weekday
      (crontab -l 2>/dev/null; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab -
      ;;
    2)
      check_crontab_installed
      read -r -p "选择每天备份的时间（小时，0-23）: " hour
      (crontab -l 2>/dev/null; echo "0 $hour * * * ./${useip}_beifen.sh") | crontab -
      ;;
    *)
      echo "已取消"
      ;;
  esac
  install sshpass
}

luopo_ldnmp_restore_all() {
  root_use
  send_stats "LDNMP环境还原"
  echo "可用的站点备份"
  echo "-------------------------"
  ls -lt /home/*.gz 2>/dev/null | awk '{print $NF}' || true
  echo
  read -r -p "回车键还原最新的备份，输入备份文件名还原指定的备份，输入0退出: " filename
  [[ "$filename" == "0" ]] && return 0

  if [[ -z "$filename" ]]; then
    filename="$(ls -t /home/*.tar.gz 2>/dev/null | head -1)"
  fi

  if [[ -n "$filename" && "$filename" != /* ]]; then
    filename="/home/$filename"
  fi

  if [[ -n "$filename" && -f "$filename" ]]; then
    cd /home/web/ >/dev/null 2>&1 && docker compose down >/dev/null 2>&1 || true
    rm -rf /home/web >/dev/null 2>&1
    echo -e "${gl_kjlan}正在解压 $filename ...${gl_bai}"
    cd /home/ && tar -xzf "$filename"
    install_dependency
    install_docker
    install_certbot
    install_ldnmp
  else
    echo "没有找到压缩包。"
  fi
}

luopo_ldnmp_update_menu() {
  root_use
  while true; do
    clear
    send_stats "更新LDNMP环境"
    echo "更新LDNMP环境"
    echo "------------------------"
    ldnmp_v
    echo "发现新版本的组件"
    echo "------------------------"
    check_docker_image_update nginx
    [[ -n "${update_status:-}" ]] && echo -e "${gl_huang}nginx $update_status${gl_bai}"
    check_docker_image_update php
    [[ -n "${update_status:-}" ]] && echo -e "${gl_huang}php $update_status${gl_bai}"
    check_docker_image_update mysql
    [[ -n "${update_status:-}" ]] && echo -e "${gl_huang}mysql $update_status${gl_bai}"
    check_docker_image_update redis
    [[ -n "${update_status:-}" ]] && echo -e "${gl_huang}redis $update_status${gl_bai}"
    echo "------------------------"
    echo "1. 更新nginx       2. 更新mysql       3. 更新php       4. 更新redis"
    echo "------------------------"
    echo "5. 更新完整环境"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        nginx_upgrade
        ;;
      2)
        local ldnmp_pods="mysql"
        read -r -p "请输入${ldnmp_pods}版本号（如: 8.0 8.3 8.4 9.0，回车最新版）: " version
        version="${version:-latest}"
        cd /home/web/
        cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
        sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
        docker rm -f "$ldnmp_pods"
        docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1 || true
        docker compose up -d --force-recreate "$ldnmp_pods"
        docker restart "$ldnmp_pods"
        cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
        echo "更新${ldnmp_pods}完成"
        ;;
      3)
        local ldnmp_pods="php"
        read -r -p "请输入${ldnmp_pods}版本号（如: 7.4 8.0 8.1 8.2 8.3，回车8.3）: " version
        version="${version:-8.3}"
        cd /home/web/
        cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
        sed -i "s/kjlion\///g" /home/web/docker-compose.yml >/dev/null 2>&1
        sed -i "s/image: php:fpm-alpine/image: php:${version}-fpm-alpine/" /home/web/docker-compose.yml
        docker rm -f "$ldnmp_pods"
        docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1 || true
        docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi >/dev/null 2>&1 || true
        docker compose up -d --force-recreate "$ldnmp_pods"
        docker exec php chown -R www-data:www-data /var/www/html
        docker restart "$ldnmp_pods" >/dev/null 2>&1
        cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
        echo "更新${ldnmp_pods}完成"
        ;;
      4)
        local ldnmp_pods="redis"
        cd /home/web/
        docker rm -f "$ldnmp_pods"
        docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1 || true
        docker compose up -d --force-recreate "$ldnmp_pods"
        docker restart "$ldnmp_pods" >/dev/null 2>&1
        echo "更新${ldnmp_pods}完成"
        ;;
      5)
        read -r -p "长时间不更新环境的用户请谨慎。确定完整更新LDNMP环境吗？(Y/N): " choice
        case "$choice" in
          [Yy])
            cd /home/web/
            docker compose down --rmi all
            install_dependency
            install_docker
            install_certbot
            install_ldnmp
            ;;
        esac
        ;;
      0)
        return 0
        ;;
      *)
        luopo_ldnmp_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_ldnmp_uninstall() {
  root_use
  send_stats "卸载LDNMP环境"
  read -r -p "强烈建议先备份全部网站数据。确定删除所有网站数据吗？(Y/N): " choice
  case "$choice" in
    [Yy])
      if [[ -d /home/web ]]; then
        cd /home/web/
        docker compose down --rmi all
        docker compose -f docker-compose.phpmyadmin.yml down >/dev/null 2>&1 || true
        docker compose -f docker-compose.phpmyadmin.yml down --rmi all >/dev/null 2>&1 || true
        rm -rf /home/web
        echo "LDNMP 环境已卸载"
      else
        echo "未检测到 /home/web，LDNMP 环境可能未安装。"
      fi
      ;;
    [Nn])
      echo "已取消"
      ;;
    *)
      echo "无效的选择，请输入 Y 或 N。"
      ;;
  esac
}

luopo_ldnmp_dispatch_choice() {
  local choice="$1"
  case "$choice" in
    0) return 1 ;;
    1) luopo_ldnmp_install_all ;;
    2) luopo_ldnmp_install_wordpress ;;
    21) luopo_ldnmp_install_nginx_only ;;
    22) luopo_ldnmp_redirect_site ;;
    23) luopo_ldnmp_reverse_proxy_ip_port ;;
    24) luopo_ldnmp_reverse_proxy_domain ;;
    28) luopo_ldnmp_reverse_proxy_load_balance ;;
    29) luopo_ldnmp_stream_proxy ;;
    31) luopo_ldnmp_site_status ;;
    32) luopo_ldnmp_backup_all ;;
    33) luopo_ldnmp_scheduled_remote_backup ;;
    34) luopo_ldnmp_restore_all ;;
    35) luopo_ldnmp_security ;;
    36) luopo_ldnmp_optimization ;;
    37) luopo_ldnmp_update_menu ;;
    38) luopo_ldnmp_uninstall ;;
    *)
      echo "该功能当前仍使用兼容实现，正在切换..."
      press_enter
      luopo_ldnmp_launch_compat
      ;;
  esac
  return 0
}

