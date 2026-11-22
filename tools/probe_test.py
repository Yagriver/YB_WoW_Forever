"""Runs YB Probe under real Lua 5.1 with a stubbed WoW API and checks its flow.
Usage: python3 tools/probe_test.py pc/YBProbe/YBProbe.lua
"""
import sys
from lupa import lua51

L = lua51.LuaRuntime(unpack_returned_tuples=True)
STUBS = r'''
LOG = {}
local now = 100
function GetTime() return now end
function ADVANCE(s) now = now + s end
function print(...) local t = {} for i = 1, select('#', ...) do t[#t+1] = tostring(select(i, ...)) end LOG[#LOG+1] = "[print] " .. table.concat(t, " ") end
format = string.format
function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function date(f) return "2026-11-22 17:00" end
function GetBuildInfo() return "1.60.1", "70000", "Nov 1 2026", 16001 end
function UnitClass() return "Druid", "DRUID" end
function UnitName() return "Yagri" end
function UnitLevel() return 21 end
COMBAT = false
function InCombatLockdown() return COMBAT end
function GetPhysicalScreenSize() return 1920, 1080 end
function GetScreenWidth() return 1365.3 end
function GetScreenHeight() return 768 end
CVARS = { GamePadEmulateShift = "PADLTRIGGER", GamePadEmulateCtrl = "PADLSHOULDER", GamePadEmulateAlt = "NONE", InputDeviceInterfaceStyle = "1" }
C_CVar = { GetCVar = function(n) return CVARS[n] end }
function GetCVar(n) return CVARS[n] end
function SetCVar(n, v) CVARS[n] = tostring(v) return true end
local BUTTONS = { "PAD1", "PAD2", "PAD3", "PAD4", "PADLSHOULDER", "PADRSHOULDER", "PADLTRIGGER", "PADRTRIGGER", "PADLSTICK", "PADRSTICK", "PADBACK", "PADFORWARD" }
local index = {}
for i, b in ipairs(BUTTONS) do index[b] = i - 1 end
PADSTATE = { buttonCount = #BUTTONS, stickCount = 2, axisCount = 6, buttons = {}, sticks = { { x = 0, y = 0, len = 0 }, { x = 0, y = 0, len = 0 } } }
C_GamePad = {
  ButtonBindingToIndex = function(b) return index[b] end,
  ButtonIndexToBinding = function(i) return BUTTONS[i + 1] end,
  StickIndexToConfigName = function(i) return ({ [0] = "Movement", [1] = "Camera" })[i] end,
  GetDeviceMappedState = function() return PADSTATE end,
  GetActiveDeviceID = function() return 1 end,
  IsEnabled = function() return true end,
}
function GetGamePadState() return PADSTATE end
function HOLD(name, down) PADSTATE.buttons[index[name] + 1] = down or nil end
Enum = { BindingContext = { None = 0, GamepadModeInGameCore = 3 } }
local saved = { ["F1"] = "MACRO YB Travel", ["CTRL-F1"] = "MACRO YB Innervate", ["PADRSHOULDER"] = "GAMEPADRIGHTTARGETMODIFIER" }
local gamepadCtx = { ["PADLSHOULDER"] = "GAMEPADLEFTTARGETMODIFIER", ["PADRSTICK"] = "PING" }
C_KeyBindings = { GetBindingByKey = function(k, c) if c == 3 then return gamepadCtx[k] end end }
OVERRIDES = {}
function GetBindingAction(k, withOverride)
  if withOverride and OVERRIDES[k] then return OVERRIDES[k] end
  return saved[k] or ""
end
local list = { { "MACRO YB Travel", "F1" }, { "MACRO YB Innervate", "CTRL-F1" }, { "JUMP", "SPACE" } }
function GetNumBindings() return #list end
function GetBinding(i) return list[i][1], "cat", list[i][2] end
function GetMacroInfo(i) if i == 1 then return "YB Travel" elseif i == 2 then return "Party Hi" end end
C_EditMode = { GetLayouts = function() return { activeLayout = 3, layouts = { { layoutName = "Deck", layoutType = 1 } } } end }
C_AddOns = { IsAddOnLoaded = function(n) return n == "EasyController" end }
function SetOverrideBindingClick(owner, prio, key, name, mb) OVERRIDES[key] = "CLICK " .. name .. ":" .. mb end
function ClearOverrideBindings(owner) for k in pairs(OVERRIDES) do OVERRIDES[k] = nil end end
RELOADED = false
function ReloadUI() RELOADED = true end
function IsShiftKeyDown() return PADSTATE.buttons[index.PADLTRIGGER + 1] == true end
function IsControlKeyDown() return false end
function IsAltKeyDown() return CVARS.GamePadEmulateAlt == "PADRTRIGGER" and PADSTATE.buttons[index.PADRTRIGGER + 1] == true end

-- Frames
FRAMES, WRAPS = {}, {}
local Obj = {}
Obj.__index = function(t, k)
  local v = rawget(Obj, k)
  if v then return v end
  return function() end
end
function Obj:SetScript(s, f) self.scripts[s] = f end
function Obj:GetScript(s) return self.scripts[s] end
function Obj:HookScript(s, f) self.hooks[s] = self.hooks[s] or {}; table.insert(self.hooks[s], f) end
function Obj:SetAttribute(k, v) self.attr[k] = v end
function Obj:GetAttribute(k) return self.attr[k] end
function Obj:Show() self.shown = true end
function Obj:Hide() self.shown = false end
function Obj:IsShown() return self.shown end
function Obj:SetText(t) self.text = t end
function Obj:GetText() return self.text end
function Obj:GetEffectiveScale() return 1 end
function Obj:RegisterEvent(e) self.events[e] = true end
function Obj:CreateFontString() return NEWOBJ() end
function NEWOBJ(name)
  local o = setmetatable({ scripts = {}, hooks = {}, attr = {}, events = {}, shown = true, name = name }, Obj)
  return o
end
function CreateFrame(kind, name, parent, template)
  local o = NEWOBJ(name)
  o.template = template
  if name then _G[name] = o end
  FRAMES[#FRAMES + 1] = o
  return o
end
UIParent = NEWOBJ("UIParent")
function SecureHandlerWrapScript(frame, script, header, pre)
  local f, err = loadstring("local self, button, down = ...\n" .. pre)
  assert(f, "snippet does not compile: " .. tostring(err))
  WRAPS[frame] = f
end
function CLICK(frame, button, down)
  if WRAPS[frame] then
    local env = { GetGamePadState = GetGamePadState, tostring = tostring }
    setfenv(WRAPS[frame], env)
    WRAPS[frame](frame, button, down)
  end
  for _, h in ipairs(frame.hooks.OnClick or {}) do h(frame, button, down) end
end
function UPDATE(frame) local f = frame.scripts.OnUpdate if f then f(frame, 0.016) end end
function FIRE(event, ...) for _, o in ipairs(FRAMES) do if o.events[event] and o.scripts.OnEvent then o.scripts.OnEvent(o, event, ...) end end end
SlashCmdList = {}
'''
L.execute(STUBS)
code = open(sys.argv[1], encoding="utf-8").read()
fn = L.eval("function(c) local f, e = loadstring(c); assert(f, e); f('YBProbe') end")
fn(code)
g = L.globals()
run = L.execute

fails = []
def check(cond, what):
    print(("PASS " if cond else "FAIL ") + what)
    if not cond: fails.append(what)

def log_has(text):
    n = int(L.eval("#YBProbeDB.log"))
    return any(text in str(g.YBProbeDB.log[i]) for i in range(1, n + 1))

run('FIRE("PLAYER_LOGIN")')
check(log_has("Logged in"), "login line")
check(g.YBProbeFrame is not None, "window opens at login")
run('SlashCmdList.YBPROBE("")')
check(g.YBProbeFrame is not None, "window opens")
run('YBProbe:Snapshot()')
for t in ["Physical: 1920 x 1080", "InputDeviceInterfaceStyle = 1", "Index of PADRTRIGGER: 8",
          "Sticks: 1=Movement 2=Camera (camera stick used: 2)", "PADRSHOULDER: saved=GAMEPADRIGHTTARGETMODIFIER",
          "PADRSTICK: GamepadModeInGameCore=PING", "F1 = MACRO YB Travel", "2 of 25 Deck keys",
          "2 bindings point to YB", "YB macros here: 1", "Custom 1 (index 3): Deck", "EasyController: LOADED"]:
    check(log_has(t), "snapshot: " + t)

# Watch stage logs button changes
run('YBProbe:Start("watch")')
run('HOLD("PADRTRIGGER", true); UPDATE(FRAMES[1])')
check(any(True for _ in [0]) and log_has("pad + PADRTRIGGER"), "watch logs RT down")
run('HOLD("PADRSHOULDER", true); UPDATE(FRAMES[1])')
check(log_has("pad + PADRSHOULDER  (held: PADRTRIGGER"), "watch logs RB with RT held")
run('HOLD("PADRSHOULDER", false); HOLD("PADRTRIGGER", false); UPDATE(FRAMES[1])')
run('PADSTATE.sticks[2] = {x = 0, y = 1, len = 1}; UPDATE(FRAMES[1])')
check(log_has("camera stick pushed x=0.00 y=1.00"), "watch logs camera stick")
run('PADSTATE.sticks[2] = {x = 0, y = 0, len = 0}; UPDATE(FRAMES[1])')

# Soft takeover: 4 keys x 7 prefixes, no plain keys
run('YBProbe:Start("soft")')
n = int(L.eval("(function() local n = 0 for _ in pairs(OVERRIDES) do n = n + 1 end return n end)()"))
check(n == 28, "soft: 28 test bindings (got %d)" % n)
check(str(g.OVERRIDES["PADRSHOULDER"]) == "None", "soft: plain RB untouched")
check(log_has("Stage 1 Watch ended (next stage)"), "previous stage ended")
run('HOLD("PADLTRIGGER", true); PADSTATE.sticks[2] = {x = 0.1, y = 0.9, len = 0.9}')
run('CLICK(YBProbeCatch, "SHIFT-PADRSHOULDER", true)')
check(log_has("CAUGHT SHIFT-PADRSHOULDER down  (secure read OK, held: LT , camera stick 0.1,0.9; keyboard mods: S)"), "secure read in click")
run('CLICK(YBProbeCatch, "SHIFT-PADRSHOULDER", false)')
check(log_has("CAUGHT SHIFT-PADRSHOULDER up"), "release logged")
run('HOLD("PADLTRIGGER", false)')

# Full takeover: plain keys too
run('YBProbe:Start("full")')
n = int(L.eval("(function() local n = 0 for _ in pairs(OVERRIDES) do n = n + 1 end return n end)()"))
check(n == 32, "full: 32 test bindings (got %d)" % n)
check(str(g.OVERRIDES["PADRSHOULDER"]) == "CLICK YBProbeCatch:PADRSHOULDER", "full: plain RB taken")

# Stage times out
run('ADVANCE(50); UPDATE(FRAMES[5])')
check(log_has("Stage 3 Full takeover ended (time)"), "stage ends on time")
n = int(L.eval("(function() local n = 0 for _ in pairs(OVERRIDES) do n = n + 1 end return n end)()"))
check(n == 0, "bindings cleared after stage")

# RT modifier stage sets and restores the setting
run('YBProbe:Start("rtmod")')
check(str(g.CVARS["GamePadEmulateAlt"]) == "PADRTRIGGER", "rtmod: Alt emulates RT")
check(g.YBProbeDB.cvarWas is not None, "rtmod: old value kept for a crash")
run('YBProbe:Stop("stopped")')
check(str(g.CVARS["GamePadEmulateAlt"]) == "NONE", "rtmod: restored")
check(g.YBProbeDB.cvarWas is None, "rtmod: nothing left to restore")

# Restore at login if the game closed mid-stage
run('YBProbe:Start("rtmod")')
L.execute('FIRE("PLAYER_LOGIN")')  # as after a crash: the old value is still in YBProbeDB
check(str(g.CVARS["GamePadEmulateAlt"]) == "NONE", "rtmod: restored at next login")

# Combat: no stage starts
run('YBProbe:Stop("x"); COMBAT = true; YBProbe:Start("soft"); COMBAT = false')
check(log_has("Not in combat, please"), "no stage in combat")

# Chat button
chat = g.YBProbeChatTest
check(str(chat.attr["macrotext"]).startswith("/w Yagri YB Probe"), "chat test macrotext")
run('CLICK(YBProbeChatTest, "LeftButton", false)')
run('FIRE("CHAT_MSG_WHISPER_INFORM", "YB Probe: chat from a secure button works")')
check(log_has("Chat test: OK"), "chat confirmation")

print("\n%d failures" % len(fails))
sys.exit(1 if fails else 0)
