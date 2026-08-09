{******************************************************************************}
{                                                                              }
{  Módulo:       inLibListadoFastReport                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Genera, previsualiza, diseña y persiste listados mediante FastReport.    }
{******************************************************************************}
unit inLibListadoFastReport;

interface

uses
  System.Classes, Data.DB, frxClass, frxDBSet, frxDesgn,
  inLibListadosDerivadosIntf;

type
  TServicioListadoFastReport = class
  private
    FContexto: TContextoListadosDerivados;
    FContextoImpresion: string;
    FDataSet: TDataSet;
    FDataSetReporte: TfrxDBDataset;
    FDesigner: TfrxDesigner;
    FListadoActual: TListadoDerivado;
    FListadoGuardado: TListadoDerivado;
    FRepositorio: IRepositorioListadosDerivados;
    FReporte: TfrxReport;
    FTitulo: string;
    function AnchoCampo(AField: TField): Integer;
    procedure CrearInformePredeterminado;
    procedure CrearPie(
      APagina: TfrxReportPage;
      AAnchoPagina: Extended);
    function GuardarReporte(
      AReporte: TfrxReport;
      AGuardarComo: Boolean): Boolean;
    function ReemplazarExistente(
      const ANombre: string): Boolean;
    procedure VincularDataSet;
  public
    constructor Create(
      ADataSet: TDataSet;
      const ATitulo: string;
      const AContextoImpresion: string;
      const AContexto: TContextoListadosDerivados;
      const ARepositorio: IRepositorioListadosDerivados);
    destructor Destroy; override;
    procedure Cargar(
      APlantilla: TStream;
      const AListado: TListadoDerivado);
    function Disenar: Boolean;
    procedure GuardarPlantilla(AContenido: TStream);
    procedure MostrarVistaPrevia;
    function Preparar: Boolean;
    property ListadoGuardado: TListadoDerivado
      read FListadoGuardado;
  end;

implementation

uses
  Winapi.Windows, System.Math, System.SysUtils, System.UITypes,
  Vcl.Dialogs, Vcl.Graphics, Vcl.Printers, frBaseGraphicsTypes,
  inMtoModalGuardarListado;

constructor TServicioListadoFastReport.Create(
  ADataSet: TDataSet;
  const ATitulo: string;
  const AContextoImpresion: string;
  const AContexto: TContextoListadosDerivados;
  const ARepositorio: IRepositorioListadosDerivados);
begin
  if ADataSet = nil then
  begin
    raise EArgumentNilException.Create('ADataSet');
  end;
  if not ADataSet.Active then
  begin
    raise EInvalidOpException.Create(
      'Consulta el listado antes de abrir FastReport.');
  end;
  if ARepositorio = nil then
  begin
    raise EArgumentNilException.Create('ARepositorio');
  end;
  inherited Create;
  FDataSet := ADataSet;
  FTitulo := ATitulo;
  FContextoImpresion := AContextoImpresion;
  FContexto := AContexto;
  FRepositorio := ARepositorio;
  FReporte := TfrxReport.Create(nil);
  FDataSetReporte := TfrxDBDataset.Create(nil);
  FDataSetReporte.Name := 'fxdsListadoContazam';
  FDataSetReporte.UserName := 'Listado';
  FDataSetReporte.DataSet := FDataSet;
  FDesigner := TfrxDesigner.Create(nil);
  FDesigner.OnSaveReport := GuardarReporte;
end;

destructor TServicioListadoFastReport.Destroy;
begin
  FreeAndNil(FDesigner);
  FreeAndNil(FReporte);
  FreeAndNil(FDataSetReporte);
  FRepositorio := nil;
  inherited;
end;

function TServicioListadoFastReport.AnchoCampo(
  AField: TField): Integer;
var
  iAncho: Integer;
begin
  iAncho := Max(AField.DisplayWidth, Length(AField.DisplayLabel));
  Result := EnsureRange(iAncho, 8, 32);
end;

procedure TServicioListadoFastReport.Cargar(
  APlantilla: TStream;
  const AListado: TListadoDerivado);
begin
  FListadoActual := AListado;
  FListadoGuardado := Default(TListadoDerivado);
  if (APlantilla <> nil) and (APlantilla.Size > 0) then
  begin
    APlantilla.Position := 0;
    FReporte.LoadFromStream(APlantilla);
  end
  else
  begin
    CrearInformePredeterminado;
  end;
  VincularDataSet;
end;

procedure TServicioListadoFastReport.CrearInformePredeterminado;
var
  dAncho: Extended;
  dAnchoPagina: Extended;
  dPesoTotal: Extended;
  dPosicion: Extended;
  iCampo: Integer;
  iCamposVisibles: Integer;
  oBandaDatos: TfrxMasterData;
  oBandaEncabezado: TfrxPageHeader;
  oBandaTitulo: TfrxReportTitle;
  oCampo: TField;
  oMemo: TfrxMemoView;
  oPagina: TfrxReportPage;
begin
  FReporte.Clear;
  FReporte.DataSets.Clear;
  FReporte.DataSets.Add(FDataSetReporte);
  oPagina := TfrxReportPage.Create(FReporte);
  oPagina.CreateUniqueName;
  iCamposVisibles := 0;
  dPesoTotal := 0;
  for iCampo := 0 to FDataSet.FieldCount - 1 do
  begin
    oCampo := FDataSet.Fields[iCampo];
    if oCampo.Visible then
    begin
      Inc(iCamposVisibles);
      dPesoTotal := dPesoTotal + AnchoCampo(oCampo);
    end;
  end;
  if iCamposVisibles > 5 then
  begin
    oPagina.Orientation := poLandscape;
  end
  else
  begin
    oPagina.Orientation := poPortrait;
  end;
  oPagina.LeftMargin := 10;
  oPagina.RightMargin := 10;
  oPagina.TopMargin := 10;
  oPagina.BottomMargin := 10;
  dAnchoPagina :=
    (oPagina.PaperWidth - oPagina.LeftMargin -
     oPagina.RightMargin) * fr01cm;
  oBandaTitulo := TfrxReportTitle.Create(oPagina);
  oBandaTitulo.CreateUniqueName;
  oBandaTitulo.SetBounds(0, 0, dAnchoPagina, 16 * fr01cm);
  oMemo := TfrxMemoView.Create(oBandaTitulo);
  oMemo.CreateUniqueName;
  oMemo.SetBounds(0, 0, dAnchoPagina, 8 * fr01cm);
  oMemo.Text := FTitulo;
  oMemo.Font.Name := 'Lucida Sans';
  oMemo.Font.Size := 16;
  oMemo.Font.Style := [fsBold];
  oMemo.HAlign := haCenter;
  oMemo.VAlign := vaCenter;
  oMemo := TfrxMemoView.Create(oBandaTitulo);
  oMemo.CreateUniqueName;
  oMemo.SetBounds(0, 8 * fr01cm, dAnchoPagina, 7 * fr01cm);
  oMemo.Text := FContextoImpresion;
  oMemo.Font.Name := 'Lucida Sans';
  oMemo.Font.Size := 8;
  oMemo.HAlign := haCenter;
  oMemo.VAlign := vaCenter;
  oBandaEncabezado := TfrxPageHeader.Create(oPagina);
  oBandaEncabezado.CreateUniqueName;
  oBandaEncabezado.SetBounds(
    0,
    18 * fr01cm,
    dAnchoPagina,
    8 * fr01cm);
  oBandaDatos := TfrxMasterData.Create(oPagina);
  oBandaDatos.CreateUniqueName;
  oBandaDatos.SetBounds(
    0,
    28 * fr01cm,
    dAnchoPagina,
    6 * fr01cm);
  oBandaDatos.DataSet := FDataSetReporte;
  dPosicion := 0;
  for iCampo := 0 to FDataSet.FieldCount - 1 do
  begin
    oCampo := FDataSet.Fields[iCampo];
    if oCampo.Visible then
    begin
      dAncho := dAnchoPagina * AnchoCampo(oCampo) / dPesoTotal;
      oMemo := TfrxMemoView.Create(oBandaEncabezado);
      oMemo.CreateUniqueName;
      oMemo.SetBounds(dPosicion, 0, dAncho, 8 * fr01cm);
      oMemo.Text := oCampo.DisplayLabel;
      oMemo.Color := RGB(36, 75, 116);
      oMemo.Font.Name := 'Lucida Sans';
      oMemo.Font.Size := 8;
      oMemo.Font.Style := [fsBold];
      oMemo.Font.Color := clWhite;
      oMemo.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
      oMemo.HAlign := haCenter;
      oMemo.VAlign := vaCenter;
      oMemo.WordWrap := True;
      oMemo := TfrxMemoView.Create(oBandaDatos);
      oMemo.CreateUniqueName;
      oMemo.SetBounds(dPosicion, 0, dAncho, 6 * fr01cm);
      oMemo.DataSet := FDataSetReporte;
      oMemo.DataField := oCampo.FieldName;
      oMemo.Font.Name := 'Lucida Sans';
      oMemo.Font.Size := 8;
      oMemo.Frame.Typ := [ftLeft, ftRight, ftTop, ftBottom];
      oMemo.VAlign := vaCenter;
      if oCampo.DataType in [
        ftSmallint,
        ftInteger,
        ftWord,
        ftFloat,
        ftCurrency,
        ftBCD,
        ftLargeint,
        ftFMTBcd
      ] then
      begin
        oMemo.HAlign := haRight;
      end;
      dPosicion := dPosicion + dAncho;
    end;
  end;
  CrearPie(oPagina, dAnchoPagina);
end;

procedure TServicioListadoFastReport.CrearPie(
  APagina: TfrxReportPage;
  AAnchoPagina: Extended);
var
  oBanda: TfrxPageFooter;
  oMemo: TfrxMemoView;
begin
  oBanda := TfrxPageFooter.Create(APagina);
  oBanda.CreateUniqueName;
  oBanda.SetBounds(0, 1000, AAnchoPagina, 7 * fr01cm);
  oMemo := TfrxMemoView.Create(oBanda);
  oMemo.CreateUniqueName;
  oMemo.SetBounds(0, 0, AAnchoPagina / 2, 6 * fr01cm);
  oMemo.Text := '[Date] [Time]';
  oMemo.Font.Name := 'Lucida Sans';
  oMemo.Font.Size := 8;
  oMemo.Frame.Typ := [ftTop];
  oMemo := TfrxMemoView.Create(oBanda);
  oMemo.CreateUniqueName;
  oMemo.SetBounds(
    AAnchoPagina / 2,
    0,
    AAnchoPagina / 2,
    6 * fr01cm);
  oMemo.Text := 'Página [Page#] de [TotalPages#]';
  oMemo.Font.Name := 'Lucida Sans';
  oMemo.Font.Size := 8;
  oMemo.Frame.Typ := [ftTop];
  oMemo.HAlign := haRight;
end;

function TServicioListadoFastReport.Disenar: Boolean;
begin
  FListadoGuardado := Default(TListadoDerivado);
  VincularDataSet;
  FReporte.PrepareReport(True);
  FReporte.DesignReport(True, False);
  Result := FListadoGuardado.Id <> 0;
end;

procedure TServicioListadoFastReport.GuardarPlantilla(
  AContenido: TStream);
begin
  if AContenido = nil then
  begin
    raise EArgumentNilException.Create('AContenido');
  end;
  AContenido.Size := 0;
  FReporte.SaveToStream(AContenido);
  AContenido.Position := 0;
end;

function TServicioListadoFastReport.GuardarReporte(
  AReporte: TfrxReport;
  AGuardarComo: Boolean): Boolean;
var
  iExistente: Int64;
  oDialogo: TfrmModalGuardarListado;
  oGrupos: TGruposListadoDerivado;
  oListadoDialogo: TListadoDerivado;
  oSolicitud: TSolicitudGuardarListadoDerivado;
  oStream: TMemoryStream;
begin
  Result := False;
  oListadoDialogo := FListadoActual;
  if AGuardarComo then
  begin
    oListadoDialogo.Id := 0;
    if Trim(oListadoDialogo.Nombre) <> '' then
    begin
      oListadoDialogo.Nombre := oListadoDialogo.Nombre + ' - copia';
    end;
  end;
  if Trim(oListadoDialogo.Nombre) = '' then
  begin
    oListadoDialogo.Nombre := FTitulo;
  end;
  oGrupos := FRepositorio.ListarGrupos(FContexto.Usuario);
  oDialogo := TfrmModalGuardarListado.Create(nil);
  try
    oDialogo.Preparar(
      FContexto.Usuario,
      FContexto.Empresa,
      oGrupos,
      oListadoDialogo);
    if oDialogo.ShowModal = mrOk then
    begin
      oSolicitud := Default(TSolicitudGuardarListadoDerivado);
      oSolicitud.Id := oListadoDialogo.Id;
      oSolicitud.Contexto := FContexto;
      oSolicitud.Nombre := oDialogo.Nombre;
      oSolicitud.Descripcion := oDialogo.Descripcion;
      oSolicitud.Alcance := oDialogo.Alcance;
      iExistente := FRepositorio.BuscarId(
        FContexto,
        oSolicitud.Nombre,
        oSolicitud.Alcance);
      if (iExistente = 0) or (iExistente = oSolicitud.Id) or
        ReemplazarExistente(oSolicitud.Nombre) then
      begin
        if (iExistente <> 0) and (iExistente <> oSolicitud.Id) then
        begin
          oSolicitud.Id := iExistente;
        end;
        oStream := TMemoryStream.Create;
        try
          AReporte.SaveToStream(oStream);
          oStream.Position := 0;
          FListadoGuardado := FRepositorio.Guardar(
            oSolicitud,
            oStream);
          FListadoActual := FListadoGuardado;
          Result := True;
        finally
          FreeAndNil(oStream);
        end;
      end;
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TServicioListadoFastReport.MostrarVistaPrevia;
begin
  if Preparar then
  begin
    FReporte.ShowPreparedReport;
  end;
end;

function TServicioListadoFastReport.Preparar: Boolean;
begin
  VincularDataSet;
  Result := FReporte.PrepareReport(True);
end;

function TServicioListadoFastReport.ReemplazarExistente(
  const ANombre: string): Boolean;
begin
  Result := MessageDlg(
    Format(
      'Ya existe el formato "%s" con ese alcance. ¿Deseas reemplazarlo?',
      [ANombre]),
    mtConfirmation,
    [mbYes, mbNo],
    0) = mrYes;
end;

procedure TServicioListadoFastReport.VincularDataSet;
var
  iObjeto: Integer;
  oMemo: TfrxCustomMemoView;
  oObjeto: TfrxComponent;
begin
  FDataSetReporte.DataSet := FDataSet;
  FReporte.DataSets.Clear;
  FReporte.DataSets.Add(FDataSetReporte);
  for iObjeto := 0 to FReporte.AllObjects.Count - 1 do
  begin
    oObjeto := TfrxComponent(FReporte.AllObjects[iObjeto]);
    if oObjeto is TfrxDataBand then
    begin
      TfrxDataBand(oObjeto).DataSet := FDataSetReporte;
    end;
    if oObjeto is TfrxCustomMemoView then
    begin
      oMemo := TfrxCustomMemoView(oObjeto);
      if oMemo.DataField <> '' then
      begin
        oMemo.DataSet := FDataSetReporte;
      end;
    end;
  end;
end;

end.
