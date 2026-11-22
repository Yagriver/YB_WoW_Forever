YB STEAM DECK v5.5 - WoW: Forever druid setup
===========================================
INSTALL (desktop mode, Konsole):   bash install.sh
Then: restart Steam > WoW controller settings > Browse Layouts > Templates > "... v5.3"
In game: /reload, open the addon (minimap paw or /yag), press "Apply binds".
The installer REPLACES the previous addon folder, layout and icons of this project only.

BUTTON MAP (same in both sets unless noted)
  Sticks, D-pad, A/B/X/Y, L1/R1, L2/R2, Start      native WoW: Forever gamepad
  Right pad                                        mouse, click = left click
  Left pad                                         scroll, click = right click
  L4  tap = Travel/Aquatic     hold = Dash         (Town set: hold = Ctrl)
  L5  tap = Bear               hold = Enrage       (Town set: hold = Shift)
  R4  tap = Cat                hold = Prowl
  R5  hold = R5 layer:
        right pad   Innervate / Barkskin / Nature's Grasp / Rejuvenation on me   (click)
        left pad    Map, Bags, Character, Spells, Talents, Social, Professions, Mount,
                    Chat + Prof. panel, YB menu (addon settings)                  (click)
        A B X Y     Rebirth, Remove Curse, Abolish/Cure Poison, Mark of the Wild
        D-pad up    Hearthstone
        D-pad down  open chat + Steam keyboard (type /r to reply to a whisper)
        D-pad left  caster / healing weapon set     D-pad right  feral weapon set
  L2  hold (light pull is enough) + left pad click   target Me / Party 1-4, then heal
  Select  tap = native, hold 0.6 s = switch Combat set <-> Town set

HEALING
  L1 (native) or L2 + left pad picks the friend; your heal buttons then heal that target.
  The YB heal macros (YB HealTouch, YB Regrowth, YB Rejuv) also heal whoever is under the
  mouse cursor if there is one, otherwise your target.

WEAPON SETS (addon Setup tab: wear a set, click Use equipped)
  Swaps are manual: R5 + D-pad left = caster set, R5 + D-pad right = feral set.
  Form keys and heals never change weapons (in combat an equip costs a global cooldown
  that would block the shift). A small two-line hint tells you when the weapon doesn't
  match the form; it never equips anything. Size and position: /yag > Device > Weapon hint
  (- / +, Move, Reset), saved separately for Handheld and Docked.

MENU KEYS the layout sends (must match your WoW key bindings):
  M map, Shift+B bags, J character, P spellbook, N talents, O social, K professions
  (YB keys: Ctrl+Shift+F11 chat panel, Ctrl+Shift+F12 YB menu)

ADDON WINDOW (YB menu, minimap paw or /yag)
  Setup     groups, weapon sets, Apply / Remove / Clean old macros
  Keybinds  every bind, its Deck button and its current state
  Device    Handheld / Docked, controller on/off (reloads the UI), UI scale, weapon hint
            First time: Controller > 'Find in options' (searches WoW's options for the
            'Enable Gamepad UI' checkbox). Plan B: Detect step 1 / step 2.
  Deck map  picture of the Deck with what every button does: Normal, Hold R5, Town set
