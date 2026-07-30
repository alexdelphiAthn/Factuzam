# Manual de administración del SQL por perfiles

## 1. Objetivo

El catálogo SQL permite corregir determinadas consultas sin recompilar ni
sustituir `fzam.exe`.

El dominio no accede a los perfiles ni conoce el texto SQL. Cada operación
llama a un repositorio mediante una interfaz. La implementación UniDAC del
repositorio decide si utiliza:

1. El SQL base incluido y probado con el ejecutable.
2. Una personalización activa guardada en `fza_usuarios_perfiles`.

El catálogo actual contiene 66 operaciones de nueve repositorios:

- 63 lecturas que admiten perfil y fallback al SQL base;
- una comprobación técnica de esquema que usa siempre el SQL base;
- dos escrituras de Facturas registradas como `pesSoloBase`.

El patrón se extenderá por fascículos al resto de repositorios.

## 2. Componentes

| Unidad | Responsabilidad |
|---|---|
| `inLibCatalogoSqlIntf` | Contratos y metadatos estables del catálogo |
| `inLibCatalogoSqlValidacion` | Valida definición, tipo, parámetros, campos de salida, DDL y sentencias múltiples |
| `inLibCatalogoSqlPerfiles` | Resuelve SQL base o SQL de perfil |
| `inLibCatalogoSqlRegistro` | Registro central, explícito y sin variables globales |
| `inLibCatalogoSqlIncidencias` | Conserva la última causa de fallback por operación |
| `inLibCatalogoSqlEjecucion` | Ejecuta lecturas y reintenta una vez con el SQL base |
| `inLibCatalogoSqlAdmin` | Publica, revisa y exporta el catálogo completo |
| `UniDataCatalogoSqlValidacion` | Comprueba en ejecución los campos realmente devueltos por UniDAC |
| `inLibComprasSesionesIntf` | Contrato del repositorio de sesiones |
| `UniDataComprasSesionesRepositorio` | Implementación UniDAC y fallback |
| `UniDataFacturasRepositorio` | Implementación UniDAC del contrato de Facturas |
| `UniDataCajaConsultasRepositorio` | Implementación UniDAC de las consultas de Caja |
| `inLibArticulosResolverIntf` | Contrato de resultados del resolver de artículos |
| `UniDataArticulosResolverRepositorio` | Implementación UniDAC de precios, costes, PMP y SKU |
| `inLibArticulosValidadorIntf` | Contrato de resolución de entradas de artículo |
| `UniDataArticulosValidadorRepositorio` | Implementación UniDAC de validación y búsqueda canónica |
| `inLibArticulosAtributosIntf` | Contrato de atributos y propiedades de artículo |
| `UniDataArticulosAtributosRepositorio` | Implementación UniDAC de selectores de atributos |
| `inLibTraspasoTicketIntf` | Contrato de lectura para tickets de traspaso |
| `UniDataTraspasoTicketRepositorio` | Implementación UniDAC de solicitudes, movimientos y stock del ticket |
| `inLibArqueoIntf` | Contrato de resultados y cálculo del arqueo de Caja |
| `UniDataArqueoRepositorio` | Implementación UniDAC del read model principal de arqueo |
| `inLibArqueoTicketIntf` | Contrato de resúmenes, cabecera e históricos de arqueo |
| `UniDataArqueoTicketRepositorio` | Implementación UniDAC de las lecturas de presentación del arqueo |
| `UniDataCatalogoSqlAplicacion` | Composición única de todas las definiciones publicadas |

Cada definición declara además una política:

| Política | Uso del perfil | Comportamiento |
|---|---|---|
| `pesSoloBase` | No | Ejecuta siempre el SQL incluido en el ejecutable y no publica una fila |
| `pesPerfilLecturaConFallback` | Sí | Permite sustituir un `SELECT` y reintenta una vez con el SQL base |
| `pesPerfilEscrituraTransaccional` | Sí | Reserva el perfil para una escritura protegida por transacción |

La política de escritura no autoriza un reintento directo. Su ejecutor debe
hacer `Rollback` antes de volver al SQL base.

## 3. Cómo se identifica una consulta

Un `inLib*` no tiene una clave de perfil propia. La clave solo se consulta
cuando la pantalla tiene `oGetSQLFromDB=True`. Si está a `False`, no se
lee ninguna `KEY_USUPER` y el repositorio utiliza directamente su SQL base.

Todas las consultas catalogadas usan:

```text
KEY_USUPER = SQL_REPOSITORIOS
```

Cada operación tiene una `SUBKEY_USUPER` estable:

```text
SQL__RepositorioComprasSesiones__ObtenerSiguienteLinea
SQL__RepositorioComprasSesiones__ConsultarCantidadesLinea
SQL__RepositorioFacturas__ExisteSerieOtraEmpresa
SQL__RepositorioConsultasCaja__ConsultarStock
SQL__RepositorioArticulosResolver__ResolverPrecio
SQL__RepositorioArticulosValidador__ResolverEntrada
SQL__RepositorioArticulosAtributos__ObtenerAtributos
SQL__RepositorioTraspasoTicket__ObtenerStock
SQL__RepositorioArqueoCaja__CalcularOperaciones
SQL__RepositorioArqueoTicket__ListarResumenSeccion
```

La subclave identifica `Repositorio + Operación`, no el nombre físico de
la antigua unidad `inLib*`. Así se puede reorganizar el código sin tener
que renombrar las filas de configuración.

`SQL_REPOSITORIOS` es un catálogo compartido. Varias pantallas pueden
activar `oGetSQLFromDB` y consumir la misma operación sin duplicar el SQL
bajo la clave de cada formulario. Cada pantalla conserva su propio
interruptor: activar una no activa las demás.

Una modificación del catálogo sí afecta a todas las pantallas activadas
que llamen a esa operación. Antes de publicarla hay que repasar todos los
consumidores del método del repositorio, no solo la pantalla desde la que
se detectó la incidencia.

| Decisión | `KEY_USUPER` | `SUBKEY_USUPER` | Alcance |
|---|---|---|---|
| Activar perfiles SQL | `frmMtoXxx` | `oGetSQLFromDB` | Solo ese formulario |
| Definir el SQL | `SQL_REPOSITORIOS` | `SQL__Repositorio__Operacion` | Todos los consumidores activados |

El contenido de la fila es:

| Columna | Uso |
|---|---|
| `USUARIO_GRUPO_USUPER` | Debe ser `Todos` para SQL de negocio |
| `KEY_USUPER` | Catálogo compartido `SQL_REPOSITORIOS` |
| `SUBKEY_USUPER` | Clave estable de la operación |
| `VALUE_USUPER` | Estado y metadatos; empieza por `S` o `N` |
| `VALUE_TEXT_USUPER` | Texto SQL completo |
| `INSTANTE_MODIF` / `USUARIO_MODIF` | Auditoría del cambio |

Ejemplo de valor activo:

```text
S;V=1;BASE=huella-del-sql-base
```

El catálogo solo considera activa una entrada cuyo `VALUE_USUPER` empieza
por `S`. Para desactivarla se cambia la primera letra a `N`.

## 4. Activación

El interruptor continúa siendo `oGetSQLFromDB`. Esta propiedad sí vive en
el perfil de cada formulario, por ejemplo:

```text
KEY_USUPER = frmMtoComprasSesiones
SUBKEY_USUPER = oGetSQLFromDB
VALUE_USUPER = True
```

1. En el perfil del formulario consumidor, establecer
   `oGetSQLFromDB=True`. Además de ComprasSesiones, Facturas y Caja,
   cualquier pantalla derivada de `TfrmBase` que cree el resolver, el
   validador, el lookup de atributos o los repositorios de tickets de
   traspaso y arqueo obtiene el catálogo con su propio nombre de formulario.
2. Cerrar y volver a abrir la pantalla.
3. Al crear el data module, Factuzam carga `SQL_REPOSITORIOS` y publica
   automáticamente cualquier consulta base que todavía falte.
4. Factuzam vuelve a cargar el catálogo compartido y las consultas recién
   publicadas quedan disponibles en esa misma apertura.

Si `oGetSQLFromDB=False`, si no existe la fila o si está desactivada, se usa
siempre el SQL base. Desactivar el interruptor de un formulario no cambia
el comportamiento de los demás formularios.

Si falla la publicación o la carga de `SQL_REPOSITORIOS`, la apertura no
queda bloqueada: se registra el error y se crea el repositorio con SQL base.

El script histórico del piloto SQL-0 solo publica las dos operaciones de
Compras:

```text
DESARROLLOS EN CURSO/perfiles_sql_compras_sesiones.sql
```

El script es idempotente y no sobrescribe filas existentes. Para el
catálogo completo debe utilizarse `PublicarCatalogo` desde la aplicación;
así se publican las 63 lecturas vigentes y se respetan las
personalizaciones existentes.

## 5. Modificar una consulta

Procedimiento recomendado:

1. Hacer copia de `VALUE_TEXT_USUPER` y de `VALUE_USUPER`.
2. Mantener `USUARIO_GRUPO_USUPER='Todos'`.
3. Editar únicamente `VALUE_TEXT_USUPER`.
4. Conservar exactamente los parámetros y aliases de salida documentados
   en la tabla siguiente.
5. Incrementar la versión de `VALUE_USUPER`.
6. Cerrar y volver a abrir la pantalla para recargar el perfil.
7. Ejecutar el flujo afectado y revisar el log.

### RepositorioComprasSesiones

| Operación | Parámetros obligatorios | Campos de salida |
|---|---|---|
| `ObtenerSiguienteLinea` | `:s`, `:n`, `:l` | `SIGUIENTE` |
| `ConsultarCantidadesLinea` | `:s`, `:n`, `:l` | `ID_AV_PIVOT_SESCEL`, `TOTAL` |

### RepositorioFacturas

| Operación | Parámetros obligatorios | Campos de salida |
|---|---|---|
| `ExisteSerieOtraEmpresa` | `:SERIE`, `:TIPODOC`, `:EMPRESA`, `:EMPRESASINASIGNAR` | `EMPRESA_CON` |
| `EsPaisUE` | `:PAIS` | `ESMIEMBRO_UE_PAI` |
| `ObtenerOperacionFiscal` | `:CODIGO` | `AMBITO_VFO`, `ESREPERCUTE_IVA_VFO` |
| `UltimaFechaSerie` | `:SERIE`, `:EMPRESA`, `:NUMERO` | `ULTIMA` |
| `HayHuecoNumeracion` | `:SERIE`, `:EMPRESA`, `:ASIGNADO` | `MAXNUM` |

`GuardarCliente` y `GuardarEmpresa` forman parte del registro para poder
revisar y exportar su SQL base, pero son escrituras `pesSoloBase`: no se
publican ni pueden sustituirse mediante perfiles.

### RepositorioConsultasCaja

| Operación | Parámetros obligatorios | Campos de salida mínimos |
|---|---|---|
| `ConsultarStock` | `:ARTICULO` | `Codigo`, `Almacen` |
| `ConsultarClientes` | ninguno | `Código`, `Razón Social`, `NIF Cliente`, `Teléfono Cliente`, `Cuenta Crédito`, `Límite Crédito`, `Deuda Usada` |
| `ConsultarEmpleados` | ninguno | `Código de Empleado`, `Nombre de Empleado` |
| `BuscarEmpleado` | `:TOKEN` | `CODIGO_EMPL`, `DIMINUTIVO_TICKET_EMPL` |
| `ObtenerCliente` | `:CODIGO` | los 22 campos de cliente declarados por el contrato |
| `ConsultarCabeceraFactura` | `:SERIE`, `:NUMERO` | `CODIGO_CLI_FAC` |
| `ConsultarLineasFactura` | `:SERIE`, `:NUMERO` | `CANTIDAD_FACLIN` |

`ConsultarStock` es un procedimiento almacenado que devuelve un dataset.
Por eso está tipado como `CALL`, pero conserva la política de lectura y el
mismo fallback que un `SELECT`.

En `BuscarEmpleado`, `:TOKEN` recibe `%texto%`. Si el texto está vacío,
recibe `%`, lo que conserva el comportamiento previo de devolver el primer
empleado activo.

### RepositorioArticulosResolver

| Operación | Parámetros obligatorios | Campos de salida mínimos |
|---|---|---|
| `DescuentoTarifaVigente` | `:tar` | `FECHA_DESDE_DTO_TAR`, `FECHA_HASTA_DTO_TAR` |
| `ContarSkusActivos` | `:art` | `CODIGO_UNIDAD_SKU` |
| `ResolverPrecio` | `:art`, `:sku`, `:tar`, `:fec` | tarifa, origen, precios, ajustes, impuestos y fechas declarados |
| `ObtenerCosteSku` | `:sku` | `PRECIO_ULT_COMPRA_SKUC`, `FECHA_ULT_COMPRA_SKUC` |
| `ObtenerCosteProveedor` | `:art`, `:prv` | proveedor, referencia, precio, fecha y principal |
| `ObtenerCostePrincipal` | `:art` | proveedor, referencia, precio, fecha y principal |
| `ResolverPmpAlmacen` | `:sku`, `:alm` | `QTY`, `VAL`, `NA` |
| `ResolverPmpTotal` | `:sku` | `QTY`, `VAL`, `NA` |
| `ObtenerDatosArticulo` | `:sku`, `:art` | datos de artículo, familia, IVA, SKU y atributos |
| `ListarSkus` | `:art`, `:incluir` | `CODIGO_UNIDAD_SKU`, `ESACTIVO_SKU`, `DESCRIPCION_SKU` |

`ListarSkus` no concatena un fragmento SQL. El parámetro `:incluir`
recibe `S` para incluir inactivos y `N` para mostrar solo activos. Esto
mantiene una única estructura validable por el catálogo.

El resolver se crea desde el formulario base y utiliza el
`oGetSQLFromDB` de la pantalla que lo consume. De esta forma una misma
operación puede utilizarse en pedidos, albaranes, facturas, compras, Caja
y documentos de trabajo, pero cada pantalla conserva su interruptor.

Los valores externos siguen asignándose con `ParamByName`. No deben
reemplazarse los parámetros por concatenaciones.

### RepositorioArticulosValidador

| Operación | Parámetros obligatorios | Campos de salida mínimos |
|---|---|---|
| `ContarCoincidencias` | `:inp`, `:solo` | `N` |
| `ObtenerDatosArticulo` | `:art` | `ESACTIVO_ART`, `ESVARIACION_ART`, `TIPO_VARIACION_ART`, `NUM_ATR_REQ` |
| `ListarSkusActivos` | `:art` | `CODIGO_UNIDAD_SKU` |
| `ValidarSkuArticulo` | `:sku`, `:art` | `ESACTIVO_SKU` |
| `ObtenerProveedorMatch` | `:art`, `:ref` | `CODIGO_PRV_AP` |
| `ResolverEntrada` | `:inp`, `:solo` | tipo de coincidencia, artículo, SKU, descripción, tipo e input |
| `TieneSkuActivo` | `:art` | `TIENE_SKU` |

En `ContarCoincidencias` y `ResolverEntrada`, `:solo` recibe `S` para
restringir la búsqueda a códigos de barras y `N` para admitir todos los
orígenes. Sustituye la antigua concatenación de un fragmento SQL.

### RepositorioArticulosAtributos

| Operación | Parámetros obligatorios | Campos de salida mínimos |
|---|---|---|
| `ValoresAtributoConjunto` | `:conj`, `:atr` | identificador, valor, descripción, orden y estado |
| `ValoresAtributoActivos` | `:atr` | identificador, valor, descripción, orden y estado |
| `ValoresPropiedad` | `:prop` | `ID_PV_ARTPROP`, `PV` |
| `ObtenerAtributos` | `:art` | atributo, nombre, orden y conjunto |
| `ObtenerPropiedades` | `:art` | propiedad, tipo, valor, obligatoriedad y orden |
| `ObtenerAtributosDeSku` | `:sku` | valor, descripción, órdenes y estado |
| `ObtenerAvsEnSkus` | `:padre`, `:orden` | identificador, valor, descripción, orden y estado |

Los formularios inyectan ambos contratos en los modos reutilizables de
SKU, desglose, tallas y pivote. Por ello esas librerías conservan el
`oGetSQLFromDB` de la pantalla que las ha creado. Los procesos sin
pantalla, como importaciones internas, usan de forma explícita el
catálogo base.

### RepositorioTraspasoTicket

| Operación | Parámetros obligatorios | Campos de salida mínimos |
|---|---|---|
| `ObtenerSolicitud` | `:NUM`, `:SER` | almacenes, empleado, estado y fecha de la solicitud |
| `ListarLineasSolicitud` | `:ORI`, `:DES`, `:NUM`, `:SER` | `SKU`, `DESCRIPCION`, `PED`, `STK_ORI`, `STK_DES` |
| `ObtenerStock` | `:ALM`, `:SKU` | `STOCK` |
| `ObtenerTraspasoHistorico` | `:EMP`, `:ALM`, `:CAJA`, `:NUMOP` | documento, almacenes, empleado y formato del documento |
| `ListarLineasTraspaso` | `:EMP`, `:ALM`, `:CAJA`, `:NUMOP` | `CODIGO_UNIDAD_MOV`, `CANTIDAD_MOV`, `DESCRIPCION` |

El ticket recibe este contrato desde la pantalla y no conoce UniDAC. La
misma corrección sirve para solicitud, reimpresión o envío por correo en
todos los formularios activados. Con `oGetSQLFromDB=False` se crea el
mismo repositorio, pero el catálogo resuelve siempre el SQL base.

### RepositorioArqueoCaja

| Operación | Parámetros obligatorios | Campos de salida mínimos |
|---|---|---|
| `CalcularContadores` | `:pTIPO_VE`, `:pEMPRESA`, `:pALMACEN`, `:pCAJA`, `:pFDESDE`, `:pFHASTA` | `VENTAS`, `OPERAC` |
| `CalcularLineas` | los mismos que `CalcularContadores` | `BRUTO`, `NETO_LIN` |
| `CalcularOperaciones` | los cinco tipos `:pTIPO_*` y el contexto de empresa, almacén, caja y rango | `NETO`, `V_NORMALES`, `V_DEVOL`, `ENTRADAS`, `SALIDAS` |
| `CalcularPrestamos` | empresa, almacén, caja y rango | `PRESTAMOS` |
| `CalcularCobrosClientes` | empresa, almacén, caja, rango, `:pTIPO_CB` y `:pTIPO_DE` | `COBROS` |
| `CalcularValesEmitidos` | empresa, almacén, caja y rango | `EMITIDOS` |
| `CalcularValesRecogidos` | empresa, almacén, caja y rango | `RECOGIDOS` |
| `CalcularPagosPorForma` | empresa, almacén, caja y rango | `CODIGO`, `DESCRIPCION`, `ESCAJON`, `IMPORTE` |
| `ObtenerEfectivoAnterior` | `:pEMPRESA`, `:pALMACEN`, `:pCAJA`, `:pFDESDE` | `EFECTIVO_DEJADO_CAJA_ARQ` |

`ComprobarEfectivoAnterior` completa las diez definiciones del repositorio,
pero consulta `INFORMATION_SCHEMA` y tiene política `pesSoloBase`. Se
incluye al revisar o exportar el catálogo para conocer el SQL técnico
utilizado, pero no se publica como personalización.

El formulario de arqueo y la reimpresión histórica reciben el repositorio
desde su pantalla. Por tanto, ambos respetan el `oGetSQLFromDB` del
formulario consumidor.

### RepositorioArqueoTicket

| Operación | Parámetros obligatorios | Campos de salida mínimos |
|---|---|---|
| `ObtenerEmpresa` | `:pEMPRESA` | razón social, NIF y dirección postal |
| `ObtenerContadores` | `:pTIPO_VE` y contexto de arqueo | `PRIMERA`, `ULTIMA`, `UDS` |
| `ListarDevolucionesPorFormaPago` | contexto y `:pTIPO_DV` | `FP`, `IMPORTE` |
| `ListarResumenSeccion` | contexto, `:pTIPO_VE`, `:pNIVELES` | `FAMILIA`, `UDS`, `NETO` |
| `ListarResumenTemporada` | contexto y `:pTIPO_VE` | `TEMPORADA`, `UDS`, `NETO` |
| `ListarResumenEmpleado` | contexto y `:pTIPO_VE` | `EMPLEADO`, `OPS`, `NETO` |
| `ListarResumenFormaPago` | contexto de arqueo | `FP`, `DESCR`, `UDS`, `IMP` |
| `ListarResumenSerie` | contexto y `:pTIPO_VE` | `SERIE`, `BASE`, `CUOTA`, `TOTAL` |
| `ObtenerRangoHistorico` | arqueo, empresa, almacén y caja | contexto y fechas del cierre |
| `ObtenerCierreHistorico` | arqueo, empresa, almacén y caja | cabecera, efectivo y vendedor |
| `ListarRecuentoHistorico` | `:pARQ` | forma de pago, sistema, recuento y diferencia |

El resumen por sección ya no genera una sentencia diferente para cada
profundidad. El SQL base contiene los nueve niveles admitidos y
`:pNIVELES` limita cuántos se muestran. Esto proporciona una única clave
estable que comparten el formulario y el ticket.

`inLibArqueoTicket` conserva únicamente el formato térmico y trabaja con
records del contrato. No conoce UniDAC ni nombres de tabla. La impresión,
la reimpresión normal y la reimpresión del cierre reciben los repositorios
creados por la pantalla.

## 6. Validación y fallback

Antes de usar una personalización, el catálogo comprueba:

- que no esté vacía;
- que sea del tipo esperado: `SELECT` o un `CALL` que devuelva dataset
  para una lectura;
- que contenga exactamente los parámetros declarados;
- que una lectura conserve todos los campos o aliases de salida obligatorios;
- que no contenga varias sentencias;
- que no incluya `DROP`, `ALTER` ni `TRUNCATE`.

Si falla esta validación:

1. Se descarta la personalización.
2. Se registra la clave y el motivo.
3. Se ejecuta el SQL base.

Si la validación es correcta pero la consulta falla al abrirse o no devuelve
los campos esperados:

1. Se registra la excepción y la clave.
2. Se repite la lectura con el SQL base.
3. Si también falla el SQL base, la excepción se propaga normalmente.

El fallback automático se aplica inicialmente a lecturas. Una futura
operación de escritura solo podrá habilitarlo si el intento personalizado
está protegido por una transacción y se hace `Rollback` antes de repetir.
Esto evita duplicar escrituras parcialmente realizadas.

## 7. Volver inmediatamente al SQL base

Hay tres opciones, de menor a mayor alcance:

1. Cambiar `VALUE_USUPER` de la operación para que empiece por `N`.
2. Eliminar únicamente la fila personalizada.
3. Establecer `oGetSQLFromDB=False` para desactivar todo el SQL de perfiles
   de esa pantalla.

No es necesario modificar ni desplegar el ejecutable.

## 8. Revisión y exportación

`TAdministradorSqlPerfiles` ofrece estas operaciones sobre el registro
central:

- `PublicarCatalogo`: crea todas las filas publicables ausentes sin
  sobrescribir cambios.
- `RevisarCatalogo`: compara base y perfil y devuelve versión, política,
  huellas, validación y última causa conocida de fallback.
- `ExportarCatalogo`: genera el SQL base, el SQL del perfil cuando exista
  y el índice `catalogo_sql.txt`.

La estructura de una exportación es:

```text
catalogo_sql.txt
RepositorioComprasSesiones/
  ObtenerSiguienteLinea.base.sql
  ObtenerSiguienteLinea.perfil.sql
  ConsultarCantidadesLinea.base.sql
  ConsultarCantidadesLinea.perfil.sql
RepositorioFacturas/
  ExisteSerieOtraEmpresa.base.sql
  ExisteSerieOtraEmpresa.perfil.sql
  ...
  GuardarCliente.base.sql
  GuardarEmpresa.base.sql
RepositorioConsultasCaja/
  ConsultarStock.base.sql
  ConsultarStock.perfil.sql
  ...
RepositorioArticulosResolver/
  ResolverPrecio.base.sql
  ResolverPrecio.perfil.sql
  ...
RepositorioArticulosValidador/
  ResolverEntrada.base.sql
  ResolverEntrada.perfil.sql
  ...
RepositorioArticulosAtributos/
  ObtenerAtributos.base.sql
  ObtenerAtributos.perfil.sql
  ...
RepositorioTraspasoTicket/
  ObtenerStock.base.sql
  ObtenerStock.perfil.sql
  ...
RepositorioArqueoCaja/
  CalcularOperaciones.base.sql
  CalcularOperaciones.perfil.sql
  ComprobarEfectivoAnterior.base.sql
  ...
RepositorioArqueoTicket/
  ListarResumenSeccion.base.sql
  ListarResumenSeccion.perfil.sql
  ObtenerCierreHistorico.base.sql
  ObtenerCierreHistorico.perfil.sql
  ...
```

El fichero `.perfil.sql` se crea aunque la entrada esté desactivada o sea
inválida, porque la finalidad de la exportación es permitir su revisión.
`catalogo_sql.txt` indica por operación:

- clave;
- estado;
- política;
- versión del contrato;
- huella del SQL base;
- huella del SQL de perfil;
- mensaje de validación;
- última causa de fallback observada durante la vida de la pantalla.

Los estados de revisión son:

```text
epsFalta
epsDesactivado
epsBase
epsPersonalizado
epsInvalido
```

`epsSoloBase` identifica operaciones que, por contrato, no admiten perfil.

La exportación debe dirigirse a una carpeta de trabajo, nunca a la carpeta
del ejecutable en producción. Sirve para revisión, control de cambios y
comparación entre instalaciones.

Para revisar el catálogo aplicado en una instalación:

```sql
SELECT SUBKEY_USUPER, VALUE_USUPER, VALUE_TEXT_USUPER,
       INSTANTE_MODIF, USUARIO_MODIF
  FROM fza_usuarios_perfiles
 WHERE USUARIO_GRUPO_USUPER = 'Todos'
   AND KEY_USUPER = 'SQL_REPOSITORIOS'
 ORDER BY SUBKEY_USUPER;
```

La consulta muestra el texto efectivo almacenado. Los `.sql` exportados
permiten compararlo con la referencia incluida en la versión del ejecutable.

## 9. Añadir una operación nueva

1. Declarar el método de negocio en `IRepositorioXxx`.
2. Implementarlo en la capa UniDAC.
3. Crear su `TDefinicionSql` indicando:
   - repositorio;
   - operación;
   - SQL base;
   - lista exacta de parámetros;
   - lista exacta de campos o aliases obligatorios si es una lectura;
   - tipo de sentencia;
   - política de ejecución;
   - versión.
4. Añadir la definición a `DefinicionesSql` en su repositorio.
5. Incorporar ese conjunto al registro compuesto por
   `CrearRegistroDefinicionesSqlAplicacion`.
6. Añadir pruebas del catálogo y del dominio con repositorio falso.
7. Compilar Win32 y Win64.
8. Publicar la nueva definición mediante `PublicarCatalogo`.

No se registra desde la sección `initialization` de ninguna unidad. El
registro se compone de forma explícita al crear la aplicación; así se
detectan claves duplicadas y las pruebas pueden construir un catálogo
aislado sin depender de estado global.

Nunca debe exponerse un método genérico como
`Ejecutar(const ASql: string)` al dominio. El contrato expresa operaciones
de negocio y el texto SQL queda en la implementación de persistencia.

## 10. Diagnóstico rápido

### La personalización no se aplica

- Comprobar `oGetSQLFromDB=True`.
- Comprobar `KEY_USUPER` y `SUBKEY_USUPER`.
- Comprobar que `VALUE_USUPER` empieza por `S`.
- Cerrar y volver a abrir la pantalla.

### Aparece “parámetros esperados/encontrados”

Comparar los nombres precedidos por `:` con la tabla del apartado 5. Los
nombres no distinguen mayúsculas, pero no pueden faltar ni sobrar.

### La consulta personalizada falla y el usuario no ve el error

Es el comportamiento previsto si el SQL base funciona: el flujo continúa
con el fallback. La incidencia queda registrada con el texto
`SQL de perfil fallido` o `SQL de perfil descartado`.

### También falla el SQL base

El problema ya no es la personalización. La excepción se propaga y debe
revisarse como un error normal de conexión, esquema o compatibilidad.
