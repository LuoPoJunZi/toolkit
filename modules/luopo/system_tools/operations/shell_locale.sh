#!/usr/bin/env bash
set -euo pipefail

# Shell prompt theme and locale operations.

luopo_system_tools_apply_shell_theme() {
  local ps1_line="$1"
  local target_file

  if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    target_file="$HOME/.bashrc"
  else
    target_file="$HOME/.profile"
  fi

  touch "$target_file"
  sed -i '/^PS1=/d' "$target_file"
  if [[ -n "$ps1_line" ]]; then
    printf '%s\n' "$ps1_line" >> "$target_file"
  fi

  echo -e "${gl_lv:-}变更完成。重新连接 SSH 后可查看变化！${gl_bai:-}"
  hash -r
}

luopo_system_tools_shell_theme_menu() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "请使用 root 权限运行此功能。"
    return 1
  fi

  send_stats "命令行美化工具"

  while true; do
    clear
    echo "命令行美化工具"
    echo "------------------------"
    echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai:-}#"
    echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai:-}#"
    echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai:-}#"
    echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai:-}#"
    echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai:-}#"
    echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai:-}#"
    echo "7. root localhost ~ #"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "输入你的选择: " choice

    local ps1_line=""
    case "$choice" in
      1) ps1_line="PS1='\\[\\033[1;32m\\]\\u\\[\\033[0m\\]@\\[\\033[1;34m\\]\\h\\[\\033[0m\\] \\[\\033[1;31m\\]\\w\\[\\033[0m\\] # '" ;;
      2) ps1_line="PS1='\\[\\033[1;35m\\]\\u\\[\\033[0m\\]@\\[\\033[1;36m\\]\\h\\[\\033[0m\\] \\[\\033[1;33m\\]\\w\\[\\033[0m\\] # '" ;;
      3) ps1_line="PS1='\\[\\033[1;31m\\]\\u\\[\\033[0m\\]@\\[\\033[1;32m\\]\\h\\[\\033[0m\\] \\[\\033[1;34m\\]\\w\\[\\033[0m\\] # '" ;;
      4) ps1_line="PS1='\\[\\033[1;36m\\]\\u\\[\\033[0m\\]@\\[\\033[1;33m\\]\\h\\[\\033[0m\\] \\[\\033[1;37m\\]\\w\\[\\033[0m\\] # '" ;;
      5) ps1_line="PS1='\\[\\033[1;37m\\]\\u\\[\\033[0m\\]@\\[\\033[1;31m\\]\\h\\[\\033[0m\\] \\[\\033[1;32m\\]\\w\\[\\033[0m\\] # '" ;;
      6) ps1_line="PS1='\\[\\033[1;33m\\]\\u\\[\\033[0m\\]@\\[\\033[1;34m\\]\\h\\[\\033[0m\\] \\[\\033[1;35m\\]\\w\\[\\033[0m\\] # '" ;;
      7) ps1_line="" ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac

    luopo_system_tools_apply_shell_theme "$ps1_line"
    break_end
  done
}

luopo_system_tools_apply_locale() {
  local locale_name="$1"
  local locale_label="$2"

  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "请使用 root 权限运行此功能。"
    return 1
  fi

  if command -v locale-gen >/dev/null 2>&1; then
    if [[ -f /etc/locale.gen ]] && ! grep -q "^${locale_name} UTF-8" /etc/locale.gen; then
      echo "${locale_name} UTF-8" >> /etc/locale.gen
    fi
    locale-gen "$locale_name" >/dev/null 2>&1 || locale-gen >/dev/null 2>&1 || true
  fi

  if command -v localectl >/dev/null 2>&1; then
    localectl set-locale "LANG=${locale_name}" 2>/dev/null || true
  fi

  if [[ -f /etc/default/locale || -d /etc/default ]]; then
    printf 'LANG=%s\nLC_ALL=%s\n' "$locale_name" "$locale_name" > /etc/default/locale
  fi

  if [[ -f /etc/locale.conf || -d /etc ]]; then
    printf 'LANG=%s\n' "$locale_name" > /etc/locale.conf
  fi

  export LANG="$locale_name"
  export LC_ALL="$locale_name"
  echo "已切换到${locale_label}。重新登录 SSH 后生效更完整。"
}

luopo_system_tools_language_menu() {
  send_stats "切换系统语言"

  while true; do
    clear
    echo "系统语言切换"
    echo "当前系统语言: ${LANG:-未知}"
    echo "------------------------"
    echo "1. 英文"
    echo "2. 简体中文"
    echo "3. 繁体中文"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -r -p "输入你的选择: " choice

    case "$choice" in
      1) luopo_system_tools_apply_locale "en_US.UTF-8" "英文" ;;
      2) luopo_system_tools_apply_locale "zh_CN.UTF-8" "简体中文" ;;
      3) luopo_system_tools_apply_locale "zh_TW.UTF-8" "繁体中文" ;;
      0) return 0 ;;
      *)
        luopo_system_tools_invalid_choice
        continue
        ;;
    esac
    break_end
  done
}
