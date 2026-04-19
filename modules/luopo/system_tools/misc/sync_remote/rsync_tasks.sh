#!/usr/bin/env bash
set -euo pipefail

# Rsync task storage, execution, and schedule helpers.

luopo_system_tools_rsync_config_file() {
  printf '%s\n' "$HOME/.rsync_tasks"
}

luopo_system_tools_rsync_key_dir() {
  printf '%s\n' "$HOME/.ssh/luopo_rsync"
}

luopo_system_tools_rsync_list_tasks() {
  local config_file="$1"
  echo "已保存的同步任务:"
  echo "---------------------------------"
  if [[ ! -s "$config_file" ]]; then
    echo "暂无任务"
  else
    awk -F'|' '{printf "%d. %s (%s -> %s@%s:%s)\n", NR, $1, $2, $3, $4, $5}' "$config_file"
  fi
  echo "---------------------------------"
}

luopo_system_tools_rsync_list_schedules() {
  echo "当前定时任务:"
  echo "---------------------------------"
  crontab -l 2>/dev/null | grep "luopo_rsync_run" || echo "暂无定时任务"
  echo "---------------------------------"
}

luopo_system_tools_rsync_add_task() {
  local config_file="$1"
  local key_dir="$2"
  local name local_path remote_user remote_host remote_path port mode options auth_method secret key_file password

  send_stats "添加新同步任务"
  echo "创建新同步任务示例："
  echo "  - 任务名称: backup_www"
  echo "  - 本地目录: /var/www"
  echo "  - 远程用户: root"
  echo "  - 远程地址: 192.168.1.100"
  echo "  - 远程目录: /backup/www"
  echo "---------------------------------"
  read -r -p "请输入任务名称: " name
  read -r -p "请输入本地目录: " local_path
  read -r -p "请输入远程用户名 [默认root]: " remote_user
  read -r -p "请输入远程服务器IP/域名: " remote_host
  read -r -p "请输入远程目录: " remote_path
  read -r -p "请输入 SSH 端口 [默认22]: " port
  remote_user="${remote_user:-root}"
  port="${port:-22}"

  if [[ -z "$name" || -z "$local_path" || -z "$remote_host" || -z "$remote_path" ]]; then
    echo "任务名称、本地目录、远程地址、远程目录不能为空。"
    return 1
  fi

  echo "请选择认证方式:"
  echo "1. SSH 密码"
  echo "2. SSH 私钥文件"
  read -r -p "请选择 (1/2): " auth_choice
  case "$auth_choice" in
    1)
      read -r -s -p "请输入 SSH 密码: " password
      echo
      auth_method="password"
      secret="$password"
      ;;
    2)
      mkdir -p "$key_dir"
      read -r -p "请输入私钥文件路径（留空则粘贴保存为专用密钥）: " key_file
      if [[ -z "$key_file" ]]; then
        key_file="$key_dir/${name}_sync.key"
        echo "请粘贴私钥内容，输入单独一行 EOF 结束："
        : > "$key_file"
        while IFS= read -r line; do
          [[ "$line" == "EOF" ]] && break
          printf '%s\n' "$line" >> "$key_file"
        done
      fi
      if [[ ! -f "$key_file" ]]; then
        echo "私钥文件不存在。"
        return 1
      fi
      chmod 600 "$key_file"
      auth_method="key"
      secret="$key_file"
      ;;
    *)
      echo "无效认证方式。"
      return 1
      ;;
  esac

  echo "请选择同步模式:"
  echo "1. 标准模式 (-avz)"
  echo "2. 删除目标多余文件 (-avz --delete)"
  read -r -p "请选择 (1/2): " mode
  case "$mode" in
    2) options="-avz --delete" ;;
    *) options="-avz" ;;
  esac

  install rsync
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$name" "$local_path" "$remote_user" "$remote_host" "$remote_path" "$port" "$options" "$auth_method" "$secret" >> "$config_file"
  echo "任务已保存。"
}

luopo_system_tools_rsync_delete_task() {
  local config_file="$1"
  local key_dir="$2"
  local num task name local_path remote_user remote_host remote_path port options auth_method secret

  send_stats "删除同步任务"
  luopo_system_tools_rsync_list_tasks "$config_file"
  read -r -p "请输入要删除的任务编号: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  task="$(sed -n "${num}p" "$config_file" 2>/dev/null || true)"
  if [[ -z "$task" ]]; then
    echo "未找到对应任务。"
    return 1
  fi

  IFS='|' read -r name local_path remote_user remote_host remote_path port options auth_method secret <<< "$task"
  read -r -p "确认删除任务 $name ? (y/N): " confirm
  case "$confirm" in
    [Yy])
      if [[ "$auth_method" == "key" && "$secret" == "$key_dir"* ]]; then
        rm -f -- "$secret"
      fi
      sed -i "${num}d" "$config_file"
      echo "任务已删除。"
      ;;
    *) echo "已取消。" ;;
  esac
}

luopo_system_tools_rsync_run_task() {
  local direction="${1:-push}"
  local num="${2:-}"
  local config_file
  local task name local_path remote_user remote_host remote_path port options auth_method secret
  local source_path destination_path ssh_options

  config_file="$(luopo_system_tools_rsync_config_file)"
  if [[ -z "$num" ]]; then
    luopo_system_tools_rsync_list_tasks "$config_file"
    read -r -p "请输入要执行的任务编号: " num
  fi
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  task="$(sed -n "${num}p" "$config_file" 2>/dev/null || true)"
  if [[ -z "$task" ]]; then
    echo "未找到对应任务。"
    return 1
  fi

  IFS='|' read -r name local_path remote_user remote_host remote_path port options auth_method secret <<< "$task"
  ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

  if [[ "$direction" == "pull" ]]; then
    echo "正在拉取同步到本地: $remote_user@$remote_host:$remote_path -> $local_path"
    source_path="$remote_user@$remote_host:$remote_path"
    destination_path="$local_path"
  else
    echo "正在推送同步到远端: $local_path -> $remote_user@$remote_host:$remote_path"
    source_path="$local_path"
    destination_path="$remote_user@$remote_host:$remote_path"
  fi

  install rsync
  if [[ "$auth_method" == "password" ]]; then
    install sshpass
    sshpass -p "$secret" rsync $options -e "ssh $ssh_options" "$source_path" "$destination_path"
  else
    if [[ ! -f "$secret" ]]; then
      echo "密钥文件不存在: $secret"
      return 1
    fi
    chmod 600 "$secret"
    rsync $options -e "ssh -i $secret $ssh_options" "$source_path" "$destination_path"
  fi
}

luopo_system_tools_rsync_schedule_task() {
  local num interval random_minute cron_time root_dir cron_job

  send_stats "添加同步定时任务"
  luopo_system_tools_rsync_list_tasks "$(luopo_system_tools_rsync_config_file)"
  read -r -p "请输入要定时同步的任务编号: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  echo "请选择定时执行间隔："
  echo "1. 每小时执行一次"
  echo "2. 每天执行一次"
  echo "3. 每周执行一次"
  read -r -p "请输入选项 (1/2/3): " interval

  random_minute="$(awk 'BEGIN{srand(); print int(rand()*60)}')"
  case "$interval" in
    1) cron_time="$random_minute * * * *" ;;
    2) cron_time="$random_minute 0 * * *" ;;
    3) cron_time="$random_minute 0 * * 1" ;;
    *)
      echo "无效选项。"
      return 1
      ;;
  esac

  check_crontab_installed
  root_dir="${ROOT_DIR:-/opt/luopo-toolkit}"
  cron_job="$cron_time bash \"$root_dir/toolkit.sh\" rsync_run \"$num\" # luopo_rsync_run:$num"
  if crontab -l 2>/dev/null | grep -q "luopo_rsync_run:$num"; then
    echo "该任务的定时同步已存在。"
    return 1
  fi
  (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
  echo "定时任务已创建: $cron_job"
}

luopo_system_tools_rsync_delete_schedule() {
  local num tmp_file

  send_stats "删除同步定时任务"
  luopo_system_tools_rsync_list_schedules
  read -r -p "请输入要删除定时任务的编号: " num
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "请输入有效编号。"
    return 1
  fi

  tmp_file="$(mktemp)"
  crontab -l 2>/dev/null | grep -v "luopo_rsync_run:$num" > "$tmp_file" || true
  crontab "$tmp_file"
  rm -f "$tmp_file"
  echo "已删除任务编号 $num 的定时任务。"
}

luopo_system_tools_rsync_menu() {
  local config_file key_dir

  config_file="$(luopo_system_tools_rsync_config_file)"
  key_dir="$(luopo_system_tools_rsync_key_dir)"
  mkdir -p "$(dirname "$config_file")" "$key_dir"
  touch "$config_file"

  while true; do
    clear
    echo "Rsync 远程同步工具"
    echo "远程目录之间同步，支持增量同步。"
    echo "---------------------------------"
    luopo_system_tools_rsync_list_tasks "$config_file"
    echo
    luopo_system_tools_rsync_list_schedules
    echo
    echo "1. 创建新任务"
    echo "2. 删除任务"
    echo "3. 执行本地同步到远端"
    echo "4. 执行远端同步到本地"
    echo "5. 创建定时任务"
    echo "6. 删除定时任务"
    echo "---------------------------------"
    echo "0. 返回上一级选单"
    echo "---------------------------------"
    read -r -p "请输入你的选择: " choice

    case "$choice" in
      1) luopo_system_tools_rsync_add_task "$config_file" "$key_dir" ;;
      2) luopo_system_tools_rsync_delete_task "$config_file" "$key_dir" ;;
      3) luopo_system_tools_rsync_run_task push ;;
      4) luopo_system_tools_rsync_run_task pull ;;
      5) luopo_system_tools_rsync_schedule_task ;;
      6) luopo_system_tools_rsync_delete_schedule ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}
