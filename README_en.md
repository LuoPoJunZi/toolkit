<h1 align="center">⚙️ LuoPo VPS Toolkit</h1>
<div align="center">

A terminal toolkit for VPS beginners.<br>
Goal: **ready to use after install, clean menus, and low-friction daily operations**.

[![Language](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-0A66C2?style=flat-square)](#)
[![Version](https://img.shields.io/github/v/release/LuoPoJunZi/toolkit?display_name=tag&style=flat-square&label=Version)](https://github.com/LuoPoJunZi/toolkit/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

<br>

[![简体中文](https://img.shields.io/badge/简体中文-2f4858?style=for-the-badge)](README.md)
[![ENGLISH](https://img.shields.io/badge/ENGLISH-2f4858?style=for-the-badge)](README_en.md)
[![繁體中文](https://img.shields.io/badge/繁體中文-455a64?style=for-the-badge)](README_zh-TW.md)
[![日本語](https://img.shields.io/badge/日本語-455a64?style=for-the-badge)](README_ja.md)
[![한국어](https://img.shields.io/badge/한국어-455a64?style=for-the-badge)](README_ko.md)
[![РУССКИЙ](https://img.shields.io/badge/РУССКИЙ-455a64?style=for-the-badge)](README_ru.md)

</div>

---

## English Description

`LuoPo VPS Toolkit` is a minimalist VPS one-click toolbox for Linux beginners, supporting Ubuntu / Debian with system operations, Docker management, and curated script integrations.

> Simplified Chinese documentation: [README.md](README.md)
>
> Traditional Chinese: [README_zh-TW.md](README_zh-TW.md) | Japanese: [README_ja.md](README_ja.md) | Korean: [README_ko.md](README_ko.md) | Russian: [README_ru.md](README_ru.md)

## 1. What Is It? Who Is It For?

`LuoPo VPS Toolkit` is a pure Bash VPS menu toolkit focused on common high-frequency operations:

- System information query
- System update and cleanup
- One-click integration of excellent third-party scripts
- Docker management
- Toolkit update and uninstall

Best for:

- Beginner webmasters: fewer commands, more visual menus
- Ops users: quick execution of standard operations
- Script maintainers: easy extension on top of menu framework

---

## 2. Capability Overview

- Compact dual-column main menu layout
- Structured system info panel (resource/network/location)
- Grouped one-click script hub (LuoPo scripts / third-party scripts)
- Safe third-party execution chain: download + SHA256 verification
- Menu-based Docker common operations
- Update mechanism:
  - Git install: Git update + rollback on failure
  - Non-git install: auto switch to remote update
- One-click uninstall (`88`) with full cleanup

---

## 3. Quick Start

### 3.1 Install (Recommended)

```bash
bash <(curl -fsSL https://z.evzzz.com)
```

### 3.2 Fallback Install (GitHub Raw)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)
```

### 3.3 Launch Command

```bash
z
```

English UI:

```bash
z en
```

### 3.4 Quick Links

- Install via domain: `bash <(curl -fsSL https://z.evzzz.com)`
- Fallback install via GitHub: `bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)`
- Launch toolkit: `z`
- Launch in English: `z en`

---

## 4. Main Menu Preview

```text
========================================
LuoPo VPS Toolkit v0.1.2 (快捷启动: z)
========================================
 1. 系统信息查询       4. 一键脚本
 2. 系统全面更新       5. Docker 管理
 3. 系统垃圾清理
----------------------------------------
 99. 更新脚本          88. 卸载脚本
----------------------------------------
 0. 退出
========================================
请输入选择:
```

---

## 5. One-Click Scripts (Menu 4)

```text
========================================
一键脚本
========================================
[落魄的脚本]
 1. 落魄 Hysteria2 一键脚本
 2. 落魄 Sing-box 一键脚本
[第三方脚本]
 3. 3X-UI 一键安装脚本
 4. F佬 Sing-box 一键脚本
 5. 老王 Sing-box 四合一
 6. 勇哥 Sing-box 四合一
 7. 233boy Sing-box 一键脚本
----------------------------------------
 0. 返回上级菜单
========================================
请输入脚本编号:
```

Script index file:

`integrations/index.json`

---

## 6. Docker Management (Menu 5)

```text
========================================
Docker 管理
========================================
 1. 安装 Docker         5. Docker 状态
 2. 启动 Docker         6. 查看容器列表
 3. 停止 Docker         7. 查看镜像列表
 4. 重启 Docker         8. 清理无用资源
----------------------------------------
 0. 返回上级
========================================
请输入选择:
```

---

## 7. Update and Rollback

Menu `99` update logic:

- Git install: `fetch/merge`, rollback to previous commit on failure
- Non-git install: auto run remote update (`https://z.evzzz.com`)

---

## 8. Uninstall

Use menu `88`, or run manually:

```bash
rm -rf /opt/luopo-toolkit
rm -f /usr/local/bin/z
```

---

## 9. Directories and Logs

- Install directory: `/opt/luopo-toolkit`
- Launcher command: `/usr/local/bin/z`
- Action log: `logs/action.log`
- Error log: `logs/error.log`

---

## 10. Development and Maintenance

### 10.1 Run Locally

```bash
bash toolkit.sh
```

### 10.2 Code Quality Checks

```bash
bash scripts/lint.sh
```

### 10.3 Automatic Release

Built-in GitHub Actions auto-release workflow:

- Trigger version release only on core code changes
- Large changes (main UI/core refactor) bump minor version (e.g. `0.1.3 -> 0.2.0`)
- Small changes (incremental feature updates) bump patch version (e.g. `0.1.3 -> 0.1.4`)
- Auto update `VERSION` / `CHANGELOG`
- Auto create tag
- Auto create GitHub Release

Workflow file:

`/.github/workflows/release.yml`

---

## 11. License

This project is released under [MIT License](LICENSE).


