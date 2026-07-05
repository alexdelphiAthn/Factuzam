{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPruebaColumnasSku                                        }
{    Tipo:       Formulario (prueba)                                           }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: banco de pruebas de los modos de entrada de       }
{    articulos sobre un cxGrid de documento generico.                          }
{                                                                              }
{      - Radio Auto / SKU / Desglose + almacen para el stock del buscador.     }
{      - "Construir" pide el modo a la factoria (inLibColumnasSku), monta      }
{        las columnas del modo y anade las del host (Descripcion,              }
{        Cantidad), simulando lo que haria un Mto de pedidos/albaranes.        }
{      - Las lineas viven en un TClientDataSet en memoria (sin tocar BBDD      }
{        de documentos); la resolucion de articulos SI consulta la BBDD        }
{        via oConn (inLibGlobalVar).                                           }
{                                                                              }
{    NOTA: prototipo fuera de fzam.dproj; no hereda de TfrmBase a proposito    }
{    para poder probarse aislado. Al integrarlo se seguira el patron           }
{    TfrmMtoGen habitual.                                                      }
{******************************************************************************}
unit inMtoPruebaColumnasSku;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Data.DB, Datasnap.DBClient,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxRadioGroup, cxButtons,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxClasses, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations,
  inLibColumnasSkuIntf, inLibColumnasSku;

type
  TfrmMtoPruebaColumnasSku = class(TForm)
    pnlTop: TPanel;
    lblAlmacen: TcxLabel;
    txtAlmacen: TcxTextEdit;
    rgModo: TcxRadioGroup;
    btnConstruir: TcxButton;
    lblEstado: TcxLabel;
    cxgrdLineas: TcxGrid;
    tvLineas: TcxGridDBTableView;
    glLineas: TcxGridLevel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConstruirClick(Sender: TObject);
  private
    FCds: TClientDataSet;
    FDs: TDataSource;
    FModo: IModoEntradaGrid;
    procedure CrearCdsLineas;
    procedure AnadirLineaVacia;
    // Columnas propias del documento (Descripcion, Cantidad) sobre el
    // mismo View, DESPUES de que el modo cree las suyas.
    procedure AnadirColumnasHost;
    procedure ModoResuelto(const ACodArt, ASku, ADescripcion: string;
                           ACompleto: Boolean);
  end;

var
  frmMtoPruebaColumnasSku: TfrmMtoPruebaColumnasSku;

implementation

{$R *.dfm}

uses
  inLibGlobalVar;

procedure TfrmMtoPruebaColumnasSku.FormCreate(Sender: TObject);
begin
  CrearCdsLineas;
  FDs := TDataSource.Create(Self);
  FDs.DataSet := FCds;
  tvLineas.DataController.DataSource := FDs;
  AnadirLineaVacia;
  lblEstado.Caption := 'Elige modo y pulsa Construir';
end;

procedure TfrmMtoPruebaColumnasSku.FormDestroy(Sender: TObject);
begin
  // FModo es interface: se libera sola al soltar la referencia.
  FModo := nil;
  FreeAndNil(FDs);
  FreeAndNil(FCds);
end;

procedure TfrmMtoPruebaColumnasSku.CrearCdsLineas;
var
  i: Integer;
begin
  // Lineas en memoria con la misma forma que el cds de un documento real
  // (mismos nombres que usa el grid de traspasos / caja).
  FCds := TClientDataSet.Create(Self);
  FCds.FieldDefs.Add('CODIGO_ART', ftString, 20);
  FCds.FieldDefs.Add('CODIGO_UNIDAD', ftString, 60);
  FCds.FieldDefs.Add('DESCRIPCION', ftString, 100);
  FCds.FieldDefs.Add('CANTIDAD', ftFloat);
  FCds.FieldDefs.Add('NUM_ATRIBUTOS', ftInteger);
  for i := 1 to 5 do
  begin
    FCds.FieldDefs.Add('ATTR' + IntToStr(i) + '_VALOR', ftString, 30);
    FCds.FieldDefs.Add('ATTR' + IntToStr(i) + '_NOMBRE', ftString, 30);
  end;
  FCds.CreateDataSet;
end;

procedure TfrmMtoPruebaColumnasSku.AnadirLineaVacia;
begin
  FCds.Append;
  FCds.FieldByName('NUM_ATRIBUTOS').AsInteger := 0;
  FCds.FieldByName('CANTIDAD').AsFloat := 1;
  FCds.Post;
end;

procedure TfrmMtoPruebaColumnasSku.btnConstruirClick(Sender: TObject);
const
  NOMBRES_MODO: array[TModoColumnasSku] of string =
    ('Auto', 'SKU (una columna)', 'Desglose (Art + Color + Talla)');
var
  Cfg: TConfigColumnasSku;
  i: Integer;
begin
  Cfg.Conexion := oConn;
  Cfg.View := tvLineas;
  Cfg.Cds := FCds;
  Cfg.AlmacenStock := Trim(txtAlmacen.Text);
  // 0=Auto, 1=SKU, 2=Desglose (mismo orden que el enumerado).
  Cfg.Modo := TModoColumnasSku(rgModo.ItemIndex);
  Cfg.Campos.CodigoArt := 'CODIGO_ART';
  Cfg.Campos.CodigoUnidad := 'CODIGO_UNIDAD';
  Cfg.Campos.Descripcion := 'DESCRIPCION';
  Cfg.Campos.Cantidad := 'CANTIDAD';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS';
  if Cfg.Modo = mcsSku then
    // En modo SKU el documento no desglosa atributos: campos vacios
    // (asi la deteccion Auto tambien elegiria mcsSku).
    for i := 1 to 5 do
    begin
      Cfg.Campos.AttrValor[i] := '';
      Cfg.Campos.AttrNombre[i] := '';
    end
  else
    for i := 1 to 5 do
    begin
      Cfg.Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR';
      Cfg.Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) + '_NOMBRE';
    end;
  // La factoria decide (o respeta) el modo y devuelve el contrato.
  FModo := CrearModoEntradaGrid(Cfg);
  FModo.OnResuelto := ModoResuelto;
  FModo.Construir;
  AnadirColumnasHost;
  lblEstado.Caption := 'Modo efectivo: ' + NOMBRES_MODO[FModo.Modo];
  cxgrdLineas.SetFocus;
  FModo.MostrarEditor;
end;

procedure TfrmMtoPruebaColumnasSku.AnadirColumnasHost;
begin
  // Lo que haria un Mto real: sus columnas propias tras las del modo.
  with tvLineas.CreateColumn as TcxGridDBColumn do
  begin
    Caption := 'Descripción';
    DataBinding.FieldName := 'DESCRIPCION';
    Options.Editing := False;
    Width := 240;
  end;
  with tvLineas.CreateColumn as TcxGridDBColumn do
  begin
    Caption := 'Cantidad';
    DataBinding.FieldName := 'CANTIDAD';
    Width := 70;
  end;
end;

procedure TfrmMtoPruebaColumnasSku.ModoResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  if ACompleto then
  begin
    // SKU cerrado: consolidar la linea y dejar otra vacia lista para
    // encadenar la siguiente entrada (tecleo o lector).
    if FCds.State in [dsEdit, dsInsert] then
      FCds.Post;
    lblEstado.Caption := 'Resuelto: ' + ASku + ' — ' + ADescripcion;
    AnadirLineaVacia;
    FModo.MostrarEditor;
  end
  else
    lblEstado.Caption := 'Falta color/talla de ' + ACodArt;
end;

end.
