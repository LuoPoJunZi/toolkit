<h1 align="center">⚙️ LuoPo VPS Toolkit</h1>
<div align="center">

A terminal toolkit for VPS beginners.<br>
Goal: **ready to use after install, clean menus, and low-friction daily operations**.

[![Language](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-0A66C2?style=flat-square)](#)
[![Version](https://img.shields.io/github/v/release/LuoPoJunZi/toolkit?display_name=tag&style=flat-square&label=Version)](https://github.com/LuoPoJunZi/toolkit/releases)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg?style=flat-square)](LICENSE)

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

Compatibility command used by the mirrored `kejilion` feature layer:

```bash
k
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
5. Basic tools
6. BBR management
7. Docker management
8. WARP management
9. Test script suite
10. Oracle Cloud tools
11. LDNMP site builder
12. App market
13. Background workspace
14. System tools
15. Server cluster control
99. Update toolkit
88. Uninstall toolkit
0. Exit script
```

## Clone Layer Notes

- Main menu `5-15` now mirrors the `4-14` feature set from `kejilion/sh`.
- This compatibility layer intentionally keeps the upstream menu structure, submenu depth, external-script integrations, and operating style as close as possible for later second-stage customization.
- Upstream source and local adaptation notes are documented in [docs/UPSTREAM_ATTRIBUTION.md](docs/UPSTREAM_ATTRIBUTION.md).
- Local adaptations currently include disabling upstream telemetry, disabling upstream self-install side effects, and wrapping the upstream script as a safely loadable library under `LuoPo VPS Toolkit`.

## Submenu Capabilities

| Menu | Highlights |
| --- | --- |
| 4. One-click script hub | Curated scripts with cached download + SHA256 verification before execution |
| 5. Basic tools | Common packages, terminal utilities, editors, small CLI tools, bulk install/remove |
| 6. BBR management | BBR / BBRv3 management and upstream network-acceleration script integration |
| 7. Docker management | Install/upgrade, global status, container/image/network/volume management, IPv6, backup/migrate/restore |
| 8. WARP management | Upstream WARP management script integration |
| 9. Test script suite | Unlock tests, route tracing, bandwidth tests, hardware benchmarks, all-in-one test suites |
| 10. Oracle Cloud tools | OCI keepalive helpers, DD reinstall, root login helpers, IPv6 recovery |
| 11. LDNMP site builder | LDNMP, WordPress, reverse proxy, redirects, full-site backup/restore, security and tuning |
| 12. App market | Upstream app-market driven deployment for a large catalog of Dockerized apps |
| 13. Background workspace | Tmux workspaces, persistent SSH mode, custom workspaces, command injection |
| 14. System tools | SSH, timezone, hostname, ports, swap, users, firewall, logs, environment variables, and more |
| 15. Server cluster control | Multi-node inventory, batch tasks, bulk system maintenance, and synchronized operations |

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
rm -f /usr/local/bin/k
```

## Directories and Logs

- Install directory: `/opt/luopo-toolkit`
- Launcher command: `/usr/local/bin/z`
- Compatibility launcher: `/usr/local/bin/k`
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

- This project is released under the [GPL-3.0 License](LICENSE).
- The mirrored `5-15` compatibility layer includes Apache-2.0 licensed upstream code from `kejilion/sh` plus local adaptations. See [docs/UPSTREAM_ATTRIBUTION.md](docs/UPSTREAM_ATTRIBUTION.md).
