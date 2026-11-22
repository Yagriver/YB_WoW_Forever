-- Yagriver Binds 6 - macros YB. Se comparten entre máquinas a propósito (son del personaje o de la cuenta).
-- Las que ya creó la Deck (YB Travel, YB Rejuv Self, conjuntos) se crean solo si faltan.
-- Las nuevas de las ruedas se reescriben siempre, con los nombres de hechizo de tu idioma.
local ADDON, YB = ...
local ICON = "INV_MISC_QUESTIONMARK"

local function name(key) local _, n = YB:Spell(key); return n or "?" end
local function click(button) return "/click " .. button .. " LeftButton true\n/click " .. button .. " LeftButton false" end

-- { nombre, cuerpo (función), ¿del personaje?, ¿reescribir? }
YB.MACROS = {
  { "YB Cat Prowl",  function() return "#showtooltip " .. name("prowl") .. "\n/cast !" .. name("cat") .. "\n/cast " .. name("prowl") end, false, true },
  { "YB Cat Dash",   function() return "#showtooltip " .. name("dash") .. "\n/cast !" .. name("cat") .. "\n/cast " .. name("dash") end, false, true },
  { "YB Bear Enrage", function() return "#showtooltip " .. name("enrage") .. "\n/cast !" .. name("bear") .. "\n/cast " .. name("enrage") end, false, true },
  { "YB Travel",     function() return "#showtooltip\n/cast [swimming] " .. name("aquatic") .. "; " .. name("travel") end, true, false },
  { "YB Rejuv Self", function() return "#showtooltip\n/cast [@player] " .. name("rejuv") end, true, false },
  { "YB Ping",       function() return "/ping" end, false, true },
  { "YB EC Frases",  function() return click("ControllerKeyboardPhrasesToggle") end, false, true },
  { "YB EC Consum",  function() return click("ControllerKeyboardWheelToggle") end, false, true },
  { "YB EC Usables", function() return click("ControllerKeyboardUsableToggle") end, false, true },
  { "YB Ajustes",    function() return "/yag" end, false, true },
  { "YB EC Ajustes", function() return "/ec config" end, false, true },
}

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

-- Al cambiar de idioma de hechizos o aprender formas: las macros reescribibles al día (fuera de combate)
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function()
  if YB.pendingMacros then YB.pendingMacros = nil; YB:RefreshSetMacros() end
end)
