/* ============================================================================
   Script SSMS para extraer DATOS DE EJEMPLO de las tablas que migran
   FAMILIAS y CARACTERISTICAS de articulo:
     - Familias        : dbo.ocartniv
     - Catalogo color  : dbo.occolor
     - Catalogo tallas : dbo.ocarttal (no hay maestra, sale via DISTINCT)
     - Asignaciones    : dbo.ocartcol (articulo-color), dbo.ocarttal
     - Como cuadra la familia con el articulo: dbo.ocartp.Familia

   Uso (igual que el anterior):
     1. Abrelo en SSMS conectado a "Herreras".
     2. Resultados -> "Resultados a archivo" (Ctrl+Shift+F) o ejecuta y
        guarda cada bloque como CSV (UTF-8, separador ;) en una carpeta
        nueva tipo src/utilmigsqlsrv/resultados/ del repo.
     3. Si SSMS te corta texto largo:
        Herramientas -> Opciones -> Resultados de consulta -> SQL Server
        -> Resultados a texto -> sube "Numero maximo de caracteres por
        columna" a 8000 o mas.
   ============================================================================ */

USE Herreras;
GO

PRINT '== Familias (ocartniv) -- pequena, sin TOP ==';
SELECT *
FROM dbo.ocartniv
ORDER BY Nivel;

PRINT '== ocartp.Familia: como esta guardado el codigo de familia ==';
-- Esto es CRITICO: necesito saber si Familia es un int corto ("1", "2")
-- o un texto/codigo distinto, para ajustar el padding de
-- inLibMigFamilias.CodigoFamilia.
SELECT TOP 30 Articulo, Familia, DescripcionCorta, DescripcionLarga
FROM dbo.ocartp
WHERE LTRIM(RTRIM(ISNULL(Familia, ''))) <> ''
ORDER BY Articulo;

PRINT '== Conteo de articulos por familia (top 20) ==';
SELECT TOP 20 Familia, COUNT(*) AS NumArticulos
FROM dbo.ocartp
GROUP BY Familia
ORDER BY NumArticulos DESC;

PRINT '== Catalogo colores (occolor) -- los 46 que ya vimos en CSV ==';
-- Ya tengo el contenido en resultados/colores.csv, lo dejo por si hay
-- diferencias o filtros que aplicar. Si ya esta no hace falta re-ejecutar.
SELECT *
FROM dbo.occolor
ORDER BY ColorBasico;

PRINT '== Articulos-Colores (ocartcol top 30 con join a occolor) ==';
SELECT TOP 30
       ac.Articulo, ac.Color, ac.ColorBasico,
       ac.Descripcion        AS DescAC,
       c.Descripcion         AS DescColorBasico
FROM dbo.ocartcol ac
LEFT JOIN dbo.occolor c ON c.ColorBasico = ac.ColorBasico
ORDER BY ac.Articulo, ac.Color;

PRINT '== ocartcol: cuantas asignaciones color por articulo en total ==';
SELECT COUNT(*) AS TotalAsignacionesColor FROM dbo.ocartcol;

PRINT '== ocartcol: cuantos articulos distintos con colores ==';
SELECT COUNT(DISTINCT Articulo) AS ArticulosConColor FROM dbo.ocartcol;

PRINT '== Tallas: cuantas tallas unicas hay en todo el catalogo ==';
SELECT COUNT(DISTINCT Talla) AS TallasUnicas
FROM dbo.ocarttal
WHERE LTRIM(RTRIM(Talla)) <> '';

PRINT '== Top 50 tallas mas usadas ==';
SELECT TOP 50 Talla, COUNT(*) AS NumArticulos
FROM dbo.ocarttal
WHERE LTRIM(RTRIM(Talla)) <> ''
GROUP BY Talla
ORDER BY NumArticulos DESC, Talla;

PRINT '== Tallas con caracteres raros o casos limite (espacios, acentos) ==';
-- Ayuda a calibrar NormalizarCodigoAtb. Si aparecen tallas con / espacio
-- # o numeros con coma decimal, ajustaremos el normalizador.
SELECT DISTINCT Talla
FROM dbo.ocarttal
WHERE Talla LIKE '%[^A-Za-z0-9]%'
  AND LTRIM(RTRIM(Talla)) <> ''
ORDER BY Talla;

PRINT '== Articulos-Tallas: muestra de 30 filas ==';
SELECT TOP 30 Articulo, Talla, Orden, Serie
FROM dbo.ocarttal
WHERE LTRIM(RTRIM(Articulo)) <> ''
  AND LTRIM(RTRIM(Talla))    <> ''
ORDER BY Articulo, Orden, Talla;

PRINT '== Conteo total de las tablas tocadas en este pase ==';
SELECT 'ocartniv'   AS Tabla, COUNT(*) AS Filas FROM dbo.ocartniv
UNION ALL SELECT 'occolor',   COUNT(*) FROM dbo.occolor
UNION ALL SELECT 'ocartcol',  COUNT(*) FROM dbo.ocartcol
UNION ALL SELECT 'ocarttal',  COUNT(*) FROM dbo.ocarttal
UNION ALL SELECT 'ocartp',    COUNT(*) FROM dbo.ocartp
ORDER BY Tabla;
GO
