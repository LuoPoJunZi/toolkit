#!/usr/bin/env bash
set -euo pipefail

LUOPO_BASIC_TOOLS_SECTIONS=(
  "core|基础工具"
  "advanced|进阶工具"
  "fun|屏保和游戏"
  "batch|批量操作"
  "custom|自定义操作"
)

LUOPO_BASIC_TOOLS_ITEMS=(
  "1|curl 下载工具|luopo_basic_tools_install_curl|core"
  "2|wget 下载工具|luopo_basic_tools_install_wget|core"
  "3|sudo 超级管理权限工具|luopo_basic_tools_install_sudo|core"
  "4|socat 通信连接工具|luopo_basic_tools_install_socat|core"
  "5|htop 系统监控工具|luopo_basic_tools_install_htop|core"
  "6|iftop 网络流量监控工具|luopo_basic_tools_install_iftop|core"
  "7|unzip ZIP压缩解压工具|luopo_basic_tools_install_unzip|core"
  "8|tar GZ压缩解压工具|luopo_basic_tools_install_tar|core"
  "9|tmux 多路后台运行工具|luopo_basic_tools_install_tmux|core"
  "10|ffmpeg 视频编码直播推流工具|luopo_basic_tools_install_ffmpeg|core"
  "11|btop 现代化监控工具|luopo_basic_tools_install_btop|advanced"
  "12|ranger 文件管理工具|luopo_basic_tools_install_ranger|advanced"
  "13|ncdu 磁盘占用查看工具|luopo_basic_tools_install_ncdu|advanced"
  "14|fzf 全局搜索工具|luopo_basic_tools_install_fzf|advanced"
  "15|vim 文本编辑器|luopo_basic_tools_install_vim|advanced"
  "16|nano 文本编辑器|luopo_basic_tools_install_nano|advanced"
  "17|git 版本控制系统|luopo_basic_tools_install_git|advanced"
  "18|opencode AI编程助手|luopo_basic_tools_install_opencode|advanced"
  "21|黑客帝国屏保|luopo_basic_tools_install_cmatrix|fun"
  "22|跑火车屏保|luopo_basic_tools_install_sl|fun"
  "23|俄罗斯方块小游戏|luopo_basic_tools_install_bastet|fun"
  "24|贪吃蛇小游戏|luopo_basic_tools_install_nsnake|fun"
  "25|太空入侵者小游戏|luopo_basic_tools_install_ninvaders|fun"
  "31|全部安装|luopo_basic_tools_install_all|batch"
  "32|全部安装（不含屏保和游戏）|luopo_basic_tools_install_all_core|batch"
  "33|全部卸载|luopo_basic_tools_remove_all|batch"
  "41|安装指定工具|luopo_basic_tools_install_custom|custom"
  "42|卸载指定工具|luopo_basic_tools_remove_custom|custom"
)

luopo_basic_tools_find_item() {
  local choice="$1"
  local item
  for item in "${LUOPO_BASIC_TOOLS_ITEMS[@]}"; do
    IFS='|' read -r number _ <<<"$item"
    if [[ "$number" == "$choice" ]]; then
      printf '%s\n' "$item"
      return 0
    fi
  done
  return 1
}

luopo_basic_tools_item_number() {
  local item="$1"
  IFS='|' read -r number _ <<<"$item"
  printf '%s\n' "$number"
}

luopo_basic_tools_item_label() {
  local item="$1"
  IFS='|' read -r _ label _ <<<"$item"
  printf '%s\n' "$label"
}

luopo_basic_tools_item_handler() {
  local item="$1"
  IFS='|' read -r _ _ handler _ <<<"$item"
  printf '%s\n' "$handler"
}

luopo_basic_tools_item_group() {
  local item="$1"
  IFS='|' read -r _ _ _ group <<<"$item"
  printf '%s\n' "$group"
}
