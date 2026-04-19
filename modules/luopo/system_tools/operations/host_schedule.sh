#!/usr/bin/env bash
set -euo pipefail

# Hostname, crontab, and hosts-file operations.

luopo_system_tools_change_hostname_menu() {
  root_use
  while true; do
    clear
    echo "当前主机名: $(hostname)"
    echo "------------------------"
    echo "1. 修改主机名"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "请输入新的主机名: " new_hostname
        [[ -n "$new_hostname" ]] || { echo "主机名不能为空"; press_enter; continue; }
        if command -v hostnamectl >/dev/null 2>&1; then
          hostnamectl set-hostname "$new_hostname"
        else
          hostname "$new_hostname"
          echo "$new_hostname" > /etc/hostname
        fi
        if grep -q '^127\.0\.1\.1' /etc/hosts 2>/dev/null; then
          sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $new_hostname/" /etc/hosts
        else
          echo "127.0.1.1 $new_hostname" >> /etc/hosts
        fi
        echo "主机名已更新为: $new_hostname"
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_crontab_menu() {
  root_use
  check_crontab_installed
  while true; do
    clear
    echo "当前定时任务列表"
    echo "------------------------"
    crontab -l 2>/dev/null || echo "暂无定时任务"
    echo "------------------------"
    echo "1. 添加每月任务"
    echo "2. 添加每周任务"
    echo "3. 添加每日任务"
    echo "4. 添加每小时任务"
    echo "5. 删除含关键字的任务"
    echo "6. 编辑当前任务"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "请输入日期 (1-31): " cron_day
        read -r -p "请输入时间 (HH:MM): " cron_time
        read -r -p "请输入任务命令: " cron_command
        IFS=: read -r cron_hour cron_minute <<<"$cron_time"
        (crontab -l 2>/dev/null; echo "$cron_minute $cron_hour $cron_day * * $cron_command") | crontab -
        ;;
      2)
        read -r -p "请输入星期几 (0-6, 0=周日): " cron_weekday
        read -r -p "请输入时间 (HH:MM): " cron_time
        read -r -p "请输入任务命令: " cron_command
        IFS=: read -r cron_hour cron_minute <<<"$cron_time"
        (crontab -l 2>/dev/null; echo "$cron_minute $cron_hour * * $cron_weekday $cron_command") | crontab -
        ;;
      3)
        read -r -p "请输入时间 (HH:MM): " cron_time
        read -r -p "请输入任务命令: " cron_command
        IFS=: read -r cron_hour cron_minute <<<"$cron_time"
        (crontab -l 2>/dev/null; echo "$cron_minute $cron_hour * * * $cron_command") | crontab -
        ;;
      4)
        read -r -p "请输入分钟 (0-59): " cron_minute
        read -r -p "请输入任务命令: " cron_command
        (crontab -l 2>/dev/null; echo "$cron_minute * * * * $cron_command") | crontab -
        ;;
      5)
        read -r -p "请输入要删除任务的关键字: " cron_keyword
        [[ -n "$cron_keyword" ]] || { echo "关键字不能为空"; press_enter; continue; }
        crontab -l 2>/dev/null | grep -v "$cron_keyword" | crontab -
        echo "已删除包含关键字的定时任务"
        ;;
      6)
        crontab -e
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}

luopo_system_tools_hosts_menu() {
  root_use
  while true; do
    clear
    echo "本机 host 解析列表"
    echo "如果你在这里添加解析匹配，将不再使用动态解析了"
    cat /etc/hosts
    echo
    echo "操作"
    echo "------------------------"
    echo "1. 添加新的解析"
    echo "2. 删除解析地址"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "请输入你的选择: " sub_choice
    case "$sub_choice" in
      1)
        read -r -p "请输入新的解析记录，格式: 110.25.5.33 example.com : " addhost
        [[ -n "$addhost" ]] || { echo "解析记录不能为空"; press_enter; continue; }
        echo "$addhost" >> /etc/hosts
        send_stats "本地host解析新增"
        echo "已添加解析记录"
        ;;
      2)
        read -r -p "请输入要删除的关键字或域名: " delhost
        [[ -n "$delhost" ]] || { echo "删除关键字不能为空"; press_enter; continue; }
        sed -i "/$delhost/d" /etc/hosts
        send_stats "本地host解析删除"
        echo "已删除匹配记录"
        ;;
      0)
        return 0
        ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}
