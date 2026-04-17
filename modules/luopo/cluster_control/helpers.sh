#!/usr/bin/env bash
set -euo pipefail

LUOPO_CLUSTER_DIR="${HOME}/cluster"
LUOPO_CLUSTER_SERVERS_FILE="${LUOPO_CLUSTER_DIR}/servers.py"

luopo_cluster_bootstrap() {
  return 0
  mkdir -p "$LUOPO_CLUSTER_DIR"
  if [[ ! -f "$LUOPO_CLUSTER_SERVERS_FILE" ]]; then
    cat >"$LUOPO_CLUSTER_SERVERS_FILE" <<'EOF'
servers = [

]
EOF
  fi
}

luopo_cluster_finish() {
  break_end
}

luopo_cluster_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

luopo_cluster_show_servers() {
  cat "$LUOPO_CLUSTER_SERVERS_FILE"
}

luopo_cluster_open_editor() {
  install nano
  nano "$LUOPO_CLUSTER_SERVERS_FILE"
}

luopo_cluster_run_commands_on_servers() {
  local remote_command="$1"
  install sshpass

  if [[ ! -f "$LUOPO_CLUSTER_SERVERS_FILE" ]]; then
    echo "未找到集群配置文件。"
    luopo_cluster_finish
    return 0
  fi

  local servers
  servers="$(grep -oP '{"name": "\K[^"]+|"hostname": "\K[^"]+|"port": \K[^,]+|"username": "\K[^"]+|"password": "\K[^"]+' "$LUOPO_CLUSTER_SERVERS_FILE" || true)"
  if [[ -z "${servers:-}" ]]; then
    echo "当前没有可执行的服务器记录。"
    luopo_cluster_finish
    return 0
  fi

  local server_array=()
  mapfile -t server_array <<<"$servers"

  clear
  local i name hostname port username password
  for ((i=0; i<${#server_array[@]}; i+=5)); do
    name="${server_array[i]}"
    hostname="${server_array[i+1]}"
    port="${server_array[i+2]}"
    username="${server_array[i+3]}"
    password="${server_array[i+4]}"
    echo
    echo -e "${gl_huang}连接到 $name ($hostname)...${gl_bai}"
    sshpass -p "$password" ssh -t -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$username@$hostname" -p "$port" "$remote_command" || true
  done
  echo
  luopo_cluster_finish
}
