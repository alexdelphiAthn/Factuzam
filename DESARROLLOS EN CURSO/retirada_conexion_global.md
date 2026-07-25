# Retirada de la conexión global `oConn` — Fase XI

Fecha: 25/07/2026

Continuación natural de las fases I a X. Aquellas retiraron el estado
global de conexiones, permisos, auditoría, monitor SQL, perfiles, filtros
y contexto de sesión. Queda una sola variable global viva en
`inLibGlobalVar`: la conexión principal `oConn`.

Estado al abrir la fase: **939 apariciones en 933 líneas de 111
unidades**.

---

## Por qué se divide por capas

`oConn` no es un dato, es un recurso. Sustituirla de golpe obliga a
decidir simultáneamente tres cosas distintas:

1. de dónde saca la conexión un formulario o un módulo de datos;
2. cómo recibe la conexión una librería sin formulario;
3. cuándo se puede borrar la declaración global.

Las tres tienen respuestas ya construidas en fases anteriores, pero cada
una con un mecanismo diferente. Mezclarlas en un único corte impide
localizar el origen de cualquier regresión, así que la fase se parte en
cuatro subfases con la misma frontera que se usó en X-A/B/C/D: primero
los consumidores, al final la compatibilidad.

## Mecanismos disponibles

Ya existen y no hay que inventar nada:

- `IServicioConexiones` (`inLibConexionesIntf`), con
  `ConexionPrincipal` y `CrearConexion`.
- `IProveedorConexiones`, que propaga el servicio por propietario.
- `TfrmBase.ConexionPrincipal` y `TdmBase.ConexionPrincipal`, que
  resuelven la conexión desde el servicio heredado.
- `TServicioConexionesUniDAC`, la implementación que envuelve
  `dmConn.conUni`.

Los 253 enlaces persistentes `Connection = dmConn.conUni` de 52 DFM son
independientes de `oConn` y se conservan en todas las subfases.

---

## XI-A — Formularios, modales y módulos de datos *(aplicada)*

Alcance: unidades cuya clase desciende de `TfrmBase` o de `TdmBase`, y
solo las referencias que viven dentro de un método de esa clase.

Cambio: `oConn` → `ConexionPrincipal`.

No hace falta inyectar nada: la propiedad ya está publicada en las dos
clases base y se hereda del propietario en el constructor.

Resultado: **754 líneas en 78 unidades**. Quedan 183 apariciones en
179 líneas de 38 unidades. Ver
`PruebasConexionGlobalFase11A/INFORME_PRUEBAS.md`.

## XI-B — Consumidores que no heredaban de las bases

### XI-B1 — Formularios directos de `TForm` *(aplicada)*

`TfrmStockConsulta` y `TfrmModalFacturarAlbaranesFechas` pasan a heredar
de `TfrmBase`. Sus DFM cambian la raíz de `object` a `inherited`, que es
el único cambio visual de la fase.

La consulta de stock deja además de duplicar `FPermisos`,
`FPerfilesUsuario`, `FContextoSesion`, sus tres asignadores y el
constructor de inyección. Los servicios llegan ahora por la jerarquía de
propietarios de `TfrmBase`. La función `MostrarStockConsulta` solo recibe
el artículo y el SKU; sus tres llamantes ya no transportan servicios.

Resultado: **14 apariciones retiradas**. Quedan 169 apariciones en 165
líneas de 36 unidades. De las 68 apariciones iniciales de XI-B quedan
54 para XI-B2/B3/B4.

Al abrir XI-B, seis unidades de la capa visual y de datos declaraban su
clase sobre `TForm` o `TDataModule` en lugar de las clases base del
proyecto:

| Unidad | Refs | Clase inicial | Estado |
| --- | ---: | --- | --- |
| `src/Caja/DataModules/UniDataTraspaso.pas` | 17 | `TDataModule` | Pendiente |
| `src/Caja/DataModules/UniDataCaja.pas` | 13 | `TDataModule` | Pendiente |
| `src/Forms/inMtoStockConsulta.pas` | 13 | `TForm` | XI-B1 aplicada |
| `src/DataModules/UniDataConsultaOpe.pas` | 9 | `TDataModule` | Pendiente |
| `src/Modals/inMtoModalFacturarAlbaranesFechas.pas` | 1 | `TForm` | XI-B1 aplicada |
| `src/Lib/inLibAtributosPaleta.pas` | 8 | Funciones de unidad | Pendiente |

Para los módulos de datos y las funciones de unidad que quedan se
decidirá entre herencia de `TdmBase` e inyección explícita de
`IServicioConexiones`, según su responsabilidad y ciclo de vida.

También entran aquí las rutinas de unidad de la capa visual que hoy leen
la global porque no tienen `Self`:

- `inMtoModalFacturarTicket.pas` y `inMtoModalSerieFechaFactura.pas`:
  resuelven la conexión sobre el formulario que acaban de crear.
- `inMtoModalVerifactuDecl.AnexoEmpresasInstalacionHtml`: recibe la
  conexión como parámetro.
- `inMtoPrincipal.RegistrarEventoFiscalSeguro` y
  `inMtoAppParam.RegistrarCambioConfiguracionVerifactuSeguro`: reciben la
  conexión como parámetro desde sus llamantes.

Resultado esperado al cerrar XI-B: **68 apariciones retiradas**.

## XI-C — Librerías, informes y procesos auxiliares *(aplicada)*

Alcance: las unidades `inLib*` sin formulario. Es donde vive el grueso de
lo que queda:

| Grupo | Unidades | Refs |
| --- | --- | ---: |
| Contadores de línea | `inLibContadorLineas` | 23 |
| Compras y sesiones | `inLibComprasSesiones`, `inLibComprasSesionesMaterializar` | 19 |
| Fotografías | `inLibFotos` | 17 |
| Tickets e impresión | `inLibGenerarTicketBD`, `inLibGenerarTicket`, `inLibGenerarTicketCaja`, `inLibArqueoTicket`, `inLibCorreoTickets` | 18 |
| Tablas y series | `inLibtb` | 6 |
| Facturación | `inLibFacturas`, `inLibFormatoDocumento` | 6 |
| Resto | `inLibData`, `inLibDocumentosTrabajo`, `inLibGenBusq`, `inLibShowMto`, `inLibInventarioNube`, `inLibUnidadesMedida`, `inLibConfigCampos`, `inLibAppParam`, `inLibCajaParam`, `inLibFaseCobro`, `inLibArticulosValidador`, `inLibVentasCalendario`, `inLibInformesGuiasCache`, `UniDataInventarios` | 19 |

Resultado aplicado: las librerías `inLib*` quedan sin consumidores de
`oConn`. El total del proyecto baja de 169 a **62 apariciones en 62
líneas de 8 unidades**.

Cambio, en este orden de preferencia:

1. si la rutina abre una consulta puntual, recibe
   `AConexion: TUniConnection` como primer parámetro, igual que ya hace
   `inLibData.AlmacenPerteneceEmpresa`;
2. si además necesita crear conexiones de trabajo o comprobar
   disponibilidad, recibe `IServicioConexiones`;
3. si es una clase con estado (cachés, validadores), la conexión se
   entrega en el constructor y se guarda como campo.

`inLibContadorLineas` merece atención aparte: abre y cierra transacciones
sobre la conexión que recibe (`InTransaction` / `StartTransaction` /
`Commit` / `Rollback`). El parámetro tiene que ser la **misma** conexión
que usa el llamante, no una nueva del pool, o las transacciones anidadas
dejarán de verse entre sí.

## XI-D — Retirada de la global y barrera *(aplicada)*

La compatibilidad queda retirada:

1. desaparece `oConn := FDmConn.conUni;` de `inMtoPrincipal`;
2. desaparecen la declaración y la inicialización de `oConn` en
   `inLibGlobalVar`, que deja también de importar `Uni`;
3. `TdmCajaOpe`, `TdmTraspaso` y `TdmConsultaOpe` reciben
   `TUniConnection` en el constructor, antes de ejecutar
   `DataModuleCreate`;
4. los auxiliares fiscales de principal, parámetros y declaración
   Verifactu reciben la conexión explícitamente;
5. se retiran cuatro `uses inLibGlobalVar` huérfanos y se actualiza la
   detección histórica de X-D;
6. la barrera anti-regresión exige **cero referencias** a `oConn` en
   `src` y `fzam.dpr`.

Resultado final de la Fase XI: **0 apariciones, 0 líneas y 0 unidades**.

---

## Reglas que se mantienen en toda la fase

- XI-B1 modifica solo la raíz de los dos DFM que pasan a herencia visual.
  No se modifica ningún enlace persistente de conexión.
- Se conservan los 253 enlaces persistentes
  `Connection = dmConn.conUni` de 52 ficheros DFM.
- No hay cambios de esquema ni scripts SQL.
- `factuzam_original.sql` no se toca.
- Máximo 80 columnas; una instrucción por línea.
