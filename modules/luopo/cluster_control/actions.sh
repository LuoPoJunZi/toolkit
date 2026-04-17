#!/usr/bin/env bash
set -euo pipefail

luopo_cluster_add_server() {
  send_stats "添加集群服务器"
  read -r -p "服务器名称: " server_name
  read -r -p "服务器IP: " server_ip
  read -r -p "服务器端口（22）: " server_port
  server_port=${server_port:-22}
  read -r -p "服务器用户名（root）: " server_username
  server_username=${server_username:-root}
  read -r -p "服务器用户密码: " server_password

  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," "$LUOPO_CLUSTER_SERVERS_FILE"
  luopo_cluster_finish
}

luopo_cluster_remove_server() {
  send_stats "删除集群服务器"
  read -r -p "请输入需要删除的关键字: " rmserver
  sed -i "/$rmserver/d" "$LUOPO_CLUSTER_SERVERS_FILE"
  luopo_cluster_finish
}

luopo_cluster_edit_server() {
  send_stats "编辑集群服务器"
  luopo_cluster_open_editor
}

luopo_cluster_backup() {
  clear
  send_stats "备份集群"
  echo "请将 /root/cluster/servers.py 文件下载，完成备份！"
  luopo_cluster_finish
}

luopo_cluster_restore() {
  clear
  send_stats "还原集群"
  echo "请上传您的servers.py，按任意键开始上传！"
  echo "请上传您的 servers.py 文件到 /root/cluster/ 完成还原！"
  luopo_cluster_finish
}

luopo_cluster_install_toolkit() { luopo_cluster_run_commands_on_servers "bash <(curl -fsSL https://z.evzzz.com)"; }
luopo_cluster_update_system() { luopo_cluster_run_commands_on_servers "z update"; }
luopo_cluster_clean_system() { luopo_cluster_run_commands_on_servers "z clean"; }
luopo_cluster_install_docker() { luopo_cluster_run_commands_on_servers "z docker install"; }
luopo_cluster_install_bbr3() { luopo_cluster_run_commands_on_servers "z bbr3"; }
luopo_cluster_set_swap() { luopo_cluster_run_commands_on_servers "z swap 1024"; }
luopo_cluster_set_timezone() { luopo_cluster_run_commands_on_servers "z time Asia/Shanghai"; }
luopo_cluster_open_ports() { luopo_cluster_run_commands_on_servers "z iptables_open"; }

luopo_cluster_custom_command() {
  send_stats "自定义执行命令"
  read -r -p "请输入批量执行的命令: " mingling
  if [[ -z "${mingling:-}" ]]; then
    luopo_cluster_finish
    return 0
  fi
  luopo_cluster_run_commands_on_servers "${mingling}"
}
