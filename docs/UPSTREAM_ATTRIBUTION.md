# Upstream Attribution

This repository includes locally modularized functionality derived from the following upstream project:

- Project: [kejilion/sh](https://github.com/kejilion/sh)
- Upstream script source: `kejilion.sh`
- Scope mirrored into this repository: upstream main-menu `4-14` feature set and related submenu/helper logic
- Upstream license: Apache-2.0
- Snapshot basis used during integration: upstream repository state inspected on 2026-04-13

## Local Adaptations

The vendored reference snapshot in [`vendor/luopo.sh`](../vendor/luopo.sh) is not a byte-for-byte copy. It includes local changes that were used during the migration into `LuoPo VPS Toolkit`:

- disabled upstream telemetry by forcing `ENABLE_STATS="false"`
- disabled upstream self-install / launcher-copy side effects when loaded as a library
- added `KEJILION_LIBRARY_MODE` guards so the upstream script can be sourced without auto-running its own main menu
- changed the upstream `kejilion()` return path so selecting `0` inside cloned menus exits back to the LuoPo Toolkit host menu when executed inside a subshell bridge
- migrated active menu execution into native `modules/luopo/` files

## Integration Layout

- LuoPo-native menu entry layer: [`modules/entries.sh`](../modules/entries.sh)
- LuoPo-native feature modules: [`modules/luopo/`](../modules/luopo/)
- vendored upstream reference/backup snapshot: [`vendor/luopo.sh`](../vendor/luopo.sh)
- LuoPo host menu entry wiring: [`core/menu.sh`](../core/menu.sh)

## Notes

- `LuoPo VPS Toolkit` remains licensed under GPL-3.0 as declared in the repository [`LICENSE`](../LICENSE).
- Active menu routing and business logic now live in LuoPo-native modules.
- `vendor/luopo.sh` is retained as attribution, audit trail, and emergency reference material rather than a normal runtime dependency.
