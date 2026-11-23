-- Yagriver Binds 6 - pestaña "Mapa de la Deck": qué hace cada control de la Steam Deck, en cuatro vistas.
-- Fotos en Media\ (frente y espalda de la Deck, iconos de los menús). Los textos están en LABELS / VIEWS.
local ADDON, YB = ...

local MEDIA = "Interface\\AddOns\\YagriverBinds\\Media\\"
local GOLD = { 1, 0.82, 0 }
local HOLD = "|cff9fd0ffMantener|r"     -- el texto de WoW no tiene cursiva: "Mantener" va en otro color

-- Posiciones de los controles medidas en las fotos (frente 1729x674, espalda en espejo 1720x657)
local FRONT = { L1 = { 218, 12 }, L2 = { 120, 8 }, R1 = { 1508, 12 }, R2 = { 1610, 8 },
  SE = { 250, 72 }, ST = { 1478, 72 }, DP = { 118, 152 }, LST = { 278, 182 }, AB = { 1618, 146 },
  RST = { 1453, 182 }, LP = { 238, 372 }, RP = { 1493, 372 } }
local BACK = { L4 = { 248, 275 }, L5 = { 260, 433 }, R4 = { 1473, 274 }, R5 = { 1460, 432 } }
local FRONT_W, FRONT_H, BACK_W, BACK_H = 1729, 674, 1720, 657

-- Vista normal (juego Combate, nada mantenido). Las líneas que empiezan por "Mantener" van en su color.
local LABELS = {
  L1 = { "L1", "Apuntar a aliado" }, L2 = { "L2", "Modificador", "Mantener + pad izq.: grupo" },
  SE = { "Vista (Select)", "Menú de foco", "Mantener = juego Ciudad" }, DP = { "Cruceta", "Habilidades" },
  LST = { "Stick izquierdo", "Moverse", "Clic = autocorrer" }, LP = { "Pad izquierdo", "Desplazar", "Clic = clic derecho" },
  R1 = { "R1", "Apuntar a enemigo" }, R2 = { "R2", "Modificador" }, ST = { "Menú (Start)", "Menú del juego" },
  AB = { "A B X Y", "Habilidades" }, RST = { "Stick derecho", "Cámara", "Clic = ping" },
  RP = { "Pad derecho", "Ratón", "Clic = clic izquierdo" },
  L4 = { "L4", "Viaje / Acuática", "Mantener = Carrera" }, L5 = { "L5", "Oso", "Mantener = Enfurecer" },
  R4 = { "R4", "Gato", "Mantener = Acecho" }, R5 = { "R5", "Mantener = capa R5" },
}
-- Con Easy Controller preparado, R3 es el modo sanador
local RST_EC = { "Stick derecho", "Cámara", "Clic = modo sanador" }
-- Otras vistas: solo lo que cambia (en dorado, el resto atenuado)
local VIEWS = {
  { id = "normal", button = "Normal", caption = "Juego Combate, sin mantener nada", change = {} },
  { id = "r5", button = "Mantener R5", caption = "Mientras mantienes R5", change = {
    AB = { "A B X Y", "A = Renacer", "B = Deshacer maldición", "X = Suprimir veneno", "Y = Marca de lo salvaje" },
    DP = { "Cruceta", "Arriba = Piedra de hogar", "Abajo = escribir en el chat", "Izq. = arma de lanzador", "Der. = arma feral" },
    LP = { "Pad izquierdo", "Menú de ventanas", "(ver pantalla)" }, RP = { "Pad derecho", "Menú de emergencias", "(ver pantalla)" },
    R5 = { "R5", "Mantenido" } } },
  { id = "ec", button = "L2 + R2", caption = "Easy Controller: mantén L2 + R2 y pulsa", change = {
    AB = { "A B X Y", "A = Emergencias", "B = Habilidades", "X = Formas", "Y = Utilidad" },
    RST = { "Stick derecho", "Apunta en la rueda", "Clic (R3) = modo sanador" },
    L2 = { "L2", "Mantenido" }, R2 = { "R2", "Mantenido" } } },
  { id = "town", button = "Juego Ciudad", caption = "Juego Ciudad: solo lo que cambia", change = {
    L4 = { "L4", "Viaje / Acuática", "Mantener = Ctrl" }, L5 = { "L5", "Oso", "Mantener = Mayús" },
    SE = { "Vista (Select)", "Menú de foco", "Mantener = vuelve a Combate" } } },
}
local LEFT_COL  = { "L2", "L1", "SE", "DP", "LST", "LP" }
local RIGHT_COL = { "R2", "R1", "ST", "AB", "RST", "RP" }
local SCREEN = {   -- lo que sale en la pantalla de la Deck en cada vista
  normal = { icons = { { "L2 + pad izq.: elegir del grupo", { "yb_me", "yb_p1", "yb_p2", "yb_p3", "yb_p4" }, 5, 44 } },
             text = { "Botones traseros: toque = forma, mantener = extra.", "Mantén R5 para emergencias y menús.",
                      "L2 + R2 + botón: ruedas de Easy Controller." } },
  r5 = { icons = { { "Menú del pad izquierdo", { "yb_map", "yb_bags", "yb_char", "yb_spells", "yb_talents", "yb_social",
                     "yb_prof", "yb_mount", "yb_panel", "yb_ybmenu" }, 4, 38 },
                   { "Menú del pad derecho", { "yb_innervate", "yb_barkskin", "yb_natures_grasp", "yb_rejuv_me" }, 2, 38 } },
         text = { "\"Chat + Prof.\" abre ahora las frases de Easy Controller." } },
  ec = { title = "Ruedas de Easy Controller", text = { "Mantén L2 + R2 y pulsa A, X, Y o B.",
         "Mini ruedas: apunta con el stick derecho y suelta.", "Utilidad (Y) es grande: elige con el stick.",
         "R3 (también con L2, R2 o los dos): modo sanador." } },
  town = { title = "Juego Ciudad", text = { "Solo cambian L4 y L5 mantenidos:", "Ctrl y Mayús, para Ctrl/Mayús + clic",
           "(enlazar objetos, partir montones).", " ", "Todo lo demás = juego Combate." } },
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
  if text:sub(1, 8) == "Mantener" then return HOLD .. text:sub(9) end
  return text
end

-- place one label box at (x, y) and draw its line to the control at (ax, ay); returns height
local function placeBox(page, key, x, y, ax, ay, view)
  local b = map.boxes[key]
  local change = view.change[key]
  local data = change or ((key == "RST" and YB.EC and YB.EC:Applied()) and RST_EC or LABELS[key])
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
  cfg.id = viewId
  local x = sx + 10
  local iconsH = 0
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
    iconsH = math.max(iconsH, 22 + math.ceil(#names / cols) * (size + 3))
  end
  local ty = sy + ((iconsH > 0) and (iconsH + 12) or 14)
  if cfg.title then
    local t = text("GameFontNormal"); t:ClearAllPoints(); t:SetPoint("TOPLEFT", page, "TOPLEFT", sx + 14, -ty); t:SetText(cfg.title)
    ty = ty + 20
  end
  if cfg.id == "ec" and not (YB.EC and YB.EC:Applied()) then
    cfg = { title = cfg.title, text = { cfg.text[1], cfg.text[2], cfg.text[3], cfg.text[4], " ",
      "|cffffff00Aún sin preparar: pestaña Easy Controller.|r" } }
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
    b:SetSize(110, 24); b:SetText(v.button)
    b:SetPoint("TOPLEFT", (i - 1) * 116, 0)
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
  bt:SetText("espalda (vista a través del frente)")
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
