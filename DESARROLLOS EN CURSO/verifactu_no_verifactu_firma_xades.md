# NO VERI*FACTU: registro firmado, exportación y modo SHA-256

Desarrollo para que Factuzam conserve localmente los registros exigibles en
modo NO VERI*FACTU y pueda exportar dos ficheros XML:

- Registro de eventos del sistema.
- Registro de facturación.

La idea importante es que la trazabilidad no se crea al descargar el fichero.
Los eventos y las facturas se registran en el momento en que ocurren. La
descarga solo empaqueta lo que ya existe en BBDD.

## Parámetro general

Categoría: **Verifactu** (`inLibAppParam`).

| Parámetro | Defecto | Uso |
|-----------|---------|-----|
| `appVerifactuModo` | `SIN` | Modo fiscal activo: `SIN`, `VERIFACTU` o `NO_VERIFACTU`. |
| `appVerifactuFirmaCertificado` | `False` | Si está activo, los eventos y registros locales se firman con XAdES usando el certificado configurado en la empresa. Si está apagado, se mantiene la firma técnica SHA-256 en el registro. |

El valor por defecto es `False` para no bloquear instalaciones que todavía no
tengan certificado seleccionado en la ficha de empresa.

Los parámetros `appVerifactu*` son de mantenimiento fiscal. No los puede
modificar un usuario normal desde **Parámetros de aplicación** aunque pueda
editar sus parámetros personales o los de su grupo. Solo un usuario del grupo
administrador (`orootGroup = 'S'`) puede cambiarlos.

La convención completa de modos, fases y textos de pantalla queda en:

```text
DESARROLLOS EN CURSO/verifactu_modos_estados_borradores.md
```

## Modo con certificado

Cuando `appVerifactuFirmaCertificado=True`:

1. El certificado se toma de `fza_empresas.CODIGO_CERTIFICADO_EMP` y
   `TITULAR_CERTIFICADO_EMP`.
2. La clave privada no se exporta.
3. La firma se hace con la API criptográfica de Windows desde
   `inLibXades.pas`.
4. No se invocan scripts `.ps1` ni procesos externos.
5. No se usa CryptoLib4Pascal para esta firma.

Si el certificado no existe, esta caducado, todavia no es valido, no tiene
clave privada utilizable o el usuario cancela la operacion de firma, el
registro no debe quedar emitido como firmado. La aplicacion debe mostrar el
error y conservar la operacion sin cierre fiscal, apoyandose en la
transaccion que estaba creando la factura. No se cambia automaticamente a
SHA-256 porque eso contradiria la configuracion activa; para trabajar en modo
SHA-256 hay que desactivar expresamente `appVerifactuFirmaCertificado`.

Datos persistidos:

- Eventos: `REGISTRO_XML_LOG`, `FIRMA_XADES_LOG`,
  `SERIE_CERTIFICADO_LOG`, `TITULAR_CERTIFICADO_LOG`,
  `HUELLA_CERTIFICADO_LOG`.
- Facturación: `REGISTRO_XML_FACCON`, `FIRMA_DIGITAL_FACCON`,
  `SERIE_CERTIFICADO_FACCON`, `TITULAR_CERTIFICADO_FACCON`,
  `HUELLA_CERTIFICADO_FACCON`.

`FIRMA_DIGITAL_LOG` conserva un SHA-256 de la firma XAdES para mantener la
columna histórica de 64 caracteres.

## Modo SHA-256

Cuando `appVerifactuFirmaCertificado=False`:

1. Se genera la huella SHA-256 encadenada.
2. No se exige certificado en la empresa.
3. `FIRMA_DIGITAL_LOG` sigue guardando el SHA-256.
4. En facturación, el XML local se guarda sin bloque XAdES y
   `FIRMA_DIGITAL_FACCON` contiene la huella SHA-256 del registro.

Este modo mantiene compatibilidad con el comportamiento previo, pero no
equivale a firma electrónica avanzada.

## Cambios de BBDD

Script idempotente:

```text
DESARROLLOS EN CURSO/verifactu_registros_firmados.sql
```

No se toca `factuzam_original.sql`.

El script añade columnas largas para conservar el XML completo y los datos del
certificado. Debe ejecutarse en cada BBDD existente antes de activar la firma
por certificado o antes de querer descargar el registro completo.

## Flujo de facturación NO VERI*FACTU

Cuando `appVerifactuModo=NO_VERIFACTU` y se crea o lanza un borrador:

1. Se construye el registro fiscal de alta/anulación en local.
2. Se calcula la huella SHA-256 y se encadena en `fza_verifactu_cadena`.
3. Si `appVerifactuFirmaCertificado=True`, se firma el XML con XAdES.
4. Se guarda el registro en `fza_facturas_consolidaciones`.
5. Se registra un evento en `fza_verifactu_eventos`.
6. El borrador pasa a fase fiscal `NOVERIFACTU_OK` o
   `NOVERIFACTU_ANULADA`.

Puntos enlazados:

- Caja: `UniDataCaja.GrabarFacturaSimplificada`.
- Borradores: botón Consolidar y Anular registro fiscal.
- Consulta de operaciones: anulación.
- Conversión F3 de ticket a borrador normal.

## Eventos del sistema

Catálogo interno añadido:

| Constante | Código AEAT previsto | Uso |
|-----------|----------------------|-----|
| `cEventoNoVerifactuInicio` | `01` | Inicio del sistema. |
| `cEventoNoVerifactuFin` | `02` | Cierre del sistema. |
| `cEventoNoVerifactuCambioConfig` | `03` | Cambio de configuración. |
| `cEventoNoVerifactuExportFact` | `08` | Exportación del registro de facturación. |
| `cEventoNoVerifactuExportEventos` | `09` | Exportación del registro de eventos. |

Los eventos técnicos antiguos de Factuzam se registran como evento voluntario
`90`, para no mezclar envíos internos con códigos oficiales de arranque o
cierre.

Puntos de disparo:

- Inicio: `TfrmMtoPrincipal.FormCreate`.
- Cierre: `TfrmMtoPrincipal.FormClose`.
- Cambio de configuración: `TfrmMtoAppParam.btnGuardarClick`, solo cuando se
  guardan parámetros `appVerifactu*`.

Estos tres puntos registran el evento de forma segura: si falta migración,
certificado o configuración, la aplicación no se cierra por ello y el motivo
queda en `inLibLog`.

## Exportación

Botón en **Verifactu Log**:

```text
Exportar NO*VF
```

Genera dos ficheros:

- `<nombre>_eventos.xml`
- `<nombre>_facturacion.xml`

Antes de construir los XML se registran dos eventos de exportación. Si el
parámetro de firma está activo, ambos ficheros también se firman XAdES como
contenedor de descarga.

## Unidades nuevas

- `src/Lib/inLibXades.pas`
- `src/Lib/inLibVerifactuNoVerifactuExport.pas`

Ambas unidades están añadidas en `fzam.dpr` y `fzam.dproj` para que Delphi las
muestre en el Project Manager y las compile con el proyecto principal.

## Límites pendientes

- Validar los XML contra los XSD definitivos que vaya publicando la AEAT.
- Revisar con certificado real FNMT en Win32 y Win64.
