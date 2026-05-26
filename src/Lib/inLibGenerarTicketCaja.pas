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

implementation

uses
  Data.DB, Uni, DBAccess,
  inLibGlobalVar, inLibFTicket, inMtoPreviewTicket, inLibDir;

procedure ImprimirTicketOperacionCaja(
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string;
  const ANombreImpresora: string = 'DEBUG');
var
  Qry: TUniQuery;
  Ticket: TTicketTermico;
  FormPreview: TFormVisualizador;
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
    Ticket.SaltarLineas(1);
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
    Ticket.TextoColumnas('Operación:', ANumOperacion);
    Ticket.LineaSeparadora;
    if sConcepto <> '' then
    begin
      Ticket.EscribirLinea('Concepto:');
      Ticket.EscribirLinea('  ' + sConcepto);
      Ticket.LineaSeparadora;
    end;
    { Importe }
    Ticket.SaltarLineas(1);
    Ticket.Negrita(True);
    Ticket.TamanoDoble(True, True);
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea(FormatFloat(',0.00', dImporte) + ' EUR');
    Ticket.TamanoDoble(False, False);
    Ticket.Negrita(False);
    Ticket.SaltarLineas(1);
    Ticket.LineaSeparadora;
    { Pie }
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea('Firma:');
    Ticket.SaltarLineas(3);
    Ticket.LineaSeparadora('.');
    Ticket.SaltarLineas(2);
    Ticket.CortarPapel;
    { Imprimir o previsualizar }
    ComandosESC := Ticket.ObtenerComandos;
    if UpperCase(ANombreImpresora) = 'DEBUG' then
    begin
      RutaFicheroPDF := ObtenerRutaPDF('ticket_caja_' +
        ANumOperacion + '.pdf');
      FormPreview := TFormVisualizador.Create(nil);
      try
        FormPreview.MostrarPreview(ComandosESC, RutaFicheroPDF);
      finally
        FreeAndNil(FormPreview);
      end;
    end
    else
      Ticket.Imprimir;
  finally
    FreeAndNil(Ticket);
  end;
end;

end.
