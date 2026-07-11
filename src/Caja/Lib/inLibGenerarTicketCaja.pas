{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenerarTicketCaja                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generación e impresión de tickets para operaciones de caja no             }
{    fiscales: Entrada de Cambio (EC) y Gastos por Caja / Retiradas (GC).      }
{    Usa TTicketTermico (ESC/POS) igual que los tickets de venta.              }
{******************************************************************************}
unit inLibGenerarTicketCaja;

interface

uses
  System.SysUtils, System.Classes;

procedure ImprimirTicketOperacionCaja(
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string;
  const ANombreImpresora: string = 'DEBUG');

// Apertura manual del cajon portamonedas sin venta asociada (tecla F9
// global en cualquier ventana del programa). Comprueba el permiso
// 'caja.abrirCajon' y manda el pulso de apertura por la impresora de
// tickets de parametros (vgerDefPrinter -> oNomImpresoraCaja).
procedure AbrirCajonSinVenta;

// True si hay impresora de tickets real asignada en parametros
// (oNomImpresoraCaja con valor no vacio y distinto de 'DEBUG').
function ImpresoraCajaAsignada: Boolean;

implementation

uses
  Data.DB, Uni, DBAccess, Vcl.Dialogs,
  inLibGlobalVar, inLibFTicket, inMtoPreviewTicket, inLibDir, inLibPermisos,
  inLibGenerarTicket;

procedure ImprimirTicketOperacionCaja(
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string;
  const ANombreImpresora: string = 'DEBUG');
var
  Qry: TUniQuery;
  Ticket: TTicketTermico;
  ComandosESC, RutaFicheroPDF: string;
  sTipo, sConcepto, sEmpleado, sFecha: string;
  dImporte: Currency;
  sTitulo: string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := oConn;
    Qry.SQL.Text :=
      'SELECT o.TIPO_OPERACION_OPCAJA,' +
      '       o.FECHA_OPERACION_OPCAJA,' +
      '       o.CODIGO_EMPLEADO_OPCAJA,' +
      '       o.CONCEPTO_GASTO_INGRESO_OPCAJA,' +
      '       o.IMPORTE_TOTAL_OPCAJA,' +
      '       e.RAZON_SOCIAL_EMP' +
      '  FROM fza_caja_operaciones o' +
      '  LEFT JOIN fza_empresas e' +
      '    ON e.CODIGO_EMP_EMP = o.CODIGO_EMP_OPCAJA' +
      ' WHERE o.CODIGO_EMP_OPCAJA       = :EMP' +
      '   AND o.CODIGO_ALM_OPCAJA       = :ALM' +
      '   AND o.CODIGO_CAJA_OPCAJA      = :CAJA' +
      '   AND o.NUMERO_OPERACION_OPCAJA = :OP' +
      ' LIMIT 1';
    Qry.ParamByName('EMP').AsString  := AEmpresa;
    Qry.ParamByName('ALM').AsString  := AAlmacen;
    Qry.ParamByName('CAJA').AsString := ACaja;
    Qry.ParamByName('OP').AsString   := ANumOperacion;
    Qry.Open;
    if Qry.IsEmpty then
      Exit;
    sTipo     := Qry.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
    sFecha    := FormatDateTime('dd/mm/yyyy hh:nn',
                   Qry.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime);
    sEmpleado := Qry.FieldByName('CODIGO_EMPLEADO_OPCAJA').AsString;
    sConcepto := Qry.FieldByName('CONCEPTO_GASTO_INGRESO_OPCAJA').AsString;
    dImporte  := Qry.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
    if sTipo = 'EC' then
      sTitulo := 'ENTRADA DE CAMBIO'
    else
      sTitulo := 'GASTO / RETIRADA DE CAJA';
  finally
    FreeAndNil(Qry);
  end;
  Ticket := TTicketTermico.Create(ANombreImpresora);
  try
    Ticket.Inicializar;
    { Título }
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    Ticket.EscribirLinea(sTitulo);
    Ticket.Negrita(False);
    Ticket.LineaSeparadora;
    { Datos }
    Ticket.Alinear(alIzquierda);
    Ticket.TextoColumnas('Fecha:', sFecha);
    Ticket.TextoColumnas('Caja:', ACaja);
    Ticket.TextoColumnas('Empleado:', sEmpleado);
    Ticket.TextoColumnas('Op.:', ANumOperacion);
    if sConcepto <> '' then
      Ticket.TextoColumnas('Concepto:', sConcepto);
    Ticket.LineaSeparadora;
    { Importe }
    Ticket.Negrita(True);
    Ticket.TextoColumnas('IMPORTE:',
      FormatFloat(',0.00', dImporte) + ' EUR');
    Ticket.Negrita(False);
    Ticket.LineaSeparadora;
    { Pie }
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea('Firma:');
    Ticket.SaltarLineas(2);
    Ticket.LineaSeparadora('.');
    EscribirPieTicketCaja(Ticket, AEmpresa);
    Ticket.SaltarLineas(1);
    Ticket.CortarPapel;
    { Imprimir o previsualizar }
    ComandosESC := Ticket.ObtenerComandos;
    RutaFicheroPDF := GetUserFolderTickets + 'ticket_caja_' +
      ANumOperacion + '.pdf';
    ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaFicheroPDF,
                                 ANombreImpresora);
  finally
    FreeAndNil(Ticket);
  end;
end;

function ImpresoraCajaAsignada: Boolean;
var
  sImpresora: string;
begin
  sImpresora := Trim(oNomImpresoraCaja);
  Result := (sImpresora <> '') and (UpperCase(sImpresora) <> 'DEBUG');
end;

procedure AbrirCajonSinVenta;
var
  Ticket: TTicketTermico;
begin
  // Lanzada por F9 global. Si no hay permiso o impresora valida, avisa y no
  // hace nada; en otro caso manda solo el pulso de apertura del cajon.
  if Assigned(oPermisos) and (not oPermisos.TienePermiso('caja.abrirCajon')) then
    ShowMessage('No tiene permiso para abrir el cajón.')
  else if not ImpresoraCajaAsignada then
    ShowMessage('No hay impresora de tickets configurada en parámetros ' +
                '(vgerDefPrinter); no se puede abrir el cajón.')
  else
  begin
    Ticket := TTicketTermico.Create(oNomImpresoraCaja);
    try
      Ticket.AbrirCajon;
      Ticket.Imprimir;
    finally
      FreeAndNil(Ticket);
    end;
  end;
end;

end.
