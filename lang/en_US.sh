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
  [menu_0]="0. Exit"
  [prompt_select]="Select an option: "
  [prompt_press_enter]="Press Enter to continue..."
  [prompt_confirm]="Confirm? (y/N): "
  [invalid]="Invalid option"
  [bye]="Bye"
)
