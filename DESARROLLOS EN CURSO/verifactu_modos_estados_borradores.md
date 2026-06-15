# Verifactu: modos fiscales, estados y textos de pantalla

Convencion aplicada al circuito fiscal de ventas y compras documentales. La
logica interna, tablas, vistas, unidades y metodos siguen usando el dominio
historico `factura` (`fza_facturas`, `TIPO_FAC`, `FASE_FAC`,
`TVerifactuCola.EncolarFactura`, etc.). En pantalla, el documento de trabajo
se muestra como **Borrador/Borradores** para no mezclar el documento editable
con el registro fiscal ya emitido.

## Modos fiscales

Parametro de mantenimiento:

```text
appVerifactuModo = SIN | VERIFACTU | NO_VERIFACTU
```

El parametro vive en la seccion **Verifactu** y solo puede editarlo un
usuario administrador/mantenedor (`oRootGroup = 'S'`). Los usuarios normales
lo ven en solo lectura; si se fuerza un cambio desde el inspector, se ignora
al guardar.

| Modo | Uso | Registro | Cola AEAT | Exportacion |
|------|-----|----------|-----------|-------------|
| `SIN` | Transitorio hasta la obligatoriedad legal. | No crea registro fiscal SIF. | No. | No. |
| `VERIFACTU` | Remision a AEAT. | Encola alta/anulacion y guarda respuesta. | Si. | AEAT. |
| `NO_VERIFACTU` | SIF no verificable. | Guarda registro local encadenado y firmable. | No. | XML local de eventos y facturacion. |

`appVerifactuActivo` queda como compatibilidad antigua. La decision nueva
debe leerse siempre con `ModoVerifactu`.

## Estados de `FASE_FAC`

Todos caben en `fza_facturas.FASE_FAC` (`varchar(20)`).

| Estado | Modo | Significado |
|--------|------|-------------|
| `BORRADOR` | Todos | Editable, sin cierre fiscal. |
| `SIN_VERIFACTU` | `SIN` | Emitido sin SIF durante el periodo transitorio. |
| `SIN_VERIF_ANULADA` | `SIN` | Anulacion en modo transitorio. |
| `VERIFACTU_PENDIENTE` | `VERIFACTU` | Alta en cola pendiente/procesando. |
| `VERIFACTU_OK` | `VERIFACTU` | Alta aceptada por AEAT. |
| `VERIFACTU_ERROR` | `VERIFACTU` | Cola agotada; relanzable tras corregir. |
| `VERIFACTU_ANULADA` | `VERIFACTU` | Anulacion aceptada por AEAT. |
| `NOVERIFACTU_OK` | `NO_VERIFACTU` | Registro local creado y encadenado. |
| `NOVERIFACTU_ANULADA` | `NO_VERIFACTU` | Anulacion local creada y encadenada. |
| `RECTIFICADA` | Todos | Documento sustituido/rectificado. |

No se reutilizan `ONLINE`, `CANCELADA` ni `ERROR` para los nuevos cierres
fiscales, porque mezclaban modos distintos.

## Estados de `ESTADO_FACCON`

Todos caben en `fza_facturas_consolidaciones.ESTADO_FACCON`
(`varchar(20)`).

| Estado | Modo | Uso |
|--------|------|-----|
| `VERIFACTU_PROCESADO` | `VERIFACTU` | Alta aceptada. |
| `VERIFACTU_ACEPT_ERR` | `VERIFACTU` | Alta aceptada con errores. |
| `VERIFACTU_DUPLICADO` | `VERIFACTU` | Alta duplicada aceptada como duplicado. |
| `VERIFACTU_SUBSANADO` | `VERIFACTU` | Subsanacion aceptada. |
| `VERIFACTU_ANULADO` | `VERIFACTU` | Anulacion aceptada. |
| `NOVERIF_REGISTRADO` | `NO_VERIFACTU` | Alta local registrada. |
| `NOVERIF_SUBSANADO` | `NO_VERIFACTU` | Subsanacion local registrada. |
| `NOVERIF_ANULADO` | `NO_VERIFACTU` | Anulacion local registrada. |

En modo `SIN` no se crea fila en `fza_facturas_consolidaciones`.

## Firma y bloqueo por certificado

Si `appVerifactuFirmaCertificado=True`, los registros locales NO VERIFACTU y
eventos se firman con XAdES usando el certificado seleccionado en la empresa.
La firma se hace con la API criptografica de Windows desde `inLibXades.pas`;
no se invocan `.ps1` ni procesos externos para generar ficheros.

Si el certificado falta, esta caducado, todavia no es valido o no permite usar
la clave privada, no se hace fallback automatico a SHA-256. La operacion debe
fallar antes de dejar el registro fiscal cerrado. Para usar SHA-256 hay que
desactivar expresamente `appVerifactuFirmaCertificado`.

## Convencion de pantalla

Texto visible:

- Usar **Borrador/Borradores** en captions, botones, pestanas, mensajes,
  titulos de busqueda, textos de progreso y nombres de exportacion.
- Usar **registro fiscal**, **registro de facturacion** o **NO VERI*FACTU**
  cuando se habla de la obligacion legal o de los XML de descarga.

No cambiar:

- Nombres de unidades, clases, metodos, parametros SQL y campos.
- Tablas/vistas `fza_facturas*`, `vi_facturas*`.
- Tipos legales AEAT (`IDFactura`, `NumSerieFactura`, `TipoFactura`,
  `FacturasSustituidas`, `FacturasRectificadas`).
- Textos legales/declarativos o contenido impreso exigido por normativa.

## Pantallas revisadas

Pantallas y modales con etiquetas alineadas:

- Caja: `inMtoCajaFaseCobro`, `inMtoCajaOperacionesHist`, rectificacion desde
  caja.
- Borradores: `inMtoFacturasBase`, `inMtoFacturasNormal`,
  `inMtoFacturasSimplif`.
- Consulta de operaciones: `inMtoConsultaOpe`.
- Albaranes y generacion por fechas: `inMtoAlbaranes`,
  `inMtoModalFacturarAlbaranesFechas`.
- Modales F3/F8/rectificacion/impresion: `inMtoModalFacturarTicket`,
  `inMtoModalSerieFechaFactura`, `inMtoModalFacRec`, `inMtoModalImpFac`,
  `inMtoModalImpRecFac`.
- Historiales/accesos relacionados: `inMtoClientes`, `inMtoEmpresas`,
  `inMtoProveedores`, `inMtoFormasdePago`, `inMtoArticulos`,
  `inMtoModalGenFilter`.
- Compra documental: `inMtoFacturasCompra`, `inMtoEfectosCompra`,
  `inMtoModalFacturarAlbaranes`.

Comprobacion usada:

```text
rg "Caption|ShowMessage|MessageDlg|Caption :=" src\Forms src\Modals src\Caja\Forms
```

La busqueda de textos visibles no debe devolver `Factura/Facturas`. Si aparece
en SQL, claves `ShowMto`, nombres de layouts o textos legales, no aplica esta
convencion de pantalla.
