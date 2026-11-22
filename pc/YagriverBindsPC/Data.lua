-- Yagriver Binds PC - data shared with the Deck edition (same phrases, channels, professions, spells).
local _, YB = ...

YB.chatChannels = {
  { "s", "Say" }, { "p", "Party" }, { "g", "Guild" }, { "r", "Reply" },
  { "ra", "Raid" }, { "bg", "BG" }, { "y", "Yell" }, { "2", "Trade" },
}
YB.defaultChannel = "p"
YB.chatPhrases = {
  "Hi!", "Thanks!", "Ready!", "brb",
  "OOM, drinking", "Yes, sure!", "Sorry, busy right now", "Invite me, please",
  "Thanks for the group, good luck!", "Can you share the quest?", "Wait for me please", "Playing on a controller, typing is slow :)",
}

-- { "fallback name", spell ids (any rank) }
YB.professions = {
  { "First Aid", 3273, 3274, 7924, 10846 }, { "Cooking", 2550, 3102, 3413, 18260 },
  { "Campfire", 818 }, { "Fishing", 7620, 7731, 7732, 18248 },
  { "Alchemy", 2259, 3101, 3464, 11611 }, { "Blacksmithing", 2018, 3100, 3538, 9785 },
  { "Enchanting", 7411, 7412, 7413, 13920 }, { "Disenchant", 13262 },
  { "Engineering", 4036, 4037, 4038, 12656 }, { "Leatherworking", 2108, 3104, 3811, 10662 },
  { "Tailoring", 3908, 3909, 3910, 12180 }, { "Smelting", 2656 },
  { "Find Herbs", 2383 }, { "Find Minerals", 2580 },
}

-- Forms where the feral weapon belongs (Bear, Dire Bear, Cat): used by the weapon hint
YB.feralForms = { 5487, 9634, 768 }

-- The Deck edition's keys. Blizzard's server copies them to this PC; the Check tab lists them.
YB.deckKeys = {
  "F1", "F2", "F3", "SHIFT-F1", "SHIFT-F2", "SHIFT-F3",
  "CTRL-F1", "CTRL-F2", "CTRL-F3", "CTRL-F4", "CTRL-F5", "CTRL-F6", "CTRL-F7", "CTRL-F8", "CTRL-F9", "CTRL-F10",
  "CTRL-SHIFT-F5", "CTRL-SHIFT-F6", "CTRL-SHIFT-F11", "CTRL-SHIFT-F12",
  "CTRL-SHIFT-1", "CTRL-SHIFT-2", "CTRL-SHIFT-3", "CTRL-SHIFT-4", "CTRL-SHIFT-5",
}

-- Controller addons that would fight over the same buttons once wheels arrive
YB.controllerAddons = { "EasyController", "ControllerForever", "ForeverControllerTweaks", "ImprovedForever", "ConsolePort" }
