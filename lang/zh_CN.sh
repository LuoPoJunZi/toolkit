#!/usr/bin/env bash
set -euo pipefail

declare -A I18N=(
  [title_main]="Toolkit VPS 一键脚本工具箱"
  [menu_1]="1. 系统信息查询"
  [menu_2]="2. 系统更新"
  [menu_3]="3. 系统清理"
  [menu_4]="4. 一键脚本"
  [menu_5]="5. Docker 管理"
  [menu_00]="00. 脚本更新"
  [menu_88]="88. 卸载脚本"
  [menu_0]="0. 退出脚本"
  [menu_label_1]="系统信息查询"
  [menu_label_2]="系统全面更新"
  [menu_label_3]="系统垃圾清理"
  [menu_label_4]="一键脚本"
  [menu_label_5]="Docker 管理"
  [menu_label_99]="更新脚本"
  [menu_label_88]="卸载脚本"
  [menu_label_0]="退出"
  [prompt_select]="请输入选择: "
  [prompt_press_enter]="按回车继续..."
  [prompt_confirm]="确认执行？(y/N): "
  [invalid]="无效选项"
  [bye]="已退出"
)
