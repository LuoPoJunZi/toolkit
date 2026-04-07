#!/usr/bin/env bash
set -euo pipefail

ai_workspace_menu() {
  local choice model_name action
  while true; do
    clear
    echo "========================================"
    echo "AI工作区(可选)"
    echo "========================================"
    menu_item "1" "OpenWebUI 一键部署"
    menu_item "2" "Ollama 一键安装"
    menu_item "3" "拉取 Ollama 模型"
    menu_item "4" "AI 服务状态检查"
    echo "------------------------"
    menu_item "21" "AnythingLLM 一键部署"
    menu_item "22" "One-API 一键部署"
    menu_item "23" "Dify 一键部署"
    menu_item "24" "更新 OpenWebUI/Ollama"
    echo "------------------------"
    menu_item "31" "查看 AI 服务日志"
    menu_item "32" "启停 AI 服务"
    menu_item "33" "卸载 AI 组件"
    menu_item "34" "清理 AI 模型缓存"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "openwebui" "OpenWebUI: http://你的IP:3000" "OpenWebUI 部署" -d --name openwebui --restart unless-stopped -p 3000:8080 -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main
        menu_wait
        ;;
      2)
        if run_remote_bash_script "https://ollama.com/install.sh" "Ollama 安装"; then
          say_ok "Ollama 安装完成"
        fi
        menu_wait
        ;;
      3)
        read -r -p "输入模型名(如 llama3.1:8b): " model_name
        if command -v ollama >/dev/null 2>&1; then
          if ollama pull "$model_name"; then
            say_ok "模型拉取完成: ${model_name}"
          else
            say_action_failed "Ollama 拉取模型" "$(i18n_get msg_reason_exec_failed 'execution failed')"
          fi
        else
          say_warn "未检测到 ollama，请先安装"
        fi
        menu_wait
        ;;
      4)
        systemctl status ollama --no-pager -l 2>/dev/null | head -n 20 || say_warn "ollama 未运行"
        if command -v docker >/dev/null 2>&1; then
          docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E 'openwebui|ollama|anythingllm|one-api|dify' || say_warn "未发现运行中的 AI 容器"
        else
          say_warn "Docker 未安装"
        fi
        menu_wait
        ;;
      21)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "anythingllm" "AnythingLLM: http://你的IP:3002" "AnythingLLM 部署" -d --name anythingllm --restart unless-stopped -p 3002:3001 -v /opt/anythingllm:/app/server/storage mintplexlabs/anythingllm:latest
        menu_wait
        ;;
      22)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "one-api" "One-API: http://你的IP:3003" "One-API 部署" -d --name one-api --restart unless-stopped -p 3003:3000 -v /opt/one-api:/data justsong/one-api:latest
        menu_wait
        ;;
      23)
        ensure_docker_compose || { menu_wait; continue; }
        mkdir -p /opt/dify
        cat >/opt/dify/docker-compose.yml <<'EOF'
services:
  dify-web:
    image: langgenius/dify-web:latest
    restart: unless-stopped
    ports:
      - "3004:3000"
EOF
        if (cd /opt/dify && docker compose up -d); then
          say_ok "Dify: http://你的IP:3004"
        else
          say_action_failed "Dify 部署" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      24)
        ensure_docker_ready || { menu_wait; continue; }
        if command -v ollama >/dev/null 2>&1; then
          systemctl restart ollama >/dev/null 2>&1 || say_warn "Ollama 重启失败，已继续更新 OpenWebUI"
        fi
        if ! docker pull ghcr.io/open-webui/open-webui:main; then
          say_action_failed "OpenWebUI 更新" "$(i18n_get msg_reason_exec_failed 'execution failed')"
          menu_wait
          continue
        fi
        docker rm -f openwebui 2>/dev/null || true
        docker_ensure_container "openwebui" "OpenWebUI/Ollama 更新完成" "OpenWebUI 更新重启" -d --name openwebui --restart unless-stopped -p 3000:8080 -v open-webui:/app/backend/data ghcr.io/open-webui/open-webui:main
        menu_wait
        ;;
      31)
        read -r -p "输入服务名(openwebui/ollama/anythingllm/one-api): " action
        case "$action" in
          ollama) journalctl -u ollama -n 120 --no-pager 2>/dev/null || say_warn "未读取到日志" ;;
          *) docker logs --tail 120 "$action" 2>/dev/null || say_warn "未读取到日志" ;;
        esac
        menu_wait
        ;;
      32)
        read -r -p "输入服务名(openwebui/ollama/anythingllm/one-api): " model_name
        read -r -p "输入操作(start/stop/restart): " action
        case "$model_name" in
          ollama)
            case "$action" in
              start) systemctl start ollama 2>/dev/null && say_ok "ollama 已启动" || say_action_failed "ollama 启动" "$(i18n_get msg_reason_exec_failed 'execution failed')" ;;
              stop) systemctl stop ollama 2>/dev/null && say_ok "ollama 已停止" || say_action_failed "ollama 停止" "$(i18n_get msg_reason_exec_failed 'execution failed')" ;;
              restart) systemctl restart ollama 2>/dev/null && say_ok "ollama 已重启" || say_action_failed "ollama 重启" "$(i18n_get msg_reason_exec_failed 'execution failed')" ;;
              *) say_warn "不支持的操作" ;;
            esac
            ;;
          *)
            case "$action" in
              start) docker start "$model_name" >/dev/null 2>&1 && say_ok "${model_name} 已启动" || say_action_failed "${model_name} 启动" "$(i18n_get msg_reason_exec_failed 'execution failed')" ;;
              stop) docker stop "$model_name" >/dev/null 2>&1 && say_ok "${model_name} 已停止" || say_action_failed "${model_name} 停止" "$(i18n_get msg_reason_exec_failed 'execution failed')" ;;
              restart) docker restart "$model_name" >/dev/null 2>&1 && say_ok "${model_name} 已重启" || say_action_failed "${model_name} 重启" "$(i18n_get msg_reason_exec_failed 'execution failed')" ;;
              *) say_warn "不支持的操作" ;;
            esac
            ;;
        esac
        menu_wait
        ;;
      33)
        local removed_count
        removed_count=0
        for c in openwebui anythingllm one-api dify-web; do
          if docker rm -f "$c" >/dev/null 2>&1; then
            removed_count=$((removed_count + 1))
          fi
        done
        if systemctl stop ollama >/dev/null 2>&1; then
          removed_count=$((removed_count + 1))
        fi
        if (( removed_count > 0 )); then
          say_ok "已卸载/停止 ${removed_count} 个 AI 组件"
        else
          say_warn "未发现可卸载的 AI 组件"
        fi
        menu_wait
        ;;
      34)
        if command -v ollama >/dev/null 2>&1; then
          ollama list 2>/dev/null || true
          read -r -p "输入要删除的模型名(可空跳过): " model_name
          if [[ -n "$model_name" ]]; then
            ollama rm "$model_name" 2>/dev/null && say_ok "已删除模型: ${model_name}" || say_warn "模型删除失败或不存在: ${model_name}"
          fi
        fi
        if docker image prune -f >/dev/null 2>&1; then
          say_ok "AI 模型/镜像缓存清理已执行"
        else
          say_warn "镜像缓存清理失败或 Docker 不可用"
        fi
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}
