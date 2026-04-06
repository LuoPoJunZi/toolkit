# ⚙️ LuoPo VPS Toolkit

<div align="center">

一个面向 VPS 新手站长的终端工具箱。<br>
目标：**安装即用、菜单清晰、常见运维操作低门槛完成**。

[![Language](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-0A66C2?style=flat-square)](#)
[![Version](https://img.shields.io/badge/Version-0.1.2-blue?style=flat-square)](#)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

</div>

---

## 1. 这是什么？适合谁用？

`LuoPo VPS Toolkit` 是一个纯 Bash 的 VPS 菜单工具，聚焦日常高频操作：

- 系统信息查询
- 系统更新与清理
- 第三方优秀脚本一键集成
- Docker 管理
- 脚本更新与卸载

适合：

- 新手站长：希望“命令少、可视化菜单多”
- 运维用户：希望快速执行标准操作
- 脚本维护者：希望在菜单框架上扩展更多功能

---

## 2. 项目能力总览

- 主菜单紧凑双列布局（更清晰）
- 系统信息面板：分区展示，含资源/网络/位置
- 一键脚本中心：分组展示（落魄的脚本 / 第三方脚本）
- 第三方脚本执行安全链路：下载 + SHA256 校验
- Docker 常见运维菜单化
- 更新机制：
  - Git 安装：Git 更新 + 失败回滚
  - 非 Git 安装：自动切换远程更新
- 一键卸载（`88`）彻底清理安装痕迹

---

## 3. 快速开始

### 3.1 一键安装（推荐）

```bash
bash <(curl -fsSL https://z.evzzz.com)
```

### 3.2 备用安装（GitHub Raw）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)
```

### 3.3 启动命令

```bash
z
```

英文界面：

```bash
z en
```

---

## 4. 主菜单预览

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

## 5. 一键脚本（菜单 4）

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

脚本索引文件：

`integrations/index.json`

---

## 6. Docker 管理（菜单 5）

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

## 7. 更新与回滚

菜单 `99` 更新逻辑：

- Git 安装：`fetch/merge`，失败自动回滚到更新前 commit
- 非 Git 安装：自动执行远程更新（`https://z.evzzz.com`）

---

## 8. 卸载

菜单 `88` 可一键卸载；也可手动执行：

```bash
rm -rf /opt/luopo-toolkit
rm -f /usr/local/bin/z
```

---

## 9. 目录与日志

- 安装目录：`/opt/luopo-toolkit`
- 启动命令：`/usr/local/bin/z`
- 操作日志：`logs/action.log`
- 错误日志：`logs/error.log`

---

## 10. 开发与维护

### 10.1 本地运行

```bash
bash toolkit.sh
```

### 10.2 代码质量检查

```bash
bash scripts/lint.sh
```

### 10.3 自动发布

已内置 GitHub Actions 自动发布流程：

- 自动补丁版本号递增
- 自动更新 `VERSION` / `CHANGELOG`
- 自动打 Tag
- 自动创建 GitHub Release

工作流文件：

`/.github/workflows/release.yml`

---

## 11. 开源协议

本项目基于 [MIT License](LICENSE) 开源。
