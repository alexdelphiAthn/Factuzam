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
  System.SysUtils, System.Classes, Uni,
  inLibPermisosIntf, inLibParametrosIntf, inLibPreviewTicket,
  inLibGenerarTicketIntf;

type
  TEstadoAperturaCajon = (
    eacAbierto,
    eacSinPermiso,
    eacSinImpresora
  );
  TResultadoAperturaCajon = record
    Estado: TEstadoAperturaCajon;
    Mensaje: string;
    function Correcto: Boolean;
  end;

procedure ImprimirTicketOperacionCaja(
  const APreview: IPreviewTicket;
  AConexion: TUniConnection;
  const ALecturasTicket: ILecturasImpresionTicket;
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string;
  const ANombreImpresora: string = 'DEBUG';
  ARutasPDF: TStrings = nil;
  ASoloPDF: Boolean = False);

// Apertura manual del cajon portamonedas sin venta asociada (tecla F9
// global en cualquier ventana del programa). Comprueba el permiso
// 'caja.abrirCajon' y manda el pulso de apertura por la impresora de
// tickets resuelta por los parámetros de caja.
function AbrirCajonSinVenta(
  const APermisos: IPermisosAplicacion;
  const AParametrosCaja: IParametrosCaja): TResultadoAperturaCajon;

// True si hay impresora de tickets real asignada en parametros
// (valor no vacío y distinto de 'DEBUG').
function ImpresoraCajaAsignada(
  const AParametrosCaja: IParametrosCaja): Boolean;

implementation

uses
  Data.DB, DBAccess,
  inLibFTicket, inLibDir,
  inLibGenerarTicket, inLibMsgCaja, inLibMsgConfiguracion,
  inLibMsgTickets;

function TResultadoAperturaCajon.Correcto: Boolean;
begin
  Result := Estado = eacAbierto;
end;

procedure ImprimirTicketOperacionCaja(
  const APreview: IPreviewTicket;
  AConexion: TUniConnection;
  const ALecturasTicket: ILecturasImpresionTicket;
  const AEmpresa, AAlmacen, ACaja, ANumOperacion: string;
  const ANombreImpresora: string;
  ARutasPDF: TStrings;
  ASoloPDF: Boolean);
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
    Qry.Connection := AConexion;
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
      sTitulo := STicketEntradaCambio
    else
      sTitulo := STicketGastoRetiradaCaja;
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
    Ticket.TextoColumnas(STicketFecha, sFecha);
    Ticket.TextoColumnas(STicketCaja, ACaja);
    Ticket.TextoColumnas(STicketEmpleado, sEmpleado);
    Ticket.TextoColumnas(
      STicketOperacionAbreviada,
      ANumOperacion);
    if sConcepto <> '' then
      Ticket.TextoColumnas(STicketConcepto, sConcepto);
    Ticket.LineaSeparadora;
    { Importe }
    Ticket.Negrita(True);
    Ticket.TextoColumnas(STicketImporte,
      FormatFloat(',0.00', dImporte) + ' EUR');
    Ticket.Negrita(False);
    Ticket.LineaSeparadora;
    { Pie }
    Ticket.Alinear(alCentro);
    Ticket.EscribirLinea(STicketFirma);
    Ticket.SaltarLineas(2);
    Ticket.LineaSeparadora('.');
    EscribirPieTicketCaja(ALecturasTicket, Ticket, AEmpresa);
    Ticket.SaltarLineas(1);
    Ticket.CortarPapel;
    { Imprimir o previsualizar }
    ComandosESC := Ticket.ObtenerComandos;
    RutaFicheroPDF := GetUserFolderTickets + 'ticket_caja_' +
      ANumOperacion + '.pdf';
    ImprimirOPrevisualizarTicket(
      APreview, Ticket, ComandosESC, RutaFicheroPDF,
                                 ANombreImpresora, ASoloPDF);
    if Assigned(ARutasPDF) and FileExists(RutaFicheroPDF) then
      ARutasPDF.Add(RutaFicheroPDF);
  finally
    FreeAndNil(Ticket);
  end;
end;

function ImpresoraCajaAsignada(
  const AParametrosCaja: IParametrosCaja): Boolean;
var
  sImpresora: string;
begin
  Result := Assigned(AParametrosCaja);
  if Result then
  begin
    sImpresora := Trim(AParametrosCaja.ImpresoraCaja);
    Result := (sImpresora <> '') and
              (UpperCase(sImpresora) <> 'DEBUG');
  end;
end;

function AbrirCajonSinVenta(
  const APermisos: IPermisosAplicacion;
  const AParametrosCaja: IParametrosCaja): TResultadoAperturaCajon;
var
  Ticket: TTicketTermico;
begin
  Result.Estado := eacSinPermiso;
  Result.Mensaje := SErrorPermisoAbrirCajon;
  if (not Assigned(APermisos)) or
     (not APermisos.TienePermiso(
       PERMISO_CAJA_ABRIR_CAJON,
       paPermitir)) then
  begin
    Result.Estado := eacSinPermiso;
    Result.Mensaje := SErrorPermisoAbrirCajon;
  end
  else if not ImpresoraCajaAsignada(AParametrosCaja) then
  begin
    Result.Estado := eacSinImpresora;
    Result.Mensaje := SErrorImpresoraTicketsCajaNoConfigurada;
  end
  else
  begin
    Ticket := TTicketTermico.Create(
      AParametrosCaja.ImpresoraCaja);
    try
      Ticket.AbrirCajon;
      Ticket.Imprimir;
    finally
      FreeAndNil(Ticket);
    end;
    Result.Estado := eacAbierto;
    Result.Mensaje := '';
  end;
end;

end.
