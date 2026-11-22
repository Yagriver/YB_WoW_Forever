-- Yagriver Binds - core engine. Profiles live in Profiles\*.lua (see README.txt).
-- Rules: nothing is created, bound or deleted unless the user clicks a button in the addon window.
local ADDON, YB = ...
YB.profiles = {}
YB.common = nil

function YB:RegisterProfile(classToken, profile) self.profiles[classToken] = profile end
function YB:RegisterCommon(profile) self.common = profile end

local ICON = "INV_MISC_QUESTIONMARK"

---------------------------------------------------------------- API compatibility
-- Forever runs on the modern client: many old globals moved into C_ namespaces.
function YB.SpellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  if C_Spell and C_Spell.GetSpellInfo then local i = C_Spell.GetSpellInfo(id); return i and i.name end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end
function YB.ItemName(id)
  if not id then return end
  if C_Item and C_Item.GetItemNameByID then local n = C_Item.GetItemNameByID(id); if n then return n end end
  if C_Item and C_Item.GetItemInfo then local n = C_Item.GetItemInfo(id); if n then return n end end
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
function YB.FormSpellID(i) return YB._FormSpellID(i) end
local function FormSpellID(i)
  if not GetShapeshiftFormInfo then return end
  local a, b, c, d = GetShapeshiftFormInfo(i)
  if type(d) == "number" then return d end
  if type(c) == "number" then return c end
end
YB._FormSpellID = FormSpellID
function YB.MacroBody(name)
  if GetMacroIndexByName(name) == 0 then return nil end
  if GetMacroBody then local b = GetMacroBody(name); if b then return b end end
  local _, _, body = GetMacroInfo(name)
  return body
end
function YB.InCombat() return InCombatLockdown and InCombatLockdown() end

function YB:DB()
  YagriverBindsCharDB = YagriverBindsCharDB or {}
  local db = YagriverBindsCharDB
  db.groups  = db.groups  or {}
  db.swap    = db.swap    or {}
  db.weapons = db.weapons or {}
  db.weapons.feral  = db.weapons.feral  or {}
  db.weapons.caster = db.weapons.caster or {}
  db.backup  = db.backup  or {}
  if db.skipConflicts == nil then db.skipConflicts = false end
  if db.weaponHint == nil then db.weaponHint = true end    -- small on-screen hint when the weapon doesn't match the form
  return db
end

function YB:ClassProfile()
  local _, token = UnitClass("player")
  return self.profiles[token], token
end

-- All groups that apply to this character: common first, then class
function YB:Groups()
  local list = {}
  if self.common then for _, g in ipairs(self.common.groups) do table.insert(list, g) end end
  local p = self:ClassProfile()
  if p then for _, g in ipairs(p.groups) do table.insert(list, g) end end
  return list
end

function YB:GroupEnabled(g)
  local v = self:DB().groups[g.id]
  if v == nil then return g.default ~= false end
  return v
end

---------------------------------------------------------------- spells
-- ids: list, best rank/version first. Returns localized name, id, isKnown
function YB:BestSpell(ids, fallback)
  for _, id in ipairs(ids) do
    if YB.IsKnown(id) then return YB.SpellName(id) or fallback, id, true end
  end
  return YB.SpellName(ids[1]) or fallback or "?", ids[1], false
end

-- Shapeshift bar index of any of these spell ids (changes when you learn new forms)
function YB:FormIndex(ids)
  local set = {}
  for _, id in ipairs(ids) do set[id] = true end
  for i = 1, (GetNumShapeshiftForms() or 0) do
    local sid = FormSpellID(i)
    if sid and set[sid] then return i end
  end
end

---------------------------------------------------------------- macros
local function fit(lines)
  local body = table.concat(lines, "\n")
  if #body > 255 and lines[1] == "#showtooltip" then  -- WoW macro limit: drop the tooltip line first
    table.remove(lines, 1); body = table.concat(lines, "\n")
  end
  return body
end
local function item(id) return "item:" .. id end

-- Form key: just the shift. Weapons are swapped by hand (R5 + D-pad left / right): in Forever an
-- equip in combat starts a global cooldown that blocks the shift (verified in game).
function YB:FormBody(e)
  local casts = {}
  for _, c in ipairs(e.casts) do
    table.insert(casts, (c[1] ~= "" and (c[1] .. " ") or "") .. self:BestSpell(c[2]))
  end
  return fit({ "#showtooltip", "/cast " .. table.concat(casts, "; ") })
end

-- Caster spells (heals, Moonfire). No /cancelform and no weapon swap: Forever leaves the form by itself.
function YB:CasterBody(e)
  local name = self:BestSpell(e.spell, e.label)
  local cond = ({ help = "[@mouseover,help,nodead][] ", harm = "[@mouseover,harm,nodead][] ", self = "[@player] " })[e.target or "help"]
  return fit({ "#showtooltip", "/cast " .. cond .. name })
end

-- Weapon set key: equips the saved set (main hand, then off hand if the set has one).
function YB:SetBody(which)
  local w = self:DB().weapons[which] or {}
  if not w.mh then
    return "/run print('|cff88ccffYagriver Binds:|r no " .. which .. " weapon set saved yet: /yag, Setup, Use equipped.')"
  end
  local lines = { "#showtooltip", "/equipslot 16 " .. item(w.mh) }
  if w.oh then table.insert(lines, "/equipslot 17 " .. item(w.oh)) end
  return fit(lines)
end

function YB:BuildBody(e)
  if e.type == "form" then return self:FormBody(e) end
  if e.type == "caster" then return self:CasterBody(e) end
  if e.set then return self:SetBody(e.set) end
  if type(e.body) == "function" then return e.body(self) end
  return e.body
end

-- create if missing; update only when overwrite=true (text you edited in-game is kept otherwise)
function YB:EnsureMacro(e)
  local body = self:BuildBody(e)
  if #body > 255 then return false end
  local idx = GetMacroIndexByName(e.name)
  if idx == 0 then
    local ok = pcall(CreateMacro, e.name, ICON, body, e.perChar and true or nil)
    return ok and GetMacroIndexByName(e.name) ~= 0
  elseif e.overwrite then
    pcall(EditMacro, idx, nil, nil, body)
  end
  return true
end

---------------------------------------------------------------- click binds
-- Hold actions (Dash, Enrage, Prowl) are bound as a "click" on a hidden action button. Unlike a
-- plain spell binding, such a button follows WoW's "cast on key down" setting like the action bars,
-- so the spell fires as soon as the Steam hold time is reached, not on release.
YB.clickButtons = {}
local function clickName(e) return "YBClick" .. e.label:gsub("[^%w]", "") end
function YB:ClickButton(e)
  local name = clickName(e)
  local b = self.clickButtons[name]
  if not b then
    b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")   -- runs once, on down or up according to ActionButtonUseKeyDown
    b:Hide()
    self.clickButtons[name] = b
  end
  if not YB.InCombat() then
    b:SetAttribute("type", "spell")
    b:SetAttribute("spell", (self:BestSpell(e.spell, e.label)))
  end
  return b, name
end
-- fill the hidden buttons after login (bindings are saved by WoW, the buttons are not)
function YB:PrepareClicks()
  if YB.InCombat() or not self:ClassProfile() then return end
  for _, g in ipairs(self:Groups()) do
    for _, e in ipairs(g.binds) do if e.type == "click" then self:ClickButton(e) end end
  end
end

---------------------------------------------------------------- bindings
local MACRO_TYPES = { macro = true, form = true, caster = true }

function YB:Expected(e)
  if e.type == "click" then return "CLICK " .. clickName(e) .. ":LeftButton" end
  if e.type == "spell" then return "SPELL " .. (self:BestSpell(e.spell, e.label)) end
  if e.type == "command" then return e.command end
  if MACRO_TYPES[e.type] then return "MACRO " .. e.name end
end

-- status for the Keybinds list
function YB:Status(e)
  if e.type == "info" then
    if e.key and e.key ~= "-" and not e.noLookup then return "info", GetBindingAction(e.key) or "" end
    return "info", ""
  end
  if not e.key then
    return GetMacroIndexByName(e.name) ~= 0 and "made" or "nomacro"
  end
  local cur = GetBindingAction(e.key) or ""
  if cur == "" then return "free", cur end
  if cur == self:Expected(e) then return "ours", cur end
  return "taken", cur
end

function YB:Apply()
  if YB.InCombat() then return false, "Leave combat first." end
  if not self:ClassProfile() then return false, "No profile for this class: nothing changed." end
  local db = self:DB()
  local done, skipped, failed = 0, 0, {}
  for _, g in ipairs(self:Groups()) do
    if self:GroupEnabled(g) then
      for _, e in ipairs(g.binds) do
        if e.type == "info" then
          -- nothing
        elseif not e.key then
          if self:EnsureMacro(e) then done = done + 1 else table.insert(failed, e.label) end
        else
          local st = self:Status(e)
          if st == "taken" and db.skipConflicts then
            skipped = skipped + 1
          else
            local before = GetBindingAction(e.key) or ""
            local ok
            if e.type == "spell" then
              ok = SetBindingSpell(e.key, (self:BestSpell(e.spell, e.label)))
            elseif e.type == "click" then
              local _, name = self:ClickButton(e)
              ok = SetBindingClick(e.key, name, "LeftButton")
            elseif e.type == "command" then
              ok = SetBinding(e.key, e.command)
            elseif self:EnsureMacro(e) then
              ok = SetBindingMacro(e.key, e.name)
            end
            if ok then
              if db.backup[e.key] == nil and before ~= self:Expected(e) then db.backup[e.key] = before end
              done = done + 1
            else
              table.insert(failed, e.label)
            end
          end
        end
      end
    end
  end
  SaveBindings(GetCurrentBindingSet())
  db.applied = true
  db.formCount = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
  local msg = ("Applied %d binds/macros."):format(done)
  if skipped > 0 then msg = msg .. (" Skipped %d keys already in use."):format(skipped) end
  if #failed > 0 then msg = msg .. " FAILED: " .. table.concat(failed, ", ") end
  return #failed == 0, msg
end

-- Unbind everything this addon set and restore what was there before. Macros are kept.
function YB:Remove()
  if YB.InCombat() then return false, "Leave combat first." end
  local db, n = self:DB(), 0
  for _, g in ipairs(self:Groups()) do
    for _, e in ipairs(g.binds) do
      if e.type ~= "info" and e.key then
        local st = self:Status(e)
        local prev = db.backup[e.key]
        if st == "ours" then
          -- never restore a key to a macro that no longer exists
          local m = prev and prev:match("^MACRO (.+)$")
          if m and GetMacroIndexByName(m) == 0 then prev = "" end
          if prev and prev ~= "" then SetBinding(e.key, prev) else SetBinding(e.key) end
          n = n + 1
        end
        db.backup[e.key] = nil
      end
    end
  end
  SaveBindings(GetCurrentBindingSet())
  db.applied = false
  return true, ("Removed %d binds (previous keys restored). Macros were kept."):format(n)
end

---------------------------------------------------------------- weapons
function YB:CaptureWeapons(which)
  local db = self:DB()
  local w = {}
  w.mh = GetInventoryItemID("player", 16)
  w.oh = GetInventoryItemID("player", 17)
  if YB.InCombat() then return false, "Leave combat first." end
  if not w.mh then return false, "No main-hand weapon equipped." end
  db.weapons[which] = w
  self:RefreshSet(which)
  return true, ("Saved %s set: %s."):format(which, self:WeaponText(which))
end
function YB:ClearWeapons(which)
  if YB.InCombat() then return false, "Leave combat first." end
  self:DB().weapons[which] = {}
  self:RefreshSet(which)
  return true, ("Cleared the %s set."):format(which)
end
-- rewrite the weapon key macro of this set (if it exists) and refresh the hint
function YB:RefreshSet(which)
  for _, g in ipairs(self:Groups()) do
    for _, e in ipairs(g.binds) do
      if e.set == which and GetMacroIndexByName(e.name) ~= 0 then self:EnsureMacro(e) end
    end
  end
  if YB.UpdateWeaponHint then YB.UpdateWeaponHint() end
end
function YB:WeaponText(which)
  local w = self:DB().weapons[which] or {}
  if not w.mh then return "none" end
  local function n(id) return YB.ItemName(id) or ("item " .. id) end
  return n(w.mh) .. (w.oh and (" + " .. n(w.oh)) or "")
end

---------------------------------------------------------------- cleanup of OLD macros (own button, never automatic)
-- A macro is deleted only if BOTH its name and its content match what an older version of this
-- addon created. A macro with the same name but different content is yours: it is kept.
local function starts(prefix) return function(b) return b:sub(1, #prefix) == prefix end end
local function exact(text) return function(b) return b == text end end
local function has(text) return function(b) return b:find(text, 1, true) ~= nil end end
local LEGACY = {
  ["Party Hi"] = exact("/p Hi everyone!"), ["Party Ready"] = exact("/p Ready!"),
  ["Party BRB"] = exact("/p Need a sec, brb"), ["Party OOM"] = exact("/p OOM, drinking"),
  ["Party Thanks"] = exact("/p Thanks for the group, good luck!"), ["Party Share"] = exact("/p Can you share the quest?"),
  ["Party Wait"] = exact("/p Wait for me please"), ["Party Deck"] = exact("/p Sorry, on Steam Deck, typing is slow"),
  ["Reply Hi"] = exact("/r Hi!"), ["Reply Sure"] = exact("/r Yes, sure!"), ["Reply NoThanks"] = exact("/r No thanks"),
  ["Reply Busy"] = exact("/r Sorry, busy right now"), ["Reply InviteMe"] = exact("/r Invite me, please"),
  ["Reply 1min"] = exact("/r One moment"), ["Reply Thanks"] = exact("/r Thanks!"),
  ["Reply Deck"] = exact("/r On Steam Deck, typing is slow :)"),
  ["Say Hello"] = exact("/s Hello!"), ["Say Thanks"] = exact("/s Thanks!"),
  ["Guild Hi"] = exact("/g Hi guild!"), ["Guild Night"] = exact("/g Good night all!"),
  ["Form Travel"] = has("[swimming]"), ["Rejuv Self"] = has("[@player]"), ["Hearthstone"] = has("item:6948"),
}
for _, n in ipairs({ "YB Ch s", "YB Ch p", "YB Ch g", "YB Ch r", "YB Ch ra", "YB Ch bg", "YB Ch y", "YB Ch 2",
  "YB Ph Hi", "YB Ph Thanks", "YB Ph Ready", "YB Ph BRB", "YB Ph OOM", "YB Ph Sure", "YB Ph Busy",
  "YB Ph Deck", "YB Ph GG", "YB Ph Invite", "YB Type", "YB Type Reply", "YB Chat Panel" }) do
  LEGACY[n] = starts("/run YagriverBinds_")
end

-- returns: list of macro names safe to delete, list of same-name macros that are kept
function YB:FindLegacy()
  local del, kept = {}, {}
  for name, check in pairs(LEGACY) do
    local body = YB.MacroBody(name)
    if body then
      if check(body) then table.insert(del, name) else table.insert(kept, name) end
    end
  end
  table.sort(del); table.sort(kept)
  return del, kept
end

function YB:DeleteLegacy()
  if YB.InCombat() then return false, "Leave combat first." end
  local del = self:FindLegacy()
  local n = 0
  for _, name in ipairs(del) do
    -- keys still pointing at the macro would be dead after deletion: free them
    local keys = { GetBindingKey("MACRO " .. name) }
    for _, k in ipairs(keys) do SetBinding(k) end
    if pcall(DeleteMacro, name) and GetMacroIndexByName(name) == 0 then n = n + 1 end
  end
  SaveBindings(GetCurrentBindingSet())
  return true, ("Deleted %d old macros. Nothing else was touched."):format(n)
end

---------------------------------------------------------------- right stick option
-- WoW's gamepad cursor grabs the right stick when some menus open. Toggle (instant, no Apply):
-- on  = GamePadCursorAutoEnable 0 + GamePadCursorAutoDisableSticks 2 (right stick stays camera)
-- off = previous values (or WoW defaults 1 / 2)
local function getCVar(n)
  if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(n) end
  if GetCVar then return GetCVar(n) end
end
local function setCVar(n, v)
  if C_CVar and C_CVar.SetCVar then return C_CVar.SetCVar(n, v) end
  if SetCVar then return SetCVar(n, v) end
end
YB.GetCVar, YB.SetCVar = getCVar, setCVar

---------------------------------------------------------------- device modes (account-wide)
-- Handheld / Docked: each remembers controller on/off, its UI scale and the weapon hint layout.
-- UI scale and hint apply instantly. Forever's controller mode ("Enable Gamepad UI") needs an
-- interface reload, exactly like Blizzard's own menu; its setting name is found once with Detect.
local SCALE_MIN, SCALE_MAX = 0.64, 1.15
YB.HINT_DEFAULTS = { handheld = { scale = 1.7, x = 0.5, y = 5 / 6 }, docked = { scale = 1.2, x = 0.5, y = 5 / 6 } }
function YB:Global()
  YagriverBindsDB = YagriverBindsDB or {}
  local g = YagriverBindsDB
  g.modes = g.modes or {}
  g.modes.handheld = g.modes.handheld or { pad = true,  scale = nil }
  g.modes.docked   = g.modes.docked   or { pad = false, scale = 0.75 }
  for k, d in pairs(YB.HINT_DEFAULTS) do
    local h = g.modes[k].hint or {}
    g.modes[k].hint = { scale = h.scale or d.scale, x = h.x or d.x, y = h.y or d.y }
  end
  return g
end
function YB:ModeKey() return self:Global().mode or "handheld" end
-- v5.4 could pick a non on/off value (e.g. a camera distance): drop such a result
function YB:SanitizePad()
  local g = self:Global()
  local function onoff(v) return v == "0" or v == "1" or v == "true" or v == "false" end
  if g.padCVar and not (onoff(g.padOn) and onoff(g.padOff)) then g.padCVar, g.padOn, g.padOff = nil, nil, nil end
end
function YB:Scale()
  local v = tonumber(getCVar("uiScale") or "")
  if not v and UIParent and UIParent.GetScale then v = UIParent:GetScale() end
  return v or 1
end

-- controller mode ------------------------------------------------------
-- Two ways to reach Forever's "Enable Gamepad UI":
--   padSetting = a setting of Blizzard's options panel (found by name with "Find in options")
--   padCVar    = a console setting with on/off values (found with the 2-step Detect)
local function bool(v) return v == true or v == 1 or v == "1" or v == "true" end
local function findSetting(variable)
  if not (Settings and Settings.GetSetting) then return end
  local ok, st = pcall(Settings.GetSetting, variable)
  if ok then return st end
end
function YB:PadKnown() local g = self:Global(); return (g.padSetting or g.padCVar) ~= nil end
function YB:PadOn()
  local g = self:Global()
  if g.padSetting then
    local st = findSetting(g.padSetting)
    if st and st.GetValue then return bool(st:GetValue()) end
    return nil
  end
  if not g.padCVar then return nil end
  return getCVar(g.padCVar) == g.padOn
end
-- sets Forever's gamepad UI; returns true if a reload is needed
function YB:SetPadValue(on)
  local g = self:Global()
  if not self:PadKnown() then return false end
  if self:PadOn() == on then return false end
  if on then setCVar("GamePadEnable", "1") end      -- input switch must be on for the gamepad UI
  if g.padSetting then
    local st = findSetting(g.padSetting)
    if not (st and st.SetValue) then return false end
    local cur = st:GetValue()
    local v = on
    if type(cur) == "number" then v = on and 1 or 0 elseif type(cur) == "string" then v = on and "1" or "0" end
    pcall(st.SetValue, st, v)
  else
    setCVar(g.padCVar, on and g.padOn or g.padOff)
  end
  return true
end
function YB:SetPad(on)
  if YB.InCombat() then return false, "Leave combat first." end
  local g = self:Global()
  if not self:PadKnown() then return false, "Controller setting not found yet: use 'Find in options' first." end
  g.modes[self:ModeKey()].pad = on
  if self:SetPadValue(on) then
    YB.pendingReload = true
    return true, (on and "Controller ON" or "Controller OFF") .. ": reloading the interface..."
  end
  return true, "Controller already " .. (on and "ON." or "OFF.")
end

-- "Find in options": walk Blizzard's options panel and look for the gamepad UI checkbox by its name
local NAME_WORDS = { "gamepad", "mando", "controller", "manette", "controle" }
local UI_WORDS = { "ui", "iu", "interfa", "interface" }
local function has(text, words)
  local l = text:lower()
  for _, w in ipairs(words) do if l:find(w, 1, true) then return true end end
end
local function walkCategory(cat, out, seen)
  if not cat or seen[cat] then return end
  seen[cat] = true
  local layout = SettingsPanel and SettingsPanel.GetLayout and SettingsPanel:GetLayout(cat)
  local inits = layout and layout.GetInitializers and layout:GetInitializers() or {}
  for _, init in ipairs(inits) do
    local data = (init.GetData and init:GetData()) or init.data
    local st = data and data.setting
    local name = (data and data.name) or (st and st.GetName and st:GetName())
    if st and type(name) == "string" and has(name, NAME_WORDS) and st.GetVariable and st.GetValue then
      local okv, val = pcall(st.GetValue, st)
      table.insert(out, { name = name, variable = st:GetVariable(), value = okv and val, cat = cat.GetName and cat:GetName() })
    end
  end
  if cat.GetSubcategories then
    for _, sub in ipairs(cat:GetSubcategories() or {}) do walkCategory(sub, out, seen) end
  end
end
function YB:FindPadSetting()
  if YB.InCombat() then return false, "Leave combat first." end
  if not (SettingsPanel and SettingsPanel.GetAllCategories) then
    return false, "This client has no searchable options panel. Use Detect (2 steps) instead."
  end
  local out, seen = {}, {}
  for _, cat in ipairs(SettingsPanel:GetAllCategories() or {}) do pcall(walkCategory, cat, out, seen) end
  if #out == 0 then return false, "No gamepad option found in the options panel. Use Detect (2 steps) instead." end
  local best
  for _, o in ipairs(out) do
    local isBool = type(o.value) == "boolean" or o.value == 0 or o.value == 1 or o.value == "0" or o.value == "1"
    if isBool and has(o.name, UI_WORDS) and not best then best = o end
  end
  local list = {}
  for i = 1, math.min(8, #out) do table.insert(list, ("%s [%s=%s]"):format(out[i].name, tostring(out[i].variable), tostring(out[i].value))) end
  local all = table.concat(list, "; ")
  if not best then return false, "Gamepad options found, but none looks like the on/off switch: " .. all end
  local g = self:Global()
  g.padSetting, g.padCVar, g.padOn, g.padOff, g.padSnap = best.variable, nil, nil, nil, nil
  return true, ("Found: '%s' (%s), now %s. Also seen: %s"):format(best.name, tostring(best.variable),
    bool(best.value) and "ON" or "OFF", all)
end

-- two-step detection: snapshot all settings, user flips Blizzard's option (game reloads), compare
local function allCVars()
  local list = (C_Console and C_Console.GetAllCommands and C_Console.GetAllCommands())
            or (ConsoleGetAllCommands and ConsoleGetAllCommands()) or {}
  local cvarType = (Enum and Enum.ConsoleCommandType and Enum.ConsoleCommandType.Cvar) or 0
  local t, n = {}, 0
  for _, c in ipairs(list) do
    if c.command and (c.commandType == nil or c.commandType == cvarType) then
      local v = getCVar(c.command)
      if v ~= nil then t[c.command] = v; n = n + 1 end
    end
  end
  return t, n
end
local function score(name)
  local l = name:lower()
  if l:find("gamepad") and l:find("ui") then return 3 end
  if l:find("gamepad") or l:find("controller") or l:find("console") then return 2 end
  return 1
end
function YB:DetectPad()
  if YB.InCombat() then return false, "Leave combat first." end
  local g = self:Global()
  if not g.padSnap then
    local t, n = allCVars()
    if n == 0 then return false, "This client doesn't list its settings: detection isn't possible here." end
    g.padSnap = t
    return true, ("Step 1 done (%d settings saved). Now open WoW Options > Gameplay > Gamepad, switch " ..
      "'Enable Gamepad UI' (the game reloads), then open /yag > Device and press Detect again."):format(n)
  end
  local now = allCVars()
  local changed, other = {}, {}
  local function onoff(v) return v == "0" or v == "1" or v == "true" or v == "false" end
  for k, v in pairs(now) do
    if g.padSnap[k] ~= nil and g.padSnap[k] ~= v then
      if onoff(v) and onoff(g.padSnap[k]) then table.insert(changed, k) else table.insert(other, k) end
    end
  end
  local before = g.padSnap
  g.padSnap = nil
  if #changed == 0 then
    table.sort(other)
    return false, "No on/off setting changed" .. (#other > 0 and (" (only values like " .. table.concat(other, ", ", 1, math.min(3, #other)) .. ")") or "") ..
      ". Try 'Find in options', or press Detect to start again."
  end
  table.sort(changed, function(a, b) local sa, sb = score(a), score(b); if sa ~= sb then return sa > sb end return a < b end)
  local best = changed[1]
  local a, b = before[best], now[best]
  -- the value that means "on": 1/true wins; otherwise the value it has now if the gamepad UI is visible
  local onV, offV = b, a
  if a == "1" or a == "true" then onV, offV = a, b end
  g.padCVar, g.padOn, g.padOff, g.padSetting = best, onV, offV, nil
  local list = {}
  for i = 1, math.min(6, #changed) do table.insert(list, changed[i] .. "=" .. tostring(now[changed[i]])) end
  return true, ("Found: %s (on = %s, off = %s). All changes: %s"):format(best, onV, offV, table.concat(list, ", "))
end
function YB:ForgetPad()
  local g = self:Global(); g.padCVar, g.padOn, g.padOff, g.padSnap, g.padSetting = nil, nil, nil, nil, nil
  return true, "Controller setting forgotten. Press Detect to find it again."
end

-- UI scale ---------------------------------------------------------------
function YB:SetScale(v)
  if YB.InCombat() then return false, "Leave combat first." end
  v = math.floor(math.max(SCALE_MIN, math.min(SCALE_MAX, v)) * 100 + 0.5) / 100
  setCVar("useUiScale", "1")
  setCVar("uiScale", tostring(v))
  if UIParent and UIParent.SetScale then pcall(UIParent.SetScale, UIParent, v) end
  local g = self:Global()
  if g.mode then g.modes[g.mode].scale = v end
  if YB.LayoutHint then YB.LayoutHint() end
  return true, ("UI scale %.2f"):format(v) .. (g.mode and (" (saved for " .. g.mode .. ")") or "")
end

function YB:ApplyMode(m)
  if YB.InCombat() then return false, "Leave combat first." end
  local g = self:Global()
  local mode = g.modes[m]
  if not mode then return false, "Unknown mode." end
  g.mode = m
  if mode.scale == nil then mode.scale = self:Scale() end   -- first use: keep the current size
  self:SetScale(mode.scale)
  if YB.LayoutHint then YB.LayoutHint() end
  local name = m == "handheld" and "Handheld" or "Docked"
  if m == "handheld" then setCVar("GamePadEnable", "1") end  -- undo older versions that switched it off
  if self:SetPadValue(mode.pad) then
    YB.pendingReload = true
    return true, ("%s mode: UI scale %.2f, controller %s: reloading the interface..."):format(name, mode.scale, mode.pad and "ON" or "OFF")
  end
  local pad = g.padCVar and ("controller " .. (mode.pad and "ON" or "OFF")) or "controller not set up (Detect)"
  return true, ("%s mode: UI scale %.2f, %s."):format(name, mode.scale, pad)
end

function YB:StickCameraOn()
  return getCVar("GamePadCursorAutoEnable") == "0"
end
function YB:SetStickCamera(on)
  local db = self:DB()
  if on then
    db.cvarBackup = db.cvarBackup or {
      auto = getCVar("GamePadCursorAutoEnable") or "1",
      sticks = getCVar("GamePadCursorAutoDisableSticks") or "2" }
    setCVar("GamePadCursorAutoEnable", "0")
    setCVar("GamePadCursorAutoDisableSticks", "2")
  else
    local b = db.cvarBackup or {}
    local auto = (b.auto and b.auto ~= "0") and b.auto or "1"
    setCVar("GamePadCursorAutoEnable", auto)
    setCVar("GamePadCursorAutoDisableSticks", b.sticks or "2")
    db.cvarBackup = nil
  end
  if self:StickCameraOn() == on then
    return true, on and "Right stick now always moves the camera." or "Right stick back to WoW default (cursor in menus)."
  end
  return false, "Could not change the setting (unknown CVar in this client?)."
end

---------------------------------------------------------------- reminder after learning a new form
-- Form spells get a new rank / form when learned: tell the user to Apply again.
-- The addon never re-applies by itself: it only tells you.
local ev = CreateFrame("Frame")
ev:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
local warned
ev:SetScript("OnEvent", function()
  local db = YagriverBindsCharDB
  if not db or not db.applied or not db.formCount then return end
  local n = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
  if n ~= db.formCount and warned ~= n then
    warned = n
    print("|cff88ccffYagriver Binds:|r your forms changed. Open /yag and press Apply binds to update the form macros.")
  end
end)

---------------------------------------------------------------- login
-- Never changes bindings by itself. It only fills the hidden hold buttons and, if the profile has
-- keys that are not bound yet (e.g. after an update), prints one reminder line.
local lg = CreateFrame("Frame")
lg:RegisterEvent("PLAYER_LOGIN")
lg:RegisterEvent("PLAYER_REGEN_ENABLED")
lg:SetScript("OnEvent", function(self, event)
  YB:PrepareClicks()
  YB:SanitizePad()
  if event ~= "PLAYER_LOGIN" then return end
  local db = YagriverBindsCharDB
  if not db or not db.applied or not YB:ClassProfile() then return end
  local n = 0
  for _, g in ipairs(YB:Groups()) do
    if YB:GroupEnabled(g) then
      for _, e in ipairs(g.binds) do
        if e.key and e.type ~= "info" and YB:Status(e) == "free" then n = n + 1 end
      end
    end
  end
  if n > 0 then
    print(("|cff88ccffYagriver Binds:|r %d new key(s) not bound yet. Open /yag and press Apply binds."):format(n))
  end
end)
