"""YB 6.1 on the Steam Deck: 5.5 settings migrate, Steam layout keys become override bindings,
the 5.5 saved keys are removed once (keeping what was there before 5.5 and anything of yours).
Usage: python3 tools/yb61_deck_test.py addon/YagriverBinds
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _yb6_world import build

base = sys.argv[1]
BEFORE = r'''
SCREEN = { 1280, 800 }
CVARS.InputDeviceInterfaceStyle = "1"
-- what Deck 5.5 left on disk
YagriverBindsDB = { mode = "handheld", padSetting = "PROXY_GAMEPAD", modes = {
  handheld = { pad = true, scale = 0.9, hint = { scale = 1.6, x = 0.5, y = 0.8 } },
  docked = { pad = false, scale = 0.75, hint = { scale = 1.1, x = 0.4, y = 0.7 } } } }
YagriverBindsCharDB = { applied = true, weaponHint = true, groups = {}, swap = {},
  weapons = { feral = { mh = 100 }, caster = { mh = 200, oh = 201 } },
  backup = { F1 = "TARGETSELF", F2 = "TARGETPARTYMEMBER1", ["CTRL-F1"] = "" } }
-- what Deck 5.5 saved in the bindings (synced to the PC by Blizzard)
SAVED = {
  F1 = "MACRO YB Travel", F2 = "MACRO YB Bear", F3 = "MACRO YB Cat",
  ["SHIFT-F1"] = "CLICK YBClickDash:LeftButton", ["SHIFT-F2"] = "CLICK YBClickEnrage:LeftButton", ["SHIFT-F3"] = "CLICK YBClickProwl:LeftButton",
  ["CTRL-F1"] = "SPELL Enervar", ["CTRL-F2"] = "SPELL Pielcorteza", ["CTRL-F3"] = "SPELL Gracia de la naturaleza",
  ["CTRL-F4"] = "MACRO YB Rejuv Self", ["CTRL-F5"] = "SPELL Renacer", ["CTRL-F6"] = "SPELL Deshacer maldición",
  ["CTRL-F7"] = "SPELL Curar veneno",
  ["CTRL-F8"] = "MACRO Mi macro",                 -- changed by hand: yours, kept
  ["CTRL-F9"] = "MULTIACTIONBAR5BUTTON12",         -- the mount, bound by you: kept
  ["CTRL-F10"] = "MACRO YB Hearth", ["CTRL-SHIFT-F5"] = "MACRO YB Caster Set", ["CTRL-SHIFT-F6"] = "MACRO YB Feral Set",
  ["CTRL-SHIFT-F11"] = "MACRO YB Panel", ["CTRL-SHIFT-F12"] = "MACRO YB Settings",
  ["CTRL-SHIFT-1"] = "TARGETSELF", ["CTRL-SHIFT-2"] = "TARGETPARTYMEMBER1", ["CTRL-SHIFT-3"] = "TARGETPARTYMEMBER2",
  ["CTRL-SHIFT-4"] = "TARGETPARTYMEMBER3", ["CTRL-SHIFT-5"] = "TARGETPARTYMEMBER4",
  ["SHIFT-Q"] = "MULTIACTIONBAR1BUTTON1",
}
'''
L, YB, g, ex, ev, yb, ec = build(base, BEFORE)
fails = []
def check(cond, what):
    print(("PASS " if cond else "FAIL ") + what)
    if not cond: fails.append(what)

# 1. first login of 6.1 on the Deck
ex('FIRE("PLAYER_LOGIN"); ADVANCE(3)')
G = g.YagriverBindsDB
check(str(G.device) == "deck" and yb("ModeKey") == "deck", "5.5 data: Steam Deck chosen, Deck mode")
check(G.modes.deck.scale == 0.9 and G.modes.deck.hint.scale == 1.6 and str(G.modes.deck.style) == "1", "Deck mode keeps its 5.5 scale, hint, controller on")
check(G.modes.dock.scale == 0.75 and str(G.modes.dock.style) == "0" and G.modes.handheld.scale == 0.9, "Dock mode from 'docked'; 5.5 entries kept for a fallback")
check(g.RELOADS == 0 and g.CVARS["uiScale"] == "0.9", "no reload needed, scale applied")
check(ev('LOGHAS("pasados a la 6.1")'), "tells about the migration")

O = g.OVERRIDES
check(str(O["F3"]) == "MACRO YB Cat" and str(O["F1"]) == "MACRO YB Travel", "back buttons: forms")
check(str(O["SHIFT-F3"]) == "CLICK YBClickProwl:LeftButton", "R4 hold: Prowl button")
check(str(O["CTRL-F1"]) == "SPELL Enervar" and str(O["CTRL-F7"]) == "SPELL Curar veneno", "R5 spells by name")
check(str(O["CTRL-SHIFT-1"]) == "TARGETSELF" and str(O["CTRL-SHIFT-5"]) == "TARGETPARTYMEMBER4", "party targets")
check(str(O["CTRL-SHIFT-F11"]) == "MACRO YB EC Frases" and str(O["CTRL-SHIFT-F12"]) == "MACRO YB Ajustes", "old panel key opens EC phrases, YB menu key opens YB")
check(str(O["CTRL-SHIFT-F5"]) == "MACRO YB Caster Set" and str(O["CTRL-F10"]) == "MACRO YB Hearth", "weapons and hearthstone")
check(O["CTRL-F9"] is None, "mount key not touched")
n = len([k for k in O.keys()])
check(n == 24, "24 Steam layout keys (got %d)" % n)
prowl = g.YBClickProwl
check(str(prowl.attr["type"]) == "spell" and str(prowl.attr["spell"]) == "Acecho", "hidden Prowl button casts Acecho")

S = g.SAVED
check(str(S["F1"]) == "TARGETSELF" and str(S["F2"]) == "TARGETPARTYMEMBER1", "saved F1/F2 back to what they had before 5.5")
check(S["F3"] is None and S["CTRL-F1"] is None and S["SHIFT-F3"] is None and S["CTRL-SHIFT-F12"] is None, "other 5.5 saved keys removed")
check(str(S["CTRL-F8"]) == "MACRO Mi macro" and str(S["CTRL-F9"]) == "MULTIACTIONBAR5BUTTON12" and str(S["SHIFT-Q"]) == "MULTIACTIONBAR1BUTTON1", "your own keys kept")
check(g.SAVES == 1 and G.cleaned == 23, "saved once, 23 keys cleaned (got %s)" % G.cleaned)

M = g.MACROS
check(str(M["YB Cat"].body) == "#showtooltip\n/cast Forma felina" and str(M["YB Bear"].body) == "#showtooltip\n/cast Forma de oso", "form macros")
check(str(M["YB Hearth"].body) == "#showtooltip\n/use item:6948" and M["YB Ajustes"] is not None and M["YB EC Frases"] is not None, "key macros exist")
check(str(M["YB Caster Set"].body) == "#showtooltip\n/equipslot 16 item:200\n/equipslot 17 item:201", "weapon set from the 5.5 saved weapons")

# 2. login again: nothing more to clean
ex('FIRE("PLAYER_LOGIN"); ADVANCE(3)')
check(g.SAVES == 1, "second login saves nothing")
check(len([k for k in g.OVERRIDES.keys()]) == 24, "keys back after login")

# 3. weapon hint shows the Deck way
ex('FORM = 3; EQUIP[16] = 200; YagriverBinds_dummy = 1')
ex('local YBt = ...', ) if False else None
L.eval('function(yb) yb.UpdateWeaponHint() end')(YB)
check(ev('FIND("R5 + cruceta derecha") ~= nil'), "hint: R5 + D-pad right for the feral set")
ex('FORM = 0')

# 4. Easy Controller: ready in Deck mode
ok, why = ec("Ready")
check(ok, "Easy Controller can be prepared in Deck mode: " + str(why))
# 4a. a newer Easy Controller (1.26) whose wheel styles fail half-way: error caught, Undo possible
ex('ECV = "1.26.0"; REAL_SETSTYLE = ControllerKeyboard.MyWheels.SetStyle; ControllerKeyboard.MyWheels.SetStyle = function() error("changed") end')
ok, msg = ec("Apply")
check(not ok and "a medias" in str(msg) and "1.26.0" in str(msg), "half-way error reported with the version warning")
check(ec("Applied") == True, "Undo available after the half-way error")
ok, msg = ec("Undo")
check(ok, "Undo after the error: " + str(msg))
ex('ControllerKeyboard.MyWheels.SetStyle = REAL_SETSTYLE')
# 4b. the newer version working: prepared, with the warning
ok, msg = ec("Apply")
check(ok and "1.26.0" in str(msg), "newer version prepared, warning in the message")
ex('ECV = "1.24.0"')
ok, msg = ec("Apply")
check(ok and "1.24" not in str(msg) and str(g.ECS.reticle.mode) == "cycle" and str(g.ECS.glyphStyle) == "auto", "OLED dot on the Deck, labels left alone")

# 5. dock by hand: keyboard UI, keys stay
ok, msg = yb("ApplyMode", "dock")
ex('ADVANCE(3.5)')
check(ok and g.CVARS["InputDeviceInterfaceStyle"] == "0" and g.RELOADS == 1, "Dock: keyboard UI, reload")
ex('SCREEN = { 1920, 1080 }; FIRE("PLAYER_LOGIN"); ADVANCE(3)')
check(yb("ModeKey") == "dock" and g.CVARS["uiScale"] == "0.75", "after reload: Dock mode, its scale")
check(str(g.OVERRIDES["F3"]) == "MACRO YB Cat", "Steam layout keys also when docked")
ok, msg = yb("SetModeStyle", True)
ex('ADVANCE(3.5)')
check(ok and str(G.modes.dock.style) == "1" and g.CVARS["InputDeviceInterfaceStyle"] == "1", "Dock can use the gamepad UI too")
ex('FIRE("PLAYER_LOGIN"); ADVANCE(3)')
ok, msg = yb("ApplyMode", "pc")
check(not ok, "Deck refuses PC modes")

# 6. Dire Bear learned: the keys and macros follow (deferred in combat)
ex('KNOWN[9634] = true; COMBAT = true; FIRE("SPELLS_CHANGED"); ADVANCE(2.5)')
check(str(g.MACROS["YB Bear"].body) == "#showtooltip\n/cast Forma de oso", "nothing changes in combat")
ex('COMBAT = false; FIRE("PLAYER_REGEN_ENABLED")')
check(str(g.MACROS["YB Bear"].body) == "#showtooltip\n/cast Forma de oso temible", "after combat: YB Bear casts Dire Bear")

# 7. window: Deck map tab and its views
ex('LOG = {}')
for t in ("Inicio", "Armas", "Dispositivo", "Easy Controller", "Comprobar", "Mapa de la Deck"):
    ex('local o = FIND("%s"); if o and o.scripts.OnClick then o.scripts.OnClick(o) end' % t)
check(ev('FIND("Apuntar a aliado") ~= nil'), "Deck map: normal view labels")
def view(v): ex('local o = FIND("%s"); if o and o.scripts.OnClick then o.scripts.OnClick(o) end' % v)
view("Mantener R5")
check(ev('FIND("A = Renacer") ~= nil'), "Deck map: R5 view")
view("L2 + R2")
check(ev('FIND("A = Emergencias") ~= nil'), "Deck map: L2 + R2 view shows the wheels")
view("Juego Ciudad"); view("Normal")
check(ev('FIND("Clic = modo sanador") ~= nil'), "Deck map: R3 = healer once EC is prepared")
check(not ev('LOGHAS("Error:")'), "every tab and view builds on the Deck")

print("\n%d failures" % len(fails))
sys.exit(1 if fails else 0)
