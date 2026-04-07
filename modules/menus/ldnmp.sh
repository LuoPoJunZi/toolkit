#!/usr/bin/env bash
set -euo pipefail

ldnmp_php_fpm_socket() {
  local sock
  if [[ -S /run/php/php-fpm.sock ]]; then
    echo "/run/php/php-fpm.sock"
    return
  fi
  sock="$(find /run/php -maxdepth 1 -type s -name 'php*-fpm.sock' 2>/dev/null | head -n1 || true)"
  echo "${sock:-/run/php/php-fpm.sock}"
}

ldnmp_nginx_reload() {
  nginx -t && systemctl reload nginx
}

ldnmp_site_data_menu() {
  local choice domain conf_file
  while true; do
    clear
    echo "========================================"
    echo "站点数据管理"
    echo "========================================"
    menu_item "1" "查看站点配置列表"
    menu_item "2" "查看某站点配置"
    menu_item "3" "禁用某站点"
    menu_item "4" "启用某站点"
    menu_item "5" "删除某站点配置"
    menu_item "6" "重载 Nginx"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1) ls -l /etc/nginx/sites-available 2>/dev/null || say_warn "目录不存在"; menu_wait ;;
      2)
        read -r -p "输入站点配置文件名(如 example.com.conf): " conf_file
        cat "/etc/nginx/sites-available/${conf_file}" 2>/dev/null || say_warn "配置不存在"
        menu_wait
        ;;
      3)
        read -r -p "输入站点配置文件名(如 example.com.conf): " conf_file
        rm -f "/etc/nginx/sites-enabled/${conf_file}"
        if ldnmp_nginx_reload; then
          say_ok "已禁用站点: ${conf_file}"
        else
          say_action_failed "站点禁用" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      4)
        read -r -p "输入站点配置文件名(如 example.com.conf): " conf_file
        if [[ -f "/etc/nginx/sites-available/${conf_file}" ]]; then
          ln -sf "/etc/nginx/sites-available/${conf_file}" "/etc/nginx/sites-enabled/${conf_file}"
          if ldnmp_nginx_reload; then
            say_ok "已启用站点: ${conf_file}"
          else
            say_action_failed "站点启用" "$(i18n_get msg_reason_exec_failed 'execution failed')"
          fi
        else
          say_warn "配置不存在"
        fi
        menu_wait
        ;;
      5)
        read -r -p "输入站点配置文件名(如 example.com.conf): " conf_file
        rm -f "/etc/nginx/sites-enabled/${conf_file}" "/etc/nginx/sites-available/${conf_file}"
        if ldnmp_nginx_reload; then
          say_ok "已删除站点配置: ${conf_file}"
        else
          say_action_failed "站点配置删除" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      6)
        if ldnmp_nginx_reload; then
          say_ok "Nginx 重载完成"
        else
          say_action_failed "Nginx 重载" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

ldnmp_menu() {
  local choice domain webroot conf_file php_sock
  local target_url upstream_ip upstream_port upstream_domain upstream_scheme upstream_url
  local upstream_list listen_port backup_root backup_path sql_file remote_target cron_expr
  while true; do
    clear
    echo "========================================"
    echo "LDNMP 建站"
    echo "========================================"
    menu_item "1" "安装LDNMP环境"
    menu_item "2" "安装WordPress"
    menu_item "3" "创建动态站点(PHP)"
    menu_item "4" "创建静态站点"
    echo "------------------------"
    menu_item "21" "仅安装nginx"
    menu_item "22" "站点重定向"
    menu_item "23" "站点反向代理-IP+端口"
    menu_item "24" "站点反向代理-域名"
    menu_item "25" "安装Bitwarden密码管理平台"
    menu_item "26" "安装Halo博客网站"
    menu_item "27" "安装AI绘画提示词生成器(静态页)"
    menu_item "28" "站点反向代理-负载均衡"
    menu_item "29" "Stream四层代理转发"
    menu_item "30" "自定义静态站点"
    echo "------------------------"
    menu_item "31" "站点数据管理"
    menu_item "32" "备份全站数据"
    menu_item "33" "定时远程备份"
    menu_item "34" "还原全站数据"
    echo "------------------------"
    menu_item "35" "防护LDNMP环境"
    menu_item "36" "优化LDNMP环境"
    menu_item "37" "更新LDNMP环境"
    menu_item "38" "卸载LDNMP环境"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1)
        if apt_install nginx mariadb-server php-fpm php-cli php-mysql php-xml php-curl php-gd php-zip unzip; then
          if systemctl enable --now nginx mariadb >/dev/null 2>&1; then
            say_ok "LDNMP 环境安装完成"
          else
            say_warn "组件安装完成，但服务启动失败，请手动检查 nginx/mariadb"
          fi
        else
          say_action_failed "LDNMP 环境安装" "$(i18n_get msg_reason_install_failed 'install failed')"
        fi
        menu_wait
        ;;
      2)
        if ! apt_install nginx mariadb-server php-fpm php-cli php-mysql php-xml php-curl php-gd php-zip unzip wget; then
          say_action_failed "基础环境安装" "$(i18n_get msg_reason_install_failed 'install failed')"
          menu_wait
          continue
        fi
        systemctl enable --now nginx mariadb >/dev/null 2>&1 || say_warn "nginx/mariadb 启动失败，后续部署可能受影响"
        php_sock="$(ldnmp_php_fpm_socket)"
        read -r -p "输入 WordPress 域名: " domain
        read -r -p "输入数据库名(默认 wp_${domain//./_}): " wp_db
        wp_db="${wp_db:-wp_${domain//./_}}"
        read -r -p "输入数据库用户名(默认 ${wp_db}): " wp_user
        wp_user="${wp_user:-$wp_db}"
        read -r -p "输入数据库密码(默认随机): " wp_pass
        wp_pass="${wp_pass:-$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)}"
        webroot="/var/www/${domain}"
        conf_file="/etc/nginx/sites-available/${domain}.conf"
        rm -rf "$webroot"
        mkdir -p "$webroot"
        wget -qO /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
        tar -xzf /tmp/wordpress.tar.gz -C /tmp
        cp -a /tmp/wordpress/. "$webroot/"
        cp "$webroot/wp-config-sample.php" "$webroot/wp-config.php"
        sed -i "s/database_name_here/${wp_db}/;s/username_here/${wp_user}/;s/password_here/${wp_pass}/" "$webroot/wp-config.php"
        chown -R www-data:www-data "$webroot"
        mysql -e "CREATE DATABASE IF NOT EXISTS \`${wp_db}\`;" 2>/dev/null || true
        mysql -e "CREATE USER IF NOT EXISTS '${wp_user}'@'localhost' IDENTIFIED BY '${wp_pass}';" 2>/dev/null || true
        mysql -e "GRANT ALL PRIVILEGES ON \`${wp_db}\`.* TO '${wp_user}'@'localhost'; FLUSH PRIVILEGES;" 2>/dev/null || true
        cat >"$conf_file" <<EOF
server {
    listen 80;
    server_name ${domain};
    root ${webroot};
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_sock};
    }
}
EOF
        ln -sf "$conf_file" "/etc/nginx/sites-enabled/${domain}.conf"
        if ldnmp_nginx_reload; then
          say_ok "WordPress 已部署: http://${domain}"
          echo "数据库: ${wp_db} 用户: ${wp_user} 密码: ${wp_pass}"
        else
          say_action_failed "WordPress 站点发布" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      3)
        php_sock="$(ldnmp_php_fpm_socket)"
        read -r -p "输入域名: " domain
        webroot="/var/www/${domain}"
        conf_file="/etc/nginx/sites-available/${domain}.conf"
        mkdir -p "$webroot"
        cat >"${webroot}/index.php" <<'EOF'
<?php echo "Hello from LuoPo dynamic site."; ?>
EOF
        chown -R www-data:www-data "$webroot"
        cat >"$conf_file" <<EOF
server {
    listen 80;
    server_name ${domain};
    root ${webroot};
    index index.php index.html;

    location / { try_files \$uri \$uri/ /index.php?\$args; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_sock};
    }
}
EOF
        ln -sf "$conf_file" "/etc/nginx/sites-enabled/${domain}.conf"
        if ldnmp_nginx_reload; then
          say_ok "动态站点已创建: ${domain}"
        else
          say_action_failed "动态站点创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      4|30)
        read -r -p "输入域名: " domain
        webroot="/var/www/${domain}"
        conf_file="/etc/nginx/sites-available/${domain}.static.conf"
        mkdir -p "$webroot"
        cat >"${webroot}/index.html" <<EOF
<html><head><meta charset="utf-8"><title>${domain}</title></head><body><h1>${domain}</h1><p>Static site by LuoPo Toolkit</p></body></html>
EOF
        cat >"$conf_file" <<EOF
server {
    listen 80;
    server_name ${domain};
    root ${webroot};
    index index.html;
    location / { try_files \$uri \$uri/ =404; }
}
EOF
        ln -sf "$conf_file" "/etc/nginx/sites-enabled/${domain}.static.conf"
        if ldnmp_nginx_reload; then
          say_ok "静态站点已创建: ${domain}"
        else
          say_action_failed "静态站点创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      21)
        if apt_install nginx; then
          if systemctl enable --now nginx >/dev/null 2>&1; then
            say_ok "nginx 已安装并启动"
          else
            say_warn "nginx 已安装，但启动失败"
          fi
        else
          say_action_failed "nginx 安装" "$(i18n_get msg_reason_install_failed 'install failed')"
        fi
        menu_wait
        ;;
      22)
        read -r -p "输入要重定向的域名: " domain
        read -r -p "输入目标URL/域名: " target_url
        [[ ! "$target_url" =~ ^https?:// ]] && target_url="https://${target_url}"
        conf_file="/etc/nginx/sites-available/${domain}.redirect.conf"
        cat >"$conf_file" <<EOF
server {
    listen 80;
    server_name ${domain} www.${domain};
    return 301 ${target_url}\$request_uri;
}
EOF
        ln -sf "$conf_file" "/etc/nginx/sites-enabled/${domain}.redirect.conf"
        if ldnmp_nginx_reload; then
          say_ok "重定向已创建: ${domain} -> ${target_url}"
        else
          say_action_failed "站点重定向创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      23)
        read -r -p "输入对外访问域名: " domain
        read -r -p "输入后端IP: " upstream_ip
        read -r -p "输入后端端口: " upstream_port
        conf_file="/etc/nginx/sites-available/${domain}.proxy-ip-port.conf"
        cat >"$conf_file" <<EOF
server {
    listen 80;
    server_name ${domain};
    location / {
        proxy_pass http://${upstream_ip}:${upstream_port};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        ln -sf "$conf_file" "/etc/nginx/sites-enabled/${domain}.proxy-ip-port.conf"
        if ldnmp_nginx_reload; then
          say_ok "反向代理已创建: ${domain} -> ${upstream_ip}:${upstream_port}"
        else
          say_action_failed "反向代理(IP+端口)创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      24)
        read -r -p "输入对外访问域名: " domain
        read -r -p "输入后端域名: " upstream_domain
        read -r -p "输入后端协议(http/https，默认 http): " upstream_scheme
        read -r -p "输入后端端口(可空): " upstream_port
        upstream_scheme="${upstream_scheme:-http}"
        upstream_url="${upstream_scheme}://${upstream_domain}"
        [[ -n "$upstream_port" ]] && upstream_url="${upstream_url}:${upstream_port}"
        conf_file="/etc/nginx/sites-available/${domain}.proxy-domain.conf"
        cat >"$conf_file" <<EOF
server {
    listen 80;
    server_name ${domain};
    location / {
        proxy_pass ${upstream_url};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        ln -sf "$conf_file" "/etc/nginx/sites-enabled/${domain}.proxy-domain.conf"
        if ldnmp_nginx_reload; then
          say_ok "反向代理已创建: ${domain} -> ${upstream_url}"
        else
          say_action_failed "反向代理(域名)创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      25)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "bitwarden" "Bitwarden(Vaultwarden): http://你的IP:8086" "Bitwarden 部署" -d --name bitwarden --restart unless-stopped -p 8086:80 -v /opt/bitwarden:/data vaultwarden/server:latest
        menu_wait
        ;;
      26)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "halo" "Halo: http://你的IP:8090" "Halo 部署" -d --name halo --restart unless-stopped -p 8090:8090 -v /opt/halo2:/root/.halo halohub/halo:2
        menu_wait
        ;;
      27)
        read -r -p "输入提示词工具域名: " domain
        webroot="/var/www/${domain}"
        conf_file="/etc/nginx/sites-available/${domain}.prompt.conf"
        mkdir -p "$webroot"
        cat >"${webroot}/index.html" <<'EOF'
<!doctype html><html><head><meta charset="utf-8"><title>Prompt Generator</title></head>
<body><h2>AI绘画提示词生成器</h2><p>风格: cinematic, anime, realistic</p><p>质量: masterpiece, ultra detailed, 8k</p></body></html>
EOF
        cat >"$conf_file" <<EOF
server {
    listen 80;
    server_name ${domain};
    root ${webroot};
    index index.html;
}
EOF
        ln -sf "$conf_file" "/etc/nginx/sites-enabled/${domain}.prompt.conf"
        if ldnmp_nginx_reload; then
          say_ok "提示词工具站点已创建: http://${domain}"
        else
          say_action_failed "提示词站点创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      28)
        read -r -p "输入对外访问域名: " domain
        read -r -p "输入后端列表(逗号分隔，如 127.0.0.1:8080,127.0.0.1:8081): " upstream_list
        conf_file="/etc/nginx/sites-available/${domain}.lb.conf"
        {
          echo "upstream ${domain//./_}_pool {"
          IFS=',' read -r -a arr <<<"$upstream_list"
          for u in "${arr[@]}"; do
            echo "    server ${u};"
          done
          cat <<EOF
}
server {
    listen 80;
    server_name ${domain};
    location / {
        proxy_pass http://${domain//./_}_pool;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
        } >"$conf_file"
        ln -sf "$conf_file" "/etc/nginx/sites-enabled/${domain}.lb.conf"
        if ldnmp_nginx_reload; then
          say_ok "负载均衡反代已创建: ${domain}"
        else
          say_action_failed "负载均衡反代创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      29)
        read -r -p "输入监听端口(本机): " listen_port
        read -r -p "输入上游IP: " upstream_ip
        read -r -p "输入上游端口: " upstream_port
        mkdir -p /etc/nginx/streams-enabled
        if ! grep -q 'include /etc/nginx/streams-enabled/\*.conf;' /etc/nginx/nginx.conf 2>/dev/null; then
          cat >>/etc/nginx/nginx.conf <<'EOF'

stream {
    include /etc/nginx/streams-enabled/*.conf;
}
EOF
        fi
        cat >"/etc/nginx/streams-enabled/stream-${listen_port}.conf" <<EOF
server {
    listen ${listen_port};
    proxy_pass ${upstream_ip}:${upstream_port};
}
EOF
        if ldnmp_nginx_reload; then
          say_ok "四层转发已创建: ${listen_port} -> ${upstream_ip}:${upstream_port}"
        else
          say_action_failed "四层转发创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      31)
        ldnmp_site_data_menu
        ;;
      32)
        backup_root="/root/ldnmp-full-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_root"
        local backup_ok
        backup_ok=1
        tar -czf "${backup_root}/www.tar.gz" /var/www 2>/dev/null || backup_ok=0
        tar -czf "${backup_root}/nginx-sites.tar.gz" /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null || backup_ok=0
        if command -v mysqldump >/dev/null 2>&1; then
          mysqldump --all-databases >"${backup_root}/all-databases.sql" 2>/dev/null || backup_ok=0
        fi
        if (( backup_ok == 1 )); then
          say_ok "全站数据备份完成: ${backup_root}"
        else
          say_warn "备份已执行，但有部分项目失败，请检查目录: ${backup_root}"
        fi
        menu_wait
        ;;
      33)
        read -r -p "输入本地备份目录(默认 /root/ldnmp-backups): " backup_path
        backup_path="${backup_path:-/root/ldnmp-backups}"
        mkdir -p "$backup_path"
        read -r -p "输入远程目标(user@host:/path): " remote_target
        read -r -p "输入cron表达式(默认 0 3 * * *): " cron_expr
        cron_expr="${cron_expr:-0 3 * * *}"
        if (crontab -l 2>/dev/null; echo "${cron_expr} rsync -az --delete ${backup_path}/ ${remote_target} >> /var/log/ldnmp-remote-backup.log 2>&1") | crontab -; then
          say_ok "定时远程备份任务已添加"
        else
          say_action_failed "定时远程备份任务添加" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      34)
        read -r -p "输入备份目录(如 /root/ldnmp-full-20260101-000000): " backup_path
        if [[ -f "${backup_path}/www.tar.gz" ]]; then tar -xzf "${backup_path}/www.tar.gz" -C /; fi
        if [[ -f "${backup_path}/nginx-sites.tar.gz" ]]; then tar -xzf "${backup_path}/nginx-sites.tar.gz" -C /; fi
        sql_file="${backup_path}/all-databases.sql"
        if [[ -f "$sql_file" ]]; then mysql <"$sql_file" 2>/dev/null || true; fi
        if ldnmp_nginx_reload; then
          say_ok "全站数据还原完成"
        else
          say_action_failed "全站数据还原" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      35)
        if ! apt_install ufw fail2ban; then
          say_action_failed "LDNMP 防护依赖安装" "$(i18n_get msg_reason_install_failed 'install failed')"
          menu_wait
          continue
        fi
        if ufw allow 22/tcp >/dev/null 2>&1 && ufw allow 80/tcp >/dev/null 2>&1 && ufw allow 443/tcp >/dev/null 2>&1; then
          yes | ufw enable >/dev/null 2>&1 || true
        else
          say_warn "UFW 规则应用失败，请手动检查"
        fi
        if ! grep -q "server_tokens off;" /etc/nginx/nginx.conf 2>/dev/null; then
          sed -i '/http {/a\    server_tokens off;' /etc/nginx/nginx.conf || true
        fi
        mkdir -p /etc/fail2ban/jail.d
        cat >/etc/fail2ban/jail.d/nginx-local.conf <<'EOF'
[nginx-http-auth]
enabled = true
[nginx-botsearch]
enabled = true
EOF
        systemctl restart fail2ban >/dev/null 2>&1 || say_warn "Fail2ban 重启失败"
        if ldnmp_nginx_reload; then
          say_ok "LDNMP 防护策略已应用"
        else
          say_action_failed "LDNMP 防护策略应用" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      36)
        cat >/etc/nginx/conf.d/99-luopo-ldnmp-opt.conf <<'EOF'
client_max_body_size 64m;
keepalive_timeout 65;
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml+rss text/javascript;
EOF
        if ldnmp_nginx_reload; then
          say_ok "LDNMP 优化配置已应用"
        else
          say_action_failed "LDNMP 优化配置应用" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      37)
        if apt_upgrade_only nginx mariadb-server php-fpm php-cli php-mysql; then
          systemctl restart nginx mariadb >/dev/null 2>&1 || true
          say_ok "LDNMP 环境更新完成"
        else
          say_action_failed "LDNMP 环境更新" "$(i18n_get msg_reason_install_failed 'install failed')"
        fi
        menu_wait
        ;;
      38)
        if confirm_or_cancel "确认卸载 LDNMP 环境？(y/N): "; then
          log_action "ldnmp:uninstall:start"
          systemctl stop nginx mariadb php-fpm 2>/dev/null || true
          apt-get purge -y nginx nginx-common mariadb-server mariadb-client php-fpm php-cli php-mysql php-xml php-curl php-gd php-zip || true
          apt-get autoremove -y || true
          log_action "ldnmp:uninstall:ok"
          say_ok "LDNMP 核心组件已卸载（站点数据请手动确认保留情况）"
        fi
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

