# Bloque A — Arreglos puntuales de estabilidad (AV latente, fugas, Release)

Fecha: 26/07/2026. Compilado en tu máquina: **0 errores** (307.665 líneas),
sin hints nuevos. Ficheros: `inLibtb`, `inMtoGen`, `inMtoPrincipal`,
`inLibFormManager`.

## Arreglos

1. **AV latente eliminado** — `ExistePeriodoUnico` (`inLibtb`): `cli` y `Dsp`
   se inicializan a `nil` (los `Assigned()` posteriores leían basura de pila
   cuando la rama de creación no corría → AV intermitente) y el uso del
   ClientDataSet va en `try/finally` (sin fuga si algo lanza a mitad).
   `Dsp` se libera con `cli` (es su Owner) — el free comentado era correcto.
2. **Fuga por pestaña** — `TfrmMtoGen.Destroy` libera `FCamposGuia`,
   `FCamposGuiaTabla` y `FColumnasVisiblesGuia` (goteaban en cada pestaña
   que usara guías/column chooser).
3. **Fuga por re-login + doble creación** — `oInfGuiasCache` y
   `oConfigCampos` se liberan antes de recrearse en las DOS rutas de
   arranque (serie y paralela) y se destruyen en el `FormClose` del
   principal.
4. **Puntero colgante del log** — `oMemoSQL := nil` al cerrar el principal:
   el `Assigned(oMemoSQL)` de `inLibLog` ya no puede tocar un TcxMemo
   destruido si se loguea durante el apagado.
5. **Cierre de pestañas seguro** — `inLibFormManager.InternalCloseForm` usa
   `AForm.Release` (destrucción diferida por cola de mensajes) en vez de
   `FreeAndNil` inline: era el sospechoso de los AVs al cerrar pestañas con
   tareas async vivas.
6. **`EInvalidCast` en standalone** — `CrearTablaPrincipal` guarda el cast
   del Owner con `is TfrmMtoPrincipal` (como ya hacían los demás puntos).

Nota: el punto 5 del plan (timeout de tareas que abandona conexiones) ya
registraba warning en el log — sin cambios; la cancelación cooperativa real
queda en la lista de pendientes (refactorizacion_estado.md, grupo B).

## Añadir a la pasada funcional (PASO 0 del plan maestro)

- Abrir un Mto, usar el chooser de columnas/guías, cerrar la pestaña — sin AV.
- Cerrar sesión y volver a hacer logon (re-login) 2-3 veces — sin degradación.
- Cerrar la app con el monitor SQL visible — sin AV al salir.
