# Fase 3, bloque 2 — TdmFacturas divorciado del form (uses eliminado)

Fecha: 26/07/2026. Ficheros: `src/DataModules/UniDataFacturas.pas`,
`src/Forms/inMtoFacturasBase.pas`.

## Qué se ha hecho

Se eliminaron las 12 referencias restantes del data module al form. Con este
bloque, **`UniDataFacturas` ya no tiene `uses inMtoFacturasBase`**: cero
`GetOwnerForm`, cero `TfrmMtoFacturasBase` (solo queda una mención en un
comentario). El ciclo facturas del grafo de dependencias pierde su arista
DM→form.

| Referencia | Solución |
|---|---|
| 6× `MasterSource := (form).dsTablaG` en `DataModuleCreate` | Método público `AsignarMaestroCabecera(ADataSource)`; el form lo llama en `CrearTablaPrincipal` pasando su `dsTablaG` |
| 2× `(form).ActualizarComboSeries` en inserts | Evento `OnSeriesCambiadas: TNotifyEvent`, suscrito por el form |
| `dsLinFacStateChange` manipulando columnas del grid (ReadOnly/Visible s-IVA vs c-IVA) | El cuerpo entero se movió al form (`AplicarEdicionPreciosLinea`); el DM solo dispara `OnLinFacEstado` |
| `(form).TipoFacturaFiltro` en el `AfterInsert` | Property `TipoFacturaDefecto: string`; el form la fija al crear el DM (respeta el virtual de NORMAL/SIMPLIFICADA) |
| `with (form).dmmFacturas.unqryTablaG` en `GetTipoIVA` | `with unqryTablaG do` — era una vuelta absurda: el DM accedía a sí mismo a través del form |

Semántica preservada: los eventos se suscriben en el mismo punto del ciclo de
vida donde antes actuaba el `GetOwnerForm`, y todos los guards `Assigned`
replican el `if not Assigned(Form) then Exit` original.

## Estado de verificación

- Verificación en frío completa: balance `begin`/`end` por método, 0 líneas
  nuevas >80 columnas, hashes local↔disco idénticos.
- **Compilación PENDIENTE**: quedó a medias al interrumpirse el permiso de
  escritorio. Basta doble clic en `compilar_release_win64.cmd` (raíz del
  repo) y mirar `resultado_build_release_win64.txt`, o compilar desde el IDE.
  Si algo fallara, lo más probable serían identificadores del form que
  vinieran implícitamente del uses eliminado — se resuelven añadiendo el
  uses correcto de la unidad que los declare (no el del form).

## Pruebas manuales (además de V1–V6 del bloque anterior)

| # | Prueba | Resultado esperado |
|---|---|---|
| W1 | Abrir Facturas: las pestañas de detalle (líneas, recibos, Verifactu, registro, movimientos) navegan con la cabecera | El maestro-detalle sigue cableado (ahora vía `AsignarMaestroCabecera`) |
| W2 | Insertar factura: el combo de series se refresca al elegir cliente/empresa | Igual que antes (vía `OnSeriesCambiadas`) |
| W3 | Línea con tarifa impuestos-incluidos vs excluidos | La columna de precio editable conmuta igual que antes (s/IVA ↔ c/IVA) |
| W4 | Factura desde form NORMAL y desde SIMPLIFICADA | `TIPO_FAC` correcto en cada caso (`TipoFacturaDefecto`) |

## Fase 3 — progreso

1. Validación sin tocar UI — hecho, compilado. 2. DM sin `uses` del form —
hecho, compilación pendiente. Próximos candidatos: registro de pantallas por
clase (sustituir RTTI-por-string de `inLibShowMto`), handler único de menú en
`inMtoPrincipal`, y los ciclos Mto↔Modal↔UniData restantes.
