#!/usr/bin/env bash
set -euo pipefail

cluster_menu() {
  local choice idx host cmd
  while true; do
    clear
    echo "========================================"
    echo "服务器集群控制"
    echo "========================================"
    menu_item "1" "查看节点列表"
    menu_item "2" "添加节点 (user@ip)"
    menu_item "3" "删除节点"
    menu_item "4" "批量执行命令"
    echo "------------------------"
    menu_item "21" "批量拉取系统信息"
    menu_item "22" "批量连通性检测 (ping)"
    menu_item "23" "批量重启节点"
    menu_item "24" "批量更新系统"
    echo "------------------------"
    menu_item "31" "批量分发文件(scp)"
    menu_item "32" "导出节点列表"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    ensure_cluster_nodes_file
    case "$choice" in
      1) show_file_with_line_no "$CLUSTER_NODES_FILE"; menu_wait ;;
      2)
        read -r -p "输入节点 (user@ip): " host
        [[ -n "$host" ]] && echo "$host" >>"$CLUSTER_NODES_FILE" && say_ok "已添加节点: $host"
        menu_wait
        ;;
      3)
        show_file_with_line_no "$CLUSTER_NODES_FILE"
        read -r -p "输入要删除的行号: " idx
        [[ "$idx" =~ ^[0-9]+$ ]] && sed -i "${idx}d" "$CLUSTER_NODES_FILE" && say_ok "删除完成" || say_warn "行号无效"
        menu_wait
        ;;
      4)
        read -r -p "输入要批量执行的命令: " cmd
        while IFS= read -r host; do
          [[ -z "$host" ]] && continue
          echo "[$host] >>> $cmd"
          ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "$cmd" || say_warn "[$host] 执行失败"
        done <"$CLUSTER_NODES_FILE"
        menu_wait
        ;;
      21)
        while IFS= read -r host; do
          [[ -z "$host" ]] && continue
          echo "[$host]"
          ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "hostname && uname -r && uptime" || say_warn "[$host] 拉取失败"
          echo ""
        done <"$CLUSTER_NODES_FILE"
        menu_wait
        ;;
      22)
        while IFS= read -r host; do
          [[ -z "$host" ]] && continue
          ip="${host##*@}"
          ping -c 1 -W 1 "$ip" >/dev/null 2>&1 && say_ok "[$host] reachable" || say_warn "[$host] unreachable"
        done <"$CLUSTER_NODES_FILE"
        menu_wait
        ;;
      23)
        if ! confirm_or_cancel "确认批量重启所有节点？(y/N): "; then
          menu_wait
          continue
        fi
        log_action "cluster:batch_reboot:start"
        while IFS= read -r host; do
          [[ -z "$host" ]] && continue
          ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "reboot" || say_warn "[$host] 重启命令执行失败"
        done <"$CLUSTER_NODES_FILE"
        log_action "cluster:batch_reboot:done"
        menu_wait
        ;;
      24)
        if ! confirm_or_cancel "确认批量更新所有节点？(y/N): "; then
          menu_wait
          continue
        fi
        log_action "cluster:batch_update:start"
        while IFS= read -r host; do
          [[ -z "$host" ]] && continue
          ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" "apt-get update -y && apt-get upgrade -y" || say_warn "[$host] 更新失败"
        done <"$CLUSTER_NODES_FILE"
        log_action "cluster:batch_update:done"
        menu_wait
        ;;
      31)
        read -r -p "输入本地文件路径: " local_file
        read -r -p "输入远程目标路径(如 /root/): " remote_path
        while IFS= read -r host; do
          [[ -z "$host" ]] && continue
          scp -o ConnectTimeout=5 "$local_file" "${host}:${remote_path}" || say_warn "[$host] 分发失败"
        done <"$CLUSTER_NODES_FILE"
        menu_wait
        ;;
      32)
        cp "$CLUSTER_NODES_FILE" "/root/cluster-nodes-$(date +%Y%m%d-%H%M%S).txt"
        say_ok "已导出到 /root"
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

