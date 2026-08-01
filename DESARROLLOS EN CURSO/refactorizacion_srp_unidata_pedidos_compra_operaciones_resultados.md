# División SRP de `UniDataPedidosCompraOperaciones`

Fecha: 01/08/2026

## Resultado

La unidad generalista se ha sustituido por adaptadores UniDAC pequeños,
agrupados por operación o consumidor real:

| Unidad | Responsabilidad | Líneas | Rutinas |
| --- | --- | ---: | ---: |
| `UniDataPedidosCompraPendientes` | Sincronización, borrado y cálculo de pendientes | 352 | 13 |
| `UniDataPedidosCompraAlbaranComun` | Cierre y finalización compartida de albaranes | 294 | 5 |
| `UniDataPedidosCompraCreacionAlbaran` | Creación de albaranes desde pedidos | 650 | 24 |
| `UniDataPedidosCompraIncorporacionAlbaran` | Incorporación a albaranes existentes | 536 | 10 |
| `UniDataPedidosCompraRecepcion` | Coordinación transaccional de la recepción | 145 | 5 |
| `UniDataPedidosCompraOperaciones` | Fachada histórica de compatibilidad | 177 | 19 |

El archivo original vigilado pasa de 1.748 líneas y 57 rutinas a una
fachada de 177 líneas y 19 rutinas, sin SQL ni lógica de negocio propia.

## Contratos y consumidores

Se han añadido cuatro contratos estrechos:

- `IPedidosCompraPendientes`: generar, borrar y calcular pendientes.
- `ICreacionAlbaranPedidoCompra`: las dos variantes de creación.
- `IIncorporacionAlbaranPedidoCompra`: las dos variantes de incorporación.
- `IRecepcionPedidoCompra`: coordinación de una recepción completa.

`TdmPedidosCompra` consume solamente `IPedidosCompraPendientes` mediante
`CrearPendientesPedidoCompraUniDAC`. El formulario de pedidos de compra
consume solamente `IRecepcionPedidoCompra` mediante
`CrearRecepcionPedidoCompraUniDAC`.

`IPedidosCompra` y `CrearPedidosCompraUniDAC` se conservan para
compatibilidad con código externo y pruebas existentes. Ningún consumidor
de producción crea ya esa fachada. Esta se limita a componer y delegar en
los cuatro adaptadores; no actúa como repositorio generalista.

El tipo `TCeldaARecibir` se obtiene de `inLibGridPivoteCompraTipos`, por lo
que los contratos y adaptadores ya no dependen de la implementación completa
del grid de compra.

## Salvaguardas

`comprobar_tamano_clases.ps1` vigila las seis unidades y las cinco clases
adaptadoras. `comprobar_flujos_largos.ps1` sigue las rutinas de recepción en
sus nuevas ubicaciones.

Comprobaciones realizadas:

- Compilación aislada de las seis unidades: correcta en Win32 y Win64.
- Pruebas DUnitX de `PruebasPedidosCompra`: 7 de 7 correctas en Win32 y
  Win64, incluidas las dos pruebas de contratos estrechos.
- Compilación completa de `FactuzamTests`: correcta en Win32 y Win64.
- Suite completa: 545 de 545 pruebas correctas, sin fugas, en Win32 y
  Win64.
- Estilo: correcto; 0 `Exit`, 0 `Continue` y 0 tabuladores en las nuevas
  unidades.
- Dependencias de capa: correctas, sin usos `inLib* -> UniData*`.
- Segregación de interfaces: correcta.
- Flujos largos: correcto; la creación con cantidades queda en 48 líneas.
- XML de `fzam.dproj` y `tests/FactuzamTests.dproj`: válido.

El control global de tamaños conserva una incidencia concurrente ajena a
esta división en `TfrmMtoArticulos` (3.303 líneas frente al tope 3.300).
Todos los límites nuevos de pedidos de compra quedan alcanzados.

La generación del ejecutable principal no llega al enlace por recursos
ausentes del proyecto: `fzam.$manifest` en Win32 y `Fzam.res` en Win64. En
Win64 el compilador sí completó previamente todas las unidades Delphi,
incluidos los dos consumidores modificados.

No se ha creado ningún commit.
