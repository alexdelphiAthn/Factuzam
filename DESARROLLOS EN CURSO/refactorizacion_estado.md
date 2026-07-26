# Estado de la refactorización Factuzam — hecho vs. pendiente

Fecha: 26/07/2026. Referencia: `refactorizacion_pendiente.md` (auditoría) y
`refactorizacion_fase0_fase1_plan.md`.

## HECHO (compilado 0 errores, regresión de datos 20/20)

| Fase | Contenido | Evidencia |
|---|---|---|
| 0 completa | Ciclo de 44 unidades desarmado (44→14): uses muertos, `ofrmMto2`, casts, `WM_FREECONTROL` | fase0_pruebas.md |
| 1 completa | Borrado de factura atómico; albarán-desde-pedido (venta) transaccional; materialización sin excepts silenciados; movimientos atómicos + índice único FC/VE (script idempotente); totales sin silenciar + fix; try/finally y Sleep(0) | 4 docs resultados + 4 test_*.py |
| 2 completa | `inLibImpuestosComun` (14 funciones); modal remesas único; fusión `CrearAlbaranDesdePedido`; conversión IVA única + fix `AsInteger` (~875 líneas duplicadas menos) | 4 docs resultados |
| 3 (2 de ~5) | Validación de cabecera sin tocar UI; `TdmFacturas` sin `uses` del form (12 refs → 0) | 2 docs resultados |

Validación acumulada: **96 comprobaciones de datos** (58 + 38 de compras)
y **26 en pantalla**, 0 fallos. Documentos: `pruebas_funcionales_resultados.md`,
`pruebas_compras_resultados.md`, `pruebas_ui_resultados.md`.

Git: consolidado en `main` (commit `2561a179`, 26/07/2026) — incluye
`inLibImpuestosComun.pas` y la baja de `inMtoModalCargarEfectosRemesaVenta.*`.

Pendiente TUYO sobre lo hecho: aplicar `movimientos_indice_unico_fcve.sql`
a la BBDD real (tras la consulta de duplicados), ejecutar si quieres
`limpiar_datos_prueba_ui.sql` en desarrollo, borrar definitivamente
`_to_delete/inMtoModalCargarEfectosRemesaVenta.*`, y la pasada de pantalla
que quedó a medias (compras y bloque A) cuando vuelvas a dar permiso de
control del escritorio.

## PENDIENTE de la auditoría (por orden de valor/riesgo sugerido)

> **El plan de ejecución de todo lo que sigue está en
> `refactorizacion_plan_pendiente.md`** (26/07/2026), con cifras medidas
> sobre el código commiteado y plan de pruebas por bloque. La lista de
> abajo se queda como índice de la auditoría.

### A. Arreglos puntuales cortos — **HECHO** (ver `refactorizacion_bloqueA_resultados.md`)

1. **AV latente**: `ExistePeriodoUnico` (`inLibtb`) usa un `TClientDataset`
   local SIN inicializar a nil que solo se crea en una rama; los `Assigned`
   posteriores leen basura de pila. (Auditoría §6.6)
2. **Fugas**: `FCamposGuiaTabla`/`FColumnasVisiblesGuia` sin liberar en
   `TfrmMtoGen.Destroy`; `oInfGuiasCache` creada dos veces y nunca liberada
   en `inMtoPrincipal` (fuga por re-login); `oMemoSQL` puntero colgante
   potencial al cerrar (`inLibLog`).
3. **`inLibFormManager`**: `FreeAndNil` de forms dentro de un handler de
   mensaje → usar `Release` (relacionado con AVs al cerrar pestañas con
   carga async).
4. Cast sin `is` en `TfrmMtoGen.CrearTablaPrincipal` (§3.1).
5. Timeout de tareas que "abandona" `TdmBase` y `TUniConnection` sin liberar
   (acumula conexiones con servidor lento) — al menos registrar/limitar.

### B. Resto de Fase 3 — desacoplar (bloques medianos)

6. **Registro de pantallas por clase**: sustituir el RTTI-por-string de
   `inLibShowMto` (`ctx.FindType(UNITF_WINF)`) y el `NewInstance` de
   `CrearDataModule` por auto-registro en `initialization`. Elimina la
   fragilidad typo-en-BBDD→error-runtime y la sincronía manual del .dpr.
7. **Handler único de menú** en `inMtoPrincipal` (52 OnClick clones) usando
   `oFzaWinf.CallRegistrado`. Baja el fan-out 48 del form principal.
8. **Ciclos Mto↔Modal↔UniData restantes**: facturas/clientes/empresas (8),
   devoluciones compra (5), albaranes compra (5), familias/tarifas (4),
   pedidos compra (3) — patrón: el modal recibe lo que necesita por
   constructor, no usa al Mto que lo abre.
9. `inLibShowMto`: identidad de ventana por caption → clave en Tag; SQL de
   facturas fuera del abridor; `IVentanaCerrable` para que FormManager no
   conozca `TfrmMtoGen`.
10. **Codificar la regla en `LIBRO_DE_ESTILO_DELPHI.md` §16**: "ninguna
    unidad `inLib*`/`UniData*` usa unidades `inMto*`".

### C. Estado global restante (medio)

11. `inLibGlobalVar`: migrar `oLicenciaAplicacion*` (4), `oNomImpresoraCaja`,
    `oCerrandoApp`, `oLogSesion`, `oMemoSQL` a las interfaces ya existentes
    (`IParametros*`, `IContextoSesion`, monitor SQL). La infraestructura de
    inyección de `TfrmBase` ya está.
12. `inMtoLogon`: credenciales (`sPass`, `sPassEn`, `sUserPassOK`) fuera de
    variables globales de interface.

### D. Fase 4 — las clases dios (grande, por fascículos)

13. Extraer de `TfrmMtoGen` (3.239 loc): filtros guardados, perfiles de
    pantalla, guías de grid, tareas+overlay, dominio artículos, diagnóstico.
14. **`TfrmMtoDocumentoBase`** para la familia Facturas/FacturasCompra/
    Albaranes/Pedidos (~1.100-1.400 líneas clonadas — la mayor duplicación
    restante del proyecto).
15. Partir `inLibtb` (9 dominios, 42 dependientes; duplica `inLibIBAN`).
16. Trocear los 37 métodos >200 líneas (empezar por
    `MaterializarSesion`/`RevertirMaterializacion`).
17. Unificar los dos motores fiscales de venta (`TFacturaTotales` vs
    `CalcularTotalesDocumentoVenta`).

### E. Robustez/varios anotados sin bloque asignado

18. **SQL concatenado con variables sin parámetros: 54 ocurrencias en 26
    ficheros** (auditoría) — pasar a parámetros; es también higiene de
    seguridad.
19. Sacar `GenerarMovimientosSalidaFactura` del `AfterPost` al flujo de
    consolidación (decisión con la caja delante; comentario ya en el código).
20. Variantes locales de `CampoFloat` en `inLibDocCompraExcel` y
    `inLibFacturae` → converger sobre la común.
21. Rendimiento del recálculo de líneas (cachear `TField`, separar línea vs
    agregados) — se nota con 200+ líneas.
22. **Proyecto DUnitX**: las piezas ya extraídas (impuestos, conversión IVA,
    helpers) son testeables sin UI ni BBDD; es la red de seguridad de todo
    lo que queda.
23. Normalizar EOLs mixtos CRLF/LF (contra §1.9 del libro de estilo) en una
    pasada git aparte, sin mezclar con cambios funcionales.
24. Nota colación: los SP de movimientos fallan si la BBDD se crea con
    colación ≠ `utf8mb4_spanish_ci` — fijar en instalador o en los SP.

## Sugerencia de secuencia

Detallada en `refactorizacion_plan_pendiente.md`. En corto: terminar el
desacoplamiento (B) → estado global (C) → **DUnitX (22) antes de tocar
las clases dios** → D por fascículos cuando toques cada zona, con la
regla B.10 y su script evitando regresiones de acoplamiento → E en ratos
sueltos.

Siguiente paso recomendado: **bloque B1** (medio día) — 8 `uses` muertos
y 18 data modules que suben al formulario a por `dsTablaG`. Quita 26 de
las 33 infracciones y desarma el ciclo de 18 unidades.
