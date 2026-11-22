"""YB 6 under real Lua 5.1 with a stubbed WoW API and a fake Easy Controller 1.24 that records calls.
Usage: python3 tools/yb6_test.py addon/YagriverBinds
"""
import sys, os
from lupa import lua51

base = sys.argv[1]
here = os.path.dirname(os.path.abspath(__file__))
L = lua51.LuaRuntime(unpack_returned_tuples=True)
L.execute(open(os.path.join(here, "_stub_base.lua"), encoding="utf-8").read())
L.execute(r'''
UISpecialFrames = {}
FIND = function(text) for _, o in ipairs(FRAMES) do if o.text == text then return o end end end
function FINDATTR(k, v) local out = {} for _, o in ipairs(FRAMES) do if o.attr[k] == v then out[#out+1] = o end end return out end
-- spells: Spanish client, some ranks known
NAMES = { [768] = "Forma felina", [5487] = "Forma de oso", [9634] = "Forma de oso temible", [1066] = "Forma acuática",
  [783] = "Forma de viaje", [5215] = "Acecho", [1850] = "Carrera", [5229] = "Enfurecer", [29166] = "Enervar",
  [22812] = "Pielcorteza", [16689] = "Gracia de la naturaleza", [774] = "Rejuvenecimiento", [1058] = "Rejuvenecimiento",
  [1430] = "Rejuvenecimiento", [20484] = "Renacer", [2782] = "Deshacer maldición", [2893] = "Suprimir veneno",
  [8946] = "Curar veneno", [1126] = "Marca de lo salvaje", [5232] = "Marca de lo salvaje", [8936] = "Recrecimiento",
  [5185] = "Toque de sanación", [5176] = "Cólera", [8921] = "Fuego lunar", [339] = "Raíces enredadoras",
  [770] = "Fuego feérico", [467] = "Espinas", [18960] = "Teletransporte: Claro de la Luna", [458] = "Caballo marrón" }
KNOWN = { [768] = true, [5487] = true, [1066] = true, [5215] = true, [1850] = true, [5229] = true, [22812] = true,
  [16689] = true, [774] = true, [1058] = true, [20484] = true, [2782] = true, [8946] = true, [1126] = true, [5232] = true,
  [8936] = true, [5185] = true, [5176] = true, [8921] = true, [339] = true, [770] = true, [467] = true, [18960] = true }
BEST = { ["Rejuvenecimiento"] = 1058, ["Marca de lo salvaje"] = 5232 }
C_Spell = { GetSpellName = function(id) return NAMES[id] end,
  GetSpellInfo = function(x) if type(x) == "string" then local id = BEST[x]; if not id then for k, v in pairs(NAMES) do if v == x and KNOWN[k] then id = k end end end return id and { spellID = id } end return NAMES[x] and { spellID = x, name = NAMES[x] } end }
function IsPlayerSpell(id) return KNOWN[id] or false end
-- macros
MACROS, MACRO_ORDER = {}, {}
function GetMacroIndexByName(n) return MACROS[n] and MACROS[n].idx or 0 end
function GetMacroBody(n) return MACROS[n] and MACROS[n].body end
function GetMacroInfo(i) if type(i) == "string" then local m = MACROS[i]; return m and i, "icon", m and m.body end local n = MACRO_ORDER[i]; return n, "icon", n and MACROS[n].body end
local nextIdx = 1
function CreateMacro(n, icon, body, perChar) assert(not COMBAT) assert(#n <= 16, "name too long " .. n) assert(#body <= 255) MACROS[n] = { idx = nextIdx, body = body, perChar = perChar }; MACRO_ORDER[nextIdx] = n; nextIdx = nextIdx + 1 return nextIdx - 1 end
function EditMacro(idx, n, icon, body) assert(not COMBAT) for k, v in pairs(MACROS) do if v.idx == idx then v.body = body end end end
CreateMacro("YB Travel", "x", "#showtooltip\n/cast [swimming] Forma acuática; Forma de viaje", true)  -- came from the Deck
function SetOverrideBindingMacro(owner, prio, key, macro) assert(not COMBAT) OVERRIDES[key] = "MACRO " .. macro end
SAVED["CTRL-F9"] = "MULTIACTIONBAR5BUTTON12"
function GetActionInfo(slot) if slot == 156 then return "spell", 458 end end
-- fake Easy Controller 1.24
local S = { mapping = {}, replaced = { ["A:LTRT"] = "spell:999" }, modules = { sellJunk = false }, features = {}, reticle = { mode = "game" }, glyphStyle = "auto", myWheels = { list = {} } }
ECS = S
ECV = "1.24.0"
C_AddOns.GetAddOnMetadata = function(a, f) if a == "EasyController" and f == "Version" then return ECV end end
LOADED.EasyController = true
PUTS = {}
local MW = {}
function MW:List() return S.myWheels.list end
function MW:Get(id) for _, w in ipairs(S.myWheels.list) do if w.id == id then return w end end end
function MW:Create() local used = {} for _, w in ipairs(S.myWheels.list) do used[w.id] = true end for id = 1, 8 do if not used[id] then table.insert(S.myWheels.list, { id = id, name = "Rueda " .. id, slots = {} }) return id end end end
function MW:Rename(id, n) self:Get(id).name = n end
function MW:SetSlot(id, i, a) self:Get(id).slots[i] = a end
function MW:SetStyle(id, st) self:Get(id).style = st return 0 end
function MW:Delete(id) for i, w in ipairs(S.myWheels.list) do if w.id == id then table.remove(S.myWheels.list, i) end end for k, v in pairs(S.replaced) do if v == "wheel:" .. id then S.replaced[k] = nil end end end
local M = { BY_ID = { A = { id = "A" }, B = { id = "B" }, X = { id = "X" }, Y = { id = "Y" }, R3 = { id = "R3" } } }
function M:Enabled() return true end
function M:SetReplaced(i, l, a) S.replaced[i .. ":" .. l] = a end
function M:Apply() end
local Page = {}
function Page:Put(input, layer, action)
  assert(not COMBAT, "Put in combat")
  table.insert(PUTS, input.id .. ":" .. layer .. "=" .. action)
  -- R3's trigger layers stay locked until R3 alone holds something of ours
  if input.id == "R3" and layer ~= "" and not S.replaced["R3:"] then return false end
  S.replaced[input.id .. ":" .. layer] = action
  return true
end
ControllerKeyboard = { db = { settings = S }, Mapping = M, MapPage = Page, MyWheels = MW, Paddles = { Apply = function() end },
  Range = { Apply = function() RANGE_APPLIED = true end }, QuietErrors = { Apply = function() QE_APPLIED = true end },
  Reticle = { SetMode = function(self, m) S.reticle.mode = m end } }
function ControllerKeyboard:PickGlyphStyle(st) S.glyphStyle = st return true end
''')

YB = L.eval("{}")
load = L.eval("function(code, name, yb) local f, e = loadstring(code, name); assert(f, e); f('YagriverBinds', yb) end")
for line in open(os.path.join(base, "YagriverBinds.toc"), encoding="utf-8").read().split("\n"):
    line = line.strip()
    if line.endswith(".lua"):
        load(open(os.path.join(base, line), encoding="utf-8").read(), line, YB)
g = L.globals(); ex = L.execute; ev = L.eval
call = ev("function(yb, m, ...) return yb[m](yb, ...) end")
def yb(m, *a): return call(YB, m, *a)
ecall = ev("function(yb, m, ...) return yb.EC[m](yb.EC, ...) end")
def ec(m, *a):
    r = ecall(YB, m, *a)
    return r if isinstance(r, tuple) or m not in ("Ready", "Apply", "Undo") else (r, None)
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
ok, msg = yb("SetDevice", "deck")
check(ok and "6.1" in str(msg), "Deck says it comes in 6.1")
ok, msg = yb("ApplyMode", "deck")
check(not ok, "no Deck modes yet")
yb("SetDevice", "pc")

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
check(not ok and "1.25.0" in str(why), "refuses an unread version")
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
check(S.modules.sellJunk == True and S.modules.autoRepair == True and S.features.rangeTint == True and S.features.quietErrors == True, "options on")
check(g.RANGE_APPLIED == True and g.QE_APPLIED == True, "options applied by Easy Controller's own functions")
check(str(S.glyphStyle) == "switch" and str(S.reticle.mode) == "cycle", "Switch labels and OLED dot on the PC")
check(str(g.MACROS["YB Cat Prowl"].body) == "#showtooltip Acecho\n/cast !Forma felina\n/cast Acecho", "two-step macro in Spanish")
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
check(S.modules.sellJunk == False and S.modules.autoRepair is None and S.features.rangeTint is None, "options back")
check(str(S.glyphStyle) == "auto" and str(S.reticle.mode) == "game", "labels and dot back")
check(g.YagriverBindsCharDB.ec is None and ec("Applied") == False, "nothing left to undo")

# 11. window tabs, all devices
ex('LOG = {}')
for dev in ("pc", "deck", None):
    ex('YagriverBindsDB.device = %s' % (('"%s"' % dev) if dev else "nil"))
    for t in ("Inicio", "Armas", "Dispositivo", "Easy Controller", "Comprobar"):
        ex('local o = FIND("%s"); if o and o.scripts.OnClick then o.scripts.OnClick(o) end' % t)
check(not ev('LOGHAS("Error:")'), "every tab builds for PC, Deck and no device")
ex('YagriverBindsDB.device = "pc"')

# 12. never saves bindings, never deletes macros
src = "".join(open(os.path.join(base, f), encoding="utf-8").read() for f in os.listdir(base) if f.endswith(".lua"))
for bad in ["SaveBindings", "DeleteMacro", "SetBinding(", "SetBindingClick(", "SetBindingSpell", "SetBindingMacro("]:
    check(bad not in src, "never calls " + bad)

print("\n%d failures" % len(fails))
sys.exit(1 if fails else 0)
