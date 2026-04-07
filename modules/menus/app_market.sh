#!/usr/bin/env bash
set -euo pipefail

app_market_menu() {
  local choice
  while true; do
    clear
    echo "========================================"
    echo "应用市场"
    echo "========================================"
    menu_item "1" "安装 Portainer"
    menu_item "2" "安装 Watchtower"
    menu_item "3" "安装 Nginx Proxy Manager"
    menu_item "4" "安装 Uptime Kuma"
    echo "------------------------"
    menu_item "21" "安装 AList"
    menu_item "22" "安装 FileBrowser"
    menu_item "23" "安装 Vaultwarden"
    menu_item "24" "安装 Gitea"
    echo "------------------------"
    menu_item "31" "安装 n8n"
    menu_item "32" "安装 Minio"
    menu_item "33" "安装 Redis"
    menu_item "34" "安装 RabbitMQ"
    menu_item "35" "查看容器化应用状态"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "portainer" "Portainer: http://你的IP:9000" "Portainer 部署" -d --name portainer --restart always -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
        menu_wait
        ;;
      2)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "watchtower" "Watchtower 已部署" "Watchtower 部署" -d --name watchtower --restart always -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup --interval 43200
        menu_wait
        ;;
      3)
        ensure_docker_compose || { menu_wait; continue; }
        mkdir -p /opt/npm && cat >/opt/npm/docker-compose.yml <<'EOF'
services:
  app:
    image: jc21/nginx-proxy-manager:latest
    restart: unless-stopped
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF
        if (cd /opt/npm && docker compose up -d); then
          say_ok "NPM: http://你的IP:81"
        else
          say_action_failed "NPM 部署" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      4)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "uptime-kuma" "Uptime Kuma: http://你的IP:3001" "Uptime Kuma 部署" -d --name uptime-kuma --restart unless-stopped -p 3001:3001 -v uptime-kuma:/app/data louislam/uptime-kuma:latest
        menu_wait
        ;;
      21)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "alist" "AList: http://你的IP:5244" "AList 部署" -d --name alist --restart unless-stopped -p 5244:5244 -v /opt/alist:/opt/alist/data xhofe/alist:latest
        menu_wait
        ;;
      22)
        ensure_docker_ready || { menu_wait; continue; }
        mkdir -p /opt/filebrowser
        docker_ensure_container "filebrowser" "FileBrowser: http://你的IP:8088" "FileBrowser 部署" -d --name filebrowser --restart unless-stopped -p 8088:80 -v /:/srv -v /opt/filebrowser/database.db:/database.db -v /opt/filebrowser/.filebrowser.json:/.filebrowser.json filebrowser/filebrowser:latest
        menu_wait
        ;;
      23)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "vaultwarden" "Vaultwarden: http://你的IP:8087" "Vaultwarden 部署" -d --name vaultwarden --restart unless-stopped -p 8087:80 -v /opt/vaultwarden:/data vaultwarden/server:latest
        menu_wait
        ;;
      24)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "gitea" "Gitea: http://你的IP:3002" "Gitea 部署" -d --name gitea --restart unless-stopped -p 3002:3000 -p 2222:22 -v /opt/gitea:/data gitea/gitea:latest
        menu_wait
        ;;
      31)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "n8n" "n8n: http://你的IP:5678" "n8n 部署" -d --name n8n --restart unless-stopped -p 5678:5678 -v /opt/n8n:/home/node/.n8n docker.n8n.io/n8nio/n8n
        menu_wait
        ;;
      32)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "minio" "Minio Console: http://你的IP:9001" "Minio 部署" -d --name minio --restart unless-stopped -p 9001:9001 -p 9002:9000 -e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=minioadmin -v /opt/minio:/data minio/minio server /data --console-address ':9001'
        menu_wait
        ;;
      33)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "redis" "Redis 已部署" "Redis 部署" -d --name redis --restart unless-stopped -p 6379:6379 redis:latest
        menu_wait
        ;;
      34)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "rabbitmq" "RabbitMQ: http://你的IP:15672" "RabbitMQ 部署" -d --name rabbitmq --restart unless-stopped -p 5672:5672 -p 15672:15672 rabbitmq:management
        menu_wait
        ;;
      35) ensure_docker_ready || { menu_wait; continue; }; docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'; menu_wait ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

