# Informe de pruebas - Conexión global Fase XI-C

Fecha: 25/07/2026

## Resultado

XI-C queda aplicada. Ninguna unidad `inLib*.pas` consume ya la conexión
global `oConn`: las funciones reciben `AConexion`, las clases con estado
la almacenan y la raíz de composición configura los servicios
persistentes.

Al cerrar XI-C, antes de retirar la compatibilidad en XI-D, el proyecto
había bajado de 169 a **62 apariciones en 62 líneas de 8 unidades**.

## Contratos migrados

- Parámetros de aplicación y caja, unidades de medida y fotografías:
  `AsignarConexion`.
- Cachés de configuración de campos e informes-guías: conexión en el
  constructor.
- Contadores de línea: `AConexion` explícita y transacciones sobre la
  misma conexión del llamante.
- Tickets, correo, documentos, inventario en nube, búsquedas, series,
  facturación, exportación y paletas: conexión como primer parámetro.
- Compras y materialización: conexión publicada por su módulo de datos.

La raíz asigna `ConexionPrincipal` a los cuatro servicios persistentes
inmediatamente después de crear `TServicioConexionesUniDAC`.

## Prueba estructural

Script: `PruebasConexionGlobalFase11C.ps1`

Resultado final: **15 comprobaciones, 15 correctas y 0 fallos**.

La barrera sigue ejecutándose tras XI-D y comprueba:

1. ausencia de `oConn` en todas las librerías;
2. inyección de los cuatro servicios persistentes;
3. construcción explícita de las dos cachés;
4. conservación de la conexión transaccional en contadores;
5. contratos explícitos de compras, tickets, tablas, búsquedas,
   facturación y paleta;
6. límite de 80 columnas;
7. conservación de los DFM;
8. integridad de `factuzam_original.sql`.

## Compilación

La fase compiló correctamente con Delphi 37.0:

| Configuración | Plataforma | Resultado |
| --- | --- | --- |
| Debug | Win64 | Correcta, 0 errores |
| Release | Win32 | Correcta, 0 errores |
| Release | Win64 | Correcta, 0 errores |

La validación definitiva se conserva en el informe y el log de XI-D.

## Compatibilidad

- Se conservan los **253** enlaces persistentes
  `Connection = dmConn.conUni` de **52 DFM**.
- No hay cambios de esquema ni scripts SQL.
- `factuzam_original.sql` permanece intacto.
- No se ha realizado ningún commit ni push.
