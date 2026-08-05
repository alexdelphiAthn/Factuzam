# Facturación periódica de operaciones de caja

La opción `TPV → Facturas proforma` permite seleccionar un periodo, una
empresa destino y una modalidad de generación.

Antes de generar se consulta el registro de periodos de la misma modalidad
y empresa destino. La pantalla avisa si el intervalo coincide con uno ya
procesado o se solapa con él y exige confirmación expresa. Cada intento queda
registrado, incluso cuando no encuentra documentos o termina con error, y los
enlaces de operación impiden facturar dos veces un mismo VE o TA.

## Ventas VE

- Genera una proforma interna a nombre de `VENTA CONTADO`.
- El IVA mostrado es únicamente informativo: la proforma no se guarda en
  `fza_facturas`, no entra en los libros fiscales y no declara VeriFactu.
- Cada operación conserva su identificador, fecha y líneas de artículos.
- Se excluyen los tickets sustituidos por una factura normal, rectificados,
  cancelados o ya incorporados a otra proforma.
- Si un ticket se rectifica o sustituye después de haber sido incluido, la
  siguiente ejecución genera líneas negativas `AJUSTE` vinculadas a las
  líneas originales. La proforma emitida no se convierte en una factura
  rectificativa fiscal.

## Traspasos TA

- El TA mantiene su naturaleza de saldo interno pendiente: por sí solo no
  declara IVA ni VeriFactu.
- La generación crea una factura de venta `NORMAL` por cada empresa origen,
  dirigida a la empresa destino.
- La cabecera usa los datos fiscales de ambas empresas de `fza_empresas`.
- Las líneas valoran el coste del movimiento y aplican el IVA vigente de la
  empresa emisora.
- Antes de confirmar se validan los requisitos fiscales. Tras guardar la
  factura se solicita su emisión mediante el servicio fiscal común, que la
  registra en VeriFactu, No VeriFactu o Sin VeriFactu según la configuración.
- El enlace de cada operación pasa a `EMITIDA` al delegarse correctamente o
  a `ERROR_FISCAL` si falla la emisión; el estado del periodo permanece
  separado del estado fiscal de la factura.
- Cada TA queda enlazado una sola vez con su factura. Una rectificación
  posterior se tramita mediante el circuito fiscal normal de rectificativas.

## Trazabilidad e informes

Las proformas VE y las facturas TA muestran una banda antes de cada grupo de
artículos con el documento, la fecha y el identificador de la operación de
caja. Los estados de periodo, proforma y factura se mantienen separados.

El script `facturas_proforma_caja.sql` es idempotente y debe aplicarse a cada
base de datos existente antes de utilizar la pantalla.
