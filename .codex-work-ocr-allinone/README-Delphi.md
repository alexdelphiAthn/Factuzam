# Interprete Delphi completo del pedido Albion

Programa de consola especifico para el formato `PRE-PEDIDO / PRE-ORDER` de Albion 1879.

El ejecutable realiza el proceso completo:

1. Selecciona el PDF.
2. Lo envia a Azure Document Intelligence con `prebuilt-layout`.
3. Espera el resultado asincrono de Azure.
4. Guarda el JSON tecnico de OCR.
5. Interpreta las tablas de Albion.
6. Genera el JSON sencillo que puede consumir Factuzam.

No usa PowerShell ni componentes Delphi externos.

## Uso sencillo

Haz doble clic en `ejecutar-interprete.cmd`.

Si solo hay un PDF en la carpeta, se selecciona automaticamente. El lanzador utiliza el archivo de credenciales existente en:

```text
..\factuzam_web\azure.txt
```

La clave no se copia al programa, no se incluye en los JSON y no se muestra por pantalla.

Se generan dos archivos junto al PDF:

```text
<pdf>.azure-ocr.prebuilt-layout.json
<pdf>.azure-ocr.prebuilt-layout.albion-simple.json
```

Si ya existen, el programa crea una version con fecha y hora para no sobrescribirlos. Usa `--force` si deseas sustituir las salidas indicadas.

## Uso por consola

Proceso completo PDF a Azure y a JSON sencillo:

```powershell
.\bin\InterpretarPedidoAlbion.exe '.\pedido.pdf' --config '..\factuzam_web\azure.txt'
```

Indicar salidas concretas:

```powershell
.\bin\InterpretarPedidoAlbion.exe '.\pedido.pdf' `
  --config '..\factuzam_web\azure.txt' `
  --raw-output '.\pedido.azure.json' `
  --output '.\pedido.simple.json' `
  --force
```

Reprocesar un JSON de Azure sin consumir de nuevo el servicio:

```powershell
.\bin\InterpretarPedidoAlbion.exe '.\pedido.azure-ocr.prebuilt-layout.json'
```

Credenciales admitidas:

- Variables `AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT` y `AZURE_DOCUMENT_INTELLIGENCE_KEY`.
- Variables genericas `AZURE_OCR_ENDPOINT` y `AZURE_OCR_KEY`.
- `--config <archivo>`.
- Variable `AZURE_OCR_CONFIG` con la ruta del archivo.
- Un `azure.txt` situado en la carpeta actual.

El formato actual de `azure.txt` con `KEY 1` y `ENDPOINT` es compatible.

## Salida sencilla

- `proveedor`: razon social, direccion, CIF y telefono.
- `referencia_doc`.
- `fecha_pedido`, `fecha_tope` y `fecha_prevista_entrega`, en ISO `YYYY-MM-DD`.
- `detalle`: modelo, descripcion, color, tallas con cantidad, cantidad total, precio unitario mayorista, PVP e importe.
- `totales` y `validacion`.

La validacion comprueba suma de tallas, cantidad por precio, suma de cantidades y suma de importes. Si el formato cambia o el OCR no cuadra, el JSON incluye advertencias.

## Alcance

Este parser es deliberadamente especifico de Albion. El cliente Azure es reutilizable, pero las reglas de interpretacion no deben aplicarse a documentos de otros proveedores. Para otro proveedor se debe crear otro adaptador.

## Compilacion

Abre `InterpretarPedidoAlbion.dproj` en Delphi 13 o compila `InterpretarPedidoAlbion.dpr` para Win32. Las unidades son:

- `AzureDocumentIntelligenceClient.pas`: PDF, autenticacion, POST, `Operation-Location` y polling.
- `AlbionPedidoParser.pas`: interpretacion y validaciones especificas de Albion.

