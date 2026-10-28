#!/usr/bin/env bash
# Copies the addon into the WoW: Forever AddOns folder.
set -euo pipefail
DEST="/mnt/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/Guildprint"
cd "$(dirname "$0")"
if command -v rsync >/dev/null; then
  rsync -a --delete Guildprint/ "$DEST/"
else
  rm -rf "$DEST" && cp -r Guildprint "$DEST"
fi
echo "Deployed to $DEST"
