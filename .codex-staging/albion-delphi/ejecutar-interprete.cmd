@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0bin\InterpretarPedidoAlbion.exe" (
  echo ERROR: no existe bin\InterpretarPedidoAlbion.exe
  echo Compila InterpretarPedidoAlbion.dpr o usa el ejecutable entregado.
  pause
  exit /b 1
)
"%~dp0bin\InterpretarPedidoAlbion.exe" %*
set "ALBION_EXIT_CODE=%ERRORLEVEL%"
echo.
if not "%ALBION_EXIT_CODE%"=="0" echo El interprete termino con error %ALBION_EXIT_CODE%.
pause
exit /b %ALBION_EXIT_CODE%

