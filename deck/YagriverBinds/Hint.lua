-- Yagriver Binds - quiet weapon hint (two rows: what to equip / which buttons).
-- Shows only when the weapon doesn't match the form:
--   Bear/Cat wearing the caster set   ->  Feral weapon  /  R5 + [right arrow]
--   caster form wearing the feral set ->  Caster weapon /  R5 + [left arrow]
-- Never equips anything. Size and position are saved per device mode (Handheld / Docked):
-- /yag > Device > Weapon hint (size, Move, Reset). Off switch: /yag > Setup > Weapon sets.
local ADDON, YB = ...
local MEDIA = "Interface\\AddOns\\YagriverBinds\\Media\\"

local hint = CreateFrame("Frame", "YagriverBindsWeaponHint", UIParent)
hint:SetFrameStrata("MEDIUM")
hint:SetClampedToScreen(true)
hint:Hide()
local bg = hint:CreateTexture(nil, "BACKGROUND")      -- only visible while moving
bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0.55)
local edge = hint:CreateTexture(nil, "BORDER")
edge:SetPoint("TOPLEFT", -2, 2); edge:SetPoint("BOTTOMRIGHT", 2, -2); edge:SetColorTexture(1, 0.82, 0, 0.8)
bg:SetDrawLayer("BACKGROUND", 1); edge:SetDrawLayer("BACKGROUND", 0)
local icon = hint:CreateTexture(nil, "ARTWORK")
icon:SetSize(30, 30); icon:SetPoint("LEFT", 4, 0)
local line1 = hint:CreateFontString(nil, "OVERLAY", "GameFontNormal")
line1:SetPoint("TOPLEFT", icon, "TOPRIGHT", 7, 1); line1:SetJustifyH("LEFT")
line1:SetTextColor(0.95, 0.85, 0.55)
local line2 = hint:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
line2:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 7, -1); line2:SetJustifyH("LEFT")
local moveLabel = hint:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
moveLabel:SetPoint("TOP", hint, "BOTTOM", 0, -4); moveLabel:SetText("drag me, then press Done in /yag > Device")

local moving = false
local ARROW = { right = "|T" .. MEDIA .. "arrow_right:16:16|t", left = "|T" .. MEDIA .. "arrow_left:16:16|t" }

local function itemIcon(id)
  if not id then return end
  if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
  if GetItemIcon then return GetItemIcon(id) end
end

local function setContent(kind, itemID)
  icon:SetTexture(itemIcon(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
  if kind == "feral" then
    line1:SetText("Feral weapon"); line2:SetText("R5 + " .. ARROW.right)
  else
    line1:SetText("Caster weapon"); line2:SetText("R5 + " .. ARROW.left)
  end
  local w = math.max(line1:GetStringWidth() or 90, line2:GetStringWidth() or 60)
  hint:SetSize(4 + 30 + 7 + w + 8, 38)
end

-- size and position of the active mode (position = centre as a fraction of the screen)
function YB.LayoutHint()
  local h = YB:Global().modes[YB:ModeKey()].hint
  hint:SetScale(h.scale)
  local W, H = UIParent:GetWidth(), UIParent:GetHeight()
  hint:ClearAllPoints()
  hint:SetPoint("CENTER", UIParent, "BOTTOMLEFT", h.x * W / h.scale, h.y * H / h.scale)
end

function YB.UpdateWeaponHint()
  if moving then return end
  local db, p = YagriverBindsCharDB, YB:ClassProfile()
  if not db or not db.weaponHint or not p or not p.feralForms or not db.weapons then hint:Hide() return end
  local c, f = db.weapons.caster or {}, db.weapons.feral or {}
  if not c.mh or not f.mh or c.mh == f.mh then hint:Hide() return end
  local mh = GetInventoryItemID("player", 16)
  local idx = GetShapeshiftForm and GetShapeshiftForm() or 0
  local feral = false
  if idx and idx > 0 then
    local sid = YB.FormSpellID(idx)
    for _, id in ipairs(p.feralForms) do if id == sid then feral = true end end
  end
  if feral and mh == c.mh then setContent("feral", f.mh)
  elseif (idx or 0) == 0 and mh == f.mh then setContent("caster", c.mh)
  else hint:Hide() return end
  YB.LayoutHint()
  hint:Show()
end

-- size: -/+ steps of 0.1, saved into the active mode
function YB:HintScale(delta)
  local h = self:Global().modes[self:ModeKey()].hint
  h.scale = math.floor(math.max(0.8, math.min(2.5, h.scale + delta)) * 10 + 0.5) / 10
  YB.LayoutHint()
  return true, ("Hint size %.1f (saved for %s)."):format(h.scale, self:ModeKey())
end
function YB:HintReset()
  local m = self:ModeKey()
  local d = YB.HINT_DEFAULTS[m]
  self:Global().modes[m].hint = { scale = d.scale, x = d.x, y = d.y }
  YB.LayoutHint()
  return true, ("Hint size and position reset for %s."):format(m)
end
function YB:HintMoving() return moving end
function YB:HintMove(on)
  moving = on
  bg:SetShown(on); edge:SetShown(on); moveLabel:SetShown(on)
  hint:EnableMouse(on); hint:SetMovable(on)
  if on then
    local db = YagriverBindsCharDB or {}
    local f = db.weapons and db.weapons.feral or {}
    setContent("feral", f.mh)          -- sample, shown even if the weapon matches
    YB.LayoutHint()
    hint:Show()
    return true, "Drag the hint with the right trackpad, then press Done."
  end
  YB.UpdateWeaponHint()
  return true, ("Hint position saved for %s."):format(YB:ModeKey())
end
hint:RegisterForDrag("LeftButton")
hint:SetScript("OnDragStart", function(self) if moving then self:StartMoving() end end)
hint:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  if self.SetUserPlaced then self:SetUserPlaced(false) end
  local h = YB:Global().modes[YB:ModeKey()].hint
  local cx, cy = self:GetCenter()
  h.x = cx * h.scale / UIParent:GetWidth()
  h.y = cy * h.scale / UIParent:GetHeight()
  YB.LayoutHint()
end)
bg:Hide(); edge:Hide(); moveLabel:Hide()

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS",
                     "PLAYER_EQUIPMENT_CHANGED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do
  ev:RegisterEvent(e)
end
ev:SetScript("OnEvent", function() YB.UpdateWeaponHint() end)
