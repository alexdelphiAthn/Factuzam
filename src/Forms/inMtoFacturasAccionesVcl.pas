{******************************************************************************}
{                                                                              }
{  Acciones modales de impresion, rectificacion y sustitucion de facturas.     }
{                                                                              }
{******************************************************************************}
unit inMtoFacturasAccionesVcl;

interface

uses
  System.Classes, Data.DB,
  inLibParametrosIntf, inLibLogIntf, UniDataFacturas;

type
  TGuardarPendienteFacturaVcl = reference to procedure;

procedure ArchivarFacturaConsolidadaVcl(
  AFacturas: TdmFacturas;
  const ASerie, ANumero: string;
  const ARegistroLog: IRegistroLog);
procedure ImprimirFacturaVcl(
  AFacturas: TdmFacturas;
  ACabecera: TDataSet;
  const AParametros: IParametrosAplicacion;
  APuedeImprimir: Boolean;
  const AGuardarPendiente: TGuardarPendienteFacturaVcl);
procedure RectificarFacturaVcl(
  AOwner: TComponent;
  AFacturas: TdmFacturas);
procedure FacturarTicketVcl(
  AOwner: TComponent;
  ACabecera: TDataSet;
  const AParametros: IParametrosAplicacion);

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Forms, Vcl.Dialogs,
  inLibFacturas, inLibVerifactu, inLibVerifactuTipos,
  inLibMsgFacturas,
  inMtoModalFacRec, inMtoModalImpFac, inMtoModalFacturarTicket;

procedure ArchivarFacturaConsolidadaVcl(
  AFacturas: TdmFacturas;
  const ASerie, ANumero: string;
  const ARegistroLog: IRegistroLog);
begin
  try
    TfrmPrintFac.ArchivarFacturaConsolidada(AFacturas, ASerie, ANumero);
  except
    on E: Exception do
      if Assigned(ARegistroLog) then
        ARegistroLog.RegistrarError(
          'No se pudo archivar el PDF al consolidar ' +
          ASerie + '\' + ANumero + ': ' + E.Message);
  end;
end;

procedure ImprimirFacturaVcl(
  AFacturas: TdmFacturas;
  ACabecera: TDataSet;
  const AParametros: IParametrosAplicacion;
  APuedeImprimir: Boolean;
  const AGuardarPendiente: TGuardarPendienteFacturaVcl);
var
  Formulario: TfrmPrintFac;
  Fase: string;
begin
  if not APuedeImprimir then
    Abort;
  if SinVerifactuActivo(AParametros) and
     Assigned(AGuardarPendiente) then
    AGuardarPendiente();
  Fase := ACabecera.FieldByName(ffasefac).AsString;
  if ((Fase = '') or SameText(Fase, 'BORRADOR')) and
     (ACabecera.FieldByName(fescon).AsString <> 'S') and
     (ModoVerifactu(AParametros) <> mvSinVerifactu) then
  begin
    ShowMessage(SAvisoBorradorPendienteImpresionFiscal);
    Abort;
  end;
  Formulario := TfrmPrintFac.Create(Application);
  try
    Formulario.edtNroFac.Text :=
      ACabecera.FindField(fnrofac).AsString;
    Formulario.edtSerie.Text :=
      ACabecera.FindField(fseriefac).AsString;
    Formulario.dmFac := AFacturas;
    Formulario.ShowModal;
  finally
    Formulario.Free;
  end;
end;

procedure RectificarFacturaVcl(
  AOwner: TComponent;
  AFacturas: TdmFacturas);
var
  Formulario: TfrmGenFacRec;
begin
  Formulario := TfrmGenFacRec.Create(AOwner);
  try
    Formulario.Preparar(AFacturas);
    Formulario.ShowModal;
  finally
    Formulario.Free;
  end;
end;

procedure FacturarTicketVcl(
  AOwner: TComponent;
  ACabecera: TDataSet;
  const AParametros: IParametrosAplicacion);
var
  Resultado: TFacturarTicketResult;
  Serie: string;
  Numero: string;
begin
  Serie := ACabecera.FieldByName('SERIE_FAC').AsString;
  Numero := ACabecera.FieldByName('NUMERO_FAC').AsString;
  if Trim(Numero) = '' then
    ShowMessage(SErrorBorradorListaNoSeleccionado)
  else if not SameText(
    ACabecera.FieldByName('TIPO_FAC').AsString,
    'SIMPLIFICADA') then
    ShowMessage(SErrorFacturarTicketRequiereSimplificado)
  else
  begin
    Resultado := TfrmModalFacturarTicket.Ejecutar(
      AOwner,
      Serie,
      Numero,
      ACabecera.FieldByName('CODIGO_EMP_FAC').AsString,
      ACabecera.FieldByName('CODIGO_ALM_FAC').AsString,
      ACabecera.FieldByName('FECHA_FAC').AsDateTime);
    if Resultado.Aceptado then
    begin
      ShowMessage(Format(
        SInfoBorradorSustitucionTicketCreado,
        [Resultado.SerieNueva, Resultado.NumeroNueva,
         Serie, Numero, ModoVerifactuTexto(AParametros)]));
      ACabecera.Refresh;
    end;
  end;
end;

end.
