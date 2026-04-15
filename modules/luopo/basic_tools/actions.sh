#!/usr/bin/env bash
set -euo pipefail

luopo_basic_tools_install_curl() { luopo_basic_tools_install_and_show "curl" "安装curl" 'echo "工具已安装，使用方法如下："; curl --help'; }
luopo_basic_tools_install_wget() { luopo_basic_tools_install_and_show "wget" "安装wget" 'echo "工具已安装，使用方法如下："; wget --help'; }
luopo_basic_tools_install_sudo() { luopo_basic_tools_install_and_show "sudo" "安装sudo" 'echo "工具已安装，使用方法如下："; sudo --help'; }
luopo_basic_tools_install_socat() { luopo_basic_tools_install_and_show "socat" "安装socat" 'echo "工具已安装，使用方法如下："; socat -h'; }
luopo_basic_tools_install_htop() { luopo_basic_tools_install_and_show "htop" "安装htop" 'htop'; }
luopo_basic_tools_install_iftop() { luopo_basic_tools_install_and_show "iftop" "安装iftop" 'iftop'; }
luopo_basic_tools_install_unzip() { luopo_basic_tools_install_and_show "unzip" "安装unzip" 'echo "工具已安装，使用方法如下："; unzip'; }
luopo_basic_tools_install_tar() { luopo_basic_tools_install_and_show "tar" "安装tar" 'echo "工具已安装，使用方法如下："; tar --help'; }
luopo_basic_tools_install_tmux() { luopo_basic_tools_install_and_show "tmux" "安装tmux" 'echo "工具已安装，使用方法如下："; tmux --help'; }
luopo_basic_tools_install_ffmpeg() { luopo_basic_tools_install_and_show "ffmpeg" "安装ffmpeg" 'echo "工具已安装，使用方法如下："; ffmpeg --help'; }
luopo_basic_tools_install_btop() { luopo_basic_tools_install_and_show "btop" "安装btop" 'btop'; }
luopo_basic_tools_install_ranger() { luopo_basic_tools_install_and_show "ranger" "安装ranger" 'cd /; ranger; cd ~'; }
luopo_basic_tools_install_ncdu() { luopo_basic_tools_install_and_show "ncdu" "安装ncdu" 'cd /; ncdu; cd ~'; }
luopo_basic_tools_install_fzf() { luopo_basic_tools_install_and_show "fzf" "安装fzf" 'cd /; fzf; cd ~'; }
luopo_basic_tools_install_vim() { luopo_basic_tools_install_and_show "vim" "安装vim" 'cd /; vim -h; cd ~'; }
luopo_basic_tools_install_nano() { luopo_basic_tools_install_and_show "nano" "安装nano" 'cd /; nano -h; cd ~'; }
luopo_basic_tools_install_git() { luopo_basic_tools_install_and_show "git" "安装git" 'cd /; git --help; cd ~'; }
luopo_basic_tools_install_cmatrix() { luopo_basic_tools_install_and_show "cmatrix" "安装cmatrix" 'cmatrix'; }
luopo_basic_tools_install_sl() { luopo_basic_tools_install_and_show "sl" "安装sl" 'sl'; }
luopo_basic_tools_install_bastet() { luopo_basic_tools_install_and_show "bastet" "安装bastet" 'bastet'; }
luopo_basic_tools_install_nsnake() { luopo_basic_tools_install_and_show "nsnake" "安装nsnake" 'nsnake'; }
luopo_basic_tools_install_ninvaders() { luopo_basic_tools_install_and_show "ninvaders" "安装ninvaders" 'ninvaders'; }

luopo_basic_tools_install_opencode() {
  luopo_basic_tools_run_shell "安装opencode" 'cd ~; curl -fsSL https://opencode.ai/install | bash; source ~/.bashrc 2>/dev/null || true; source ~/.profile 2>/dev/null || true; opencode'
}

luopo_basic_tools_install_all() {
  luopo_basic_tools_run_shell "全部安装" 'install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git'
}

luopo_basic_tools_install_all_core() {
  luopo_basic_tools_run_shell "全部安装（不含游戏和屏保）" 'install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git'
}

luopo_basic_tools_remove_all() {
  luopo_basic_tools_run_shell "全部卸载" 'remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git; opencode uninstall 2>/dev/null || true; rm -rf ~/.opencode'
}

luopo_basic_tools_install_custom() {
  read -r -p "请输入安装的工具名（wget curl sudo htop）: " installname
  if [[ -z "${installname:-}" ]]; then
    echo "未输入工具名"
    luopo_basic_tools_finish
    return 0
  fi
  luopo_basic_tools_run_shell "安装指定软件" "install \"$installname\""
}

luopo_basic_tools_remove_custom() {
  read -r -p "请输入卸载的工具名（htop ufw tmux cmatrix）: " removename
  if [[ -z "${removename:-}" ]]; then
    echo "未输入工具名"
    luopo_basic_tools_finish
    return 0
  fi
  luopo_basic_tools_run_shell "卸载指定软件" "remove \"$removename\""
}
