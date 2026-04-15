#!/usr/bin/env bash
set -euo pipefail

luopo_workspace_open_work1() { luopo_workspace_run_named_session "work1"; }
luopo_workspace_open_work2() { luopo_workspace_run_named_session "work2"; }
luopo_workspace_open_work3() { luopo_workspace_run_named_session "work3"; }
luopo_workspace_open_work4() { luopo_workspace_run_named_session "work4"; }
luopo_workspace_open_work5() { luopo_workspace_run_named_session "work5"; }
luopo_workspace_open_work6() { luopo_workspace_run_named_session "work6"; }
luopo_workspace_open_work7() { luopo_workspace_run_named_session "work7"; }
luopo_workspace_open_work8() { luopo_workspace_run_named_session "work8"; }
luopo_workspace_open_work9() { luopo_workspace_run_named_session "work9"; }
luopo_workspace_open_work10() { luopo_workspace_run_named_session "work10"; }

luopo_workspace_manage_ssh_mode() {
  while true; do
    clear
    local status_text="关闭"
    if luopo_workspace_is_ssh_mode_enabled; then
      status_text="开启"
    fi
    send_stats "SSH常驻模式"
    echo "SSH常驻模式 $status_text"
    echo "开启后SSH连接后会直接进入常驻模式，直接回到之前的工作状态。"
    echo "------------------------"
    echo "1. 开启            2. 关闭"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " ssh_mode_choice

    case "$ssh_mode_choice" in
      1)
        luopo_workspace_enable_ssh_mode
        return 0
        ;;
      2)
        luopo_workspace_disable_ssh_mode
        luopo_workspace_finish
        return 0
        ;;
      0)
        return 0
        ;;
      *)
        luopo_workspace_invalid_choice
        ;;
    esac
  done
}

luopo_workspace_enter_custom() {
  read -r -p "请输入你创建或进入的工作区名称，如1001 kj001 work1: " SESSION_NAME
  if [[ -z "${SESSION_NAME:-}" ]]; then
    echo "未输入工作区名称"
    luopo_workspace_finish
    return 0
  fi
  clear
  install tmux
  tmux_run
  send_stats "自定义工作区"
  return 0
}

luopo_workspace_inject_command() {
  read -r -p "请输入你要后台执行的命令，如:curl -fsSL https://get.docker.com | sh: " tmux_command
  if [[ -z "${tmux_command:-}" ]]; then
    echo "未输入后台命令"
    luopo_workspace_finish
    return 0
  fi
  luopo_workspace_send_command "$tmux_command"
}

luopo_workspace_remove_custom() {
  read -r -p "请输入要删除的工作区名称: " workspace_name
  luopo_workspace_delete_session "$workspace_name"
}
