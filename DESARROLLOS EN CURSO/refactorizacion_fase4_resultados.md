# Fase 4 — sacar el estado global (resultados)

Fecha: 27/07/2026. Implementación C1 y C2 terminada. Sin commit.

## Resultado

`inLibGlobalVar` ya no contiene estado mutable ni una sección `var`.
Conserva únicamente `oAppName`, `oVersion` y `oAll` como constantes de
compatibilidad.

### C1 — parámetros y contexto

- La licencia se transporta como `TResultadoLicenciaAplicacion` y queda
  expuesta por `IParametrosAplicacion`.
- La impresora de caja vive en `IParametrosCaja` y se actualiza al recargar
  los parámetros.
- El indicador de cierre y el registro de Sesiones de Compra viven en
  `IContextoSesionAplicacion`.
- Las colas de Verifactu y ventas WS reciben el contexto de sesión y consultan
  en él si la aplicación se está cerrando.
- El visor del monitor SQL se comunica mediante `IVisorMonitorSQL`; el servicio
  ya no conoce un `TcxMemo` global.
- La caché de guías se inyecta mediante `IInformesGuiasCache` y se hereda desde
  `TfrmBase`.
- Los controladores de artículos, tallas y pivote reciben el contexto mediante
  sus records de configuración. Ya no llaman a un callback global.

### C2 — credenciales

`inMtoLogon` ya no publica `sPass`, `sPassEn` ni `sUserPassOK`. Las dos
contraseñas de conexión son campos privados del formulario y el exterior
recibe únicamente el resultado del inicio de sesión y el resultado de la
licencia.

## Verificación automática realizada

- Proyecto principal Release/Win64: 0 errores; 307.749 líneas; 27,27 s.
- `PruebaVentasWs` Debug/Win32: 0 errores; 10.489 líneas; 1,83 s.
- Se añadió `Vcl.Imaging` a los namespaces de esta careta para que su
  compilación normal resuelva la unidad heredada `jpeg`.
- Comprobador de dependencias de capa: `Dependencias de capa: OK`.
- `git diff --check`: sin errores.
- Referencias a las nueve familias de variables globales retiradas: 0.
- Credenciales globales de `inMtoLogon`: 0.
- Sección `var` en `inLibGlobalVar`: 0.
- Fuentes modificadas: UTF-8 con BOM y CRLF.
- `factuzam_original.sql`: sin cambios.

No existe todavía el proyecto DUnitX previsto para la fase 5. Por tanto, estas
comprobaciones cubren compilación, contratos y dependencias, pero no sustituyen
las pruebas funcionales de licencia, login, cierre e impresión.

## Plan de pruebas funcionales

Estado actual: **pendiente de ejecución manual**.

1. **Licencia válida.** Arrancar con una licencia vigente y comprobar que se
   abre la aplicación, el título muestra el estado esperado y no aparece un
   aviso nuevo.
2. **Licencia caducada.** Arrancar con una licencia caducada y comprobar que
   se conserva el mensaje y el bloqueo o limitación anterior.
3. **Sin licencia.** Arrancar sin licencia y comprobar el mismo mensaje y
   comportamiento que antes de la refactorización.
4. **Login correcto.** Entrar con un usuario válido y verificar usuario, grupo,
   empresa, almacén y caja activos.
5. **Contraseña incorrecta.** Confirmar el rechazo, el mensaje y que no queda
   una sesión parcialmente inicializada.
6. **Usuario inexistente.** Confirmar el rechazo y el mensaje anterior.
7. **Re-login tres veces.** Cerrar sesión y volver a entrar tres veces seguidas,
   comprobando identidad, ubicación, permisos y ausencia de errores o fugas
   visibles.
8. **Cierre con monitor SQL.** Abrir el monitor SQL, generar actividad y cerrar
   la aplicación; debe terminar sin excepción de acceso ni proceso colgado.
9. **Cierre con tarea asíncrona.** Iniciar una consulta o tarea en segundo plano
   y cerrar; no debe arrancar trabajo nuevo ni tocar formularios destruidos.
10. **Impresora de caja.** Cambiar la impresora en parámetros, recargarlos e
    imprimir un ticket y abrir el cajón; ambos deben usar el nuevo valor.

La fase queda implementada, pero no se considerará validada funcionalmente
hasta completar esta pasada manual.
