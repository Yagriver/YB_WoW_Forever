#!/bin/bash
# YB Steam Deck installer: icons + Steam layout + WoW addon.   Run:  bash install.sh
# It replaces previous versions of THIS project only (YagriverBinds folder, wow_forever_druid*_neptune*.vdf, yb_*.png).
HERE="$(cd "$(dirname "$0")" && pwd)"
STEAM="$HOME/.steam/steam"
FAIL=0
echo "== 1/3 Icons"
ICONS="$STEAM/tenfoot/resource/images/library/controller/binding_icons"
mkdir -p "$ICONS" && rm -f "$ICONS"/yb_*.png   # old icons of this project only
if cp "$HERE"/icons/yb_*.png "$ICONS"/; then echo "   OK: $(ls "$HERE"/icons | wc -l) icons copied"; else echo "   FAILED"; FAIL=1; fi

echo "== 2/3 Steam layout"
TPL="$STEAM/controller_base/templates"
mkdir -p "$TPL"
rm -f "$TPL"/wow_forever_druida_neptune*.vdf "$TPL"/wow_forever_druid_neptune*.vdf
if cp "$HERE"/wow_forever_druid_neptune_v5.vdf "$TPL"/; then echo "   OK: layout v5.3 copied (older versions of this layout removed)"; else echo "   FAILED"; FAIL=1; fi

echo "== 3/3 WoW addon"
ADDONS="$HOME/Games/prefixes/battlenet/wow/drive_c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns"
if [ -d "$ADDONS" ]; then
  if rm -rf "$ADDONS/YagriverBinds" && cp -r "$HERE/YagriverBinds" "$ADDONS/"; then echo "   OK: addon installed in $ADDONS"; else echo "   FAILED"; FAIL=1; fi
else
  echo "   FAILED: AddOns folder not found:"; echo "     $ADDONS"; echo "   Copy the YagriverBinds folder there by hand."; FAIL=1
fi
echo
if [ "$FAIL" -eq 0 ]; then
  echo "All done. Restart Steam, then: WoW > Controller Settings > Browse Layouts > Templates > v5.3"
  echo "In game: /reload, open the addon (minimap paw or /yag) and press Apply binds."
else
  echo "Finished WITH ERRORS (see above)."
fi
