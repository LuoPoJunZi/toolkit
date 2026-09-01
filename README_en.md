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
bash <(curl -fsSL https://raw.githubusercontent.com/LuoPoJunZi/toolkit/main/install.sh)
```

### 2) Launch Command

```bash
z
```

English UI:

```bash
z en
```

## Main Menu (Current)

```text
========================================
LuoPo VPS Toolkit v{VERSION} (Quick start: z)
========================================
 1.  Overview
 2.  Update
 3.  Cleanup
 4.  Tools
 5.  BBR
 6.  Docker
 7.  WARP
 8.  Network test
 9.  Site builder
 10. App market
 11. Workspace
 12. System tools
----------------------------------------
 99. Update toolkit
 88. Uninstall toolkit
 0.  Exit script
========================================
Enter choice:
```

## Clone Layer Notes

- Visible main menu entries `4-12` are local modular mirrors of the relevant `kejilion/sh` features; the Oracle Cloud tools and server cluster control code have been removed from the project.
- These local modules intentionally keep the upstream menu structure, submenu depth, external-script integrations, and operating style as close as possible for later second-stage customization.
- Upstream source and local adaptation notes are documented in [docs/UPSTREAM_ATTRIBUTION.md](docs/UPSTREAM_ATTRIBUTION.md).
- Local adaptations currently include disabling upstream telemetry, disabling upstream self-install side effects, and migrating active menus into native `modules/luopo/` modules. `vendor/luopo.sh` may be kept locally as a source-reference snapshot, but it is no longer uploaded to the GitHub repository.

## Current Architecture Status

- Main entry: `toolkit.sh`
- Main menu: `core/menu.sh`
- Main menu registry: `core/menu_registry.sh`
- Main menu dispatcher: `core/menu_dispatcher.sh`
- Active feature modules: `modules/luopo/`
- Retained but inactive: script hub code at `modules/scripts_hub.sh` and index at `integrations/index.json`
- Upstream reference backup: `vendor/luopo.sh` may be kept locally, but is not uploaded to GitHub

The active runtime path no longer depends on:

- `modules/compat/`
- `legacy_bridge.sh`
- `ensure_luopo_vendor_loaded`
- `run_luopo_compat_menu`

Retired menu drafts are kept locally and no longer uploaded to GitHub:

- `modules/menus/`
- `modules/extended_menus.sh`
- `modules/singbox.sh`

## Submenu Capabilities

| Menu | Highlights |
| --- | --- |
| 4. Tools | Common packages, terminal utilities, editors, small CLI tools, bulk install/remove |
| 5. BBR | BBR / BBRv3 management and upstream network-acceleration script integration |
| 6. Docker | Install/upgrade, global status, numbered container/image/network/volume selection, destructive-action confirmation, IPv6, backup/migrate/restore |
| 7. WARP | Upstream WARP management script integration |
| 8. Network test | Unlock tests, route tracing, bandwidth tests, hardware benchmarks, all-in-one test suites |
| 9. Site builder | LDNMP, WordPress, reverse proxy, redirects, full-site backup/restore, security and tuning |
| 10. App market | Locally maintained catalog with Docker app install, configuration-preserving updates, uninstall, backup, and restore |
| 11. Workspace | Tmux workspaces, persistent SSH mode, custom workspaces, command injection |
| 12. System tools | SSH, timezone, hostname, ports, swap, users, firewall, logs, environment variables, and more |

## Update and Rollback

- Use `99` to update toolkit.
- Git install mode: `fetch + ff-only merge`, with rollback on failure.
- Non-git install mode: update through the official GitHub Raw installer.

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

`scripts/lint.sh` runs Bash syntax checks, ShellCheck (`info` and above), and a read-only shfmt format check across every tracked `.sh` file. The development environment must provide `shellcheck` and `shfmt`; Bash uses two-space indentation, and CI fails on violations without rewriting files.

The repository uses `.editorconfig` for baseline editor formatting and `.gitattributes` to keep scripts and documentation on LF line endings.

Windows preflight (auto-detects Git Bash/WSL):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\preflight.ps1
```

The Windows preflight checks every Bash file for syntax and runs the menu smoke suite. It also runs the full lint when `shellcheck` and `shfmt` are installed; otherwise GitHub Actions remains the enforced lint path.
On Linux, Git Bash, or WSL, the same Bash checks can be run directly with `bash scripts/preflight.sh`.

Version and release:

- Version history is managed by `VERSION` + `CHANGELOG.md`.
- GitHub Actions runs `ci` and `release` workflows.
- Versions use the triggering commit date converted to the Asia/Shanghai time zone in `YY.M.D` format; for example, a change dated `2026-08-21` becomes `26.8.21`.
- Only one version tag is created per calendar day to avoid duplicate releases or moving an existing tag.
- Each GitHub Release description must include a concise "主要变化" / "Major Changes" section so version differences are clear.
- Release page: <https://github.com/LuoPoJunZi/toolkit/releases>
- Current directory structure: [docs/DIRECTORY_STRUCTURE.md](docs/DIRECTORY_STRUCTURE.md)
- Structure optimization log: [docs/STRUCTURE_OPTIMIZATION_LOG.md](docs/STRUCTURE_OPTIMIZATION_LOG.md)

## License

- This project is released under the [GPL-3.0 License](LICENSE).
- The visible `4-12` modules include Apache-2.0 licensed upstream code from `kejilion/sh` plus local adaptations. See [docs/UPSTREAM_ATTRIBUTION.md](docs/UPSTREAM_ATTRIBUTION.md).
