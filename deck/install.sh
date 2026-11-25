#!/bin/bash
# Instalador de Yagriver Binds 6 para la Steam Deck: iconos + plantilla de Steam + addon (+ Easy Controller si falta).
# Ejecuta:  bash install.sh
# Solo reemplaza cosas de ESTE proyecto (carpeta YagriverBinds, wow_forever_druid*_neptune*.vdf, yb_*.png).
# Easy Controller solo se copia si no lo tienes; si ya está, no se toca.
HERE="$(cd "$(dirname "$0")" && pwd)"
STEAM="$HOME/.steam/steam"
FAIL=0
echo "== 1/4 Iconos"
ICONS="$STEAM/tenfoot/resource/images/library/controller/binding_icons"
mkdir -p "$ICONS" && rm -f "$ICONS"/yb_*.png
if cp "$HERE"/icons/yb_*.png "$ICONS"/; then echo "   OK: $(ls "$HERE"/icons | wc -l) iconos"; else echo "   FALLO"; FAIL=1; fi

echo "== 2/4 Plantilla de Steam (la misma v5 de siempre)"
TPL="$STEAM/controller_base/templates"
mkdir -p "$TPL"
rm -f "$TPL"/wow_forever_druida_neptune*.vdf "$TPL"/wow_forever_druid_neptune*.vdf
if cp "$HERE"/wow_forever_druid_neptune_v5.vdf "$TPL"/; then echo "   OK: plantilla copiada"; else echo "   FALLO"; FAIL=1; fi

ADDONS="$HOME/Games/prefixes/battlenet/wow/drive_c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns"
echo "== 3/4 Addon Yagriver Binds"
if [ -d "$ADDONS" ]; then
  if rm -rf "$ADDONS/YagriverBinds" && cp -r "$HERE/YagriverBinds" "$ADDONS/"; then echo "   OK: YagriverBinds 6.1.1 instalado"; else echo "   FALLO"; FAIL=1; fi
else
  echo "   FALLO: no encuentro la carpeta AddOns:"; echo "     $ADDONS"; echo "   Copia la carpeta YagriverBinds ahí a mano."; FAIL=1
fi

echo "== 4/4 Easy Controller"
if [ -d "$ADDONS" ]; then
  if [ -d "$ADDONS/EasyController" ]; then
    V=$(grep -i "^## Version" "$ADDONS/EasyController/EasyController.toc" 2>/dev/null | sed 's/.*: *//' | tr -d '\r')
    echo "   Ya lo tienes (versión ${V:-?}): no lo toco."
  elif [ -d "$HERE/EasyController" ]; then
    if cp -r "$HERE/EasyController" "$ADDONS/"; then echo "   OK: Easy Controller 1.24.0 instalado (el que viene en el paquete)"; else echo "   FALLO"; FAIL=1; fi
  else
    echo "   Falta Easy Controller y no viene en este paquete: instálalo a mano."
  fi
fi
echo
if [ "$FAIL" -eq 0 ]; then
  echo "Hecho. Reinicia Steam. En WoW: /reload. YB pasa solo tus ajustes de la 5.5."
else
  echo "Terminado CON ERRORES (mira arriba)."
fi
