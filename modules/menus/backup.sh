#!/usr/bin/env bash
set -euo pipefail

backup_menu() {
  local choice src_dir backup_file
  while true; do
    clear
    echo "========================================"
    echo "备份/恢复/迁移"
    echo "========================================"
    menu_item "1" "目录打包备份"
    menu_item "2" "从 tar.gz 恢复目录"
    menu_item "3" "远程迁移（rsync）"
    menu_item "4" "列出 /root 下备份包"
    echo "------------------------"
    menu_item "21" "备份 /etc 配置"
    menu_item "22" "数据库备份 (mysqldump)"
    menu_item "23" "数据库恢复 (mysql < sql)"
    menu_item "24" "查看最近备份日志"
    echo "------------------------"
    menu_item "31" "压缩并加密备份包(gpg)"
    menu_item "32" "解密备份包(gpg)"
    echo "----------------------------------------"
    menu_item "0" "返回上级菜单"
    echo "========================================"
    read_menu_choice choice
    case "$choice" in
      1)
        read -r -p "输入要备份的目录: " src_dir
        if [[ -d "$src_dir" ]]; then
          tar -czf "/root/backup-$(date +%Y%m%d-%H%M%S).tar.gz" -C "$(dirname "$src_dir")" "$(basename "$src_dir")"
          say_ok "备份完成，输出目录: /root"
        else
          say_warn "目录不存在"
        fi
        menu_wait
        ;;
      2)
        read -r -p "输入备份文件路径(.tar.gz): " backup_file
        if [[ -f "$backup_file" ]]; then
          read -r -p "输入恢复目标目录(默认 /): " restore_to
          restore_to="${restore_to:-/}"
          tar -xzf "$backup_file" -C "$restore_to"
          say_ok "恢复完成"
        else
          say_warn "备份文件不存在"
        fi
        menu_wait
        ;;
      3)
        if ! apt_install rsync; then
          say_action_failed "rsync 安装" "$(i18n_get msg_reason_install_failed 'install failed')"
          menu_wait
          continue
        fi
        read -r -p "输入源目录: " src
        read -r -p "输入目标 (user@host:/path): " dst
        if rsync -avz "$src" "$dst"; then
          say_ok "远程迁移完成"
        else
          say_action_failed "远程迁移" "$(i18n_get msg_reason_exec_failed 'execution failed')"
        fi
        menu_wait
        ;;
      4) ls -lh /root/backup-*.tar.gz 2>/dev/null || say_warn "暂无备份包"; menu_wait ;;
      21)
        tar -czf "/root/etc-backup-$(date +%Y%m%d-%H%M%S).tar.gz" /etc
        say_ok "已备份 /etc 到 /root"
        menu_wait
        ;;
      22)
        if command -v mysqldump >/dev/null 2>&1; then
          read -r -p "输入数据库名: " db
          read -r -p "输入数据库用户名: " dbu
          read -r -s -p "输入数据库密码: " dbp
          echo ""
          mysqldump -u"$dbu" -p"$dbp" "$db" >"/root/${db}-$(date +%Y%m%d-%H%M%S).sql" && say_ok "备份完成"
        else
          say_warn "未安装 mysqldump"
        fi
        menu_wait
        ;;
      23)
        read -r -p "输入 SQL 文件路径: " sql_file
        read -r -p "输入数据库用户名: " dbu
        read -r -s -p "输入数据库密码: " dbp
        echo ""
        [[ -f "$sql_file" ]] && mysql -u"$dbu" -p"$dbp" <"$sql_file" && say_ok "恢复完成" || say_warn "SQL 文件不存在或恢复失败"
        menu_wait
        ;;
      24) ls -lt /root/*backup* 2>/dev/null | head -n 20 || say_warn "暂无备份日志"; menu_wait ;;
      31)
        try_install_pkg gnupg
        read -r -p "输入要加密的备份文件路径: " backup_file
        if [[ -f "$backup_file" ]]; then
          gpg -c "$backup_file" && say_ok "已加密: ${backup_file}.gpg"
        else
          say_warn "文件不存在"
        fi
        menu_wait
        ;;
      32)
        try_install_pkg gnupg
        read -r -p "输入 .gpg 文件路径: " backup_file
        if [[ -f "$backup_file" ]]; then
          gpg -d "$backup_file" >"${backup_file%.gpg}" && say_ok "已解密到: ${backup_file%.gpg}"
        else
          say_warn "文件不存在"
        fi
        menu_wait
        ;;
      0) return 0 ;;
      *) menu_invalid ;;
    esac
  done
}

