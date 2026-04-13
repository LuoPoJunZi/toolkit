# Upstream Attribution

This repository now includes a compatibility layer derived from the following upstream project:

- Project: [kejilion/sh](https://github.com/kejilion/sh)
- Upstream script source: `kejilion.sh`
- Scope mirrored into this repository: upstream main-menu `4-14` feature set and related submenu/helper logic
- Upstream license: Apache-2.0
- Snapshot basis used during integration: upstream repository state inspected on 2026-04-13

## Local Adaptations

The vendored compatibility layer in [`vendor/kejilion.sh`](../vendor/kejilion.sh) is not a byte-for-byte copy. It includes local changes required to make the code safely usable inside `LuoPo VPS Toolkit`:

- disabled upstream telemetry by forcing `ENABLE_STATS="false"`
- disabled upstream self-install / launcher-copy side effects when loaded as a library
- added `KEJILION_LIBRARY_MODE` guards so the upstream script can be sourced without auto-running its own main menu
- changed the upstream `kejilion()` return path so selecting `0` inside cloned menus exits back to the LuoPo Toolkit host menu when executed inside a subshell bridge

## Integration Layout

- host bridge: [`modules/kejilion_bridge.sh`](../modules/kejilion_bridge.sh)
- vendored upstream snapshot: [`vendor/kejilion.sh`](../vendor/kejilion.sh)
- LuoPo host menu entry wiring: [`core/menu.sh`](../core/menu.sh)

## Notes

- `LuoPo VPS Toolkit` remains licensed under GPL-3.0 as declared in the repository [`LICENSE`](../LICENSE).
- The mirrored compatibility layer keeps the upstream menu behavior as close as possible for future second-stage customization.
