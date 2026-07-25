# Informe de pruebas - Contexto de sesión Fase X-D

Fecha: 25/07/2026

## Resultado

La Fase X-D queda completada y validada. Una vez migrados todos los
consumidores en X-C, se retira la capa de compatibilidad global del contexto
de sesión.

El estado final es:

- `inLibContextoSesionGlobal.pas` eliminado;
- `TContextoSesionGlobal` sin referencias ni registro en el proyecto;
- `oUser`, `oGroup`, `oRootGroup`, `oEmpresa`, `oAlmacen` y `oCaja`
  eliminadas de `inLibGlobalVar`;
- cero referencias a esas seis variables en `src` y `fzam.dpr`;
- composición directa de `TContextoSesionAplicacion` en `fzam.dpr`.

## Limpieza de dependencias

Se han retirado siete importaciones de `inLibGlobalVar` que habían quedado
huérfanas después de la migración:

1. `UniDataEmpleados.pas`
2. `inMtoGenSearch.pas`
3. `inLibDevExp.pas`
4. `inLibGridPivoteVenta.pas`
5. `inLibWin.pas`
6. `inMtoModalDistribuidor.pas`
7. `otras pruebas/parametros VerticalGrid/Unit1.pas`

La prueba de X-D revisa dinámicamente todos los importadores de
`inLibGlobalVar` y falla si encuentra un `uses` que no consuma ninguno de sus
símbolos públicos actuales.

XI-D ha retirado posteriormente `oConn` y la excepción transitoria. La
prueba vuelve a exigir que todo `uses inLibGlobalVar` consuma uno de los
símbolos que la unidad publica realmente.

La conexión global no formaba parte del corte original X-D; su retirada
definitiva se documenta en
`PruebasConexionGlobalFase11D/INFORME_PRUEBAS.md`.

## Prueba estructural de X-D

Script:
`PruebasContextoSesionFase10D.ps1`

Resultado: **11 pruebas ejecutadas, 11 correctas y 0 fallos**.

La barrera anti-regresión comprueba:

1. Que el fichero del adaptador no existe.
2. Que ninguna fuente registra o consume el adaptador.
3. Que `inLibGlobalVar` no declara las seis variables retiradas.
4. Que ninguna fuente vuelve a introducir esas variables.
5. Que el DPR compone directamente el contexto definitivo.
6. Que el proyecto no registra la compatibilidad eliminada.
7. Que no quedan importaciones huérfanas de `inLibGlobalVar`.
8. Que las siete unidades detectadas permanecen limpias.
9. Que se conservan los enlaces persistentes de conexión.
10. Que no se modifica ningún DFM ajeno a las dos conversiones de
    herencia visual añadidas después en XI-B1.
11. Que `factuzam_original.sql` permanece intacto.

## Regresión automatizada

| Batería | Resultado |
| --- | ---: |
| Contexto de sesión Fase X-D | 11/11 |
| Contexto de sesión Fase X-C | 17/17 |
| Contexto de sesión Fase X-B | 13/13 |
| Contexto de sesión Fase X-A | 14/14 |
| Contexto de sesión Fase VIII | 18/18 |
| Perfiles Fase IX | 20/20 |
| Filtros Fase IX | 17/17 |
| Total | 110/110 |

El informe y la prueba de X-C se ajustan al límite correcto entre fases:
X-C migra los consumidores y X-D elimina la compatibilidad.

## Compilación

| Configuración | Plataforma | Resultado |
| --- | --- | --- |
| Debug | Win64 | Correcta, 0 errores |
| Release | Win32 | Correcta, 0 errores |
| Release | Win64 | Correcta, 0 errores |

Las compilaciones mantienen avisos e indicaciones ya existentes en el
proyecto. La limpieza de `uses` no ha introducido errores ni dependencias
transitivas ocultas.

`git diff --check` termina correctamente, sin errores de espacios ni de
estructura del parche.

## Compatibilidad

- Se conservan los 253 enlaces persistentes
  `Connection = dmConn.conUni` de 52 ficheros DFM.
- En X-D no se modificó ningún DFM. La barrera admite después los dos
  cambios de raíz de XI-B1 y rechaza cualquier otro.
- No hay cambios de esquema ni scripts SQL.
- `factuzam_original.sql` permanece intacto.
- La eliminación de las antiguas variables es intencionada: cualquier código
  nuevo que intente recuperarlas fallará en la prueba estructural.

## Prueba funcional recomendada

Con una base de datos de desarrollo:

1. iniciar sesión manual y automáticamente;
2. comprobar usuario, grupo, empresa, almacén y caja en la ventana principal;
3. abrir un formulario, un DataModule y un modal representativos;
4. validar filtros, perfiles y permisos con usuario normal y administrador;
5. crear un documento y comprobar el usuario de auditoría;
6. ejecutar una operación de caja y una operación fiscal.

Estas comprobaciones conectadas quedan pendientes porque requieren las
credenciales y los datos locales del entorno.

## Conclusión

X-D cierra la transición del contexto de sesión. Ya no existe un camino de
compatibilidad global: identidad y ubicación solo pueden obtenerse mediante
los contratos explícitos implantados en las fases anteriores. La prueba
estructural convierte esta decisión arquitectónica en una restricción
verificable para cambios futuros.
