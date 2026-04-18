#!/usr/bin/env bash
set -euo pipefail

LUOPO_SYSTEM_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LUOPO_SYSTEM_TOOLS_DIR/../../.." && pwd)"

luopo_system_tools_bootstrap() {
  return 0
}

root_use() {
  if [[ "$EUID" -ne 0 ]]; then
    echo -e "${gl_huang}提示: ${gl_bai}该功能需要root用户才能运行！"
    break_end
    return 1
  fi
}

check_crontab_installed() {
  if command -v crontab >/dev/null 2>&1; then
    return 0
  fi

  if command -v apt >/dev/null 2>&1; then
    apt update -y
    apt install -y cron
    systemctl enable --now cron 2>/dev/null || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y cronie
    systemctl enable --now crond 2>/dev/null || true
  elif command -v yum >/dev/null 2>&1; then
    yum install -y cronie
    systemctl enable --now crond 2>/dev/null || true
  elif command -v apk >/dev/null 2>&1; then
    apk add dcron
    rc-service dcron start 2>/dev/null || true
    rc-update add dcron default 2>/dev/null || true
  else
    echo "未检测到可用包管理器，无法安装 crontab。"
    return 1
  fi
}

prefer_ipv4() {
  grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
  echo "已切换为 IPv4 优先"
  send_stats "已切换为 IPv4 优先"
}

restart_ssh() {
  systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null || service sshd restart 2>/dev/null || true
}

save_iptables_rules() {
  mkdir -p /etc/iptables
  touch /etc/iptables/rules.v4
  iptables-save > /etc/iptables/rules.v4
  check_crontab_installed || return 1
  crontab -l 2>/dev/null | grep -v 'iptables-restore' | crontab - >/dev/null 2>&1 || true
  { crontab -l 2>/dev/null; echo '@reboot iptables-restore < /etc/iptables/rules.v4'; } | crontab - >/dev/null 2>&1
}

iptables_open() {
  install iptables
  save_iptables_rules || true

  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -F

  if command -v ip6tables >/dev/null 2>&1; then
    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -F
  fi
}

fix_dpkg() {
  pkill -9 -f 'apt|dpkg' >/dev/null 2>&1 || true
  rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
  DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}

open_port() {
  local ports=("$@")
  [[ ${#ports[@]} -gt 0 ]] || { echo "请提供至少一个端口号"; return 1; }

  install iptables

  for port in "${ports[@]}"; do
    iptables -D INPUT -p tcp --dport "$port" -j DROP >/dev/null 2>&1 || true
    iptables -D INPUT -p udp --dport "$port" -j DROP >/dev/null 2>&1 || true

    if ! iptables -C INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1; then
      iptables -I INPUT 1 -p tcp --dport "$port" -j ACCEPT
    fi
    if ! iptables -C INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1; then
      iptables -I INPUT 1 -p udp --dport "$port" -j ACCEPT
    fi
  done

  save_iptables_rules || true
  send_stats "已打开端口"
}

close_port() {
  local ports=("$@")
  [[ ${#ports[@]} -gt 0 ]] || { echo "请提供至少一个端口号"; return 1; }

  install iptables

  for port in "${ports[@]}"; do
    iptables -D INPUT -p tcp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true
    iptables -D INPUT -p udp --dport "$port" -j ACCEPT >/dev/null 2>&1 || true

    if ! iptables -C INPUT -p tcp --dport "$port" -j DROP >/dev/null 2>&1; then
      iptables -I INPUT 1 -p tcp --dport "$port" -j DROP
    fi
    if ! iptables -C INPUT -p udp --dport "$port" -j DROP >/dev/null 2>&1; then
      iptables -I INPUT 1 -p udp --dport "$port" -j DROP
    fi
  done

  iptables -D INPUT -i lo -j ACCEPT >/dev/null 2>&1 || true
  iptables -D FORWARD -i lo -j ACCEPT >/dev/null 2>&1 || true
  iptables -I INPUT 1 -i lo -j ACCEPT
  iptables -I FORWARD 1 -i lo -j ACCEPT

  save_iptables_rules || true
  send_stats "已关闭端口"
}

correct_ssh_config() {
  local sshd_config="/etc/ssh/sshd_config"

  if grep -Eq "^\s*PasswordAuthentication\s+no" "$sshd_config"; then
    sed -i \
      -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
      -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
      -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
      -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' \
      "$sshd_config"
  else
    sed -i \
      -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin yes/' \
      -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication yes/' \
      -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
      "$sshd_config"
  fi

  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/* 2>/dev/null || true
}

new_ssh_port() {
  local new_port="$1"

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
  sed -i '/^\s*#\?\s*Port\s\+/d' /etc/ssh/sshd_config
  echo "Port $new_port" >> /etc/ssh/sshd_config

  correct_ssh_config
  restart_ssh
  open_port "$new_port"
  remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1 || true

  echo "SSH 端口已修改为: $new_port"
  sleep 1
}

add_swap() {
  local new_swap="$1"
  local swap_partitions
  swap_partitions="$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')"

  for partition in $swap_partitions; do
    swapoff "$partition" >/dev/null 2>&1 || true
    wipefs -a "$partition" >/dev/null 2>&1 || true
    mkswap -f "$partition" >/dev/null 2>&1 || true
  done

  swapoff /swapfile >/dev/null 2>&1 || true
  rm -f /swapfile

  fallocate -l "${new_swap}M" /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile

  sed -i '/\/swapfile/d' /etc/fstab
  echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

  if [[ -f /etc/alpine-release ]]; then
    mkdir -p /etc/local.d
    echo "nohup swapon /swapfile" > /etc/local.d/swap.start
    chmod +x /etc/local.d/swap.start
    rc-update add local >/dev/null 2>&1 || true
  fi

  echo -e "虚拟内存大小已调整为${gl_huang}${new_swap}${gl_bai}M"
}

luopo_system_tools_ip_address() {
  local public_ip isp_info
  public_ip="$(curl -s --max-time 3 https://ipinfo.io/ip && echo)"
  isp_info="$(curl -s --max-time 3 http://ipinfo.io/org)"

  if echo "$isp_info" | grep -Eiq 'CHINANET|mobile|unicom|telecom'; then
    ipv4_address="$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || hostname -I 2>/dev/null | awk '{print $1}')"
  else
    ipv4_address="$public_ip"
  fi
}

sshkey_on() {
  sed -i \
    -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
    -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
    -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
    -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' \
    /etc/ssh/sshd_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/* 2>/dev/null || true
  restart_ssh
  echo -e "${gl_lv}用户密钥登录模式已开启，已关闭密码登录模式，重连将会生效${gl_bai}"
}

add_sshkey() {
  chmod 700 "$HOME"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  touch "$HOME/.ssh/authorized_keys"

  ssh-keygen -t ed25519 -C "luopo@toolkit" -f "$HOME/.ssh/sshkey" -N ""
  cat "$HOME/.ssh/sshkey.pub" >> "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"

  luopo_system_tools_ip_address
  echo -e "私钥信息已生成，务必复制保存，可保存成 ${gl_huang}${ipv4_address:-server}_ssh.key${gl_bai} 文件，用于后续 SSH 登录"
  echo "--------------------------------"
  cat "$HOME/.ssh/sshkey"
  echo "--------------------------------"

  sshkey_on
}

import_sshkey() {
  local public_key="${1:-}"
  local base_dir="${2:-$HOME}"
  local ssh_dir="${base_dir}/.ssh"
  local auth_keys="${ssh_dir}/authorized_keys"

  if [[ -z "$public_key" ]]; then
    read -r -p "请输入您的SSH公钥内容（通常以 'ssh-rsa' 或 'ssh-ed25519' 开头）: " public_key
  fi

  [[ -n "$public_key" ]] || { echo "错误：未输入公钥内容。"; return 1; }
  [[ "$public_key" =~ ^ssh-(rsa|ed25519|ecdsa) ]] || { echo "错误：看起来不像合法的 SSH 公钥。"; return 1; }

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
  touch "$auth_keys"
  if grep -Fxq "$public_key" "$auth_keys" 2>/dev/null; then
    echo "该公钥已存在，无需重复添加"
    return 0
  fi

  echo "$public_key" >> "$auth_keys"
  chmod 600 "$auth_keys"
  sshkey_on
}

fetch_remote_ssh_keys() {
  local keys_url="${1:-}"
  local base_dir="${2:-$HOME}"
  local ssh_dir="${base_dir}/.ssh"
  local authorized_keys="${ssh_dir}/authorized_keys"
  local temp_file added

  if [[ -z "$keys_url" ]]; then
    read -r -p "请输入您的远端公钥URL： " keys_url
  fi

  temp_file="$(mktemp)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --connect-timeout 10 "$keys_url" -o "$temp_file" || { rm -f "$temp_file"; echo "错误：无法从 URL 下载公钥"; return 1; }
  elif command -v wget >/dev/null 2>&1; then
    wget -q --timeout=10 -O "$temp_file" "$keys_url" || { rm -f "$temp_file"; echo "错误：无法从 URL 下载公钥"; return 1; }
  else
    rm -f "$temp_file"
    echo "错误：系统中未找到 curl 或 wget，无法下载公钥"
    return 1
  fi

  [[ -s "$temp_file" ]] || { rm -f "$temp_file"; echo "错误：下载到的文件为空"; return 1; }

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
  touch "$authorized_keys"
  chmod 600 "$authorized_keys"
  cp "$authorized_keys" "${authorized_keys}.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

  added=0
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    [[ "$line" =~ ^ssh-(rsa|ed25519|ecdsa) ]] || continue
    if ! grep -Fxq "$line" "$authorized_keys" 2>/dev/null; then
      echo "$line" >> "$authorized_keys"
      added=$((added + 1))
    fi
  done < "$temp_file"
  rm -f "$temp_file"

  if (( added > 0 )); then
    echo "成功添加 ${added} 条新的公钥到 ${authorized_keys}"
    sshkey_on
  else
    echo "没有新的公钥需要添加（可能已全部存在）"
  fi
}

fetch_github_ssh_keys() {
  local username="${1:-}"
  local base_dir="${2:-$HOME}"
  [[ -n "$username" ]] || read -r -p "请输入您的 GitHub 用户名（username，不含 @）： " username
  [[ -n "$username" ]] || { echo "错误：GitHub 用户名不能为空"; return 1; }
  fetch_remote_ssh_keys "https://github.com/${username}.keys" "$base_dir"
}

create_user_with_sshkey() {
  local new_username="$1"
  local is_sudo="${2:-false}"
  local sshkey_vl

  [[ -n "$new_username" ]] || { echo "用法：create_user_with_sshkey <用户名>"; return 1; }
  id "$new_username" >/dev/null 2>&1 && { echo "用户 $new_username 已存在"; return 1; }

  useradd -m -s /bin/bash "$new_username" || return 1

  echo "导入公钥范例："
  echo "  - URL：      https://github.com/torvalds.keys"
  echo "  - GitHub：   github:torvalds"
  echo "  - 直接粘贴： ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
  read -r -p "请导入 ${new_username} 的公钥: " sshkey_vl

  case "$sshkey_vl" in
    http://*|https://*)
      send_stats "从 URL 导入 SSH 公钥"
      fetch_remote_ssh_keys "$sshkey_vl" "/home/$new_username"
      ;;
    github:*)
      send_stats "从 GitHub 导入 SSH 公钥"
      fetch_github_ssh_keys "${sshkey_vl#github:}" "/home/$new_username"
      ;;
    ssh-rsa*|ssh-ed25519*|ssh-ecdsa*)
      send_stats "公钥直接导入"
      import_sshkey "$sshkey_vl" "/home/$new_username"
      ;;
    *)
      echo "错误：未知参数 '$sshkey_vl'"
      userdel -r "$new_username" >/dev/null 2>&1 || true
      return 1
      ;;
  esac

  chown -R "$new_username:$new_username" "/home/$new_username/.ssh" 2>/dev/null || true
  install sudo
  if [[ "$is_sudo" == "true" ]]; then
    cat > "/etc/sudoers.d/$new_username" <<EOF
$new_username ALL=(ALL) NOPASSWD:ALL
EOF
    chmod 440 "/etc/sudoers.d/$new_username"
  fi

  sed -i '/^\s*#\?\s*UsePAM\s\+/d' /etc/ssh/sshd_config
  echo 'UsePAM yes' >> /etc/ssh/sshd_config
  passwd -l "$new_username" >/dev/null 2>&1 || true
  restart_ssh
  echo "用户 $new_username 创建完成"
}

current_timezone() {
  if grep -q 'Alpine' /etc/issue 2>/dev/null; then
    date +"%Z %z"
  elif command -v timedatectl >/dev/null 2>&1; then
    timedatectl | awk '/Time zone/ {print $3}'
  elif [[ -f /etc/timezone ]]; then
    cat /etc/timezone
  else
    echo "UTC"
  fi
}

set_timedate() {
  local shiqu="$1"
  if grep -q 'Alpine' /etc/issue 2>/dev/null; then
    install tzdata
    cp "/usr/share/zoneinfo/${shiqu}" /etc/localtime
    hwclock --systohc 2>/dev/null || true
  elif command -v timedatectl >/dev/null 2>&1; then
    timedatectl set-timezone "${shiqu}"
  else
    ln -sf "/usr/share/zoneinfo/${shiqu}" /etc/localtime
    echo "${shiqu}" > /etc/timezone
  fi
}

luopo_system_tools_write_dns() {
  local dns1_ipv4="$1"
  local dns2_ipv4="$2"
  local dns1_ipv6="${3:-}"
  local dns2_ipv6="${4:-}"
  local resolv_conf="/etc/resolv.conf"

  cp -f "$resolv_conf" "${resolv_conf}.bak.$(date +%s)" 2>/dev/null || true
  {
    echo "nameserver $dns1_ipv4"
    echo "nameserver $dns2_ipv4"
    [[ -n "$dns1_ipv6" ]] && echo "nameserver $dns1_ipv6"
    [[ -n "$dns2_ipv6" ]] && echo "nameserver $dns2_ipv6"
  } > "$resolv_conf"
}

auto_optimize_dns() {
  local country dns1_ipv4 dns2_ipv4 dns1_ipv6 dns2_ipv6
  country="$(curl -s --max-time 5 ipinfo.io/country | tr -d '\r\n')"

  if [[ "$country" == "CN" ]]; then
    dns1_ipv4="223.5.5.5"
    dns2_ipv4="183.60.83.19"
    dns1_ipv6="2400:3200::1"
    dns2_ipv6="2400:da00::6666"
  else
    dns1_ipv4="1.1.1.1"
    dns2_ipv4="8.8.8.8"
    dns1_ipv6="2606:4700:4700::1111"
    dns2_ipv6="2001:4860:4860::8888"
  fi

  luopo_system_tools_write_dns "$dns1_ipv4" "$dns2_ipv4" "$dns1_ipv6" "$dns2_ipv6"
  echo "DNS 已优化为: $dns1_ipv4 $dns2_ipv4 ${dns1_ipv6:-} ${dns2_ipv6:-}"
  send_stats "DNS 已自动优化"
}

linux_update() {
  echo -e "${gl_kjlan}正在系统更新...${gl_bai}"
  if command -v dnf >/dev/null 2>&1; then
    dnf -y update
  elif command -v yum >/dev/null 2>&1; then
    yum -y update
  elif command -v apt >/dev/null 2>&1; then
    fix_dpkg
    DEBIAN_FRONTEND=noninteractive apt update -y
    DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
  elif command -v apk >/dev/null 2>&1; then
    apk update && apk upgrade
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Syu --noconfirm
  elif command -v zypper >/dev/null 2>&1; then
    zypper refresh
    zypper update -y
  elif command -v opkg >/dev/null 2>&1; then
    opkg update
  else
    echo "未知的包管理器!"
  fi
}

linux_clean() {
  echo -e "${gl_kjlan}正在系统清理...${gl_bai}"
  if command -v dnf >/dev/null 2>&1; then
    rpm --rebuilddb
    dnf autoremove -y
    dnf clean all
    dnf makecache
  elif command -v yum >/dev/null 2>&1; then
    rpm --rebuilddb
    yum autoremove -y
    yum clean all
    yum makecache
  elif command -v apt >/dev/null 2>&1; then
    fix_dpkg
    apt autoremove --purge -y
    apt clean -y
    apt autoclean -y
  elif command -v apk >/dev/null 2>&1; then
    apk cache clean
    rm -rf /var/log/* /var/cache/apk/* /tmp/* /var/tmp/* 2>/dev/null || true
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Sc --noconfirm
  elif command -v zypper >/dev/null 2>&1; then
    zypper clean --all
  fi

  journalctl --rotate >/dev/null 2>&1 || true
  journalctl --vacuum-time=1s >/dev/null 2>&1 || true
  journalctl --vacuum-size=500M >/dev/null 2>&1 || true
}

f2b_status() {
  fail2ban-client reload >/dev/null 2>&1 || true
  sleep 1
  fail2ban-client status
}

f2b_install_sshd() {
  docker rm -f fail2ban >/dev/null 2>&1 || true
  install fail2ban
  systemctl enable --now fail2ban 2>/dev/null || service fail2ban start 2>/dev/null || true

  if command -v dnf >/dev/null 2>&1; then
    mkdir -p /etc/fail2ban/jail.d/
    curl -sS -o /etc/fail2ban/jail.d/centos-ssh.conf "${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/centos-ssh.conf"
  fi

  if command -v apt >/dev/null 2>&1; then
    install rsyslog
    systemctl enable --now rsyslog 2>/dev/null || service rsyslog start 2>/dev/null || true
  fi
}

luopo_system_tools_fail2ban_status_label() {
  if command -v fail2ban-client >/dev/null 2>&1 && fail2ban-client ping >/dev/null 2>&1; then
    printf '%b已安装%b' "$gl_lv" "$gl_bai"
  else
    printf '%b未安装%b' "$gl_hui" "$gl_bai"
  fi
}

k_info() {
  send_stats "z命令参考用例"
  echo "-------------------"
  echo "视频介绍: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
  echo "以下是 z 命令参考用例："
  echo "启动脚本            z"
  echo "安装软件包          z install nano wget | z add nano wget | z 安装 nano wget"
  echo "卸载软件包          z remove nano wget | z del nano wget | z uninstall nano wget | z 卸载 nano wget"
  echo "更新系统            z update | z 更新"
  echo "清理系统垃圾        z clean | z 清理"
  echo "重装系统面板        z dd | z 重装"
  echo "bbr3控制面板        z bbr3 | z bbrv3"
  echo "内核调优面板        z nhyh | z 内核优化"
  echo "设置虚拟内存        z swap 2048"
  echo "设置虚拟时区        z time Asia/Shanghai | z 时区 Asia/Shanghai"
  echo "系统回收站          z trash | z hsz | z 回收站"
  echo "系统备份功能        z backup | z bf | z 备份"
  echo "ssh远程连接工具     z ssh | z 远程连接"
  echo "rsync远程同步工具   z rsync | z 远程同步"
  echo "硬盘管理工具        z disk | z 硬盘管理"
  echo "内网穿透（服务端）  z frps"
  echo "内网穿透（客户端）  z frpc"
  echo "软件启动            z start sshd | z 启动 sshd"
  echo "软件停止            z stop sshd | z 停止 sshd"
  echo "软件重启            z restart sshd | z 重启 sshd"
  echo "软件状态查看        z status sshd | z 状态 sshd"
  echo "软件开机启动        z enable docker | z autostart docker | z 开机启动 docker"
  echo "域名证书申请        z ssl"
  echo "域名证书到期查询    z ssl ps"
  echo "docker管理平面      z docker"
  echo "docker环境安装      z docker install | z docker 安装"
  echo "docker容器管理      z docker ps | z docker 容器"
  echo "docker镜像管理      z docker img | z docker 镜像"
  echo "LDNMP站点管理       z web"
  echo "LDNMP缓存清理       z web cache"
}

luopo_system_tools_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_SYSTEM_TOOLS_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_system_tools_item_label() {
  local item="$1"
  IFS='|' read -r _ label <<<"$item"
  printf '%s\n' "$label"
}

luopo_system_tools_render_cell() {
  local key="$1"
  local item label
  item="$(luopo_system_tools_find_item "$key")" || return 1
  label="$(luopo_system_tools_item_label "$item")"
  printf "%b%-4s %b%s%b" "$gl_kjlan" "${key}." "$gl_bai" "$label" "$gl_bai"
}

luopo_system_tools_invalid_choice() {
  echo "无效的输入!"
  press_enter
}

luopo_system_tools_current_swap_info() {
  free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}'
}

luopo_system_tools_print_generated_credentials() {
  local i first_name_index last_name_index user_name password uuid username
  local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
  local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

  echo "随机用户名"
  echo "------------------------"
  for i in {1..5}; do
    username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
    echo "随机用户名 $i: $username"
  done

  echo
  echo "随机姓名"
  echo "------------------------"
  for i in {1..5}; do
    first_name_index=$((RANDOM % ${#first_names[@]}))
    last_name_index=$((RANDOM % ${#last_names[@]}))
    user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
    echo "随机用户姓名 $i: $user_name"
  done

  echo
  echo "随机UUID"
  echo "------------------------"
  for i in {1..5}; do
    uuid="$(cat /proc/sys/kernel/random/uuid)"
    echo "随机UUID $i: $uuid"
  done

  echo
  echo "16位随机密码"
  echo "------------------------"
  for i in {1..5}; do
    password="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)"
    echo "随机密码 $i: $password"
  done
}

luopo_system_tools_print_user_table() {
  echo "用户列表"
  echo "----------------------------------------------------------------------------"
  printf "%-24s %-34s %-20s %-10s\n" "用户名" "主目录" "用户组" "sudo权限"
  while IFS=: read -r username _ _ _ _ _ homedir _; do
    local groups sudo_status
    groups="$(groups "$username" 2>/dev/null | cut -d : -f 2 | xargs)"
    if sudo -n -lU "$username" 2>/dev/null | grep -q "(ALL) \(NOPASSWD: \)\?ALL"; then
      sudo_status="Yes"
    else
      sudo_status="No"
    fi
    printf "%-24s %-34s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
  done < /etc/passwd
}

