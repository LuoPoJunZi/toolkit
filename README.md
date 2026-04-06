# LuoPo VPS Toolkit

LuoPo VPS Toolkit 是一个面向新手站长的 Linux VPS 一键工具箱（首版支持 Ubuntu / Debian），采用纯菜单交互，集成常用系统运维能力与精选一键脚本。

当前版本：`0.1.0`

## 支持环境

- Ubuntu
- Debian
- Root 权限运行

## 一键安装与启动

推荐安装命令：

```bash
bash <(curl -fsSL https://z.evzzz.com)
```

安装完成后会自动进入主菜单。若只想安装不自动进入，可使用：

```bash
AUTO_LAUNCH=0 bash <(curl -fsSL https://z.evzzz.com)
```

如果你是本地仓库开发环境，也可以：

```bash
sudo bash install.sh
```

安装完成后支持以下快捷命令：

```bash
z
```

英文界面启动：

```bash
z en
```

## 主菜单说明

- `1` 系统信息查询：查看主机名、内核、运行时长、CPU、内存、磁盘信息
- `2` 系统更新：执行系统包更新
- `3` 系统清理：执行自动清理（autoremove/autoclean）
- `4` 一键脚本：脚本白名单选择、下载、哈希校验、确认执行
- `5` Docker 管理：Docker 安装与常用运维
- `00` 脚本更新：拉取最新代码并自动更新（失败自动回滚）
- `88` 卸载脚本：完全清理 Toolkit 安装与启动命令
- `0` 退出脚本

## 一键脚本（菜单 4）

当前已集成：

- LuoPoJunZi Hysteria2 脚本
- LuoPoJunZi Sing-box EV 脚本
- F佬 Sing-box 一键脚本
- 老王 Sing-box 四合一
- 勇哥 Sing-box 四合一
- 233boy Sing-box 一键脚本

执行流程：

1. 从索引读取启用脚本
2. 下载到本地缓存
3. SHA256 校验
4. 人工确认
5. 执行脚本

索引文件位置：

`integrations/index.json`

## Docker 管理（菜单 5）

内置功能：

- 安装 Docker（`docker.io`）
- 启动 / 停止 / 重启 Docker 服务
- 查看 Docker 状态
- 查看容器列表
- 查看镜像列表
- 清理无用资源（`docker system prune -f`，带确认）

## 更新与回滚（菜单 00）

- Git 安装模式：自动检查远端更新，失败自动回滚到更新前 commit
- 非 Git 安装模式：自动切换到远程更新（`bash <(curl -fsSL https://z.evzzz.com)`）
- 若检测到 Git 本地未提交改动，会中止更新避免覆盖

## 日志与目录

- 安装目录：`/opt/luopo-toolkit`
- 启动命令：`/usr/local/bin/z`
- 操作日志：`logs/action.log`
- 错误日志：`logs/error.log`

## 卸载

菜单中可直接选择 `88` 一键卸载，或手动执行：

```bash
rm -rf /opt/luopo-toolkit
rm -f /usr/local/bin/z
```
