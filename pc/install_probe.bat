@echo off
setlocal
rem YB Probe installer: copies the YBProbe folder into WoW Forever's AddOns.
rem It deletes and replaces only the YBProbe folder.
set "ADDONS=E:\Archivos de programa\World of Warcraft\_forever_\Interface\AddOns"
if not exist "%ADDONS%\" (
  echo AddOns folder not found:
  echo   %ADDONS%
  echo Copy the YBProbe folder there by hand.
  pause
  exit /b 1
)
if exist "%ADDONS%\YBProbe\" rmdir /s /q "%ADDONS%\YBProbe"
xcopy "%~dp0YBProbe" "%ADDONS%\YBProbe\" /e /i /y /q >nul
if errorlevel 1 (
  echo FAILED to copy. If Windows says access denied, right-click this file and Run as administrator.
  pause
  exit /b 1
)
echo OK: YB Probe installed in
echo   %ADDONS%\YBProbe
echo Start WoW (or type /reload), make sure "YB Probe" is ticked in the AddOns list, then type /ybprobe.
pause
