# Plan de refactorización — Fase 0 (romper el ciclo) y Fase 1 (robustez de datos)

Plan operativo, paso a paso, para las dos primeras tareas de
`refactorizacion_pendiente.md`. Elegidas por relación valor/riesgo: la Fase 0
desarma el ciclo de 44 unidades sin cambiar comportamiento; la Fase 1 corrige los
riesgos reales de integridad de datos en producción. Ninguna de las dos exige
tocar la jerarquía de formularios ni el esquema (salvo un índice, con script
idempotente aparte).

Convenciones respetadas: español, sin `Exit`/`Continue` nuevos, `if`/`while` en dos
líneas, `FreeAndNil`, cambios de esquema solo como script idempotente en
`DESARROLLOS EN CURSO/`, sin tocar `factuzam_original.sql`, sin commit ni push
hasta que lo pidas.

---

## Preparación (antes de tocar nada)

1. Compilar `fzam.dproj` y guardar el resultado como referencia (0 errores, N hints).
   Cada paso de este plan termina con "compila y los hints no crecen".
2. Definir el smoke test manual mínimo (10 min) que se repetirá tras cada bloque:
   - Logon → abrir Clientes, Artículos, Facturas, Pedidos de compra.
   - Crear factura con 2 líneas → grabar → consolidar → borrar.
   - Abrir dos pestañas del mismo Mto ("Clientes" y "Clientes 2") y cerrarlas.
   - Crear albarán desde pedido de compra (flujo sesiones si aplica).
3. Rama de trabajo `claude/refactor-fase0-<id>` (según convención del CLAUDE.md).

---

## FASE 0 — Cortar el ciclo de 44 unidades (estimación: 1 día)

Regla que se instaura al acabar: **ninguna unidad `inLib*` ni `UniData*` usa
unidades `inMto*` en su `interface`**. Los pasos van de menor a mayor contacto.

### 0.1 Borrar los `uses inMtoPrincipal` muertos de 9 data modules  [5 min/fichero]

Ninguno de estos ficheros referencia ningún símbolo de `inMtoPrincipal`
(verificado por grep). Quitar el identificador de la cláusula `uses` de interface:

| Fichero | Línea |
|---|---|
| `DataModules/UniDataFacturas.pas` | 22 |
| `DataModules/UniDataPedidos.pas` | 23 |
| `DataModules/UniDataAlbaranes.pas` | 23 |
| `DataModules/UniDataClientes.pas` | 22 |
| `DataModules/UniDataDevolucionesCompra.pas` | 27 |
| `DataModules/UniDataPedidosCompra.pas` | 30 |
| `DataModules/UniDataComprasSesiones.pas` | 23 |
| `DataModules/UniDataAlbaranesCompra.pas` | 28 |
| `DataModules/UniDataFacturasCompra.pas` | 29 |

Verificación: compila; buscar `inMtoPrincipal` en cada fichero devuelve 0.

### 0.2 Borrar `ofrmMto2` y liberar `inLibGlobalVar`  [15 min]

- `Lib/inLibGlobalVar.pas:37`: borrar `ofrmMto2 :TfrmMtoPrincipal;`.
- `Lib/inLibGlobalVar.pas:19`: borrar `inMtoPrincipal` del `uses` de interface.
- `Core/inMtoPrincipal.pas:761`: borrar la asignación `ofrmMto2 := Self;`.

Es la arista central del ciclo: ~21 unidades dejan de arrastrar la UI completa.
Verificación: compila; `grep ofrmMto2` en el árbol devuelve 0.

### 0.3 Borrar globales muertas de `inMtoGen`  [5 min]

`Forms/inMtoGen.pas:384-385`: borrar `sConsultaO` y `sConsultaP` (cero lecturas y
cero escrituras en el proyecto).

### 0.4 `inLibUnitForm` deja de conocer `TfrmMtoPrincipal`  [20 min]

`Lib/inLibUnitForm.pas:102,115,127-128`: el único uso es
`(AOwn as TfrmMtoPrincipal).FindComponent(...)`. `FindComponent` es de
`TComponent`, así que el cast sobra:

```pascal
// antes
frmOpen2 := (AOwn as TfrmMtoPrincipal);
oComp := frmOpen2.FindComponent(...);
// después
oComp := AOwn.FindComponent(...);
```

Quitar `inMtoPrincipal` del `uses`. Verificación: compila; el menú sigue
aplicando permisos (smoke test).

### 0.5 `inLibDevExp.CancelarGrids` recibe el page control, no el form principal  [45 min]

`Lib/inLibDevExp.pas:1109-1121` castea a `TfrmMtoPrincipal` para llegar a
`pcPrincipal` y luego castea la página activa a `TfrmMtoGen` solo para usar
`ComponentCount`/`Components` (miembros de `TComponent`). Cambio:

```pascal
// antes (inLibDevExp.pas:44 y :1109)
procedure CancelarGrids(AoPrincipal: TComponent);
// después
procedure CancelarGrids(ApcPrincipal: TcxPageControl);
```

Dentro: `tsNew := ApcPrincipal.Pages[ApcPrincipal.ActivePageIndex];` y declarar
`frmMto: TComponent` (basta para el bucle de `Components[i]`). Quitar
`inMtoPrincipal` e `inMtoGen` de los `uses` (líneas 31 y 108).

Llamantes (los dos en `Forms/inMtoGen.pas:2286` y `:2833`):

```pascal
CancelarGrids((Owner as TfrmMtoPrincipal).pcPrincipal);
```

(`inMtoGen` ya usa `inMtoPrincipal` en implementation, así que no se crea
dependencia nueva; el comentario de `:2836` sobre el `EInvalidCast` deja de
aplicar porque el cast se hace en el llamante, que sí sabe quién es su Owner.)

### 0.6 Unificar `WM_FREECONTROL`  [20 min]

Hoy hay dos definiciones con valores distintos: `Core/inMtoPrincipal.pas:56`
(`WM_USER`, incorrecta, nadie la escucha) y `Forms/inMtoGen.pas:623`
(`WM_USER + 1`, la que funciona). Además el handler está declarado con el literal:
`inMtoPrincipal.pas:254` (`message WM_USER + 1`).

- Declarar una sola vez, p. ej. en `Lib/inLibWin.pas` (interface):
  `const WM_FREECONTROL = WM_USER + 1;`
- `inMtoPrincipal.pas:56`: borrar la constante local; `:254`: usar
  `message WM_FREECONTROL`.
- `inMtoGen.pas:623`: borrar la constante local; el `PostMessage` de `:652` queda igual.

Verificación: cerrar pestañas con el botón Salir de un Mto sigue funcionando.

### 0.7 Comprobación final de la fase  [30 min]

Volver a generar el grafo de `uses` (script disponible; pedídmelo y lo dejo en
`DESARROLLOS EN CURSO/`) y confirmar que el SCC grande quedó por debajo de ~10
unidades y que ya no contiene ningún `UniData*` ni `inLib*`. Smoke test completo.

Quedan para más adelante (Fase 3, no bloquean): los ciclos pequeños
Mto ↔ Modal ↔ UniData (facturas/clientes/empresas, devoluciones, albaranes compra,
familias/tarifas) y el `uses inMtoFacturasBase` en implementation de
`UniDataFacturas.pas:216`.

---

## FASE 1 — Robustez de datos (estimación: 1 semana)

Objetivo: que un corte de red, un error SQL o dos usuarios simultáneos no dejen
datos a medias. Patrón de referencia: el idiom `bTransPropia` que ya usa
`UniDataAlbaranes.pas:1715`:

```pascal
bTransPropia := not Conn.InTransaction;
if bTransPropia then
  Conn.StartTransaction;
try
  // ... pasos ...
  if bTransPropia then
    Conn.Commit;
except
  on E: Exception do
  begin
    if bTransPropia then
      Conn.Rollback;
    GrabarLog(...);  // según §19 del libro de estilo
    raise;
  end;
end;
```

### 1.1 Borrado de factura en transacción  [medio día]

`DataModules/UniDataFacturas.pas:2212-2337`: hoy borra efectos, recibos, líneas y
movimientos en 4 pasos sueltos. Envolver la secuencia completa en el idiom
`bTransPropia`. Además, `qryBorrarLineas` (`:2290-2306`) y `qryBorrarRecibos`
(`:2307-2322`) usan `with TUniQuery.Create ... Free` sin protección: pasar a
`try/finally` con `FreeAndNil`.

Prueba: provocar un fallo a mitad (p. ej. renombrar temporalmente una tabla en una
BBDD de pruebas) y comprobar que la factura queda íntegra.

### 1.2 Movimientos de almacén: transacción + salida del `AfterPost`  [1 día]

`DataModules/UniDataFacturas.pas:2672-2838` (`GenerarMovimientosSalidaFactura`):

1. Envolver el bucle de `ExecProc` + `UPDATE NUMERO_MOV_FACLIN` en transacción.
2. Sacar la llamada del `unqryFacAfterPost` (`:2101-2122`) al flujo explícito de
   consolidación (donde ya se decide la fase del documento), para que no se
   dispare en cada grabación intermedia.
3. La protección anti-duplicados hoy es un `SELECT ... LIMIT 1` sin bloqueo
   (`:2712-2727`): dos puestos grabando a la vez pueden duplicar movimientos.
   Complemento en BBDD → paso 1.6.

### 1.3 `CrearAlbaranDesdePedido` con transacción (simetría con albaranes)  [medio día]

`DataModules/UniDataPedidos.pas:1582-1700`: encadena 3 `ExecProc` (cabecera,
líneas, actualización del pedido) sin transacción. Aplicar el mismo idiom
`bTransPropia` que ya usa `UniDataAlbaranes.pas:1715`. Lo mismo aplica a las dos
variantes grandes de `Lib/inLibPedidosCompra.pas` (`:443` y `:794`) si no la abren
ya en el llamante (comprobar primero con quien las invoca desde sesiones).

### 1.4 Dejar de silenciar el fallo de totales  [medio día]

Cadena actual: `ProcesarFacturaCompleta` captura todo y devuelve `False`
(`Lib/inLibFacturas.pas:890-916`) → `Lib/inLibtb.pas:434-440` ignora el `Result` →
`UniDataFacturas.pas:626-667` solo hace `ShowMessage`. La factura puede grabarse
con totales a 0.

- En `inLibtb.pas:434-440`: comprobar el resultado y, si es `False`, `raise` con
  mensaje claro (aborta el Post).
- En `inLibFacturas.pas:890-916`: registrar la excepción original en el log antes
  de devolver `False` (hoy se pierde la causa).

Prueba: forzar un error en el cálculo (IVA inexistente) y verificar que el Post
se aborta con mensaje y sin grabar.

### 1.5 `except` vacíos de la materialización → log de avisos  [1 día]

`Lib/inLibComprasSesionesMaterializar.pas` tiene 8 `except` que tragan errores;
los dos completamente vacíos son `:2555-2556` y `:2693-2694`. El de `:2555` es
crítico: su propio comentario (`:2541-2547`) explica que si ese DELETE falla, una
re-materialización duplicaría documentos.

Cambio mínimo sin reestructurar los métodos todavía (eso es Fase 4):

```pascal
except
  on E: Exception do
  begin
    GrabarLog('RevertirMaterializacion paso 0j-bis: ' + E.Message);
    AAvisos.Add('No se pudo limpiar fza_compras_sesiones_documentos: ' +
                E.Message);
  end;
end;
```

con `AAvisos: TStrings` como parámetro nuevo (o lista en el resultado) que el
llamante muestra al usuario al terminar. Separar el caso "la tabla no existe en
BBDD legacy" comprobándolo una vez al principio con `INFORMATION_SCHEMA.TABLES`,
no tragándolo en cada paso.

### 1.6 Índice único de movimientos (script idempotente)  [1 hora + ventana de aplicación]

Único cambio de esquema de todo el plan. Crear
`DESARROLLOS EN CURSO/movimientos_indice_unico.sql`, idempotente vía
`INFORMATION_SCHEMA.STATISTICS` (patrón de `proveedores_nombre.sql`), que añada un
índice único sobre la identidad del movimiento de documento en
`fza_movimientos_almacen` (columnas exactas a confirmar contra el esquema:
tipo de documento + serie + número + línea).

**Antes de aplicarlo**: ejecutar el SELECT de duplicados existentes (el script debe
incluirlo comentado) — si hay históricos duplicados, decidir limpieza contigo.
Después, en `GenerarMovimientosSalidaFactura`, tratar la violación de clave como
"ya generado" (idempotencia real en vez del `SELECT ... LIMIT 1`).

### 1.7 Fugas rápidas de la misma zona  [1 hora]

Ya que se toca `UniDataFacturas.pas`: `try/finally` en `BuscarCliente`
(`:600-624`) y `CalcularRetencionesEmpresa` (`:670-700`), y sustituir el
`Sleep(0)` de `:691` por la condición invertida.

---

## Orden recomendado y criterios de "hecho"

| Orden | Paso | Riesgo | Hecho cuando... |
|---|---|---|---|
| 1 | 0.1–0.3 | Nulo | Compila, greps a 0, smoke test OK |
| 2 | 0.4–0.6 | Bajo | Compila, cerrar pestañas y menú OK |
| 3 | 0.7 | — | SCC < 10 unidades, sin `UniData*`/`inLib*` dentro |
| 4 | 1.4 | Bajo | Error de totales aborta el Post con mensaje |
| 5 | 1.1 | Medio | Borrado atómico verificado con fallo provocado |
| 6 | 1.3 | Medio | Albarán desde pedido atómico |
| 7 | 1.5 | Medio | Avisos visibles; revertir ya no traga errores |
| 8 | 1.2 + 1.6 | Medio-alto | Movimientos transaccionales + índice único aplicado en BBDD de pruebas |
| 9 | 1.7 | Nulo | Compila |

Cada bloque = una revisión tuya antes de seguir (sin commits hasta que lo pidas).
La Fase 0 entera es revertible fichero a fichero; en la Fase 1 el único cambio no
revertible con git es el índice (1.6), por eso va al final y con script aparte.

## Qué NO hacer todavía (aunque tiente)

- No unificar `GridPivoteCompra`/`GridPivoteVenta` (diseños distintos; ver auditoría §5).
- No partir aún `inLibtb` ni `TfrmMtoGen` (Fase 4: mucho contacto, poco urgente).
- No cambiar el mecanismo RTTI de `inLibShowMto` (Fase 3; requiere plan propio).
- No reordenar `uses` "de paso" en ficheros que no se tocan: cada paso cambia lo
  mínimo para poder revisar el diff en segundos.
