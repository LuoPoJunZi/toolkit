#!/usr/bin/env bash
set -euo pipefail

workspace_menu() {
  local choice session_name
  while true; do
    clear
    echo "========================================"
    echo "后台工作区"
    echo "========================================"
    menu_item "1" "Screen 会话列表"
    menu_item "2" "Tmux 会话列表"
    menu_item "3" "创建 Screen 会话"
    menu_item "4" "创建 Tmux 会话"
    echo "------------------------"
    menu_item "21" "开机自启服务查看"
    menu_item "22" "关闭指定 Screen 会话"
    menu_item "23" "关闭指定 Tmux 会话"
    menu_item "24" "查看最近 100 行系统日志"
    echo "------------------------"
    menu_item "31" "查看前台高占用进程"
    menu_item "32" "查看后台任务(job)"
    menu_item "33" "查看 systemd failed 服务"
    menu_item "34" "实时系统日志(journalctl -f)"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1) screen -ls 2>/dev/null || say_warn "未安装或无会话"; menu_wait ;;
      2) tmux ls 2>/dev/null || say_warn "未安装或无会话"; menu_wait ;;
      3)
        if ! apt_install screen; then
          say_action_failed "Screen 安装" "$(i18n_get msg_reason_install_failed 'install failed')"
          menu_wait
          continue
        fi
        read -r -p "输入会话名: " session_name
        if screen -dmS "$session_name"; then
          say_ok "已创建 screen 会话: $session_name"
        else
          say_action_failed "Screen 会话创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      4)
        if ! apt_install tmux; then
          say_action_failed "Tmux 安装" "$(i18n_get msg_reason_install_failed 'install failed')"
          menu_wait
          continue
        fi
        read -r -p "输入会话名: " session_name
        if tmux new-session -d -s "$session_name"; then
          say_ok "已创建 tmux 会话: $session_name"
        else
          say_action_failed "Tmux 会话创建" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      21) systemctl list-unit-files --type=service | grep enabled || true; menu_wait ;;
      22)
        read -r -p "输入要关闭的 Screen 会话名: " session_name
        if screen -S "$session_name" -X quit 2>/dev/null; then
          say_ok "已关闭 Screen 会话: $session_name"
        else
          say_warn "未找到 Screen 会话: $session_name"
        fi
        menu_wait
        ;;
      23)
        read -r -p "输入要关闭的 Tmux 会话名: " session_name
        if tmux kill-session -t "$session_name" 2>/dev/null; then
          say_ok "已关闭 Tmux 会话: $session_name"
        else
          say_warn "未找到 Tmux 会话: $session_name"
        fi
        menu_wait
        ;;
      24) journalctl -n 100 --no-pager || true; menu_wait ;;
      31) ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 25; menu_wait ;;
      32) jobs -l || say_warn "当前无 shell 后台任务"; menu_wait ;;
      33) systemctl --failed; menu_wait ;;
      34) journalctl -f ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

