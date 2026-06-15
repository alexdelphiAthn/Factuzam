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
4. Confirmar que existe `appVerifactuFirmaCertificado`.
5. Para las pruebas XAdES: seleccionar un certificado FNMT válido en la ficha
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

- `appVerifactuFirmaCertificado=False`.

**B2 - Persistencia.**

Cambiarlo a `True`, guardar, cerrar sesión y volver a entrar.

Resultado esperado:

- El valor persiste igual que el resto de parámetros de `frmMtoAppParam`.

## C. Registro NO VERI*FACTU sin certificado

Configuración:

- `appVerifactuActivo=False`.
- `appVerifactuFirmaCertificado=False`.

Crear una factura desde caja o lanzar una factura en borrador desde Facturas.

Resultado esperado:

- No se crea fila en `fza_verifactu_cola`.
- Sí se crea o actualiza fila en `fza_facturas_consolidaciones`.
- `CHAIN_HASH_FACCON` tiene SHA-256 en mayúsculas.
- `FIRMA_DIGITAL_FACCON` contiene la misma huella SHA-256 del registro.
- Las columnas de certificado quedan vacías.
- En `fza_verifactu_eventos`, `FIRMA_DIGITAL_LOG` contiene SHA-256.

Consulta rápida:

```sql
SELECT SERIE_FAC_FACCON,
       NUMERO_FAC_FACCON,
       ESTADO_FACCON,
       CHAIN_HASH_FACCON,
       FIRMA_DIGITAL_FACCON,
       SERIE_CERTIFICADO_FACCON
  FROM fza_facturas_consolidaciones
 ORDER BY ID_FACCON DESC
 LIMIT 5;
```

## D. Registro NO VERI*FACTU con certificado

Configuración:

- `appVerifactuActivo=False`.
- `appVerifactuFirmaCertificado=True`.
- Empresa con certificado FNMT instalado y seleccionado.

Crear una factura desde caja o lanzar una factura en borrador.

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

- `appVerifactuActivo=False`.
- `appVerifactuFirmaCertificado=True`.
- Empresa sin certificado seleccionado.

Crear una factura.

Resultado esperado:

- La operación no debe quedar registrada como firmada.
- Se muestra error claro indicando que falta certificado de empresa.
- No se avanza la cadena fiscal si la transacción se revierte.

## F. Anulación NO VERI*FACTU

Con una factura ya registrada localmente:

1. Ejecutar Anular Verifactu desde Facturas o Buscar operaciones.
2. Repetir en modo SHA-256 y en modo XAdES.

Resultado esperado:

- Se genera registro de anulación.
- La factura pasa a `FASE_FAC='CANCELADA'`.
- `ESTADO_FACCON` queda `ANULADO_NO_VERIFACTU`.
- La cadena `fza_verifactu_cadena` avanza.

## G. Exportación

Abrir **Verifactu Log** y pulsar `Exportar NO*VF`.

Resultado esperado:

- Se crean dos ficheros:
  - `_eventos.xml`
  - `_facturacion.xml`
- Se registran eventos de exportación antes de generar el XML.
- En modo firmado, ambos ficheros contienen `<ds:Signature`.
- En modo SHA-256, los ficheros no contienen `<ds:Signature` como firma de
  contenedor, pero sí incluyen las huellas y registros guardados.

## H. Cadena de eventos

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
