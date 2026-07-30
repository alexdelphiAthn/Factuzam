# Capas §3.3 — `inLib*` → `UniData*` (resultados)

Fecha: 30/07/2026. Opción A completada. Sin commit.

**Estado de la verificación: VALIDADA EN AISLADO.** Trinquete, pruebas
y compilación del proyecto DUnitX confirmados por el autor (§5). Queda
abierto lo de §8.

**Este trabajo es una fusión de dos hilos concurrentes.** Mientras se
preparaba, otro proceso estaba tocando los mismos ficheros. Se detuvo la
escritura, se volvió a leer el árbol y se aplicó encima solo lo que
faltaba. Ver §6.

---

## 1. Corrección del hallazgo

El hallazgo hablaba de **6 units**. La medición dio **8 units y 10
aristas**: faltaban dos de `src\Caja\Lib`.

| # | Unidad `inLib*` | Dependencia `UniData*` | Categoría |
|---|---|---|---|
| 1-3 | `inLibFacturasComposicion` | `UniDataFacturasRepositorio`, `UniDataArticulosResolverRepositorio`, `UniDataVerifactuColaRepositorio` | cableado |
| 4 | `inLibFacturasRepositorio` | `UniDataFacturasRepositorio` | fachada |
| 5 | `inLibArticulosValidador` | `UniDataArticulosValidadorRepositorio` | fachada |
| 6 | `inLibArticulosAtributosLookup` | `UniDataArticulosAtributosRepositorio` | fachada |
| 7 | `inLibCajaOpeComposicion` | `UniDataCajaConsultasRepositorio` | cableado |
| 8 | `inLibCajaConsultasRepositorio` | `UniDataCajaConsultasRepositorio` | fachada — **no estaba en la lista** |
| 9 | `inLibColumnasDocumento` | `UniDataGen` | deuda |
| 10 | `inLibGridColumnChooser` | `UniDataConn` | deuda |

Dos matices más:

- **Las dos «deuda» no eran el mismo problema.** `inLibGridColumnChooser`
  → `UniDataConn` era un `uses` **muerto**: ningún símbolo de
  `UniDataConn` aparecía en el cuerpo. Solo `inLibColumnasDocumento`
  necesitaba contrato.
- **La infracción era más ancha que el recuento.** Cinco units `inLib*`
  más (`inLibFotos`, `inLibGridArticulos`, `inLibGridPivoteVenta`,
  `inLibColumnasSkuModoSku`, `inLibColumnasSkuModoTallas`) construían
  repositorios de persistencia llamando a `CrearValidadorArticulosBase`
  / `CrearLookupAtributosArticulosBase`. No salían en el trinquete
  porque la fachada `inLib*` les escondía el `uses UniData*`. El lavado
  de dependencia no las hacía menos infractoras.

## 2. Resultado

**10 aristas → 0**, medido sobre el árbol tal como queda en disco. El
tope del script queda en **0**.

Las cuatro fachadas se han **eliminado**, no reubicado. Están en
`_to_delete\fachadas_capas_3_3\` para que las borres tú (`device_bash`
no puede borrar en la carpeta montada).

| Fachada eliminada | Consumidores | Sustituto |
|---|---:|---|
| `inLibFacturasRepositorio` | 0 | — |
| `inLibCajaConsultasRepositorio` | 0 | — |
| `inLibArticulosValidador` | 24 | `inLibArticulosValidadorIntf` (tipos) + `UniDataArticulosValidadorRepositorio` (helpers) |
| `inLibArticulosAtributosLookup` | 11 | `inLibArticulosAtributosIntf` |

Las dos primeras solo las citaba `fzam.dpr`: alias de tipo sin un solo
consumidor.

## 3. Opción A aplicada

La raíz de composición ya existía y estaba bien formada: `TfrmBase`
(`src\Core\inMtoFrmBase.pas`) construye `CrearResolverArticulos`,
`CrearValidadorArticulos` y `CrearLookupAtributosArticulos` con catálogo
SQL e incidencias cableados. Las factorías `inLib*` duplicaban ese
trabajo y lo hacían peor: construían los repositorios **sin** catálogo
ni incidencias.

### 3.1 Las factorías reciben lo ya construido

```pascal
function CrearServiciosFactura(
  AConexion: TUniConnection;
  const ARepositorio: IRepositorioFacturas;
  const AArticulosResolver: IArticulosResolver;
  const AVerifactuCola: IServicioVerifactuCola
): TServiciosFactura;
```

Sigue construyendo validador fiscal, calculador, borrado y efectos: son
piezas de dominio que viven en `inLib*`.
`CrearServiciosOperacionCaja` recibe `IRepositorioConsultasCaja` en
lugar del par `ICatalogoSql` + `IRegistroIncidenciasSql` con el que lo
construía.

Los tres consumidores son `inMto*`, capa a la que el diagrama sí
permite conocer `UniData*`:

| Consumidor | Construye ahora |
|---|---|
| `inMtoFacturasBase` | `TRepositorioFacturas` + `CrearResolverArticulos` heredado + cola VERI*FACTU |
| `inMtoCajaImpresorVenta` | los tres adaptadores de factura |
| `inMtoCajaOpe` | `TRepositorioConsultasCaja` |

### 3.2 Fin de la construcción encubierta

Donde había

```pascal
Val := FConfig.ValidadorArticulos;
if not Assigned(Val) then
  Val := CrearValidadorArticulosBase(FConfig.Conexion);
```

hay ahora `raise Exception.Create(SErrorValidadorArticulosNoInyectado)`.

Ese camino debería ser inalcanzable: las **nueve** construcciones de
`TConfigColumnasSku` del proyecto ya rellenan `ValidadorArticulos` y
`LookupAtributos` desde `TfrmBase`, y los dos constructores de
`TGridArticulosLineas` reciben instancias reales. Comprobado uno por
uno. El fallo es ruidoso, que es lo que no era el `nil` silencioso.

Dos casos aparte:

- `inLibFotos` usa el singleton `oFotos`. El validador se inyecta en
  `AsignarConexion`, que llama un solo sitio: `inMtoPrincipal`. Sin
  inyección, `CompletarSkuDesdeCodigoBarras` no hace nada — su
  comportamiento cuando no puede resolver.
- `inLibColumnasSku` construía el lookup en `TProveedorValoresSku`. Esa
  clase y `CrearProveedorValoresSku` **no tenían consumidores**: se han
  borrado. El contrato `IProveedorValoresSku` sigue declarado en
  `inLibColumnasSkuIntf`.

## 4. Fase 2b — el trinquete

Lo implementó el hilo concurrente y **se ha conservado su versión**:
`$maximoUsosLibADatos` en `comprobar_dependencias_capas.ps1`, que barre
todo el árbol enumerado por `fzam.dpr`, incluido `src\Caja\Lib`.

Único cambio aportado aquí: **el tope baja de 8 a 0**, porque las 10
aristas están cerradas. Ya solo puede quedarse ahí.

`$dependenciasPermitidas` sigue vacío: §14.1 dice «no se añaden
excepciones ni listas blancas» y no se ha añadido ninguna.

## 5. Medición y validación

Ejecutado por el autor sobre el árbol resultante:

| Comprobación | Resultado |
|---|---|
| `comprobar_dependencias_capas.ps1` | **0/0** aristas `inLib*` → `UniData*`, 485 unidades, código de salida 0 |
| `PruebasColumnasDocumento` (Release Win32) | **40/40** |
| `PruebasColumnasDocumento` (Release Win64) | **40/40** |
| Proyecto DUnitX | compila en Win32 y Win64 |
| Suite global | 392/398 |

Los seis casos rojos de la suite **no pertenecen a este trabajo**: tres
son recuentos desactualizados del catálogo SQL y tres son pruebas que no
registran el proveedor MySQL, ambos de desarrollos concurrentes.

Pruebas negativas del trinquete, todas con código de salida 1:

| Caso | Resultado |
|---|---|
| reintroducir 1 arista con tope 0 | detectado |
| 2 aristas con tope 1 | detectado |
| 0 aristas con tope 3 (por debajo) | aviso, sin fallo |

Comprobaciones estáticas sobre los 36 ficheros tocados:

- ningún símbolo de las 4 fachadas queda referenciado;
- ninguna unidad usa un símbolo cuyo `uses` se haya quedado fuera
  (mapa símbolo→unidad de 18 entradas);
- sin duplicados nuevos en cláusulas `uses`;
- 0 líneas nuevas de más de 80 columnas;
- BOM y CRLF de cada fichero conservados respecto al original;
- md5 de los 36 verificado en disco justo antes de escribir: ninguno
  había cambiado desde su lectura.

## 6. La fusión

A las 17:47-17:54 otro proceso modificó 15 de los ficheros que este
trabajo tenía preparados, incluido `comprobar_dependencias_capas.ps1`.
Se abortó la escritura antes de tocar nada.

Ese hilo había hecho: el trinquete de Fase 2b y las **dos** correcciones
de deuda (`inLibGridColumnChooser` y el contrato
`IAnfitrionDatosDocumento` para `inLibColumnasDocumento`). Dejó
pendientes las 8 aristas de cableado y fachada.

Criterio de fusión: **se conserva todo lo suyo y se añade encima solo lo
que faltaba.** En concreto se descartó de este lado un contrato
equivalente (`IDataModuleDocumento`) que hacía lo mismo que su
`IAnfitrionDatosDocumento`, y su implementación del trinquete se
mantuvo tal cual. Sus ficheros no se han tocado salvo para añadir lo
propio de las 8 aristas.

## 7. Ficheros

**Movidos a `_to_delete\fachadas_capas_3_3\` (4).**

**Modificados (36):** 10 `UniData*`, 12 `inMto*`, 11 `inLib*`,
`fzam.dpr`, `fzam.dproj` y `scripts\comprobar_dependencias_capas.ps1`.

## 8. Qué falta para cerrar

1. **Release Win32 y Win64 de `fzam.exe`**. Lo validado en §5 es el
   proyecto DUnitX; falta confirmar la aplicación.
2. Borrar `_to_delete\fachadas_capas_3_3\`.
3. Pruebas funcionales de lo tocado: alta de línea en albaranes,
   pedidos, facturas y sus versiones de compra; inventarios; traspaso de
   caja; operación de caja; impresión de factura A4 desde caja; y una
   lectura de código de barras en un informe con fotos (`inLibFotos`),
   el único cambio con caída silenciosa si faltara la inyección.
4. Promover el tope 0 a `LIBRO_DE_ESTILO_DELPHI.md` §14.1 como
   invariante, no como trinquete transitorio.

## 9. Registro de unidades en `fzam.dpr`

Al compilar apareció `UniDataCatalogoSqlAplicacion.pas(39) F2613`. No
venía de este trabajo: `UniDataComprasSesionesMaterializacionRepositorio`
**nunca** estuvo en `fzam.dpr` (`git show HEAD:fzam.dpr` lo confirma),
solo en el `.dproj`. Como el proyecto enumera cada unidad en el `.dpr` y
`src\DataModules` no está en el *search path*, no se encontraba.

Resolviendo el grafo de `uses` completo aparecieron **diez** unidades en
disco sin registrar en `fzam.dpr`, no una:

| Unidad | Origen |
|---|---|
| `UniDataComprasSesionesMaterializacionRepositorio` | compras (C1-C7) |
| `inLibAnfitrionDatosIntf` | hilo concurrente — no estaba ni en `.dpr` ni en `.dproj` |
| `inLibModoTallasIntf`, `…Modelo`, `…Lineas`, `…Conversion`, `…Buscador`, `…Presentacion`, `inLibDistribuidorTallas`, `UniDataModoTallas` | T1-T6 |

Las ocho de tallas no habrían compilado nunca. Las diez quedan
registradas.

**Contención en los ficheros de proyecto.** A las 18:09:39 el hilo
concurrente reescribió `fzam.dpr` y `fzam.dproj`, borró esas diez altas
y devolvió al `.dpr` una fachada ya inexistente en disco. Se rehízo. Si
vuelve a ocurrir, el síntoma es un `F2613` sin relación con el código:
antes de diagnosticar, comprobar que las diez altas siguen presentes.
