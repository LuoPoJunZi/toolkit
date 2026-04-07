#!/usr/bin/env bash
set -euo pipefail

game_server_menu() {
  local choice container_name action
  while true; do
    clear
    echo "========================================"
    echo "游戏开服脚本合集"
    echo "========================================"
    menu_item "1" "Minecraft Java 一键部署"
    menu_item "2" "Minecraft Bedrock 一键部署"
    menu_item "3" "Palworld 一键部署"
    menu_item "4" "CS2 一键部署(社区镜像)"
    echo "------------------------"
    menu_item "21" "Valheim 一键部署"
    menu_item "22" "Rust 一键部署"
    menu_item "23" "Terraria 一键部署"
    menu_item "24" "7 Days to Die 一键部署"
    echo "------------------------"
    menu_item "31" "查看游戏容器状态"
    menu_item "32" "启停/重启游戏容器"
    menu_item "33" "查看游戏容器日志"
    menu_item "34" "卸载指定游戏容器"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "mc-java" "Minecraft Java 已部署，端口: 25565" "Minecraft Java 部署" -d --name mc-java --restart unless-stopped -p 25565:25565 -e EULA=TRUE -e MEMORY=2G -v /opt/games/mc-java:/data itzg/minecraft-server:latest
        menu_wait
        ;;
      2)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "mc-bedrock" "Minecraft Bedrock 已部署，端口: 19132/udp" "Minecraft Bedrock 部署" -d --name mc-bedrock --restart unless-stopped -p 19132:19132/udp -v /opt/games/mc-bedrock:/data itzg/minecraft-bedrock-server:latest
        menu_wait
        ;;
      3)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "palworld" "Palworld 已部署，端口: 8211/udp, 27015/udp" "Palworld 部署" -d --name palworld --restart unless-stopped -p 8211:8211/udp -p 27015:27015/udp -v /opt/games/palworld:/palworld/ palworld-server-docker/palworld-server:latest
        menu_wait
        ;;
      4)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "cs2" "CS2 已部署，端口: 27015/udp, 27020/udp（请配置 SRCDS_TOKEN）" "CS2 部署" -d --name cs2 --restart unless-stopped -p 27015:27015/udp -p 27020:27020/udp -e SRCDS_TOKEN=changeme -v /opt/games/cs2:/home/steam/cs2/ joedwards32/cs2
        menu_wait
        ;;
      21)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "valheim" "Valheim 已部署，端口: 2456-2458/udp" "Valheim 部署" -d --name valheim --restart unless-stopped -p 2456-2458:2456-2458/udp -e SERVER_NAME=ValheimServer -e WORLD_NAME=Dedicated -e SERVER_PASS=ChangeMe123 -v /opt/games/valheim:/config lloesche/valheim-server:latest
        menu_wait
        ;;
      22)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "rust" "Rust 已部署，端口: 28015/udp, 28016/udp" "Rust 部署" -d --name rust --restart unless-stopped -p 28015:28015/udp -p 28016:28016/udp -v /opt/games/rust:/steamcmd/rust didstopia/rust-server:latest
        menu_wait
        ;;
      23)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "terraria" "Terraria 已部署，端口: 7777" "Terraria 部署" -d --name terraria --restart unless-stopped -p 7777:7777 -v /opt/games/terraria:/root/.local/share/Terraria tmodloader/tmodloader:latest
        menu_wait
        ;;
      24)
        ensure_docker_ready || { menu_wait; continue; }
        docker_ensure_container "sdtz" "7 Days to Die 已部署，端口: 26900/tcp+udp, 26901/udp" "7 Days to Die 部署" -d --name sdtz --restart unless-stopped -p 26900:26900/tcp -p 26900:26900/udp -p 26901:26901/udp -v /opt/games/7dtd:/data didstopia/7dtd-server:latest
        menu_wait
        ;;
      31)
        if ! ensure_docker_ready; then
          menu_wait
          continue
        fi
        docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E 'mc-java|mc-bedrock|palworld|cs2|valheim|rust|terraria|sdtz' || say_warn "未发现已知游戏容器"
        menu_wait
        ;;
      32)
        read -r -p "输入容器名: " container_name
        read -r -p "输入操作(start/stop/restart): " action
        case "$action" in
          start) docker start "$container_name" >/dev/null 2>&1 && say_ok "已启动 ${container_name}" || say_err "操作失败" ;;
          stop) docker stop "$container_name" >/dev/null 2>&1 && say_ok "已停止 ${container_name}" || say_err "操作失败" ;;
          restart) docker restart "$container_name" >/dev/null 2>&1 && say_ok "已重启 ${container_name}" || say_err "操作失败" ;;
          *) say_warn "不支持的操作" ;;
        esac
        menu_wait
        ;;
      33)
        read -r -p "输入容器名: " container_name
        docker logs --tail 120 "$container_name" 2>/dev/null || say_warn "未读取到日志"
        menu_wait
        ;;
      34)
        read -r -p "输入要卸载的容器名: " container_name
        if ! confirm_or_cancel "确认卸载容器 ${container_name} ? (y/N): "; then
          menu_wait
          continue
        fi
        read -r -p "是否同时删除对应目录 /opt/games/${container_name} ? (y/N): " ans
        log_action "game_server:uninstall:${container_name}:start"
        if docker rm -f "$container_name" >/dev/null 2>&1; then
          say_ok "容器已删除: ${container_name}"
        else
          say_warn "容器不存在或删除失败: ${container_name}"
        fi
        if is_yes "$ans"; then
          rm -rf "/opt/games/${container_name}" 2>/dev/null || true
          say_ok "数据目录已清理: /opt/games/${container_name}"
        fi
        log_action "game_server:uninstall:${container_name}:done"
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

