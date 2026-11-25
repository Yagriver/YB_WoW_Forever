-- Yagriver Binds 6 - núcleo: dispositivo, modos, escala, diseño, armas y teclas.
-- Reglas:
--   * Cada máquina guarda sus ajustes en sus propios archivos (YagriverBindsDB / YagriverBindsCharDB).
--   * Las teclas de YB son "override bindings": existen solo mientras el addon corre y Blizzard
--     no las copia a la otra máquina. Las macros YB sí se comparten, a propósito.
--   * Nada se cambia en combate.
local ADDON, YB = ...
YB.VERSION = "6.1.1"

---------------------------------------------------------------- compatibilidad de API
function YB.SpellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  if C_Spell and C_Spell.GetSpellInfo then local i = C_Spell.GetSpellInfo(id); return i and i.name end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end
function YB.ItemName(id)
  if not id then return end
  if C_Item and C_Item.GetItemNameByID then local n = C_Item.GetItemNameByID(id); if n then return n end end
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
-- El rango más alto que conoces de un hechizo: el juego lo da al buscarlo por su nombre
function YB.BestRank(id)
  local name = YB.SpellName(id)
  if name and C_Spell and C_Spell.GetSpellInfo then
    local ok, info = pcall(C_Spell.GetSpellInfo, name)
    if ok and type(info) == "table" and info.spellID and YB.IsKnown(info.spellID) then return info.spellID end
  end
  return id
end
-- De una lista (mejor versión primero): id, nombre, ¿conocido?
function YB:Spell(key)
  local ids = YB.SPELL[key] or {}
  for _, id in ipairs(ids) do
    if YB.IsKnown(id) then local best = YB.BestRank(id); return best, YB.SpellName(best), true end
  end
  return ids[1], ids[1] and YB.SpellName(ids[1]), false
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
function YB.IsLoaded(name)
  local fn = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  if not fn then return false end
  local ok, v = pcall(fn, name)
  return ok and v and true or false
end
function YB.Tell(msg) print("|cff88ccffYagriver Binds:|r " .. msg) end
local tell = YB.Tell

---------------------------------------------------------------- ajustes guardados
-- La 5.x (solo existía en la Deck) guardaba "handheld" y "docked": se copian a "deck" y "dock".
-- Los originales se quedan, por si hay que volver a la 5.5.
local function migrate55(g)
  if g.migrated55 or not (g.modes and (g.modes.handheld or g.modes.docked)) then return end
  for old, new in pairs({ handheld = "deck", docked = "dock" }) do
    local o = g.modes[old]
    if o and not g.modes[new] then
      local h = o.hint or {}
      g.modes[new] = { scale = o.scale, hint = { scale = h.scale, x = h.x, y = h.y },
        style = (o.pad == nil) and nil or (o.pad and "1" or "0") }
    end
  end
  if g.mode == "handheld" then g.mode = "deck" elseif g.mode == "docked" then g.mode = "dock" end
  if not g.device then g.device = "deck"; g.auto = false end   -- la 5.x elegía el modo a mano
  g.migrated55 = true
  YB.migrated = true
end

function YB:Global()
  YagriverBindsDB = YagriverBindsDB or {}
  local g = YagriverBindsDB
  migrate55(g)
  if g.auto == nil then g.auto = true end
  g.keys = g.keys or {}
  g.modes = g.modes or {}
  for m, d in pairs(YB.HINT_DEFAULTS) do
    local mode = g.modes[m] or {}
    local h = mode.hint or {}
    mode.hint = { scale = h.scale or d.scale, x = h.x or d.x, y = h.y or d.y }
    if mode.stickCamera == nil then mode.stickCamera = false end
    g.modes[m] = mode
  end
  return g
end
function YB:DB()
  YagriverBindsCharDB = YagriverBindsCharDB or {}
  local db = YagriverBindsCharDB
  db.weapons = db.weapons or {}
  db.weapons.feral = db.weapons.feral or {}
  db.weapons.caster = db.weapons.caster or {}
  if db.weaponHint == nil then db.weaponHint = true end
  return db
end
function YB:Device() return self:Global().device end
function YB:SetDevice(d)
  if YB.InCombat() then return false, "Sal del combate primero." end
  if not YB.DEVICES[d] then return false, "Dispositivo desconocido." end
  local g = self:Global()
  g.device = d
  g.mode = nil
  self:ApplyKeys()
  local cleaned = self:CleanSavedDeckKeys()
  local ok, msg = self:ApplyMode(self:DetectMode())
  local extra = cleaned > 0 and (" Quitadas %d teclas guardadas de la 5.x (ahora las pone YB sin guardarlas)."):format(cleaned) or ""
  return true, YB.DEVICES[d].name .. " elegido. " .. (msg or "") .. extra
end
function YB:ModeKey()
  local g = self:Global()
  local d = YB.DEVICES[g.device or "pc"]
  for _, m in ipairs(d.modes) do if g.mode == m then return m end end
  return self:DetectMode()
end
function YB:Mode() return self:Global().modes[self:ModeKey()] end
-- Estilo de interfaz de un modo: "1" mando, "0" teclado y ratón. En la Deck se puede cambiar por modo.
function YB:StyleFor(m)
  local mode = self:Global().modes[m]
  return (mode and mode.style) or YB.MODE_STYLE[m]
end
function YB:SetModeStyle(pad)
  if YB.InCombat() then return false, "Sal del combate primero." end
  if self:Device() ~= "deck" then return false, "En el PC el estilo va fijo con cada modo." end
  local m = self:ModeKey()
  self:Mode().style = pad and "1" or "0"
  return self:ApplyMode(m)
end

---------------------------------------------------------------- qué modo pide la pantalla
-- PC: el monitor del escritorio es 21:9 (3440x1440); Moonlight es una pantalla virtual 16:9 (1920x1080).
-- Deck: su pantalla es 1280x800; otra cosa es el Dock.
function YB:ScreenSize()
  if GetPhysicalScreenSize then
    local w, h = GetPhysicalScreenSize()
    if w and h and h > 0 then return w, h end
  end
end
function YB:DetectMode()
  local w, h = self:ScreenSize()
  if self:Device() == "deck" then
    return (w == 1280 and h == 800) and "deck" or "dock"
  end
  if not w then return "pc" end
  return (w / h) > 2.0 and "pc" or "moonlight"
end

---------------------------------------------------------------- escala (por modo)
local SCALE_MIN, SCALE_MAX = 0.64, 1.15
function YB:Scale()
  local v = tonumber(getCVar("uiScale") or "")
  if not v and UIParent and UIParent.GetScale then v = UIParent:GetScale() end
  return v or 1
end
function YB:SetScale(v)
  if YB.InCombat() then return false, "Sal del combate primero." end
  v = math.floor(math.max(SCALE_MIN, math.min(SCALE_MAX, v)) * 100 + 0.5) / 100
  setCVar("useUiScale", "1")
  setCVar("uiScale", tostring(v))
  if UIParent and UIParent.SetScale then pcall(UIParent.SetScale, UIParent, v) end
  self:Mode().scale = v
  if YB.LayoutHint then YB.LayoutHint() end
  return true, ("Escala %.2f (guardada para %s)."):format(v, YB.MODE_NAMES[self:ModeKey()])
end

---------------------------------------------------------------- stick derecho siempre cámara (modos de mando)
function YB:StickCameraOn() return getCVar("GamePadCursorAutoEnable") == "0" end
function YB:ApplyStickCamera()
  local on = self:StyleFor(self:ModeKey()) == "1" and self:Mode().stickCamera
  setCVar("GamePadCursorAutoEnable", on and "0" or "1")
  setCVar("GamePadCursorAutoDisableSticks", "2")
end
function YB:SetStickCamera(on)
  if YB.InCombat() then return false, "Sal del combate primero." end
  if self:StyleFor(self:ModeKey()) ~= "1" then return false, "Esta opción es para los modos con mando." end
  self:Mode().stickCamera = on
  self:ApplyStickCamera()
  return true, on and "El stick derecho mueve siempre la cámara." or "Stick derecho como trae WoW (cursor en los menús)."
end

---------------------------------------------------------------- diseños de Edit Mode (por modo, por nombre)
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
  return true, "Diseño: no cambiar (guardado para " .. YB.MODE_NAMES[self:ModeKey()] .. ")."
end
function YB:ApplyLayout()
  local want = self:Mode().layout
  if not want then return true end
  if YB.InCombat() then return false, "Sal del combate primero." end
  local list, active = self:Layouts()
  for _, l in ipairs(list) do
    if l.name == want then
      if l.index ~= active and C_EditMode.SetActiveLayout then pcall(C_EditMode.SetActiveLayout, l.index) end
      return true, "Diseño \"" .. want .. "\" (guardado para " .. YB.MODE_NAMES[self:ModeKey()] .. ")."
    end
  end
  return false, "No encuentro el diseño \"" .. want .. "\" en Edit Mode: créalo allí o elige otro."
end

---------------------------------------------------------------- aplicar un modo
-- Cambiar el estilo de interfaz hace que el juego recargue la interfaz; YB termina el modo al volver.
function YB:InterfaceStyle() return getCVar("InputDeviceInterfaceStyle") end
function YB:ApplyMode(m)
  if YB.InCombat() then return false, "Sal del combate primero." end
  local g = self:Global()
  local dev = YB.DEVICES[self:Device() or "pc"]
  local valid = false
  for _, x in ipairs(dev.modes) do if x == m then valid = true end end
  if not (valid and g.modes[m]) then return false, "Modo desconocido para esta máquina." end
  g.mode = m
  local mode = g.modes[m]
  setCVar("GamePadEnable", "1")
  if mode.scale == nil then mode.scale = self:Scale() end
  self:SetScale(mode.scale)
  self:ApplyStickCamera()
  if YB.LayoutHint then YB.LayoutHint() end
  local style = self:StyleFor(m)
  if self:InterfaceStyle() ~= style then
    g.styleChange = { mode = m, at = time() }
    setCVar("InputDeviceInterfaceStyle", style)
    if C_Timer and C_Timer.After then
      C_Timer.After(3, function() if not YB.InCombat() then ReloadUI() end end)
    end
    return true, ("Modo %s: escala %.2f, %s: la interfaz se recarga..."):format(YB.MODE_NAMES[m], mode.scale,
      style == "1" and "interfaz de mando" or "teclado y ratón")
  end
  local okL, msgL = self:ApplyLayout()
  local msg = ("Modo %s: escala %.2f."):format(YB.MODE_NAMES[m], mode.scale)
  if mode.layout then msg = msg .. " " .. (msgL or "") end
  return okL ~= false, msg
end

-- Al entrar: elegir el modo (Auto) y poner sus ajustes
function YB:Startup()
  if YB.InCombat() then YB.pendingStartup = true return end
  local g = self:Global()
  if not g.device then
    if YB.Toggle then YB:Toggle(true) end
    tell("elige el dispositivo en la ventana de YB (PC o Steam Deck).")
    return
  end
  if YB.migrated then
    YB.migrated = nil
    tell("ajustes de la 5.x pasados a la 6.1: Deck y Dock conservan su escala y su aviso.")
  end
  if g.device == "deck" then
    if YB.macrosLater then YB.macrosLater = nil; self:ApplyKeys() end
    local n = self:CleanSavedDeckKeys()
    if n > 0 then tell(("quitadas %d teclas guardadas de la 5.x: ahora YB las pone sin guardarlas, y el PC deja de recibirlas."):format(n)) end
  end
  local want = g.auto and self:DetectMode() or self:ModeKey()
  local styleOK = self:InterfaceStyle() == self:StyleFor(want)
  if not styleOK and g.styleChange and g.styleChange.mode == want and (time() - (g.styleChange.at or 0)) < 60 then
    g.mode = want
    g.styleChange = nil
    tell("no pude cambiar el estilo de interfaz para el modo " .. YB.MODE_NAMES[want] ..
      ". Cambia 'Activar interfaz de mando' a mano en las opciones de WoW.")
    return
  end
  g.styleChange = nil
  local _, msg = self:ApplyMode(want)
  if msg then tell(msg) end
end

---------------------------------------------------------------- armas
function YB:CaptureWeapons(which)
  if YB.InCombat() then return false, "Sal del combate primero." end
  local w = { mh = GetInventoryItemID("player", 16), oh = GetInventoryItemID("player", 17) }
  if not w.mh then return false, "No llevas arma en la mano principal." end
  self:DB().weapons[which] = w
  if YB.RefreshSetMacros then YB:RefreshSetMacros() end
  if YB.UpdateWeaponHint then YB.UpdateWeaponHint() end
  return true, ("Conjunto %s guardado: %s."):format(which == "feral" and "feral" or "de lanzador", self:WeaponText(which))
end
function YB:ClearWeapons(which)
  if YB.InCombat() then return false, "Sal del combate primero." end
  self:DB().weapons[which] = {}
  if YB.RefreshSetMacros then YB:RefreshSetMacros() end
  if YB.UpdateWeaponHint then YB.UpdateWeaponHint() end
  return true, ("Conjunto %s borrado."):format(which == "feral" and "feral" or "de lanzador")
end
function YB:WeaponText(which)
  local w = self:DB().weapons[which] or {}
  if not w.mh then return "ninguno" end
  local function n(id) return YB.ItemName(id) or ("objeto " .. id) end
  return n(w.mh) .. (w.oh and (" + " .. n(w.oh)) or "")
end

---------------------------------------------------------------- teclas elegidas en YB (override bindings, PC)
YB.KEY_ACTIONS = {
  { id = "caster", label = "Equipar conjunto de lanzador", macro = "YB Caster Set" },
  { id = "feral",  label = "Equipar conjunto feral",       macro = "YB Feral Set" },
}
local owner = CreateFrame("Frame", "YagriverBindsKeys")
function YB:ApplyKeys()
  if YB.InCombat() then YB.pendingKeys = true return false end
  ClearOverrideBindings(owner)
  if self:Device() == "deck" then self:ApplyDeckKeys(owner) return true end
  if self:Device() ~= "pc" then return true end
  local g = self:Global()
  for _, a in ipairs(YB.KEY_ACTIONS) do
    local key = g.keys[a.id]
    if key then SetOverrideBindingMacro(owner, false, key, a.macro) end
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
function YB:KeyUnder(key)
  local a = GetBindingAction and GetBindingAction(key, false) or ""
  return a ~= "" and a or nil
end
function YB:SetKey(id, key)
  if YB.InCombat() then return false, "Sal del combate primero." end
  local g = self:Global()
  for _, a in ipairs(YB.KEY_ACTIONS) do
    if a.id ~= id and key and g.keys[a.id] == key then g.keys[a.id] = nil end
  end
  g.keys[id] = key
  self:ApplyKeys()
  if YB.UpdateWeaponHint then YB.UpdateWeaponHint() end
  if not key then return true, "Tecla quitada." end
  local under = self:KeyUnder(key)
  return true, ("Tecla %s."):format(self:KeyText(key)) ..
    (under and (" Mientras YB funciona sustituye a: " .. under .. ".") or "")
end

---------------------------------------------------------------- comprobaciones (solo leen)
function YB:DeckLeftovers()
  local out = {}
  for _, key in ipairs(YB.deckKeys) do
    local a = GetBindingAction and GetBindingAction(key, false) or ""
    if a ~= "" then table.insert(out, { key = key, action = a }) end
  end
  return out
end
function YB:Conflicts()
  local out = {}
  if YB.IsLoaded("YagriverBindsPC") then table.insert(out, "YagriverBindsPC (la versión anterior) está activado: desactívalo.") end
  for _, name in ipairs(YB.controllerAddons) do
    if YB.IsLoaded(name) then table.insert(out, name .. " está activado: se pelearía con Easy Controller por los botones.") end
  end
  return out
end

---------------------------------------------------------------- modo automático al cambiar la pantalla
local banner = CreateFrame("Frame", "YagriverBindsBanner", UIParent, "BackdropTemplate")
banner:SetSize(440, 64); banner:SetPoint("TOP", 0, -90); banner:SetFrameStrata("DIALOG"); banner:Hide()
if banner.SetBackdrop then
  banner:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  banner:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
end
local bText = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bText:SetPoint("TOP", 0, -10)
local bNow = CreateFrame("Button", nil, banner, "UIPanelButtonTemplate"); bNow:SetSize(130, 22); bNow:SetPoint("BOTTOMLEFT", 70, 8)
bNow:SetText("Cambiar ya")
local bStay = CreateFrame("Button", nil, banner, "UIPanelButtonTemplate"); bStay:SetSize(130, 22); bStay:SetPoint("BOTTOMRIGHT", -70, 8)
bStay:SetText("Quedarme")
local pending, countdown = nil, 0
local function finishBanner(go)
  banner:Hide()
  banner:SetScript("OnUpdate", nil)
  local m = pending
  pending = nil
  if go and m then
    local _, msg = YB:ApplyMode(m)
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
    bText:SetText(("Pantalla nueva: modo %s en %d s"):format(YB.MODE_NAMES[m], math.ceil(countdown)))
  end)
end
local screenTimer
local function screenChanged()
  local g = YB:Global()
  if not g.device or not g.auto or not YB.started then return end
  local want = YB:DetectMode()
  if want ~= YB:ModeKey() then YB:OfferMode(want) elseif pending then finishBanner(false) end
end

---------------------------------------------------------------- eventos
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("DISPLAY_SIZE_CHANGED")
ev:RegisterEvent("SPELLS_CHANGED")
local spellTimer
ev:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    YB:ApplyKeys()
    if C_Timer and C_Timer.After then
      C_Timer.After(1.5, function() YB:Startup(); YB.started = true end)
    else
      YB:Startup(); YB.started = true
    end
    for _, c in ipairs(YB:Conflicts()) do tell("|cffff5050" .. c .. "|r") end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if YB.pendingKeys then YB.pendingKeys = nil; YB:ApplyKeys() end
    if YB.pendingClean then YB.pendingClean = nil; YB:CleanSavedDeckKeys() end
    if YB.pendingStartup then YB.pendingStartup = nil; YB:Startup(); YB.started = true end
    if YB.pendingOffer then local m = YB.pendingOffer; YB.pendingOffer = nil; YB:OfferMode(m) end
  elseif event == "PLAYER_REGEN_DISABLED" then
    if pending then YB.pendingOffer = pending; finishBanner(false) end
  elseif event == "SPELLS_CHANGED" then
    -- la Deck: rangos y hechizos nuevos (Oso temible, Suprimir veneno...) en sus teclas
    if YB:Device() ~= "deck" or not YB.started then return end
    if spellTimer then spellTimer:Cancel() end
    local function again() if YB.InCombat() then YB.pendingKeys = true else YB:ApplyKeys() end end
    if C_Timer and C_Timer.NewTimer then spellTimer = C_Timer.NewTimer(2, again) else again() end
  elseif event == "DISPLAY_SIZE_CHANGED" then
    if screenTimer then screenTimer:Cancel() end
    if C_Timer and C_Timer.NewTimer then screenTimer = C_Timer.NewTimer(1.5, screenChanged) else screenChanged() end
  end
end)
