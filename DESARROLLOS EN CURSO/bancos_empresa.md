# Bancos por empresa y asignación de cuenta en efectos / recibos

Permite que **cada empresa tenga N cuentas bancarias** y que, al generar el
**efecto de pago** (compras) o el **recibo de cobro** (ventas), se **asigne la
cuenta de la empresa** correspondiente (de dónde se paga / dónde se ingresa).

```
empresa ──┬─ N cuentas bancarias (fza_empresas_bancos)
          │      IBAN + nombre + entidad (catálogo fza_bancos)
          │      marca por defecto de COBRO y/o de PAGO
          │
  compras │  factura compra ─► efecto de pago ─► CODIGO_EMPBAN_EFEC (cargo)
  ventas  └  factura venta  ─► recibo de cobro ─► CODIGO_EMPBAN_REC  (ingreso)
```

El IBAN que ya guardaban esos documentos es el de la **contraparte**
(`IBAN_EFEC` = proveedor, `IBAN_CLI_REC` = cliente). Lo que faltaba —y añade
este desarrollo— es la cuenta **de la propia empresa**.

---

## Esquema (scripts idempotentes, no tocan `factuzam_original.sql`)

Orden de ejecución:

1. **`bancos_catalogo.sql`** — `fza_bancos` (sufijo `BAN`): catálogo maestro de
   entidades españolas (código NRBE de 4 dígitos + nombre + BIC). Sembrado con
   ~230 entidades del registro público, deduplicado por código. La semilla usa
   `ON DUPLICATE KEY UPDATE`, así que recargar el script refresca nombres/BIC
   del catálogo base sin duplicar.

2. **`bancos_empresa.sql`** — el resto:
   - `fza_empresas_bancos` (sufijo `EMPBAN`): una fila por cuenta de empresa.
     PK `CODIGO_EMPBAN` (contador `'EB'`). Columnas clave: `CODIGO_EMP_EMPBAN`,
     `NOMBRE_EMPBAN`, `IBAN_EMPBAN`, `CODIGO_BAN_EMPBAN` (FK catálogo),
     descomposición CCC (`ENTIDAD_/OFICINA_/DIGITO_CONTROL_/CUENTA_EMPBAN`),
     `BIC_EMPBAN`, y los dos flags de defecto:
     `ESDEFECTO_COBRO_EMPBAN` / `ESDEFECTO_PAGO_EMPBAN`.
   - `ALTER` idempotente en `fza_efectos_compra`: `CODIGO_EMPBAN_EFEC` +
     `IBAN_EMP_EFEC` (cuenta de cargo de la empresa).
   - `ALTER` idempotente en `fza_recibos`: `CODIGO_EMPBAN_REC` +
     `IBAN_EMP_REC` (cuenta de ingreso de la empresa).
   - Vista `vi_empresas_bancos` (cuentas + nombre del banco resuelto).
   - Contador `'EB'` + tipo de documento `'EB'` (BANCOS POR EMPRESA).

Sufijos `BAN` y `EMPBAN` registrados en `LIBRO_DE_ESTILO_BBDD.md §2` y en
`UNormalizerEngine.pas / InitDefaults` (`AddSuf` + `AddOwn`).

---

## Capa Delphi

### Mantenimiento de empresas — pestaña «Bancos»
- `UniDataEmpresas` (`unqryBancos` / `dsBancos`): detail con
  `MasterSource = dsTablaG`, carga perezosa `AsegurarBancosAbierta`, alta
  automática de código (`GetCodigoAutoBanco` → contador `'EB'`) y borrado en
  cascada al eliminar la empresa. En `BeforePost` valida el IBAN con
  `inLibIBAN` y rellena entidad/oficina/DC/cuenta + `CODIGO_BAN_EMPBAN`.
- `inMtoEmpresas`: pestaña `tsBancos` con rejilla (`tvBancos`) y botón
  «Añadir banco», espejo de la pestaña Series.

### Selección de cuenta al generar (elección manual)
- `inMtoModalSeleccionarBanco` (`src/Modals/`): modal
  `class function Ejecutar(AOwner, AConn, ACodigoEmpresa, AUso)` que lista las
  cuentas de la empresa (`vi_empresas_bancos`, activas) y preselecciona la
  marcada por defecto según el uso (`bucPago` / `bucCobro`). Devuelve el
  `CODIGO_EMPBAN` + IBAN elegidos.
- **Compras**: `inMtoFacturasCompra.btnGenerarEfectosClick` abre el modal
  (uso pago) antes de generar; tras generar, `UniDataFacturasCompra` estampa
  `CODIGO_EMPBAN_EFEC` / `IBAN_EMP_EFEC` en los efectos de la factura.
- **Ventas**: `inMtoFacturasBase.btnGenerarRecibosClick` abre el modal (uso
  cobro) antes de generar recibos; tras generar, se estampa
  `CODIGO_EMPBAN_REC` / `IBAN_EMP_REC` en los recibos de la factura.

El estampado se hace con un `UPDATE` posterior (Delphi) por `(SERIE, NUMERO)`,
de modo que **no se tocan** los SP `PRC_EFEC_GENERAR_DESDE_FACTURA` ni
`PRC_CREAR_RECIBOS_FACTURA` (este último vive solo en `factuzam_original.sql`).

---

## Pendiente / notas

- **Compilar en el IDE Delphi**: los cambios `.pas`/`.dfm` no se han compilado
  en esta entrega (entorno sin compilador). Revisar el alta de campos en la
  declaración de clase (E2169) y la carga de los `.dfm` antes de publicar.
- **Mto de catálogo `fza_bancos`** (`inMtoBancos`): no incluido; el catálogo se
  usa sembrado y vía `vi_empresas_bancos`. Es un añadido sencillo si se quiere
  editar el catálogo desde la app (registrar `fza_winforms`).
- **Fichero SEPA**: la cuenta de cargo de la remesa (`IBAN_REMC`) puede pasar a
  derivarse del `CODIGO_EMPBAN` del primer efecto en lugar de teclearse.
- Validar las SP de efectos contra BBDD viva (ya advertido en
  `efectos_remesas_compra.md`).
