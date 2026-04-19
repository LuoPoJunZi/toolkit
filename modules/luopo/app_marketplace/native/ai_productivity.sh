#!/usr/bin/env bash
set -euo pipefail

# Monitoring, AI, automation, and productivity applications.

luopo_app_marketplace_uptime_kuma_install() {
  local app_port="$1"
  docker rm -f uptime-kuma >/dev/null 2>&1 || true
  docker run -d \
    --name uptime-kuma \
    -p "${app_port}:3001" \
    -v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
    --restart=always \
    louislam/uptime-kuma:latest
}

luopo_app_marketplace_uptime_kuma_update() {
  local app_port="$1"
  docker rm -f uptime-kuma >/dev/null 2>&1 || true
  docker rmi -f louislam/uptime-kuma:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_uptime_kuma_install "$app_port"
}

luopo_app_marketplace_uptime_kuma_uninstall() {
  docker rm -f uptime-kuma >/dev/null 2>&1 || true
  docker rmi -f louislam/uptime-kuma:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/uptime-kuma
  echo "应用已卸载"
}

luopo_app_marketplace_uptime_kuma_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "9" \
    "UptimeKuma监控工具" \
    "uptime-kuma" \
    "louislam/uptime-kuma:latest" \
    "8022" \
    "Uptime Kuma 易于使用的自托管监控工具" \
    "官网介绍: https://github.com/louislam/uptime-kuma" \
    "luopo_app_marketplace_uptime_kuma_install" \
    "luopo_app_marketplace_uptime_kuma_update" \
    "luopo_app_marketplace_uptime_kuma_uninstall"
}

luopo_app_marketplace_beszel_install() {
  local app_port="$1"
  mkdir -p /home/docker/beszel
  docker rm -f beszel >/dev/null 2>&1 || true
  docker run -d \
    --name beszel \
    --restart=always \
    -v /home/docker/beszel:/beszel_data \
    -p "${app_port}:8090" \
    henrygd/beszel
}

luopo_app_marketplace_beszel_update() {
  local app_port="$1"
  docker rm -f beszel >/dev/null 2>&1 || true
  docker rmi -f henrygd/beszel >/dev/null 2>&1 || true
  luopo_app_marketplace_beszel_install "$app_port"
}

luopo_app_marketplace_beszel_uninstall() {
  docker rm -f beszel >/dev/null 2>&1 || true
  docker rmi -f henrygd/beszel >/dev/null 2>&1 || true
  rm -rf /home/docker/beszel
  echo "应用已卸载"
}

luopo_app_marketplace_beszel_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "10" \
    "Beszel服务器监控" \
    "beszel" \
    "henrygd/beszel" \
    "8079" \
    "Beszel 轻量易用的服务器监控工具。" \
    "官网介绍: https://beszel.dev/zh/" \
    "luopo_app_marketplace_beszel_install" \
    "luopo_app_marketplace_beszel_update" \
    "luopo_app_marketplace_beszel_uninstall"
}

luopo_app_marketplace_komari_install() {
  local app_port="$1"
  mkdir -p /home/docker/komari
  docker rm -f komari >/dev/null 2>&1 || true
  docker run -d \
    --name komari \
    -p "${app_port}:25774" \
    -v /home/docker/komari:/app/data \
    -e ADMIN_USERNAME=admin \
    -e ADMIN_PASSWORD=1212156 \
    -e TZ=Asia/Shanghai \
    --restart=always \
    ghcr.io/komari-monitor/komari:latest
}

luopo_app_marketplace_komari_update() {
  local app_port="$1"
  docker rm -f komari >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/komari-monitor/komari:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_komari_install "$app_port"
}

luopo_app_marketplace_komari_uninstall() {
  docker rm -f komari >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/komari-monitor/komari:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/komari
  echo "应用已卸载"
}

luopo_app_marketplace_komari_post_install() {
  echo "默认账号: admin"
  echo "默认密码: 1212156"
}

luopo_app_marketplace_komari_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "11" \
    "komari服务器监控工具" \
    "komari" \
    "ghcr.io/komari-monitor/komari:latest" \
    "8083" \
    "Komari 是轻量级的自托管服务器监控工具。" \
    "官网介绍: https://github.com/komari-monitor/komari" \
    "luopo_app_marketplace_komari_install" \
    "luopo_app_marketplace_komari_update" \
    "luopo_app_marketplace_komari_uninstall" \
    "luopo_app_marketplace_komari_post_install"
}

luopo_app_marketplace_stirling_pdf_install() {
  local app_port="$1"
  mkdir -p /home/docker/s-pdf/trainingData /home/docker/s-pdf/extraConfigs /home/docker/s-pdf/logs
  docker rm -f s-pdf >/dev/null 2>&1 || true
  docker run -d \
    --name s-pdf \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/s-pdf/trainingData:/usr/share/tesseract-ocr/5/tessdata \
    -v /home/docker/s-pdf/extraConfigs:/configs \
    -v /home/docker/s-pdf/logs:/logs \
    -e DOCKER_ENABLE_SECURITY=false \
    frooodle/s-pdf:latest
}

luopo_app_marketplace_stirling_pdf_update() {
  local app_port="$1"
  docker rm -f s-pdf >/dev/null 2>&1 || true
  docker rmi -f frooodle/s-pdf:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_stirling_pdf_install "$app_port"
}

luopo_app_marketplace_stirling_pdf_uninstall() {
  docker rm -f s-pdf >/dev/null 2>&1 || true
  docker rmi -f frooodle/s-pdf:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/s-pdf
  echo "应用已卸载"
}

luopo_app_marketplace_stirling_pdf_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "67" \
    "StirlingPDF工具大全" \
    "s-pdf" \
    "frooodle/s-pdf:latest" \
    "8031" \
    "强大的本地托管 PDF 操作工具，支持拆分、合并、转换、压缩等。" \
    "官网介绍: https://github.com/Stirling-Tools/Stirling-PDF" \
    "luopo_app_marketplace_stirling_pdf_install" \
    "luopo_app_marketplace_stirling_pdf_update" \
    "luopo_app_marketplace_stirling_pdf_uninstall"
}

luopo_app_marketplace_drawio_install() {
  local app_port="$1"
  mkdir -p /home/docker/drawio
  docker rm -f drawio >/dev/null 2>&1 || true
  docker run -d \
    --name drawio \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/drawio:/var/lib/drawio \
    jgraph/drawio
}

luopo_app_marketplace_drawio_update() {
  local app_port="$1"
  docker rm -f drawio >/dev/null 2>&1 || true
  docker rmi -f jgraph/drawio >/dev/null 2>&1 || true
  luopo_app_marketplace_drawio_install "$app_port"
}

luopo_app_marketplace_drawio_uninstall() {
  docker rm -f drawio >/dev/null 2>&1 || true
  docker rmi -f jgraph/drawio >/dev/null 2>&1 || true
  rm -rf /home/docker/drawio
  echo "应用已卸载"
}

luopo_app_marketplace_drawio_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "68" \
    "drawio免费的在线图表软件" \
    "drawio" \
    "jgraph/drawio" \
    "8032" \
    "强大的在线图表绘制软件，支持思维导图、拓扑图和流程图。" \
    "官网介绍: https://www.drawio.com/" \
    "luopo_app_marketplace_drawio_install" \
    "luopo_app_marketplace_drawio_update" \
    "luopo_app_marketplace_drawio_uninstall"
}

luopo_app_marketplace_it_tools_install() {
  local app_port="$1"
  docker rm -f it-tools >/dev/null 2>&1 || true
  docker run -d \
    --name it-tools \
    --restart=always \
    -p "${app_port}:80" \
    corentinth/it-tools:latest
}

luopo_app_marketplace_it_tools_update() {
  local app_port="$1"
  docker rm -f it-tools >/dev/null 2>&1 || true
  docker rmi -f corentinth/it-tools:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_it_tools_install "$app_port"
}

luopo_app_marketplace_it_tools_uninstall() {
  docker rm -f it-tools >/dev/null 2>&1 || true
  docker rmi -f corentinth/it-tools:latest >/dev/null 2>&1 || true
  echo "应用已卸载"
}

luopo_app_marketplace_it_tools_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "66" \
    "it-tools工具箱" \
    "it-tools" \
    "corentinth/it-tools:latest" \
    "8064" \
    "面向开发者和 IT 工作者的实用工具合集。" \
    "官网介绍: https://github.com/CorentinTh/it-tools" \
    "luopo_app_marketplace_it_tools_install" \
    "luopo_app_marketplace_it_tools_update" \
    "luopo_app_marketplace_it_tools_uninstall"
}

luopo_app_marketplace_gpt_load_install() {
  local app_port="$1"
  local app_passwd
  read -r -p "设置 gpt-load 登录密钥（建议 sk- 开头）: " app_passwd
  mkdir -p /home/docker/gpt-load/data
  docker rm -f gpt-load >/dev/null 2>&1 || true
  docker run -d \
    --name gpt-load \
    --restart=always \
    -p "${app_port}:3001" \
    -e AUTH_KEY="${app_passwd}" \
    -v /home/docker/gpt-load/data:/app/data \
    tbphp/gpt-load:latest
}

luopo_app_marketplace_gpt_load_update() {
  local app_port="$1"
  docker rm -f gpt-load >/dev/null 2>&1 || true
  docker rmi -f tbphp/gpt-load:latest >/dev/null 2>&1 || true
  luopo_app_marketplace_gpt_load_install "$app_port"
}

luopo_app_marketplace_gpt_load_uninstall() {
  docker rm -f gpt-load >/dev/null 2>&1 || true
  docker rmi -f tbphp/gpt-load:latest >/dev/null 2>&1 || true
  rm -rf /home/docker/gpt-load
  echo "应用已卸载"
}

luopo_app_marketplace_gpt_load_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "45" \
    "gpt-load高性能AI透明代理" \
    "gpt-load" \
    "tbphp/gpt-load:latest" \
    "8082" \
    "高性能 AI 接口透明代理服务。" \
    "官网介绍: https://www.gpt-load.com/" \
    "luopo_app_marketplace_gpt_load_install" \
    "luopo_app_marketplace_gpt_load_update" \
    "luopo_app_marketplace_gpt_load_uninstall"
}

luopo_app_marketplace_openwebui_install() {
  local app_port="$1"
  mkdir -p /home/docker/open-webui
  docker rm -f open-webui >/dev/null 2>&1 || true
  docker run -d \
    --name open-webui \
    --restart=always \
    -p "${app_port}:8080" \
    -v /home/docker/open-webui:/app/backend/data \
    ghcr.io/open-webui/open-webui:main
}

luopo_app_marketplace_openwebui_update() {
  local app_port="$1"
  docker rm -f open-webui >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/open-webui/open-webui:main >/dev/null 2>&1 || true
  luopo_app_marketplace_openwebui_install "$app_port"
}

luopo_app_marketplace_openwebui_uninstall() {
  docker rm -f open-webui >/dev/null 2>&1 || true
  docker rmi -f ghcr.io/open-webui/open-webui:main >/dev/null 2>&1 || true
  rm -rf /home/docker/open-webui
  echo "应用已卸载"
}

luopo_app_marketplace_openwebui_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "43" \
    "OpenWebUI自托管AI平台" \
    "open-webui" \
    "ghcr.io/open-webui/open-webui:main" \
    "8063" \
    "自托管大语言模型 Web UI，支持各类模型 API 接入。" \
    "官网介绍: https://github.com/open-webui/open-webui" \
    "luopo_app_marketplace_openwebui_install" \
    "luopo_app_marketplace_openwebui_update" \
    "luopo_app_marketplace_openwebui_uninstall"
}

luopo_app_marketplace_n8n_install() {
  local app_port="$1"
  luopo_app_marketplace_add_yuming
  mkdir -p /home/docker/n8n
  chmod -R 777 /home/docker/n8n
  docker rm -f n8n >/dev/null 2>&1 || true
  docker run -d \
    --name n8n \
    --restart=always \
    -p "${app_port}:5678" \
    -v /home/docker/n8n:/home/node/.n8n \
    -e N8N_HOST="${yuming}" \
    -e N8N_PORT=5678 \
    -e N8N_PROTOCOL=https \
    -e WEBHOOK_URL="https://${yuming}/" \
    docker.n8n.io/n8nio/n8n
  luopo_ldnmp_proxy_site "${yuming}" 127.0.0.1 "${app_port}"
  luopo_app_marketplace_block_container_port n8n "$ipv4_address"
}

luopo_app_marketplace_n8n_update() {
  local app_port="$1"
  docker rm -f n8n >/dev/null 2>&1 || true
  docker rmi -f docker.n8n.io/n8nio/n8n >/dev/null 2>&1 || true
  luopo_app_marketplace_n8n_install "$app_port"
}

luopo_app_marketplace_n8n_uninstall() {
  docker rm -f n8n >/dev/null 2>&1 || true
  docker rmi -f docker.n8n.io/n8nio/n8n >/dev/null 2>&1 || true
  rm -rf /home/docker/n8n
  echo "应用已卸载"
}

luopo_app_marketplace_n8n_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "44" \
    "n8n自动化工作流平台" \
    "n8n" \
    "docker.n8n.io/n8nio/n8n" \
    "8065" \
    "强大的自动化工作流平台，适合自动化编排与 webhook 流程。" \
    "官网介绍: https://github.com/n8n-io/n8n" \
    "luopo_app_marketplace_n8n_install" \
    "luopo_app_marketplace_n8n_update" \
    "luopo_app_marketplace_n8n_uninstall"
}

luopo_app_marketplace_dify_install() {
  local app_port="$1"
  install git
  luopo_app_marketplace_native_repo_sync "${gh_proxy}github.com/langgenius/dify.git" /home/docker/dify
  cd /home/docker/dify/docker
  [[ -f .env ]] || cp .env.example .env
  luopo_app_marketplace_native_set_env_value .env EXPOSE_NGINX_PORT "${app_port}"
  luopo_app_marketplace_native_set_env_value .env EXPOSE_NGINX_SSL_PORT "8858"
  docker compose up -d
  chown -R 1001:1001 /home/docker/dify/docker/volumes/app/storage 2>/dev/null || true
  chmod -R 755 /home/docker/dify/docker/volumes/app/storage 2>/dev/null || true
}

luopo_app_marketplace_dify_update() {
  local app_port="$1"
  luopo_app_marketplace_dify_install "$app_port"
  cd /home/docker/dify/docker
  docker compose pull || true
  docker compose up -d --remove-orphans
}

luopo_app_marketplace_dify_uninstall() {
  if [[ -d /home/docker/dify/docker ]]; then
    cd /home/docker/dify/docker && docker compose down --rmi all
  fi
  rm -rf /home/docker/dify
  echo "应用已卸载"
}

luopo_app_marketplace_dify_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "41" \
    "Dify大模型知识库" \
    "docker-nginx-1" \
    "dify" \
    "8058" \
    "开源 LLM 应用开发平台，支持知识库、工作流与 Agent。" \
    "官网介绍: https://github.com/langgenius/dify" \
    "luopo_app_marketplace_dify_install" \
    "luopo_app_marketplace_dify_update" \
    "luopo_app_marketplace_dify_uninstall"
}

luopo_app_marketplace_newapi_install() {
  local app_port="$1"
  install git
  luopo_app_marketplace_native_repo_sync "${gh_proxy}github.com/Calcium-Ion/new-api.git" /home/docker/new-api
  cd /home/docker/new-api
  sed -i \
    -e "s/- \"3000:3000\"/- \"${app_port}:3000\"/g" \
    -e 's/container_name: redis/container_name: redis-new-api/g' \
    -e 's/container_name: mysql/container_name: mysql-new-api/g' \
    docker-compose.yml
  docker compose up -d
}

luopo_app_marketplace_newapi_update() {
  local app_port="$1"
  luopo_app_marketplace_newapi_install "$app_port"
  cd /home/docker/new-api
  docker compose pull || true
  docker compose up -d --remove-orphans
}

luopo_app_marketplace_newapi_uninstall() {
  if [[ -d /home/docker/new-api ]]; then
    cd /home/docker/new-api && docker compose down --rmi all
  fi
  rm -rf /home/docker/new-api
  echo "应用已卸载"
}

luopo_app_marketplace_newapi_menu() {
  luopo_app_marketplace_native_docker_app_menu \
    "42" \
    "NewAPI大模型资产管理" \
    "new-api" \
    "calciumion/new-api" \
    "8059" \
    "OpenAI API 分发与额度管理面板。" \
    "官网介绍: https://github.com/Calcium-Ion/new-api" \
    "luopo_app_marketplace_newapi_install" \
    "luopo_app_marketplace_newapi_update" \
    "luopo_app_marketplace_newapi_uninstall"
}
