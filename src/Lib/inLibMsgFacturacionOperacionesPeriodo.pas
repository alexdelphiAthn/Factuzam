{******************************************************************************}
{  Módulo: inLibMsgFacturacionOperacionesPeriodo                              }
{  Tipo: Recursos de texto                                                    }
{******************************************************************************}
unit inLibMsgFacturacionOperacionesPeriodo;

interface

resourcestring
  SErrorEmpresaFacturacionPeriodoObligatoria =
    'Debe indicar la empresa del TPV.';
  SErrorAlmacenFacturacionPeriodoObligatorio =
    'Debe indicar el almacén del TPV.';
  SErrorCajaFacturacionPeriodoObligatoria =
    'Debe indicar la caja del TPV.';
  SErrorFechaDesdeFacturacionPeriodoObligatoria =
    'Debe indicar la fecha inicial del periodo.';
  SErrorRangoFacturacionPeriodoNoValido =
    'La fecha final no puede ser anterior a la fecha inicial.';
  SErrorFechaDocumentoFacturacionPeriodoObligatoria =
    'Debe indicar la fecha de los documentos.';
  SErrorTipoFacturacionPeriodoObligatorio =
    'Debe seleccionar ventas a contado, traspasos entre empresas o ambos.';
  SErrorSerieFiscalFacturacionPeriodoObligatoria =
    'Debe indicar una serie fiscal para las facturas TA.';
  SErrorSerieFiscalFacturacionPeriodoNoValida =
    'La serie fiscal no pertenece a la empresa, no es de facturas normales ' +
    'o no está vigente en la fecha del documento.';
  SErrorEmpresaDestinoFacturacionPeriodoInvalida =
    'La empresa destino del traspaso no tiene datos fiscales completos.';
  SErrorSinLineasFacturacionPeriodo =
    'La operación no contiene líneas facturables.';
  SInfoSinOperacionesFacturacionPeriodo =
    'No hay operaciones nuevas ni ajustes pendientes en el periodo.';
  SInfoResultadoFacturacionPeriodo =
    'Proceso completado: %d proformas internas, %d facturas fiscales, ' +
    '%d ajustes y %d operaciones.';
  SPreguntaProcesarFacturacionPeriodo =
    'Se procesarán %d operaciones pendientes. ¿Desea continuar?';
  STituloFacturacionOperacionesPeriodo =
    'Facturación de operaciones por periodo';
  STituloInformeFacturacionOperacionesPeriodo =
    'Informe de facturación de operaciones por periodo';
  SEstadoFiscalNoAplicaFacturacionPeriodo = 'NO APLICA';
  SEstadoFiscalPendienteFacturacionPeriodo = 'PENDIENTE';

implementation

end.
