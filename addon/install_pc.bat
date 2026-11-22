@echo off
setlocal
rem Instalador de Yagriver Binds 6 para el PC.
rem Solo toca carpetas de este proyecto: reemplaza YagriverBinds y quita YagriverBindsPC y YBProbe.
rem No toca Easy Controller ni ningun otro addon.
set "ADDONS=E:\Archivos de programa\World of Warcraft\_forever_\Interface\AddOns"
if not exist "%ADDONS%\" (
  echo No encuentro la carpeta de AddOns:
  echo   %ADDONS%
  pause
  exit /b 1
)
if exist "%ADDONS%\YagriverBinds\" rmdir /s /q "%ADDONS%\YagriverBinds"
xcopy "%~dp0YagriverBinds" "%ADDONS%\YagriverBinds\" /e /i /y /q >nul
if errorlevel 1 (
  echo FALLO al copiar YagriverBinds. Si Windows dice acceso denegado: clic derecho, Ejecutar como administrador.
  pause
  exit /b 1
)
echo OK: YagriverBinds 6 instalado.
for %%D in (YagriverBindsPC YBProbe) do (
  if exist "%ADDONS%\%%D\" (
    rmdir /s /q "%ADDONS%\%%D"
    echo OK: %%D quitado.
  )
)
if not exist "%ADDONS%\EasyController\" echo AVISO: falta Easy Controller en AddOns. Instalalo (CurseForge o su zip).
echo Arranca WoW, o escribe /reload si ya esta abierto.
pause
