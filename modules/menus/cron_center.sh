#!/usr/bin/env bash
set -euo pipefail

cron_center_menu() {
  local choice keyword
  while true; do
    clear
    echo "========================================"
    echo "定时任务中心"
    echo "========================================"
    menu_item "1" "查看当前任务"
    menu_item "2" "编辑任务 (crontab -e)"
    menu_item "3" "清空当前用户任务"
    menu_item "4" "备份当前任务"
    echo "------------------------"
    menu_item "21" "快速添加每日自动更新任务"
    menu_item "22" "按关键字删除任务"
    menu_item "23" "添加每日备份任务模板"
    menu_item "24" "添加每小时健康检查模板"
    echo "------------------------"
    menu_item "31" "查看系统级定时任务(/etc/crontab)"
    menu_item "32" "查看近期 cron 日志"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1) crontab -l 2>/dev/null || say_warn "暂无任务"; menu_wait ;;
      2) crontab -e ;;
      3)
        if confirm_or_cancel "确认清空当前用户的 crontab？(y/N): "; then
          if run_logged "cron_center:clear_crontab" crontab -r; then
            say_ok "已清空"
          else
            say_err "清空失败"
          fi
        fi
        menu_wait
        ;;
      4)
        crontab -l >"/root/crontab-backup-$(date +%Y%m%d-%H%M%S).txt" 2>/dev/null && say_ok "已备份到 /root" || say_warn "暂无任务"
        menu_wait
        ;;
      21)
        if (crontab -l 2>/dev/null; echo "30 4 * * * apt-get update -y && apt-get upgrade -y >> /var/log/cron-auto-update.log 2>&1") | crontab -; then
          say_ok "已添加每日 04:30 自动更新任务"
        else
          say_action_failed "添加自动更新任务" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      22)
        read -r -p "输入关键字: " keyword
        if [[ -z "$keyword" ]]; then
          say_warn "关键字不能为空"
          menu_wait
          continue
        fi
        if crontab -l 2>/dev/null | grep -v "$keyword" | crontab -; then
          say_ok "已删除包含关键字 [$keyword] 的任务"
        else
          say_action_failed "按关键字删除任务" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      23)
        read -r -p "输入备份命令(如 /root/backup.sh): " backup_cmd
        if [[ -z "$backup_cmd" ]]; then
          say_warn "备份命令不能为空"
          menu_wait
          continue
        fi
        if (crontab -l 2>/dev/null; echo "0 3 * * * ${backup_cmd} >> /var/log/cron-backup.log 2>&1") | crontab -; then
          say_ok "已添加每日 03:00 备份任务"
        else
          say_action_failed "添加备份任务" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      24)
        if (crontab -l 2>/dev/null; echo "0 * * * * uptime >> /var/log/cron-health.log 2>&1") | crontab -; then
          say_ok "已添加每小时健康检查任务"
        else
          say_action_failed "添加健康检查任务" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      31) cat /etc/crontab 2>/dev/null || say_warn "/etc/crontab 不存在"; menu_wait ;;
      32) grep -i CRON /var/log/syslog 2>/dev/null | tail -n 100 || journalctl -u cron -n 100 --no-pager 2>/dev/null || true; menu_wait ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

