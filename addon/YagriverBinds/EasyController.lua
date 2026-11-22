-- Yagriver Binds 6 - "Preparar Easy Controller".
-- Monta las ruedas y el modo sanador de YB en el perfil ACTUAL de Easy Controller, con las
-- funciones del propio Easy Controller (las mismas que usa su panel). No escribe en sus archivos.
-- No crea perfiles: uno nuevo vacía la barra del mando, y esa barra viaja a la otra máquina.
-- Antes de cambiar un botón apunta lo que había; "Deshacer" lo deja como estaba.
local ADDON, YB = ...
local EC = {}
YB.EC = EC

local function CK() return _G.ControllerKeyboard end
local function ecSettings() local ck = CK(); return ck and ck.db and ck.db.settings end

function EC:Version()
  local fn = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  if not fn then return nil end
  local ok, v = pcall(fn, "EasyController", "Version")
  return ok and v or nil
end
local function majorMinor(v) return v and v:match("^(%d+%.%d+)") end

-- ¿Se puede preparar ahora? Devuelve true, o false y el motivo
function EC:Ready()
  local ck = CK()
  if not (YB.IsLoaded("EasyController") and ck) then return false, "Easy Controller no está activado." end
  local v = self:Version()
  if not YB.EC_TESTED[majorMinor(v) or ""] then
    return false, ("Easy Controller %s: no he leído esta versión, así que no toco nada. Usa la hoja de pasos."):format(tostring(v))
  end
  if not (ck.MapPage and ck.MapPage.Put and ck.Mapping and ck.Mapping.BY_ID and ck.MyWheels and ck.MyWheels.Create
          and ecSettings()) then
    return false, "Easy Controller no expone lo que esperaba (¿versión cambiada?). No toco nada."
  end
  if ck.Mapping.Enabled and not ck.Mapping:Enabled() then return false, "Activa el módulo de mapeo en Easy Controller (Inicio)." end
  if YB.InCombat() then return false, "Sal del combate primero." end
  if YB:InterfaceStyle() ~= "1" then return false, "Hazlo con la interfaz de mando activa (modo Moonlight)." end
  return true
end

---------------------------------------------------------------- qué va en cada hueco
-- Monturas: la que tengas en el botón 12 de la barra 5 (la de Ctrl+F9 en la Deck)
local BAR_BASE = { MULTIACTIONBAR1 = 60, MULTIACTIONBAR2 = 48, MULTIACTIONBAR3 = 24, MULTIACTIONBAR4 = 36,
  MULTIACTIONBAR5 = 144, MULTIACTIONBAR6 = 156, MULTIACTIONBAR7 = 168, ACTION = 0 }
function EC:MountAction()
  local cmd = GetBindingAction and GetBindingAction("CTRL-F9", false) or ""
  local bar, n = cmd:match("^(%u+%d?)BUTTON(%d+)$")
  if cmd:match("^ACTIONBUTTON(%d+)$") then bar, n = "ACTION", cmd:match("(%d+)$") end
  local slot = bar and BAR_BASE[bar] and (BAR_BASE[bar] + tonumber(n)) or 156
  if not GetActionInfo then return nil, nil end
  local kind, id = GetActionInfo(slot)   -- (two values: never "GetActionInfo and GetActionInfo(...)")
  if kind == "spell" and id then return "spell:" .. id, YB.SpellName(id) end
  if kind == "item" and id then return "item:" .. id, YB.ItemName(id) end
  if kind == "macro" and id then local mn = GetMacroInfo(id); if mn then return "macro:" .. mn, mn end end
  return nil, nil
end

function EC:SlotAction(s)
  local kind, v = s[1], s[2]
  if kind == "spell" then local id, n = YB:Spell(v); return id and ("spell:" .. id), n end
  if kind == "macro" then return "macro:" .. v, v end
  if kind == "item" then return "item:" .. v, YB.ItemName(v) or ("objeto " .. v) end
  if kind == "mount" then return self:MountAction() end
end
function EC:PartyAction(p)
  local id, n = YB:Spell(p.spell)
  return id and ("wheel:party:" .. id), n
end

---------------------------------------------------------------- vista previa
local LAYER_TEXT = { [""] = "", LT = "ZL + ", RT = "ZR + ", LTRT = "ZL + ZR + " }
local POSITION = { A = "abajo (A)", B = "derecha (B)", X = "izquierda (X)", Y = "arriba (Y)", R3 = "R3" }
local function combo(input, layer) return LAYER_TEXT[layer] .. (POSITION[input] or input) end
function EC:Preview()
  local lines = {}
  for _, w in ipairs(YB.EC_WHEELS) do
    local names = {}
    for _, s in ipairs(w.slots) do
      local _, n = self:SlotAction(s)
      table.insert(names, n or (s[1] == "mount" and "(montura: ponla en la barra 5, botón 12)" or "?"))
    end
    table.insert(lines, ("%s  %s (%s): %s"):format(combo(w.input, w.layer), w.name:gsub("^YB ", ""),
      w.style == "stick" and "mini de stick" or "grande", table.concat(names, ", ")))
  end
  for _, p in ipairs(YB.EC_PARTY) do
    local _, n = self:PartyAction(p)
    table.insert(lines, ("%s  sanador: %s"):format(combo(p.input, p.layer), n or "?"))
  end
  table.insert(lines, "Opciones: vender lo gris, reparar, rojo fuera de alcance, ocultar errores de cada pulsación" ..
    (YB:Device() == "pc" and ", letras de Switch, punto central que cambia de color (OLED)" or "") .. ".")
  table.insert(lines, "R3 deja de hacer ping (el ping va en la rueda de Utilidad).")
  return lines
end

---------------------------------------------------------------- aplicar
local function key(input, layer) return input .. ":" .. layer end
local function findWheel(name)
  local ck = CK()
  for _, w in ipairs(ck.MyWheels:List() or {}) do if w.name == name then return w.id end end
end
local OPTIONS = {
  { path = { "modules", "sellJunk" }, value = true },
  { path = { "modules", "autoRepair" }, value = true },
  { path = { "features", "rangeTint" }, value = true, apply = function(ck) if ck.Range and ck.Range.Apply then ck.Range:Apply() end end },
  { path = { "features", "quietErrors" }, value = true, apply = function(ck) if ck.QuietErrors and ck.QuietErrors.Apply then ck.QuietErrors:Apply() end end },
}
local function getPath(t, path) for i = 1, #path - 1 do t = t and t[path[i]] end return t and t[path[#path]] end
local function setPath(t, path, v)
  for i = 1, #path - 1 do t[path[i]] = t[path[i]] or {}; t = t[path[i]] end
  t[path[#path]] = v
end

function EC:Backup()
  local db = YB:DB()
  db.ec = db.ec or {}
  local b = db.ec
  b.replaced = b.replaced or {}
  b.mapping = b.mapping or {}
  b.options = b.options or {}
  b.created = b.created or {}
  return b
end

-- remember a button's previous assignment once (the first time YB changes it)
local function remember(b, s, input, layer)
  local k = key(input, layer)
  if b.replaced[k] == nil then b.replaced[k] = s.replaced[k] or false end
  if b.mapping[k] == nil then b.mapping[k] = s.mapping[k] or false end
end

function EC:Apply()
  local ok, why = self:Ready()
  if not ok then return false, why end
  local ck, s = CK(), ecSettings()
  local b = self:Backup()
  local failed, done = {}, 0
  local missing = YB:EnsureMacros()
  for _, m in ipairs(missing) do table.insert(failed, "macro " .. m) end

  -- the four wheels
  for _, w in ipairs(YB.EC_WHEELS) do
    local id = findWheel(w.name)
    if not id then
      id = ck.MyWheels:Create()
      if id then table.insert(b.created, id) end
    end
    if not id then
      table.insert(failed, w.name .. " (no caben más ruedas: Easy Controller admite 8)")
    else
      ck.MyWheels:Rename(id, w.name)
      for i = 1, 8 do
        local action = w.slots[i] and self:SlotAction(w.slots[i]) or nil
        ck.MyWheels:SetSlot(id, i, action)
      end
      ck.MyWheels:SetStyle(id, w.style)
      remember(b, s, w.input, w.layer)
      if ck.MapPage:Put(ck.Mapping.BY_ID[w.input], w.layer, "wheel:" .. id) then
        done = done + 1
      else
        table.insert(failed, combo(w.input, w.layer) .. " (Easy Controller no deja ponerla ahí)")
      end
    end
  end

  -- healer mode on R3 (alone first: then its trigger layers open up)
  for _, p in ipairs(YB.EC_PARTY) do
    local action = self:PartyAction(p)
    remember(b, s, p.input, p.layer)
    if action and ck.MapPage:Put(ck.Mapping.BY_ID[p.input], p.layer, action) then
      done = done + 1
    else
      table.insert(failed, combo(p.input, p.layer) .. " (sanador)")
    end
  end

  -- options
  for _, o in ipairs(OPTIONS) do
    local k = table.concat(o.path, ".")
    if b.options[k] == nil then
      local cur = getPath(s, o.path)
      b.options[k] = cur == nil and "nil" or cur
    end
    setPath(s, o.path, o.value)
    if o.apply then pcall(o.apply, ck) end
  end
  if YB:Device() == "pc" then
    if b.options.glyphStyle == nil then b.options.glyphStyle = s.glyphStyle or "auto" end
    if ck.PickGlyphStyle then pcall(ck.PickGlyphStyle, ck, "switch") end
    if b.options.reticle == nil then b.options.reticle = (s.reticle and s.reticle.mode) or "game" end
    if ck.Reticle and ck.Reticle.SetMode then pcall(ck.Reticle.SetMode, ck.Reticle, "cycle") end
  end

  if ck.Mapping.Apply then pcall(ck.Mapping.Apply, ck.Mapping) end
  if ck.Paddles and ck.Paddles.Apply then pcall(ck.Paddles.Apply, ck.Paddles) end
  b.version, b.at = self:Version(), time()
  local msg = ("Easy Controller preparado: %d botones."):format(done)
  if #failed > 0 then msg = msg .. " Sin hacer: " .. table.concat(failed, "; ") .. "." end
  return #failed == 0, msg
end

function EC:Applied() local db = YB:DB(); return (db.ec and db.ec.at ~= nil) and true or false end

---------------------------------------------------------------- deshacer
function EC:Undo()
  local ck, s = CK(), ecSettings()
  if not (ck and s) then return false, "Easy Controller no está activado." end
  if YB.InCombat() then return false, "Sal del combate primero." end
  local db = YB:DB()
  local b = db.ec
  if not b then return false, "No hay nada que deshacer." end
  for _, id in ipairs(b.created or {}) do pcall(ck.MyWheels.Delete, ck.MyWheels, id) end
  for k, prev in pairs(b.replaced or {}) do
    local input, layer = k:match("^([^:]+):(.*)$")
    if ck.Mapping.SetReplaced then pcall(ck.Mapping.SetReplaced, ck.Mapping, input, layer, prev or nil) end
  end
  for k, prev in pairs(b.mapping or {}) do
    local input, layer = k:match("^([^:]+):(.*)$")
    s.mapping[k] = prev or nil
  end
  for k, prev in pairs(b.options or {}) do
    if k == "glyphStyle" then
      if ck.PickGlyphStyle then pcall(ck.PickGlyphStyle, ck, prev) end
    elseif k == "reticle" then
      if ck.Reticle and ck.Reticle.SetMode then pcall(ck.Reticle.SetMode, ck.Reticle, prev) end
    else
      local path = {}
      for part in k:gmatch("[^%.]+") do table.insert(path, part) end
      local value = prev
      if prev == "nil" then value = nil end   -- (false stays false)
      setPath(s, path, value)
    end
  end
  if ck.Range and ck.Range.Apply then pcall(ck.Range.Apply, ck.Range) end
  if ck.QuietErrors and ck.QuietErrors.Apply then pcall(ck.QuietErrors.Apply, ck.QuietErrors) end
  if ck.Mapping.Apply then pcall(ck.Mapping.Apply, ck.Mapping) end
  if ck.Paddles and ck.Paddles.Apply then pcall(ck.Paddles.Apply, ck.Paddles) end
  db.ec = nil
  return true, "Easy Controller como estaba antes de YB."
end

---------------------------------------------------------------- rangos nuevos al entrenar
-- Las ruedas guardan un rango concreto: al aprender uno más alto, YB lo cambia en sus huecos.
function EC:SyncRanks()
  if not self:Applied() or YB.InCombat() then return end
  local ck = CK()
  if not (ck and ck.MyWheels and YB.EC_TESTED[majorMinor(self:Version()) or ""]) then return end
  local changed = 0
  for _, w in ipairs(YB.EC_WHEELS) do
    local id = findWheel(w.name)
    local wheel = id and ck.MyWheels:Get(id)
    if wheel then
      for i, slot in ipairs(w.slots) do
        if slot[1] == "spell" then
          local action = self:SlotAction(slot)
          if action and wheel.slots[i] ~= action then ck.MyWheels:SetSlot(id, i, action); changed = changed + 1 end
        end
      end
    end
  end
  local s = ecSettings()
  for _, p in ipairs(YB.EC_PARTY) do
    local action = self:PartyAction(p)
    local cur = s and s.replaced[key(p.input, p.layer)]
    if action and cur and cur:find("^wheel:party:") and cur ~= action then
      pcall(ck.Mapping.SetReplaced, ck.Mapping, p.input, p.layer, action); changed = changed + 1
    end
  end
  if changed > 0 then YB.Tell(("rangos nuevos puestos en las ruedas (%d)."):format(changed)) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("SPELLS_CHANGED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
local timer
ev:SetScript("OnEvent", function(_, event)
  if event == "SPELLS_CHANGED" or EC.syncPending then
    if YB.InCombat() then EC.syncPending = true return end
    EC.syncPending = nil
    if timer then timer:Cancel() end
    if C_Timer and C_Timer.NewTimer then timer = C_Timer.NewTimer(2, function() EC:SyncRanks() end) else EC:SyncRanks() end
  end
end)
