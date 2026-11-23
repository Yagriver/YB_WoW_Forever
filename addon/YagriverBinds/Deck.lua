-- Yagriver Binds 6 - Steam Deck: las teclas que manda la plantilla de Steam (v5).
-- Son "override bindings": existen solo mientras YB funciona en la Deck. WoW no las guarda y el
-- servidor de Blizzard no las copia al PC.
-- La 5.x las guardaba con SetBinding. En la Deck, y solo en la Deck, YB quita esas teclas guardadas
-- (solo si siguen siendo exactamente lo que puso la 5.x) y deja lo que había antes de la 5.x.
-- Así desaparecen también del PC.
local ADDON, YB = ...

-- { tecla, tipo, valor, texto }
--   macro: nombre de macro YB | spell: clave de YB.SPELL | hold: clave de YB.SPELL (botón oculto) |
--   cmd: comando de WoW
YB.DECK_BINDS = {
  { "F1", "macro", "YB Travel", "L4: Viaje / Acuática" },
  { "F2", "macro", "YB Bear", "L5: Oso" },
  { "F3", "macro", "YB Cat", "R4: Gato" },
  { "SHIFT-F1", "hold", "dash", "L4 mantener: Carrera" },
  { "SHIFT-F2", "hold", "enrage", "L5 mantener: Enfurecer" },
  { "SHIFT-F3", "hold", "prowl", "R4 mantener: Acecho" },
  { "CTRL-F1", "spell", "innervate", "R5 + pad der.: Enervar" },
  { "CTRL-F2", "spell", "barkskin", "R5 + pad der.: Pielcorteza" },
  { "CTRL-F3", "spell", "grasp", "R5 + pad der.: Gracia de la naturaleza" },
  { "CTRL-F4", "macro", "YB Rejuv Self", "R5 + pad der.: Rejuvenecimiento en ti" },
  { "CTRL-F5", "spell", "rebirth", "R5 + A: Renacer" },
  { "CTRL-F6", "spell", "removeCurse", "R5 + B: Deshacer maldición" },
  { "CTRL-F7", "spell", "poison", "R5 + X: Suprimir / Curar veneno" },
  { "CTRL-F8", "spell", "motw", "R5 + Y: Marca de lo salvaje" },
  { "CTRL-F10", "macro", "YB Hearth", "R5 + cruceta arriba: Piedra de hogar" },
  { "CTRL-SHIFT-F5", "macro", "YB Caster Set", "R5 + cruceta izq.: arma de lanzador" },
  { "CTRL-SHIFT-F6", "macro", "YB Feral Set", "R5 + cruceta der.: arma feral" },
  { "CTRL-SHIFT-F11", "macro", "YB EC Frases", "R5 + pad izq.: frases (Easy Controller)" },
  { "CTRL-SHIFT-F12", "macro", "YB Ajustes", "R5 + pad izq.: menú YB" },
  { "CTRL-SHIFT-1", "cmd", "TARGETSELF", "L2 + pad izq.: yo" },
  { "CTRL-SHIFT-2", "cmd", "TARGETPARTYMEMBER1", "L2 + pad izq.: grupo 1" },
  { "CTRL-SHIFT-3", "cmd", "TARGETPARTYMEMBER2", "L2 + pad izq.: grupo 2" },
  { "CTRL-SHIFT-4", "cmd", "TARGETPARTYMEMBER3", "L2 + pad izq.: grupo 3" },
  { "CTRL-SHIFT-5", "cmd", "TARGETPARTYMEMBER4", "L2 + pad izq.: grupo 4" },
}
-- Ctrl+F9 (montura) es tuyo: lo pusiste con Quick Keybind en tu barra. YB no lo toca.

-- Macros de las teclas. Las que la 5.x ya creó se dejan como estén (si no faltan).
local function spellName(key) local _, n = YB:Spell(key); return n or "?" end
YB.DECK_MACROS = {
  { "YB Cat",  function() return "#showtooltip\n/cast " .. spellName("cat") end, true, true },
  { "YB Bear", function() return "#showtooltip\n/cast " .. spellName("bear") end, true, true },
  { "YB Hearth", function() return "#showtooltip\n/use item:6948" end, false, true },
}

---------------------------------------------------------------- botones ocultos (mantener)
-- Igual que en la 5.x: un botón de acción oculto sigue "lanzar al pulsar" como las barras, así el
-- hechizo sale en cuanto Steam llega al tiempo de mantener.
YB.holdButtons = {}
local HOLD_NAMES = { dash = "YBClickDash", enrage = "YBClickEnrage", prowl = "YBClickProwl" }
function YB:HoldButton(key)
  local name = HOLD_NAMES[key]
  local b = self.holdButtons[key]
  if not b then
    b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:Hide()
    self.holdButtons[key] = b
  end
  if not YB.InCombat() then
    b:SetAttribute("type", "spell")
    b:SetAttribute("spell", spellName(key))
  end
  return b, name
end

---------------------------------------------------------------- poner las teclas (override)
-- Las macros aún no están cargadas justo al entrar: crear entonces duplicaría las tuyas
function YB.MacrosReady()
  if not GetNumMacros then return true end
  local a, c = GetNumMacros()
  return ((a or 0) + (c or 0)) > 0
end
function YB:ApplyDeckKeys(owner)
  if YB.MacrosReady() then
    for _, m in ipairs(YB.DECK_MACROS) do self:EnsureMacro(m[1], m[2](), m[3], m[4]) end
    self:EnsureDeckKeyMacros()
  else
    YB.macrosLater = true
  end
  local n = 0
  for _, d in ipairs(YB.DECK_BINDS) do
    local key, kind, value = d[1], d[2], d[3]
    if kind == "macro" then
      pcall(SetOverrideBindingMacro, owner, false, key, value)
    elseif kind == "spell" then
      SetOverrideBindingSpell(owner, false, key, spellName(value))
    elseif kind == "hold" then
      local _, name = self:HoldButton(value)
      SetOverrideBindingClick(owner, false, key, name, "LeftButton")
    elseif kind == "cmd" then
      SetOverrideBinding(owner, false, key, value)
    end
    n = n + 1
  end
  YB.deckKeyCount = n
  return n
end

---------------------------------------------------------------- limpiar las teclas guardadas de la 5.x
-- Lo que la 5.x guardaba en cada tecla (para reconocerlo y no tocar nada tuyo)
local OLD = {
  F1 = { "MACRO YB Travel" }, F2 = { "MACRO YB Bear" }, F3 = { "MACRO YB Cat" },
  ["SHIFT-F1"] = { "CLICK YBClickDash:LeftButton" }, ["SHIFT-F2"] = { "CLICK YBClickEnrage:LeftButton" },
  ["SHIFT-F3"] = { "CLICK YBClickProwl:LeftButton" },
  ["CTRL-F4"] = { "MACRO YB Rejuv Self" }, ["CTRL-F10"] = { "MACRO YB Hearth" },
  ["CTRL-SHIFT-F5"] = { "MACRO YB Caster Set" }, ["CTRL-SHIFT-F6"] = { "MACRO YB Feral Set" },
  ["CTRL-SHIFT-F11"] = { "MACRO YB Panel" }, ["CTRL-SHIFT-F12"] = { "MACRO YB Settings" },
  ["CTRL-SHIFT-1"] = { "TARGETSELF" }, ["CTRL-SHIFT-2"] = { "TARGETPARTYMEMBER1" }, ["CTRL-SHIFT-3"] = { "TARGETPARTYMEMBER2" },
  ["CTRL-SHIFT-4"] = { "TARGETPARTYMEMBER3" }, ["CTRL-SHIFT-5"] = { "TARGETPARTYMEMBER4" },
}
local OLD_SPELL = { ["CTRL-F1"] = "innervate", ["CTRL-F2"] = "barkskin", ["CTRL-F3"] = "grasp",
  ["CTRL-F5"] = "rebirth", ["CTRL-F6"] = "removeCurse", ["CTRL-F7"] = "poison", ["CTRL-F8"] = "motw" }

local function isOld(key, action)
  for _, a in ipairs(OLD[key] or {}) do if a == action then return true end end
  local sk = OLD_SPELL[key]
  if sk then
    local spell = action:match("^SPELL (.+)$")
    if spell then
      for _, id in ipairs(YB.SPELL[sk] or {}) do
        local n = YB.SpellName(id)
        if n and (spell == n or spell:sub(1, #n + 1) == n .. "(") then return true end
      end
    end
  end
  return false
end

-- Solo en la Deck. Devuelve cuántas teclas quitó.
function YB:CleanSavedDeckKeys()
  if self:Device() ~= "deck" then return 0 end
  if YB.InCombat() then YB.pendingClean = true return 0 end
  local backup = (YagriverBindsCharDB and YagriverBindsCharDB.backup) or {}
  local n = 0
  for _, d in ipairs(YB.DECK_BINDS) do
    local key = d[1]
    local saved = GetBindingAction(key, false) or ""
    if saved ~= "" and isOld(key, saved) then
      local prev = backup[key]
      local m = prev and prev:match("^MACRO (.+)$")
      if m and GetMacroIndexByName(m) == 0 then prev = nil end
      if prev and prev ~= "" and not isOld(key, prev) then SetBinding(key, prev) else SetBinding(key) end
      n = n + 1
    end
  end
  if n > 0 then
    SaveBindings(GetCurrentBindingSet())
    local g = self:Global()
    g.cleaned = (g.cleaned or 0) + n
  end
  return n
end
