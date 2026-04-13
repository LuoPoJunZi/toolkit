<h1 align="center">⚙️ LuoPo VPS Toolkit</h1>
<div align="center">

一个面向 VPS 新手站长的终端工具箱。<br>
目标：**安装即用、菜单清晰、常见运维操作低门槛完成**。

[![Language](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-0A66C2?style=flat-square)](#)
[![Version](https://img.shields.io/github/v/release/LuoPoJunZi/toolkit?display_name=tag&style=flat-square&label=Version)](https://github.com/LuoPoJunZi/toolkit/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

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
5. Docker管理
6. 网络加速管理
7. 网络测试工具
8. 安全与防护
9. LDNMP 建站
10. 应用市场
11. 后台工作区
12. 系统工具
13. 备份/恢复/迁移
14. 定时任务中心
15. 服务器集群控制
16. Oracle Cloud 工具集
17. 游戏开服脚本合集
18. AI工作区(可选)
99. 更新脚本
88. 卸载脚本
0. 退出脚本
```

## 子菜单能力概览

| 菜单 | 主要能力 |
| --- | --- |
| 4. 一键脚本中心 | 集成自研与第三方脚本，下载缓存 + SHA256 校验后执行 |
| 5. Docker管理 | Docker 安装升级、全局状态、容器/镜像/网络/卷管理、镜像源切换、daemon 配置、IPv6 开关、备份迁移还原、环境卸载 |
| 6. 网络加速管理 | BBR/FQ、WARP、Fast Open、出口检测、连接统计 |
| 7. 网络测试工具 | Ping/Traceroute/MTR/DNS、TLS 检测、端口连通、测速脚本 |
| 8. 安全与防护 | SSH 与防火墙检查、Fail2ban、Root 策略、认证日志、安全巡检 |
| 9. LDNMP 建站 | LDNMP、WordPress、Nginx 代理/重定向、站点备份恢复与优化 |
| 10. 应用市场 | Portainer、Uptime Kuma、NPM、AList、Gitea、Minio、Redis 等 |
| 11. 后台工作区 | Screen/Tmux、开机自启、日志查看、进程与 failed 服务检查 |
| 12. 系统工具 | 时区/主机名/Swap/端口/DNS/磁盘/网卡/用户/时间同步 |
| 13. 备份/恢复/迁移 | 目录备份恢复、rsync 迁移、数据库备份恢复、GPG 加解密 |
| 14. 定时任务中心 | crontab 查看编辑、模板任务、日志检查、关键字删除 |
| 15. 服务器集群控制 | 节点管理、批量执行、批量更新重启、SCP 分发、列表导出 |
| 16. Oracle Cloud 工具集 | OCI 诊断、路由端口检查、metadata 检查、安全组建议 |
| 17. 游戏开服脚本合集 | Minecraft、Palworld、Rust 等容器化部署与运维 |
| 18. AI工作区(可选) | OpenWebUI、Ollama、AnythingLLM、One-API、Dify |

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

## 开源协议

本项目基于 [MIT License](LICENSE) 开源。
