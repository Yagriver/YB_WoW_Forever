-- Binds shared by every class. Edit freely (see README.txt).
local _, YB = ...

-- Utility panel content. Channels: { "slash command", "button text" }.
YB.chatChannels = {
  { "s", "Say" }, { "p", "Party" }, { "g", "Guild" }, { "r", "Reply" },
  { "ra", "Raid" }, { "bg", "BG" }, { "y", "Yell" }, { "2", "Trade" },
}
YB.defaultChannel = "p"
-- Default phrases. One real macro per phrase ("YB Say 1" ...). To change a phrase in game: /macro,
-- edit the text after the channel (keep the "/p " part). Apply never overwrites your text.
YB.chatPhrases = {
  "Hi!", "Thanks!", "Ready!", "brb",
  "OOM, drinking", "Yes, sure!", "Sorry, busy right now", "Invite me, please",
  "Thanks for the group, good luck!", "Can you share the quest?", "Wait for me please", "On Steam Deck, typing is slow :)",
}
function YB.SayName(i) return "YB Say " .. i end

-- Profession buttons shown in the panel when known. { "fallback name", spell ids (any rank) }
YB.professions = {
  { "First Aid", 3273, 3274, 7924, 10846 }, { "Cooking", 2550, 3102, 3413, 18260 },
  { "Campfire", 818 }, { "Fishing", 7620, 7731, 7732, 18248 },
  { "Alchemy", 2259, 3101, 3464, 11611 }, { "Blacksmithing", 2018, 3100, 3538, 9785 },
  { "Enchanting", 7411, 7412, 7413, 13920 }, { "Disenchant", 13262 },
  { "Engineering", 4036, 4037, 4038, 12656 }, { "Leatherworking", 2108, 3104, 3811, 10662 },
  { "Tailoring", 3908, 3909, 3910, 12180 }, { "Smelting", 2656 },
  { "Find Herbs", 2383 }, { "Find Minerals", 2580 },
}

local chatBinds = {
  { type = "macro", key = "CTRL-SHIFT-F12", name = "YB Settings", label = "Open / close this settings window",
    body = "/yag", deck = "R5 + L pad: YB menu", overwrite = true },
  { type = "macro", key = "CTRL-SHIFT-F11", name = "YB Panel", label = "Open / close the YB panel (chat + professions)",
    body = "/yagpanel", deck = "R5 + L pad: Panel", overwrite = true },
}
for i, text in ipairs(YB.chatPhrases) do
  table.insert(chatBinds, { type = "macro", name = YB.SayName(i), label = "Phrase " .. i .. ": " .. text,
    body = "/" .. YB.defaultChannel .. " " .. text, deck = "YB panel button" })
end
table.insert(chatBinds, { type = "info", key = "ENTER", label = "Type freely (chat + Steam keyboard)", deck = "R5 + D-pad down" })

YB:RegisterCommon({
  groups = {
    { id = "chat", label = "YB windows + chat phrases", binds = chatBinds },
    { id = "party", label = "Party targets (hold L2 + L pad)", binds = {
      { type = "command", key = "CTRL-SHIFT-1", command = "TARGETSELF",         label = "Target: me",      deck = "L2 + L pad: Me" },
      { type = "command", key = "CTRL-SHIFT-2", command = "TARGETPARTYMEMBER1", label = "Target: party 1", deck = "L2 + L pad: P1" },
      { type = "command", key = "CTRL-SHIFT-3", command = "TARGETPARTYMEMBER2", label = "Target: party 2", deck = "L2 + L pad: P2" },
      { type = "command", key = "CTRL-SHIFT-4", command = "TARGETPARTYMEMBER3", label = "Target: party 3", deck = "L2 + L pad: P3" },
      { type = "command", key = "CTRL-SHIFT-5", command = "TARGETPARTYMEMBER4", label = "Target: party 4", deck = "L2 + L pad: P4" },
    }},
    { id = "utility", label = "Hearthstone + menu keys", binds = {
      { type = "macro", key = "CTRL-F10", name = "YB Hearth", label = "Hearthstone",
        body = "#showtooltip\n/use item:6948", deck = "R5 + D-pad up", overwrite = true },
      { type = "info", key = "CTRL-F9", label = "Mount (drag your mount to a bar, bind it with Quick Keybind)", deck = "R5 + L pad: Mount" },
      { type = "info", key = "M",       label = "World map (game default key)",   deck = "R5 + L pad: Map" },
      { type = "info", key = "SHIFT-B", label = "All bags (game default key)",    deck = "R5 + L pad: Bags" },
      { type = "info", key = "J",       label = "Character (your key)",           deck = "R5 + L pad: Char" },
      { type = "info", key = "P",       label = "Spellbook (game default key)",   deck = "R5 + L pad: Spells" },
      { type = "info", key = "N",       label = "Talents (game default key)",     deck = "R5 + L pad: Talents" },
      { type = "info", key = "O",       label = "Social (game default key)",      deck = "R5 + L pad: Social" },
      { type = "info", key = "K",       label = "Profession book (game default key)", deck = "R5 + L pad: Prof." },
      { type = "info", key = "-", label = "Town set: L4 hold = Ctrl, L5 hold = Shift", deck = "Hold Select (toggle)" },
    }},
  },
})
