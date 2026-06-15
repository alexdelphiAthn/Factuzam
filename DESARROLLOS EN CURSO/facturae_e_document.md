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
  impuestos, retenciones si existen y lineas.
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
- NIF nacional con longitud distinta de 9 caracteres tras normalizar.
- Factura sin lineas.
- Linea sin descripcion.
- Linea con cantidad cero.
- Descuadre entre suma de bases de lineas y `TOTAL_BASES_FAC`.
- Descuadre entre bases, impuestos, retencion y `TOTAL_LIQUIDO_FAC`.

La tolerancia de cuadre es 0,05 euros para evitar falsos errores por redondeos
historicos.

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
- Las personas fisicas se separan de forma simple a partir de la razon social:
  primer token como nombre y resto como primer apellido. Si se necesita Facturae
  mas estricto para autonomos, conviene guardar nombre/apellidos desglosados.

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
0 errores, 0 advertencias
```
