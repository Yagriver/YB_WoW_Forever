-- Yagriver Binds PC - core.
-- Rules of this edition:
--   * No saved key bindings and no macros: Blizzard's server would copy them to the Deck.
--     Keys are override bindings (alive only while this addon runs); buttons carry their own text.
--   * Every setting lives in this PC's own files (YagriverBindsPCDB / YagriverBindsPCCharDB).
--   * Two modes: "pc" (desk, keyboard and mouse) and "switch" (Moonlight, gamepad UI).
local ADDON, YB = ...
YB.VERSION = "1.0"

---------------------------------------------------------------- API compatibility
function YB.SpellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  if C_Spell and C_Spell.GetSpellInfo then local i = C_Spell.GetSpellInfo(id); return i and i.name end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end
function YB.ItemName(id)
  if not id then return end
  if C_Item and C_Item.GetItemNameByID then local n = C_Item.GetItemNameByID(id); if n then return n end end
  if C_Item and C_Item.GetItemInfo then local n = C_Item.GetItemInfo(id); if n then return n end end
  if GetItemInfo then return (GetItemInfo(id)) end
end
function YB.IsKnown(id)
  if IsPlayerSpell and IsPlayerSpell(id) then return true end
  if C_SpellBook and C_SpellBook.IsSpellKnown then
    local ok, v = pcall(C_SpellBook.IsSpellKnown, id); if ok and v then return true end
  end
  if IsSpellKnown then local ok, v = pcall(IsSpellKnown, id); if ok and v then return true end end
  return false
end
function YB.FormSpellID(i)
  if not GetShapeshiftFormInfo then return end
  local _, _, c, d = GetShapeshiftFormInfo(i)
  if type(d) == "number" then return d end
  if type(c) == "number" then return c end
end
function YB.InCombat() return InCombatLockdown and InCombatLockdown() end
local function getCVar(n)
  if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(n) end
  if GetCVar then return GetCVar(n) end
end
local function setCVar(n, v)
  if C_CVar and C_CVar.SetCVar then return C_CVar.SetCVar(n, v) end
  if SetCVar then return SetCVar(n, v) end
end
YB.GetCVar, YB.SetCVar = getCVar, setCVar
local function isLoaded(name)
  local fn = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  if not fn then return false end
  local ok, v = pcall(fn, name)
  return ok and v and true or false
end
YB.IsLoaded = isLoaded
local function tell(msg) print("|cff88ccffYagriver Binds PC:|r " .. msg) end
YB.Tell = tell

---------------------------------------------------------------- saved settings
YB.MODES = { "pc", "switch" }
YB.MODE_NAMES = { pc = "PC", switch = "Switch" }
YB.HINT_DEFAULTS = { pc = { scale = 1.0, x = 0.5, y = 5 / 6 }, switch = { scale = 1.3, x = 0.5, y = 5 / 6 } }
local STYLE = { pc = "0", switch = "1" }   -- InputDeviceInterfaceStyle: 0 keyboard and mouse, 1 gamepad UI

function YB:Global()
  YagriverBindsPCDB = YagriverBindsPCDB or {}
  local g = YagriverBindsPCDB
  if g.auto == nil then g.auto = true end
  g.channel = g.channel or YB.defaultChannel
  g.keys = g.keys or {}
  g.modes = g.modes or {}
  for _, m in ipairs(YB.MODES) do
    local mode = g.modes[m] or {}
    local d, h = YB.HINT_DEFAULTS[m], mode.hint or {}
    mode.hint = { scale = h.scale or d.scale, x = h.x or d.x, y = h.y or d.y }
    if mode.stickCamera == nil then mode.stickCamera = false end
    g.modes[m] = mode
  end
  return g
end
function YB:DB()
  YagriverBindsPCCharDB = YagriverBindsPCCharDB or {}
  local db = YagriverBindsPCCharDB
  db.weapons = db.weapons or {}
  db.weapons.feral = db.weapons.feral or {}
  db.weapons.caster = db.weapons.caster or {}
  if db.weaponHint == nil then db.weaponHint = true end
  return db
end
function YB:ModeKey() return self:Global().mode or self:DetectMode() end
function YB:Mode() return self:Global().modes[self:ModeKey()] end

---------------------------------------------------------------- which mode fits this screen
-- The desk monitor is 21:9 (3440 x 1440); the Switch stream is a 16:9 virtual display (1920 x 1080).
function YB:ScreenSize()
  if GetPhysicalScreenSize then
    local w, h = GetPhysicalScreenSize()
    if w and h and h > 0 then return w, h end
  end
end
function YB:DetectMode()
  local w, h = self:ScreenSize()
  if not w then return "pc" end
  return (w / h) > 2.0 and "pc" or "switch"
end

---------------------------------------------------------------- UI scale (per mode)
local SCALE_MIN, SCALE_MAX = 0.64, 1.15
function YB:Scale()
  local v = tonumber(getCVar("uiScale") or "")
  if not v and UIParent and UIParent.GetScale then v = UIParent:GetScale() end
  return v or 1
end
function YB:SetScale(v)
  if YB.InCombat() then return false, "Leave combat first." end
  v = math.floor(math.max(SCALE_MIN, math.min(SCALE_MAX, v)) * 100 + 0.5) / 100
  setCVar("useUiScale", "1")
  setCVar("uiScale", tostring(v))
  if UIParent and UIParent.SetScale then pcall(UIParent.SetScale, UIParent, v) end
  self:Mode().scale = v
  if YB.LayoutHint then YB.LayoutHint() end
  return true, ("UI scale %.2f (saved for %s)."):format(v, YB.MODE_NAMES[self:ModeKey()])
end

---------------------------------------------------------------- right stick stays camera (Switch mode option)
-- on  = GamePadCursorAutoEnable 0 + GamePadCursorAutoDisableSticks 2
-- off = WoW defaults (1 / 2)
function YB:StickCameraOn() return getCVar("GamePadCursorAutoEnable") == "0" end
function YB:ApplyStickCamera()
  local on = self:ModeKey() == "switch" and self:Mode().stickCamera
  setCVar("GamePadCursorAutoEnable", on and "0" or "1")
  setCVar("GamePadCursorAutoDisableSticks", "2")
end
function YB:SetStickCamera(on)
  if YB.InCombat() then return false, "Leave combat first." end
  if self:ModeKey() ~= "switch" then return false, "This option belongs to Switch mode." end
  self:Mode().stickCamera = on
  self:ApplyStickCamera()
  return true, on and "Right stick now always moves the camera (Switch mode)." or "Right stick back to WoW default (cursor in menus)."
end

---------------------------------------------------------------- Edit Mode layouts (per mode, by name)
-- Blizzard keeps layouts on its server, shared with the Deck. Each mode can pick one by name;
-- "(don't change)" leaves Edit Mode alone. Custom layouts start at index 3 (1 and 2 are presets).
function YB:Layouts()
  local out, active = {}, nil
  if not (C_EditMode and C_EditMode.GetLayouts) then return out end
  local ok, info = pcall(C_EditMode.GetLayouts)
  if not ok or type(info) ~= "table" then return out end
  active = info.activeLayout
  for i, l in ipairs(info.layouts or {}) do
    table.insert(out, { name = l.layoutName, index = i + 2, active = (i + 2) == active })
  end
  return out, active
end
function YB:CycleLayout()
  local list = self:Layouts()
  local names = { false }
  for _, l in ipairs(list) do table.insert(names, l.name) end
  local cur = self:Mode().layout or false
  local nextName = names[1]
  for i, n in ipairs(names) do
    if n == cur then nextName = names[(i % #names) + 1] end
  end
  self:Mode().layout = nextName or nil
  local ok, msg = self:ApplyLayout()
  if nextName then return ok, msg end
  return true, "Layout: don't change (saved for " .. YB.MODE_NAMES[self:ModeKey()] .. ")."
end
function YB:ApplyLayout()
  local want = self:Mode().layout
  if not want then return true end
  if YB.InCombat() then return false, "Leave combat first." end
  local list, active = self:Layouts()
  for _, l in ipairs(list) do
    if l.name == want then
      if l.index ~= active and C_EditMode.SetActiveLayout then pcall(C_EditMode.SetActiveLayout, l.index) end
      return true, "Layout \"" .. want .. "\" (saved for " .. YB.MODE_NAMES[self:ModeKey()] .. ")."
    end
  end
  return false, "Layout \"" .. want .. "\" not found in Edit Mode: create it there, or pick another."
end

---------------------------------------------------------------- applying a mode
-- Changing the interface style makes the game reload its interface. YB then finishes the mode
-- at the next login (layout). A guard stops a loop if the game ever refuses the change.
function YB:InterfaceStyle() return getCVar("InputDeviceInterfaceStyle") end
function YB:ApplyMode(m)
  if YB.InCombat() then return false, "Leave combat first." end
  local g = self:Global()
  if not g.modes[m] then return false, "Unknown mode." end
  g.mode = m
  local mode = g.modes[m]
  setCVar("GamePadEnable", "1")
  if mode.scale == nil then mode.scale = self:Scale() end
  self:SetScale(mode.scale)
  self:ApplyStickCamera()
  if YB.LayoutHint then YB.LayoutHint() end
  if self:InterfaceStyle() ~= STYLE[m] then
    g.styleChange = { mode = m, at = time() }
    setCVar("InputDeviceInterfaceStyle", STYLE[m])
    -- the game normally reloads by itself; if it hasn't after 3 s, reload for it
    if C_Timer and C_Timer.After then
      C_Timer.After(3, function() if not YB.InCombat() then ReloadUI() end end)
    end
    return true, ("%s mode: UI scale %.2f, %s: the interface reloads..."):format(YB.MODE_NAMES[m], mode.scale,
      m == "switch" and "gamepad UI on" or "keyboard and mouse")
  end
  local okL, msgL = self:ApplyLayout()
  local msg = ("%s mode: UI scale %.2f."):format(YB.MODE_NAMES[m], mode.scale)
  if mode.layout then msg = msg .. " " .. (msgL or "") end
  return okL ~= false, msg
end

-- at login: pick the mode (Auto) and make sure its settings are in place
function YB:Startup()
  if YB.InCombat() then YB.pendingStartup = true return end
  local g = self:Global()
  local want = g.auto and self:DetectMode() or (g.mode or self:DetectMode())
  local styleOK = self:InterfaceStyle() == STYLE[want]
  if not styleOK and g.styleChange and g.styleChange.mode == want and (time() - (g.styleChange.at or 0)) < 60 then
    -- we already asked for this change a moment ago and the game did not take it: don't loop
    g.mode = want
    g.styleChange = nil
    tell("couldn't switch the interface style for " .. YB.MODE_NAMES[want] ..
      " mode. Switch 'Enable Gamepad UI' in WoW's options by hand.")
    return
  end
  g.styleChange = nil
  local ok, msg = self:ApplyMode(want)
  if msg then tell(msg) end
end

---------------------------------------------------------------- secure buttons (no macros)
-- Each button carries its own command text. Registered for down AND up: the game fires secure
-- buttons on the press when "cast on key down" (ActionButtonUseKeyDown) is on, else on release.
YB.buttons = {}
function YB:SecureButton(name, parent)
  local b = self.buttons[name]
  if b then return b end
  b = CreateFrame("Button", name, parent or UIParent, parent and "SecureActionButtonTemplate,UIPanelButtonTemplate" or "SecureActionButtonTemplate")
  b:RegisterForClicks("AnyUp", "AnyDown")
  if not parent then b:Hide() end
  self.buttons[name] = b
  return b
end

---------------------------------------------------------------- weapon sets
local function item(id) return "item:" .. id end
function YB:SetText(which)
  local w = self:DB().weapons[which] or {}
  if not w.mh then return "/run print('|cff88ccffYagriver Binds PC:|r no " .. which .. " set saved yet: /yag, Setup, Use equipped.')" end
  local t = "/equipslot 16 " .. item(w.mh)
  if w.oh then t = t .. "\n/equipslot 17 " .. item(w.oh) end
  return t
end
function YB:RefreshSetButtons()
  if YB.InCombat() then YB.pendingSets = true return end
  for _, which in ipairs({ "caster", "feral" }) do
    local b = self:SecureButton(which == "caster" and "YBPCSetCaster" or "YBPCSetFeral")
    b:SetAttribute("type", "macro")
    b:SetAttribute("macrotext", self:SetText(which))
  end
  if YB.RefreshPanelSets then YB.RefreshPanelSets() end
  if YB.UpdateWeaponHint then YB.UpdateWeaponHint() end
end
function YB:CaptureWeapons(which)
  if YB.InCombat() then return false, "Leave combat first." end
  local w = { mh = GetInventoryItemID("player", 16), oh = GetInventoryItemID("player", 17) }
  if not w.mh then return false, "No main-hand weapon equipped." end
  self:DB().weapons[which] = w
  self:RefreshSetButtons()
  return true, ("Saved %s set: %s."):format(which, self:WeaponText(which))
end
function YB:ClearWeapons(which)
  if YB.InCombat() then return false, "Leave combat first." end
  self:DB().weapons[which] = {}
  self:RefreshSetButtons()
  return true, ("Cleared the %s set."):format(which)
end
function YB:WeaponText(which)
  local w = self:DB().weapons[which] or {}
  if not w.mh then return "none" end
  local function n(id) return YB.ItemName(id) or ("item " .. id) end
  return n(w.mh) .. (w.oh and (" + " .. n(w.oh)) or "")
end

---------------------------------------------------------------- keys chosen inside YB (override bindings)
-- Never saved by WoW, so they don't travel to the Deck. Re-applied at every login.
YB.KEY_ACTIONS = {
  { id = "caster", label = "Equip caster set", button = "YBPCSetCaster" },
  { id = "feral",  label = "Equip feral set",  button = "YBPCSetFeral" },
  { id = "panel",  label = "Open / close the YB panel", button = "YBPCPanelToggle" },
}
local owner = CreateFrame("Frame", "YagriverBindsPCBindings")
local panelToggle = CreateFrame("Button", "YBPCPanelToggle", UIParent)
panelToggle:Hide()
panelToggle:RegisterForClicks("AnyUp")
panelToggle:SetScript("OnClick", function() if YagriverBinds_TogglePanel then YagriverBinds_TogglePanel() end end)

function YB:ApplyKeys()
  if YB.InCombat() then YB.pendingKeys = true return false end
  ClearOverrideBindings(owner)
  local g = self:Global()
  for _, a in ipairs(YB.KEY_ACTIONS) do
    local key = g.keys[a.id]
    if key then SetOverrideBindingClick(owner, false, key, a.button, "LeftButton") end
  end
  return true
end
function YB:KeyText(key)
  if not key then return nil end
  if GetBindingText then
    local ok, t = pcall(GetBindingText, key)
    if ok and t and t ~= "" then return t end
  end
  return key
end
-- what the key does without YB (its saved binding), for the conflict note
function YB:KeyUnder(key)
  local a = GetBindingAction and GetBindingAction(key, false) or ""
  return a ~= "" and a or nil
end
function YB:SetKey(id, key)
  if YB.InCombat() then return false, "Leave combat first." end
  local g = self:Global()
  for _, a in ipairs(YB.KEY_ACTIONS) do
    if a.id ~= id and key and g.keys[a.id] == key then g.keys[a.id] = nil end   -- one action per key
  end
  g.keys[id] = key
  self:ApplyKeys()
  if YB.UpdateWeaponHint then YB.UpdateWeaponHint() end
  if not key then return true, "Key cleared." end
  local under = self:KeyUnder(key)
  return true, ("%s set to %s."):format(id, self:KeyText(key)) ..
    (under and (" While YB runs it replaces: " .. under .. ".") or "")
end

---------------------------------------------------------------- checks (read only)
function YB:DeckLeftovers()
  local out = {}
  for _, key in ipairs(YB.deckKeys) do
    local a = GetBindingAction and GetBindingAction(key, false) or ""
    if a ~= "" then table.insert(out, { key = key, action = a }) end
  end
  return out
end
function YB:DeckMacros()
  local n = 0
  for i = 1, 150 do
    local name = GetMacroInfo and GetMacroInfo(i)
    if type(name) == "string" and name:find("^YB ") then n = n + 1 end
  end
  return n
end
function YB:Conflicts()
  local out = {}
  if isLoaded("YagriverBinds") then table.insert(out, "YagriverBinds (the Deck edition) is enabled on this PC: disable it here.") end
  for _, name in ipairs(YB.controllerAddons) do
    if isLoaded(name) then table.insert(out, name .. " is enabled: it will fight YB for the pad once wheels arrive.") end
  end
  return out
end

---------------------------------------------------------------- stick check (for the coming wheels)
-- 10 seconds: push the right stick around, then the left. Records which of the game's sticks move.
function YB:StickCheck(done)
  if not (C_GamePad and C_GamePad.GetDeviceMappedState) then return false, "No gamepad API in this client." end
  local maxes, names = {}, {}
  local t, f = 0, YB.stickFrame or CreateFrame("Frame")
  YB.stickFrame = f
  f:SetScript("OnUpdate", function(self, elapsed)
    t = t + elapsed
    local st = C_GamePad.GetDeviceMappedState()
    if st and st.sticks then
      for i = 1, st.stickCount or #st.sticks do
        local s = st.sticks[i]
        if s then
          local m = math.max(math.abs(s.x or 0), math.abs(s.y or 0))
          if m > (maxes[i] or 0) then maxes[i] = m end
          if not names[i] and C_GamePad.StickIndexToConfigName then
            local ok, n = pcall(C_GamePad.StickIndexToConfigName, i - 1)
            names[i] = ok and n or "?"
          end
        end
      end
    end
    if t >= 10 then
      self:SetScript("OnUpdate", nil)
      local parts = {}
      for i = 1, 8 do
        if maxes[i] then table.insert(parts, ("%d %s %.2f"):format(i, tostring(names[i]), maxes[i])) end
      end
      local line = #parts > 0 and table.concat(parts, ", ") or "no pad state seen"
      YB:Global().stickReport = { at = date and date("%Y-%m-%d %H:%M") or "", result = line }
      if done then done(true, "Stick check: " .. line) end
    end
  end)
  return true, "Stick check running for 10 s: push the RIGHT stick all around, then the LEFT stick."
end

---------------------------------------------------------------- automatic mode on screen change
local banner = CreateFrame("Frame", "YagriverBindsPCBanner", UIParent, "BackdropTemplate")
banner:SetSize(420, 64); banner:SetPoint("TOP", 0, -90); banner:SetFrameStrata("DIALOG"); banner:Hide()
if banner.SetBackdrop then
  banner:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  banner:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
end
local bText = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bText:SetPoint("TOP", 0, -10)
local bNow = CreateFrame("Button", nil, banner, "UIPanelButtonTemplate"); bNow:SetSize(120, 22); bNow:SetPoint("BOTTOMLEFT", 70, 8)
bNow:SetText("Switch now")
local bStay = CreateFrame("Button", nil, banner, "UIPanelButtonTemplate"); bStay:SetSize(120, 22); bStay:SetPoint("BOTTOMRIGHT", -70, 8)
bStay:SetText("Stay")
local pending, countdown = nil, 0
local function finishBanner(go)
  banner:Hide()
  banner:SetScript("OnUpdate", nil)
  local m = pending
  pending = nil
  if go and m then
    local ok, msg = YB:ApplyMode(m)
    if msg then tell(msg) end
  end
end
bNow:SetScript("OnClick", function() finishBanner(true) end)
bStay:SetScript("OnClick", function() finishBanner(false) end)
function YB:OfferMode(m)
  if YB.InCombat() then YB.pendingOffer = m return end
  pending, countdown = m, 6
  banner:Show()
  banner:SetScript("OnUpdate", function(_, elapsed)
    countdown = countdown - elapsed
    if countdown <= 0 then finishBanner(true) return end
    bText:SetText(("New screen: %s mode in %d s"):format(YB.MODE_NAMES[m], math.ceil(countdown)))
  end)
end

local screenTimer
local function screenChanged()
  local g = YB:Global()
  if not g.auto or not YB.started then return end
  local want = YB:DetectMode()
  if want ~= YB:ModeKey() then YB:OfferMode(want) elseif pending then finishBanner(false) end
end

---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("DISPLAY_SIZE_CHANGED")
ev:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    YB:RefreshSetButtons()
    YB:ApplyKeys()
    -- let the screen settle (it reports its size twice at login) before choosing the mode
    if C_Timer and C_Timer.After then
      C_Timer.After(1.5, function() YB:Startup(); YB.started = true end)
    else
      YB:Startup(); YB.started = true
    end
    for _, c in ipairs(YB:Conflicts()) do tell("|cffff5050" .. c .. "|r") end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if YB.pendingKeys then YB.pendingKeys = nil; YB:ApplyKeys() end
    if YB.pendingSets then YB.pendingSets = nil; YB:RefreshSetButtons() end
    if YB.pendingStartup then YB.pendingStartup = nil; YB:Startup(); YB.started = true end
    if YB.pendingOffer then local m = YB.pendingOffer; YB.pendingOffer = nil; YB:OfferMode(m) end
  elseif event == "PLAYER_REGEN_DISABLED" then
    if pending then YB.pendingOffer = pending; finishBanner(false) end
  elseif event == "DISPLAY_SIZE_CHANGED" then
    if screenTimer then screenTimer:Cancel() end
    if C_Timer and C_Timer.NewTimer then screenTimer = C_Timer.NewTimer(1.5, screenChanged) else screenChanged() end
  end
end)
