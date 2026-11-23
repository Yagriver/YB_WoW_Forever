-- Yagriver Binds 6 - macros YB. Se comparten entre máquinas a propósito (son del personaje o de la cuenta).
-- Las que ya creó la Deck (YB Travel, YB Rejuv Self, conjuntos) se crean solo si faltan.
-- Las nuevas de las ruedas se reescriben siempre, con los nombres de hechizo de tu idioma.
local ADDON, YB = ...
local ICON = "INV_MISC_QUESTIONMARK"

local function name(key) local _, n = YB:Spell(key); return n or "?" end
local function click(button) return "/click " .. button .. " LeftButton true\n/click " .. button .. " LeftButton false" end

-- Índice de una forma en la barra de formas (cambia al aprender formas nuevas)
function YB:FormIndex(key)
  local set = {}
  for _, id in ipairs(YB.SPELL[key] or {}) do set[id] = true end
  for i = 1, (GetNumShapeshiftForms and GetNumShapeshiftForms() or 0) do
    local sid = YB.FormSpellID(i)
    if sid and set[sid] then return i end
  end
end
-- Forma + extra con una sola línea: fuera de la forma entra en ella; dentro, lanza el extra.
-- (En Forever "/cast !Forma" no impide volver a lanzar la forma, por eso se usa [noform:N].)
-- Pulsar otra vez con Acecho puesto lo quita, como el botón normal.
local function formExtra(form, extra)
  local idx = YB:FormIndex(form)
  if idx then
    return "#showtooltip " .. name(extra) .. "\n/cast [noform:" .. idx .. "] " .. name(form) .. "; " .. name(extra)
  end
  return "#showtooltip " .. name(extra) .. "\n/cast " .. name(form)
end
-- El comando de ping va traducido: en el cliente en español es /aviso, no /ping
function YB.PingCommand()
  for i = 1, 4 do
    local c = _G["SLASH_PING" .. i]
    if type(c) == "string" and c:sub(1, 1) == "/" then return c end
  end
  return "/ping"
end

-- { nombre, cuerpo (función), ¿del personaje?, ¿reescribir? }
YB.MACROS = {
  { "YB Cat Prowl",  function() return formExtra("cat", "prowl") end, false, true },
  { "YB Cat Dash",   function() return formExtra("cat", "dash") end, false, true },
  { "YB Bear Enrage", function() return formExtra("bear", "enrage") end, false, true },
  { "YB Travel",     function() return "#showtooltip\n/cast [swimming] " .. name("aquatic") .. "; " .. name("travel") end, true, false },
  { "YB Rejuv Self", function() return "#showtooltip\n/cast [@player] " .. name("rejuv") end, true, false },
  { "YB Ping",       function() return YB.PingCommand() .. " [@target,exists][]" end, false, true },
  { "YB EC Frases",  function() return click("ControllerKeyboardPhrasesToggle") end, false, true },
  { "YB EC Consum",  function() return click("ControllerKeyboardWheelToggle") end, false, true },
  { "YB EC Usables", function() return click("ControllerKeyboardUsableToggle") end, false, true },
  { "YB Ajustes",    function() return "/yag" end, false, true },
  { "YB EC Ajustes", function() return "/ec config" end, false, true },
}
local DECK_KEY_MACROS = { ["YB Travel"] = true, ["YB Rejuv Self"] = true, ["YB EC Frases"] = true, ["YB Ajustes"] = true }

function YB.MacroBody(n)
  if GetMacroIndexByName(n) == 0 then return nil end
  if GetMacroBody then local b = GetMacroBody(n); if b then return b end end
  local _, _, body = GetMacroInfo(n)
  return body
end

-- crea si falta; reescribe solo si overwrite. Devuelve true si la macro existe al acabar.
function YB:EnsureMacro(n, body, perChar, overwrite)
  if YB.InCombat() then return false end
  if #body > 255 then return false end
  local idx = GetMacroIndexByName(n)
  if idx == 0 then
    local ok = pcall(CreateMacro, n, ICON, body, perChar and true or nil)
    return ok and GetMacroIndexByName(n) ~= 0
  elseif overwrite and YB.MacroBody(n) ~= body then
    pcall(EditMacro, idx, nil, nil, body)
  end
  return true
end

-- Todas las macros que usan las ruedas. Devuelve la lista de las que no se pudieron crear.
function YB:EnsureMacros()
  local failed = {}
  for _, m in ipairs(YB.MACROS) do
    if not self:EnsureMacro(m[1], m[2](), m[3], m[4]) then table.insert(failed, m[1]) end
  end
  if not self:RefreshSetMacros(true) then table.insert(failed, "YB Caster Set / YB Feral Set") end
  return failed
end

-- Conjuntos de armas: YB Caster Set / YB Feral Set, los mismos nombres que en la Deck.
-- Se escriben solo si este personaje tiene el conjunto guardado aquí; si no, se deja la de la Deck.
function YB:RefreshSetMacros(create)
  if YB.InCombat() then YB.pendingMacros = true return false end
  local ok = true
  for _, which in ipairs({ "caster", "feral" }) do
    local n = which == "caster" and "YB Caster Set" or "YB Feral Set"
    local w = self:DB().weapons[which] or {}
    if w.mh then
      local body = "#showtooltip\n/equipslot 16 item:" .. w.mh .. (w.oh and ("\n/equipslot 17 item:" .. w.oh) or "")
      ok = self:EnsureMacro(n, body, true, true) and ok
    elseif create and GetMacroIndexByName(n) == 0 then
      local body = "/run print('|cff88ccffYagriver Binds:|r guarda el conjunto en /yag > Armas > Usar equipado.')"
      ok = self:EnsureMacro(n, body, true, false) and ok
    end
  end
  return ok
end

-- Las macros que usan las teclas de la plantilla de Steam (Deck)
function YB:EnsureDeckKeyMacros()
  for _, m in ipairs(YB.MACROS) do
    if DECK_KEY_MACROS[m[1]] then self:EnsureMacro(m[1], m[2](), m[3], m[4]) end
  end
  self:RefreshSetMacros(true)
end

-- Macros ya creadas que dependen del índice de las formas o del idioma: al día (no crea ninguna)
function YB:RefreshMacros()
  if YB.InCombat() then YB.pendingMacros = true return end
  for _, m in ipairs(YB.MACROS) do
    if m[4] and GetMacroIndexByName(m[1]) ~= 0 then self:EnsureMacro(m[1], m[2](), m[3], true) end
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
ev:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_ENABLED" then
    if YB.pendingMacros then YB.pendingMacros = nil; YB:RefreshSetMacros(); YB:RefreshMacros() end
  else
    YB:RefreshMacros()
  end
end)
