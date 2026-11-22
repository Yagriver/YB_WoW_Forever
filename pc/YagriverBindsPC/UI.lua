-- Yagriver Binds PC - settings window: Setup, Device and Check tabs.
-- Open with the minimap paw, /ybpc (also /yag when the Deck edition isn't installed here).
local ADDON, YB = ...

local W, H = 600, 560
local GOLD = { 1, 0.82, 0 }
local MEDIA = "Interface\\AddOns\\YagriverBindsPC\\Media\\"

local f = CreateFrame("Frame", "YagriverBindsPCFrame", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(W, H)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "YagriverBindsPCFrame")   -- Esc closes it

---------------------------------------------------------------- widget helpers
local function button(parent, text, w, h)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(w or 120, h or 26); b:SetText(text)
  return b
end
local function label(parent, text, font, oneLine)
  local s = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
  s:SetJustifyH("LEFT"); s:SetText(text or "")
  if oneLine then s:SetWordWrap(false) end
  return s
end
local function rect(parent, r, g, b, a, layer)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetColorTexture(r, g, b, a)
  return t
end
local function check(parent, text, onClick)
  local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  c:SetSize(24, 24)
  local t = label(parent, text, "GameFontHighlight", true)
  t:SetPoint("LEFT", c, "RIGHT", 2, 0)
  c.text = t
  c:SetScript("OnClick", function(self) onClick(self:GetChecked() and true or false) end)
  return c
end
local function tip(widget, text)
  widget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(text, 1, 1, 1, 1, true); GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

---------------------------------------------------------------- header
local logo = f:CreateTexture(nil, "ARTWORK")
logo:SetTexture("Interface\\Icons\\Ability_Druid_Maul"); logo:SetSize(16, 16)
logo:SetPoint("TOPLEFT", 8, -4)
local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", 0, -5)
title:SetText("|cffffd100Yagriver|r Binds PC  |cff888888v" .. YB.VERSION .. "|r")

local pages, tabs = {}, {}
local function page()
  local p = CreateFrame("Frame", nil, f)
  p:SetPoint("TOPLEFT", 14, -66); p:SetPoint("BOTTOMRIGHT", -14, 48)
  p:Hide()
  return p
end
local setup, device, checks = page(), page(), page()
pages.setup, pages.device, pages.checks = setup, device, checks
local tabDefs = { { "setup", "Setup" }, { "device", "Device" }, { "checks", "Check" } }
for i, d in ipairs(tabDefs) do
  local b = button(f, d[2], 96, 24)
  b:SetPoint("TOPLEFT", 14 + (i - 1) * 100, -30)
  tabs[d[1]] = b
end
local tabPanel = button(f, "YB panel", 120, 24); tabPanel:SetPoint("TOPRIGHT", -14, -30)
tabPanel:SetScript("OnClick", function() if YagriverBinds_TogglePanel then YagriverBinds_TogglePanel() end end)
tip(tabPanel, "Chat phrases, weapon sets and professions.")
local tabLine = rect(f, GOLD[1], GOLD[2], GOLD[3], 0.35, "ARTWORK")
tabLine:SetPoint("TOPLEFT", 12, -58); tabLine:SetPoint("TOPRIGHT", -12, -58); tabLine:SetHeight(1)

---------------------------------------------------------------- footer status
local footer = rect(f, 0, 0, 0, 0.45, "BORDER")
footer:SetPoint("BOTTOMLEFT", 8, 8); footer:SetPoint("BOTTOMRIGHT", -8, 8); footer:SetHeight(34)
local status = label(f, "", "GameFontHighlight")
status:SetPoint("BOTTOMLEFT", 16, 14); status:SetPoint("BOTTOMRIGHT", -16, 14); status:SetHeight(24)
status:SetJustifyV("MIDDLE")
local function say(msg, isError)
  if not msg or msg == "" then status:SetText("|cff888888Ready.|r"); return end
  status:SetText((isError and "|cffff5050" or "|cff40ff40") .. msg .. "|r")
  print("|cff88ccffYagriver Binds PC:|r " .. msg)
  if UIErrorsFrame then UIErrorsFrame:AddMessage(msg, isError and 1 or 0.3, isError and 0.3 or 1, 0.3) end
end
YB.Say = say
local function run(fn, after)
  local ok, res, msg = pcall(fn)
  if not ok then say("Error: " .. tostring(res), true)
  else say(msg or (res and "Done." or "Nothing changed."), not res) end
  if after then pcall(after) end
end

local function holder(p)
  p.widgets = p.widgets or {}
  for _, w in ipairs(p.widgets) do w:Hide(); w:ClearAllPoints() end
  wipe(p.widgets)
  return function(w) table.insert(p.widgets, w); w:Show(); return w end
end
local function section(add, p, text, y)
  local h = add(label(p, text, "GameFontNormal")); h:SetPoint("TOPLEFT", 0, y)
  local line = add(rect(p, GOLD[1], GOLD[2], GOLD[3], 0.25, "ARTWORK"))
  line:SetPoint("TOPLEFT", 0, y - 15); line:SetPoint("TOPRIGHT", 0, y - 15); line:SetHeight(1)
  return y - 22
end

---------------------------------------------------------------- key capture
-- "Set key": the next key you press (with Shift / Ctrl / Alt) becomes the key. Esc cancels.
local capture = CreateFrame("Frame", "YagriverBindsPCKeyCapture", UIParent)
capture:SetAllPoints(); capture:SetFrameStrata("FULLSCREEN_DIALOG"); capture:EnableKeyboard(false); capture:Hide()
local capBg = rect(capture, 0, 0, 0, 0.6)
capBg:SetAllPoints()
local capText = label(capture, "", "GameFontNormalLarge"); capText:SetPoint("CENTER")
local MODIFIERS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true }
local capturing, afterCapture
local function stopCapture()
  capture:EnableKeyboard(false); capture:Hide(); capturing = nil
end
capture:SetScript("OnKeyDown", function(self, key)
  if MODIFIERS[key] then return end
  local id = capturing
  stopCapture()
  if key == "ESCAPE" then say("Key not changed.") return end
  local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. key
  run(function() return YB:SetKey(id, combo) end, afterCapture)
end)
local function startCapture(id, labelText, after)
  if YB.InCombat() then say("Leave combat first.", true) return end
  capturing, afterCapture = id, after
  capText:SetText("Press the key for: " .. labelText .. "\n|cff888888(with Shift / Ctrl / Alt if you like; Esc cancels)|r")
  capture:Show(); capture:EnableKeyboard(true)
  if capture.SetPropagateKeyboardInput then pcall(capture.SetPropagateKeyboardInput, capture, false) end
end

---------------------------------------------------------------- SETUP
local buildSetup
buildSetup = function()
  local add = holder(setup)
  local db, g = YB:DB(), YB:Global()
  local y = 0
  local _, class = UnitClass("player")

  if class == "DRUID" then
    y = section(add, setup, "Weapon sets", y)
    for _, which in ipairs({ "feral", "caster" }) do
      local l = add(label(setup, (which == "feral" and "|cffffffffFeral:|r  " or "|cffffffffCaster:|r ") ..
        YB:WeaponText(which), "GameFontHighlightSmall", true))
      l:SetPoint("TOPLEFT", 4, y - 6); l:SetWidth(360)
      local b = add(button(setup, "Use equipped", 110, 24)); b:SetPoint("TOPLEFT", 375, y)
      tip(b, "Wear this set first, then click.")
      b:SetScript("OnClick", function() run(function() return YB:CaptureWeapons(which) end, buildSetup) end)
      local cl = add(button(setup, "Clear", 60, 24)); cl:SetPoint("LEFT", b, "RIGHT", 4, 0)
      cl:SetScript("OnClick", function() run(function() return YB:ClearWeapons(which) end, buildSetup) end)
      y = y - 26
    end
    local wh = add(check(setup, "Show a small hint when the weapon doesn't match the form", function(v)
      db.weaponHint = v; if YB.UpdateWeaponHint then YB.UpdateWeaponHint() end
    end))
    add(wh.text); wh:SetPoint("TOPLEFT", 0, y); wh:SetChecked(db.weaponHint); y = y - 32
  end

  y = section(add, setup, "Keys (PC keyboard)", y)
  local kn = add(label(setup, "|cff888888Only while this addon runs; WoW doesn't save them, so the Deck never gets them.|r",
    "GameFontHighlightSmall"))
  kn:SetPoint("TOPLEFT", 4, y); kn:SetWidth(W - 40); y = y - 20
  for _, a in ipairs(YB.KEY_ACTIONS) do
    if class == "DRUID" or a.id == "panel" then
      local key = g.keys[a.id]
      local under = key and YB:KeyUnder(key)
      local l = add(label(setup, "|cffffffff" .. a.label .. ":|r  " .. (key and YB:KeyText(key) or "|cff888888none|r") ..
        (under and ("  |cffff9040(replaces " .. under .. ")|r") or ""), "GameFontHighlightSmall", true))
      l:SetPoint("TOPLEFT", 4, y - 6); l:SetWidth(360)
      local sb = add(button(setup, "Set key", 90, 24)); sb:SetPoint("TOPLEFT", 375, y)
      sb:SetScript("OnClick", function() startCapture(a.id, a.label, buildSetup) end)
      local cb = add(button(setup, "Clear", 60, 24)); cb:SetPoint("LEFT", sb, "RIGHT", 4, 0)
      cb:SetScript("OnClick", function() run(function() return YB:SetKey(a.id, nil) end, buildSetup) end)
      y = y - 26
    end
  end
  y = y - 8
  y = section(add, setup, "On the Switch", y)
  local sn = add(label(setup, "|cff888888Tap the minimap paw with the touchscreen to open this window; the YB panel has the " ..
    "weapon sets. Wheels on the pad come in the next version.|r", "GameFontHighlightSmall"))
  sn:SetPoint("TOPLEFT", 4, y); sn:SetWidth(W - 40)
end

---------------------------------------------------------------- DEVICE
local buildDevice
buildDevice = function()
  local add = holder(device)
  local g = YB:Global()
  local m = YB:ModeKey()
  local mode = YB:Mode()
  local y = 0

  y = section(add, device, "Mode", y)
  local defs = { { "pc", "PC (desk)", "Keyboard and mouse, 21:9 monitor" },
                 { "switch", "Switch (Moonlight)", "Gamepad UI, 16:9 stream" } }
  for i, d in ipairs(defs) do
    local b = add(button(device, d[2], 270, 40))
    b:SetPoint("TOPLEFT", (i - 1) * 290, y)
    if m == d[1] then b:LockHighlight() else b:UnlockHighlight() end
    local ic = add(b:CreateTexture(nil, "OVERLAY"))
    ic:SetTexture(MEDIA .. (d[1] == "pc" and "monitor" or "switch")); ic:SetTexCoord(0, 1, 0, 1)
    ic:SetSize(d[1] == "pc" and 30 or 48, d[1] == "pc" and 30 or 24); ic:SetPoint("LEFT", b, "LEFT", 12, 0)
    tip(b, d[3] .. ".\nChanging the interface style reloads the interface.")
    b:SetScript("OnClick", function() run(function() return YB:ApplyMode(d[1]) end, buildDevice) end)
    local sub = add(label(device, "|cff888888" .. d[3] .. "|r" .. (m == d[1] and "  |cff40ff40(active)|r" or ""),
      "GameFontHighlightSmall", true))
    sub:SetPoint("TOPLEFT", (i - 1) * 290 + 4, y - 44)
  end
  y = y - 66
  local w, h = YB:ScreenSize()
  local au = add(check(device, "Auto: pick the mode from the screen (21:9 = PC, 16:9 = Switch)", function(v)
    g.auto = v; say(v and "Auto on." or "Auto off: the mode stays as you set it.")
  end))
  add(au.text); au:SetPoint("TOPLEFT", 0, y); au:SetChecked(g.auto)
  local sc = add(label(device, "|cff888888screen " .. (w and (w .. " x " .. h) or "?") .. "|r", "GameFontHighlightSmall"))
  sc:SetPoint("TOPRIGHT", device, "TOPRIGHT", 0, y - 6)
  y = y - 32

  y = section(add, device, "UI scale  |cff888888(" .. YB.MODE_NAMES[m] .. ")|r", y)
  local cur = YB:Scale()
  local minus = add(button(device, "-", 44, 30)); minus:SetPoint("TOPLEFT", 0, y)
  local val = add(label(device, ("%.2f"):format(cur), "GameFontNormalLarge")); val:SetPoint("LEFT", minus, "RIGHT", 16, 0)
  local plus = add(button(device, "+", 44, 30)); plus:SetPoint("LEFT", minus, "RIGHT", 72, 0)
  local reset = add(button(device, "1.00", 60, 30)); reset:SetPoint("LEFT", plus, "RIGHT", 12, 0)
  minus:SetScript("OnClick", function() run(function() return YB:SetScale(YB:Scale() - 0.05) end, buildDevice) end)
  plus:SetScript("OnClick", function() run(function() return YB:SetScale(YB:Scale() + 0.05) end, buildDevice) end)
  reset:SetScript("OnClick", function() run(function() return YB:SetScale(1) end, buildDevice) end)
  y = y - 40

  y = section(add, device, "Edit Mode layout  |cff888888(" .. YB.MODE_NAMES[m] .. ")|r", y)
  local lb = add(button(device, "Layout: " .. (mode.layout or "don't change"), 270, 26)); lb:SetPoint("TOPLEFT", 0, y)
  tip(lb, "Click to cycle through your Edit Mode layouts. YB switches to it whenever this mode starts.\n" ..
    "Layouts live on Blizzard's server and are shared with the Deck, so give each device its own.")
  lb:SetScript("OnClick", function() run(function() return YB:CycleLayout() end, buildDevice) end)
  local ln = add(label(device, "|cff888888Create a layout for this screen in Edit Mode first.|r", "GameFontHighlightSmall"))
  ln:SetPoint("LEFT", lb, "RIGHT", 12, 0)
  y = y - 34

  y = section(add, device, "Weapon hint  |cff888888(" .. YB.MODE_NAMES[m] .. ")|r", y)
  local hm = add(button(device, "-", 44, 30)); hm:SetPoint("TOPLEFT", 0, y)
  local hv = add(label(device, ("%.1f"):format(mode.hint.scale), "GameFontNormalLarge")); hv:SetPoint("LEFT", hm, "RIGHT", 18, 0)
  local hp = add(button(device, "+", 44, 30)); hp:SetPoint("LEFT", hm, "RIGHT", 72, 0)
  hm:SetScript("OnClick", function() run(function() return YB:HintScale(-0.1) end, buildDevice) end)
  hp:SetScript("OnClick", function() run(function() return YB:HintScale(0.1) end, buildDevice) end)
  local mv = add(button(device, YB:HintMoving() and "Done" or "Move", 90, 30)); mv:SetPoint("LEFT", hp, "RIGHT", 16, 0)
  if YB:HintMoving() then mv:LockHighlight() else mv:UnlockHighlight() end
  mv:SetScript("OnClick", function() run(function() return YB:HintMove(not YB:HintMoving()) end, buildDevice) end)
  local rr = add(button(device, "Reset", 80, 30)); rr:SetPoint("LEFT", mv, "RIGHT", 8, 0)
  rr:SetScript("OnClick", function() run(function() return YB:HintReset() end, buildDevice) end)
  y = y - 40

  if m == "switch" then
    y = section(add, device, "Pad (Switch)", y)
    local rs = add(check(device, "Right stick always moves the camera (WoW cursor won't take it in menus)", function(v)
      run(function() return YB:SetStickCamera(v) end, buildDevice)
    end))
    add(rs.text); rs:SetPoint("TOPLEFT", 0, y); rs:SetChecked(mode.stickCamera)
    y = y - 28
    local stb = add(button(device, "Stick check (10 s)", 150, 24)); stb:SetPoint("TOPLEFT", 0, y)
    tip(stb, "For the coming wheels: shows which of the game's sticks move. Push the right stick around, then the left.")
    stb:SetScript("OnClick", function() run(function() return YB:StickCheck(function(ok, msg) say(msg, not ok) end) end) end)
    local rep = g.stickReport
    local sl = add(label(device, "|cff888888" .. (rep and ("Last: " .. rep.result) or "Not run yet.") .. "|r", "GameFontHighlightSmall"))
    sl:SetPoint("LEFT", stb, "RIGHT", 10, 0); sl:SetWidth(W - 220)
  end
end

---------------------------------------------------------------- CHECK
local buildChecks
buildChecks = function()
  local add = holder(checks)
  local y = 0
  y = section(add, checks, "Conflicts", y)
  local cs = YB:Conflicts()
  local cl = add(label(checks, #cs > 0 and ("|cffff5050" .. table.concat(cs, "\n") .. "|r") or "|cff40ff40None.|r", "GameFontHighlightSmall"))
  cl:SetPoint("TOPLEFT", 4, y); cl:SetWidth(W - 40)
  y = y - 16 * math.max(1, #cs) - 10

  y = section(add, checks, "Deck keys found on this PC", y)
  local left = YB:DeckLeftovers()
  local intro = add(label(checks, ("|cffffffff%d of %d|r Deck keys and |cffffffff%d|r YB macros arrived here through Blizzard's server. " ..
    "Leave them: the Deck still needs them. Deck 6.0 removes them from both machines."):format(#left, #YB.deckKeys, YB:DeckMacros()),
    "GameFontHighlightSmall"))
  intro:SetPoint("TOPLEFT", 4, y); intro:SetWidth(W - 40)
  y = y - 34
  local col = 0
  for i, e in ipairs(left) do
    local l = add(label(checks, "|cffaad4ff" .. e.key .. "|r  " .. e.action, "GameFontHighlightSmall", true))
    l:SetWidth(270); l:SetPoint("TOPLEFT", 4 + col * 285, y)
    if col == 1 then y = y - 14 end
    col = 1 - col
  end
  if col == 1 then y = y - 14 end
end

---------------------------------------------------------------- switching
local builders = { setup = function() buildSetup() end, device = function() buildDevice() end, checks = function() buildChecks() end }
local current = "setup"
local function show(which)
  current = which
  for k, p in pairs(pages) do if k == which then p:Show() else p:Hide() end end
  for k, b in pairs(tabs) do if k == which then b:LockHighlight() else b:UnlockHighlight() end end
  local ok, err = pcall(builders[which]); if not ok then say("Error: " .. tostring(err), true) end
end
for k, b in pairs(tabs) do b:SetScript("OnClick", function() show(k) end) end

function YB:Toggle()
  if f:IsShown() then f:Hide() else say(""); f:Show(); show(current) end
end

SLASH_YAGRIVERBINDSPC1 = "/ybpc"
SlashCmdList["YAGRIVERBINDSPC"] = function() YB:Toggle() end

-- The Deck's synced "YB Settings" / "YB Panel" macros run /yag and /yagpanel: answer them here too,
-- unless the Deck edition itself is installed on this PC.
local alias = CreateFrame("Frame")
alias:RegisterEvent("PLAYER_LOGIN")
alias:SetScript("OnEvent", function()
  if YB.IsLoaded("YagriverBinds") then return end
  SLASH_YBPCDECKSETTINGS1 = "/yag"
  SlashCmdList["YBPCDECKSETTINGS"] = function() YB:Toggle() end
  SLASH_YBPCDECKPANEL1 = "/yagpanel"
  SlashCmdList["YBPCDECKPANEL"] = function() YagriverBinds_TogglePanel() end
end)

-- minimap button: left click = settings, right click = YB panel
local mm = CreateFrame("Button", "YagriverBindsPCMinimapButton", Minimap)
mm:SetSize(31, 31); mm:SetFrameStrata("MEDIUM"); mm:SetFrameLevel(8)
mm:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -2, -40)
mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
local icon = mm:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\Ability_Druid_Maul"); icon:SetSize(20, 20); icon:SetPoint("CENTER", 0, 1)
local border = mm:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetSize(53, 53); border:SetPoint("TOPLEFT")
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
mm:SetScript("OnClick", function(_, btn)
  if btn == "RightButton" then YagriverBinds_TogglePanel() else YB:Toggle() end
end)
mm:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("Yagriver Binds PC")
  GameTooltip:AddLine("Left click: settings", 1, 1, 1); GameTooltip:AddLine("Right click: YB panel", 1, 1, 1)
  GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)
