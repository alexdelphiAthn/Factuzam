# Parámetros de aplicación y de caja como servicios con interfaz — Fase XII

Fecha: 25/07/2026

Continuación de la serie I–XI. Aquellas fases retiraron el estado global
de conexiones, permisos, auditoría, monitor SQL, perfiles, filtros y
contexto de sesión, y la XI está retirando `oConn`. Quedan vivos dos
singletons gemelos fuera de `inLibGlobalVar`: `oAppParams`
(`inLibAppParam`) y `oCajaParams` (`inLibCajaParam`).

Estado al abrir la fase (recontar antes de aplicar cada subfase):

- `inLibAppParam` aparece en el `uses` de **43 unidades**;
  `inLibCajaParam` en **25**.
- **116 referencias directas** `oAppParams.*` / `oCajaParams.*` en
  **42 unidades** (79 App / 37 Caja).
- Reparto por método — App: `GetString` 31, `GetPath` 23, `GetBool` 12,
  `GetInt` 8, `Params` 2, `Recargar` 1, `InicializarParametrosApp` 1,
  `AsignarConexion` 1. Caja: `GetBool` 22, `GetString` 7, `GetInt` 3,
  `Params` 2, `Recargar` 1, `InicializarParametrosCaja` 1,
  `AsignarConexion` 1.
- Las funciones libres `TarifaDefecto` y `NivelesFamiliaArqueo`
  (`inLibCajaParam`) se llaman desde **15 unidades** más.
- Solo dos unidades tocan las tripas (`Params: TObjectDictionary` y las
  clases `TAppParamDef` / `TParamDef`): los editores `inMtoAppParam` e
  `inMtoCajaParam`.
- `inMtoPrincipal` es la raíz: `AsignarConexion` +
  `InicializarParametrosApp/Caja` + `Recargar` indirecto.
- Los hilos `TVerifactuCola` y `TVentasWsCola` leen parámetros **en
  caliente desde hilo secundario** (`appVerifactuActivo` cada ciclo).

## Problemas que corrige la fase

1. **Duplicación**: las dos unidades son ~90 % el mismo código
   (`TTipoParametro` definido dos veces, `CargarDesdeDB`, getters y
   registro idénticos; solo difieren catálogo, formulario de perfil
   — `frmMtoAppParam` / `frmMtoCajaParam` — y `GetPath` +
   `AplicarFlagsLog` en la de App).
2. **Acoplamiento**: 42 unidades dependen de clases concretas con `Uni`
   en su `interface`; ciclo real con `inLibLog` (el log lee flags de
   parámetros y los parámetros llaman a `AplicarModosDepuracion`),
   sorteado hoy vía `uses` de `implementation`.
3. **Carrera latente**: el diccionario se lee desde los hilos de
   Verifactu / ventas WS mientras `Recargar` reescribe `ValorActual`
   sin ninguna protección.

## Mecanismos disponibles (ya construidos en fases anteriores)

- Patrón contrato puro `inLib<Dominio>Intf` + `IProveedor<Dominio>`
  (véanse `inLibConexionesIntf`, `inLibPerfilesUsuarioIntf`,
  `inLibContextoSesionIntf`).
- `TfrmBase` / `TdmBase` resuelven servicios del propietario con
  `Supports(AOwner, IProveedorX)` y los publican como propiedad.
- Las librerías sin formulario reciben la interfaz como parámetro
  explícito (precedente: `inLibBuscarImpresora`, `inLibLayoutForm`).
- Los hilos reciben los servicios en `IniciarHilo(...)` (precedente:
  `TVerifactuCola.IniciarHilo(Conexiones, ...)`).
- `IPerfilesUsuario.CargarPerfilFormulario(AFormulario, AUsuario,
  AGrupo, out APerfil)` ya encapsula `PRC_GETPERFILFORMULARIO`, que es
  exactamente lo que hace hoy `CargarDesdeDB` a mano con `TUniQuery`.

## Diseño destino

Dos unidades nuevas en `src/Lib/`:

**`inLibParametrosIntf`** — contrato puro, `uses` solo `System.*`.

```pascal
type
  TTipoParametro = (tpString, tpInteger, tpBoolean);

  // Instantánea de una definición para los editores (record, no clase:
  // los formularios dejan de ver el diccionario interno)
  TParamInfo = record
    Categoria      : string;
    Nombre         : string;
    Descripcion    : string;
    Tipo           : TTipoParametro;
    ValorPorDefecto: string;
    ValorActual    : string;
  end;

  // Lectura pura: lo único que necesita el 95 % de consumidores
  IParametros = interface
    ['{NUEVO-GUID}']
    function GetString(const AKey: string;
                       const ADefault: string = ''): string;
    function GetBool(const AKey: string;
                     const ADefault: Boolean = False): Boolean;
    function GetInt(const AKey: string;
                    const ADefault: Integer = 0): Integer;
  end;

  IParametrosAplicacion = interface(IParametros)
    ['{NUEVO-GUID}']
    function GetPath(const ANombre: string): string;
  end;

  IParametrosCaja = interface(IParametros)
    ['{NUEVO-GUID}']
    // Absorben las funciones libres homónimas de inLibCajaParam
    function TarifaDefecto: string;
    function NivelesFamiliaArqueo: Integer;
  end;

  // Solo para inMtoAppParam / inMtoCajaParam
  IParametrosEdicion = interface
    ['{NUEVO-GUID}']
    function ListarDefiniciones: TArray<TParamInfo>;
    procedure Recargar(const AUsuario, AGrupo: string);
  end;

  IProveedorParametros = interface
    ['{NUEVO-GUID}']
    function GetParametrosApp: IParametrosAplicacion;
    function GetParametrosCaja: IParametrosCaja;
    property ParametrosApp: IParametrosAplicacion
      read GetParametrosApp;
    property ParametrosCaja: IParametrosCaja read GetParametrosCaja;
  end;
```

**`inLibParametrosBase`** — motor común único.

- `TParametrosBase = class(TInterfacedObject, IParametros,
  IParametrosEdicion)`; campos: sección crítica (`TCriticalSection`,
  precedente `TContextoSesionAplicacion`), diccionario de definiciones,
  nombre del formulario de perfil y lista de claves excluidas.
- Absorbe `RegistrarParametro`, `RegistrarDefectos`, `CargarDesdeDB`
  (parametrizada por formulario + exclusiones, incluida la lógica de
  parámetros huérfanos → «Otros (Heredados de BD)»), `Inicializar`,
  `Recargar` y los tres getters. Getters y carga bajo bloqueo: corrige
  la carrera con los hilos.
- **Decisión a validar en XII-A**: sustituir el `TUniQuery` +
  `AsignarConexion` por `IPerfilesUsuario.CargarPerfilFormulario`
  (sobrecarga con usuario/grupo). Si cubre el caso — mismo SP, lectura
  fresca en `Recargar` —, el motor pierde `Uni` por completo y el
  servicio se alinea con el resto de la serie. Si no, se mantiene el
  SQL directo y `AsignarConexion` como hoy (plan B, sin impacto en el
  resto de la fase).

Las unidades actuales quedan como implementaciones finas:

- `inLibAppParam`: `TParametrosAplicacion(TParametrosBase,
  IParametrosAplicacion)` — catálogo `InicializarParametrosApp`,
  `GetPath` (vía `inLibPathTokens`) y `AplicarFlagsLog`.
- `inLibCajaParam`: `TParametrosCaja(TParametrosBase,
  IParametrosCaja)` — catálogo `InicializarParametrosCaja`,
  `TarifaDefecto` y `NivelesFamiliaArqueo` como métodos (con el mismo
  saneo de rango [1..9] y el default 'PVP').

Propagación: `inMtoPrincipal` implementa `IProveedorParametros`;
`TfrmBase` y `TdmBase` añaden las propiedades `ParametrosApp` y
`ParametrosCaja` resueltas del propietario, igual que `Conexiones` o
`PerfilesUsuario`.

---

## XII-A — Motor común, contratos y compatibilidad

Alcance: unidades nuevas, las dos unidades de parámetros, los dos
editores, `inMtoPrincipal`, `TfrmBase`, `TdmBase`. **Cero cambios en
los demás consumidores.**

Cambios:

1. Crear `inLibParametrosIntf` e `inLibParametrosBase`.
2. Vaciar `inLibAppParam` / `inLibCajaParam` en las clases finas de
   arriba. Las variables globales **cambian de tipo pero no de
   nombre**: `oAppParams: IParametrosAplicacion` y
   `oCajaParams: IParametrosCaja`. Como los getters conservan nombre y
   firma, las ~110 llamadas existentes compilan sin tocarse.
3. Ciclo de vida: las instancias se siguen creando en
   `initialization` (misma ventana temporal que hoy: los getters antes
   de `Inicializar*` devuelven el default del punto de llamada). En
   `finalization`, `oAppParams := nil` — **nunca** `FreeAndNil` sobre
   una interfaz. La raíz guarda además su propia referencia de
   interfaz durante toda la vida de la aplicación.
4. `inMtoPrincipal` implementa `IProveedorParametros`; `TfrmBase` y
   `TdmBase` añaden las propiedades (mismo molde `Supports(AOwner,...)`
   que las seis existentes).
5. Migrar los dos editores a `IParametrosEdicion.ListarDefiniciones`
   (construcción del `JvInspector`, `ResetearADefectos`) y `Recargar`.
   Desaparece todo uso externo de `.Params` y de
   `TParamDef` / `TAppParamDef`.

Pruebas (carpeta `PruebasParametrosFase12A/`, mismo esquema que
`PruebasConexionGlobalFase11A`):

- Estructurales:
  - `inLibParametrosIntf` no usa `Uni` ni unidades del proyecto.
  - Toda interfaz declara GUID.
  - 0 apariciones de `TParamDef|TAppParamDef|\.Params\b` fuera de
    `inLibParametrosBase`.
  - 0 apariciones de `TObjectDictionary` en los editores.
- Compilación: matriz Delphi completa sin errores ni warnings nuevos.
- Funcionales (contra BBDD de pruebas, capturar pantallas de
  referencia ANTES de empezar):
  1. Arranque completo hasta el menú principal.
  2. Abrir ambos editores: mismas categorías y mismo número de
     parámetros que en la captura de referencia.
  3. Editar y guardar un parámetro de cada tipo (bool, int, string)
     en cada editor; cerrar, reabrir y comprobar persistencia.
  4. Recarga en caliente: activar `appLogSQL` y comprobar trazas SQL
     sin reiniciar; desactivar y comprobar que cesan.
  5. Huérfanos: insertar a mano una subclave inexistente en el perfil
     y comprobar que aparece en «Otros (Heredados de BD)».
  6. Caja: tarifa por defecto aplicada al abrir caja; arqueo con el
     desglose de familias configurado; venta con vale y devolución.
  7. Hilo Verifactu: conmutar `appVerifactuActivo` y comprobar que el
     ciclo siguiente lo lee (log del hilo).

Resultado esperado: comportamiento idéntico; el diff solo toca las 2
unidades nuevas + 2 de parámetros + 2 editores + raíz + 2 clases base;
~400 líneas duplicadas eliminadas; carrera de hilos cerrada.

---

## XII-B — Formularios, modales y módulos de datos

Alcance: `src/Forms`, `src/Modals`, `src/DataModules`, `src/Caja/Forms`,
`src/Caja/Modals`, `src/Caja/DataModules` — unas 30 unidades, todas
descendientes de `TfrmBase` / `TdmBase` (~60 referencias entre directas
y funciones libres; recontar al abrir).

Cambio mecánico por unidad:

- `oAppParams.GetX(...)` → `ParametrosApp.GetX(...)`
- `oCajaParams.GetX(...)` → `ParametrosCaja.GetX(...)`
- `TarifaDefecto` / `NivelesFamiliaArqueo` (función libre) →
  `ParametrosCaja.TarifaDefecto` / `.NivelesFamiliaArqueo`
- En `uses`: `inLibAppParam` / `inLibCajaParam` →
  `inLibParametrosIntf` (o eliminación si ya no queda referencia).

Pruebas:

- Estructural: 0 apariciones de `oAppParams|oCajaParams` y de las
  funciones libres en las seis carpetas del alcance.
- Compilación completa.
- Funcional de humo sobre lo más denso: `inMtoCajaOpe` (18 refs: venta
  completa, cobro por fases, selección de vale, empleado por defecto,
  scanner), los 12 modales de impresión (`GetPath appDirPDF` /
  `appDirExcel`: generar un PDF y un Excel), consulta de stock
  (`appStockOcultarCeros`), inventarios y documentos de trabajo.

Resultado esperado: quedan ~55 referencias vivas, todas en `src/Lib`,
`src/Caja/Lib`, `src/verifactu` y la raíz.

---

## XII-C — Librerías e hilos

Alcance: `inLibVerifactu` (11), `inLibFactuzamApi` (9), `inLibLog` (5),
`inLibVerifactuEnvio` (5), `inLibVerifactuCola` (3),
`inLibVentasWsCola` (3), `inLibRelojFiscal` (3), `inLibFotos` (2),
`inLibFotosNube`, `inLibFiltroUsuario`, `inLibDevExp`,
`inLibBuscarImpresora`, `inLibArticulosResolver`, `inLibArqueoTicket`,
`UniDataConn`.

Mecanismo, según el caso:

1. **Parámetro explícito en la firma** (precedente
   `inLibBuscarImpresora(AContextoSesion)`): la rutina recibe
   `AParametros: IParametrosAplicacion` (o `IParametrosCaja`) y el
   llamante pasa su propiedad heredada. Es la opción por defecto.
2. **Hilos**: `TVerifactuCola.IniciarHilo` y
   `TVentasWsCola.IniciarHilo` amplían su firma para recibir la
   interfaz junto a `Conexiones`; el hilo guarda la referencia (las
   lecturas ya son seguras desde XII-A).
3. **`inLibLog`**: aquí muere el ciclo. `AplicarModosDepuracion` pasa a
   recibir `IParametrosAplicacion`; `AplicarFlagsLog` del motor le
   pasa `Self`. `inLibLog` deja de usar `inLibAppParam` y depende solo
   de `inLibParametrosIntf`.

Pruebas:

- Estructural: 0 apariciones de `oAppParams|oCajaParams` fuera de
  `inLibAppParam`, `inLibCajaParam` e `inMtoPrincipal`; `inLibLog` sin
  `inLibAppParam` en ningún `uses`.
- Compilación completa.
- Funcional: ciclo Verifactu completo en entorno PRE (registro + QR +
  envío), cola de ventas WS con reintento, los 4 flags de log en
  caliente, resolución de fotos (`GetPath appDirFotos` + fallback),
  reloj fiscal NTP, API Factuzam (si hay instalación de pruebas), y
  arranque midiendo que no se degrada (log de cronómetros).

Resultado esperado: solo la raíz y las dos unidades de parámetros
mencionan las variables globales.

---

## XII-D — Retirada y cierre

Cambios:

1. Marcar `oAppParams` / `oCajaParams` con `deprecated`, compilar y
   confirmar **cero warnings** de uso.
2. Retirar las variables públicas y las funciones libres
   `TarifaDefecto` / `NivelesFamiliaArqueo`. La creación de instancias
   se traslada del `initialization` a `inMtoPrincipal`, junto al resto
   de servicios (a partir de aquí el orden de arranque es explícito).
3. Barrido final de `uses`: ningún consumidor fuera de la raíz debe
   usar `inLibAppParam` / `inLibCajaParam`; limpiar menciones en
   comentarios cruzados.
4. Documentar el patrón en `LIBRO_DE_ESTILO_DELPHI.md` (§14 —
   singletons: referenciar que parametrización va por
   `IProveedorParametros`) y anotar en este fichero el resultado real
   de cada subfase, al estilo XI-A.

Pruebas: estructural global (`grep` de `oAppParams|oCajaParams` = 0 en
`src/` salvo raíz), matriz de compilación, y repetición de la batería
funcional de XII-A completa como regresión de cierre.

Resultado esperado final:

- 1 motor en lugar de 2 copias; 0 variables globales de parámetros.
- Consumidores acoplados solo a `inLibParametrosIntf` (sin `Uni`).
- Ciclo `inLibLog` ↔ parámetros eliminado.
- Lecturas thread-safe.
- Editores trabajando contra `IParametrosEdicion` sin ver el
  diccionario interno.

---

## Riesgos y salvaguardas

- **Conteo de referencias**: nunca mezclar referencia de objeto y de
  interfaz sobre la misma instancia fuera de la raíz; los globales de
  transición son de tipo interfaz desde XII-A; `:= nil` en
  `finalization`, jamás `Free`.
- **Orden de arranque**: hasta XII-D las instancias nacen en
  `initialization`, exactamente como hoy; el traslado a la raíz se
  hace el último, cuando ya nadie las toca en unidades ajenas.
- **`Recargar` vs. caché de perfiles**: si XII-A adopta
  `IPerfilesUsuario`, verificar que la sobrecarga con usuario/grupo lee
  de BBDD y no de caché (si no, invalidar antes con
  `ResincronizarPerfilFormulario`). Es la prueba nº 4 de XII-A.
- **Regresión silenciosa en modales de impresión**: son 12 unidades de
  1 referencia; el riesgo es dejarse alguna. La comprobación
  estructural por carpeta la cubre.
- Cada subfase es un commit propio → rollback = `git revert` de la
  subfase, sin arrastrar las anteriores.

## Orden y dependencias

XII-A es prerequisito de todo. XII-B y XII-C son independientes entre
sí (pueden intercambiarse o solaparse por lotes), pero ambas antes que
XII-D. No abrir XII-D con ningún warning `deprecated` pendiente.
