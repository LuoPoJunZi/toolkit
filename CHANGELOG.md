# Changelog

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
