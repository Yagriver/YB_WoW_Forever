#!/bin/bash
# Builds the PC and Steam Deck zips from the repository.  Usage: bash tools/package.sh <out dir> <EasyController dir>
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; OUT="$1"; EC="$2"
V=$(grep "^## Version" "$ROOT/addon/YagriverBinds/YagriverBinds.toc" | sed 's/.*: *//')
T=$(mktemp -d)
mkdir -p "$T/pc" "$T/deck"
cp -r "$ROOT/addon/YagriverBinds" "$ROOT/addon/install_pc.bat" "$ROOT/addon/LEEME.txt" "$T/pc/"
cp -r "$ROOT/addon/YagriverBinds" "$ROOT/deck/install.sh" "$ROOT/deck/LEEME_DECK.txt" "$ROOT/deck/icons" \
      "$ROOT/deck/wow_forever_druid_neptune_v5.vdf" "$T/deck/"
[ -n "$EC" ] && cp -r "$EC" "$T/deck/EasyController"
rm -f "$OUT/YB_${V}_PC.zip" "$OUT/YB_${V}_SteamDeck.zip"
(cd "$T/pc" && zip -qr "$OUT/YB_${V}_PC.zip" .)
(cd "$T/deck" && zip -qr "$OUT/YB_${V}_SteamDeck.zip" .)
rm -rf "$T"
ls -la "$OUT"/YB_${V}_*.zip
