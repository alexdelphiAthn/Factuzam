# Guión de pruebas — Sistema de fotos por artículo / SKU

Plan de pruebas manual para validar el subsistema documentado en
`LIBRO_DE_ESTILO_DELPHI.md` §18, implementado en la rama
`claude/add-photo-system-sku-1OMev`.

Cubre: alta de fotos, fallback SKU → artículo, naming con índice
incremental, rotación de las tres copias, eliminación, atajo
`Ctrl + Alt + F`, sustitución en FastReports y wrapper modal.

---

## 0. Preparación

**0.1 BBDD** — ejecuta el DDL una sola vez:

```bash
mysql -u root -p factuzam < "DESARROLLOS EN CURSO/fotos_articulos.sql"
```

Verifica:

```sql
SHOW CREATE TABLE fza_articulos_fotos;
SHOW CREATE VIEW  vi_articulos_fotos;
```

**0.2 Build** — compila `fzam.dpr` con Delphi 13. No debe dar errores.
Si el IDE pide reordenar unidades del package list, di que **No** (que
use sólo las del proyecto).

**0.3 Parámetro** — abre Factuzam y entra a *Parámetros de Aplicación*
(`frmMtoAppParam`). En la categoría **Directorios** debe aparecer
`appDirFotos` con valor por defecto `$(PUBLICO)\Factuzam\fotos`, que se
expande a `C:\Users\Public\Documents\Factuzam\fotos` y es accesible
para todos los usuarios de la máquina (lo lógico para un recurso
compartido).

Puedes dejar el valor por defecto o cambiarlo a una ruta compartida en
red (`\\servidor\factuzam\fotos`, etc.). Si quieres una carpeta de
prueba aislada, asigna por ejemplo `C:\Factuzam\fotos`.

Verifica en disco que la carpeta resuelta existe (créala si no). Los
subdirectorios `300/`, `600/`, `real/` se crearán automáticamente con
el primer guardado.

---

## 1. Foto a nivel artículo (sin SKU)

**1.1** Abre *Mantenimiento de Artículos*. Sitúate en `BOLSO-PIEL`
(artículo sin variaciones).

**1.2** Pulsa **Ctrl + Alt + F**. Debe abrirse `frmFotoArticulo`:

- Caption: *Foto del artículo / SKU*
- Etiqueta superior: *Sin foto para BOLSO-PIEL*
- Imagen vacía
- Resolución: **300** seleccionada
- Botones: *Cambiar foto del artículo*, *Cambiar foto del SKU*,
  *Quitar foto*, *Rotar izquierda*, *Rotar derecha*

**1.3** Pulsa **Cambiar foto del artículo**. Elige una imagen grande
(p.ej. 2000×1500 JPG).

- La imagen debe aparecer en pantalla.
- Etiqueta: *Foto del SKU: BOLSO-PIEL* (porque ese artículo tiene un
  solo SKU autogenerado con el mismo código).

**1.4** Verifica en disco — los tres son PNG (el "real" también, con
la resolución original):

```
C:\Factuzam\fotos\300\BOLSO-PIEL_001.png    300 px lado mayor
C:\Factuzam\fotos\600\BOLSO-PIEL_001.png    600 px lado mayor
C:\Factuzam\fotos\real\BOLSO-PIEL_001.png   resolución original como PNG
```

Verifica en BBDD:

```sql
SELECT * FROM fza_articulos_fotos WHERE CODIGO_ART_FOT = 'BOLSO-PIEL';
-- NOMBRE_FOT_FOT        = 'BOLSO-PIEL_001'
-- EXTENSION_ORIGEN_FOT  = 'jpg'
```

**1.5** Cambia el selector a **600** y luego a **Real**. La imagen del
panel debe recargarse con cada cambio (300 borrosa, 600 mejor, real
nítida).

---

## 2. Foto SKU + herencia del artículo

**2.1** Sitúate ahora en `BLUS-SEDA` (artículo con variaciones). Ve a
la pestaña **SKUs** y posiciónate en cualquier SKU,
p.ej. `BLUS-SEDA/BLANCO/L`.

**2.2** `Ctrl + Alt + F`. Etiqueta: *Sin foto para BLUS-SEDA /
BLUS-SEDA/BLANCO/L*. El combo **Nivel al que aplica el cambio** debe
mostrar dos opciones:

- `BLUS-SEDA/BLANCO/L` (seleccionada por defecto, SKU completo)
- `BLUS-SEDA/BLANCO`   (prefijo de grupo)

**2.3** Pulsa **Cambiar foto del artículo** y elige una imagen. Tras
guardar, la etiqueta debe decir *Foto heredada del artículo: BLUS-SEDA*
(la foto está a nivel artículo).

**2.4** Vuelve a `Ctrl + Alt + F` estando en otro SKU del mismo artículo
(`BLUS-SEDA/NEGRO/M`). Debe mostrarse **la misma foto** y etiqueta
*Foto heredada del artículo: BLUS-SEDA*. **← fallback artículo
funcionando.**

**2.5** Estando en `BLUS-SEDA/NEGRO/M`, deja el combo en la opción del
SKU completo (`BLUS-SEDA/NEGRO/M`), pulsa **Cambiar foto del SKU /
grupo** y elige una imagen distinta. La etiqueta debe pasar a
*Foto del SKU: BLUS-SEDA/NEGRO/M*.

**2.6** En disco:

```
real/BLUS-SEDA_001.jpg                 la del artículo
real/BLUS-SEDA_NEGRO_M_001.jpg         la del SKU, '/' saneado a '_'
```

**2.7** Cambia a otro SKU sin foto propia (`BLUS-SEDA/ROSA/M`) y
`Ctrl + Alt + F`: debe heredar la del artículo, no la de `NEGRO/M`.

---

## 2bis. Foto por prefijo de SKU (grupo)

Permite asignar una foto a TODOS los SKUs que compartan un prefijo
(típicamente un color, talla agrupada, etc.). El resolver elige siempre
la coincidencia más específica.

**2bis.1** Sitúate en `BLUS-SEDA/BLANCO/L`. `Ctrl + Alt + F`.

**2bis.2** En el combo **Nivel al que aplica el cambio**, selecciona
`BLUS-SEDA/BLANCO` (la opción del prefijo). Pulsa **Cambiar foto del
SKU / grupo** y elige una imagen distinta de las anteriores.

**2bis.3** Verifica:

```sql
SELECT CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT
  FROM fza_articulos_fotos
 WHERE CODIGO_ART_FOT='BLUS-SEDA';
```

Debe haber una fila con `CODIGO_UNIDAD_FOT = 'BLUS-SEDA/BLANCO'`.

**2bis.4** Sin cerrar la pantalla, en el Mto navega a otro SKU
**del mismo grupo BLANCO**, p.ej. `BLUS-SEDA/BLANCO/M`. La pantalla
flotante debe **auto-refrescarse** y mostrar la foto del prefijo con
etiqueta *Foto heredada del grupo: BLUS-SEDA/BLANCO*.

**2bis.5** Navega ahora a un SKU de otro color, p.ej. `BLUS-SEDA/NEGRO/M`
(el que tiene foto propia del paso 2.5). Debe mostrar **su foto
propia** (etiqueta *Foto del SKU: BLUS-SEDA/NEGRO/M*), porque la
coincidencia exacta gana frente al prefijo.

**2bis.6** Navega a `BLUS-SEDA/ROSA/M` (sin foto propia, sin foto de
grupo ROSA): debe mostrar la del artículo, no la de BLANCO.

**2bis.7** Cambia el combo a `BLUS-SEDA/BLANCO/L` (vuelve al SKU
completo) y pulsa **Quitar foto** desde un SKU del grupo BLANCO. Debe
borrarse la fila del **grupo** (porque era la que estaba resolviendo)
y los SKUs del grupo BLANCO deben volver a heredar la del artículo.

---

## 2ter. Auto-refresh al navegar

**2ter.1** Con la pantalla flotante abierta sobre el Mto de Artículos,
sin cerrarla, navega por la lista de artículos (flechas, click).
La foto debe **cambiar automáticamente** sin tener que volver a pulsar
Ctrl + Alt + F. La etiqueta también se actualiza.

**2ter.2** Para artículos sin foto registrada: la etiqueta debe pasar a
*Sin foto para …* y el panel quedar en blanco.

**2ter.3** Cierra y vuelve a abrir el Mto. Verifica que tu `OnDataChange`
local sigue funcionando (la pantalla restaura el handler previo al
desengancharse).

---

## 3. Naming con índice e incremento

**3.1** Estando en `BOLSO-PIEL` con foto cargada, sube **otra foto
distinta** con *Cambiar foto del artículo*.

**3.2** En disco deben aparecer los nuevos ficheros con índice `002`,
y los `001` **se han borrado**:

```
300/BOLSO-PIEL_002.png    OK
600/BOLSO-PIEL_002.png    OK
real/BOLSO-PIEL_002.jpg   OK
300/BOLSO-PIEL_001.png    ya no existe
```

En BBDD:

```sql
SELECT NOMBRE_FOT_FOT FROM fza_articulos_fotos WHERE CODIGO_ART_FOT='BOLSO-PIEL';
-- 'BOLSO-PIEL_002'
```

**3.3** Sube una **tercera** foto: índice pasa a `003` y los `002` se
borran.

---

## 4. Rotación

**4.1** Con foto cargada en `BOLSO-PIEL`, observa la orientación a
300 px.

**4.2** Pulsa **Rotar derecha**. La imagen debe girar 90° en sentido
horario. Cambia el selector a **600** y luego **Real** — las tres
copias deben estar rotadas exactamente igual.

**4.3** Verifica en disco:

- El fichero anterior (`BOLSO-PIEL_003.*`) ya no existe.
- Aparecen `BOLSO-PIEL_004.*` con la imagen rotada.

```sql
SELECT NOMBRE_FOT_FOT FROM fza_articulos_fotos WHERE CODIGO_ART_FOT='BOLSO-PIEL';
-- 'BOLSO-PIEL_004'
```

**4.4** Pulsa **Rotar izquierda** dos veces. Cada pulsación incrementa
índice. Al final, la imagen debe estar girada 90° en sentido
anti-horario respecto al estado del paso 4.2.

**4.5 Caso especial — rotar foto heredada desde un SKU**:

- Estando en `BLUS-SEDA/ROSA/M` (que hereda del artículo), pulsa
  **Rotar derecha**.
- Se rotan los ficheros del **artículo** padre (`BLUS-SEDA_NNN`), no se
  crea fila de SKU.
- La etiqueta sigue diciendo *Foto heredada del artículo: BLUS-SEDA*.
- El resto de SKUs sin foto propia ven la rotación.

---

## 5. Quitar foto

**5.1** En `BLUS-SEDA/NEGRO/M` (con foto propia de SKU) pulsa
**Quitar foto** → Sí.

- Fichero `real/BLUS-SEDA_NEGRO_M_*.*` borrado en disco.
- Fila SKU borrada en `fza_articulos_fotos`.
- La pantalla pasa a mostrar la foto heredada del artículo (etiqueta:
  *Foto heredada del artículo: BLUS-SEDA*).

**5.2** Pulsa **Quitar foto** otra vez (ahora elimina la del artículo)
→ Sí.

- Ficheros `BLUS-SEDA_*.*` borrados.
- Etiqueta: *Sin foto para BLUS-SEDA / BLUS-SEDA/ROSA/M*.

---

## 6. Atajo Ctrl + Alt + F y refresco

**6.1** Cierra `frmFotoArticulo`. En *Mtto Artículos* sitúate en
`ABRIGO-PAÑO`, pulsa `Ctrl + Alt + F` → se abre con datos de
`ABRIGO-PAÑO`.

**6.2** Sin cerrarla, vuelve al Mto y navega a otro artículo. Pulsa
`Ctrl + Alt + F` de nuevo: la pantalla flotante se trae al frente y se
refresca con el nuevo artículo (no se crea otra ventana).

**6.3** `Ctrl + F12` — verifica que sigue **guardando el tamaño de
ventana** del Mto como siempre (no se ha tocado ese flujo).

---

## 7. FastReports

**7.1** Abre el diseñador de un informe que herede de `TfrmPrint`
(p.ej. imprime una factura y dale a *Editar*).

**7.2** Añade tres `TfrxPictureView` en una banda de datos de líneas (o
en `MasterData`) y nómbralos exactamente:

- `foto300`
- `foto600`
- `fotoReal`

Guarda el informe.

**7.3** Imprime el informe. En cada banda donde las imágenes están,
debe verse la foto del artículo / SKU correspondiente a la fila, en la
resolución indicada por el nombre.

**7.4** Para una fila cuyo artículo no tenga foto registrada: la
imagen debe quedar **en blanco** (no error).

**7.5** Para una fila con SKU que hereda del artículo: debe verse la
foto del artículo padre.

---

## 8. Wrapper modal (opcional, devs)

Desde código de cualquier modal:

```pascal
uses inMtoModalFotoArticulo;
...
TfrmModalFotoArticulo.Ejecutar(Self, 'BOLSO-PIEL', '');
```

Debe abrir la misma pantalla con `ShowModal`, sin `fsStayOnTop`.

---

## 9. Mtos de documentos con sub-grid de líneas

`Ctrl + Alt + F` debe funcionar sobre la **línea activa** del grid de
detalle, no sobre la cabecera del documento. Los cuatro Mtos
implicados ya sobreescriben `ResolverArtSkuActivo`:

| Mto                | Pestaña a probar           | Grid de detalle    |
|--------------------|----------------------------|--------------------|
| `inMtoFacturas`    | Líneas de factura          | `tvLineasFactura`  |
| `inMtoTarifas`     | Artículos                  | `tvArticulos`      |
| `inMtoPedidos`     | Líneas del pedido          | `tvPedidosLineas`  |
| `inMtoAlbaranes`   | Líneas del albarán         | `tvLineasAlbaran`  |

**9.1** En cada uno, posiciónate sobre una línea con artículo conocido
(p.ej. uno al que ya le hayas asignado foto en §1 o §2). Pulsa
`Ctrl + Alt + F`: debe abrirse la pantalla flotante con la foto del
artículo / SKU de esa línea.

**9.2** Navega entre líneas con flechas: la pantalla debe
auto-refrescarse (estamos enganchados al `dsLineas` / `dsArticulos` del
grid, no al `dsTablaG` de cabecera).

**9.3** Si pulsas Ctrl + Alt + F desde la cabecera (registro activo de
cabecera, sin línea con artículo seleccionable) no se abre nada — los
overrides devuelven `''`.

---

## 10. Caja Operaciones — foto embebida

`inMtoCajaOpe` no usa Ctrl + Alt + F. La foto se muestra en un panel
fijo a la derecha del grid de stock (`pnlFotoStock`), siempre cargada
en resolución 300 px.

**10.1** Abre Caja, introduce un código de artículo y graba la línea
(o navega a una línea existente). La foto del artículo / SKU debe
aparecer en el panel a la derecha del grid de stock.

**10.2** Mueve el cursor entre líneas: la foto debe auto-refrescarse
con el artículo de la línea activa.

**10.3** Línea sin artículo aún introducido / sin foto en BBDD: el
panel se queda en blanco (no error).

---

## 11. Consulta de operaciones

`inMtoConsultaOpe` ya tiene Ctrl + Alt + F a mano (no hereda de
`TfrmMtoGen`) sobre la **línea de factura** activa
(`cxViewFacLin`).

**11.1** Abre la consulta, busca una factura con artículos con foto,
posiciónate sobre una línea en la pestaña "Líneas factura". Pulsa
`Ctrl + Alt + F`: debe salir la foto del artículo / SKU de la línea.

**11.2** Navega entre líneas: auto-refresh igual que en el resto.

---

## Limitaciones conocidas

- **Mtos sin sub-grid configurado**: si añades un Mto nuevo con
  artículos en sub-grid y olvidas sobreescribir `ResolverArtSkuActivo`,
  `Ctrl + Alt + F` lee del `dsTablaG` (cabecera) y devolverá `''`.
  Patrón de override en `LIBRO_DE_ESTILO_DELPHI.md` §18.6.
- **FastReports iterativos**: la sustitución se hace una sola vez antes
  de `PrepareReport`. Para informes que iteran filas y necesitan foto
  distinta por banda, hoy se mostrará la del registro activo en el
  momento de preparar el reporte. Para soportarlo bien haría falta
  inyectar scripts + user-function (pendiente, ver
  `fotos_articulos.md`).
- **Concurrencia**: si dos usuarios suben fotos al mismo (art, sku) en
  paralelo, ambos verán índice `N+1` y uno pisará al otro. No hay
  locking de fila — asumir uso normal mono-usuario por artículo.
