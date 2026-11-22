
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
