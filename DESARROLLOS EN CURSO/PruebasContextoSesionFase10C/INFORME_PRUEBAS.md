# Informe de pruebas - Contexto de sesión Fase X-C

Fecha: 25/07/2026

## Resultado

La Fase X-C queda validada correctamente. Las unidades no visuales dejan de
leer las seis variables globales de sesión (`oUser`, `oGroup`, `oRootGroup`,
`oEmpresa`, `oAlmacen` y `oCaja`).

Al comenzar la fase quedaban 88 referencias repartidas entre 20 unidades:
18 consumidores no visuales, la unidad de variables globales y el adaptador
transitorio. X-C migra los 18 consumidores. La eliminación física de las dos
unidades de compatibilidad corresponde a X-D.

## Cambios validados

- La raíz de composición crea directamente un
  `TContextoSesionAplicacion` a partir de las selecciones del inicio de sesión.
- Las librerías que necesitan identidad y ubicación reciben un
  `IContextoSesionAplicacion`.
- Las operaciones que solo necesitan un dato reciben el valor mínimo
  explícito, normalmente `AUsuario` o `ACodigoEmpresa`.
- Los trabajadores en segundo plano de Verifactu y ventas web capturan el
  usuario al construirse, evitando consultar estado global durante su
  ejecución.
- Los filtros de usuario, permisos, disposiciones visuales, documentos de
  trabajo, fotografías, contadores, impresión y generación de tickets usan
  contratos explícitos.
- El circuito de Verifactu, su cola, el envío, la instalación SIF y la
  exportación No Verifactu reciben el usuario de auditoría explícitamente.
- El adaptador y las declaraciones globales quedan sin consumidores y
  preparados para su retirada en X-D.
- Se mantienen los 253 enlaces persistentes
  `Connection = dmConn.conUni` existentes en 52 ficheros DFM.
- No se ha modificado ningún DFM ni el esquema de la base de datos.
- `factuzam_original.sql` permanece intacto.

## Pruebas automatizadas

| Batería | Resultado |
| --- | ---: |
| Contexto de sesión Fase X-C | 17/17 |
| Contexto de sesión Fase X-A | 14/14 |
| Contexto de sesión Fase X-B | 13/13 |
| Contexto de sesión Fase VIII | 18/18 |
| Perfiles Fase IX | 20/20 |
| Filtros Fase IX | 17/17 |
| Total | 99/99 |

El script específico de X-C comprueba:

1. La ausencia de las seis variables globales en los consumidores.
2. La independencia de los consumidores respecto al adaptador transitorio.
3. El registro de los contratos y la implementación definitiva del contexto.
4. La inyección de contexto en filtros, permisos, disposiciones visuales,
   documentos de trabajo, Facturae y PDF.
5. La recepción explícita del usuario en fotografías, contadores y servicios
   de Verifactu.
6. La captura del usuario en los trabajadores en segundo plano.
7. La conservación de enlaces persistentes y ficheros DFM.
8. La integridad de `factuzam_original.sql`.

Las baterías históricas de X-A, X-B y VIII se adaptan para poder ejecutarse
también sobre el estado definitivo posterior a X-D.

`git diff --check` termina sin errores de espacios ni de estructura del
parche. Git únicamente informa de la normalización futura de finales de línea
LF a CRLF.

## Compilación

| Configuración | Plataforma | Resultado |
| --- | --- | --- |
| Debug | Win64 | Correcta, 0 errores |
| Release | Win32 | Correcta, 0 errores |
| Release | Win64 | Correcta, 0 errores |

La compilación conserva avisos e indicaciones ya presentes en el proyecto. No
se ha detectado ningún error nuevo de compilación causado por X-C.

## Pruebas funcionales recomendadas

Estas comprobaciones requieren una base de datos y credenciales de prueba, por
lo que quedan pendientes de ejecución manual:

1. Iniciar sesión con selección automática y manual de empresa, almacén y caja.
2. Validar filtros con un administrador y con usuarios restringidos por
   empresa, almacén y caja.
3. Cargar y guardar disposiciones visuales y modificar permisos.
4. Crear documentos y comprobar contadores, auditoría y documentos de trabajo.
5. Guardar y rotar fotografías comprobando el usuario de modificación.
6. Probar la selección de impresora, recordatorios, tickets y arqueos.
7. Probar los modos SIN, VERIFACTU y NO VERIFACTU, incluyendo generación,
   envío, rectificación, exportación e instalación SIF.
8. Procesar las colas de Verifactu y ventas web y comprobar el usuario de los
   eventos generados por sus trabajadores.
9. Cambiar la ubicación activa durante la sesión y verificar que los nuevos
   consumidores reciben la instantánea actualizada del contexto.

## Conclusión

X-C completa la migración de los consumidores del estado global de sesión. La
identidad y la ubicación pasan por contratos explícitos hasta los formularios,
DataModules, librerías y procesos en segundo plano. X-D puede retirar ya el
adaptador y las declaraciones de compatibilidad sin afectar a esos
consumidores.
