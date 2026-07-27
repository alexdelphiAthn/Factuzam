# Fase 3 — Bloque B1: el `uses` invertido (resultados)

Fecha: 27/07/2026. Ficheros tocados: **32**. Líneas: +308 / −172 (netas).
**Pendiente de compilar en tu máquina** — ver el plan de pruebas abajo.

## Qué se ha hecho

### 1. Siete `uses` muertos borrados (no ocho)

`UniDataAtributosBasicos`, `UniDataGrupos`, `UniDataProveedores`,
`UniDataTarifas`, `UniDataUsuariosPerfiles`, `inLibGenerarTicket` e
`inLibGenerarTicketBD` referenciaban unidades `inMto*` sin usar nada de
ellas. Verificado con búsqueda **insensible a mayúsculas** de todos los
identificadores exportados — y menos mal: el octavo candidato,
`inLibArticulosPropiedades → inMtoModalAceptCancel`, resultó estar VIVO
(declara `TfrmSelPropiedades = class(TFrmModalAceptCancel)`; mi scan
anterior lo marcó muerto por una diferencia de mayúsculas). Ese queda
para el bloque B4, porque lo suyo es mover esos forms a `Modals/`.

### 2. `AsignarMaestroCabecera` sube a `TdmBase` (el patrón de 18 DMs)

- `TdmBase` (UniDataGen) gana `AsignarMaestroCabecera(ADataSource)`
  **virtual** que guarda `FMaestroCabecera` (protected), y el evento
  `OnActivarFicha` que sustituye al único toque de UI que tenía:
  `unqryTablaGBeforeInsert` ya no busca el form con
  `GetOwnerForm<TfrmMtoGen>` para activar la pestaña Ficha — avisa, y
  `TfrmMtoGen.ActivarFichaDesdeDM` hace el cambio de pestaña.
  `UniDataGen` ya no usa `inMtoGen`.
- `TfrmMtoGen.CrearTablaPrincipal` empuja el maestro nada más crear el
  DM: `AsignarMaestroCabecera(dsTablaG)` + suscripción al evento. Es la
  misma pauta que estrenó `TdmFacturas` en la Fase 3, ahora para todos.
- `TdmFacturas.AsignarMaestroCabecera` pasa a `override` (sin cambio de
  comportamiento; la llamada explícita de `inMtoFacturasBase` se queda y
  es idempotente).
- **17 data modules** migrados al override y sin su `uses inMto*`:
  Albaranes/Devoluciones/Facturas/Pedidos de compra, Remesas compra y
  venta, Clientes, Empresas, Familias, Almacenes, Usuarios, Variaciones,
  AtributosConjuntos, FormasdePago, DocumentosTrabajo, Artículos y
  GeneradorProcesos.

### 3. Los tres casos que no eran solo `dsTablaG`

- **`TdmArticulos`**: además de los 6 MasterSource, buscaba en el form la
  vista de stock (`tvStock`) para reconstruir columnas. Ahora el form la
  empuja con `AsignarVistaStock(tvStock)` y el `AfterScroll` sale limpio
  si no hay vista (el `TdmArticulos` temporal del botón "Pegatinas" de
  Albaranes de Compra, que antes dependía de un guard con GetOwnerForm).
- **`TdmGeneradorProcesos`**: tocaba el form dos veces (foco al editor
  SQL tras insertar; refresco del editor al navegar). Dos eventos nuevos,
  `OnNuevoProceso` y `OnProcesoCambiado`, y los handlers viven en el form.
- **`TdmDocumentosTrabajo`**: cableaba en tres sitios (ConfigurarQueries,
  ConfigurarQueryCompartidos y un cinturón en AbrirDetalles). Los tres
  usan ahora `FMaestroCabecera`; cero GetOwnerForm.

### 4. Caso especial: los tipos SEPA (la infracción nº 34)

`UniDataRemesasVenta` usaba en su **interface** el modal
`inMtoModalSepaRemesaVenta` — solo para el record `TDatosSepaRemesaVenta`
y sus auxiliares. Los tres tipos se han movido a `inLibSepaRemesasVenta`
(la librería que genera el XML), y modal, DM y form los toman de ahí.
Este caso no estaba en mi recuento original de 33: apareció al descubrir
que mi copia local no tenía 25 modales (el análisis descartaba `uses`
hacia unidades que no conocía). El total real era **34**.

### 5. Familias: los `.Open` salen de `DataModuleCreate`

`TdmFamilias` era el único DM que abría sus detalles DENTRO de
`DataModuleCreate`, justo después de cablear el maestro. Con el maestro
llegando ahora un instante después, esos `.Open` se han movido a un
`AbrirDetalles` override — exactamente la migración que ya tenían hechos
Clientes, Artículos, Empresas y compañía ("Los .Open se han movido a
AbrirDetalles").

## Resultado medido (después vs antes)

| Métrica | Antes | Ahora |
|---|---|---|
| Infracciones `inLib*`/`UniData*` → `inMto*` | 34 | **8** |
| Ciclos de dependencias (SCC > 1) | 21 | **5** |
| Ciclo mayor | 18 unidades | 12 (el del núcleo, objetivo de B2) |
| `GetOwnerForm<TfrmX>` en data modules | 40+ | **0** |

Las 8 infracciones restantes son las previstas para B2/B4:
`inLibShowMto` (×2), `inLibFormManager`, `inLibGenBusq`,
`inLibDefaultValues`, `inLibColumnasSkuModoTallas`, `inLibLayoutForm` e
`inLibArticulosPropiedades`.

Los 5 ciclos restantes: el núcleo (12: ShowMto/FormManager/inMtoGen…, es
B2), uno de 10 **entre formularios** (Mto↔Modal de etiquetas, es B4), el
de librerías (8: inLibtb/GlobalVar/Log…, es la Fase 4), ComprasSesiones
(3) y ModalGenImp (2).

## Verificación en frío ya hecha

- Diff completo de los 32 ficheros contra los originales **verificados
  por md5 contra tu disco**: solo cambios previstos. (La caché del puente
  volvió a servir copias rancias de 10 ficheros; los originales de esos
  se extrajeron con gzip+base64 por el shell del dispositivo y se
  comprobaron por hash antes de dar el diff por bueno.)
- BOM y balance begin/end idénticos al original en los 32.
- 0 líneas nuevas por encima de 80 columnas; CRLF en lo añadido.
- 18 DMs con exactamente una declaración y una implementación del
  override; `inLibSepaRemesasVenta` ya estaba en el `.dpr`; ningún
  `GetOwnerForm<Tfrm...>` queda en DataModules.

## Plan de pruebas (tras compilar)

1. **Compilar** `compilar_release_win64.cmd` — 0 errores esperados.
2. **Maestro-detalle en las 17 pantallas migradas** (la comprobación W1
   de siempre: navegar la cabecera y ver que el detalle la sigue):
   Clientes, Empresas, Familias, Almacenes, Usuarios, Variaciones,
   Atributos Conjuntos, Formas de Pago, Documentos de Trabajo, Artículos
   (SKUs, tarifas, proveedores, líneas factura, movimientos, stock),
   Albaranes/Devoluciones/Facturas/Pedidos de compra, Remesas de compra
   y de venta, Generador de Procesos.
3. **Insertar registro** en 2-3 Mtos → debe saltar a la pestaña Ficha
   (ahora vía evento).
4. **Generador de procesos**: nuevo registro → foco al editor SQL y
   pestaña SQL activa; navegar registros → el editor se refresca.
5. **Artículos**: la pestaña Stock pinta el pivote de tallas; y el botón
   "Pegatinas" de Albaranes de Compra sigue funcionando (usa el
   TdmArticulos temporal sin form).
6. **Familias**: las cuatro pestañas de detalle cargan datos (los Open
   movidos).
7. **Remesas de venta**: generar la orden SEPA de una remesa (tipos
   movidos de sitio; el flujo no cambió).
8. **Facturas**: humo rápido (nuevo borrador, líneas siguen a cabecera) —
   el cableado ahora ocurre dos veces y debe ser inocuo.

## Limpieza

`_to_delete/b1orig/` contiene temporales (copias gzip de originales que
usé para verificar el diff cuando la caché del puente servía versiones
viejas). Se puede borrar con el resto de `_to_delete`.
