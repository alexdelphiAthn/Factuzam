# Facturae eDoc en venta mayor

## Objetivo

Boton **Emitir eDoc** en `Borradores (Venta Mayor)` para generar un fichero
Facturae 3.2.2 firmado con XAdES y certificado electronico de la empresa.

El codigo nuevo vive en `src/Lib/inLibFacturae.pas`. El prototipo de
`src/pruebas factura-e` se ha usado solo como referencia de campos y estructura,
pero la pantalla real no depende de ese proyecto de pruebas.

## Alcance actual

La emision eDoc hace:

- Carga `fza_facturas` y `fza_facturas_lineas` por `SERIE_FAC` y
  `NUMERO_FAC`.
- Exige `TIPO_FAC = NORMAL`, por tanto queda limitado a venta mayor.
- Exige `ESCONSOLIDADA_FAC = 'S'`: no emite eDoc desde un borrador sin cierre
  fiscal.
- Valida datos minimos de emisor, cliente, fecha, lineas y totales.
- Genera XML Facturae 3.2.2 con `FileHeader`, `Parties`, `Invoices`,
  impuestos, retenciones si existen, lineas y `PaymentDetails`.
- Genera `AdministrativeCentres` con oficina contable, organo gestor y unidad
  tramitadora. Primero toma la foto guardada en la factura, si esta vacia toma
  los codigos del cliente y, solo para validacion tecnica inicial, aplica el
  respaldo DIR3 documentado abajo.
- Firma el XML con `inLibXades.OpcionesXadesFacturae`, politica Facturae y rol
  `emisor`.
- Guarda el XML firmado en el fichero elegido por el usuario (`.xsig` por
  defecto).
- Guarda el mismo XML firmado en `fza_facturas.XML_FAC`.

No se invocan scripts `.ps1` ni procesos externos para crear el fichero. La
firma usa la API criptografica de Windows desde `inLibXades.pas`.

## Certificado

El certificado se toma de la empresa de la factura:

```sql
fza_empresas.CODIGO_CERTIFICADO_EMP
fza_empresas.TITULAR_CERTIFICADO_EMP
```

Si no hay certificado configurado, si no existe en el almacen personal de
Windows o si no permite firmar, se aborta la emision eDoc. No se genera un XML
sin firma como sustituto legal.

## Validaciones antes de firmar

La validacion interna bloquea:

- Factura inexistente.
- Tipo distinto de `NORMAL`.
- Factura no consolidada.
- Fecha oficial vacia.
- NIF, razon social, direccion, codigo postal, poblacion o provincia vacios en
  emisor o cliente.
- NIF, NIE o CIF espanol invalido usando el validador local
  `inLibDocumentoFiscal`, adaptado del proyecto Subocasoft.
- Falta de oficina contable, organo gestor o unidad tramitadora cuando se
  emite Facturae para receptor publico.
- Factura sin lineas.
- Linea sin descripcion.
- Linea con cantidad cero.
- Descuadre entre suma de bases de lineas y `TOTAL_BASES_FAC`.
- Descuadre entre bases, impuestos, retencion y `TOTAL_LIQUIDO_FAC`.

La tolerancia de cuadre es 0,05 euros para evitar falsos errores por redondeos
historicos.

La misma validacion de NIF/NIE/CIF se aplica antes de guardar cabeceras
`NORMAL`, antes de crear una F3 desde ticket y antes de emitir una factura
completa desde caja con F8. Las facturas simplificadas siguen permitiendo venta
contado sin cliente identificado.

## Datos DIR3

El script idempotente
`DESARROLLOS EN CURSO/facturae_formas_pago_codigo.sql` anade a
`fza_formas_pago`:

```sql
CODIGO_FACTURAE_FP
```

Ese campo guarda el `PaymentMeans` oficial de Facturae (`01` a `19`). El valor
por defecto es `01` al contado. La emision eDoc toma este valor desde la forma
de pago de la factura; si una instalacion todavia no tiene la columna aplicada,
usa `01` para no romper la generacion tecnica. El vencimiento se emite de
momento con `FECHA_FAC`, hasta completar el uso real de recibos.

El script idempotente
`DESARROLLOS EN CURSO/facturae_dir3_clientes.sql` anade a `fza_clientes`:

```sql
CODIGO_OFICINA_CONTABLE_CLI
CODIGO_ORGANO_GESTOR_CLI
CODIGO_UNIDAD_TRAMITADORA_CLI
```

Y anade la foto equivalente a `fza_facturas`:

```sql
CODIGO_OFICINA_CONTABLE_FAC
CODIGO_ORGANO_GESTOR_FAC
CODIGO_UNIDAD_TRAMITADORA_FAC
```

El mismo script recrea `vi_clientes`, `vi_cli_busquedas`, `vi_facturas`,
`vi_facturas_normales` y `vi_facturas_simplificadas`, porque MariaDB fija las
columnas de una vista en el momento de crearla. Tambien rellena facturas
existentes desde el cliente cuando los nuevos campos de factura estan vacios.

La ficha de clientes tiene una pestana **Parametros eDoc** para guardar los
DIR3 habituales del cliente publico. La pantalla de `Borradores (Venta Mayor)`
tiene otra pestana **Parametros eDoc** con la foto de esa factura concreta.

Estos codigos deben ser los DIR3 reales del cliente publico. Mientras se corrige
la validacion externa inicial, el generador usa como ultimo recurso tecnico
`L01070184` en los tres centros; no debe considerarse un valor legal para
facturas reales de otras administraciones.

## Personas fisicas

El script idempotente
`DESARROLLOS EN CURSO/facturae_persona_fisica.sql` anade a `fza_clientes`:

```sql
NOMBRE_PERSONA_CLIENTE_CLI
APELLIDOS_PERSONA_CLIENTE_CLI
```

Y anade la foto equivalente a `fza_facturas`:

```sql
NOMBRE_PERSONA_CLIENTE_FAC
APELLIDOS_PERSONA_CLIENTE_FAC
```

Estos campos se editan en la pestana **Parametros eDoc** del cliente. Al
seleccionar el cliente en una factura mayor se copian a la factura como foto
de emision, igual que los DIR3. La pestana **Parametros eDoc** de
`Borradores (Venta Mayor)` permite revisar o corregir la foto de esa factura
concreta. Si el cliente tiene NIF/NIE de persona fisica, la emision eDoc exige
que ambos esten rellenos y no intenta partir `RAZON_SOCIAL_CLIENTE_FAC`,
porque nombres compuestos como `JOSE CARLOS RODRIGUEZ LOPEZ` no se pueden
separar de forma segura.

## Normativa y formato

Referencias oficiales revisadas:

- Facturae: formato oficial y ultima version publicada:
  <https://www.facturae.gob.es/formato/ultima-version>
- Facturae: documentacion general del formato:
  <https://www.facturae.gob.es/formato>
- Politica de firma Facturae 3.1 incluida en el paquete local de pruebas:
  `src/pruebas factura-e/documentation/Politica_Firma_formato_facturae_v3_1.pdf`
- Ley 18/2022, de creacion y crecimiento de empresas:
  <https://www.boe.es/buscar/act.php?id=BOE-A-2022-15818>
- Real Decreto 238/2026 de factura electronica entre empresarios y
  profesionales:
  <https://www.boe.es/buscar/act.php?id=BOE-A-2026-7295>

El eDoc generado es un XML Facturae firmado. El cumplimiento B2B completo no se
agota en el fichero: tambien puede exigir intercambio por plataforma, estados,
acuse/aceptacion/rechazo y trazabilidad segun el circuito que se implante.

## Limitaciones pendientes

- No hay validacion XSD completa contra los esquemas oficiales. La validacion
  actual es una prevalidacion de negocio y estructura minima antes de firmar.
- No se genera PDF dentro de este boton. El PDF sigue saliendo por el circuito
  de impresion existente.
- No se registran estados B2B de entrega/aceptacion/rechazo. Eso deberia ir en
  una tabla propia o en un subsistema de intercambio cuando se decida la
  plataforma.

## Prueba funcional

1. Abrir `Borradores (Venta Mayor)`.
2. Seleccionar una factura NORMAL ya consolidada.
3. Pulsar **Emitir eDoc**.
4. Elegir fichero `.xsig`.
5. Verificar que se genera el fichero y que `XML_FAC` queda relleno con el XML
   firmado.

Compilacion verificada:

```text
Delphi 13 / Win64 / Release
0 errores; advertencias previas del proyecto y librerias de terceros
```
