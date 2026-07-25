@echo off
set "MYSQL=C:\Program Files\MariaDB 12.3\bin\mysql.exe"
if not exist "%MYSQL%" set "MYSQL=C:\Program Files\MariaDB 12.1\bin\mysql.exe"
"%MYSQL%" -h 127.0.0.1 -P 3306 -u root -pZamora2023 -D Factuzam --table < "%~dp0consulta.sql" > "%~dp0salida_sql.txt" 2>&1
