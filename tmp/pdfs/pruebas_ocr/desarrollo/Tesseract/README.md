# ExtraerPedidoTesseract

Aplicación de consola Delphi 13 para convertir pedidos PDF al JSON estructurado
usado por el intérprete de pedidos, sin Azure y sin conexión a Internet. El
proveedor se detecta en el OCR y se aplica un parser Tesseract independiente.

Parsers disponibles:

- `parsers\albion\AlbionTesseractParser.pas`
- `parsers\anita\AnitaTesseractParser.pas`
- `parsers\aznar\AznarTesseractParser.pas`
- `parsers\guasch\GuaschTesseractParser.pas`
- `parsers\puntoblanco\PuntoBlancoTesseractParser.pas`
- `parsers\rasdemar\RasdemarTesseractParser.pas`

El ejecutable Win64 contiene en sus recursos:

- PDFium 153.0.7988.0 para renderizar cada página del PDF.
- Tesseract 5.5.3 y Leptonica 1.87.0.
- Las DLL nativas auxiliares mínimas.
- Los modelos `spa+eng`.

En el primer uso, el recurso comprimido se extrae y se conserva en
`%LOCALAPPDATA%\AlbionTesseract\runtime-2026.08.06.2`. No se instala ningún
servicio ni se modifica el sistema.

## Uso

```bat
bin\Win64\ExtraerPedidoAlbionTesseract.exe "pedido.pdf"
```

La salida predeterminada es:

```text
pedido.tesseract.pedido.json
```

Opciones:

```text
--output <archivo.json>  Selecciona la salida.
--debug-dir <carpeta>    Conserva los TIFF y los TXT/TSV de las dos pasadas OCR.
--force                  Sobrescribe una salida existente.
--help                   Muestra la ayuda.
```

Ejemplo completo:

```bat
bin\Win64\ExtraerPedidoAlbionTesseract.exe ^
  "C:\DISCO_DURO\proyectos\PruebasOCR\CamScanner 6-8-26 17.51.pdf" ^
  --output "resultado.json" ^
  --debug-dir "diagnostico" ^
  --force
```

## Proceso automático

1. `TPdfToTiff` abre el PDF con PDFium y produce un TIFF independiente por
   página a 300 DPI.
2. Tesseract ejecuta `PSM_AUTO` para reconstruir la tabla.
3. Ejecuta `PSM_SPARSE_TEXT` para recuperar campos aislados y totales.
4. `TPedidoTesseractParser` detecta el proveedor y delega en su parser.
5. El parser combina las pasadas `AUTO` y `SPARSE`, normaliza números y valida
   cantidades e importes.
6. Cada línea con foto incluye `codigo_foto`, estable y único por pedido.
7. El mismo ejecutable extrae las fotos con PDFium en la carpeta `fotos`, junto
   al JSON. El nombre del PNG es exactamente `<codigo_foto>.png`.

El texto del pedido siempre procede de Tesseract. La capa de texto interna del
PDF no se usa como alternativa ni para corregir el resultado.

## Fotos temporales

No requieren un segundo comando ni Python. El ejecutable las obtiene del PDF
con PDFium y crea automáticamente una carpeta `fotos` junto al JSON. Cada
archivo se denomina con el valor de `codigo_foto`, por ejemplo
`AZNAR-037-210-001.png`. Junto al JSON se crea también un archivo
`<salida>.fotos.json` con la relación entre código, archivo, modelo y página.
Las líneas promocionales sin foto usan `null`.

Con el PDF de prueba se han verificado 8 modelos, 55 unidades, 2.172,85 EUR y
`validacion.cuadra=true`.

## Compilación

Requiere Delphi 13 / Studio 37 y destino Win64:

```bat
build-win64.cmd
```

El script recompila `resources\EmbeddedRuntime.res` y genera:

```text
bin\Win64\ExtraerPedidoAlbionTesseract.exe
```

Para actualizar las DLL o los modelos:

1. Sustituir los archivos en `resources\runtime`.
2. Regenerar `resources\ocr-runtime.zip` manteniendo como raíz `bin`,
   `tessdata`, `licenses` y `runtime.info.txt`.
3. Incrementar `CRuntimeVersion` en `src\EmbeddedOcrRuntime.pas`.
4. Ejecutar `build-win64.cmd`.

## Código y limitaciones

- El código de aplicación, integración, parser y componente PDF está escrito
  en Delphi/Pascal.
- El motor OCR y el rasterizador son DLL nativas C/C++; por tanto, el conjunto
  no es un motor 100 % Pascal.
- Cada parser está especializado en las coordenadas y reglas de su proveedor.
- Un diseño nuevo debe añadirse en `parsers\<proveedor>` y registrarse en
  `src\PedidoTesseractParser.pas`.
- En equipos que no lo tengan, puede ser necesario Microsoft Visual C++
  Redistributable 2015-2022 x64.

Consulta `THIRD-PARTY-NOTICES.md` y `resources\runtime\licenses` para las
licencias de los componentes incluidos.
