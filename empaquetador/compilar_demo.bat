@echo off
setlocal
pushd "%~dp0"

set "MAKENSIS=makensis.exe"
where makensis.exe >nul 2>nul
if errorlevel 1 (
  if exist "%ProgramFiles(x86)%\NSIS\makensis.exe" (
    set "MAKENSIS=%ProgramFiles(x86)%\NSIS\makensis.exe"
  )
)

if not exist "mariadb_installer.msi" (
  echo Falta mariadb_installer.msi en %CD%
  echo Copie aqui el MSI de MariaDB antes de generar el instalador final.
)

"%MAKENSIS%" factuzam_demo_autoinstalable.nsi
set "CODIGO=%ERRORLEVEL%"
popd
exit /b %CODIGO%
