-- Yagriver Binds - Deck map tab: what every Steam Deck control does, in three views.
-- Pictures live in Media\ (front/back of the Deck, menu icons). Edit the texts in LABELS / VIEWS.
local ADDON, YB = ...

local MEDIA = "Interface\\AddOns\\YagriverBinds\\Media\\"
local GOLD = { 1, 0.82, 0 }
local HOLD = "|cff9fd0ffHold|r"           -- WoW text can't be italic: "Hold" gets its own color

-- Control positions measured on the source images (front 1729x674, back mirrored 1720x657)
local FRONT = { L1 = { 218, 12 }, L2 = { 120, 8 }, R1 = { 1508, 12 }, R2 = { 1610, 8 },
  SE = { 250, 72 }, ST = { 1478, 72 }, DP = { 118, 152 }, LST = { 278, 182 }, AB = { 1618, 146 },
  RST = { 1453, 182 }, LP = { 238, 372 }, RP = { 1493, 372 } }
local BACK = { L4 = { 248, 275 }, L5 = { 260, 433 }, R4 = { 1473, 274 }, R5 = { 1460, 432 } }
local FRONT_W, FRONT_H, BACK_W, BACK_H = 1729, 674, 1720, 657

-- Normal view (Combat set, nothing held). Lines starting with "Hold" get the Hold color.
local LABELS = {
  L1 = { "L1", "Target friend" }, L2 = { "L2", "Skill modifier", "Hold + left pad = party" },
  SE = { "View (Select)", "Focus menu", "Hold = switch to Town" }, DP = { "D-pad", "Skills" },
  LST = { "Left stick", "Move" }, LP = { "Left pad", "Scroll", "Click = right click" },
  R1 = { "R1", "Target enemy" }, R2 = { "R2", "Skill modifier" }, ST = { "Menu (Start)", "Game menu" },
  AB = { "A B X Y", "Skills" }, RST = { "Right stick", "Camera" }, RP = { "Right pad", "Mouse", "Click = left click" },
  L4 = { "L4", "Travel / Aquatic", "Hold = Dash" }, L5 = { "L5", "Bear", "Hold = Enrage" },
  R4 = { "R4", "Cat", "Hold = Prowl" }, R5 = { "R5", "Hold = R5 layer" },
}
-- Other views: only what changes (shown in gold, the rest dimmed)
local VIEWS = {
  { id = "normal", button = "Normal", caption = "Combat set, nothing held", change = {} },
  { id = "r5", button = "Hold R5", caption = "While holding R5", change = {
    AB = { "A B X Y", "A = Rebirth", "B = Remove Curse", "X = Abolish Poison", "Y = Mark of the Wild" },
    DP = { "D-pad", "Up = Hearthstone", "Down = type in chat", "Left = caster weapon", "Right = feral weapon" },
    LP = { "Left pad", "Windows menu", "(see screen)" }, RP = { "Right pad", "Emergencies menu", "(see screen)" },
    R5 = { "R5", "Held" } } },
  { id = "town", button = "Town set", caption = "Town set: only the differences", change = {
    L4 = { "L4", "Travel / Aquatic", "Hold = Ctrl" }, L5 = { "L5", "Bear", "Hold = Shift" },
    SE = { "View (Select)", "Focus menu", "Hold = back to Combat" } } },
}
local LEFT_COL  = { "L2", "L1", "SE", "DP", "LST", "LP" }
local RIGHT_COL = { "R2", "R1", "ST", "AB", "RST", "RP" }
local SCREEN = {   -- what the console screen shows in each view
  normal = { icons = { { "Hold L2 + left pad: party picker", { "yb_me", "yb_p1", "yb_p2", "yb_p3", "yb_p4" }, 5, 44 } },
             text = { "Back buttons: tap = form, hold = extra.", "Hold R5 for emergencies and menus." } },
  r5 = { icons = { { "Left pad menu", { "yb_map", "yb_bags", "yb_char", "yb_spells", "yb_talents", "yb_social",
                     "yb_prof", "yb_mount", "yb_panel", "yb_ybmenu" }, 4, 38 },
                   { "Right pad menu", { "yb_innervate", "yb_barkskin", "yb_natures_grasp", "yb_rejuv_me" }, 2, 38 } } },
  town = { title = "Town set", text = { "Only the L4 and L5 holds change:", "Ctrl and Shift, for Ctrl/Shift + click",
           "(link items, split stacks).", " ", "Everything else = Combat set." } },
}

-- Layout in UI units (page is about 972 x 446)
local PW = 972
local BOXW, FW, BW = 150, 600, 330
local fs, bs = FW / FRONT_W, BW / BACK_W
local FX, FY = (PW - FW) / 2, 40
local BX, BY = (PW - BW) / 2, FY + FRONT_H * fs + 26

local map = {}   -- built widgets

local function fontString(parent, template)
  local s = parent:CreateFontString(nil, "OVERLAY", template)
  s:SetJustifyH("LEFT"); s:SetWordWrap(false)
  return s
end

local function line(parent)
  if not parent.CreateLine then return end
  local l = parent:CreateLine(nil, "ARTWORK")
  if l and l.SetThickness then l:SetThickness(1.5) end
  return l
end

local function makeBox(page, key, side)
  local b = { side = side }
  b.bg = page:CreateTexture(nil, "BACKGROUND")
  b.bar = page:CreateTexture(nil, "BORDER")
  b.title = fontString(page, "GameFontNormalSmall")
  b.lines = {}
  for i = 1, 4 do b.lines[i] = fontString(page, "GameFontHighlightSmall") end
  b.line = line(page)
  b.dot = page:CreateTexture(nil, "OVERLAY")
  b.dot:SetSize(6, 6)
  map.boxes[key] = b
  return b
end

local function colorize(text)
  if text:sub(1, 4) == "Hold" then return HOLD .. text:sub(5) end
  return text
end

-- place one label box at (x, y) and draw its line to the control at (ax, ay); returns height
local function placeBox(page, key, x, y, ax, ay, view)
  local b = map.boxes[key]
  local change = view.change[key]
  local data = change or LABELS[key]
  local changed, dim = change ~= nil, view.id ~= "normal" and change == nil
  local n = #data - 1
  local h = 18 + 13 * n
  b.bg:ClearAllPoints(); b.bg:SetPoint("TOPLEFT", page, "TOPLEFT", x, -y); b.bg:SetSize(BOXW, h)
  b.bg:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], changed and 0.13 or 0)
  local barX = (b.side == "L") and (x + BOXW - 3) or x
  b.bar:ClearAllPoints(); b.bar:SetPoint("TOPLEFT", page, "TOPLEFT", barX, -y); b.bar:SetSize(3, h)
  if changed then b.bar:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1) else b.bar:SetColorTexture(0.35, 0.31, 0.23, 1) end
  local tx = (b.side == "L") and (x + 5) or (x + 9)
  b.title:ClearAllPoints(); b.title:SetPoint("TOPLEFT", page, "TOPLEFT", tx, -(y + 3)); b.title:SetText(data[1])
  b.title:SetAlpha(dim and 0.45 or 1)
  for i = 1, 4 do
    local s = b.lines[i]
    if data[i + 1] then
      s:ClearAllPoints(); s:SetPoint("TOPLEFT", page, "TOPLEFT", tx, -(y + 16 + 13 * (i - 1)))
      s:SetText(colorize(data[i + 1])); s:SetAlpha(dim and 0.45 or 1); s:Show()
    else
      s:Hide()
    end
  end
  local r, g, bl, a = 0.6, 0.5, 0.3, 0.8
  if changed then r, g, bl, a = GOLD[1], GOLD[2], GOLD[3], 1 elseif dim then a = 0.3 end
  local ex = (b.side == "L") and (x + BOXW) or x
  if b.line then
    b.line:SetColorTexture(r, g, bl, a)
    b.line:SetStartPoint("TOPLEFT", page, ex, -(y + 9))
    b.line:SetEndPoint("TOPLEFT", page, ax, -ay)
  end
  b.dot:ClearAllPoints(); b.dot:SetPoint("CENTER", page, "TOPLEFT", ax, -ay)
  b.dot:SetColorTexture(r, g, bl, a)
  return h
end

local function screenWidgets(page)
  -- recycled pool of icon textures and text lines drawn on the console screen
  map.pool = map.pool or { icons = {}, texts = {} }
  for _, t in ipairs(map.pool.icons) do t:Hide() end
  for _, t in ipairs(map.pool.texts) do t:Hide() end
  local ni, nt = 0, 0
  local function icon()
    ni = ni + 1
    local t = map.pool.icons[ni]
    if not t then t = page:CreateTexture(nil, "OVERLAY"); map.pool.icons[ni] = t end
    t:Show(); return t
  end
  local function text(template)
    nt = nt + 1
    local t = map.pool.texts[nt]
    if not t then t = fontString(page, "GameFontHighlightSmall"); map.pool.texts[nt] = t end
    t:SetFontObject(template or "GameFontHighlightSmall"); t:Show(); return t
  end
  return icon, text
end

local function drawScreen(page, viewId)
  local icon, text = screenWidgets(page)
  local sx, sy = FX + 360 * fs, FY + 52 * fs     -- top-left of the console screen
  local cfg = SCREEN[viewId]
  local x = sx + 10
  for _, grp in ipairs(cfg.icons or {}) do
    local title, names, cols, size = grp[1], grp[2], grp[3], grp[4]
    local t = text("GameFontNormalSmall"); t:ClearAllPoints(); t:SetPoint("TOPLEFT", page, "TOPLEFT", x, -(sy + 8)); t:SetText(title)
    for i, n in ipairs(names) do
      local tex = icon()
      tex:SetTexture(MEDIA .. "icons\\" .. n); tex:SetSize(size, size)
      tex:ClearAllPoints()
      tex:SetPoint("TOPLEFT", page, "TOPLEFT", x + ((i - 1) % cols) * (size + 3), -(sy + 22 + math.floor((i - 1) / cols) * (size + 3)))
    end
    x = x + cols * (size + 3) + 22
  end
  local ty = sy + ((cfg.icons and #cfg.icons > 0) and (22 + 48 + 14) or 14)
  if cfg.title then
    local t = text("GameFontNormal"); t:ClearAllPoints(); t:SetPoint("TOPLEFT", page, "TOPLEFT", sx + 14, -ty); t:SetText(cfg.title)
    ty = ty + 20
  end
  for _, l in ipairs(cfg.text or {}) do
    local t = text("GameFontHighlightSmall"); t:ClearAllPoints(); t:SetPoint("TOPLEFT", page, "TOPLEFT", sx + 14, -ty); t:SetText(l)
    ty = ty + 15
  end
end

function YB:DeckMapBuild(page)
  if map.built then return end
  map.built, map.boxes, map.buttons = true, {}, {}
  map.page = page
  for i, v in ipairs(VIEWS) do
    local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    b:SetSize(100, 24); b:SetText(v.button)
    b:SetPoint("TOPLEFT", (i - 1) * 106, 0)
    b:SetScript("OnClick", function() YB:DeckMapShow(v.id) end)
    map.buttons[v.id] = b
  end
  map.caption = fontString(page, "GameFontDisableSmall")
  map.caption:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -6); map.caption:SetJustifyH("RIGHT")
  local front = page:CreateTexture(nil, "ARTWORK")
  front:SetTexture(MEDIA .. "deck_front"); front:SetTexCoord(0, 1, 0, 399 / 512)
  front:SetSize(FW, FRONT_H * fs); front:SetPoint("TOPLEFT", page, "TOPLEFT", FX, -FY)
  local back = page:CreateTexture(nil, "ARTWORK")
  back:SetTexture(MEDIA .. "deck_back"); back:SetTexCoord(0, 1, 0, 196 / 256)
  back:SetSize(BW, BACK_H * bs); back:SetPoint("TOPLEFT", page, "TOPLEFT", BX, -BY)
  local bt = fontString(page, "GameFontDisableSmall"); bt:SetPoint("BOTTOM", back, "TOP", 0, 3)
  bt:SetText("back (seen through the front)")
  for _, k in ipairs(LEFT_COL) do makeBox(page, k, "L") end
  for _, k in ipairs(RIGHT_COL) do makeBox(page, k, "R") end
  makeBox(page, "L4", "L"); makeBox(page, "L5", "L"); makeBox(page, "R4", "R"); makeBox(page, "R5", "R")
end

function YB:DeckMapShow(viewId)
  local page = map.page
  if not page then return end
  map.current = viewId or map.current or "normal"
  local view
  for _, v in ipairs(VIEWS) do if v.id == map.current then view = v end end
  for id, b in pairs(map.buttons) do if id == map.current then b:LockHighlight() else b:UnlockHighlight() end end
  map.caption:SetText(view.caption)
  local function fa(k) return FX + FRONT[k][1] * fs, FY + FRONT[k][2] * fs end
  local function ba(k) return BX + BACK[k][1] * bs, BY + BACK[k][2] * bs end
  for _, col in ipairs({ { LEFT_COL, 0 }, { RIGHT_COL, PW - BOXW } }) do
    local y = 34
    for _, k in ipairs(col[1]) do
      local ax, ay = fa(k)
      y = y + placeBox(page, k, col[2], y, ax, ay, view) + 6
    end
  end
  for _, col in ipairs({ { { "L4", "L5" }, BX - BOXW - 12 }, { { "R4", "R5" }, BX + BW + 12 } }) do
    local y = BY + 8
    for _, k in ipairs(col[1]) do
      local ax, ay = ba(k)
      y = y + placeBox(page, k, col[2], y, ax, ay, view) + 8
    end
  end
  drawScreen(page, map.current)
end

YB.DeckMapSize = { 1000, 560 }   -- window size while this tab is open
