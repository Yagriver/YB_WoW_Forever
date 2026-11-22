# YagriverBinds (YB)

Controller and keybind setup for WoW: Forever, built around a Night Elf druid.
Two editions, one per machine. They never share settings.

| Edition | Folder | Machine | Modes | Status |
| --- | --- | --- | --- | --- |
| Deck | `deck/` | Steam Deck OLED | Handheld, Docked | v5.5 ready (v5.4 installed) |
| PC | `pc/` | Gaming PC (Windows) | PC (21:9 desk), Switch (Moonlight, 1080p) | Planned |

## Layout

```
deck/     Deck edition: addon (YagriverBinds), Steam Input layout, menu icons, install.sh
pc/       PC edition: addon (YagriverBindsPC) and Windows installer, from phase 1
tools/    Test tools: Lua simulator, Steam layout generator and checker
docs/     Roadmap
```

## Rules

- Each edition has its own addon name and settings file, so nothing set on one machine reaches the other.
- Neither edition saves key bindings or creates macros that Blizzard would copy to the other machine
  (from Deck 6.0 and PC 1.0 on).
- Installers delete and replace only this project's own files.

## Releases

Each version is tagged per edition (`deck-v6.0`, `pc-v1.0`) and published as a zip on the Releases page.
Download the zip of your edition on that machine.
