-- Yagriver Binds - YB panel: premade chat phrases + profession buttons.
--
-- Why it is built this way: in WoW: Forever addon code is not allowed to send chat messages
-- (the game blocks it, even from a button's own click handler). Macros ARE allowed. So every
-- phrase is a real macro ("YB Say 1" ... made by Apply binds) whose text is e.g. "/p Thanks!",
-- and each panel button simply runs that macro on your click: one click = one message.
-- The channel buttons rewrite the "/p" part of those macros (out of combat only).
local ADDON, YB = ...

local panel = CreateFrame("Frame", "YagriverBindsPanel", UIParent, "BasicFrameTemplateWithInset")
panel:SetSize(560, 400)
panel:SetPoint("CENTER", 0, 60)
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true); panel:EnableMouse(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", panel.StartMoving)
panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
panel:Hide()

local function text(font, str)
  local s = panel:CreateFontString(nil, "OVERLAY", font)
  s:SetJustifyH("LEFT"); s:SetText(str or "")
  return s
end
local title = text("GameFontHighlight", "YB panel"); title:ClearAllPoints(); title:SetPoint("TOP", 0, -5)
local chanLabel = text("GameFontNormalSmall", "Send to:"); chanLabel:SetPoint("TOPLEFT", 14, -30)
local note = text("GameFontHighlightSmall", ""); note:SetPoint("TOPLEFT", 14, -78); note:SetWidth(530)
local profLabel = text("GameFontNormalSmall", "Professions:"); profLabel:SetPoint("TOPLEFT", 14, -282)
local hint = text("GameFontDisableSmall", "Free text: R5 + D-pad down.   Edit a phrase: /macro, change the text after the channel.")
hint:SetPoint("BOTTOMLEFT", 14, 10)

local channelButtons, phraseButtons, profButtons = {}, {}, {}

local function warn(msg) if UIErrorsFrame then UIErrorsFrame:AddMessage(msg, 1, .3, .3) end end
local function useOnDown()
  if C_CVar and C_CVar.GetCVarBool then return C_CVar.GetCVarBool("ActionButtonUseKeyDown") end
  if GetCVarBool then return GetCVarBool("ActionButtonUseKeyDown") end
  return false
end
local function secure(w, h)
  local b = CreateFrame("Button", nil, panel, "SecureActionButtonTemplate,UIPanelButtonTemplate")
  b:SetSize(w, h)
  b:RegisterForClicks("AnyUp", "AnyDown")
  -- close the panel on the click that actually fires
  b:HookScript("PostClick", function(_, _, down)
    if (down and true or false) == (useOnDown() and true or false) and not YB.InCombat() then panel:Hide() end
  end)
  return b
end

-- "/p Thanks!" -> "p", "Thanks!"
local function split(body)
  if not body then return end
  local ch, phrase = body:match("^/(%S+)%s+(.+)$")
  return ch, phrase
end

-- channel the phrase macros currently point to (read from the macros themselves)
function YB:ChatChannel()
  for i = 1, #YB.chatPhrases do
    local ch = split(YB.MacroBody(YB.SayName(i)))
    if ch then return ch end
  end
  return YB.defaultChannel
end

-- rewrite "/<channel> " in every phrase macro, keeping the phrase text
function YB:SetChatChannel(ch)
  if YB.InCombat() then return false end
  for i = 1, #YB.chatPhrases do
    local name = YB.SayName(i)
    local idx = GetMacroIndexByName(name)
    if idx ~= 0 then
      local _, phrase = split(YB.MacroBody(name))
      pcall(EditMacro, idx, nil, nil, "/" .. ch .. " " .. (phrase or YB.chatPhrases[i]))
    end
  end
  return true
end

local function refresh()
  if YB.InCombat() then return end
  local ch = YB:ChatChannel()
  local missing = 0
  for i, b in ipairs(phraseButtons) do
    local _, phrase = split(YB.MacroBody(YB.SayName(i)))
    if phrase then b:SetText(phrase); b:Enable() else b:SetText(YB.chatPhrases[i]); b:Disable(); missing = missing + 1 end
  end
  for _, cb in ipairs(channelButtons) do
    if cb.slash == ch then cb:LockHighlight() else cb:UnlockHighlight() end
  end
  note:SetText(missing > 0 and "|cffff5050Phrases are not created yet: open /yag and press Apply binds.|r"
    or ("Click a phrase to send it to |cffffd100/" .. ch .. "|r."))
  -- professions: one button per known profession spell
  local n = 0
  for _, p in ipairs(YB.professions or {}) do
    local known
    for j = 2, #p do if YB.IsKnown(p[j]) then known = p[j] end end
    if known then
      n = n + 1
      local b = profButtons[n]
      if not b then
        b = secure(128, 24); profButtons[n] = b
        b:SetPoint("TOPLEFT", 14 + ((n - 1) % 4) * 132, -298 - math.floor((n - 1) / 4) * 26)
      end
      local name = YB.SpellName(known) or p[1]
      b:SetAttribute("type", "spell"); b:SetAttribute("spell", name)
      b:SetText(name); b:Show()
    end
  end
  for j = n + 1, #profButtons do profButtons[j]:Hide() end
  profLabel:SetText(n > 0 and "Professions:" or "Professions: none found yet")
end

local function build()
  if panel.built then return end
  panel.built = true
  for i, c in ipairs(YB.chatChannels or {}) do
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(64, 26); b:SetText(c[2])
    b:SetPoint("TOPLEFT", 14 + (i - 1) * 66, -46)
    b.slash = c[1]
    b:SetScript("OnClick", function(self)
      if not YB:SetChatChannel(self.slash) then warn("YB panel: can't change channel in combat") return end
      refresh()
    end)
    table.insert(channelButtons, b)
  end
  local cols, w, h = 2, 262, 30
  for i in ipairs(YB.chatPhrases or {}) do
    local b = secure(w, h - 3)
    local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
    b:SetPoint("TOPLEFT", 14 + col * (w + 6), -96 - row * h)
    b:SetAttribute("type", "macro")
    b:SetAttribute("macro", YB.SayName(i))   -- runs the real macro with that name
    table.insert(phraseButtons, b)
  end
end

function YagriverBinds_TogglePanel()
  if YB.InCombat() then warn("YB panel: not available in combat") return end
  build()
  if panel:IsShown() then panel:Hide() else refresh(); panel:Show() end
end

-- A window holding secure buttons can't be closed during combat: close it as combat starts.
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:SetScript("OnEvent", function() if panel:IsShown() then panel:Hide() end end)

SLASH_YAGRIVERPANEL1 = "/yagpanel"
SLASH_YAGRIVERPANEL2 = "/yagchat"
SlashCmdList["YAGRIVERPANEL"] = function() YagriverBinds_TogglePanel() end
