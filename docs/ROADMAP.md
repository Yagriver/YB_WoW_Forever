# Roadmap

The full plan lives in the doc "YagriverBinds: PC + Moonlight edition plan".

1. Repository and YB Probe (PC): what Forever does on each pad combination, whether YB can take it over,
   chat from secure buttons, Edit Mode layouts, screen sizes. Gate: final combinations fixed.
2. PC edition core: modes PC / Switch with Auto, per-mode settings, panel, weapon set keys, override
   bindings, Windows installer. Gate: clean mode switches, nothing changes on the Deck.
3. Switch wheels: mockup, then Forms (R1 + R2), Emergencies (L1 + R2), Utility and chat (R1 + L2), and a
   Pad map tab. Gate: wheels work in combat over Moonlight.
4. Deck edition 6.0: override bindings with clean-up, controller toggle via the interface-style setting,
   mode re-applied at login, named layouts. Installed in the same round as phase 2.

Rules kept: installers delete only this project's files; no mouseover on emergencies; no /cancelform;
weapon swaps manual; mockups first; restart Steam after a Deck install.

## Probe results (2026-11-22, PC desk and Switch over Moonlight)

- Screens: desk 3440x1440 (ratio 2.39), Switch stream 1920x1080 (1.78). WoW follows the virtual display.
- Both used UI scale 0.85: per-mode scale is needed.
- Sync is on (synchronizeBindings 1, synchronizeConfig 1): all 25 Deck keys and 25 YB macros are on the PC.
- Edit Mode: only the Deck's layouts exist; the Switch used "SteamDeck at dock 1080".
- Forever's pad bindings sit in their own context (GamepadModeInGameCore), the same on every modifier:
  face and D-pad = gamepad action buttons, LB/RB = target modifiers, LT/RT = bar modifiers,
  L3 = autorun, R3 = ping, Select = UI focus, Start = radial. PADSOCIAL arrived once and is unbound.
- With a trigger held, buttons arrive as the plain key (LT is not Shift in the gamepad UI).
  Overrides on SHIFT-/CTRL-/ALT- combinations never fire; RT as Alt changes nothing.
- A priority override on the plain key catches L1, R1, L3 and R3 on press and release, and the secure
  code sees which triggers are held, also in combat. Taking a button removes its own job.
- The trigger must be pressed first. Chat test: inconclusive (probe bug). Stick read: not tested yet.

## Estado 2026-11-23 (6.1)
- Hecho: dispositivo Steam Deck en el addon único (teclas de la plantilla v5 como override, limpieza de
  las teclas guardadas de la 5.5 desde la Deck, mapa de la Deck), arreglo de Acecho/Carrera/Enfurecer,
  ping con `/aviso`, sin rojo fuera de alcance. La 5.5 queda en la etiqueta `deck-5.5`.
- Pendiente: pestaña "Mapa del mando" (maqueta esperando visto bueno), comprobar A/B en Moonlight y la
  montura de la barra 5 botón 12, subir a GitHub (falta la app de Claude en el repositorio).
