-- Yagriver Binds PC - YB panel: chat phrases, weapon sets and professions.
-- Addon code can't send chat in WoW: Forever, but a secure button carrying its own command text can,
-- on your click. So every phrase button holds "/p Thanks!" itself: no macros are created, so nothing
-- is copied to the Deck by Blizzard's server. The channel buttons rewrite that text (out of combat).
local ADDON, YB = ...

local panel = CreateFrame("Frame", "YagriverBindsPCPanel", UIParent, "BasicFrameTemplateWithInset")
panel:SetSize(560, 440)
panel:SetPoint("CENTER", 0, 60)
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true); panel:EnableMouse(true); panel:SetClampedToScreen(true)
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
local setLabel = text("GameFontNormalSmall", "Weapons:"); setLabel:SetPoint("TOPLEFT", 14, -282)
local profLabel = text("GameFontNormalSmall", "Professions:"); profLabel:SetPoint("TOPLEFT", 14, -330)

local channelButtons, phraseButtons, profButtons, setButtons = {}, {}, {}, {}

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

function YB:ChatChannel() return self:Global().channel or YB.defaultChannel end
function YB:Phrase(i)
  local custom = self:Global().phrases
  return (custom and custom[i]) or YB.chatPhrases[i]
end
function YB:PhraseText(i) return "/" .. self:ChatChannel() .. " " .. self:Phrase(i) end

local function refresh()
  if YB.InCombat() then return end
  local ch = YB:ChatChannel()
  for i, b in ipairs(phraseButtons) do
    b:SetAttribute("type", "macro")
    b:SetAttribute("macrotext", YB:PhraseText(i))
    b:SetText(YB:Phrase(i))
  end
  for _, cb in ipairs(channelButtons) do
    if cb.slash == ch then cb:LockHighlight() else cb:UnlockHighlight() end
  end
  note:SetText("Click a phrase to send it to |cffffd100/" .. ch .. "|r.")
  for _, s in ipairs(setButtons) do
    s:SetAttribute("type", "macro")
    s:SetAttribute("macrotext", YB:SetText(s.which))
    local w = YB:DB().weapons[s.which] or {}
    s:SetText((s.which == "caster" and "Caster set" or "Feral set") .. (w.mh and "" or " (not saved)"))
  end
  local n = 0
  for _, p in ipairs(YB.professions or {}) do
    local known
    for j = 2, #p do if YB.IsKnown(p[j]) then known = p[j] end end
    if known then
      n = n + 1
      local b = profButtons[n]
      if not b then
        b = secure(128, 24); profButtons[n] = b
        b:SetPoint("TOPLEFT", 14 + ((n - 1) % 4) * 132, -346 - math.floor((n - 1) / 4) * 26)
      end
      local name = YB.SpellName(known) or p[1]
      b:SetAttribute("type", "spell"); b:SetAttribute("spell", name)
      b:SetText(name); b:Show()
    end
  end
  for j = n + 1, #profButtons do profButtons[j]:Hide() end
  profLabel:SetText(n > 0 and "Professions:" or "Professions: none found yet")
end
function YB.RefreshPanelSets() if panel:IsShown() then refresh() end end

local function build()
  if panel.built then return end
  panel.built = true
  for i, c in ipairs(YB.chatChannels or {}) do
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(64, 26); b:SetText(c[2])
    b:SetPoint("TOPLEFT", 14 + (i - 1) * 66, -46)
    b.slash = c[1]
    b:SetScript("OnClick", function(self)
      if YB.InCombat() then warn("YB panel: can't change channel in combat") return end
      YB:Global().channel = self.slash
      refresh()
    end)
    table.insert(channelButtons, b)
  end
  local cols, w, h = 2, 262, 30
  for i in ipairs(YB.chatPhrases or {}) do
    local b = secure(w, h - 3)
    local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
    b:SetPoint("TOPLEFT", 14 + col * (w + 6), -96 - row * h)
    table.insert(phraseButtons, b)
  end
  for i, which in ipairs({ "caster", "feral" }) do
    local b = secure(160, 24)
    b.which = which
    b:SetPoint("TOPLEFT", 14 + (i - 1) * 166, -298)
    table.insert(setButtons, b)
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

SLASH_YAGRIVERPCPANEL1 = "/ybpanel"
SlashCmdList["YAGRIVERPCPANEL"] = function() YagriverBinds_TogglePanel() end
