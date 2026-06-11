@echo off
chcp 65001 >nul
rem ============================================================
rem  Genera la version HTML del manual a partir de los .md
rem  Doble clic para ejecutar. Vuelca el resultado en html\
rem ============================================================
cd /d "%~dp0"

rem Busca un interprete de Python disponible (python o py)
where python >nul 2>nul
if %errorlevel%==0 (
    python generar_html.py
    goto fin
)
where py >nul 2>nul
if %errorlevel%==0 (
    py generar_html.py
    goto fin
)

echo.
echo  [ERROR] No se ha encontrado Python en este equipo.
echo  Instala Python 3 desde https://www.python.org/downloads/
echo  (marca la opcion "Add Python to PATH" durante la instalacion)
echo  y vuelve a ejecutar este fichero.
echo.

:fin
echo.
echo  Manual HTML actualizado en la carpeta "html".
echo  Abre html\index.html en el navegador para verlo.
echo.
pause
