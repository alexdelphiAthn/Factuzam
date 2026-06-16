# Batería de pruebas: NO VERI*FACTU firmado y exportable

Pruebas del desarrollo descrito en
`verifactu_no_verifactu_firma_xades.md`.

## 0. Preparación

1. Compilar `fzam.dproj` en Win64 y Win32.
2. Ejecutar:

   ```sql
   DESARROLLOS EN CURSO/verifactu_registros_firmados.sql
   ```

3. Abrir parámetros de aplicación y localizar la categoría **Verifactu**.
4. Confirmar que existen `appVerifactuModo` y
   `appVerifactuFirmaCertificado`.
5. Confirmar que existen `appVerifactuNtpServidores`,
   `appVerifactuNtpTimeoutMs` y `appVerifactuNtpMargenSegundos`.
6. Para las pruebas XAdES: seleccionar un certificado FNMT válido en la ficha
   de empresa (`CODIGO_CERTIFICADO_EMP` y `TITULAR_CERTIFICADO_EMP`).

## A. Script SQL

**A1 - Primera ejecución.**

Ejecutar el script en una BBDD de pruebas.

Resultado esperado:

- Se añaden las columnas de XML/firma en `fza_verifactu_eventos`.
- Se añaden las columnas de XML/firma en `fza_facturas_consolidaciones`.
- No se modifica `factuzam_original.sql`.

**A2 - Re-ejecución.**

Ejecutar el mismo script de nuevo.

Resultado esperado:

- No da error.
- Las columnas existentes se omiten.

## B. Parámetro de firma

**B1 - Valor por defecto.**

Abrir parámetros de aplicación.

Resultado esperado:

- `appVerifactuModo=SIN`.
- `appVerifactuFirmaCertificado=False`.

**B2 - Persistencia.**

Cambiarlo a `True`, guardar, cerrar sesión y volver a entrar.

Resultado esperado:

- El valor persiste igual que el resto de parámetros de `frmMtoAppParam`.

**B3 - Bloqueo para usuario no administrador.**

Entrar con un usuario cuyo grupo no sea administrador.

Resultado esperado:

- Los parámetros `appVerifactu*` aparecen en solo lectura.
- Si se fuerza un cambio desde el inspector, no se guarda.
- El mensaje indica que solo un administrador puede cambiar parámetros
  Verifactu.

## C. Modo NO VERI*FACTU sin firma activada

Configuración:

- `appVerifactuModo=NO_VERIFACTU`.
- `appVerifactuFirmaCertificado=False`.

Crear un borrador desde caja o lanzar un borrador desde Borradores.

Resultado esperado:

- No se crea fila en `fza_verifactu_cola`.
- No se crea un cierre fiscal válido en `fza_facturas_consolidaciones`.
- El borrador no pasa a `NOVERIFACTU_OK`.
- Se muestra error indicando que el modo NO VERI*FACTU exige firma con
  certificado oficial.
- En `fza_verifactu_eventos` queda una incidencia con
  `INCIDENCIA_CERTIFICADO=...`, XML base y huella SHA-256.

Consulta rápida:

```sql
SELECT ID_LOG,
       DESCRIPCION_LOG,
       DATOS_ADICIONALES_LOG,
       HASH_PROPIO_LOG,
       FIRMA_XADES_LOG
  FROM fza_verifactu_eventos
 ORDER BY ID_LOG DESC
 LIMIT 5;
```

## D. Registro NO VERI*FACTU con certificado

Configuración:

- `appVerifactuModo=NO_VERIFACTU`.
- `appVerifactuFirmaCertificado=True`.
- Empresa con certificado FNMT instalado y seleccionado.

Crear un borrador desde caja o lanzar un borrador.

Resultado esperado:

- No se crea fila en `fza_verifactu_cola`.
- Se crea registro local en `fza_facturas_consolidaciones`.
- `REGISTRO_XML_FACCON` contiene `<ds:Signature`.
- `FIRMA_DIGITAL_FACCON` contiene el `SignatureValue`.
- `SERIE_CERTIFICADO_FACCON`, `TITULAR_CERTIFICADO_FACCON` y
  `HUELLA_CERTIFICADO_FACCON` quedan rellenos.
- En `fza_verifactu_eventos`, `REGISTRO_XML_LOG` contiene el XML de evento y
  `FIRMA_XADES_LOG` queda rellena.

Consulta rápida:

```sql
SELECT SERIE_FAC_FACCON,
       NUMERO_FAC_FACCON,
       ESTADO_FACCON,
       LOCATE('<ds:Signature', REGISTRO_XML_FACCON) AS TIENE_FIRMA,
       LENGTH(FIRMA_DIGITAL_FACCON) AS TAM_FIRMA,
       SERIE_CERTIFICADO_FACCON
  FROM fza_facturas_consolidaciones
 ORDER BY ID_FACCON DESC
 LIMIT 5;
```

## E. Falta de certificado en modo firmado

Configuración:

- `appVerifactuModo=NO_VERIFACTU`.
- `appVerifactuFirmaCertificado=True`.
- Empresa sin certificado seleccionado.

Crear un borrador.

Resultado esperado:

- La operación no debe quedar registrada como firmada.
- Se muestra error claro indicando que falta certificado de empresa.
- No se avanza la cadena fiscal si la transacción se revierte.
- En el libro de eventos queda registrada la incidencia de certificado.

**E2 - Certificado caducado o no vigente.**

Configuración:

- `appVerifactuModo=NO_VERIFACTU`.
- `appVerifactuFirmaCertificado=True`.
- Empresa con un certificado seleccionado que exista en Windows pero no este
  vigente.

Crear un borrador.

Resultado esperado:

- La firma XAdES no se genera.
- Se muestra un error indicando que el certificado esta caducado o todavia no
  es valido, incluyendo su rango de vigencia.
- No se hace fallback automatico a SHA-256.
- El borrador no debe quedar cerrado fiscalmente ni debe avanzar la cadena si
  la transaccion se revierte.
- En el libro de eventos queda registrada la incidencia de certificado.

## F. Anulación NO VERI*FACTU

Con un borrador ya registrado localmente:

1. Ejecutar Anular registro fiscal desde Borradores o Buscar operaciones.
2. Repetir con certificado válido y con certificado inválido.

Resultado esperado:

- Con certificado válido, se genera registro de anulación firmado.
- El borrador pasa a `FASE_FAC='NOVERIFACTU_ANULADA'`.
- `ESTADO_FACCON` queda `NOVERIF_ANULADO`.
- La cadena `fza_verifactu_cadena` avanza.
- Con certificado inválido, se muestra error, no se hace fallback a SHA-256 y
  queda una incidencia en el libro de eventos.

## G. Exportación

Abrir **Verifactu Log** y pulsar `Exportar NO*VF`.

Resultado esperado:

- Se crean dos ficheros:
  - `_eventos.xml`
  - `_facturacion.xml`
- Se registran eventos de exportación antes de generar el XML.
- Los dos XML llevan atributo raíz `ModoVerifactu` con el modo usado al
  exportar.
- En modo `NO_VERIFACTU`, la exportación se bloquea si hay eventos o registros
  de facturación sin XAdES y datos de certificado.
- Con todos los registros firmados, ambos ficheros contienen `<ds:Signature`.
- La firma debe estar dentro de cada `RegistroAlta`, `RegistroAnulacion` o
  `RegistroEvento/Evento`, no como firma del contenedor raíz de descarga.
- En modo `SIN`, la descarga puede generarse como demo aunque no haya firmas
  legales.

**G2 - Verificación local.**

Después de exportar, pulsar `Verificar NO*VF` seleccionando cualquiera de los
dos XML generados.

Resultado esperado:

- Se localizan automáticamente los ficheros `_eventos.xml` y
  `_facturacion.xml`.
- Se crea el informe `errores_<nombre>.xml.txt` en la misma carpeta.
- El resumen indica el modo del fichero. Si el XML no lo declara por ser una
  exportación antigua, se usa el modo actual de la aplicación como fallback.
- No se avisa por falta de firma del contenedor raíz.
- En modo `NO_VERIFACTU`, se da error si falta firma XAdES en algún registro
  interno.
- En modo `SIN`, la falta de firma XAdES se informa como aviso porque el
  fichero es demo y no una exportación legal no verificable.
- Se da error si la firma interna no usa política AGE
  `urn:oid:2.16.724.1.3.1.1.2.1.9`, RSA-SHA256, SHA-256 para el registro y
  SHA-1 únicamente para el hash de la política.

**G3 - Contraste con ejemplo AEAT.**

Abrir:

```text
DESARROLLOS EN CURSO/ejnoverifactu/ejemploRegistro-firmado-epes-xades4j.xml
```

Resultado esperado:

- Se confirma que el ejemplo es un `RegistroAlta` individual firmado.
- La firma está dentro del registro, no en un contenedor de exportación.
- El perfil coincide con la validación interna: `XAdES Enveloped` EPES,
  RSA-SHA256, dos referencias en `SignedInfo`, política AGE y
  `DataObjectFormat` `text/xml`.
- Para validar en VALIDe se debe usar un XML individual firmado, no el
  fichero `_eventos.xml` o `_facturacion.xml` completo de Factuzam.

## H. Control de reloj fiscal

Configuración:

- `appVerifactuModo=NO_VERIFACTU`.
- `appVerifactuFirmaCertificado=True`.
- `appVerifactuNtpServidores=time.google.com,time.windows.com,pool.ntp.org`.
- `appVerifactuNtpMargenSegundos=60`.

Crear un borrador con el reloj de Windows correcto.

Resultado esperado:

- La comprobación NTP permite continuar.
- El registro se firma y queda en `NOVERIFACTU_OK`.

Forzar una prueba de fallo configurando temporalmente:

```text
appVerifactuNtpServidores=127.0.0.1
appVerifactuNtpTimeoutMs=500
```

Crear otro borrador.

Resultado esperado:

- Se muestra error indicando que no se pudo comprobar el reloj fiscal contra
  NTP.
- No se genera cierre fiscal válido.
- Se registra evento `cEventoNoVerifactuIncidenciaReloj` con
  `INCIDENCIA_RELOJ=...`.

Prueba de desviación: cambiar manualmente el reloj de Windows más de un minuto
en una máquina de pruebas y repetir.

Resultado esperado:

- Se bloquea la operación.
- El mensaje indica la diferencia en segundos y el margen de 60 segundos.

## I. Cadena de eventos

Ejecutar:

```sql
SELECT a.ID_LOG,
       IF(a.HASH_ANTERIOR_LOG = IFNULL(
            (SELECT b.HASH_PROPIO_LOG
               FROM fza_verifactu_eventos b
              WHERE b.ID_LOG < a.ID_LOG
              ORDER BY b.ID_LOG DESC
              LIMIT 1),
            REPEAT('0', 64)),
          'OK', 'ROTA') AS CADENA
  FROM fza_verifactu_eventos a
 ORDER BY a.ID_LOG;
```

Resultado esperado:

- Todas las filas devuelven `OK`.
