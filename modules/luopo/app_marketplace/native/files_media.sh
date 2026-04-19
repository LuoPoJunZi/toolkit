#!/usr/bin/env bash
set -euo pipefail

LUOPO_APP_MARKETPLACE_FILES_MEDIA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/files_media"

# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_FILES_MEDIA_DIR/notes_bookmarks.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_FILES_MEDIA_DIR/file_storage_sync.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_FILES_MEDIA_DIR/media_gallery.sh"
# shellcheck disable=SC1091
source "$LUOPO_APP_MARKETPLACE_FILES_MEDIA_DIR/docs_dev_data.sh"
