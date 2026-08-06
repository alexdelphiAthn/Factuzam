# Interprete Delphi del pedido Albion

Programa de consola especifico para el formato `PRE-PEDIDO / PRE-ORDER` de Albion 1879.

Lee directamente el JSON bruto de Azure Document Intelligence `prebuilt-layout`. Ignora poligonos, coordenadas, palabras y estilos; solo usa el texto y la matriz fila/columna de las tablas.

## Uso

Haz doble clic en `ejecutar-interprete.cmd`. Si solo hay un `*.azure-ocr.*.json` en la carpeta, lo selecciona automaticamente y genera:

```text
<archivo>.albion-simple.json
```

Tambien puede ejecutarse por consola:

```powershell
.\bin\InterpretarPedidoAlbion.exe `.\resultado.azure-ocr.prebuilt-layout.json`
```

Se puede indicar una ruta de salida como segundo parametro.

## Salida

- `proveedor`: razon social, direccion, CIF y telefono.
- `referencia_doc`.
- `fecha_pedido`, `fecha_tope` y `fecha_prevista_entrega`, en ISO `YYYY-MM-DD`.
- `detalle`: modelo, descripcion, color, tallas con cantidad, cantidad total, precio unitario mayorista, PVP e importe.
- `totales` y `validacion`.

La validacion comprueba suma de tallas, cantidad por precio, suma de cantidades y suma de importes. Si el formato cambia o el OCR no cuadra, el JSON incluye advertencias.

## Alcance

Este parser es deliberadamente especifico de Albion. Localiza las cabeceras bilingues y conoce la equivalencia de las columnas de talla, pero no debe usarse para documentos de otros proveedores sin crear otro adaptador.

