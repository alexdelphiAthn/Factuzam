# Fase 3 — Bloque B4: cierre de dependencias Mto (resultados)

Fecha: 27/07/2026. **Compilado Release/Win64: 0 errores** (307.334
líneas, 11,59 s). Sin commit.

## Ajuste del alcance real

El plan original enumeraba tres ciclos de impresión de compras:
Devoluciones, Albaranes y Pedidos. Esos ciclos ya habían desaparecido como
efecto de B1: sus data modules reciben el maestro desde el formulario y ya no
usan ninguna unidad `inMto*`. Los modales de impresión reciben los data
modules, la serie y el número sin conocer al mantenimiento que los abrió.

Por tanto, B4 se ha aplicado a las dependencias de capa que seguían anotadas
al terminar B2 y B3.

## Qué se ha hecho

### 1. Buscador genérico sin dependencia del formulario

`inLibGenBusq` conserva las dos firmas de `TBusquedaUtils`, pero ya no usa
`inMtoGenSearch`. Declara un ejecutor abstracto y `inMtoGenSearch` registra la
implementación visual durante su inicialización.

La creación, configuración y liberación de `TfrmMtoSearch` sigue siendo la
misma. Los llamadores de `TBusquedaUtils` no han cambiado.

`inLibDefaultValues` se ha eliminado del proyecto: no tenía ninguna llamada
ejecutable; solo quedaba una línea comentada en `inMtoFacturasBase`.

### 2. Diálogo de permisos de layout invertido

`inLibLayoutForm` ya no crea `TfrmModalGenImpSave`. Solicita el permiso por
medio de `TSolicitudPermisoLayout`; el modal registra el ejecutor visual.
Se mantienen las APIs `PreguntarYGrabar` y `ResetearLayout`, por lo que sus
llamadores no cambian.

### 3. Distribuidor de tallas por contrato

`inLibColumnasSkuModoTallas` ya no conoce `TfrmModalDistribuidor`.
Empaqueta tabla, campos, documento, línea y conjunto pivote en
`TParametrosDistribuidorTallas`. El modal recibe esos parámetros mediante el
ejecutor registrado y devuelve únicamente si se confirmó.

La recarga de cantidades, totales y grid permanece en la librería, en el mismo
orden que antes.

### 4. Previews neutrales

Se ha añadido `inLibPreviewTicket`, contrato único para imprimir o
previsualizar tickets. `inMtoPreviewTicket` registra la implementación visual.

Se han migrado los seis consumidores directos:

- `inLibGenerarTicket` e `inLibGenerarTicketBD`.
- `inLibArqueoTicket`, `inLibGenerarTicketCaja`,
  `inLibTiraCajaTicket` e `inLibTraspasoTicket`.

Las llamadas a `ImprimirOPrevisualizarTicket` conservan su firma.

También se ha añadido `inLibPreviewExcel`. La tira de caja prepara la misma
hoja DevExpress sobre una sesión neutral; `inMtoPreviewExcel` aporta y registra
la ventana, el nombre de archivo y la visualización modal.

### 5. Propiedades de artículos en su capa correcta

La unidad que contiene `TfrmSelPropiedades` y `TfrmPropPorUnidad` se ha movido
de `src/Lib/inLibArticulosPropiedades.pas` a
`src/Modals/inMtoModalArticulosPropiedades.pas`. `inMtoArticulos`, el `.dpr`
y el `.dproj` apuntan al nombre nuevo.

### 6. Acoplamiento oculto de Caja

La compilación detectó tres casts vivos de `UniDataCaja` a
`TfrmMtoOpeCaja` para obtener `tvLineasOpe`. Se han sustituido por
`OnRecalcularLineas`: el data module avisa y el formulario ejecuta
`GridRecalc` con su grid. El orden de los eventos `AfterPost` y `AfterDelete`
no cambia.

### 7. Regla comprobable

`LIBRO_DE_ESTILO_DELPHI.md` §16 prohíbe ya que una unidad `inLib*` o
`UniData*` use una unidad `inMto*`.

El script `scripts/comprobar_dependencias_capas.ps1` revisa todas las unidades
propias y falla si aparece una dependencia nueva. Resultado actual:

```text
Dependencias de capa: OK.
```

No quedan excepciones ni dependencias permitidas por lista blanca.

## Verificación realizada

- Release/Win64: 0 errores.
- Comprobador de capas: OK.
- `git diff --check`: sin errores.
- Referencias a `inLibDefaultValues` e `inLibArticulosPropiedades`: 0.
- Archivos Pascal tocados: UTF-8 con BOM y CRLF.
- Líneas añadidas: ninguna supera 80 columnas.
- `factuzam_original.sql`: sin cambios.

## Pruebas funcionales pendientes

1. Abrir búsquedas genéricas desde Albaranes, Pedidos, Facturas y Caja;
   aceptar y cancelar.
2. Guardar y resetear un layout; comprobar usuario, grupo y grupo raíz.
3. Abrir el distribuidor de Compras Sesiones, confirmar y cancelar.
4. Imprimir un ticket real, abrirlo con impresora `DEBUG` y generar solo PDF.
5. En Artículos, añadir una propiedad y editarla por color/SKU.
6. En Caja, añadir, modificar y borrar líneas; cargar depósitos y comprobar
   que total y grid se recalculan.
7. Imprimir etiquetas y documentos horizontal/vertical desde Albaranes,
   Devoluciones y Pedidos de compra.

Con esas pruebas de pantalla queda cerrada la Fase 3 completa.
