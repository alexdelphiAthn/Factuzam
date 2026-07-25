# Plan de pruebas — puntos 5 a 8 de la Fase XII-D

Fecha: 25/07/2026

Los puntos 1 a 4 están ejecutados y documentados en
`INFORME_PRUEBAS.md`. Los puntos 5 a 8 escriben documentos
persistentes, así que antes de tocarlos se fija aquí el entorno, los
datos de partida, el resultado esperado de cada paso y la limpieza.

## Conclusión previa: no ejecutar sobre `Factuzam`

La instalación tiene `appVerifactuActivo = True` y
`appVerifactuModo = VERIFACTU`. Cada venta de caja escribe, además de
la operación y la factura, un registro firmado y **encadenado** en
`fza_verifactu_cadena` / `fza_verifactu_operaciones` y su entrada en
`fza_verifactu_cola`. Ese encadenamiento es inmutable por diseño: no
existe una limpieza que devuelva la BBDD a su estado anterior sin
romper la cadena de huellas, que es justamente lo que la cadena está
para impedir.

A eso se suma que los contadores de `fza_contadores` no se rebobinan
al borrar documentos, de modo que la numeración quedaría con huecos
aunque se borrasen las filas.

Por tanto la recomendación es ejecutar los puntos 5 a 8 sobre una
copia: la BBDD `alexzam`, que ya existe y tiene su propio
`alexzam.ini`, o una BBDD nueva cargada desde `factuzam_demo.sql`. La
limpieza pasa entonces a ser «restaurar la copia», que sí es exacta.

Si aun así se decide ejecutar sobre `Factuzam`, la sección de limpieza
describe el borrado acotado posible y sus límites.

## Entorno y datos de partida

Ubicación de la sesión: empresa `012`, almacén `GEN`, caja `1`
(la que muestra la barra de estado como `012\GEN\1`).

| Elemento | Valor | Origen |
|---|---|---|
| Empresa | `012` | `fza_almacenes.CODIGO_EMP_ALM` |
| Almacén | `GEN` — Almacén Central, uso ESTANDAR | `fza_almacenes` |
| Caja | `1` — «CAJA PARA VENDER ARTÍCULOS AL DETALLE» | `fza_almacenes_cajas` |
| Serie de factura | `2026.A1`, tipo FC, subtipo SIMPLIFICADA | `fza_empresas_series` |
| Serie de operación | `OV`, tipo OV | `fza_empresas_series` |
| Contador FC actual | `2026.A1` = 167, siguiente 168 | `fza_contadores` |
| Contador OV actual | `OV` = 194, siguiente 195 | `fza_contadores` |
| Tarifa por defecto | `PVP` (IVA incluido) | parámetro `vgerDefTarifa` |
| Tarifa alternativa | `REBAJAS` (código `3`) | `fza_tarifas` |
| Empleado por defecto | `1` | parámetro de caja |

SKUs con stock suficiente en `GEN` para las pruebas:

| SKU | Stock |
|---|---:|
| `CAMI-BASICA/BLANCO/M` | 24 |
| `TESTPMP1` | 22 |
| `CAMI-BASICA/ROJO/L` | 19 |
| `CAMI-POLO/AZUL/M` | 17 |
| `CAMI-POLO/BLANCO/S` | 15 |

Se usarán `CAMI-BASICA/BLANCO/M` para la venta y `CAMI-POLO/AZUL/M`
para la devolución, que dejan margen de sobra sobre el stock.

## Línea base

Antes de empezar hay que capturar la foto de partida con
`linea_base_5_8.sql` y guardar su salida. Los valores en el momento de
escribir este plan son:

| Tabla | Filas | Último |
|---|---:|---|
| `fza_caja_operaciones` | 72 | `ID_OPCAJA` = 195 |
| `fza_caja_pagos` | 159 | operación `00000192` |
| `fza_caja_vales` | 12 | `VALE-1-GEN-2-00006` |
| `fza_caja_arqueos` | 1 | `20260613-01` |
| `fza_movimientos_almacen` | 780 | `IV-4-0001S` |
| `fza_verifactu_cola` | 15 | `ID_VFCOLA` = 19 |
| `fza_ventas_ws_cola` | 0 | — |

La captura debe repetirse justo antes de ejecutar, porque estos
valores cambian con cualquier uso de la aplicación.

## Punto 5 — Caja completa

Precondición: caja abierta en `012\GEN\1`, tarifa por defecto `PVP`,
parámetro «Niveles de familia en resumen por sección» = 2.

1. **Tarifa por defecto al abrir caja.** Abrir caja y comprobar que la
   línea nueva toma `PVP` sin intervención. Esperado: el precio
   aplicado coincide con `fza_articulos_tarifas` para `PVP` y el SKU.
   Comprobación: `IMPORTE_TOTAL_OPCAJA` de la operación creada.
2. **Venta completa.** Vender 2 unidades de `CAMI-BASICA/BLANCO/M`,
   cobro en efectivo. Esperado: una fila en `fza_caja_operaciones`
   con `TIPO_OPERACION_OPCAJA` de venta, su fila en `fza_caja_pagos`,
   la factura simplificada en `fza_facturas` con serie `2026.A1` y
   número 168, el
   movimiento de salida en `fza_movimientos_almacen` y el stock del
   SKU reducido en 2.
3. **Vale.** Emitir un vale desde la operación anterior. Esperado:
   fila nueva en `fza_caja_vales` con `ESTADO_VL` emitido, importe
   nominal correcto y caducidad a 365 días, que es el valor del
   parámetro.
4. **Devolución.** Devolver 1 unidad de `CAMI-POLO/AZUL/M` con
   referencia a su operación de origen. Esperado: operación de
   devolución con `SERIE_REF_ORIGEN_OPCAJA` / `NUMERO_REF_ORIGEN_OPCAJA`
   apuntando al original, movimiento de entrada y stock repuesto. El
   parámetro «Pedir referencia en devoluciones» está a True, así que
   la aplicación debe exigir la referencia.
5. **Arqueo.** Cerrar arqueo. Esperado: fila en `fza_caja_arqueos`
   cuyos totales de ventas, devoluciones y vales emitidos cuadran con
   las operaciones del punto, y cuyo resumen por familias respeta los
   2 niveles configurados. Las operaciones quedan marcadas con
   `CODIGO_ARQUEO_OPCAJA`.

## Punto 6 — Impresión y exportaciones

1. **PDF.** Generar el PDF de la factura de la venta. Esperado: se
   escribe en la carpeta de `appDirPDF`, que resuelve
   `$(DOCUMENTOS)\PDF`.
2. **Excel.** Exportar una consulta a Excel. Esperado: se escribe en
   `appDirExcel`, que resuelve `$(DOCUMENTOS)\Excels`.
3. **Ticket y tira de caja.** Con `Nombre impresora de tickets` y
   `Tipo de Impresión tickets` a `DEBUG`, la salida no va a una
   impresora física; hay que comprobar el volcado que produce el modo
   DEBUG y el histórico en `appDirHistoricoCaja`, que resuelve
   `$(LOCALAPPDATA)\factuzam\tickets`.

Este punto es el único de los cuatro que no deja rastro en BBDD.

## Punto 7 — Fotos, correo e inventarios por API

**Bloqueado por configuración.** El perfil de Administrador no tiene
valores para `appApiUrl`, `appApiToken`, `appApiReferencia`,
`appFotosUrlDescarga`, `appFotosApiKey`, `appFotosCarpetaCliente`,
`appRecuentoUrl` ni `appRecuentoApiKey`, de modo que toman el valor
por defecto del catálogo y el token queda vacío. La aplicación ya lo
denuncia en el log:

```
WARNING: Cola de ventas WS pendiente: falta URL, API key o referencia
         de instalación.
```

Para ejecutar este punto hacen falta credenciales de un entorno de
pruebas de la API, y para el correo, una cuenta SMTP de pruebas. Sin
eso solo puede comprobarse la parte local: fotos desde carpeta y
lectura de `appDirFotos`.

## Punto 8 — Colas Verifactu y ventas WS

Estado actual: `appVerifactuActivo = True`, `appVerifactuModo =
VERIFACTU`, entorno `PRE`, SIF activo, firma con certificado de
empresa desactivada. La cola tiene 15 registros y el hilo funciona: el
log muestra su ciclo cada 60 segundos.

1. **Cola Verifactu.** La venta del punto 5 debe encolar su registro.
   Esperado: fila nueva en `fza_verifactu_cola` en estado PENDIENTE y,
   tras el ciclo, su registro firmado y encadenado.
2. **Error y reintento.** Forzar un error de envío y comprobar que la
   fila pasa a ERROR, incrementa `CONTADOR_INTENTOS_VFCOLA` y respeta
   `INSTANTE_PROXIMO_INTENTO_VFCOLA` y el máximo de 10 reintentos.
3. **Conmutación en caliente.** Cambiar `appVerifactuActivo` y
   comprobar en el log que el ciclo siguiente del hilo lee el valor
   nuevo. Esta parte ya está indirectamente verificada: al activar
   `appLogSQL` en el punto 4 aparecieron las consultas del hilo, lo
   que demuestra que lee los parámetros por interfaz.
4. **Ventas WS.** Bloqueado por lo mismo que el punto 7: sin URL, API
   key y referencia de instalación la cola no arranca.
5. **Reloj fiscal y NO VERI\*FACTU.** Requiere decidir antes si se
   permite tráfico real contra el entorno de preproducción de la AEAT
   y contra los servidores NTP configurados.

## Limpieza

Si las pruebas se ejecutan sobre una copia, la limpieza es restaurar
la copia y no hace falta nada más.

Sobre `Factuzam`, `limpieza_5_8.sql` borra de forma acotada lo
generado, tomando como frontera los valores capturados en la línea
base. Las nueve tablas implicadas tienen `INSTANTE_ALTA`, así que el
acotado se hace por el instante de inicio de las pruebas, que
`linea_base_5_8.sql` devuelve como primer resultado. Hay que rellenar
esa fecha en el script y confirmar explícitamente; sin las dos cosas
no borra nada. Antes de borrar deja el recuento de lo que va a tocar,
y actúa en orden de dependencia: pagos de caja, operaciones de caja,
vales, arqueo, líneas y cabeceras de factura, movimientos de almacén y
las dos colas.

Límites que ese borrado **no** resuelve:

- El stock de `fza_articulos_stockactual` no se recalcula solo. Hay
  que reponer a mano las cantidades de los SKUs usados o lanzar el
  recálculo de la aplicación.
- Los contadores de `fza_contadores` no se rebobinan; la numeración
  de `FC / 2026.A1` y `OV / OV` queda con huecos.
- La cadena de `fza_verifactu_cadena` no admite borrado limpio. Si el
  registro ya se firmó, eliminarlo deja la cadena rota. Es la razón
  principal para no ejecutar el punto 8 sobre esta BBDD.

## Decisiones pendientes antes de ejecutar

1. Sobre qué BBDD se ejecuta: copia `alexzam`, BBDD nueva desde
   `factuzam_demo.sql` o `Factuzam` asumiendo lo anterior.
2. Si se facilitan credenciales de API y SMTP de pruebas, o si los
   puntos 7 y la parte de ventas WS del 8 se dan por no ejecutables y
   se documentan como tales.
3. Si se autoriza tráfico real contra el entorno de preproducción de
   la AEAT y contra los servidores NTP para el reloj fiscal.
