@echo off
setlocal
rem Removes only the YBProbe folder from WoW Forever's AddOns.
set "ADDONS=E:\Archivos de programa\World of Warcraft\_forever_\Interface\AddOns"
if exist "%ADDONS%\YBProbe\" (
  rmdir /s /q "%ADDONS%\YBProbe"
  echo OK: YB Probe removed.
) else (
  echo YB Probe is not installed.
)
pause
