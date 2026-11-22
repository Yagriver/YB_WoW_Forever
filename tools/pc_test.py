"""Runs the PC edition under real Lua 5.1 with a stubbed WoW API and checks its behaviour.
Usage: python3 tools/pc_test.py pc/YagriverBindsPC
"""
import sys, os
from lupa import lua51

base = sys.argv[1]
L = lua51.LuaRuntime(unpack_returned_tuples=True)
L.execute(r'''
LOG = {}
local now, clock = 100, 1000
function GetTime() return now end
function time() return clock end
function ADVANCE(s) now = now + s; clock = clock + s; RUNTIMERS() end
function print(...) local t = {} for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end LOG[#LOG+1] = table.concat(t, " ") end
function LOGHAS(s) for _, l in ipairs(LOG) do if l:find(s, 1, true) then return true end end return false end
format = string.format
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
tinsert = table.insert
function date() return "2026-11-22 22:00" end
SCREEN = { 3440, 1440 }
function GetPhysicalScreenSize() return SCREEN[1], SCREEN[2] end
CVARS = { InputDeviceInterfaceStyle = "0", uiScale = "0.85", useUiScale = "1", GamePadEnable = "1",
  GamePadCursorAutoEnable = "1", GamePadCursorAutoDisableSticks = "2", ActionButtonUseKeyDown = "1" }
C_CVar = { GetCVar = function(n) return CVARS[n] end, SetCVar = function(n, v) CVARS[n] = tostring(v) return true end,
  GetCVarBool = function(n) return CVARS[n] == "1" end }
COMBAT = false
function InCombatLockdown() return COMBAT end
RELOADS = 0
function ReloadUI() RELOADS = RELOADS + 1 end
TIMERS = {}
C_Timer = {
  After = function(s, fn) table.insert(TIMERS, { at = now + s, fn = fn }) end,
  NewTimer = function(s, fn) local t = { at = now + s, fn = fn } function t:Cancel() self.cancelled = true end table.insert(TIMERS, t) return t end,
}
function RUNTIMERS()
  local again = true
  while again do
    again = false
    for i, t in ipairs(TIMERS) do
      if t.at <= now then table.remove(TIMERS, i); if not t.cancelled then t.fn() end; again = true; break end
    end
  end
end
CLASS = "DRUID"
function UnitClass() return "Druida", CLASS end
EQUIP = { [16] = 200, [17] = 201 }
function GetInventoryItemID(_, s) return EQUIP[s] end
C_Item = { GetItemNameByID = function(id) return ({ [100] = "Staff of Bears", [200] = "Wand of Light", [201] = "Holy Book" })[id] end,
  GetItemIconByID = function() return 1 end }
FORM = 0
FORMS = { 5487, 1066, 768 }
function GetShapeshiftForm() return FORM end
function GetShapeshiftFormInfo(i) return "icon", false, true, FORMS[i] end
function IsPlayerSpell(id) return id == 2550 end
C_Spell = { GetSpellName = function(id) return ({ [2550] = "Cocina" })[id] end }
SAVED = { ["F1"] = "MACRO YB Travel", ["CTRL-F1"] = "SPELL Enervar", ["SHIFT-Q"] = "MULTIACTIONBAR1BUTTON1" }
OVERRIDES = {}
function GetBindingAction(k, o) if o and OVERRIDES[k] then return OVERRIDES[k] end return SAVED[k] or "" end
function GetBindingText(k) return (k:gsub("SHIFT%-", "Shift-")) end
function SetOverrideBindingClick(owner, prio, key, name, mb)
  assert(not COMBAT, "SetOverrideBindingClick in combat")
  OVERRIDES[key] = "CLICK " .. name .. ":" .. mb
end
function ClearOverrideBindings() assert(not COMBAT, "ClearOverrideBindings in combat") wipe(OVERRIDES) end
function GetMacroInfo(i) if i <= 25 then return "YB Say " .. i end end
LAYOUTS = { activeLayout = 4, layouts = { { layoutName = "Deck" }, { layoutName = "SteamDeck at dock 1080" }, { layoutName = "Switch 1080" } } }
SETLAYOUT = {}
C_EditMode = { GetLayouts = function() return LAYOUTS end, SetActiveLayout = function(i) table.insert(SETLAYOUT, i); LAYOUTS.activeLayout = i end }
LOADED = {}
C_AddOns = { IsAddOnLoaded = function(n) return LOADED[n] or false end }
STICKS = nil
C_GamePad = { GetDeviceMappedState = function() return STICKS end,
  StickIndexToConfigName = function(i) return ({ [0] = "Left", [1] = "Right", [5] = "Camera" })[i] or "x" end }
function IsShiftKeyDown() return SHIFTDOWN end
function IsControlKeyDown() return false end
function IsAltKeyDown() return false end

FRAMES = {}
local Obj = {}
Obj.__index = function(t, k)
  local v = rawget(Obj, k)
  if v ~= nil then return v end
  if type(k) == "string" and k:match("^%u") then return function() end end   -- unknown methods are no-ops
  return nil                                                                -- plain fields start empty, as in WoW
end
local function new(name)
  local o = setmetatable({ scripts = {}, hooks = {}, attr = {}, events = {}, shown = true, name = name, text = "", checked = false }, Obj)
  FRAMES[#FRAMES + 1] = o
  if name then _G[name] = o end
  return o
end
NEW = new
function Obj:SetScript(s, f) self.scripts[s] = f end
function Obj:GetScript(s) return self.scripts[s] end
function Obj:HookScript(s, f) self.hooks[s] = self.hooks[s] or {}; table.insert(self.hooks[s], f) end
function Obj:SetAttribute(k, v) assert(not COMBAT or not self.secure, "SetAttribute on secure frame in combat") self.attr[k] = v end
function Obj:GetAttribute(k) return self.attr[k] end
function Obj:Show() self.shown = true end
function Obj:Hide() self.shown = false end
function Obj:IsShown() return self.shown end
function Obj:SetShown(v) self.shown = v and true or false end
function Obj:SetText(t) self.text = t end
function Obj:GetText() return self.text end
function Obj:GetStringWidth() return 80 end
function Obj:GetWidth() return self.w or 2158 end
function Obj:GetHeight() return self.h or 903 end
function Obj:GetCenter() return 1079, 750 end
function Obj:GetChecked() return self.checked end
function Obj:SetChecked(v) self.checked = v and true or false end
function Obj:RegisterEvent(e) self.events[e] = true end
function Obj:CreateFontString() return new() end
function Obj:CreateTexture() return new() end
function Obj:GetScale() return 1 end
function CreateFrame(kind, name, parent, template)
  local o = new(name)
  o.template = template or ""
  o.secure = (template or ""):find("Secure") ~= nil
  return o
end
UIParent = new("UIParent")
Minimap = new("Minimap")
GameTooltip = new("GameTooltip")
UIErrorsFrame = new("UIErrorsFrame")
SlashCmdList = {}
UISpecialFrames = {}
function FINDATTR(k, v) local out = {} for _, o in ipairs(FRAMES) do if o.attr[k] == v then out[#out+1] = o end end return out end
function FINDRAW(k, v) local out = {} for _, o in ipairs(FRAMES) do if rawget(o, k) == v then out[#out+1] = o end end return out end
function FIRE(event, ...) for _, o in ipairs(FRAMES) do if o.events[event] and o.scripts.OnEvent then o.scripts.OnEvent(o, event, ...) end end end
function CLICKBTN(o) if o.scripts.OnClick then o.scripts.OnClick(o, "LeftButton") end end
function UPDATE(o, e) if o.scripts.OnUpdate then o.scripts.OnUpdate(o, e or 0.1) end end
''')

YB = L.eval("{}")
load = L.eval("function(code, name, yb) local f, e = loadstring(code, name); assert(f, e); f('YagriverBindsPC', yb) end")
toc = open(os.path.join(base, "YagriverBindsPC.toc"), encoding="utf-8").read().split("\n")
for line in toc:
    line = line.strip()
    if line.endswith(".lua"):
        load(open(os.path.join(base, line), encoding="utf-8").read(), line, YB)
g = L.globals()
ex = L.execute
ev = L.eval

fails = []
def check(cond, what):
    print(("PASS " if cond else "FAIL ") + what)
    if not cond: fails.append(what)

call = ev("function(yb, m, ...) return yb[m](yb, ...) end")
def yb(m, *a): return call(YB, m, *a)

# 1. login at the desk
ex('FIRE("PLAYER_LOGIN")')
check(ev('SLASH_YBPCDECKSETTINGS1') == "/yag", "/yag alias when the Deck edition isn't here")
ex('ADVANCE(2)')
check(yb("ModeKey") == "pc", "auto picks PC at 3440x1440")
check(g.CVARS["InputDeviceInterfaceStyle"] == "0" and g.RELOADS == 0, "no reload at the desk")
check(abs(float(g.YagriverBindsPCDB.modes.pc.scale) - 0.85) < 1e-9, "PC keeps its 0.85 scale")

# 2. stream starts: 1920x1080
ex('SCREEN = {1920, 1080}; FIRE("DISPLAY_SIZE_CHANGED"); FIRE("DISPLAY_SIZE_CHANGED"); ADVANCE(1.6)')
check(ev('YagriverBindsPCBanner.shown') == True, "banner offers Switch mode")
check(ev('YagriverBindsPCBanner.scripts.OnUpdate ~= nil'), "banner counts down")
ex('for i = 1, 70 do UPDATE(YagriverBindsPCBanner) end')
check(g.CVARS["InputDeviceInterfaceStyle"] == "1", "Switch mode sets the gamepad UI")
check(yb("ModeKey") == "switch", "mode is Switch")
ex('ADVANCE(3.1)')
check(g.RELOADS == 1, "reload requested once (game didn't reload by itself in the stub)")

# 3. after the reload, in Switch mode: scale of its own, layout picked
ex('LOG = {}; FIRE("PLAYER_LOGIN"); ADVANCE(2)')
check(g.RELOADS == 1, "no second reload once the style is right")
yb("SetScale", 0.75)
check(g.CVARS["uiScale"] == "0.75", "Switch scale 0.75")
r = yb("CycleLayout")
r = yb("CycleLayout")
r = yb("CycleLayout")
check(g.YagriverBindsPCDB.modes.switch.layout == "Switch 1080", "layout cycle reaches 'Switch 1080'")
check(ev('SETLAYOUT[#SETLAYOUT]') == 5, "SetActiveLayout(5) for the third custom layout")
yb("SetStickCamera", True)
check(g.CVARS["GamePadCursorAutoEnable"] == "0", "stick camera on in Switch mode")

# 4. back to the desk restores PC scale and stick default
ex('SCREEN = {3440, 1440}')
ok, msg = yb("ApplyMode", "pc")
check(g.CVARS["uiScale"] == "0.85", "PC scale back to 0.85")
check(g.CVARS["GamePadCursorAutoEnable"] == "1", "stick camera back to default at the desk")
check(g.CVARS["InputDeviceInterfaceStyle"] == "0", "keyboard UI at the desk")

# 5. loop guard: the game refuses the style change
ex('ADVANCE(3.1)')
ex('CVARS.InputDeviceInterfaceStyle = "1"; YagriverBindsPCDB.styleChange = {mode = "pc", at = time()}; LOG = {}')
before = g.RELOADS
ex('FIRE("PLAYER_LOGIN"); ADVANCE(5)')
check(g.RELOADS == before, "no reload loop when the game refuses")
check(ev('LOGHAS("couldn\'t switch the interface style")'), "tells the user once")

# 6. weapon sets and keys
ex('CVARS.InputDeviceInterfaceStyle = "0"; YagriverBindsPCDB.mode = "pc"')
EQ = g.EQUIP
ok, msg = yb("CaptureWeapons", "caster")
check(ok, "caster set saved")
ex('EQUIP[16] = 100; EQUIP[17] = nil')
ok, msg = yb("CaptureWeapons", "feral")
check(str(ev('YBPCSetCaster.attr.macrotext')) == "/equipslot 16 item:200\n/equipslot 17 item:201", "caster button text")
check(str(ev('YBPCSetFeral.attr.macrotext')) == "/equipslot 16 item:100", "feral button text")
ok, msg = yb("SetKey", "caster", "SHIFT-Q")
check(str(g.OVERRIDES["SHIFT-Q"]) == "CLICK YBPCSetCaster:LeftButton", "Shift-Q bound for this session only")
check("replaces: MULTIACTIONBAR1BUTTON1" in str(msg), "conflict named")
ok, msg = yb("SetKey", "feral", "SHIFT-Q")
check(g.YagriverBindsPCDB["keys"]["caster"] is None, "one action per key")
check(str(g.OVERRIDES["SHIFT-Q"]) == "CLICK YBPCSetFeral:LeftButton", "key moved to feral")
yb("SetKey", "caster", "SHIFT-E")

# 7. hint
ex('FORM = 3; EQUIP[16] = 200; FIRE("UPDATE_SHAPESHIFT_FORM")')
check(ev('YagriverBindsPCWeaponHint.shown') == True, "hint in Cat with the caster weapon")
texts = [str(ev('FRAMES[%d].text' % i)) for i in range(1, int(ev('#FRAMES')) + 1)]
check("Feral weapon" in texts and "Shift-Q" in texts, "hint shows 'Feral weapon / Shift-Q'")
ex('YagriverBindsPCDB.mode = "switch"; FIRE("UPDATE_SHAPESHIFT_FORM")')
texts = [str(ev('FRAMES[%d].text' % i)) for i in range(1, int(ev('#FRAMES')) + 1)]
check("YB panel" in texts, "hint in Switch mode points to the YB panel")
ex('YagriverBindsPCDB.mode = "pc"; FORM = 0; EQUIP[16] = 200; FIRE("UPDATE_SHAPESHIFT_FORM")')
check(ev('YagriverBindsPCWeaponHint.shown') == False, "no hint when weapon matches")

# 8. panel
ex('YagriverBinds_TogglePanel()')
check(ev('YagriverBindsPCPanel.shown') == True, "panel opens")
phrase = list(ev('FINDATTR("macrotext", "/p Hi!")').values())
check(len(phrase) == 1, "phrase button carries '/p Hi!'")
chan = list(ev('FINDRAW("slash", "g")').values())
ex('YagriverBinds_TogglePanel()')
L.eval("function(b) b.scripts.OnClick(b) end")(chan[0])
check(phrase[0].attr["macrotext"] == "/g Hi!", "channel Guild rewrites the phrase text")
sets = list(ev('FINDRAW("which", "feral")').values())
check(sets and sets[0].attr["macrotext"] == "/equipslot 16 item:100", "panel feral set button")
profs = list(ev('FINDATTR("spell", "Cocina")').values())
check(len(profs) == 1, "profession button (localized name)")
ex('COMBAT = true; FIRE("PLAYER_REGEN_DISABLED")')
check(ev('YagriverBindsPCPanel.shown') == False, "panel closes in combat")
ex('YagriverBinds_TogglePanel()')
check(ev('YagriverBindsPCPanel.shown') == False, "panel refuses to open in combat")

# 9. combat refusals and deferrals
ok, msg = yb("ApplyMode", "switch")
check(not ok, "no mode change in combat")
ok, msg = yb("SetKey", "panel", "SHIFT-P")
check(not ok, "no key change in combat")
ex('SCREEN = {1920, 1080}; FIRE("DISPLAY_SIZE_CHANGED"); ADVANCE(1.6)')
check(ev('YagriverBindsPCBanner.shown') == False, "no banner in combat")
ex('COMBAT = false; FIRE("PLAYER_REGEN_ENABLED")')
check(ev('YagriverBindsPCBanner.shown') == True, "banner after combat")
L.eval("function(b) for _, o in ipairs(FRAMES) do if o.text == 'Stay' then o.scripts.OnClick(o) end end end")(None)
check(yb("ModeKey") == "pc", "Stay keeps PC mode")

# 10. checks
left = yb("DeckLeftovers")
check(len(list(left.values())) == 2, "Deck leftovers found (2 in the stub)")
check(int(yb("DeckMacros")) == 25, "25 YB macros counted")
ex('LOADED.EasyController = true')
c = yb("Conflicts")
check(len(list(c.values())) == 1, "Easy Controller reported as a conflict")

# 11. stick check, phased: right then left
ex('STICKS = {stickCount = 6, buttons = {}, sticks = {{x=0,y=0},{x=0,y=0},{x=0,y=0},{x=0,y=0},{x=0,y=0},{x=0,y=0}}}')
ok, msg = yb("StickCheck", None)
check(ok, "stick check starts")
fr = YB.checkFrame
step = L.eval("function(f, n) for i = 1, n do if f.scripts.OnUpdate then f.scripts.OnUpdate(f, 0.1) end end end")
ex('STICKS.sticks[2] = {x=0.9,y=0.1}; STICKS.sticks[6] = {x=0.8,y=0}')
step(fr, 60)
ex('STICKS.sticks[2] = {x=0,y=0}; STICKS.sticks[6] = {x=0,y=0}; STICKS.sticks[1] = {x=0,y=1}; STICKS.sticks[5] = {x=0,y=0.95}')
step(fr, 70)
rep = g.YagriverBindsPCDB.stickReport
check(rep is not None and str(rep.result) == "right: 2 Right 0.90, 6 Camera 0.80 | left: 1 Left 1.00, 5 x 0.95", "phased stick report: " + (str(rep.result) if rep else "none"))

# 11b. trigger check: the bar page follows ZL in this stub, and a protected frame's attribute follows ZR
ex('''
PAGE = 1
function GetActionBarPage() return PAGE end
function GetBonusBarOffset() return 0 end
function SecureCmdOptionParse(s) if s:find("%[bar:2%]") then return PAGE == 2 and "1" or "0" end return "0" end
STICKS.buttons = {}
GamepadMainActionBarFrame = NEW("GamepadMainActionBarFrame")
function GamepadMainActionBarFrame:IsProtected() return true end
function GamepadMainActionBarFrame:GetName() return "GamepadMainActionBarFrame" end
function C_GamePad.ButtonBindingToIndex(b) return ({PADLTRIGGER = 14, PADRTRIGGER = 15})[b] end
function SETTRIG(lt, rt)
  STICKS.buttons[15] = lt or nil; STICKS.buttons[16] = rt or nil
  PAGE = lt and 2 or 1
  local h = GamepadMainActionBarFrame.hooks.OnAttributeChanged
  if h then for _, f in ipairs(h) do f(GamepadMainActionBarFrame, "state-layer", rt and "rt" or "none") end end
end
''')
ok, msg = yb("TriggerCheck", None)
check(ok, "trigger check starts")
fr = YB.checkFrame
ex('SETTRIG(true, false)'); step(fr, 50)
ex('SETTRIG(false, true)'); step(fr, 50)
ex('SETTRIG(true, true)'); step(fr, 50)
ex('SETTRIG(false, false)'); step(fr, 55)
tr = g.YagriverBindsPCDB.triggerReport
lines = [str(x) for x in tr.lines.values()] if tr else []
print("   " + "\n   ".join(lines))
check(any(l.startswith("[bar:2]  ZL=1") for l in lines), "finds [bar:2] following ZL")
check(any(l.startswith("page  ZL=2") for l in lines), "finds the bar page following ZL")
check(any(l.startswith("attr GamepadMainActionBarFrame.state-layer  ZL=none ZR=rt") for l in lines), "finds the attribute following ZR")
check(any(l.startswith("ZL: ZL held") for l in lines), "reports how long each trigger was held")

# 13. window: every tab builds without errors, in both modes, druid and not
ex('LOG = {}')
for mode in ("pc", "switch"):
    for cls in ("DRUID", "WARRIOR"):
        ex('YagriverBindsPCDB.mode = "%s"; CLASS = "%s"' % (mode, cls))
        ex('if YagriverBindsPCFrame.shown then YB_T = nil end')
        yb("Toggle") if not ev('YagriverBindsPCFrame.shown') else None
        for t in ("Setup", "Device", "Check"):
            ex('for _, o in ipairs(FRAMES) do if o.text == "%s" and o.scripts.OnClick then o.scripts.OnClick(o) end end' % t)
check(not ev('LOGHAS("Error:")'), "all tabs build in both modes (no 'Error:' lines)")
# 14. key capture: Set key, then Shift+R
ex('CLASS = "DRUID"; YagriverBindsPCDB.mode = "pc"')
ex('for _, o in ipairs(FRAMES) do if o.text == "Setup" and o.scripts.OnClick then o.scripts.OnClick(o) end end')
ex('for _, o in ipairs(FRAMES) do if o.text == "Set key" and o.scripts.OnClick and o.shown then o.scripts.OnClick(o) break end end')
check(ev('YagriverBindsPCKeyCapture.shown') == True, "capture overlay shown")
ex('SHIFTDOWN = true; YagriverBindsPCKeyCapture.scripts.OnKeyDown(YagriverBindsPCKeyCapture, "LSHIFT"); YagriverBindsPCKeyCapture.scripts.OnKeyDown(YagriverBindsPCKeyCapture, "R"); SHIFTDOWN = false')
check(g.YagriverBindsPCDB["keys"]["caster"] == "SHIFT-R", "captured Shift-R for the first action")
check(str(g.OVERRIDES["SHIFT-R"]) == "CLICK YBPCSetCaster:LeftButton", "captured key bound")

# 12. no saved bindings, no macros ever
src = "".join(open(os.path.join(base, f), encoding="utf-8").read() for f in os.listdir(base) if f.endswith(".lua"))
for bad in ["SaveBindings", "CreateMacro", "EditMacro", "DeleteMacro", "SetBinding(", "SetBindingClick(", "SetBindingSpell", "SetBindingMacro"]:
    check(bad not in src, "never calls " + bad)

print("\n%d failures" % len(fails))
sys.exit(1 if fails else 0)
