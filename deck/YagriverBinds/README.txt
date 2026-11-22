YAGRIVER BINDS 5.5 - how it works and how to change it
======================================================
Nothing is created, bound or deleted until you click a button in the addon window
(minimap paw, /yag, or R5 + left pad "YB menu").

DEVICE TAB (instant, shared by all characters, not in combat)
  Handheld / Docked   each mode remembers controller on/off and its own UI scale
  Controller          Forever's 'Enable Gamepad UI': found once with 'Find in options'
                      (plan B: Detect, 2 steps), then switched with a UI reload
  UI scale  - / +     0.05 steps (CVar uiScale), saved into the active mode
  Right stick camera  stops WoW's cursor from taking the right stick in menus

  Apply binds       creates/updates the YB macros and binds the keys the Steam layout sends.
                    Never deletes anything. Run it again after: learning a new form,
                    changing weapon sets, or changing a tick box.
  Remove binds      unbinds those keys and puts back what they did before. Macros are kept.
  Clean old macros  deletes macros left by OLDER versions of this addon (two clicks).
                    A macro is deleted only if its name AND its content match what the old
                    version created; anything you wrote or edited is kept.

YB panel (/yagpanel, R5 + left pad "Chat + Prof.", or right-click the minimap paw)
  Pick a channel, click a phrase: it is sent. Each phrase is a real macro ("YB Say 1"...).
  To change a phrase: /macro, edit the text after "/p " (keep the channel part).
  Professions you know appear as buttons. The panel does not open in combat.

FILES
  Core.lua             engine - no need to touch
  DeckMap.lua          Deck map tab: button texts are in LABELS / VIEWS at the top
  Media\              Deck pictures and menu icons (TGA)
  UI.lua, Panel.lua    windows - no need to touch
  Hint.lua             quiet weapon hint (on/off in Setup; size/position in Device)
  Profiles\Common.lua  shared binds, chat channels, default phrases, profession list
  Profiles\Druid.lua   druid binds
  YagriverBinds.toc    list of files to load - add new profiles here

CHANGE A KEY OR A SPELL
  Edit key = "..." or the spell id in the profile file, /reload, Apply binds.
  The Steam layout must send the same key. Spell ids: the number in the wowhead.com address.

ADD A CLASS (example: Priest)
  1. Copy Profiles\Druid.lua to Profiles\Priest.lua
  2. Change "DRUID" to "PRIEST" and replace the binds.
  3. Add the line  Profiles\Priest.lua  to YagriverBinds.toc (before UI.lua).
  With no profile for a class, Apply is disabled and nothing changes.

BIND TYPES
  { type="spell",   key="CTRL-F1", spell={29166}, label="Innervate" }      key -> spell (your target)
  { type="click",   key="SHIFT-F3", spell={5215}, label="Prowl" }          key -> hidden action button (fires on key down)
  { type="command", key="CTRL-SHIFT-1", command="TARGETSELF", label=".." } key -> a WoW key command
  { type="macro",   key=.., name="YB Hearth", body="/use item:6948", overwrite=true }
  { type="form",    ... }   form key with optional weapon swap (see Druid.lua)
  { type="caster",  name="YB Regrowth", spell={8936}, target="help" }      heal/damage macro, no key = for your bars
  { type="info",    key="M", label=".." }  only listed in the Keybinds tab, never applied
