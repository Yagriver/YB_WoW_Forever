YB Probe 1.0 - one-off test for the YagriverBinds PC edition
=============================================================

It only reads. During stages 2-4 it adds temporary bindings on L, R, L3 and R3
(removed when the stage ends or on /reload), and stage 4 changes one gamepad
setting that it puts back afterwards. Delete it when we are done.

Install
  1. Double-click install_probe.bat (copies YBProbe into
     E:\Archivos de programa\World of Warcraft\_forever_\Interface\AddOns).
  2. In the AddOns list at character select: tick "YB Probe" and UNTICK any other
     controller addon (Easy Controller, Controller Forever, ...) for this test.

At the desk (keyboard and mouse)
  1. The window opens by itself after login: Snapshot  ->  Save (reload).

On the Switch (Moonlight, gamepad UI on), in a city, out of combat
  1. The probe window opens by itself after login. Tap its buttons with the
     touchscreen (closed it? log out and back in, or /ybprobe).
  2. Snapshot.
  3. 1 Watch, 2 Soft, 3 Full, 4 RT modifier: in each stage press, slowly, one at a time:
       ZR+R (ZR first), R+ZR (R first), ZL+R, ZR+L, ZL+L, R3, ZL+R3, ZR+R3, L3, + and -.
     In stage 1, also note what the game does for ZR+R and ZL+L.
     In stage 3, also hold ZR+R while pushing the right stick up, then let go.
     Each stage stops by itself after 45 seconds.
  4. Chat test (whispers yourself one line).
  5. Save (reload).

Send me
  E:\Archivos de programa\World of Warcraft\_forever_\WTF\Account\<YOUR ACCOUNT>\SavedVariables\YBProbe.lua
  plus one line on what the game did for ZR+R and ZL+L in stage 1.

Remove
  Double-click uninstall_probe.bat.
