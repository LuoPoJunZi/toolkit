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

</div>

---

## Introduction

`LuoPo VPS Toolkit` is a pure Bash menu-driven toolbox for Ubuntu / Debian VPS operations. It is designed for beginner webmasters who want visual menus and one-click execution for common server tasks.

## Quick Start

### 1) Install (Recommended)

```bash
bash <(curl -fsSL z.evzzz.com)
```

### 2) Fallback Install (GitHub Raw)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)
```

### 3) Launch Command

```bash
z
```

English UI:

```bash
z en
```

## Main Menu (Current)

```text
1. System info
2. Full system update
3. System cleanup
4. One-click script hub
5. Docker management
6. Network acceleration
7. Network test tools
8. Security and protection
9. LDNMP site builder
10. App market
11. Background workspace
12. System tools
13. Backup/Restore/Migrate
14. Cron task center
15. Server cluster control
16. Oracle Cloud toolkit
17. Game server scripts
18. AI workspace (optional)
99. Update toolkit
88. Uninstall toolkit
0. Exit script
```

## Submenu Capabilities

| Menu | Highlights |
| --- | --- |
| 4. One-click script hub | Curated scripts with cached download + SHA256 verification before execution |
| 5. Docker management | Install/upgrade, global status, container/image/network/volume management, mirror switch, daemon config, IPv6 toggle, backup/migrate/restore, and uninstall |
| 6. Network acceleration | BBR/FQ, WARP, TCP Fast Open, egress checks, connection stats |
| 7. Network test tools | Ping/Traceroute/MTR/DNS, TLS checks, port checks, speed test scripts |
| 8. Security and protection | SSH/firewall checks, Fail2ban, root policy checks, auth logs, hardening helpers |
| 9. LDNMP site builder | LDNMP/WordPress, nginx proxy/redirect, site backup/restore/optimization |
| 10. App market | Portainer, Uptime Kuma, NPM, AList, Gitea, Minio, Redis, and more |
| 11. Background workspace | Screen/Tmux sessions, startup services, logs, process and failed-service checks |
| 12. System tools | Timezone/hostname/swap/ports/DNS/disk/NIC/users/time sync |
| 13. Backup/Restore/Migrate | Directory backup/restore, rsync migration, DB dump/restore, GPG encrypt/decrypt |
| 14. Cron task center | Crontab view/edit, templates, logs, keyword-based task deletion |
| 15. Server cluster control | Node management, batch execute/update/reboot, SCP distribution, export list |
| 16. Oracle Cloud toolkit | OCI diagnostics, routing/port checks, metadata checks, security group hints |
| 17. Game server scripts | Containerized deployment and management for multiple game servers |
| 18. AI workspace (optional) | OpenWebUI, Ollama, AnythingLLM, One-API, Dify |

## One-Click Script List (Menu 4)

1. LuoPo Hysteria2 install script
2. LuoPo Sing-box install script
3. 3X-UI install script
4. Fscarmen Sing-box script
5. Eooce Sing-box script
6. Yongge Sing-box script
7. 233boy Sing-box script

Script index: `integrations/index.json`

## Update and Rollback

- Use `99` to update toolkit.
- Git install mode: `fetch + ff-only merge`, with rollback on failure.
- Non-git install mode: fallback to remote bootstrap update (`https://z.evzzz.com`).

## Uninstall

- Use menu `88` for one-click uninstall.
- Manual uninstall:

```bash
rm -rf /opt/luopo-toolkit
rm -f /usr/local/bin/z
```

## Directories and Logs

- Install directory: `/opt/luopo-toolkit`
- Launcher command: `/usr/local/bin/z`
- Cache directory: `data/cache/`
- Action log: `logs/action.log`
- Error log: `logs/error.log`

## Development and Maintenance

Run locally:

```bash
bash toolkit.sh
```

Quality checks:

```bash
bash scripts/lint.sh
bash tests/smoke_menu.sh
```

Version and release:

- Version history is managed by `VERSION` + `CHANGELOG.md`.
- GitHub Actions runs `ci` and `release` workflows.
- Release page: <https://github.com/LuoPoJunZi/toolkit/releases>

## License

This project is released under the [MIT License](LICENSE).
