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
  dxScrollbarAnnotations, dxCore, cxRadioGroup, Vcl.AppEvnts,
  JvComponentBase, JvEnterTab, dxShellDialogs, UniDataDocumentosTrabajo;

type
  TfrmMtoDocumentosTrabajo = class(TfrmMtoGen)
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
    lblLineasDTR: TcxLabel;
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
  private
    { Private declarations }
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
  inLibFotos;

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
  end;
  pkFieldName := 'ID_DTR';
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
