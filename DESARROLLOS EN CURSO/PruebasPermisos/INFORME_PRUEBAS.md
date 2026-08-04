# Informe de pruebas: refactorización de permisos

Fecha: 23/07/2026

## Resultado

La refactorización supera las pruebas automatizadas y compila en las dos
plataformas Windows del proyecto. El resultado es apto para revisión
funcional en una instalación conectada a una base de datos real.

## Alcance validado

- Contrato `IPermisosAplicacion` independiente de VCL, UniDAC y variables
  globales.
- Resolución por prioridad: administrador, usuario, grupo y `Todos`.
- Política explícita para permisos ausentes.
- Fallo cerrado cuando el servicio de permisos no está disponible.
- Adaptador de carga de reglas mediante UniDAC.
- Propagación de permisos desde el formulario principal a formularios hijos.
- Sustitución de accesos directos al antiguo `oPermisos`.
- Paso explícito de la autorización a servicios de Caja y consulta de stock.

## Pruebas automatizadas

Proyecto:
`DESARROLLOS EN CURSO/PruebasPermisos/PruebasPermisos.dpr`

Compilador: Embarcadero Delphi 37.0 para Win32.

Resultado: **15 pruebas ejecutadas, 15 correctas y 0 fallos**.

| Escenario | Resultado |
| --- | --- |
| El administrador conserva acceso aun sin servicio disponible | Correcto |
| Una regla de usuario prevalece sobre grupo y `Todos` | Correcto |
| Una regla de grupo prevalece sobre `Todos` | Correcto |
| La regla `Todos` se usa como último ámbito | Correcto |
| Un permiso ausente puede configurarse como permitido | Correcto |
| Un permiso ausente puede configurarse como denegado | Correcto |
| El resultado informa del origen de la decisión | Correcto |
| Un servicio no disponible deniega por fallo cerrado | Correcto |
| Usuario, grupo y código se comparan normalizados | Correcto |
| Los códigos de mantenimiento se generan por acción | Correcto |

Salida final del ejecutable:

```text
Pruebas: 15 | Fallos: 0
```

## Compilación de la aplicación

Se ejecutó una compilación completa de `fzam.dproj` en configuración
`Release`.

| Plataforma | Resultado |
| --- | --- |
| Win32 | Correcto, 0 errores |
| Win64 | Correcto, 0 errores |

El compilador emitió avisos e indicaciones en unidades existentes del
proyecto. Ninguno corresponde a las tres unidades nuevas del sistema de
permisos y ninguno impide la generación de los ejecutables.

## Comprobaciones estáticas

- No quedan referencias a `oPermisos`.
- No quedan referencias a `TPermisosCache`.
- El resolvedor no depende de UniDAC, VCL ni `inLibGlobalVar`.
- La consulta SQL está aislada en `inLibPermisosUniDAC`.
- Las unidades nuevas están incluidas en `fzam.dpr` y `fzam.dproj`.
- Todas las firmas modificadas tienen sus llamadas actualizadas.
- `git diff --check` no informa de errores de espacios.
- No se ha modificado `factuzam_original.sql`.
- No se ha realizado ningún cambio de esquema de base de datos.

## Pruebas funcionales pendientes

Estas pruebas necesitan ejecutar la aplicación con usuarios y reglas reales:

1. Entrar como administrador y verificar acceso completo.
2. Entrar con reglas contradictorias de usuario, grupo y `Todos` y confirmar
   la prioridad efectiva.
3. Comprobar ocultación y desactivación de menús.
4. Comprobar las seis acciones de un mantenimiento: consultar, insertar,
   modificar, borrar, exportar e imprimir.
5. Comprobar en Caja el cambio de fecha, apertura de cajón, visualización de
   coste e importes de arqueo.
6. Forzar un error de carga de permisos y confirmar que las operaciones
   sensibles quedan denegadas y el error aparece en el registro.

## Criterio de aceptación

La validación automatizada queda superada. Para cerrar la validación funcional
se recomienda ejecutar los seis casos pendientes en una base de datos de
pruebas antes de desplegar el cambio.
