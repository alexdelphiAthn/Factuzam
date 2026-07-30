@echo off
setlocal
set "RAIZ=C:\DISCO_DURO\proyectos\Factuzam"
set "LOG=%~dp0resultado_build_release_win64.txt"
pwsh -NoProfile -ExecutionPolicy Bypass ^
  -File "%RAIZ%\scripts\comprobar_tamano_clases.ps1" > "%LOG%" 2>&1
if errorlevel 1 goto fin
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild "%RAIZ%\fzam.dproj" /t:Build /p:Config=Release ^
  /p:Platform=Win64 /nologo /verbosity:minimal >> "%LOG%" 2>&1
:fin
set "CODIGO=%ERRORLEVEL%"
echo EXITCODE=%CODIGO%>> "%LOG%"
exit /b %CODIGO%
