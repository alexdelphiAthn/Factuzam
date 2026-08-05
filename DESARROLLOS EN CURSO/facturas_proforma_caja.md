# Facturación periódica de operaciones de caja

La opción `TPV → Facturas proforma` permite seleccionar un periodo, la
**empresa emisora** y una modalidad de generación. La empresa emisora se
propone desde la empresa de la sesión, pero se selecciona expresamente para
que una estructura con varias sociedades no dependa de un origen implícito.
La **empresa destino** solo se solicita en la modalidad de traspasos TA.

Antes de generar se consulta el registro de periodos de la misma modalidad y
del mismo par empresa origen/destino. En VE, donde no hay empresa destino, el
ámbito es la empresa emisora. La pantalla avisa si el intervalo coincide con
uno ya procesado o se solapa con él y exige confirmación expresa. Cada intento
queda registrado, incluso cuando no encuentra documentos o termina con error,
y los enlaces de operación impiden facturar dos veces un mismo VE o TA.

## Ventas VE

- Genera una proforma interna a nombre de `VENTA CONTADO`.
- La empresa emisora seleccionada determina tanto los tickets incluidos como
  los datos fiscales, la serie y el contador de la proforma. No se mezclan en
  una misma proforma ventas pertenecientes a otra empresa.
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
- La generación toma únicamente los TA entre la empresa origen y la empresa
  destino seleccionadas. Crea una factura de venta `NORMAL` en fase
  `BORRADOR`, emitida por el origen, dirigida al destino y visible en Venta
  mayor. Si existen varios almacenes de origen, puede separar los documentos
  para respetar sus series.
- La cabecera usa los datos fiscales de ambas empresas de `fza_empresas`.
- Las líneas valoran el coste del movimiento y aplican el IVA vigente de la
  empresa emisora.
- Antes de guardar se validan los requisitos fiscales, pero el borrador no se
  emite automáticamente. Al consolidarlo manualmente desde Venta mayor sigue
  el circuito fiscal normal, con IVA y VeriFactu según la configuración.
- El enlace de cada operación queda reservado al borrador para impedir otra
  factura del mismo TA. El estado del periodo permanece separado de la fase
  fiscal de la factura.
- Cada TA queda enlazado una sola vez con su factura. Una rectificación
  posterior se tramita mediante el circuito fiscal normal de rectificativas.

## Trazabilidad e informes

Las proformas VE y las facturas TA muestran una banda antes de cada grupo de
artículos con el documento, la fecha y el identificador de la operación de
caja. Los estados de periodo, proforma y factura se mantienen separados.

Los datos fiscales de la empresa emisora quedan copiados en la cabecera del
documento. Por ello, en una instalación multiempresa, cada PDF VE muestra la
empresa origen seleccionada y los PDF de TA conservan el emisor y destinatario
de su factura, sin depender de la empresa activa cuando se imprimen después.

## Compatibilidad con periodos existentes

El campo nullable `CODIGO_EMP_ORIGEN_FACPER` identifica el emisor del periodo.
Al actualizar una base existente:

- En los periodos VE, el antiguo campo «empresa destino» se utilizaba en
  realidad como empresa de los tickets y emisora; ese valor se copia al nuevo
  campo de origen.
- En los periodos TA con un único origen enlazado, este se recupera desde
  `fza_facturas_operaciones_caja`.
- Un periodo TA histórico que agrupó varios orígenes conserva el origen a
  `NULL`; los orígenes exactos siguen disponibles en sus enlaces de operación.
  También permanece a `NULL` cuando un periodo sin documentos o con error no
  ofrece trazabilidad suficiente. En ambos casos significa «varios/todos los
  orígenes del proceso legado», no una empresa desconocida elegida hoy.

El índice de revisión de periodos incluye modalidad, origen, destino y fechas.
El script comprueba y reconstruye el índice cuando una instalación conserva
su definición anterior.

El script `facturas_proforma_caja.sql` es idempotente y debe aplicarse a cada
base de datos existente antes de utilizar la pantalla.
