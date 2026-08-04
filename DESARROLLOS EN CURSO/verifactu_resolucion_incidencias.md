# Resolución de incidencias VERI*FACTU

## Regla funcional

La resolución se ofrece únicamente en Factura Venta Mayor cuando el último
registro está en `VERIFACTU_ACEPT_ERR` y no existe una subsanación pendiente,
procesándose o ya enviada.

- Si la factura expedida es correcta y el fallo está solo en el registro
  remitido, se encola `SUBSANACION` con motivo obligatorio.
- Si el NIF u otro dato erróneo figura en la propia factura, se crea una
  rectificativa sustitutiva `R4` con el cliente corregido, se enlaza con la
  original y se encola por el circuito fiscal existente.

Un estado «Aceptado con errores» describe la respuesta de la AEAT, no
autoriza a cambiar una factura expedida mediante subsanación.

## Esquema

Ejecutar `verifactu_resolucion_incidencias.sql`. El script es idempotente y
no modifica el dump modelo. Añade:

- el tipo explícito `R1`...`R5` a `fza_facturas`;
- el motivo a `fza_verifactu_cola`;
- código y descripción de error AEAT a la consolidación;
- una instantánea del alta original y los datos de auditoría de la
  subsanación a `fza_facturas_consolidaciones`.

No se crea una tabla nueva: el histórico original se conserva junto a la
consolidación única de la factura para mantener su identidad fiscal.

## Componentes

- `inLibFacturasIncidenciaFiscalIntf` define los contratos.
- `inLibFacturasIncidenciaFiscal` aplica la decisión y las validaciones.
- `UniDataFacturasIncidenciaFiscal` carga la incidencia y crea la R4.
- `inMtoModalResolverIncidenciaVerifactu` recoge la decisión del usuario.
- `UniDataVerifactuColaRepositorio` encola solo subsanaciones válidas.
- `UniDataVerifactuColaResultados` conserva el alta original al aceptar la
  subsanación.

## Pruebas manuales

1. Provocar en PRE un alta `AceptadoConErrores` y comprobar que aparece
   **Resolver incidencia** en la pestaña Verifactu.
2. Elegir **factura correcta**, indicar un motivo y resolver. Debe aparecer
   una fila `SUBSANACION/PENDIENTE`; un segundo intento debe quedar impedido.
3. Tras respuesta correcta, verificar `VERIFACTU_SUBSANADO`, los campos
   `*_ORIGINAL_FACCON`, el motivo, instante y usuario de subsanación.
4. Repetir con otra factura aceptada con errores y elegir **el dato figura en
   la factura**. Seleccionar cliente, serie y fecha; debe crearse una factura
   `RECTIFICATIVA`, `TIPO_RECTIFICATIVA_FAC='S'` y
   `TIPO_FACTURA_VERIFACTU_FAC='R4'`.
5. Comprobar que la factura original apunta a la R4, que existe la relación
   `RECTIFICA` y que el XML enviado contiene `TipoFactura=R4`.

La reversión de esquema, si llegara a necesitarse, debe prepararse y
autorizarse expresamente porque eliminaría el histórico fiscal almacenado.
