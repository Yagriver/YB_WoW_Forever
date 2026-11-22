-- Yagriver Binds 6 - datos: dispositivos, hechizos, teclas de la Deck, ruedas de Easy Controller.
local _, YB = ...

-- Dispositivos y sus modos. Cada máquina guarda el suyo en sus propios archivos.
YB.DEVICES = {
  pc   = { name = "PC",         modes = { "pc", "moonlight" } },
  deck = { name = "Steam Deck", modes = { "deck", "dock" } },
}
YB.MODE_NAMES = { pc = "PC", moonlight = "Moonlight", deck = "Deck", dock = "Dock" }
-- InputDeviceInterfaceStyle: 0 teclado y ratón, 1 interfaz de mando
YB.MODE_STYLE = { pc = "0", moonlight = "1", deck = "1", dock = "0" }
YB.HINT_DEFAULTS = {
  pc = { scale = 1.0, x = 0.5, y = 5 / 6 }, moonlight = { scale = 1.3, x = 0.5, y = 5 / 6 },
  deck = { scale = 1.7, x = 0.5, y = 5 / 6 }, dock = { scale = 1.2, x = 0.5, y = 5 / 6 },
}

-- Hechizos (ids: mejor versión primero; el rango más alto que conozcas se busca por el nombre)
YB.SPELL = {
  cat = { 768 }, bear = { 9634, 5487 }, aquatic = { 1066 }, travel = { 783 },
  prowl = { 5215 }, dash = { 1850 }, enrage = { 5229 },
  innervate = { 29166 }, barkskin = { 22812 }, grasp = { 16689 }, rejuv = { 774 }, rebirth = { 20484 },
  removeCurse = { 2782 }, poison = { 2893, 8946 }, motw = { 1126 },
  regrowth = { 8936 }, healingTouch = { 5185 },
  wrath = { 5176 }, moonfire = { 8921 }, roots = { 339 }, faerieFire = { 770 }, thorns = { 467 }, moonglade = { 18960 },
}
-- Formas donde va el arma feral (Oso, Oso temible, Gato): para el aviso de arma
YB.feralForms = { 5487, 9634, 768 }

-- Teclas que la Deck 5.x guardaba y que el servidor de Blizzard copia al PC (pestaña Comprobar)
YB.deckKeys = {
  "F1", "F2", "F3", "SHIFT-F1", "SHIFT-F2", "SHIFT-F3",
  "CTRL-F1", "CTRL-F2", "CTRL-F3", "CTRL-F4", "CTRL-F5", "CTRL-F6", "CTRL-F7", "CTRL-F8", "CTRL-F9", "CTRL-F10",
  "CTRL-SHIFT-F5", "CTRL-SHIFT-F6", "CTRL-SHIFT-F11", "CTRL-SHIFT-F12",
  "CTRL-SHIFT-1", "CTRL-SHIFT-2", "CTRL-SHIFT-3", "CTRL-SHIFT-4", "CTRL-SHIFT-5",
}
-- Addons de mando que se pelearían con Easy Controller por los mismos botones
YB.controllerAddons = { "ControllerForever", "ForeverControllerTweaks", "ImprovedForever", "ConsolePort" }

-- Ruedas de Easy Controller (ver EasyController.lua). Botones por posición en la barra del mando:
-- A abajo, X izquierda, Y arriba, B derecha (los nombres de la Deck).
--   { "spell", clave de YB.SPELL } | { "macro", nombre } | { "item", id } | { "mount" }
YB.EC_WHEELS = {
  { name = "YB Emergencias", input = "A", layer = "LTRT", style = "stick", slots = {
    { "spell", "innervate" }, { "spell", "barkskin" }, { "spell", "grasp" }, { "macro", "YB Rejuv Self" },
    { "spell", "rebirth" }, { "spell", "removeCurse" }, { "spell", "poison" }, { "spell", "motw" } } },
  { name = "YB Formas", input = "X", layer = "LTRT", style = "stick", slots = {
    { "spell", "cat" }, { "macro", "YB Cat Prowl" }, { "macro", "YB Cat Dash" }, { "spell", "bear" },
    { "macro", "YB Bear Enrage" }, { "macro", "YB Travel" }, { "macro", "YB Caster Set" }, { "macro", "YB Feral Set" } } },
  { name = "YB Utilidad", input = "Y", layer = "LTRT", style = nil, slots = {
    { "item", 6948 }, { "mount" }, { "macro", "YB Ping" }, { "macro", "YB EC Frases" },
    { "macro", "YB EC Consum" }, { "macro", "YB EC Usables" }, { "macro", "YB Ajustes" }, { "macro", "YB EC Ajustes" } } },
  { name = "YB Habilidades", input = "B", layer = "LTRT", style = "stick", slots = {
    { "spell", "wrath" }, { "spell", "moonfire" }, { "spell", "roots" }, { "spell", "faerieFire" },
    { "spell", "thorns" }, { "spell", "moonglade" } } },
}
-- Modo sanador en R3: cada capa abre la rueda del grupo con ese hechizo
YB.EC_PARTY = {
  { input = "R3", layer = "",     spell = "rejuv" },
  { input = "R3", layer = "LT",   spell = "regrowth" },
  { input = "R3", layer = "RT",   spell = "healingTouch" },
  { input = "R3", layer = "LTRT", spell = "rebirth" },
}
YB.EC_TESTED = { ["1.24"] = true }   -- versiones de Easy Controller cuyo código he leído
