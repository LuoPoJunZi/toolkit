# Changelog

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
