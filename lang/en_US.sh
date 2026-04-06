#!/usr/bin/env bash
set -euo pipefail

declare -A I18N=(
  [title_main]="Toolkit VPS one-click toolbox"
  [menu_1]="1. System information"
  [menu_2]="2. System update"
  [menu_3]="3. System cleanup"
  [menu_4]="4. One-click scripts"
  [menu_5]="5. Docker management"
  [menu_00]="00. Script self-update"
  [menu_88]="88. Uninstall toolkit"
  [menu_0]="0. Exit"
  [menu_label_1]="System info"
  [menu_label_2]="Full update"
  [menu_label_3]="System cleanup"
  [menu_label_4]="One-click scripts"
  [menu_label_5]="Docker management"
  [menu_label_99]="Update toolkit"
  [menu_label_88]="Uninstall toolkit"
  [menu_label_0]="Exit"
  [prompt_select]="Select an option: "
  [prompt_press_enter]="Press Enter to continue..."
  [prompt_confirm]="Confirm? (y/N): "
  [invalid]="Invalid option"
  [bye]="Bye"
)
