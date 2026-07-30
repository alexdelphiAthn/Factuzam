# Fase 2b — Sellar la dirección de capas (Opción A)

Fecha: 30/07/2026.

Estado: **IMPLEMENTADA; COMPILACIÓN GLOBAL APLAZADA**. Como en las
tandas Verifactu, la compilación conjunta y las baterías DUnitX quedan
aplazadas hasta cerrar la tanda concurrente de traducciones.

## 1. Decisión

Se adopta la **Opción A** de PLAN_SOLID §3.3: el cableado de
implementaciones `UniData*` pertenece a la raíz de composición real
(`fzam.dpr` / `TfrmMtoPrincipal` / Core). Ninguna unidad `inLib*` nueva
usa `UniData*`; las composiciones y alias existentes son deuda
transitoria vigilada, con tope que solo baja hasta cero. La regla queda
promovida a §14.1 del libro de estilo.

## 2. Medición

Antes de la tanda, con el mismo criterio del script (unidades `inLib*`
cuyo `uses` nombra unidades `UniData*`):

```text
10 usos en 8 unidades
```

Los dos usos sin coartada de composición se corrigen en esta tanda.
Quedan:

```text
inLibArticulosAtributosLookup  -> UniDataArticulosAtributosRepositorio
inLibArticulosValidador        -> UniDataArticulosValidadorRepositorio
inLibCajaConsultasRepositorio  -> UniDataCajaConsultasRepositorio
inLibCajaOpeComposicion        -> UniDataCajaConsultasRepositorio
inLibFacturasComposicion       -> UniDataArticulosResolverRepositorio
inLibFacturasComposicion       -> UniDataFacturasRepositorio
inLibFacturasComposicion       -> UniDataVerifactuColaRepositorio
inLibFacturasRepositorio       -> UniDataFacturasRepositorio

8 usos en 6 unidades
```

Todos son composición o alias en retirada hacia la raíz real; cada
fascículo que suba uno a la raíz baja el tope.

## 3. Corrección de los casos sin coartada

### `inLibColumnasDocumento` (usaba `UniDataGen`)

La dependencia existía por dos rutinas acopladas a `TdmBase`. La tanda
las separa por naturaleza:

- Contrato nuevo `IAnfitrionDatosDocumento` en
  `inLibAnfitrionDatosIntf` (expone la tabla principal y la asignación
  del maestro de cabecera). `TdmBase` lo implementa en `UniDataGen`;
  su `AsignarMaestroCabecera` virtual ya encajaba con el contrato.
- `ConfigurarTablaPrincipalDocumento` recibe ahora el contrato en vez
  de `TdmBase`. Los ocho formularios llamantes no cambian la llamada:
  el data module se convierte implícitamente a la interfaz.
- `TClaseDataModuleDocumento` y `AsegurarDataModuleDocumento` son
  ciclo de vida del data module, no dominio: se mueven a `UniDataGen`.
  Los ocho formularios (`inMtoAlbaranes`, `inMtoAlbaranesCompra`,
  `inMtoDevolucionesCompra`, `inMtoFacturasBase`,
  `inMtoFacturasCompra`, `inMtoInventarios`, `inMtoPedidos`,
  `inMtoPedidosCompra`) añaden `UniDataGen` al `uses`; las llamadas
  quedan intactas.
- `PruebasColumnasDocumento` ya usaba `UniDataGen` y compila sin
  cambios; sus casos cubren las dos rutinas movidas y el cableado por
  contrato.

### `inLibGridColumnChooser` (usaba `UniDataConn`)

El `uses` era código muerto: ningún símbolo de `UniDataConn` se
referencia en la unidad (la conexión llega por `AQuery.Connection`).
Se elimina la cláusula.

Nota posterior: ese `uses` cargaba por arrastre `MySQLUniProvider` en
el enlace de `FactuzamTests` (vía `PruebasGestorGuiasGridMto`). Al
retirarlo, tres casos de `PruebasConexiones` dejaron de poder crear la
conexión. El proveedor se registra ahora explícito en el `uses` de
`FactuzamTests.dpr`: el registro deja de depender de un arrastre
accidental.

## 4. Trinquete

`comprobar_dependencias_capas.ps1` cuenta ahora la dirección
`inLib*` → `UniData*` sobre las mismas unidades del grafo del proyecto:

- lista siempre la deuda con formato
  `unidad -> dependencia (ruta)`;
- falla con salida no-cero si los usos superan el tope;
- tope congelado en **8**; solo puede bajar;
- la línea de resumen añade `Usos inLib*->UniData*: N/8 en M unidades`.

No hay lista blanca: la deuda es visible en cada ejecución y el tope es
un trinquete, no una excepción.

## 5. Regla promovida al libro de estilo

§14.1 añade: *"`inLib*` no usa ninguna unidad `UniData*` (Opción A,
Fase 2b): la persistencia entra por contrato `inLib*Intf` y el cableado
de implementaciones vive en la raíz de composición. Los usos existentes
son deuda transitoria: el script los cuenta y su tope solo baja, hasta
cero."*

## 6. Ficheros tocados

- `src/Lib/inLibAnfitrionDatosIntf.pas` (nueva, contrato)
- `src/Lib/inLibColumnasDocumento.pas`
- `src/Lib/inLibGridColumnChooser.pas`
- `src/DataModules/UniDataGen.pas`
- ocho formularios de documentos (alta de `UniDataGen` en `uses`)
- `fzam.dpr` (alta de la unidad nueva)
- `scripts/comprobar_dependencias_capas.ps1`
- `LIBRO_DE_ESTILO_DELPHI.md` §14.1
- `PLAN_SOLID.md` (§3.3, Fase 2b, §6 y §8)

## 7. Pendiente

1. Ejecutar `comprobar_dependencias_capas.ps1` y la batería completa
   con la compilación conjunta al cerrar traducciones
   (`PruebasColumnasDocumento` incluida).
2. Retirar los 8 usos restantes subiendo la construcción a la raíz de
   composición, empezando por `inLibFacturasComposicion` (3 usos).
   Cada retirada baja el tope del script.
