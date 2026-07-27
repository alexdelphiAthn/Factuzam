# Fase 6 (D1) — revisión externa de atributos y modos comunes

Fecha: 27/07/2026. Revisión en frío del estado actual del árbol (sin
commit), centrada en `inLibColumnasDocumento`, `inLibValidacionDocumento`,
`inLibPresentacionDocumento` y los seis formularios de documentos que
delegan en ellas. Método: cruce contra el esquema del dump modelo,
comparación línea a línea contra el código anterior en git (HEAD) y
checks mecánicos de estilo.

## Veredicto

**Está muy bien.** No he encontrado ningún error funcional. La extracción
es fiel al comportamiento anterior en todos los puntos que he comparado,
y las particularidades de cada documento están conservadas a propósito,
no perdidas. Solo hay una corrección menor de estilo y dos cosas
pendientes de ejecutar (abajo).

## Qué se ha verificado (y ha salido limpio)

**Campos derivados contra el esquema: 104/104.** Todos los nombres que
las factorías componen por prefijo (`SERIE_<CAB>_<LIN>`,
`ID_FILA_<CAB>_<CEL>`, `ATTRn_VALOR_<LIN>`, `ESPIVOTE_HORIZONTAL_<CAB>`,
tablas `fza_<doc>_compra_lineas/celdas`…) existen en
`factuzam_original.sql` para los cuatro juegos de prefijos
(PEDC/ALBC/DEVC/FACC). También los especiales:
`CANTIDAD_RECIBIDA_PEDCLIN`, `CANTIDAD_A_RECIBIR_PEDCLIN`,
`PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN`.

**Fidelidad contra el código viejo (git HEAD), método a método:**

- `PuedeActivarTallasHorizontalCompra`: mismo orden de guardas, mismo
  SQL (byte a byte salvo la parametrización), mismos mensajes — las
  constantes de `inLibMsg` reproducen los literales viejos con sus `%s`
  en el sitio correcto.
- `AsegurarCabeceraPersistidaDocumento`: equivalencia exacta con las DOS
  variantes históricas. La compra cancelaba la línea vacía solo sin
  número (capturado en `CancelarLineaSoloSinNumero=True`); la venta la
  cancelaba siempre que publicara y la RECREABA después (capturado en
  `RecrearLineaVacia=True`). El flag `ESPIVOTE_HORIZONTAL` a 'N' en el
  primer Post se conserva. La validación específica se inyecta como
  callback en el mismo punto del flujo (cliente en pedidos de venta,
  almacén de salida en devoluciones).
- `TextoProveedorDocumento`: las tres ramas (razón social sola, nombre
  ≠ razón con paréntesis, iguales) y el «(proveedor no encontrado)»,
  idénticas.
- Captions de modo: el espacio final de albaranes/devoluciones/facturas
  y el acelerador `&1_` se conservan; pedidos mantiene la distinción
  «Tallas horiz.» / «Tallas horiz. bandas» vía `AUsaBandasSeparadas`.
- Columnas de talla y atributo: Tag positivo/negativo, anchos por
  formulario (pedidos `ANCHO_TALLA_PX`, resto 50), `AtribGetDataText`
  solo en pedidos — todo como antes.
- Teardown del modo: los mismos 6 eventos a nil, en el mismo orden
  relativo a `Desmontar`/`ClearItems`; pedidos conserva en local sus dos
  referencias extra (`FColColorProveedorPivot`, `colLineaPedcARecibir`).
- Atributos globales: SQL idéntico (`COALESCE(NOMBRE_VA, ID_ATB_VA)`,
  `LIMIT 5`) y mismo emparejamiento por Tag.
- Configs del pivote de bandas: campo a campo igual que el bloque viejo;
  albaranes re-aplica `BandaUnica=True` + `FieldTotalUdsGrupo` y
  facturas re-aplica el formato moneda `#,##0.00 €` de «Precio compra»
  tras la factoría común — las dos particularidades que la factoría no
  cubre, bien resueltas en el sitio de llamada.

**Coherencia de los 4+2 formularios:** los cuatro de compra rellenan
`TConfigPivoteDocumentoCompra` de forma homogénea, con las diferencias
correctas (`AplicarContextoPivote=False` solo en devoluciones,
`TieneCantidadRecibida` y color de proveedor solo en pedidos). Pedidos y
albaranes de venta usan ya la persistencia común con la variante venta, y
FacturasBase la presentación.

**Estilo y registro:** BOM+CRLF, cero líneas reales >80, cero
Exit/Continue, cero tabuladores en las 3 unidades y los 3 módulos de
prueba nuevos. Unidades registradas en `fzam.dpr`/`.dproj` y
`FactuzamTests.dpr`. La app Release/Win64 compiló limpia hoy a las 18:06
(308.704 líneas) con todo esto dentro.

**Tests:** los casos nuevos están bien elegidos — derivación de campos,
reglas puras con `TClientDataSet` (línea vacía/artículo/sistema de
tallas), persistencia compra Y venta (incluida la recreación de línea), y
el SQL parametrizado.

## Correcciones sugeridas

1. **`Free` → `FreeAndNil`** (convención del repo; el código viejo usaba
   `FreeAndNil`):
   - `inLibColumnasDocumento.pas:450` → `FreeAndNil(oConsulta);`
   - `inLibValidacionDocumento.pas:357-358` → `FreeAndNil(oConsulta);
     FreeAndNil(oIncidencias);`

2. **Ejecutar la batería DUnitX otra vez.** Los binarios de tests son de
   las 11:27 y `PruebasValidacionTallasCompra` (16:31) y
   `PruebasPresentacionDocumento` (16:43) son posteriores: la última
   pasada verde documentada no incluye los ~7 casos nuevos. (La app
   principal sí está compilada con todo.)

3. **Pendientes ya conocidos** (los anotan tus propios docs 6D/6E): la
   comprobación funcional manual con BBDD de los cuatro documentos, y el
   commit del fascículo cuando la cierres.

## Notas (no correcciones)

- `Columnas.ColPrecioCompra` se usa en facturas sin `Assigned`: solo
  sería nil con la vista nil, que aquí no ocurre. Aceptable tal cual.
- `AsegurarPrimeraLineaFacturaCompra` usa 3 `Exit`, pero es código
  previo al fascículo, no de esta extracción.
- Aviso de método: la copia que sirve el puente de ficheros de la sesión
  estaba rancia para los 4 formularios (me llegaban versiones pre-6A);
  la revisión se hizo leyendo el disco real. Los md5 de las unidades
  nuevas sí coincidían por ambas vías.
