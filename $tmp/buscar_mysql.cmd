@echo off
set "OUT=%~dp0salida_sql.txt"
where mysql > "%OUT%" 2>&1
dir /b "C:\Program Files\MariaDB*" >> "%OUT%" 2>&1
dir /b "C:\Program Files\MariaDB*\bin\mysql.exe" >> "%OUT%" 2>&1
