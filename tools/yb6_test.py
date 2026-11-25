"""YB 6 under real Lua 5.1 with a stubbed WoW API and a fake Easy Controller 1.24 that records calls.
Usage: python3 tools/yb6_test.py addon/YagriverBinds
"""
import sys, os

base = sys.argv[1]
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _yb6_world import build
L, YB, g, ex, ev, yb, ec = build(base)
fails = []
def check(cond, what):
    print(("PASS " if cond else "FAIL ") + what)
    if not cond: fails.append(what)

# 1. first login: no device yet
ex('FIRE("PLAYER_LOGIN"); ADVANCE(2)')
check(ev('YagriverBindsFrame.shown') == True, "window opens to choose the device")
check(ev('LOGHAS("elige el dispositivo")'), "asks for the device")
check(g.CVARS["InputDeviceInterfaceStyle"] == "0" and g.RELOADS == 0, "nothing changed before choosing")

# 2. choose PC at the desk
ok, msg = yb("SetDevice", "pc")
check(ok and yb("ModeKey") == "pc", "PC device, PC mode at 3440x1440")
ok, msg = yb("ApplyMode", "deck")
check(not ok, "PC device refuses Deck modes")
check(str(g.SAVED["F1"]) == "MACRO YB Travel" and g.SAVES == 0, "PC never touches the Deck's saved keys")

# 3. weapons: captured sets write the shared macros
ok, msg = yb("CaptureWeapons", "caster")
check(ok and str(g.MACROS["YB Caster Set"].body) == "#showtooltip\n/equipslot 16 item:200\n/equipslot 17 item:201", "caster macro body")
check(g.MACROS["YB Caster Set"].perChar == True, "set macros are per character, like the Deck's")
ex('EQUIP[16] = 100; EQUIP[17] = nil')
yb("CaptureWeapons", "feral")
check(str(g.MACROS["YB Feral Set"].body) == "#showtooltip\n/equipslot 16 item:100", "feral macro body")
ok, msg = yb("SetKey", "caster", "6")
check(str(g.OVERRIDES["6"]) == "MACRO YB Caster Set", "key 6 runs YB Caster Set (override only)")
yb("SetKey", "feral", "7")
check(str(g.OVERRIDES["7"]) == "MACRO YB Feral Set", "key 7 runs YB Feral Set")

# 4. Easy Controller: not at the desk (keyboard UI)
ok, why = ec("Ready")
check(not ok and "Moonlight" in str(why), "refuses with the keyboard UI: " + str(why))
ex('SCREEN = {1920, 1080}; FIRE("DISPLAY_SIZE_CHANGED"); ADVANCE(1.6)')
ex('for i = 1, 70 do UPDATE(YagriverBindsBanner) end; ADVANCE(3.1)')
check(yb("ModeKey") == "moonlight" and g.CVARS["InputDeviceInterfaceStyle"] == "1", "stream starts: Moonlight mode, gamepad UI")
ex('FIRE("PLAYER_LOGIN"); ADVANCE(2)')
ok, why = ec("Ready")
check(ok, "ready in Moonlight mode")
ex('ECV = "1.25.0"')
ok, why = ec("Ready")
check(ok and "1.25.0" in str(ec("VersionWarning")), "a newer version is allowed, with a warning")
ex('ECV = "1.24.0"')

# 5. preview
lines = [str(x) for x in ec("Preview").values()]
print("   " + "\n   ".join(lines))
check(any("ZL + ZR + abajo (A)  Emergencias (mini de stick): Enervar, Pielcorteza" in l for l in lines), "preview: Emergencias on A")
check(any("Caballo marrón" in l for l in lines), "preview: the mount from bar 5 button 12")
check(any("R3  sanador: Rejuvenecimiento" in l for l in lines), "preview: healer on R3")

# 6. apply
ok, msg = ec("Apply")
print("   " + str(msg))
check(ok, "apply succeeds")
S = g.ECS
wheels = {str(w.name): w for w in S.myWheels.list.values()}
check(set(wheels) == {"YB Emergencias", "YB Formas", "YB Utilidad", "YB Habilidades"}, "four YB wheels")
em, fo, ut, ab = wheels["YB Emergencias"], wheels["YB Formas"], wheels["YB Utilidad"], wheels["YB Habilidades"]
check(em.style == "stick" and fo.style == "stick" and ab.style == "stick" and ut.style is None, "mini stick wheels, Utilidad big")
check(str(em.slots[1]) == "spell:29166" and str(em.slots[4]) == "macro:YB Rejuv Self" and str(em.slots[8]) == "spell:5232", "Emergencias slots (MotW at its best rank)")
check(str(fo.slots[2]) == "macro:YB Cat Prowl" and str(fo.slots[4]) == "spell:5487" and str(fo.slots[7]) == "macro:YB Caster Set", "Formas slots (Bear while Dire Bear is unknown)")
check(str(ut.slots[1]) == "item:6948" and str(ut.slots[2]) == "spell:458" and str(ut.slots[3]) == "macro:YB Ping", "Utilidad slots")
check(ab.slots[7] is None and str(ab.slots[6]) == "spell:18960", "Habilidades: six spells, two free")
R = S.replaced
check(str(R["A:LTRT"]) == "wheel:%d" % em.id and str(R["X:LTRT"]) == "wheel:%d" % fo.id and str(R["Y:LTRT"]) == "wheel:%d" % ut.id and str(R["B:LTRT"]) == "wheel:%d" % ab.id, "wheels on ZL+ZR+A/X/Y/B")
check(str(R["R3:"]) == "wheel:party:1058" and str(R["R3:LT"]) == "wheel:party:8936" and str(R["R3:RT"]) == "wheel:party:5185" and str(R["R3:LTRT"]) == "wheel:party:20484", "healer on R3 layers, best ranks")
puts = [str(x) for x in g.PUTS.values()]
check(puts.index("R3:=wheel:party:1058") < puts.index("R3:LT=wheel:party:8936"), "R3 alone is set before its trigger layers")
check(S.modules.sellJunk == True and S.modules.autoRepair == True and S.features.rangeTint is None and S.features.quietErrors == True, "options on, range tint left alone")
check(g.QE_APPLIED == True, "options applied by Easy Controller's own functions")
check(str(S.glyphStyle) == "switch" and str(S.reticle.mode) == "cycle", "Switch labels and OLED dot on the PC")
check(str(g.MACROS["YB Cat Prowl"].body) == "#showtooltip Acecho\n/cast [noform:3] Forma felina; Acecho", "Prowl: cat form if not in it, else Prowl")
check(str(g.MACROS["YB Bear Enrage"].body) == "#showtooltip Enfurecer\n/cast [noform:1] Forma de oso; Enfurecer", "Enrage: bear index 1")
check(str(g.MACROS["YB Ping"].body) == "/aviso [@target,exists][]", "ping uses the client's own command (/aviso in Spanish)")
check(str(g.MACROS["YB Travel"].body) == "#showtooltip\n/cast [swimming] Forma acuática; Forma de viaje", "Deck's YB Travel left as it was")
check("ControllerKeyboardPhrasesToggle LeftButton true" in str(g.MACROS["YB EC Frases"].body), "quick phrases macro")
check(g.MACROS["YB Rejuv Self"] is not None, "YB Rejuv Self created when missing")
check(ec("Applied") == True, "remembered as applied")

# 7. again: no duplicates, first backup kept
n_before = len(list(S.myWheels.list.values()))
ec("Apply")
check(len(list(S.myWheels.list.values())) == n_before, "running it again makes no new wheels")
b = g.YagriverBindsCharDB.ec
check(str(b.replaced["A:LTRT"]) == "spell:999", "backup keeps what A had before YB")

# 7b. forms change (Travel learned before Cat): macros follow the new index
ex('FORMS = { 5487, 1066, 783, 768 }; FIRE("UPDATE_SHAPESHIFT_FORMS")')
check(str(g.MACROS["YB Cat Prowl"].body) == "#showtooltip Acecho\n/cast [noform:4] Forma felina; Acecho", "Prowl macro follows the cat's new index")
ex('FORMS = { 5487, 1066, 768 }; FIRE("UPDATE_SHAPESHIFT_FORMS")')
# 7c. a 6.0 install that turned range tint on: 6.1 turns it off again at login
ex('ECS.features.rangeTint = true; YagriverBindsCharDB.ec.options["features.rangeTint"] = false; FIRE("PLAYER_LOGIN"); ADVANCE(2)')
check(g.ECS.features.rangeTint == False and g.YagriverBindsCharDB.ec.options["features.rangeTint"] is None, "6.0's range tint switched back off")

# 8. a new rank is learned
ex('KNOWN[1430] = true; BEST["Rejuvenecimiento"] = 1430; FIRE("SPELLS_CHANGED"); ADVANCE(2.5)')
check(str(S.replaced["R3:"]) == "wheel:party:1430", "healer Rejuvenation moves to the new rank")

# 9. combat
ex('COMBAT = true')
ok, why = ec("Apply")
check(not ok, "no preparing in combat")
ex('COMBAT = false')

# 10. undo
ok, msg = ec("Undo")
check(ok, "undo")
check(len(list(S.myWheels.list.values())) == 0, "YB wheels deleted")
check(str(S.replaced["A:LTRT"]) == "spell:999" and S.replaced["R3:"] is None and S.replaced["X:LTRT"] is None, "buttons back as they were")
check(S.modules.sellJunk == False and S.modules.autoRepair is None and S.features.rangeTint == False, "options back")
check(str(S.glyphStyle) == "auto" and str(S.reticle.mode) == "game", "labels and dot back")
check(g.YagriverBindsCharDB.ec is None and ec("Applied") == False, "nothing left to undo")

# 11. window tabs, all devices
ex('LOG = {}')
for dev in ("pc", "deck", None):
    ex('YagriverBindsDB.device = %s' % (('"%s"' % dev) if dev else "nil"))
    for t in ("Inicio", "Armas", "Dispositivo", "Easy Controller", "Comprobar", "Mapa de la Deck"):
        ex('local o = FIND("%s"); if o and o.scripts.OnClick then o.scripts.OnClick(o) end' % t)
check(not ev('LOGHAS("Error:")'), "every tab builds for PC, Deck and no device")
ex('YagriverBindsDB.device = "pc"')

# 12. never saves bindings, never deletes macros
src = "".join(open(os.path.join(base, f), encoding="utf-8").read() for f in os.listdir(base) if f.endswith(".lua") and f != "Deck.lua")
for bad in ["SaveBindings", "DeleteMacro", "SetBinding(", "SetBindingClick(", "SetBindingSpell", "SetBindingMacro("]:
    check(bad not in src, "never calls " + bad + " (outside the Deck cleanup)")

print("\n%d failures" % len(fails))
sys.exit(1 if fails else 0)
