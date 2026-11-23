"""Shared world for the YB 6 tests: real Lua 5.1, stubbed WoW API, fake Easy Controller 1.24."""
import os
from lupa import lua51
here = os.path.dirname(os.path.abspath(__file__))

def build(base, before_load=""):
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

    L.execute(r'''
    function SetOverrideBindingSpell(owner, prio, key, spell) assert(not COMBAT) OVERRIDES[key] = "SPELL " .. spell end
    function SetOverrideBinding(owner, prio, key, cmd) assert(not COMBAT) OVERRIDES[key] = cmd end
    SAVES = 0
    function SetBinding(key, action) assert(not COMBAT) SAVED[key] = action end
    function SaveBindings(set) SAVES = SAVES + 1 end
    function GetCurrentBindingSet() return 1 end
    function GetNumShapeshiftForms() return #FORMS end
    SLASH_PING1 = "/aviso"
    function GetNumMacros() local a, c = 0, 0 for _, m in pairs(MACROS) do if m.perChar then c = c + 1 else a = a + 1 end end return a, c end
    ''')
    L.execute(before_load)
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

    return L, YB, g, ex, ev, yb, ec
