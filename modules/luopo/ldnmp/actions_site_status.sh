#!/usr/bin/env bash
set -euo pipefail

luopo_ldnmp_site_status() {
  root_use || return 1
  while true; do
    clear
    local cert_count db_count dbrootpasswd
    cert_count="$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l | tr -d '[:space:]')"
    db_count="0"
    dbrootpasswd="$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')"
    if [[ -n "$dbrootpasswd" ]] && docker inspect mysql >/dev/null 2>&1; then
      db_count="$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e 'SHOW DATABASES;' 2>/dev/null | grep -Ev 'Database|information_schema|mysql|performance_schema|sys' | wc -l | tr -d '[:space:]')"
    fi

    echo "LDNMP站点数据管理"
    echo "------------------------"
    ldnmp_v
    echo "站点: $cert_count    数据库: $db_count"
    echo "------------------------"
    echo "站点与证书到期时间"
    for cert_file in /home/web/certs/*_cert.pem; do
      [[ -f "$cert_file" ]] || continue
      local domain expire_date formatted_date
      domain="$(basename "$cert_file" | sed 's/_cert.pem//')"
      expire_date="$(openssl x509 -noout -enddate -in "$cert_file" 2>/dev/null | awk -F= '{print $2}')"
      formatted_date="$(date -d "$expire_date" '+%Y-%m-%d' 2>/dev/null || echo N/A)"
      printf "%-32s %s\n" "$domain" "$formatted_date"
    done
    echo "------------------------"
    echo "站点目录: /home/web/html"
    echo "证书目录: /home/web/certs"
    echo "配置目录: /home/web/conf.d"
    echo "------------------------"
    echo "1. 申请/更新域名证书"
    echo "2. 清理站点缓存"
    echo "3. 查看访问日志"
    echo "4. 查看错误日志"
    echo "5. 编辑全局配置"
    echo "6. 编辑站点配置"
    echo "7. 查看数据库列表"
    echo "20. 删除指定站点数据"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1) add_yuming; install_ssltls; certs_status ;;
      2) docker exec nginx sh -c 'rm -rf /var/cache/nginx/*' >/dev/null 2>&1 || true; echo "站点缓存已清理" ;;
      3) docker logs --tail=200 nginx 2>/dev/null || tail -n 200 /home/web/log/nginx/access.log 2>/dev/null || true ;;
      4) docker logs --tail=200 nginx 2>/dev/null || tail -n 200 /home/web/log/nginx/error.log 2>/dev/null || true ;;
      5) install nano; nano /home/web/nginx.conf; docker exec nginx nginx -s reload >/dev/null 2>&1 || true ;;
      6) luopo_ldnmp_edit_site_conf ;;
      7) [[ -n "$dbrootpasswd" ]] && docker exec mysql mysql -u root -p"$dbrootpasswd" -e 'SHOW DATABASES;' 2>/dev/null || echo "未检测到数据库容器" ;;
      20) luopo_ldnmp_delete_site_prompt ;;
      0) return 0 ;;
      *) luopo_ldnmp_invalid_choice; continue ;;
    esac
    break_end
  done
}

luopo_ldnmp_edit_site_conf() {
  local domain conf
  ls /home/web/conf.d/*.conf 2>/dev/null | xargs -r -n1 basename
  read -r -p "请输入配置文件名或域名: " domain
  [[ -n "$domain" ]] || return 0
  conf="$domain"
  [[ "$conf" == *.conf ]] || conf="${domain}.conf"
  conf="/home/web/conf.d/$conf"
  [[ -f "$conf" ]] || { echo "配置不存在: $conf"; return 1; }
  install nano
  nano "$conf"
  docker exec nginx nginx -s reload >/dev/null 2>&1 || true
}

luopo_ldnmp_delete_site_prompt() {
  local domain confirm
  read -r -p "请输入要删除的站点域名: " domain
  [[ -n "$domain" ]] || return 0
  read -r -p "确认删除 $domain 的站点/证书/配置/数据库？输入 DELETE 确认: " confirm
  [[ "$confirm" == "DELETE" ]] || { echo "已取消"; return 0; }
  luopo_ldnmp_delete_site "$domain"
  echo "站点已删除: $domain"
}
