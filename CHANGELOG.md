# Changelog

## 1.0.2

### 主要变化

- 主菜单标题和启动横幅改为语言文件驱动，英文界面不再显示中文快捷启动提示。
- 菜单 `4` 的运行时标题统一为“脚本中心”，与主菜单短标签保持一致。
- 新增 Windows 本地预检脚本 `scripts/preflight.ps1`，可自动检测 Git Bash 或 WSL 并运行 Bash 语法检查和菜单烟测。
- README 中英文和目录结构文档已同步 Windows 预检入口与新脚本位置。
- 菜单烟测新增主菜单标题国际化、英文快捷启动文案和脚本中心标题断言。

## 1.0.1

### 主要变化

- 主菜单 `1-13` 文案改为更短、更均衡的 4-5 字风格：系统概览、系统更新、系统清理、脚本中心、基础工具、BBR管理、Docker、WARP管理、网络测试、建站管理、应用市场、后台工作、系统工具。
- 同步更新英文界面短标签，使中英文主菜单都保持更整齐的视觉长度。
- README 中英文和运行检查清单已同步新的主菜单展示名称。
- 功能入口和编号保持不变，仍为连续编号 `1-13 / 99 / 88 / 0`。

## 1.0.0

### 主要变化

- 正式版主菜单调整为连续编号 `1-13 / 99 / 88 / 0`，整体保持单列、清晰、易扫描的 VPS 运维菜单风格。
- 主菜单当前提供系统信息、系统更新、系统清理、一键脚本中心、基础工具、BBR、Docker、WARP、测试脚本合集、LDNMP 建站、应用市场、后台工作区、系统工具等核心能力。
- 一键脚本中心仅展示 LuoPo 自维护脚本，包括 Hysteria2 与 Sing-box，并保留下载缓存和 SHA256 校验执行链路。
- Docker 管理已覆盖安装升级、状态查看、容器/镜像/网络/卷管理、清理、IPv6、备份迁移还原等常用操作。
- LDNMP 建站、应用市场、后台工作区、系统工具等模块已迁移到 `modules/luopo/` 原生模块体系，主运行路径不再依赖旧兼容层。
- 甲骨文云脚本合集和服务器集群控制代码仍保留在仓库中，但当前从主菜单隐藏，后续可按需要恢复入口。
- README 中英文、目录结构文档、运行检查清单、语言文案和菜单烟测断言已同步当前正式版菜单。
- 后续 GitHub Release 描述必须包含“主要变化”，方便维护者和用户区分不同版本差异。

## 0.9.14
- Auto release: v0.9.14
- chore: limit script hub to luopo scripts (327ae04)

## 0.9.13
- Auto release: v0.9.13
- feat: expand warp menu and unify submenu style (c7a6a08)

## 0.9.12
- Auto release: v0.9.12
- refactor: deepen native module splits (3a20538)

## 0.9.11
- Auto release: v0.9.11
- refactor: split ldnmp site actions (11c904a)

## 0.9.10
- Auto release: v0.9.10
- refactor: split system tools operations and helpers (aacad1a)

## 0.9.9
- Auto release: v0.9.9
- refactor: split large native module files (7a075f7)
- fix(ci): guard fixed-string grep patterns (da6a8e9)

## 0.9.8
- Auto release: v0.9.8
- chore: keep vendor snapshot local only (74fc7ad)

## 0.9.7
- Auto release: v0.9.7
- fix(ci): restore uptime kuma app market entry (15a9fea)
- fix(ci): relax app market backup shortcut assertion (bb29d51)

## 0.9.6
- Auto release: v0.9.6
- style: organize app market menu categories (c0b0713)

## 0.9.5
- Auto release: v0.9.5
- style: normalize submenu numbering and layout (4e7de1a)
- chore: make auto release patch only (105eb12)

## 0.9.4
- Auto release: v0.9.4
- style: align long submenu columns (e6a00ff)

## 0.9.3
- Auto release: v0.9.3
- style: simplify ldnmp menu layout (94c0005)

## 0.9.2
- Auto release: v0.9.2
- fix: remove dangling system tools declarations (8ccdfc7)
- docs: refresh architecture documentation (741a2b8)

## 0.9.1
- Auto release: v0.9.1
- chore: keep retired menu drafts local (7c2070c)

## 0.9.0
- Auto release: v0.9.0
- refactor: complete native module migration (8b7255b)

## 0.8.1
- Auto release: v0.8.1
- refactor: reduce luopo legacy fallbacks (170d0f0)

## 0.8.0
- Manual release: v0.8.0
- refactor: deepen native ldnmp and system tools structure
- refactor: remove app marketplace proxy bridge and reuse native ldnmp helpers
- docs: sync structure optimization log and dependency audit

## 0.7.30
- Auto release: v0.7.30
- feat: complete native app marketplace entries (95eed6c)

## 0.7.29
- Auto release: v0.7.29
- feat: add native ai and ops app entries (55e3cb4)

## 0.7.28
- Auto release: v0.7.28
- feat: add native compose app marketplace entries (7a343af)

## 0.7.27
- Auto release: v0.7.27
- feat: add native core app marketplace entries (e94ea0d)

## 0.7.26
- Auto release: v0.7.26
- refactor: narrow app marketplace scope (f293bdd)

## 0.7.25
- Auto release: v0.7.25
- feat: add more native app marketplace entries (41f2e70)

## 0.7.24
- Auto release: v0.7.24
- refactor: complete native ldnmp routing (b79aaee)

## 0.7.23
- Auto release: v0.7.23
- refactor: add native ldnmp commerce installers (83fc9dc)

## 0.7.22
- Auto release: v0.7.22
- refactor: add native ldnmp forum installers (5ac31b5)

## 0.7.21
- Auto release: v0.7.21
- refactor: add native ldnmp blog installers (90b5b1b)

## 0.7.20
- Auto release: v0.7.20
- refactor: add native ldnmp site utilities (54f0c90)

## 0.7.19
- Auto release: v0.7.19
- refactor: route system tools bbr shortcut natively (a7be9d5)

## 0.7.18
- Auto release: v0.7.18
- refactor: deepen native ldnmp operations (4203549)

## 0.7.17
- Auto release: v0.7.17
- feat: expand native app marketplace coverage (43c3424)

## 0.7.16
- Auto release: v0.7.16
- refactor: complete native system tools routing (7a62790)

## 0.7.15
- Auto release: v0.7.15
- refactor: deepen system tools and ldnmp routing (6720994)

## 0.7.14
- Auto release: v0.7.14
- refactor: deepen native system tools actions (be7da79)

## 0.7.13
- Auto release: v0.7.13
- refactor: move system tools menu flow into luopo layer (470591c)

## 0.7.12
- Auto release: v0.7.12
- feat: expand native app marketplace docker handlers (bad4094)

## 0.7.11
- Auto release: v0.7.11
- feat: add native app marketplace handlers for core docker apps (5ddcd76)

## 0.7.10
- Auto release: v0.7.10
- refactor: render and dispatch app marketplace in luopo layer (392f819)

## 0.7.9
- Auto release: v0.7.9
- docs: refresh run checklist for current menu layout (abcada0)

## 0.7.8
- Auto release: v0.7.8
- refactor: align menu action names with luopo handlers (d1016c1)

## 0.7.7
- Auto release: v0.7.7
- refactor: remove obsolete compat menu shims (2ec41e0)

## 0.7.6
- Auto release: v0.7.6
- refactor: extract ldnmp and system tools menus (17efa9f)

## 0.7.5
- Auto release: v0.7.5
- refactor: extract warp and app marketplace menus (d834f09)

## 0.7.4
- Auto release: v0.7.4
- refactor: move docker management under luopo modules (884475c)

## 0.7.3
- Auto release: v0.7.3
- refactor: extract cluster control menu (f679ecc)

## 0.7.2
- Auto release: v0.7.2
- refactor: extract oracle cloud menu (55c3a00)

## 0.7.1
- Auto release: v0.7.1
- refactor: extract workspace basic tools and bbr menus (033f4a2)

## 0.7.0
- Auto release: v0.7.0
- refactor: modularize menu routing and extract network test suite (90d52b5)
- fix(ci): drop stale app market contribution assertion (b054365)
- style: remove duplicate app market separator (1d14f85)
- style: trim third-party app list from app market (15d0900)
- style: refresh visible luopo branding in compat layer (645157c)

## 0.6.1
- Auto release: v0.6.1
- refactor: standardize launcher on z only (595afc8)

## 0.6.0
- Auto release: v0.6.0
- refactor: rename compatibility layer files to luopo (4cffa0b)
- style: refresh cloned submenu branding and fix display text (4bf8260)

## 0.5.1
- Auto release: v0.5.1
- fix: support remote bootstrap install via z domain (013120f)

## 0.5.0
- Auto release: v0.5.0
- feat: mirror kejilion menus 4-14 via compatibility layer (c9624a9)
- Update README_en.md (9362638)
- Update README.md (cf7a116)

## 0.4.0
- Auto release: v0.4.0
- fix: avoid double-enter on menu return paths (ec443e2)
- feat: replace toolkit menus 5-15 with a kejilion/sh 4-14 compatibility layer
- feat: vendor upstream compatibility layer in `vendor/luopo.sh` with telemetry/self-install disabled
- docs: add upstream attribution notes and sync zh/en README to the cloned menu structure

## 0.3.3
- Auto release: v0.3.3
- feat: expand docker management suite and add route smoke checks (9cc6233)

## 0.3.2
- Auto release: v0.3.2
- feat: switch system info to single-column layout and refresh READMEs (dd0a354)
- chore: restore docs tracking and keep local ignore rules (d9e8c46)
- fix(ci): disable brittle submenu mapping assertion (afcfca0)
- fix(ci): make case label extraction independent of ')' spacing (136b435)
- fix(ci): skip menu 0 in submenu case mapping check (144a8dd)
- fix(ci): preserve line boundaries when parsing case labels (a25befe)
- fix(ci): tolerate shfmt spacing in case label parsing (dfad182)
- fix(ci): simplify smoke script for runner compatibility (94fa469)
- chore(ci): add ERR trap for smoke diagnostics (b5eaf34)
- fix(ci): allow shfmt spacing in 99|00 case assertion (8677168)
- chore(ci): emit smoke failure annotations for debugging (3e07a23)
- fix(ci): stabilize smoke checks and lint submenu scripts (51ba838)
- docs: add run-level checklist for all menus (99d2819)

## 0.3.1
- Auto release: v0.3.1
- fix: avoid silent no-op for remote script actions (33be5f1)

## 0.3.0
- Auto release: v0.3.0
- refactor: modularize submenus and harden menu action reliability (22e36dd)
- Update LICENSE (ce1e511)

## 0.2.0
- Auto release: v0.2.0
- style: improve main menu spacing and column alignment (1d3aed0)
- docs: remove duplicated language link blocks from READMEs (ed09c60)
- docs: sync multilingual READMEs and release version badges (b2635a1)
- docs: add multilingual README language-switch section (9c48ef6)
- chore: refine auto-release version bump policy (406661c)

## 0.1.4
- Auto release: v0.1.4
- docs: rewrite README with structured toolkit guide (dbb6008)

## 0.1.3
- Auto release: v0.1.3
- feat: polish toolkit UI, script hub grouping, and update UX (6a75b4a)

## 0.1.2
- Auto release: v0.1.2
- style: refine system info layout and silent auto-launch install (e161299)

## 0.1.1
- Auto release: v0.1.1
- ci: add automatic release workflow with version bump (a3b2415)
- feat: add uninstall menu and improve update/install flow (7607b9b)
- feat: improve system info view and streamline one-click script execution (e204bf5)
- docs: polish v0.1.0 usage and switch launcher to z (bed9f31)
- first commit (273c4c1)

## 0.1.0
- Initial release of LuoPo VPS Toolkit.
- Added pure menu-driven toolkit for Ubuntu/Debian.
- Added core menu items:
  - system info
  - system update
  - system cleanup
  - one-click scripts hub
  - Docker management
  - self-update
- Added one-click script integrations with SHA256 verification:
  - LuoPoJunZi/hysteria2-luopo
  - LuoPoJunZi/sing-box-ev
  - fscarmen/sing-box
  - eooce/sing-box
  - yonggekkk/sing-box-yg
  - 233boy/sing-box
- Added self-update rollback on failure.
- Added installer deployment to `/opt/luopo-toolkit`.
- Added launcher commands:
  - `luo`
  - `z`
