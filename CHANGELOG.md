# Changelog

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
