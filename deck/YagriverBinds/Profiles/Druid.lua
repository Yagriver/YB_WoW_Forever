-- Druid profile. Spell ids: best rank / version first, base version last.
-- Emergency and utility spells are plain spell binds: they use your current target (L1 = friends).
local _, YB = ...

local function spell(key, ids, label, deck)
  return { type = "spell", key = key, spell = ids, label = label, deck = deck }
end

YB:RegisterProfile("DRUID", {
  name = "Druid",
  weapons = true,  -- shows the feral / caster weapon section
  feralForms = { 5487, 9634, 768 },   -- forms where the feral set belongs (Bear, Dire Bear, Cat)
  groups = {
    { id = "forms", label = "Forms (L4 / L5 / R4 tap)", binds = {
      { type = "form", key = "F3", name = "YB Cat",    form = "cat",    label = "Cat Form",
        casts = { { "", { 768 } } }, deck = "Combat R4 tap", perChar = true, overwrite = true },
      { type = "form", key = "F2", name = "YB Bear",   form = "bear",   label = "Bear / Dire Bear Form",
        casts = { { "", { 9634, 5487 } } }, deck = "Combat L5 tap", perChar = true, overwrite = true },
      { type = "form", key = "F1", name = "YB Travel", form = "travel", label = "Travel / Aquatic (in water)",
        casts = { { "[swimming]", { 1066 } }, { "", { 783 } } }, deck = "Combat L4 tap", perChar = true, overwrite = true },
    }},
    { id = "holds", label = "Form extras (L4 / L5 / R4 hold)", binds = {
      { type = "click", key = "SHIFT-F3", spell = { 5215 }, label = "Prowl",  deck = "Combat R4 hold" },
      { type = "click", key = "SHIFT-F2", spell = { 5229 }, label = "Enrage", deck = "Combat L5 hold" },
      { type = "click", key = "SHIFT-F1", spell = { 1850 }, label = "Dash",   deck = "Combat L4 hold" },
    }},
    { id = "weapons", label = "Weapon sets (R5 + D-pad left / right)", binds = {
      { type = "macro", key = "CTRL-SHIFT-F5", name = "YB Caster Set", set = "caster", label = "Equip caster / healing set",
        deck = "R5 + D-pad left", perChar = true, overwrite = true },
      { type = "macro", key = "CTRL-SHIFT-F6", name = "YB Feral Set", set = "feral", label = "Equip feral set",
        deck = "R5 + D-pad right", perChar = true, overwrite = true },
    }},
    { id = "emergency", label = "Emergencies (R5 + right pad)", binds = {
      spell("CTRL-F1", { 29166 }, "Innervate",      "Combat R5 + R pad 1"),
      spell("CTRL-F2", { 22812 }, "Barkskin",       "Combat R5 + R pad 2"),
      spell("CTRL-F3", { 16689 }, "Nature's Grasp", "Combat R5 + R pad 3"),
      { type = "caster", key = "CTRL-F4", name = "YB Rejuv Self", label = "Rejuvenation on yourself",
        spell = { 774 }, target = "self", deck = "Combat R5 + R pad 4", perChar = true, overwrite = true },
    }},
    { id = "utility_druid", label = "Druid utilities (R5 + A/B/X/Y)", binds = {
      spell("CTRL-F5", { 20484 }, "Rebirth",          "Combat R5 + A"),
      spell("CTRL-F6", { 2782 },  "Remove Curse",     "Combat R5 + B"),
      spell("CTRL-F7", { 2893, 8946 }, "Abolish Poison / Cure Poison", "Combat R5 + X"),
      spell("CTRL-F8", { 1126 },  "Mark of the Wild", "Combat R5 + Y"),
    }},
    { id = "caster_macros", label = "Heal + Moonfire macros (on bars)", binds = {
      { type = "caster", name = "YB HealTouch", label = "Healing Touch (mouseover)", spell = { 5185 },
        target = "help", deck = "Your bars (e.g. L2 + button)", perChar = true, overwrite = true },
      { type = "caster", name = "YB Regrowth",  label = "Regrowth (mouseover)",      spell = { 8936 },
        target = "help", deck = "Your bars (e.g. L2 + button)", perChar = true, overwrite = true },
      { type = "caster", name = "YB Rejuv",     label = "Rejuvenation (mouseover)",  spell = { 774 },
        target = "help", deck = "Your bars (e.g. L2 + button)", perChar = true, overwrite = true },
      { type = "caster", name = "YB Moonfire",  label = "Moonfire (mouseover enemy)", spell = { 8921 },
        target = "harm", deck = "Your bars", perChar = true, overwrite = true },
    }},
  },
})
