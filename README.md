<h1 align="center">⚙️ LuoPo VPS Toolkit</h1>
<div align="center">

一个面向 VPS 新手站长的终端工具箱。<br>
目标：**安装即用、菜单清晰、常见运维操作低门槛完成**。

[![Language](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-0A66C2?style=flat-square)](#)
[![Version](https://img.shields.io/github/v/release/LuoPoJunZi/toolkit?display_name=tag&style=flat-square&label=Version)](https://github.com/LuoPoJunZi/toolkit/releases)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg?style=flat-square)](LICENSE)

<br>

[![简体中文](https://img.shields.io/badge/简体中文-2f4858?style=for-the-badge)](README.md)
[![ENGLISH](https://img.shields.io/badge/ENGLISH-2f4858?style=for-the-badge)](README_en.md)

</div>

---

## 简介

`LuoPo VPS Toolkit` 是一个纯 Bash 的 VPS 菜单工具箱，聚焦 Ubuntu / Debian 场景，面向新手站长提供“可视化菜单 + 一键操作”的运维体验。

## 快速开始

### 1) 一键安装（推荐）

```bash
bash <(curl -fsSL z.evzzz.com)
```

### 2) 备用安装（GitHub Raw）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)
```

### 3) 启动命令

```bash
z
```

英文界面：

```bash
z en
```

## 主菜单（当前实现）

```text
1. 系统信息查询
2. 系统全面更新
3. 系统垃圾清理
4. 一键脚本中心
5. 基础工具
6. BBR管理
7. Docker管理
8. WARP管理
9. 测试脚本合集
10. 甲骨文云脚本合集
11. LDNMP建站
12. 应用市场
13. 后台工作区
14. 系统工具
15. 服务器集群控制
99. 更新脚本
88. 卸载脚本
0. 退出脚本
```

## 复刻说明

- 当前 `5-15` 主菜单基于 `kejilion/sh` 的 `4-14` 功能体系做了本地模块化复刻。
- 本地模块优先保留上游菜单结构、子菜单层级、外部脚本调用方式与运行习惯，便于后续继续二次开发。
- 上游来源与本地适配说明见：[docs/UPSTREAM_ATTRIBUTION.md](docs/UPSTREAM_ATTRIBUTION.md)。
- 当前本地适配主要包括：关闭上游遥测、关闭上游自安装副作用、将活动菜单迁移到 `modules/luopo/` 原生模块，`vendor/luopo.sh` 仅作为备份与来源参考保留。

## 当前架构状态

- 主入口：`toolkit.sh`
- 主菜单：`core/menu.sh`
- 主菜单注册：`core/menu_registry.sh`
- 主菜单分发：`core/menu_dispatcher.sh`
- 活动功能模块：`modules/luopo/`
- 一键脚本索引：`integrations/index.json`
- 上游参考备份：`vendor/luopo.sh`

当前活动运行路径不再依赖：

- `modules/compat/`
- `legacy_bridge.sh`
- `ensure_luopo_vendor_loaded`
- `run_luopo_compat_menu`

旧菜单草稿已本地保留、不再上传 GitHub：

- `modules/menus/`
- `modules/extended_menus.sh`
- `modules/singbox.sh`

## 子菜单能力概览

| 菜单 | 主要能力 |
| --- | --- |
| 4. 一键脚本中心 | 集成自研与第三方脚本，下载缓存 + SHA256 校验后执行 |
| 5. 基础工具 | 常用系统包、终端工具、编辑器、实用小工具与批量安装/卸载 |
| 6. BBR管理 | BBR / BBRv3 相关管理与上游网络加速脚本接入 |
| 7. Docker管理 | Docker 安装升级、全局状态、容器/镜像/网络/卷管理、IPv6、备份迁移还原 |
| 8. WARP管理 | 接入上游 WARP 管理脚本 |
| 9. 测试脚本合集 | 解锁检测、回程测试、测速脚本、硬件性能与综合测评 |
| 10. 甲骨文云脚本合集 | 甲骨文保活、DD 重装、root 登录、IPv6 恢复等 |
| 11. LDNMP建站 | LDNMP、WordPress、站点反代、重定向、全站备份恢复、防护优化 |
| 12. 应用市场 | 对接上游应用市场体系，提供大量 Docker 化应用一键部署 |
| 13. 后台工作区 | Tmux 工作区、常驻 SSH 模式、自定义工作区与命令注入 |
| 14. 系统工具 | SSH、时区、主机名、端口、swap、用户、防火墙、日志、环境变量等 |
| 15. 服务器集群控制 | 多节点服务器清单、批量执行任务、批量系统维护与同步操作 |

## 一键脚本清单（菜单 4）

1. 落魄 Hysteria2 一键脚本
2. 落魄 Sing-box 一键脚本
3. 3X-UI 一键安装脚本
4. F佬 Sing-box 一键脚本
5. 老王 Sing-box 四合一
6. 勇哥 Sing-box 四合一
7. 233boy Sing-box 一键脚本

脚本索引：`integrations/index.json`

## 更新与回滚

- 选择 `99` 可执行脚本更新。
- Git 安装场景：`fetch + ff-only merge`，失败自动回滚。
- 非 Git 安装场景：自动走远程引导更新（`https://z.evzzz.com`）。

## 卸载

- 菜单 `88`：一键卸载。
- 手动卸载：

```bash
rm -rf /opt/luopo-toolkit
rm -f /usr/local/bin/z
```

## 目录与日志

- 安装目录：`/opt/luopo-toolkit`
- 启动命令：`/usr/local/bin/z`
- 缓存目录：`data/cache/`
- 操作日志：`logs/action.log`
- 错误日志：`logs/error.log`

## 开发与维护

本地运行：

```bash
bash toolkit.sh
```

代码检查：

```bash
bash scripts/lint.sh
bash tests/smoke_menu.sh
```

版本与发布：

- `VERSION` + `CHANGELOG.md` 管理版本历史。
- GitHub Actions 执行 `ci` 与 `release` 工作流。
- Release 页面：<https://github.com/LuoPoJunZi/toolkit/releases>
- 当前目录结构说明：[docs/DIRECTORY_STRUCTURE.md](docs/DIRECTORY_STRUCTURE.md)
- 结构优化记录：[docs/STRUCTURE_OPTIMIZATION_LOG.md](docs/STRUCTURE_OPTIMIZATION_LOG.md)

## 开源协议

- 本项目基于 [GPL-3.0 License](LICENSE) 开源。
- `5-15` 模块化复刻层包含来自 `kejilion/sh` 的 Apache-2.0 授权代码与适配修改，详细说明见 [docs/UPSTREAM_ATTRIBUTION.md](docs/UPSTREAM_ATTRIBUTION.md)。
