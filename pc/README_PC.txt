Yagriver Binds PC 1.0
=====================

The PC edition: two modes on one PC, each with its own settings.
  PC      desk, 21:9 3440x1440, keyboard and mouse
  Switch  Moonlight stream, 16:9 1920x1080, gamepad UI
It never saves key bindings and never creates macros, so nothing it does reaches the Deck.

Install
  Double-click install_pc.bat. It replaces only YagriverBindsPC and removes YBProbe.

First time, at the desk
  1. Open it: minimap paw, /ybpc, or /yag (Ctrl+Shift+F12 also works: that key came from the Deck).
  2. Setup > Weapon sets: wear each set and press "Use equipped".
  3. Setup > Keys: "Set key" for Caster set, Feral set and the YB panel, then press the key you want
     (Shift / Ctrl / Alt allowed, Esc cancels). It tells you if the key had another job.
  4. Device: PC should be active (Auto). Adjust the UI scale if you like.
  5. Optional: Device > Layout: pick the Edit Mode layout for the desk.

First time, on the Switch
  1. Start the stream with WoW open: a banner switches to Switch mode after 6 s ("Stay" cancels).
     Starting WoW while streaming also works: Auto picks Switch at login.
  2. Tap the minimap paw with the touchscreen.
  3. Device: UI scale for 1080p, hint size / Move, "Right stick always moves the camera" if you want it.
  4. Edit Mode: make a layout for the Switch (copy "SteamDeck at dock 1080", rename it), then pick it in
     Device > Layout. Right now the Switch borrows the Deck's docked layout.
  5. Device > Stick check (10 s): push the RIGHT stick all around, then the LEFT. The result is saved
     for the wheels.

Checklist
  [ ] Desk: PC mode at login, keyboard UI, your scale, weapon keys work, hint shows your key.
  [ ] Switch: Switch mode by itself (banner or login), gamepad UI, its own scale, hint says "YB panel".
  [ ] Back at the desk: PC scale and keyboard UI come back.
  [ ] YB panel: a phrase reaches the chat (try Say), channel buttons work, Caster / Feral set buttons equip.
  [ ] Stick check done on the Switch.

Send me afterwards
  E:\Archivos de programa\World of Warcraft\_forever_\WTF\Account\<ACCOUNT>\SavedVariables\YagriverBindsPC.lua

Good to know
  * The 25 Deck keys and 25 YB macros on this PC came from the Deck through Blizzard's server.
    Leave them for now: deleting them here would delete them on the Deck too. Deck 6.0 cleans them up.
  * Blizzard may also copy the interface style or UI scale to the Deck. If the Deck ever opens in
    keyboard UI, switch "Enable Gamepad UI" back once there; Deck 6.0 will do it by itself.
  * Edit Mode layout switching is off until you pick a layout.
