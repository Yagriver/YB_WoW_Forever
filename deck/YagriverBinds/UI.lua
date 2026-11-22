-- Yagriver Binds - settings window: Setup, Keybinds and Device tabs.
-- Open with the minimap paw, /yag, or R5 + left pad "YB menu".
local ADDON, YB = ...

local W, H = 600, 600
local GOLD = { 1, 0.82, 0 }

local f = CreateFrame("Frame", "YagriverBindsFrame", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(W, H)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "YagriverBindsFrame")

---------------------------------------------------------------- small widget helpers
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
title:SetText("|cffffd100Yagriver|r Binds  |cff888888v5.5|r")

---------------------------------------------------------------- tabs
local pages, tabs = {}, {}
local function page()
  local p = CreateFrame("Frame", nil, f)
  p:SetPoint("TOPLEFT", 14, -66); p:SetPoint("BOTTOMRIGHT", -14, 48)
  p:Hide()
  return p
end
local setup, list, device, deckmap = page(), page(), page(), page()
pages.setup, pages.list, pages.device, pages.deckmap = setup, list, device, deckmap

local tabDefs = { { "setup", "Setup" }, { "list", "Keybinds" }, { "device", "Device" }, { "deckmap", "Deck map" } }
for i, d in ipairs(tabDefs) do
  local b = button(f, d[2], 96, 24)
  b:SetPoint("TOPLEFT", 14 + (i - 1) * 100, -30)
  tabs[d[1]] = b
end
local tabPanel = button(f, "Chat + Prof. panel", 140, 24); tabPanel:SetPoint("TOPRIGHT", -14, -30)
tabPanel:SetScript("OnClick", function() if YagriverBinds_TogglePanel then YagriverBinds_TogglePanel() end end)
tip(tabPanel, "Opens the chat phrases and profession panel (also R5 + left pad, Chat+Prof).")

local tabLine = rect(f, GOLD[1], GOLD[2], GOLD[3], 0.35, "ARTWORK")
tabLine:SetPoint("TOPLEFT", 12, -58); tabLine:SetPoint("TOPRIGHT", -12, -58); tabLine:SetHeight(1)

---------------------------------------------------------------- footer status bar
local footer = rect(f, 0, 0, 0, 0.45, "BORDER")
footer:SetPoint("BOTTOMLEFT", 8, 8); footer:SetPoint("BOTTOMRIGHT", -8, 8); footer:SetHeight(34)
local status = label(f, "", "GameFontHighlight")
status:SetPoint("BOTTOMLEFT", 16, 14); status:SetPoint("BOTTOMRIGHT", -16, 14); status:SetHeight(24)
status:SetJustifyV("MIDDLE")

local function say(msg, isError)
  if not msg or msg == "" then status:SetText("|cff888888Ready.|r"); return end
  status:SetText((isError and "|cffff5050" or "|cff40ff40") .. msg .. "|r")
  print("|cff88ccffYagriver Binds:|r " .. msg)
  if UIErrorsFrame then UIErrorsFrame:AddMessage(msg, isError and 1 or 0.3, isError and 0.3 or 1, 0.3) end
end
YB.Say = say
-- run an action safely and always show what happened
local function run(fn, after)
  local ok, res, msg = pcall(fn)
  if not ok then say("Error: " .. tostring(res), true)
  else say(msg or (res and "Done." or "Nothing changed."), not res) end
  if after then pcall(after) end
  if YB.pendingReload then YB.pendingReload = nil; ReloadUI() end   -- controller mode needs it, like Blizzard's menu
end

---------------------------------------------------------------- page content helpers
-- Every page is rebuilt from scratch each time it is shown; widgets are recycled per page.
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

---------------------------------------------------------------- SETUP
local confirmUntil = 0   -- cleanup needs a second click within 15 seconds
local showGroups = false -- groups are a first-run choice: folded by default
local buildSetup
buildSetup = function()
  local add = holder(setup)
  local db = YB:DB()
  local p, token = YB:ClassProfile()
  local y = 0
  local head = add(label(setup, p and ("|cffffffffProfile:|r " .. p.name ..
    "   |cff888888changes here need Apply binds|r") or
    ("|cffff5050No profile for " .. (token or "?") .. ".|r Only shared binds are listed; Apply is disabled."), "GameFontHighlight"))
  head:SetPoint("TOPLEFT", 0, y); head:SetWidth(W - 40); y = y - 22

  y = section(add, setup, "Groups to apply", y)
  local groups = YB:Groups()
  local on = 0
  for _, g in ipairs(groups) do if YB:GroupEnabled(g) then on = on + 1 end end
  local gl = add(label(setup, ("|cffffffff%d of %d|r groups enabled"):format(on, #groups), "GameFontHighlight"))
  gl:SetPoint("TOPLEFT", 4, y - 5)
  local gb = add(button(setup, showGroups and "Hide groups" or "Show groups", 120, 22)); gb:SetPoint("TOPLEFT", 200, y)
  gb:SetScript("OnClick", function() showGroups = not showGroups; buildSetup() end)
  y = y - 28
  if showGroups then
    for i, g in ipairs(groups) do
      local c = add(check(setup, g.label, function(v) db.groups[g.id] = v end))
      add(c.text); c.text:SetWidth(250)
      local col = (i - 1) % 2
      c:SetPoint("TOPLEFT", col * 285, y)
      c:SetChecked(YB:GroupEnabled(g))
      if col == 1 then y = y - 22 end
    end
    if #groups % 2 == 1 then y = y - 22 end
  end
  y = y - 6

  if p and p.weapons then
    y = section(add, setup, "Weapon sets", y)
    for _, which in ipairs({ "feral", "caster" }) do
      local l = add(label(setup, (which == "feral" and "|cffffffffFeral:|r  " or "|cffffffffCaster:|r ") ..
        YB:WeaponText(which), "GameFontHighlightSmall", true))
      l:SetPoint("TOPLEFT", 4, y - 6); l:SetWidth(360)
      local b = add(button(setup, "Use equipped", 110, 24)); b:SetPoint("TOPLEFT", 375, y)
      tip(b, "Wear this set first, then click. The weapon key updates at once.")
      b:SetScript("OnClick", function() run(function() return YB:CaptureWeapons(which) end, buildSetup) end)
      local cl = add(button(setup, "Clear", 60, 24)); cl:SetPoint("LEFT", b, "RIGHT", 4, 0)
      cl:SetScript("OnClick", function() run(function() return YB:ClearWeapons(which) end, buildSetup) end)
      y = y - 26
    end
    local hk = add(label(setup, "|cff888888Swap by hand: |r|cffffffffR5 + D-pad left|r|cff888888 = caster set,  |r|cffffffffR5 + D-pad right|r|cff888888 = feral set.|r", "GameFontHighlightSmall"))
    hk:SetPoint("TOPLEFT", 4, y - 4); y = y - 22
    local wh = add(check(setup, "Show a small hint when the weapon doesn't match the form", function(v)
      db.weaponHint = v; if YB.UpdateWeaponHint then YB.UpdateWeaponHint() end
    end))
    add(wh.text); wh:SetPoint("TOPLEFT", 0, y); wh:SetChecked(db.weaponHint); y = y - 26
  end

  y = section(add, setup, "Safety", y)
  local sk = add(check(setup, "Apply skips keys already used by something else (safer for PC)", function(v) db.skipConflicts = v end))
  add(sk.text); sk:SetPoint("TOPLEFT", 0, y); sk:SetChecked(db.skipConflicts)

  -- three clearly different actions
  local ap = add(button(setup, "Apply binds", 140, 28)); ap:SetPoint("BOTTOMLEFT", 0, 2)
  tip(ap, "Creates/updates the YB macros and binds the keys. Never deletes anything.")
  ap:SetScript("OnClick", function() run(function() return YB:Apply() end, buildSetup) end)
  if not p then ap:Disable() else ap:Enable() end
  local rm = add(button(setup, "Remove binds", 140, 28)); rm:SetPoint("LEFT", ap, "RIGHT", 8, 0)
  tip(rm, "Unbinds the YB keys and restores what they did before. Macros are kept.")
  rm:SetScript("OnClick", function() run(function() return YB:Remove() end, buildSetup) end)

  local del, kept = YB:FindLegacy()
  local armed = GetTime and GetTime() < confirmUntil
  local cu = add(button(setup, armed and ("CONFIRM: delete " .. #del) or ("Clean old macros (" .. #del .. ")"), 200, 28))
  cu:SetPoint("BOTTOMRIGHT", 0, 2)
  tip(cu, "Deletes macros left by OLDER versions of this addon. Two clicks. Your own macros are never touched.")
  if #del == 0 then cu:Disable() else cu:Enable() end
  cu:SetScript("OnClick", function()
    if GetTime() < confirmUntil then
      confirmUntil = 0
      run(function() return YB:DeleteLegacy() end, buildSetup)
    else
      confirmUntil = GetTime() + 15
      local msg = "This DELETES " .. #del .. " old macros: " .. table.concat(del, ", ") ..
        ". Click CONFIRM within 15 s, or do nothing to cancel."
      if #kept > 0 then msg = msg .. " Kept (your own text): " .. table.concat(kept, ", ") .. "." end
      say(msg, true)
      buildSetup()
    end
  end)
end

---------------------------------------------------------------- KEYBINDS
local scroll = CreateFrame("ScrollFrame", nil, list, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, -22); scroll:SetPoint("BOTTOMRIGHT", -24, 0)
local content = CreateFrame("Frame", nil, scroll); content:SetSize(W - 60, 10)
scroll:SetScrollChild(content)

local COLS = { 0, 160, 270, 450 }
local hdrBg = rect(list, GOLD[1], GOLD[2], GOLD[3], 0.12)
hdrBg:SetPoint("TOPLEFT", 0, 0); hdrBg:SetPoint("TOPRIGHT", -24, 0); hdrBg:SetHeight(18)
for i, h in ipairs({ "Steam Deck", "Key", "Action", "Now" }) do
  local s = label(list, h, "GameFontNormalSmall"); s:SetPoint("TOPLEFT", COLS[i] + 4, -3)
end

local rows = {}
local COLORS = { ours = "|cff40ff40OK|r", free = "|cffffff00not set|r",
  made = "|cff40ff40macro ready|r", nomacro = "|cffffff00not created|r" }
local function row(i)
  if rows[i] then return rows[i] end
  local r = {}
  r.bg   = rect(content, 1, 1, 1, 0.04)
  r.bar  = rect(content, GOLD[1], GOLD[2], GOLD[3], 1, "BORDER")
  r.deck = label(content, "", "GameFontHighlightSmall", true)
  r.key  = label(content, "", "GameFontHighlightSmall", true)
  r.act  = label(content, "", "GameFontHighlightSmall", true)
  r.st   = label(content, "", "GameFontHighlightSmall", true)
  rows[i] = r
  return r
end

local function buildList()
  for _, r in pairs(rows) do for _, s in pairs(r) do s:Hide() end end
  local i, y, n = 0, 0, 0
  for _, g in ipairs(YB:Groups()) do
    i = i + 1
    local r = row(i)
    r.bg:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.10)
    r.bg:SetPoint("TOPLEFT", 0, y); r.bg:SetPoint("RIGHT", content, "RIGHT", 0, 0); r.bg:SetHeight(18); r.bg:Show()
    r.bar:SetPoint("TOPLEFT", 0, y); r.bar:SetSize(3, 18); r.bar:Show()
    r.deck:SetText("|cffffd100" .. g.label .. "|r"); r.deck:SetWidth(500)
    r.deck:SetPoint("TOPLEFT", 9, y - 3); r.deck:Show()
    y = y - 20
    for _, e in ipairs(g.binds) do
      i = i + 1; n = n + 1
      r = row(i)
      local okS, st, cur = pcall(YB.Status, YB, e)
      if not okS then st, cur = "taken", "error: " .. tostring(st) end
      r.bg:SetColorTexture(1, 1, 1, (n % 2 == 0) and 0.05 or 0)
      r.bg:SetPoint("TOPLEFT", 0, y + 1); r.bg:SetPoint("RIGHT", content, "RIGHT", 0, 0); r.bg:SetHeight(16)
      r.deck:SetWidth(COLS[2] - 8); r.key:SetWidth(COLS[3] - COLS[2] - 6)
      r.act:SetWidth(COLS[4] - COLS[3] - 6); r.st:SetWidth(W - 60 - COLS[4])
      r.deck:SetText("|cffaad4ff" .. (e.deck or "") .. "|r")
      r.key:SetText(e.key or "|cff888888(no key)|r")
      r.act:SetText(e.label)
      if st == "info" then
        r.st:SetText("|cff999999" .. ((cur and cur ~= "") and cur or "info") .. "|r")
      else
        r.st:SetText(COLORS[st] or ("|cffff6060used: " .. (cur or "") .. "|r"))
      end
      r.deck:SetPoint("TOPLEFT", COLS[1] + 4, y); r.key:SetPoint("TOPLEFT", COLS[2] + 4, y)
      r.act:SetPoint("TOPLEFT", COLS[3] + 4, y); r.st:SetPoint("TOPLEFT", COLS[4] + 4, y)
      for k2, s in pairs(r) do if k2 ~= "bar" then s:Show() end end
      y = y - 16
    end
    y = y - 6
  end
  content:SetHeight(-y + 10)
end

---------------------------------------------------------------- DEVICE
local buildDevice
buildDevice = function()
  local add = holder(device)
  local g = YB:Global()
  local y = 0

  y = section(add, device, "Mode", y)
  local modes = { { "handheld", "Handheld (Deck)", "Controller ON, bigger UI, big hint" },
                  { "docked", "Docked (monitor)", "Controller OFF, smaller UI, small hint" } }
  local MEDIA = "Interface\\AddOns\\YagriverBinds\\Media\\"
  for i, m in ipairs(modes) do
    local b = add(button(device, m[2], 270, 40))
    b:SetPoint("TOPLEFT", (i - 1) * 290, y)
    if g.mode == m[1] then b:LockHighlight() else b:UnlockHighlight() end
    local ic = add(b:CreateTexture(nil, "OVERLAY"))
    if m[1] == "handheld" then
      ic:SetTexture(MEDIA .. "deck_front"); ic:SetTexCoord(0, 1, 0, 399 / 512); ic:SetSize(62, 24)
    else
      ic:SetTexture(MEDIA .. "monitor"); ic:SetTexCoord(0, 1, 0, 1); ic:SetSize(30, 30)
    end
    ic:SetPoint("LEFT", b, "LEFT", 12, 0)
    local saved = g.modes[m[1]]
    tip(b, m[3] .. ".\nSaved: controller " .. (saved.pad and "ON" or "OFF") ..
      ", UI scale " .. (saved.scale and ("%.2f"):format(saved.scale) or "current"))
    b:SetScript("OnClick", function() run(function() return YB:ApplyMode(m[1]) end, buildDevice) end)
    local sub = add(label(device, "|cff888888" .. m[3] .. "|r" .. (g.mode == m[1] and "  |cff40ff40(active)|r" or ""),
      "GameFontHighlightSmall", true))
    sub:SetPoint("TOPLEFT", (i - 1) * 290 + 4, y - 44)
  end
  y = y - 70

  y = section(add, device, "Controller", y)
  if YB:PadKnown() then
    local on = YB:PadOn()
    local pb = add(button(device, on and "Controller: ON" or "Controller: OFF", 170, 28))
    pb:SetPoint("TOPLEFT", 0, y)
    tip(pb, "Forever's 'Enable Gamepad UI'. Switching it reloads the interface, like Blizzard's menu.\nSaved into the active mode.")
    pb:SetScript("OnClick", function() run(function() return YB:SetPad(not YB:PadOn()) end, buildDevice) end)
    local pl = add(label(device, (on and "|cff40ff40Gamepad UI on|r" or "|cffffff00Keyboard + mouse|r") ..
      "  |cff888888(reloads the interface)|r", "GameFontHighlight"))
    pl:SetPoint("LEFT", pb, "RIGHT", 12, 0)
    local again = add(button(device, "Detect again", 110, 22)); again:SetPoint("TOPRIGHT", device, "TOPRIGHT", 0, y - 3)
    again:SetScript("OnClick", function() run(function() YB:ForgetPad(); return YB:DetectPad() end, buildDevice) end)
    y = y - 32
  else
    local fb = add(button(device, "Find in options", 150, 28)); fb:SetPoint("TOPLEFT", 0, y)
    tip(fb, "Searches WoW's options panel for the 'Enable Gamepad UI' checkbox and uses it from now on.")
    fb:SetScript("OnClick", function() run(function() return YB:FindPadSetting() end, buildDevice) end)
    local step2 = g.padSnap ~= nil
    local db = add(button(device, step2 and "Detect: step 2" or "Detect: step 1", 130, 28))
    db:SetPoint("LEFT", fb, "RIGHT", 8, 0)
    tip(db, "Plan B if 'Find in options' fails.\nStep 1 saves all settings. Then switch the option in WoW's Options (the game reloads). Step 2 compares.")
    db:SetScript("OnClick", function() run(function() return YB:DetectPad() end, buildDevice) end)
    local dl = add(label(device, step2 and "|cffffff00Switch 'Enable Gamepad UI' in WoW Options, then step 2.|r"
      or "|cff888888Not set up yet.|r", "GameFontHighlightSmall"))
    dl:SetPoint("LEFT", db, "RIGHT", 10, 0); dl:SetWidth(W - 330)
    y = y - 32
  end
  local rs = add(check(device, "Right stick always moves the camera (WoW cursor won't take it in menus)", function(v)
    run(function() return YB:SetStickCamera(v) end, buildDevice)
  end))
  add(rs.text); rs:SetPoint("TOPLEFT", 0, y); rs:SetChecked(YB:StickCameraOn())
  y = y - 32

  y = section(add, device, "UI scale", y)
  local cur = YB:Scale()
  local minus = add(button(device, "-", 44, 30)); minus:SetPoint("TOPLEFT", 0, y)
  local val = add(label(device, ("%.2f"):format(cur), "GameFontNormalLarge")); val:SetPoint("LEFT", minus, "RIGHT", 16, 0)
  local plus = add(button(device, "+", 44, 30)); plus:SetPoint("LEFT", minus, "RIGHT", 72, 0)
  local reset = add(button(device, "1.00", 60, 30)); reset:SetPoint("LEFT", plus, "RIGHT", 12, 0)
  minus:SetScript("OnClick", function() run(function() return YB:SetScale(YB:Scale() - 0.05) end, buildDevice) end)
  plus:SetScript("OnClick", function() run(function() return YB:SetScale(YB:Scale() + 0.05) end, buildDevice) end)
  reset:SetScript("OnClick", function() run(function() return YB:SetScale(1) end, buildDevice) end)
  local sh = add(label(device, "|cff888888Steps of 0.05 (0.64 to 1.15), saved into the active mode.|r", "GameFontHighlightSmall"))
  sh:SetPoint("LEFT", reset, "RIGHT", 14, 0)
  y = y - 40

  y = section(add, device, "Weapon hint", y)
  local h = g.modes[YB:ModeKey()].hint
  local hm = add(button(device, "-", 44, 30)); hm:SetPoint("TOPLEFT", 0, y)
  local hv = add(label(device, ("%.1f"):format(h.scale), "GameFontNormalLarge")); hv:SetPoint("LEFT", hm, "RIGHT", 18, 0)
  local hp = add(button(device, "+", 44, 30)); hp:SetPoint("LEFT", hm, "RIGHT", 72, 0)
  hm:SetScript("OnClick", function() run(function() return YB:HintScale(-0.1) end, buildDevice) end)
  hp:SetScript("OnClick", function() run(function() return YB:HintScale(0.1) end, buildDevice) end)
  local mv = add(button(device, YB:HintMoving() and "Done" or "Move", 90, 30)); mv:SetPoint("LEFT", hp, "RIGHT", 16, 0)
  if YB:HintMoving() then mv:LockHighlight() else mv:UnlockHighlight() end
  tip(mv, "Shows a sample hint you can drag with the right trackpad. Press Done to keep the position.")
  mv:SetScript("OnClick", function() run(function() return YB:HintMove(not YB:HintMoving()) end, buildDevice) end)
  local rr = add(button(device, "Reset", 80, 30)); rr:SetPoint("LEFT", mv, "RIGHT", 8, 0)
  rr:SetScript("OnClick", function() run(function() return YB:HintReset() end, buildDevice) end)
  local hl = add(label(device, "|cff888888for " .. (YB:ModeKey() == "handheld" and "Handheld" or "Docked") .. "|r", "GameFontHighlightSmall"))
  hl:SetPoint("LEFT", rr, "RIGHT", 12, 0)
  y = y - 40

  local note = add(label(device, "|cff888888Device settings are shared by all your characters and can't be changed in combat.|r",
    "GameFontHighlightSmall"))
  note:SetPoint("TOPLEFT", 0, y); note:SetWidth(W - 40)
end

---------------------------------------------------------------- switching
local builders = { setup = function() buildSetup() end, list = function() buildList() end, device = function() buildDevice() end,
  deckmap = function() YB:DeckMapBuild(deckmap); YB:DeckMapShow() end }
local current = "setup"
local function show(which)
  current = which
  if which == "deckmap" and YB.DeckMapSize then f:SetSize(YB.DeckMapSize[1], YB.DeckMapSize[2]) else f:SetSize(W, H) end
  for k, p in pairs(pages) do if k == which then p:Show() else p:Hide() end end
  for k, b in pairs(tabs) do if k == which then b:LockHighlight() else b:UnlockHighlight() end end
  local ok, err = pcall(builders[which]); if not ok then say("Error: " .. tostring(err), true) end
end
for k, b in pairs(tabs) do b:SetScript("OnClick", function() show(k) end) end

function YB:Toggle()
  if f:IsShown() then f:Hide() else say(""); confirmUntil = 0; f:Show(); show(current) end
end

SLASH_YAGRIVERBINDS1 = "/yag"
SLASH_YAGRIVERBINDS2 = "/yagbinds"
SlashCmdList["YAGRIVERBINDS"] = function() YB:Toggle() end

-- minimap button: left click = settings, right click = chat + professions panel ----
local mm = CreateFrame("Button", "YagriverBindsMinimapButton", Minimap)
mm:SetSize(31, 31); mm:SetFrameStrata("MEDIUM"); mm:SetFrameLevel(8)
mm:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -2, -40)
mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
local icon = mm:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\Ability_Druid_Maul"); icon:SetSize(20, 20); icon:SetPoint("CENTER", 0, 1)
local border = mm:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetSize(53, 53); border:SetPoint("TOPLEFT")
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
mm:SetScript("OnClick", function(_, btn)
  if btn == "RightButton" and YagriverBinds_TogglePanel then YagriverBinds_TogglePanel() else YB:Toggle() end
end)
mm:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("Yagriver Binds")
  GameTooltip:AddLine("Left click: settings", 1, 1, 1); GameTooltip:AddLine("Right click: chat + professions panel", 1, 1, 1)
  GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)
