# toolkit

Minimal VPS one-click toolbox for beginner Linux users (Ubuntu/Debian first).

## Quick Start

```bash
sudo bash install.sh
```

安装后快捷启动:

```bash
luo
```

项目目录下直接运行:

```bash
bash toolkit.sh
```

English UI:

```bash
bash toolkit.sh en
```

## v1 Menu

- 1. System information / 系统信息查询
- 2. System update / 系统更新
- 3. System cleanup / 系统清理
- 4. One-click scripts / 一键脚本
- 5. Docker management / Docker管理
- 00. Script self-update / 脚本更新
- 0. Exit / 退出脚本

## Docker 子菜单

- 安装 Docker（`apt-get install docker.io`）
- 启动/停止/重启 Docker 服务
- 查看 Docker 状态
- 查看容器/镜像列表
- 清理无用资源（`docker system prune -f`，带确认）

## Security Baseline For Third-Party Scripts

- Source review
- Pinned version
- SHA256 verification
- Manual confirmation before execution

## 更新与回滚

- 菜单 `00` 执行脚本更新
- 更新失败会自动回滚到更新前提交
- 若检测到本地未提交修改，将中止更新以避免覆盖
