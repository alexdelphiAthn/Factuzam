# Parámetros de aplicación y de caja como servicios con interfaz — Fase XII

Fecha: 25/07/2026

Continuación de la serie I–XI. Aquellas fases retiraron el estado global
de conexiones, permisos, auditoría, monitor SQL, perfiles, filtros y
contexto de sesión, y la XI está retirando `oConn`. Quedan vivos dos
singletons gemelos fuera de `inLibGlobalVar`: `oAppParams`
(`inLibAppParam`) y `oCajaParams` (`inLibCajaParam`).

Estado al abrir la fase (recontar antes de aplicar cada subfase):

- `inLibAppParam` se menciona en **43 ficheros** y
  `inLibCajaParam` en **25** (incluidos `fzam.dpr`, las propias
  unidades y comentarios cruzados). Las cláusulas `uses` reales son
  **39/22** dentro de `src`; `fzam.dpr` registra además ambas
  unidades.
- **116 accesos directos** `oAppParams.*` / `oCajaParams.*` en
  **41 unidades** (79 App / 37 Caja). Los nombres globales aparecen en
  42 unidades al incluir su declaración.
- Reparto por método — App: `GetString` 31, `GetPath` 23, `GetBool` 12,
  `GetInt` 8, `Params` 2, `Recargar` 1, `InicializarParametrosApp` 1,
  `AsignarConexion` 1. Caja: `GetBool` 22, `GetString` 7, `GetInt` 3,
  `Params` 2, `Recargar` 1, `InicializarParametrosCaja` 1,
  `AsignarConexion` 1.
- Las funciones libres `TarifaDefecto` y `NivelesFamiliaArqueo`
  (`inLibCajaParam`) se mencionan en **15 unidades** externas; dos
  menciones son comentarios y se excluyen del lote de llamadas real.
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

## XII-0 — Cierre de diseño y línea base

Estado: **iniciada el 25/07/2026**.

Esta subfase no modifica código Pascal. Su objetivo es cerrar las
decisiones de arquitectura, congelar una línea base reproducible y
evitar que XII-A empiece con contratos o ciclos de vida incompletos.
Los artefactos viven en `PruebasParametrosFase12_0/`.

### Decisiones cerradas

1. **Propiedad y creación**. `inMtoPrincipal` es el único propietario
   lógico de los servicios. Los crea, mediante factorías que devuelven
   interfaces, después de crear `TdmPerfiles`. Durante la transición,
   `oAppParams` y `oCajaParams` son únicamente alias de interfaz hacia
   esas mismas instancias; nunca crean ni destruyen objetos.
2. **Fuente de datos**. El motor recibe `IPerfilesUsuario`; no recibe
   `TUniConnection` ni contiene `TUniQuery`. `Recargar` llama primero a
   `ResincronizarPerfilFormulario` y después a
   `CargarPerfilFormulario`, porque la sobrecarga con usuario/grupo
   puede devolver la caché de la sesión actual.
3. **Lectura y edición separadas**. Los consumidores reciben
   `IParametrosAplicacion` / `IParametrosCaja`. Los dos editores
   reciben además `IParametrosEdicion` mediante un proveedor
   específico; no ven el diccionario interno.
4. **Sin referencias mixtas**. Las factorías devuelven interfaces y la
   raíz conserva solo referencias de interfaz. No se mantiene a la vez
   una referencia de objeto y otra de interfaz sobre la misma
   instancia.
5. **Orden de cierre**. Detener hilos, cerrar formularios, liberar los
   alias y las interfaces de parámetros, liberar las interfaces de
   perfiles y `TdmPerfiles`, y por último las conexiones. Así ninguna
   interfaz conserva un `TdmPerfiles` ya destruido.
6. **Bloqueo mínimo**. La lectura del perfil se hace fuera de la
   sección crítica. Bajo bloqueo solo se sustituye la instantánea del
   diccionario y se atienden getters/listados. Los efectos posteriores
   a la recarga, como aplicar flags de log, se ejecutan fuera del
   bloqueo.
7. **Ciclo del log**. `AplicarModosDepuracion` recibe
   `IParametrosAplicacion` desde XII-A, no se aplaza a XII-C.
8. **Compatibilidad exacta**. Se conservan las conversiones actuales:
   booleano verdadero solo para `True` o `1`; entero inválido usa el
   default; una tarifa existente pero vacía sigue vacía; el default
   `PVP` se usa cuando falta el parámetro; niveles de familia se
   limitan a `[1..9]`; las exclusiones App y Caja siguen separadas.
9. **Proyecto Delphi**. Toda unidad nueva se añade tanto a `fzam.dpr`
   como a `fzam.dproj`.

### Línea base a congelar

- Inventario exacto de `uses`, accesos a los globales, métodos,
  funciones libres y propagación por firmas.
- Capturas de los dos editores, número de claves por categoría y
  valores representativos antes de XII-A.
- Matriz de compilación Debug Win64, Release Win32 y Release Win64,
  con salida aislada y comparación contra los warnings ya existentes.
- Pruebas de humo de arranque, recarga, log en caliente, caja y lectura
  desde hilos.

Los conteos iniciales de la cabecera quedan como referencia histórica.
El inventario ejecutable de XII-0 será la fuente de verdad al abrir
cada lote.

### Avance registrado el 25/07/2026

- Inventario ejecutado sobre 612 ficheros Pascal: conteos directos y
  métodos coherentes con la cabecera; corregida la distinción entre
  menciones y cláusulas `uses`.
- Confirmadas cero lecturas de parámetros en secciones
  `initialization`.
- La incidencia `frxClass` de la primera matriz quedó aislada al abrir
  XII-A: el script elegía Studio 22.0 por un error al ordenar las
  versiones. Corregido el selector, Studio 37.0 compila la matriz
  completa.
- Pendientes de XII-0: obtener las capturas y pruebas funcionales
  contra BBDD de pruebas.

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

  IProveedorParametrosEdicion = interface
    ['{NUEVO-GUID}']
    function GetParametrosAppEdicion: IParametrosEdicion;
    function GetParametrosCajaEdicion: IParametrosEdicion;
    property ParametrosAppEdicion: IParametrosEdicion
      read GetParametrosAppEdicion;
    property ParametrosCajaEdicion: IParametrosEdicion
      read GetParametrosCajaEdicion;
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
- **Decisión cerrada en XII-0**: sustituir el `TUniQuery` +
  `AsignarConexion` por `IPerfilesUsuario.CargarPerfilFormulario`
  (sobrecarga con usuario/grupo). **Validado en XII-0**: antes de cargar
  hay que llamar a `ResincronizarPerfilFormulario`; el motor pierde
  `Uni` por completo y no conserva `AsignarConexion`.

Las unidades actuales quedan como implementaciones finas:

- `inLibAppParam`: `TParametrosAplicacion(TParametrosBase,
  IParametrosAplicacion)` — catálogo `InicializarParametrosApp`,
  `GetPath` (vía `inLibPathTokens`) y `AplicarFlagsLog`.
- `inLibCajaParam`: `TParametrosCaja(TParametrosBase,
  IParametrosCaja)` — catálogo `InicializarParametrosCaja`,
  `TarifaDefecto` y `NivelesFamiliaArqueo` como métodos (con el mismo
  saneo de rango [1..9] y el default 'PVP').

Propagación: `inMtoPrincipal` implementa `IProveedorParametros` e
`IProveedorParametrosEdicion`; `TfrmBase` y `TdmBase` añaden las
propiedades de lectura resueltas del propietario, igual que
`Conexiones` o `PerfilesUsuario`. Solo los editores resuelven el
proveedor de edición.

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
3. Añadir factorías de implementación que reciben
   `IPerfilesUsuario` y devuelven `IParametrosAplicacion` /
   `IParametrosCaja`. La raíz crea ambos servicios después de
   `TdmPerfiles`, publica los alias temporales y ejecuta la
   inicialización de los catálogos. No hay creación en
   `initialization` ni destrucción en `finalization`.
4. `inMtoPrincipal` implementa `IProveedorParametros` e
   `IProveedorParametrosEdicion`; `TfrmBase` y `TdmBase` añaden las
   propiedades de lectura (mismo molde `Supports(AOwner,...)` que las
   existentes).
5. Cambiar `inLibLog.AplicarModosDepuracion` para recibir
   `IParametrosAplicacion` y eliminar el ciclo con `inLibAppParam`.
6. Migrar los dos editores a `IParametrosEdicion.ListarDefiniciones`
   (construcción del `JvInspector`, `ResetearADefectos`) y `Recargar`.
   Desaparece todo uso externo de `.Params` y de
   `TParamDef` / `TAppParamDef`.
7. Añadir las unidades nuevas a `fzam.dpr` y `fzam.dproj` y verificar
   el orden de liberación de servicios en la raíz.

Pruebas (carpeta `PruebasParametrosFase12A/`, mismo esquema que
`PruebasConexionGlobalFase11A`):

- Estructurales:
  - `inLibParametrosIntf` no usa `Uni` ni unidades del proyecto.
  - Toda interfaz declara GUID.
  - 0 apariciones de `TParamDef|TAppParamDef` fuera de
    `inLibParametrosBase`.
  - 0 apariciones de `oAppParams\.Params|oCajaParams\.Params`.
    No usar `\.Params\b`: produce falsos positivos sobre componentes
    UniDAC legítimos.
  - 0 apariciones de `TObjectDictionary` en los editores.
  - 0 creación de servicios de parámetros en `initialization`.
- Compilación: matriz Delphi completa sin errores ni warnings nuevos.
- Unitarias con fuente de perfiles falsa: defaults, conversiones,
  exclusiones, huérfanos, copia de instantáneas, `QueryInterface`,
  vida de interfaces y lectores concurrentes durante una recarga.
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

Resultado esperado: comportamiento idéntico; el diff se limita al
motor y contratos nuevos, las dos implementaciones, los dos editores,
la raíz, las dos clases base, el log y los dos ficheros de proyecto;
~400 líneas duplicadas eliminadas; carrera de hilos cerrada.

### Resultado real de XII-A — 25/07/2026

Estado de implementación: **terminada**.

- Creados `inLibParametrosIntf` e `inLibParametrosBase`.
- Los catálogos conservan sus 49 claves App y 30 claves Caja.
- El motor usa `IPerfilesUsuario`, resincroniza antes de cargar y no
  depende de UniDAC.
- `oAppParams` / `oCajaParams` son alias de interfaz creados desde la
  raíz después de `TdmPerfiles`; no hay creación en `initialization`.
- La raíz libera parámetros antes de liberar perfiles y conexiones.
- `TfrmBase` / `TdmBase` propagan lectura; la raíz provee por separado
  las dos interfaces de edición.
- Los editores trabajan con copias `TParamInfo`; han desaparecido
  `.Params`, `TAppParamDef` y `TParamDef`.
- `inLibLog.AplicarModosDepuracion` recibe
  `IParametrosAplicacion`; el ciclo con `inLibAppParam` desaparece.
- Inventario tras XII-A: 98 accesos a miembros de los alias en 38
  unidades (66 App / 32 Caja). Ya no quedan accesos de ciclo de vida,
  edición ni diccionario mediante los alias.
- Pruebas estructurales y unitarias correctas en Win32/Win64.
- Matriz Delphi correcta: Debug Win64, Release Win32 y Release Win64,
  con 0 errores y exactamente los mismos avisos que XI-D
  (110/107/109).

Detalle en `PruebasParametrosFase12A/INFORME_PRUEBAS.md`. Queda
pendiente la batería funcional interactiva contra BBDD de pruebas
antes de considerar validado el comportamiento en ejecución.

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

El alcance no se limita a las 15 unidades que leen directamente los
globales. Al cambiar firmas se propaga a sus llamantes y alcanza unas
87 unidades. Se ejecuta en lotes compilables y reversibles:

- **XII-C1 — Filtros de usuario**: `inLibFiltroUsuario`,
  `SqlFiltroEmpAlmCaja` y sus llamantes.
- **XII-C2 — Caja, tarifas y resolución de artículos**:
  `inLibArticulosResolver`, `inLibArqueoTicket`, tickets y llamantes.
- **XII-C3 — Excel, fotos y API**: `inLibDevExp`, exportaciones,
  `inLibFotos`, `inLibFotosNube`, `inLibFactuzamApi` y llamantes.
- **XII-C4 — Ventas WS**: cola, hilo y todos los métodos estáticos de
  encolado/adjuntos. `TVentasWsCola.Activa` también se consulta desde
  `RegistrarFactura`, `RegistrarEventoSeguro` y adjuntos PDF; no basta
  con ampliar `IniciarHilo`.
- **XII-C5 — Verifactu, envío, reloj e hilos**:
  `inLibVerifactu`, `inLibVerifactuEnvio`, `inLibVerifactuCola`,
  `inLibRelojFiscal` y su grafo de llamantes.
- **XII-C6 — Barrido transversal**: `UniDataConn`,
  `inLibBuscarImpresora` y cualquier referencia residual.

Mecanismo según el caso:

1. **Parámetro explícito en la firma** (precedente
   `inLibBuscarImpresora(AContextoSesion)`): la rutina recibe
   `AParametros: IParametrosAplicacion` (o `IParametrosCaja`) y el
   llamante pasa su propiedad heredada. Es la opción por defecto.
2. **Hilos**: `TVerifactuCola.IniciarHilo` y
   `TVentasWsCola.IniciarHilo` amplían su firma para recibir la
   interfaz junto a `Conexiones`; el hilo guarda la referencia (las
   lecturas ya son seguras desde XII-A).
3. **Objetos con estado**: `TArticulosResolver` recibe la dependencia
   en el constructor. El singleton `TFotosArticulos` la recibe una vez
   desde la raíz; no se añade un parámetro repetido a cada método.
4. **Métodos estáticos de colas**: reciben la interfaz de parámetros
   en cada operación que decide si debe encolar.
5. **`inLibLog`** ya queda desacoplado en XII-A; los lotes C solo
   limpian llamantes residuales si aparecen.

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

Cada lote termina con inventario estructural, compilación completa y
una prueba funcional focalizada. Resultado esperado al cerrar XII-C:
solo la raíz y las dos unidades de parámetros mencionan los alias
globales.

---

## XII-D — Retirada y cierre

Cambios:

1. Marcar `oAppParams` / `oCajaParams` con `deprecated`, compilar y
   confirmar **cero warnings nuevos** y cero warnings `deprecated` de
   uso.
2. Retirar las variables públicas y las funciones libres
   `TarifaDefecto` / `NivelesFamiliaArqueo`. La creación ya reside en
   `inMtoPrincipal` desde XII-A; aquí solo desaparecen los alias de
   transición.
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
  la raíz, jamás `Free` ni `FreeAndNil`.
- **Orden de arranque**: las instancias nacen en la raíz después de
  `TdmPerfiles`. La auditoría de XII-0 no encontró lecturas de
  `oAppParams.*` / `oCajaParams.*` en secciones `initialization`.
- **Vida de perfiles**: el servicio conserva `IPerfilesUsuario`; esa
  referencia y los alias de parámetros deben liberarse antes de
  destruir manualmente `TdmPerfiles`.
- **`Recargar` vs. caché de perfiles**: invalidar siempre con
  `ResincronizarPerfilFormulario` antes de
  `CargarPerfilFormulario`.
- **Reentrada del log**: aplicar flags fuera de la sección crítica.
- **Regresión silenciosa en modales de impresión**: son 12 unidades de
  1 referencia; el riesgo es dejarse alguna. La comprobación
  estructural por carpeta la cubre.
- Cada subfase es una frontera lógica de rollback. Solo se crea un
  commit cuando el usuario lo solicite; hasta entonces se conserva el
  trabajo por lotes revisables.

## Orden y dependencias

XII-0 cierra diseño y línea base. XII-A es prerequisito de todo.
XII-B y XII-C son independientes entre sí, pero C se ejecuta en orden
C1 → C6 para mantener compilable el grafo de firmas. Ambas terminan
antes de XII-D. No abrir XII-D con referencias estructurales ni
warnings `deprecated` pendientes.
