#!/usr/bin/env bash
set -euo pipefail

luopo_workspace_bootstrap() {
  return 0
}

luopo_workspace_finish() {
  break_end
}

luopo_workspace_list_sessions() {
  tmux list-sessions 2>/dev/null || echo "暂无工作区"
}

luopo_workspace_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

luopo_workspace_run_named_session() {
  local session_name="$1"
  clear
  install tmux
  local SESSION_NAME="$session_name"
  send_stats "启动工作区$SESSION_NAME"
  tmux_run
  return 0
}

luopo_workspace_send_command() {
  local command_text="$1"
  clear
  install tmux
  local tmuxd="$command_text"
  tmux_run_d
  send_stats "注入命令到后台工作区"
  luopo_workspace_finish
}

luopo_workspace_delete_session() {
  local session_name="$1"
  if [[ -z "${session_name:-}" ]]; then
    echo "未输入工作区名称"
    luopo_workspace_finish
    return 0
  fi

  tmux kill-window -t "$session_name" 2>/dev/null || tmux kill-session -t "$session_name" 2>/dev/null || true
  send_stats "删除工作区"
  luopo_workspace_finish
}

luopo_workspace_is_ssh_mode_enabled() {
  grep -q 'tmux attach-session -t sshd || tmux new-session -s sshd' ~/.bashrc 2>/dev/null
}

luopo_workspace_enable_ssh_mode() {
  install tmux
  local SESSION_NAME="sshd"
  send_stats "启动工作区$SESSION_NAME"
  grep -q "tmux attach-session -t sshd" ~/.bashrc 2>/dev/null || cat >> ~/.bashrc <<'EOF'

# 自动进入 tmux 会话
if [[ -z "$TMUX" ]]; then
    tmux attach-session -t sshd || tmux new-session -s sshd
fi
EOF
  tmux_run
  return 0
}

luopo_workspace_disable_ssh_mode() {
  sed -i '/# 自动进入 tmux 会话/,+4d' ~/.bashrc 2>/dev/null || true
  tmux kill-window -t sshd 2>/dev/null || tmux kill-session -t sshd 2>/dev/null || true
  return 0
}
