{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoDocumentosTrabajo                                        }
{    Tipo:       Formulario (Mto)                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       21/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Mantenimiento de Documentos de Trabajo.                                   }
{******************************************************************************}
unit inMtoDocumentosTrabajo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoGen, dxSkinsCore, dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB,
  cxDBData, cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization,
  Vcl.StdCtrls, cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel,
  cxTextEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls,
  cxSplitter, cxCurrencyEdit, cxCalendar, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, cxListView, Vcl.AppEvnts,
  JvComponentBase, JvEnterTab, dxShellDialogs, UniDataDocumentosTrabajo;

type
  TfrmMtoDocumentosTrabajo = class(TfrmMtoGen)
    pcAmbitoDTR: TcxPageControl;
    tsAmbitoPropiosDTR: TcxTabSheet;
    tsAmbitoCompartidosDTR: TcxTabSheet;
    colDtrId: TcxGridDBColumn;
    colDtrTitulo: TcxGridDBColumn;
    colDtrTipo: TcxGridDBColumn;
    colDtrEstado: TcxGridDBColumn;
    colDtrUsuario: TcxGridDBColumn;
    colDtrInstante: TcxGridDBColumn;
    colDtrEmpresa: TcxGridDBColumn;
    colDtrAlmacen: TcxGridDBColumn;
    splLineasDTR: TcxSplitter;
    pnlLineasDTR: TPanel;
    pnlAccionesDTR: TPanel;
    lblLineasDTR: TcxLabel;
    btnImprimirEtiquetasDTR: TcxButton;
    pcDetalleDTR: TcxPageControl;
    tsLineasDTR: TcxTabSheet;
    tsCompartirDTR: TcxTabSheet;
    cxgrdLineasDTR: TcxGrid;
    tvLineasDTR: TcxGridDBTableView;
    colDtlLinea: TcxGridDBColumn;
    colDtlArticulo: TcxGridDBColumn;
    colDtlSku: TcxGridDBColumn;
    colDtlAlmacen: TcxGridDBColumn;
    colDtlDescripcionArticulo: TcxGridDBColumn;
    colDtlDescripcionSku: TcxGridDBColumn;
    colDtlCantidadStock: TcxGridDBColumn;
    colDtlCantidad: TcxGridDBColumn;
    colDtlOrigen: TcxGridDBColumn;
    colDtlInstanteStock: TcxGridDBColumn;
    glLineasDTR: TcxGridLevel;
    cxgrdCompartidosDTR: TcxGrid;
    tvCompartidosDTR: TcxGridDBTableView;
    colDtcUsuario: TcxGridDBColumn;
    colDtcPermiso: TcxGridDBColumn;
    colDtcAlta: TcxGridDBColumn;
    glCompartidosDTR: TcxGridLevel;
    procedure btnImprimirEtiquetasDTRClick(Sender: TObject);
    procedure pcAmbitoDTRChange(Sender: TObject);
  private
    FIdEtiquetasDTR: Int64;
    procedure AplicarEstadoAmbito;
    procedure CargarAlmacenesEtiquetasDTR(ALV: TcxListView);
    procedure CrearDataSetEtiquetasDTR(ADmArt: TObject;
                                       const ACodTarifa,
                                             AAlmacenesCsv: string;
                                       AFecha: TDateTime);
  public
    dmmDocumentosTrabajo: TdmDocumentosTrabajo;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoDocumentosTrabajo: TfrmMtoDocumentosTrabajo;

implementation

uses
  UniDataArticulos, inLibFotos, inMtoModalEtiqArt;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoDocumentosTrabajo.CrearTablaPrincipal;
begin
  inherited;
  dmmDocumentosTrabajo := tdmDataModule as TdmDocumentosTrabajo;
  if dmmDocumentosTrabajo <> nil then
  begin
    dsTablaG.DataSet := dmmDocumentosTrabajo.unqryTablaG;
    tvLineasDTR.DataController.DataSource := dmmDocumentosTrabajo.dsLineas;
    tvCompartidosDTR.DataController.DataSource :=
      dmmDocumentosTrabajo.dsCompartidos;
    AplicarEstadoAmbito;
  end;
  pkFieldName := 'ID_DTR';
end;

procedure TfrmMtoDocumentosTrabajo.AplicarEstadoAmbito;
var
  bPropios: Boolean;
begin
  bPropios := True;
  if dmmDocumentosTrabajo <> nil then
  begin
    bPropios := dmmDocumentosTrabajo.Ambito = dtaPropios;
  end;
  cxGrdDBTabPrin.OptionsData.Editing := bPropios;
  tvLineasDTR.OptionsData.Editing := bPropios;
  tvCompartidosDTR.OptionsData.Editing := bPropios;
end;

procedure TfrmMtoDocumentosTrabajo.CargarAlmacenesEtiquetasDTR(
  ALV: TcxListView);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    dmmDocumentosTrabajo.CargarAlmacenesEtiquetasDoc(FIdEtiquetasDTR, ALV);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.CrearDataSetEtiquetasDTR(ADmArt: TObject;
  const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    dmmDocumentosTrabajo.CrearDataSetEtiquetasDoc(ADmArt,
                                                  FIdEtiquetasDTR,
                                                  ACodTarifa,
                                                  AAlmacenesCsv,
                                                  AFecha);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnImprimirEtiquetasDTRClick(
  Sender: TObject);
var
  formulario: TfrmPrintEtiqArt;
  dmArt: TdmArticulos;
  sTitulo: string;
begin
  inherited;
  if dmmDocumentosTrabajo <> nil then
  begin
    if (dmmDocumentosTrabajo.unqryTablaG.Active) and
       (not dmmDocumentosTrabajo.unqryTablaG.IsEmpty) then
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryLineas.Post;
      end;
      if dmmDocumentosTrabajo.unqryTablaG.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryTablaG.Post;
      end;
      if not dmmDocumentosTrabajo.unqryTablaG.FieldByName('ID_DTR').IsNull then
      begin
        FIdEtiquetasDTR := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
          'ID_DTR').AsLargeInt;
        sTitulo := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
          'TITULO_DTR').AsString;
        dmArt := TdmArticulos.Create(nil);
        try
          formulario := TfrmPrintEtiqArt.Create(Application);
          try
            formulario.DM := dmArt;
            formulario.Caption :=
              'Impresion de Etiquetas de Documento de Trabajo';
            formulario.TextoOrigenExterno := sTitulo;
            formulario.CargarAlmacenesExterno := CargarAlmacenesEtiquetasDTR;
            formulario.CrearDataSetExterno := CrearDataSetEtiquetasDTR;
            formulario.ShowModal;
          finally
            FreeAndNil(formulario);
          end;
        finally
          FreeAndNil(dmArt);
        end;
      end
      else
      begin
        ShowMessage('Grabe el Documento de Trabajo antes de imprimir etiquetas.');
      end;
    end
    else
    begin
      ShowMessage('Seleccione un Documento de Trabajo antes de imprimir etiquetas.');
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.pcAmbitoDTRChange(Sender: TObject);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    if pcAmbitoDTR.ActivePage = tsAmbitoCompartidosDTR then
    begin
      dmmDocumentosTrabajo.CambiarAmbito(dtaCompartidos);
    end
    else
    begin
      dmmDocumentosTrabajo.CambiarAmbito(dtaPropios);
    end;
    AplicarEstadoAmbito;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoDocumentosTrabajo.ResolverArtSkuActivo(out ACodArt,
  ACodSku: string);
begin
  ACodArt := '';
  ACodSku := '';
  if (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.dsLineas <> nil) and
     (dmmDocumentosTrabajo.dsLineas.DataSet <> nil) then
  begin
    inLibFotos.LeerArtSkuDeDataSet(dmmDocumentosTrabajo.dsLineas.DataSet,
                                   ACodArt, ACodSku);
  end;
  if ACodArt = '' then
  begin
    inherited ResolverArtSkuActivo(ACodArt, ACodSku);
  end;
end;

function TfrmMtoDocumentosTrabajo.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.dsLineas <> nil) then
  begin
    Result := [dsTablaG, dmmDocumentosTrabajo.dsLineas];
  end
  else
  begin
    Result := inherited DataSourcesParaFoto;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoDocumentosTrabajo);
end.
