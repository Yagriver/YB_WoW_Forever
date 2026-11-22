-- Yagriver Binds PC - quiet weapon hint (two rows: what to equip / how).
-- Shows only when the weapon doesn't match the form:
--   Bear/Cat wearing the caster set   ->  Feral weapon  / your key (PC) or "YB panel" (Switch)
--   caster form wearing the feral set ->  Caster weapon / same
-- Never equips anything. Size and position are saved per mode (PC / Switch).
local ADDON, YB = ...

local hint = CreateFrame("Frame", "YagriverBindsPCWeaponHint", UIParent)
hint:SetFrameStrata("MEDIUM")
hint:SetClampedToScreen(true)
hint:Hide()
local bg = hint:CreateTexture(nil, "BACKGROUND")
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

local function itemIcon(id)
  if not id then return end
  if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(id) end
  if GetItemIcon then return GetItemIcon(id) end
end

-- second row: how to swap in the current mode
local function how(kind)
  if YB:ModeKey() == "switch" then return "YB panel" end
  local key = YB:Global().keys[kind]
  return key and YB:KeyText(key) or "YB panel"
end

local function setContent(kind, itemID)
  icon:SetTexture(itemIcon(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
  line1:SetText(kind == "feral" and "Feral weapon" or "Caster weapon")
  line2:SetText(how(kind))
  local w = math.max(line1:GetStringWidth() or 90, line2:GetStringWidth() or 60)
  hint:SetSize(4 + 30 + 7 + w + 8, 38)
end

-- size and position of the active mode (position = centre as a fraction of the screen)
function YB.LayoutHint()
  local h = YB:Mode().hint
  hint:SetScale(h.scale)
  local W, H = UIParent:GetWidth(), UIParent:GetHeight()
  hint:ClearAllPoints()
  hint:SetPoint("CENTER", UIParent, "BOTTOMLEFT", h.x * W / h.scale, h.y * H / h.scale)
end

function YB.UpdateWeaponHint()
  if moving then return end
  local db = YagriverBindsPCCharDB
  if not db or not db.weaponHint or not db.weapons then hint:Hide() return end
  local _, class = UnitClass("player")
  if class ~= "DRUID" then hint:Hide() return end
  local c, f = db.weapons.caster or {}, db.weapons.feral or {}
  if not c.mh or not f.mh or c.mh == f.mh then hint:Hide() return end
  local mh = GetInventoryItemID("player", 16)
  local idx = GetShapeshiftForm and GetShapeshiftForm() or 0
  local feral = false
  if idx and idx > 0 then
    local sid = YB.FormSpellID(idx)
    for _, id in ipairs(YB.feralForms) do if id == sid then feral = true end end
  end
  if feral and mh == c.mh then setContent("feral", f.mh)
  elseif (idx or 0) == 0 and mh == f.mh then setContent("caster", c.mh)
  else hint:Hide() return end
  YB.LayoutHint()
  hint:Show()
end

function YB:HintScale(delta)
  local h = self:Mode().hint
  h.scale = math.floor(math.max(0.8, math.min(2.5, h.scale + delta)) * 10 + 0.5) / 10
  YB.LayoutHint()
  return true, ("Hint size %.1f (saved for %s)."):format(h.scale, YB.MODE_NAMES[self:ModeKey()])
end
function YB:HintReset()
  local m = self:ModeKey()
  local d = YB.HINT_DEFAULTS[m]
  self:Mode().hint = { scale = d.scale, x = d.x, y = d.y }
  YB.LayoutHint()
  return true, ("Hint size and position reset for %s."):format(YB.MODE_NAMES[m])
end
function YB:HintMoving() return moving end
function YB:HintMove(on)
  moving = on
  bg:SetShown(on); edge:SetShown(on); moveLabel:SetShown(on)
  hint:EnableMouse(on); hint:SetMovable(on)
  if on then
    local db = YagriverBindsPCCharDB or {}
    local f = db.weapons and db.weapons.feral or {}
    setContent("feral", f.mh)
    YB.LayoutHint()
    hint:Show()
    return true, "Drag the sample hint, then press Done."
  end
  YB.UpdateWeaponHint()
  return true, ("Hint position saved for %s."):format(YB.MODE_NAMES[YB:ModeKey()])
end
hint:RegisterForDrag("LeftButton")
hint:SetScript("OnDragStart", function(self) if moving then self:StartMoving() end end)
hint:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  if self.SetUserPlaced then self:SetUserPlaced(false) end
  local h = YB:Mode().hint
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
