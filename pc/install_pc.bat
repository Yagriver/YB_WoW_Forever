@echo off
setlocal
rem Yagriver Binds PC installer. Replaces only this project's folders in WoW Forever's AddOns:
rem   YagriverBindsPC (replaced) and YBProbe (removed, the test is over).
set "ADDONS=E:\Archivos de programa\World of Warcraft\_forever_\Interface\AddOns"
if not exist "%ADDONS%\" (
  echo AddOns folder not found:
  echo   %ADDONS%
  pause
  exit /b 1
)
if exist "%ADDONS%\YagriverBindsPC\" rmdir /s /q "%ADDONS%\YagriverBindsPC"
xcopy "%~dp0YagriverBindsPC" "%ADDONS%\YagriverBindsPC\" /e /i /y /q >nul
if errorlevel 1 (
  echo FAILED to copy YagriverBindsPC. If Windows says access denied, right-click and Run as administrator.
  pause
  exit /b 1
)
echo OK: YagriverBindsPC installed.
if exist "%ADDONS%\YBProbe\" (
  rmdir /s /q "%ADDONS%\YBProbe"
  echo OK: YB Probe removed.
)
echo Start WoW, or type /reload if it is running.
pause
