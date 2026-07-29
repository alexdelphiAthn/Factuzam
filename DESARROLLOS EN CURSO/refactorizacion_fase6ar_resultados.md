# Fase 6AR — resguardo de depósitos por secciones

Fecha: 29/07/2026. D4.8, octava tanda de métodos largos. Sin commit.

## Balance de código productivo

Las líneas de pruebas no forman parte del cómputo:

| Elemento | Antes | Después | Balance |
|---|---:|---:|---:|
| `ImprimirResguardoDeposito` | 339 | 23 | **-316** |
| Métodos del alcance por encima de 200 líneas | 1 | 0 | **-1** |
| `inLibGenerarTicketBD` completa | 943 | 1.020 | **+77** |

La unidad crece un 8,2 %. D4.8 reduce complejidad, no volumen: el flujo
monolítico pasa a ser una fachada y trece operaciones privadas con
nombre. Todas tienen consumidor y ninguna supera 45 líneas.

No se crea otra unidad ni se cambia la API pública. El generador privado
reutiliza una sola `TUniQuery` para las consultas secuenciales, en lugar
de mantener hasta cuatro consultas simultáneas.

## Implementación

`TGeneradorResguardoDeposito` conserva en un contexto explícito la
conexión, empresa, almacén, caja, operación, impresora, ticket y totales.
El flujo queda separado en:

- carga de empresa y fecha de operación;
- escritura de la cabecera;
- nuevos depósitos;
- entregas a cuenta;
- devolución económica;
- artículos devueltos;
- resumen, pie de caja y corte;
- impresión o previsualización y registro de la ruta PDF.

Se conservan la firma pública, los filtros por empresa/almacén/caja/
operación, el orden visual, textos, totales, formato ESC/POS, nombre del
PDF y comportamiento de `ARutasPDF` y `ASoloPDF`.

La extracción corrige dos defectos locales del código anterior:

- los artículos devueltos ahora exponen `TOTAL_PVP`, el mismo alias que
  consume el impresor;
- no queda una consulta de devoluciones sin liberar al no haber otros
  importes. La consulta única pertenece al generador y siempre se libera
  con `FreeAndNil`.

Además, una operación que solo contenga artículos devueltos ya cuenta
como movimiento y puede producir su resguardo.

## No regresión estructural

`scripts/comprobar_flujos_largos.ps1` incorpora D4.8:

- `ImprimirResguardoDeposito` no puede superar 100 líneas;
- las trece operaciones privadas deben existir una sola vez;
- cada operación debe tener consumidor;
- ninguna puede superar 100 líneas;
- se protege el orden de secciones y salida;
- se conservan tablas, alias, títulos, total, pie, preview y rutas PDF;
- el límite global baja de 43 a 42 métodos mayores de 200 líneas.

Resultado: fachada de 23 líneas, colaborador máximo de 45 y 42 métodos
productivos por encima de 200, justo el nuevo límite.

## Pruebas automáticas

La aplicación se reconstruyó con Delphi 37 en Release/Win64 y
Release/Win32 dentro de `build/validacion_d48`. Ambas plataformas
enlazaron `inLibGenerarTicketBD` sin errores.

La matriz DUnitX se recompiló en salida aislada:

| Configuración | Compilación | Pruebas | Fugas | Fallos |
|---|---:|---:|---:|---:|
| Debug / Win64 | 0 errores | 219/220 | 0 | 1 |
| Debug / Win32 | 0 errores | 219/220 | 0 | 1 |
| Release / Win64 | 0 errores | 219/220 | 0 | 1 |
| Release / Win32 | 0 errores | 219/220 | 0 | 1 |

La única roja sigue siendo ajena a D4.8:
`PruebasGestorPerfilesMto.Carga_ExponeValoresYAplicaCaption` espera
`Perfil activo`, pero recibe `Original`.

La batería general no enlaza `inLibGenerarTicketBD`; la validación
automática específica del objetivo la cubren la compilación de la
aplicación y la guarda estructural.

También pasan:

- el comprobador de flujos largos;
- ninguna línea productiva nueva por encima de 80 columnas;
- ningún `Exit`, `Continue` o `.Free` directo añadido;
- `git diff --check` limitado al alcance.

El comprobador global de dependencias queda rojo por dos aristas del
desarrollo paralelo del usuario:
`inLibCajaOpeComposicion -> inMtoCajaImpresorVenta` y
`inLibCajaOpeComposicion -> inMtoCajaGrabadorVenta`.
D4.8 no modifica ningún `uses` ni añade dependencias.

`factuzam_original.sql` sigue modificado (+95/-6) por el desarrollo
paralelo del usuario. D4.8 no lo ha tocado ni revertido.

## Validación funcional pendiente

Con una BBDD y una impresora/PDF de pruebas:

1. Probar una operación con nuevos depósitos y comparar cabecera,
   cliente, artículos, SKU y valores.
2. Probar entregas `CB` y `DE`, con y sin descripción del artículo.
3. Probar una devolución económica `DV`.
4. Probar artículos devueltos, incluida una operación que solo los tenga.
5. Combinar las cuatro secciones y cotejar todos los subtotales.
6. Comparar el total pagado contra entregado menos cambio.
7. Verificar pie de caja, firma, corte y orden exacto de las secciones.
8. Probar impresora real, previsualización, `ASoloPDF` y `ARutasPDF`.
9. Probar operación vacía, inexistente y sin movimientos.

El siguiente fascículo es **D4.9**:
`TdmConsultaOpe.DataModuleCreate`, actualmente con 333 líneas.
