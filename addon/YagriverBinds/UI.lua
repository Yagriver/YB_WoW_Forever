-- Yagriver Binds 6 - ventana: Inicio, Armas, Dispositivo, Easy Controller y Comprobar.
-- Se abre con la huella del minimapa, /yag o la rueda Utilidad de Easy Controller.
local ADDON, YB = ...

local W, H = 640, 580
local GOLD = { 1, 0.82, 0 }
local MEDIA = "Interface\\AddOns\\YagriverBinds\\Media\\"

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

---------------------------------------------------------------- piezas
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

---------------------------------------------------------------- cabecera, pestañas, pie
local logo = f:CreateTexture(nil, "ARTWORK")
logo:SetTexture("Interface\\Icons\\Ability_Druid_Maul"); logo:SetSize(16, 16)
logo:SetPoint("TOPLEFT", 8, -4)
local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", 0, -5)
title:SetText("|cffffd100Yagriver|r Binds  |cff888888v" .. YB.VERSION .. "|r")

local pages, tabs = {}, {}
local function page()
  local p = CreateFrame("Frame", nil, f)
  p:SetPoint("TOPLEFT", 14, -66); p:SetPoint("BOTTOMRIGHT", -14, 48)
  p:Hide()
  return p
end
local tabDefs = { { "home", "Inicio" }, { "weapons", "Armas" }, { "device", "Dispositivo" }, { "ec", "Easy Controller" }, { "checks", "Comprobar" } }
for i, d in ipairs(tabDefs) do
  pages[d[1]] = page()
  local b = button(f, d[2], i == 4 and 130 or 102, 24)
  b:SetPoint("TOPLEFT", 14 + (i - 1) * 106 + (i > 4 and 28 or 0), -30)
  tabs[d[1]] = b
end
local tabLine = rect(f, GOLD[1], GOLD[2], GOLD[3], 0.35, "ARTWORK")
tabLine:SetPoint("TOPLEFT", 12, -58); tabLine:SetPoint("TOPRIGHT", -12, -58); tabLine:SetHeight(1)

local footer = rect(f, 0, 0, 0, 0.45, "BORDER")
footer:SetPoint("BOTTOMLEFT", 8, 8); footer:SetPoint("BOTTOMRIGHT", -8, 8); footer:SetHeight(34)
local status = label(f, "", "GameFontHighlight")
status:SetPoint("BOTTOMLEFT", 16, 14); status:SetPoint("BOTTOMRIGHT", -16, 14); status:SetHeight(24)
status:SetJustifyV("MIDDLE")
local function say(msg, isError)
  if not msg or msg == "" then status:SetText("|cff888888Listo.|r"); return end
  status:SetText((isError and "|cffff5050" or "|cff40ff40") .. msg .. "|r")
  print("|cff88ccffYagriver Binds:|r " .. msg)
  if UIErrorsFrame then UIErrorsFrame:AddMessage(msg, isError and 1 or 0.3, isError and 0.3 or 1, 0.3) end
end
YB.Say = say
local function run(fn, after)
  local ok, res, msg = pcall(fn)
  if not ok then say("Error: " .. tostring(res), true)
  else say(msg or (res and "Hecho." or "Nada cambió."), not res) end
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
local function para(add, p, text, y, font)
  local l = add(label(p, text, font or "GameFontHighlightSmall"))
  l:SetPoint("TOPLEFT", 4, y); l:SetWidth(W - 44)
  return y - (l.GetStringHeight and math.max(14, (l:GetStringHeight() or 14)) or 14) - 6
end

local show   -- forward

---------------------------------------------------------------- INICIO
local function buildHome()
  local p = pages.home
  local add = holder(p)
  local g = YB:Global()
  local y = 0
  y = section(add, p, "¿En qué máquina estás?", y)
  local defs = { { "pc", "PC", "Escritorio 21:9 y Moonlight a la Switch" },
                 { "deck", "Steam Deck", "Deck y Dock (llega en la 6.1)" } }
  for i, d in ipairs(defs) do
    local b = add(button(p, d[2], 290, 44))
    b:SetPoint("TOPLEFT", (i - 1) * 310, y)
    if g.device == d[1] then b:LockHighlight() else b:UnlockHighlight() end
    local ic = add(b:CreateTexture(nil, "OVERLAY"))
    if d[1] == "pc" then ic:SetTexture(MEDIA .. "monitor"); ic:SetTexCoord(0, 1, 0, 1); ic:SetSize(30, 30)
    else ic:SetTexture(MEDIA .. "deck_front"); ic:SetTexCoord(0, 1, 0, 399 / 512); ic:SetSize(62, 24) end
    ic:SetPoint("LEFT", b, "LEFT", 12, 0)
    tip(b, d[3] .. ".\nSe guarda solo en esta máquina.")
    b:SetScript("OnClick", function() run(function() return YB:SetDevice(d[1]) end, function() show("home") end) end)
    local sub = add(label(p, "|cff888888" .. d[3] .. "|r" .. (g.device == d[1] and "  |cff40ff40(esta máquina)|r" or ""),
      "GameFontHighlightSmall", true))
    sub:SetPoint("TOPLEFT", (i - 1) * 310 + 4, y - 48)
  end
  y = y - 76
  if not g.device then
    y = para(add, p, "Elige una para empezar. Puedes cambiarla luego aquí mismo.", y, "GameFontHighlight")
    return
  end
  y = section(add, p, "Ahora", y)
  local m = YB:ModeKey()
  local w, h = YB:ScreenSize()
  y = para(add, p, ("Modo |cffffffff%s|r, pantalla %s, escala %.2f."):format(YB.MODE_NAMES[m] or m,
    w and (w .. " x " .. h) or "?", YB:Scale()), y, "GameFontHighlight")
  local ecText
  if not YB.IsLoaded("EasyController") then ecText = "|cffff9040Easy Controller no está activado.|r Instálalo y vuelve a la pestaña Easy Controller."
  elseif YB.EC:Applied() then ecText = "|cff40ff40Easy Controller preparado por YB.|r"
  else ecText = "|cffffff00Easy Controller sin preparar:|r pestaña Easy Controller." end
  y = para(add, p, ecText, y, "GameFontHighlight")
  local cs = YB:Conflicts()
  if #cs > 0 then y = para(add, p, "|cffff5050" .. table.concat(cs, "\n") .. "|r", y) end
end

---------------------------------------------------------------- captura de teclas
local capture = CreateFrame("Frame", "YagriverBindsKeyCapture", UIParent)
capture:SetAllPoints(); capture:SetFrameStrata("FULLSCREEN_DIALOG"); capture:EnableKeyboard(false); capture:Hide()
local capBg = rect(capture, 0, 0, 0, 0.6); capBg:SetAllPoints()
local capText = label(capture, "", "GameFontNormalLarge"); capText:SetPoint("CENTER")
local MODIFIERS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true }
local capturing, afterCapture
local function stopCapture() capture:EnableKeyboard(false); capture:Hide(); capturing = nil end
capture:SetScript("OnKeyDown", function(self, k)
  if MODIFIERS[k] then return end
  local id = capturing
  stopCapture()
  if k == "ESCAPE" then say("Tecla sin cambios.") return end
  local combo = (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") .. k
  run(function() return YB:SetKey(id, combo) end, afterCapture)
end)
local function startCapture(id, text, after)
  if YB.InCombat() then say("Sal del combate primero.", true) return end
  capturing, afterCapture = id, after
  capText:SetText("Pulsa la tecla para: " .. text .. "\n|cff888888(con Mayús / Ctrl / Alt si quieres; Esc cancela)|r")
  capture:Show(); capture:EnableKeyboard(true)
  if capture.SetPropagateKeyboardInput then pcall(capture.SetPropagateKeyboardInput, capture, false) end
end

---------------------------------------------------------------- ARMAS
local buildWeapons
buildWeapons = function()
  local p = pages.weapons
  local add = holder(p)
  local db, g = YB:DB(), YB:Global()
  local y = 0
  local _, class = UnitClass("player")
  if class ~= "DRUID" then para(add, p, "Las armas por forma son para druidas.", y, "GameFontHighlight") return end
  y = section(add, p, "Conjuntos de armas", y)
  for _, which in ipairs({ "feral", "caster" }) do
    local l = add(label(p, (which == "feral" and "|cffffffffFeral:|r  " or "|cffffffffLanzador:|r ") .. YB:WeaponText(which),
      "GameFontHighlightSmall", true))
    l:SetPoint("TOPLEFT", 4, y - 6); l:SetWidth(380)
    local b = add(button(p, "Usar equipado", 120, 24)); b:SetPoint("TOPLEFT", 400, y)
    tip(b, "Ponte ese conjunto y pulsa. Actualiza la macro " .. (which == "feral" and "YB Feral Set" or "YB Caster Set") ..
      ", que también usa la Deck.")
    b:SetScript("OnClick", function() run(function() return YB:CaptureWeapons(which) end, buildWeapons) end)
    local cl = add(button(p, "Borrar", 70, 24)); cl:SetPoint("LEFT", b, "RIGHT", 4, 0)
    cl:SetScript("OnClick", function() run(function() return YB:ClearWeapons(which) end, buildWeapons) end)
    y = y - 26
  end
  local wh = add(check(p, "Aviso pequeño cuando el arma no va con la forma", function(v)
    db.weaponHint = v; if YB.UpdateWeaponHint then YB.UpdateWeaponHint() end
  end))
  add(wh.text); wh:SetPoint("TOPLEFT", 0, y); wh:SetChecked(db.weaponHint); y = y - 34

  if YB:Device() == "pc" then
    y = section(add, p, "Teclas en el teclado del PC", y)
    y = para(add, p, "|cff888888Solo mientras YB funciona: WoW no las guarda, así que nunca llegan a la Deck.|r", y)
    for _, a in ipairs(YB.KEY_ACTIONS) do
      local key = g.keys[a.id]
      local under = key and YB:KeyUnder(key)
      local l = add(label(p, "|cffffffff" .. a.label .. ":|r  " .. (key and YB:KeyText(key) or "|cff888888ninguna|r") ..
        (under and ("  |cffff9040(sustituye a " .. under .. ")|r") or ""), "GameFontHighlightSmall", true))
      l:SetPoint("TOPLEFT", 4, y - 6); l:SetWidth(380)
      local sb = add(button(p, "Elegir tecla", 110, 24)); sb:SetPoint("TOPLEFT", 400, y)
      sb:SetScript("OnClick", function() startCapture(a.id, a.label, buildWeapons) end)
      local cb = add(button(p, "Quitar", 70, 24)); cb:SetPoint("LEFT", sb, "RIGHT", 4, 0)
      cb:SetScript("OnClick", function() run(function() return YB:SetKey(a.id, nil) end, buildWeapons) end)
      y = y - 26
    end
    y = y - 6
  end
  y = section(add, p, "Con el mando", y)
  para(add, p, "|cff888888Los dos conjuntos están en la rueda Formas de Easy Controller (ZL + ZR + izquierda).|r", y)
end

---------------------------------------------------------------- DISPOSITIVO
local buildDevice
buildDevice = function()
  local p = pages.device
  local add = holder(p)
  local g = YB:Global()
  local y = 0
  if g.device ~= "pc" then
    para(add, p, g.device == "deck" and "Los modos de la Deck llegan en YB 6.1. En la Deck sigue usando la 5.x por ahora."
      or "Elige primero la máquina en Inicio.", y, "GameFontHighlight")
    return
  end
  local m, mode = YB:ModeKey(), YB:Mode()
  y = section(add, p, "Modo", y)
  local defs = { { "pc", "PC (escritorio)", "Teclado y ratón, monitor 21:9", "monitor", 30, 30 },
                 { "moonlight", "Moonlight (Switch)", "Interfaz de mando, 16:9", "switch", 48, 24 } }
  for i, d in ipairs(defs) do
    local b = add(button(p, d[2], 290, 40))
    b:SetPoint("TOPLEFT", (i - 1) * 310, y)
    if m == d[1] then b:LockHighlight() else b:UnlockHighlight() end
    local ic = add(b:CreateTexture(nil, "OVERLAY"))
    ic:SetTexture(MEDIA .. d[4]); ic:SetTexCoord(0, 1, 0, 1); ic:SetSize(d[5], d[6]); ic:SetPoint("LEFT", b, "LEFT", 12, 0)
    tip(b, d[3] .. ".\nCambiar el estilo de interfaz recarga la interfaz.")
    b:SetScript("OnClick", function() run(function() return YB:ApplyMode(d[1]) end, buildDevice) end)
    local sub = add(label(p, "|cff888888" .. d[3] .. "|r" .. (m == d[1] and "  |cff40ff40(activo)|r" or ""), "GameFontHighlightSmall", true))
    sub:SetPoint("TOPLEFT", (i - 1) * 310 + 4, y - 44)
  end
  y = y - 66
  local w, h = YB:ScreenSize()
  local au = add(check(p, "Auto: el modo según la pantalla (21:9 = PC, 16:9 = Moonlight)", function(v)
    g.auto = v; say(v and "Auto activado." or "Auto desactivado: el modo se queda como lo pongas.")
  end))
  add(au.text); au:SetPoint("TOPLEFT", 0, y); au:SetChecked(g.auto)
  local sc = add(label(p, "|cff888888pantalla " .. (w and (w .. " x " .. h) or "?") .. "|r", "GameFontHighlightSmall"))
  sc:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, y - 6)
  y = y - 32

  y = section(add, p, "Escala de la interfaz  |cff888888(" .. YB.MODE_NAMES[m] .. ")|r", y)
  local minus = add(button(p, "-", 44, 30)); minus:SetPoint("TOPLEFT", 0, y)
  local val = add(label(p, ("%.2f"):format(YB:Scale()), "GameFontNormalLarge")); val:SetPoint("LEFT", minus, "RIGHT", 16, 0)
  local plus = add(button(p, "+", 44, 30)); plus:SetPoint("LEFT", minus, "RIGHT", 72, 0)
  local reset = add(button(p, "1.00", 60, 30)); reset:SetPoint("LEFT", plus, "RIGHT", 12, 0)
  minus:SetScript("OnClick", function() run(function() return YB:SetScale(YB:Scale() - 0.05) end, buildDevice) end)
  plus:SetScript("OnClick", function() run(function() return YB:SetScale(YB:Scale() + 0.05) end, buildDevice) end)
  reset:SetScript("OnClick", function() run(function() return YB:SetScale(1) end, buildDevice) end)
  y = y - 40

  y = section(add, p, "Diseño de Edit Mode  |cff888888(" .. YB.MODE_NAMES[m] .. ")|r", y)
  local lb = add(button(p, "Diseño: " .. (mode.layout or "no cambiar"), 290, 26)); lb:SetPoint("TOPLEFT", 0, y)
  tip(lb, "Pulsa para pasar por tus diseños de Edit Mode. YB lo activa cada vez que empieza este modo.\n" ..
    "Los diseños se comparten con la Deck: dale uno propio a cada pantalla.")
  lb:SetScript("OnClick", function() run(function() return YB:CycleLayout() end, buildDevice) end)
  y = y - 34

  y = section(add, p, "Aviso de arma  |cff888888(" .. YB.MODE_NAMES[m] .. ")|r", y)
  local hm = add(button(p, "-", 44, 30)); hm:SetPoint("TOPLEFT", 0, y)
  local hv = add(label(p, ("%.1f"):format(mode.hint.scale), "GameFontNormalLarge")); hv:SetPoint("LEFT", hm, "RIGHT", 18, 0)
  local hp = add(button(p, "+", 44, 30)); hp:SetPoint("LEFT", hm, "RIGHT", 72, 0)
  hm:SetScript("OnClick", function() run(function() return YB:HintScale(-0.1) end, buildDevice) end)
  hp:SetScript("OnClick", function() run(function() return YB:HintScale(0.1) end, buildDevice) end)
  local mv = add(button(p, YB:HintMoving() and "Hecho" or "Mover", 90, 30)); mv:SetPoint("LEFT", hp, "RIGHT", 16, 0)
  if YB:HintMoving() then mv:LockHighlight() else mv:UnlockHighlight() end
  mv:SetScript("OnClick", function() run(function() return YB:HintMove(not YB:HintMoving()) end, buildDevice) end)
  local rr = add(button(p, "Por defecto", 100, 30)); rr:SetPoint("LEFT", mv, "RIGHT", 8, 0)
  rr:SetScript("OnClick", function() run(function() return YB:HintReset() end, buildDevice) end)
  y = y - 40

  if YB.MODE_STYLE[m] == "1" then
    y = section(add, p, "Mando", y)
    local rs = add(check(p, "El stick derecho mueve siempre la cámara (el cursor de WoW no lo coge en los menús)", function(v)
      run(function() return YB:SetStickCamera(v) end, buildDevice)
    end))
    add(rs.text); rs:SetPoint("TOPLEFT", 0, y); rs:SetChecked(mode.stickCamera)
  end
end

---------------------------------------------------------------- EASY CONTROLLER
local confirmUntil, buildEC = 0, nil
buildEC = function()
  local p = pages.ec
  local add = holder(p)
  local y = 0
  local ec = YB.EC
  y = section(add, p, "Estado", y)
  local v = ec:Version()
  local ready, why = ec:Ready()
  y = para(add, p, (YB.IsLoaded("EasyController") and ("Easy Controller " .. tostring(v) .. ". ") or "") ..
    (ready and "|cff40ff40Listo para preparar.|r" or ("|cffffff00" .. tostring(why) .. "|r")) ..
    (ec:Applied() and "  |cff40ff40Ya preparado por YB.|r" or ""), y, "GameFontHighlight")

  y = section(add, p, "Lo que YB pondrá en tu perfil actual", y)
  for _, line in ipairs(ec:Preview()) do y = para(add, p, line, y) end
  y = y - 4
  local armed = GetTime() < confirmUntil
  local go = add(button(p, armed and "CONFIRMAR: preparar" or (ec:Applied() and "Preparar de nuevo" or "Preparar Easy Controller"), 230, 30))
  go:SetPoint("BOTTOMLEFT", 0, 2)
  tip(go, "Dos clics. Solo toca los botones de la lista y apunta lo que había, para Deshacer.\nFuera de combate y con la interfaz de mando.")
  if not ready then go:Disable() else go:Enable() end
  go:SetScript("OnClick", function()
    if GetTime() < confirmUntil then
      confirmUntil = 0
      run(function() return ec:Apply() end, buildEC)
    else
      confirmUntil = GetTime() + 15
      say("Pulsa CONFIRMAR antes de 15 s para preparar Easy Controller.", true)
      buildEC()
    end
  end)
  local un = add(button(p, "Deshacer", 120, 30)); un:SetPoint("LEFT", go, "RIGHT", 10, 0)
  if ec:Applied() then un:Enable() else un:Disable() end
  un:SetScript("OnClick", function() run(function() return ec:Undo() end, buildEC) end)
  local rl = add(button(p, "Recargar interfaz", 150, 30)); rl:SetPoint("BOTTOMRIGHT", 0, 2)
  tip(rl, "Después de preparar, recarga para que Easy Controller muestre todo.")
  rl:SetScript("OnClick", function() if not YB.InCombat() then ReloadUI() end end)
end

---------------------------------------------------------------- COMPROBAR
local function buildChecks()
  local p = pages.checks
  local add = holder(p)
  local y = 0
  y = section(add, p, "Addons que chocan", y)
  local cs = YB:Conflicts()
  y = para(add, p, #cs > 0 and ("|cffff5050" .. table.concat(cs, "\n") .. "|r") or "|cff40ff40Ninguno.|r", y)
  y = section(add, p, "Teclas de la Deck en esta máquina", y)
  local left = YB:DeckLeftovers()
  y = para(add, p, ("|cffffffff%d de %d|r teclas de la Deck han llegado por el servidor de Blizzard. Déjalas de momento: " ..
    "la Deck aún las usa. YB 6.1 en la Deck las quita de las dos máquinas."):format(#left, #YB.deckKeys), y)
  local col = 0
  for _, e in ipairs(left) do
    local l = add(label(p, "|cffaad4ff" .. e.key .. "|r  " .. e.action, "GameFontHighlightSmall", true))
    l:SetWidth(290); l:SetPoint("TOPLEFT", 4 + col * 305, y)
    if col == 1 then y = y - 14 end
    col = 1 - col
  end
end

---------------------------------------------------------------- cambiar de pestaña
local builders = { home = buildHome, weapons = function() buildWeapons() end, device = function() buildDevice() end,
  ec = function() buildEC() end, checks = buildChecks }
local current = "home"
show = function(which)
  current = which
  for k, pg in pairs(pages) do if k == which then pg:Show() else pg:Hide() end end
  for k, b in pairs(tabs) do if k == which then b:LockHighlight() else b:UnlockHighlight() end end
  local ok, err = pcall(builders[which]); if not ok then say("Error: " .. tostring(err), true) end
end
for k, b in pairs(tabs) do b:SetScript("OnClick", function() show(k) end) end

function YB:Toggle(open)
  if f:IsShown() and not open then f:Hide() return end
  say(""); confirmUntil = 0; f:Show()
  show(YB:Device() and current or "home")
end

SLASH_YAGRIVERBINDS1 = "/yag"
SLASH_YAGRIVERBINDS2 = "/yb"
SlashCmdList["YAGRIVERBINDS"] = function() YB:Toggle() end

-- botón del minimapa
local mm = CreateFrame("Button", "YagriverBindsMinimapButton", Minimap)
mm:SetSize(31, 31); mm:SetFrameStrata("MEDIUM"); mm:SetFrameLevel(8)
mm:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -2, -40)
mm:RegisterForClicks("LeftButtonUp")
local icon = mm:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\Ability_Druid_Maul"); icon:SetSize(20, 20); icon:SetPoint("CENTER", 0, 1)
local border = mm:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetSize(53, 53); border:SetPoint("TOPLEFT")
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
mm:SetScript("OnClick", function() YB:Toggle() end)
mm:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine("Yagriver Binds")
  GameTooltip:AddLine("Clic: ajustes", 1, 1, 1); GameTooltip:Show()
end)
mm:SetScript("OnLeave", function() GameTooltip:Hide() end)
