# NO VERI*FACTU: registro firmado y exportación

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
| `appVerifactuFirmaCertificado` | `False` | Si está activo, los eventos y registros locales se firman con XAdES usando el certificado configurado en la empresa. En modo `NO_VERIFACTU` legal debe estar activo. Si está apagado, solo se mantiene la huella SHA-256 como rastro técnico/demo fuera del modo legal no verificable. |
| `appVerifactuNtpServidores` | `time.google.com,time.windows.com,pool.ntp.org` | Servidores NTP usados para validar el reloj del sistema antes de fechar registros NO VERI*FACTU. |
| `appVerifactuNtpTimeoutMs` | `1500` | Tiempo máximo de espera por servidor NTP. |
| `appVerifactuNtpMargenSegundos` | `60` | Margen máximo admitido entre reloj del sistema y reloj NTP. La aplicación no permite subirlo por encima de 60 segundos. |

El valor por defecto es `False` para no bloquear instalaciones que todavía no
tengan certificado seleccionado en la ficha de empresa. Al activar
`appVerifactuModo=NO_VERIFACTU`, la aplicación bloquea consolidación y
exportación legal si la firma con certificado no está disponible.

Los parámetros `appVerifactu*` son de mantenimiento fiscal. No los puede
modificar un usuario normal desde **Parámetros de aplicación** aunque pueda
editar sus parámetros personales o los de su grupo. Solo un usuario del grupo
administrador (`orootGroup = 'S'`) puede cambiarlos.

La convención completa de modos, fases y textos de pantalla queda en:

```text
DESARROLLOS EN CURSO/verifactu_modos_estados_borradores.md
```

## Firma obligatoria en NO VERI*FACTU

Según el criterio aplicado para cumplir la normativa SIF, los sistemas de
emisión de facturas no verificables deben firmar electrónicamente los
registros de facturación y los registros de evento. Por tanto, cuando
`appVerifactuModo=NO_VERIFACTU`:

1. `appVerifactuFirmaCertificado` debe estar activo.
2. Cada registro de facturación se firma al consolidar la factura.
3. Cada evento se firma al registrarse.
4. La exportación solo empaqueta registros ya firmados.

Cuando se firma:

1. El certificado se toma de `fza_empresas.CODIGO_CERTIFICADO_EMP` y
   `TITULAR_CERTIFICADO_EMP`.
2. La clave privada no se exporta.
3. La firma se hace con la API criptográfica de Windows desde
   `inLibXades.pas`.
4. No se invocan scripts `.ps1` ni procesos externos.
5. No se usa CryptoLib4Pascal para esta firma.

Formato técnico aplicado según `EspecTecGenerFirmaElectRfact.pdf`
AEAT v0.1.5:

- Firma `XAdES Enveloped` clase EPES.
- El nodo firmado es `RegistroAlta`, `RegistroAnulacion` o
  `RegistroEvento/Evento`, nunca los nodos superiores de transporte.
- `SignatureMethod`: RSA-SHA256.
- Digest de registro y `SignedProperties`: SHA-256.
- Política AGE:
  `urn:oid:2.16.724.1.3.1.1.2.1.9`.
- Hash de política: SHA-1 con
  `DigestValue=G7roucf600+f03r/o0bAOQ6WAs0=`.
- URL de política:
  `https://sede.administracion.gob.es/politica_de_firma_anexo_1.pdf`.
- No se exige sello de tiempo TSA.

Si el certificado no existe, esta caducado, todavia no es valido, no tiene
clave privada utilizable o el usuario cancela la operacion de firma, el
registro no debe quedar emitido como firmado. La aplicacion debe mostrar el
error y conservar la operacion sin cierre fiscal, apoyandose en la
transaccion que estaba creando la factura. No se cambia automaticamente a
SHA-256 porque eso dejaria un registro no verificable sin la firma exigible.

Si la incidencia ocurre al registrar un evento, se guarda una línea en
`fza_verifactu_eventos` con el XML base, la huella SHA-256 y
`INCIDENCIA_CERTIFICADO=...` en `DATOS_ADICIONALES_LOG`. Esa línea explica
por qué no hay XAdES y hace que la exportación legal quede bloqueada hasta que
se resuelva el problema.

Datos persistidos:

- Eventos: `REGISTRO_XML_LOG`, `FIRMA_XADES_LOG`,
  `SERIE_CERTIFICADO_LOG`, `TITULAR_CERTIFICADO_LOG`,
  `HUELLA_CERTIFICADO_LOG`.
- Facturación: `REGISTRO_XML_FACCON`, `FIRMA_DIGITAL_FACCON`,
  `SERIE_CERTIFICADO_FACCON`, `TITULAR_CERTIFICADO_FACCON`,
  `HUELLA_CERTIFICADO_FACCON`.

`FIRMA_DIGITAL_LOG` conserva un SHA-256 de la firma XAdES para mantener la
columna histórica de 64 caracteres.

## SHA-256 técnico / demo

Cuando `appVerifactuFirmaCertificado=False`:

1. Se genera la huella SHA-256 encadenada.
2. No se exige certificado en la empresa.
3. `FIRMA_DIGITAL_LOG` sigue guardando el SHA-256.
4. En facturación, el XML local se guarda sin bloque XAdES y
   `FIRMA_DIGITAL_FACCON` contiene la huella SHA-256 del registro.

Este modo mantiene compatibilidad con el comportamiento previo, pero no
equivale a firma electrónica avanzada. En modo `SIN` puede usarse para
generar ficheros de demostración. En modo `NO_VERIFACTU` no permite consolidar
ni exportar legalmente.

## Control de hora

La Orden HAC/1177/2024 exige que la fecha y hora usadas para fechar registros
de facturación sean exactas con margen máximo de un minuto e incluyan huso
horario. Para cumplirlo de forma verificable, Factuzam comprueba el reloj del
sistema contra NTP antes de generar registros NO VERI*FACTU.

Regla aplicada:

- Si el reloj se valida y la diferencia es igual o inferior a 60 segundos, se
  permite generar el registro.
- Si ningún servidor NTP responde, o la diferencia supera el margen, se bloquea
  la consolidación/anulación legal.
- La incidencia se guarda en el libro de eventos como
  `cEventoNoVerifactuIncidenciaReloj`, con `INCIDENCIA_RELOJ=...` en
  `DATOS_ADICIONALES_LOG`.
- En modo `SIN`, no se bloquea porque la descarga es solo demo.

El control se hace en `src/Lib/inLibRelojFiscal.pas`, reutilizando Indy
`TIdSNTP`. No corrige el reloj de Windows ni invoca comandos externos; solo
comprueba y bloquea si no se puede garantizar la exactitud legal.

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
3. Se firma el XML con XAdES usando el certificado de empresa.
4. Se guarda el registro en `fza_facturas_consolidaciones`.
5. Se registra un evento en `fza_verifactu_eventos`.
6. El borrador pasa a fase fiscal `NOVERIFACTU_OK` o
   `NOVERIFACTU_ANULADA`.

Si el certificado no permite firmar, no se guarda el cierre fiscal de la
factura y se registra una incidencia en el libro de eventos.

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
| `cEventoNoVerifactuIncidenciaCert` | `90` | Incidencia de certificado o bloqueo de exportación. |
| `cEventoNoVerifactuIncidenciaReloj` | `90` | Incidencia de reloj/NTP. |

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

Los dos ficheros incluyen el atributo `ModoVerifactu` en el nodo raíz. Ese
valor congela el contexto de la descarga (`SIN`, `VERIFACTU` o
`NO_VERIFACTU`) para que una verificación posterior no dependa de cómo esté
configurada la aplicación en ese momento.

Antes de construir los XML se valida el modo:

- En `NO_VERIFACTU`, se bloquea la exportación si hay eventos o registros de
  facturación sin `REGISTRO_XML`, firma XAdES y datos de certificado.
- En `SIN`, se permite la descarga como demo aunque no haya firmas legales.

Después se registran dos eventos de exportación. Si el parámetro de firma está
activo, esos eventos de exportación quedan firmados en el libro de eventos
igual que el resto de eventos legales.

Los ficheros raíz de descarga no se firman como contenedor adicional. El XML
de exportación incluye registros ya firmados dentro de CDATA para conservar
exactamente el XML oficial generado en el momento de emisión. La firma legal
exigible está en cada `RegistroAlta`, `RegistroAnulacion` y `RegistroEvento`,
no en `RegistroEventosNoVerifactu` ni en
`RegistroFacturacionNoVerifactu`. Firmar el contenedor duplicaría una garantía
que la especificación AEAT no exige y obliga a canonicalizar XML embebido en
CDATA, lo que no aporta valor legal.

## Ejemplo AEAT y validación externa

El ejemplo local de firma EPES/XAdES está en:

```text
DESARROLLOS EN CURSO/ejnoverifactu/ejemploRegistro-firmado-epes-xades4j.xml
```

Ese fichero es un registro fiscal individual firmado (`RegistroAlta`). No es
un libro completo de eventos/facturación ni un contenedor de descarga. Por eso
un validador público de firma debe recibir un XML individual firmado, no el
XML de exportación de Factuzam con los registros embebidos en CDATA.

Comparación aplicada:

- El ejemplo AEAT firma el nodo `RegistroAlta`.
- Factuzam firma `RegistroAlta` o `RegistroAnulacion` en facturación.
- Factuzam firma `RegistroEvento/Evento` en eventos.
- En todos los casos se usa `XAdES Enveloped` EPES, RSA-SHA256, SHA-256 para
  las referencias y la política AGE indicada arriba.

Para validación externa de firma puede usarse VALIDe con un registro
individual firmado extraído de `RegistroXmlFirmado`. FACe/AOC no son
validadores de ficheros NO VERI*FACTU; son validadores de Facturae.

## Unidades nuevas

- `src/Lib/inLibXades.pas`
- `src/Lib/inLibVerifactuNoVerifactuExport.pas`

Ambas unidades están añadidas en `fzam.dpr` y `fzam.dproj` para que Delphi las
muestre en el Project Manager y las compile con el proyecto principal.

## Límites pendientes

- Validar los XML contra los XSD definitivos que vaya publicando la AEAT.
- Revisar con certificado real FNMT en Win32 y Win64.
