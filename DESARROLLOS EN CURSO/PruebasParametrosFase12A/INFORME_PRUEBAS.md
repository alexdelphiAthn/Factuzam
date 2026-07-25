# Informe de pruebas — Fase XII-A

Fecha: 25/07/2026

## Alcance implementado

- Contrato puro `inLibParametrosIntf`.
- Motor común `inLibParametrosBase` con sección crítica.
- Implementaciones finas para App y Caja.
- Carga mediante `IPerfilesUsuario`, sin `TUniQuery` en el motor.
- Factorías y propiedad de los servicios en `inMtoPrincipal`.
- Proveedor de lectura en `TfrmBase` y `TdmBase`.
- Proveedor de edición en la raíz.
- Editores migrados a instantáneas `TParamInfo`.
- `inLibLog` desacoplado de `inLibAppParam`.
- Unidades registradas en `fzam.dpr` y `fzam.dproj`.

## Pruebas estructurales

Resultado: **correcto**.

Comprobaciones principales:

- seis interfaces con GUID;
- contrato sin UniDAC ni dependencias de unidades del proyecto;
- motor con `TCriticalSection` e `IPerfilesUsuario`, sin UniDAC;
- cero `TParamDef` / `TAppParamDef`;
- cero accesos `oAppParams.Params` / `oCajaParams.Params`;
- editores sin `TObjectDictionary`;
- log sin dependencia de `inLibAppParam`;
- alias globales de tipo interfaz;
- ninguna creación de parámetros en `initialization`;
- unidades nuevas registradas en ambos ficheros de proyecto.

Ejecutor: `probar_estructura.ps1`.

## Pruebas unitarias

Resultado: **correcto en Win32 y Win64 con Delphi 37.0**.

Se utiliza una implementación falsa de `IPerfilesUsuario` para probar:

- lectura de strings;
- entero inválido con valor predeterminado;
- semántica booleana histórica;
- claves excluidas;
- parámetros huérfanos y su categoría;
- copia independiente de `ListarDefiniciones`;
- `QueryInterface` de lectura y edición;
- resincronización antes de cada carga;
- cuatro lectores concurrentes durante cien recargas;
- tarifa ausente igual a `PVP`;
- tarifa existente pero vacía conservada;
- niveles de familia limitados a `[1..9]`.

Ejecutor: `ejecutar_pruebas.ps1`.
Detalle: `resultado_pruebas.txt`.

## Compilación del proyecto

Resultado:

| Configuración | Estado | Errores | Avisos existentes |
|---|---:|---:|---:|
| Debug Win64 | Correcta | 0 | 110 |
| Release Win32 | Correcta | 0 | 107 |
| Release Win64 | Correcta | 0 | 109 |

Los conteos de avisos coinciden exactamente con la línea base de XI-D:
no se han introducido avisos nuevos.

La incidencia `frxClass` registrada en XII-0 no era un defecto del
proyecto. El selector del script calculaba mal la versión y elegía
Studio 22.0; las DCU actuales de FastReport corresponden a Studio
37.0. Se corrigió el selector antes de ejecutar esta matriz.

Ejecutor: `ejecutar_compilacion.ps1`.
Detalle: `resultado_compilacion.txt`.

## Regresión de servicios anteriores

| Batería | Resultado |
|---|---:|
| Perfiles Fase IX | 20/20 |
| Filtros Fase IX | 17/17 |
| Conexión global XI-D | 14/15 |

La única expectativa no satisfecha de XI-D exige exactamente dos DFM
modificados que formaban parte del árbol de trabajo de aquella fase.
Actualmente hay cero DFM modificados. Las otras 14 barreras de XI-D,
incluidas las 253 conexiones persistentes y la integridad del dump,
son correctas; no es una regresión de XII-A.

Detalle: `resultado_regresion.txt`.

## Validación funcional pendiente

Requiere una BBDD de pruebas y sesión interactiva:

- arranque hasta el menú principal;
- comparación visual de ambos editores;
- guardar y recargar string, integer y boolean;
- cambio de flags de log sin reiniciar;
- parámetro huérfano visible;
- tarifa y niveles de arqueo en Caja;
- lectura en caliente desde Verifactu.

No se han almacenado credenciales ni datos personales en los
artefactos de prueba.
