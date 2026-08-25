# Contrato del puente transaccional de ventas

Este contrato define el límite entre el MCP, que no dispone de credenciales de
escritura SQL, y el servicio que ejecuta el caso de uso nativo de venta de
Factuzam. El servicio debe usar `IUnidadTrabajoVentaCaja`; implementar estas
rutas con inserciones SQL directas no cumple el contrato.

## Transporte y autenticación

- El origen se configura una sola vez con `FACTUZAM_VENTAS_BRIDGE_URL`.
- Se exige HTTPS. Solo se admite HTTP para una dirección IP numérica de
  loopback (`127.0.0.0/8` o `::1`); no se confía en resolución de nombres.
- Todas las peticiones llevan `Authorization: Bearer <token>` y
  `X-Factuzam-Principal: <principal>`.
- El servicio no debe redirigir las peticiones ni registrar el token.
- El cliente ignora deliberadamente `HTTP_PROXY`/`HTTPS_PROXY`; el puente es un
  destino explícito y no se contacta mediante proxy.
- Las respuestas son objetos JSON UTF-8 y no pueden superar 1 MiB.

## Preparar una venta

```http
POST /v1/ventas/preparaciones
Content-Type: application/json
```

El cuerpo contiene:

```json
{
  "empresa": "EMP01",
  "almacen": "ALM01",
  "caja": "CAJA01",
  "cliente": "CLI01",
  "tipo_documento": "SIMPLIFICADA",
  "serie": "A",
  "tarifa": "GENERAL",
  "lineas": [{"sku": "SKU-001", "cantidad": "2"}],
  "cobros": [
    {"forma_pago": "EFECTIVO", "importe": "20.00", "referencia": "op-42"}
  ]
}
```

Los decimales viajan como cadenas para no perder precisión. La preparación no
crea factura, movimiento de almacén, cobro ni asiento. El servicio vuelve a
validar permisos, códigos, stock, tarifa, precios, impuestos y medios de pago,
y devuelve un objeto con un `preparacion_id` opaco, `caduca_en` en ISO-8601 con
zona horaria y un objeto `resumen` que el operador pueda revisar. El cliente
rechaza una preparación si ese resumen no tiene, como mínimo, esta forma:

```json
{
  "preparacion_id": "prep-opaco",
  "caduca_en": "2026-08-25T12:15:00+02:00",
  "resumen": {
    "empresa": "EMP01",
    "almacen": "ALM01",
    "caja": "CAJA01",
    "tipo_documento": "SIMPLIFICADA",
    "serie": "A",
    "tarifa": "GENERAL",
    "cliente": {"codigo": "CLI01", "nombre": "Cliente de ejemplo"},
    "moneda": "EUR",
    "lineas": [
      {
        "sku": "SKU-001",
        "descripcion": "Artículo de ejemplo",
        "cantidad": "2",
        "precio_unitario_sin_impuestos": "10.00",
        "porcentaje_iva": "21",
        "base_imponible": "20.00",
        "cuota_iva": "4.20",
        "total_con_impuestos": "24.20"
      }
    ],
    "cobros": [{"forma_pago": "EFECTIVO", "importe": "24.20"}],
    "totales": {"base": "20.00", "impuestos": "4.20", "liquido": "24.20"}
  }
}
```

Empresa, almacén, caja, tipo de documento, serie y tarifa deben coincidir
exactamente con la solicitud normalizada. `cliente` identifica siempre al
cliente efectivo mediante código y nombre, o es `null` cuando la venta no se
asigna a ninguno. Si la solicitud especificó cliente, su código debe coincidir.
Debe existir al menos una línea.

`precio_unitario_sin_impuestos` es el precio unitario neto después de descuentos
de línea y antes de impuestos; `base_imponible` es la base de toda la línea;
`cuota_iva` es su impuesto y `total_con_impuestos` es el total final de línea.
Los campos numéricos son cadenas decimales ASCII exactas; no se aceptan números
JSON en coma flotante ni dígitos Unicode. El puente es responsable de que
líneas, cobros y totales sean coherentes entre sí y con sus reglas fiscales.

## Confirmar una venta

```http
POST /v1/ventas
Idempotency-Key: pedido-42
Content-Type: application/json
```

```json
{
  "preparacion_id": "prep-opaco",
  "idempotency_key": "pedido-42",
  "confirmar": true
}
```

La misma clave se envía en cabecera y cuerpo. El servicio debe comprobar que
coinciden, asociarla al principal y al hash de la solicitud y ejecutar toda la
venta en una única unidad de trabajo. Un reintento idéntico devuelve el mismo
resultado; reutilizar la clave para otro contenido se rechaza con conflicto.
Si `confirmar` no es exactamente `true`, no se efectúa ninguna operación.
La respuesta contiene `estado`. Sus únicos valores son `DESCONOCIDA`,
`PENDIENTE`, `CONFIRMADA` y `FALLIDA`; una respuesta `CONFIRMADA` incluye un
objeto `documento` con `empresa`, `serie` y `numero`.

## Consultar el resultado

```http
GET /v1/ventas/estado/{idempotency_key_codificada}
```

La clave ocupa un único segmento URL y el cliente la codifica por completo.
Esta ruta debe distinguir, como mínimo, operación desconocida, pendiente,
confirmada y fallida. Tras un timeout se consulta este estado con la misma
clave antes de decidir cualquier reintento.

Una vez enviada la confirmación, un timeout, HTTP 408/425/429 o 5xx, una
respuesta inválida/incompleta o un fallo de cierre se considera un resultado
indeterminado, no un rechazo: el servidor pudo haber confirmado la transacción
antes de perderse la respuesta.

## Invariantes del servicio

El puente vuelve a autorizar principal, empresa, almacén y caja; comprueba que
la preparación no ha caducado ni cambiado; y aplica numeración, stock,
impuestos, cobros, fiscalidad y auditoría mediante el dominio Delphi. Un fallo
en cualquier fase provoca rollback completo. Los mensajes de error públicos no
deben incluir SQL, rutas internas, credenciales ni datos sensibles de pago.
