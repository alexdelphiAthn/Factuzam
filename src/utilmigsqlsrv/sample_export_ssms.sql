/* ============================================================================
   Script SSMS para extraer DATOS DE EJEMPLO de las tablas maestras de
   "Herreras" que migra el FactuzamMigrator.

   Cómo usarlo:
     1. Abre SQL Server Management Studio conectado a la base "Herreras".
     2. Resultados -> "Resultados a archivo" (Ctrl+Shift+F) o copia y pega.
        Si quieres CSV legible: abajo en la barra de estado, click derecho
        en la pestaña -> "Guardar resultados como..." -> .csv (UTF-8).
     3. Ejecuta este script (F5). Saldra un bloque por tabla con TOP 20
        filas. Manda esos resultados al hilo / al canal.
     4. Si una tabla es pequena (octipefe, ocgrpiva, etc.) tira "SELECT *"
        sin TOP para que llegue completa.

   Si SSMS te trunca columnas largas (Observacion, IBAN...), ejecuta primero:
        Herramientas -> Opciones -> Resultados de consulta -> SQL Server ->
        Resultados a texto -> "Numero maximo de caracteres por columna"
        subelo a 8000 o mas.
   ============================================================================ */

USE Herreras;
GO

PRINT '== Empresas (ocemp) ==';
SELECT TOP 20 *
FROM dbo.ocemp
ORDER BY Empresa;

PRINT '== Almacenes (ocalm) ==';
SELECT TOP 20 *
FROM dbo.ocalm
ORDER BY Empresa, Almacen;

PRINT '== Clientes (occli) ==';
SELECT TOP 20
       Cliente, RazonSocial, Nombre, NIF, Direccion1, Direccion2,
       CodPostal, Poblacion, Provincia, Pais,
       Telefono1, TelefonoMovil, Email,
       PersonaContacto, ReferenciaProveedor, IBAN,
       Estado, FormaPago, TipoEfecto, Tarifa,
       CAST(Observacion AS varchar(4000)) AS Observacion
FROM dbo.occli
ORDER BY Cliente;

PRINT '== Articulos (ocartp) ==';
SELECT TOP 20
       Articulo, DescripcionCorta, DescripcionLarga, Familia,
       TipoIva, Estado, Tipo, HayColores, HayTallas, NroTallaje,
       Marca, Proveedor
FROM dbo.ocartp
ORDER BY Articulo;

PRINT '== Tipos de IVA / historico (octipiva) ==';
SELECT TipoIva, Fecha, PorIVA, PorRe, Descripcion
FROM dbo.octipiva
ORDER BY TipoIva, Fecha DESC;

PRINT '== Grupos de IVA (ocgrpiva) ==';
SELECT *
FROM dbo.ocgrpiva
ORDER BY Grupo;

PRINT '== Tipos de IVA cabecera (octiposiva) ==';
SELECT *
FROM dbo.octiposiva
ORDER BY TipoIva;

PRINT '== Tipos de Efecto (octipefe) -> formas de pago ==';
SELECT *
FROM dbo.octipefe
ORDER BY TipoEfecto;

PRINT '== Tipos de Transaccion (octiptra) ==';
SELECT *
FROM dbo.octiptra
ORDER BY 1;

PRINT '== Divisas (ocdiv) ==';
SELECT *
FROM dbo.ocdiv;

PRINT '== Tallas/Colores (ocarttal, occolor) -- pequenas, sin TOP ==';
SELECT * FROM dbo.ocarttal;
SELECT * FROM dbo.occolor;

PRINT '== Conteo de filas por tabla maestra ==';
SELECT 'ocemp'      AS Tabla, COUNT(*) AS Filas FROM dbo.ocemp
UNION ALL SELECT 'ocalm',     COUNT(*) FROM dbo.ocalm
UNION ALL SELECT 'occli',     COUNT(*) FROM dbo.occli
UNION ALL SELECT 'ocartp',    COUNT(*) FROM dbo.ocartp
UNION ALL SELECT 'octipiva',  COUNT(*) FROM dbo.octipiva
UNION ALL SELECT 'ocgrpiva',  COUNT(*) FROM dbo.ocgrpiva
UNION ALL SELECT 'octiposiva',COUNT(*) FROM dbo.octiposiva
UNION ALL SELECT 'octipefe',  COUNT(*) FROM dbo.octipefe
UNION ALL SELECT 'octiptra',  COUNT(*) FROM dbo.octiptra
UNION ALL SELECT 'ocdiv',     COUNT(*) FROM dbo.ocdiv
ORDER BY Tabla;
GO
