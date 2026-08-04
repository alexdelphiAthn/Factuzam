{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalEtiqDev                                             }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       23/05/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion de etiquetas de un DEVOLUCION DE COMPRA. Clon          }
{    simplificado de inMtoModalEtiqArt: misma estructura de TfrmPrint y        }
{    mismo dataset de etiquetas (cdsEtiquetasArt en TdmArticulos), pero        }
{    los SKUs vienen filtrados por las lineas del devolucion. El listado       }
{    de almacenes que se pinta esta limitado a los almacenes que aparecen      }
{    en las lineas (no toda la red), porque un devolucion puede tener varios.  }
{                                                                              }
{    El .fr3 se diseña a mano en el modal una vez; si se quiere compartir      }
{    plantilla con el modal de articulos, basta con copiar el contenido        }
{    de frxrprt1 entre los .dfm (mismo nombre de datasets y aliases).          }
{******************************************************************************}
unit inMtoModalEtiqDev;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni, frxExportXLSX, frxClass,
  frxExportBaseDialog, frxExportPDF, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, Vcl.ExtCtrls, dxSkinsCore, dxSkinBlue, cxControls, cxContainer,
  cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit, cxLabel, cxGroupBox,
  cxRadioGroup, cxDropDownEdit, cxDateUtils, cxCalendar, cxListView,
  cxCheckBox, ComCtrls,
  UniDataArticulos, UniDataDevolucionesCompra, inLibLayoutForm,
  JvComponentBase, JvEnterTab, frxSmartMemo, frLocalization, frLanguageSpanish,
  dxCore, System.Actions, Vcl.ActnList, frxExportBaseImageSettingsDialog,
  frCoreClasses, System.Rtti;

type
  TfrmPrintEtiqDev = class(TfrmPrint)
    pnlOpciones: TPanel;
    cxlblTarifa: TcxLabel;
    cbbTarifa: TcxComboBox;
    cxlblFecha: TcxLabel;
    dtFechaAplicacion: TcxDateEdit;
    cxlblAlmacenes: TcxLabel;
    lvAlmacenes: TcxListView;
    cxlblDevolucion: TcxLabel;
    edtDevolucion: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FCodigosTarifa: TStringList;
    FLayout: TLayoutLoader;
    function ObtenerCodigoTarifa: string;
    function ObtenerAlmacenesCsv: string;
  public
    DMArt:    TdmArticulos;        // datasets fxds / cdsEtiquetasArt
    DMDevc:   TdmDevolucionesCompra;  // queries del devolucion
    Serie:    string;
    Numero:   string;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    function  RelacionarClientDataSetConQuery(aCDS: TDataSet): TDataSet;
    override;
    procedure OnGuiasAplicadas; override;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgArticulos;

procedure TfrmPrintEtiqDev.FormCreate(Sender: TObject);
begin
  // El Name del form coincide con el del modal de etiquetas de
  // articulos ('frmPrintEtiqArt') — esta fijado en el .dfm para que
  // TfrmPrint.FormCreate (que se ejecuta ANTES por herencia) ya lea
  // ese Name al cargar perfiles. Asi compartimos formatos guardados
  // y guias entre los dos modales sin duplicar el diseno.
  inherited;
  // Snapshot del diseno embebido en frxrprt1 para que la opcion
  // 'Predeterminado' del selector de formatos (Consultar_Formularios)
  // pueda restaurarlo via frxrprt1.AssignAll(frxReportOrigen). Sin
  // este AssignAll la primera vez, frxReportOrigen queda vacio y
  // 'Predeterminado' pinta un report en blanco.
  frxReportOrigen.AssignAll(frxrprt1);
  FCodigosTarifa := TStringList.Create;
  FLayout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  dtFechaAplicacion.Date := Date;
end;

procedure TfrmPrintEtiqDev.FormShow(Sender: TObject);
var
  Idx: Integer;
begin
  inherited;
  edtDevolucion.Text := Serie + ' / ' + Numero;
  // Tarifas: reutilizamos las del DM de articulos (mismas que en Mto
  // Articulos).
  if Assigned(DMArt) then
  begin
    Idx := -1;
    DMArt.CargarTarifasEtiquetas(cbbTarifa.Properties.Items,
                                 FCodigosTarifa,
                                 Idx);
    if Idx >= 0 then cbbTarifa.ItemIndex := Idx;
  end;
  // Almacenes: solo los que aparecen en las lineas del devolucion. Usamos
  // el helper del DM de devoluciones (a anadir en commit conjunto).
  if Assigned(DMDevc) then
    DMDevc.CargarAlmacenesDelDevolucion(Serie, Numero, lvAlmacenes);
  if FLayout.Disponible then FLayout.RestaurarGeometria(Self);
end;

procedure TfrmPrintEtiqDev.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLayout);
  FreeAndNil(FCodigosTarifa);
  inherited;
end;

function TfrmPrintEtiqDev.ObtenerCodigoTarifa: string;
begin
  Result := '';
  if (cbbTarifa.ItemIndex >= 0) and
     (cbbTarifa.ItemIndex < FCodigosTarifa.Count) then
    Result := FCodigosTarifa[cbbTarifa.ItemIndex];
end;

function TfrmPrintEtiqDev.ObtenerAlmacenesCsv: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to lvAlmacenes.Items.Count - 1 do
    if lvAlmacenes.Items[i].Checked then
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + lvAlmacenes.Items[i].Caption;
    end;
end;

procedure TfrmPrintEtiqDev.preparar_consulta;
begin
  if ObtenerCodigoTarifa = '' then
  begin
    ShowMessage(SErrorTarifaEtiquetasNoSeleccionada);
    Abort;
  end;
  // Generamos el dataset filtrado a los SKUs del devolucion (lo crea el
  // DM de devoluciones apoyandose en la query base de etiquetas del DM
  // de articulos pero con WHERE adicional por SKU IN (...)).
  DMDevc.CrearDataSetEtiquetasAlb(
    DMArt, Serie, Numero,
    ObtenerCodigoTarifa, ObtenerAlmacenesCsv,
    dtFechaAplicacion.Date);
end;

procedure TfrmPrintEtiqDev.AfterReportLoaded;
var
  i: Integer;
  obj: TfrxComponent;
  ctx: TRttiContext;
  rType: TRttiType;
  propDs, propName: TRttiProperty;
  dsName: string;
begin
  inherited;
  if not Assigned(DMArt) then Exit;
  if not DMArt.cdsEtiquetasArt.Active then
    DMArt.CrearDataSetEtiquetasArt('DUMMY_DISENO', '', '', Date);
  DMArt.fxdsEtiquetasArt.DataSet := nil;
  DMArt.fxdsEtiquetasArt.DataSet := DMArt.cdsEtiquetasArt;
  DMArt.fxdsEtiquetasArt.FieldAliases.Clear;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(DMArt.fxdsEtiquetasArt);
  ctx := TRttiContext.Create;
  try
    for i := 0 to frxrprt1.AllObjects.Count - 1 do
    begin
      obj := TfrxComponent(frxrprt1.AllObjects[i]);
      rType := ctx.GetType(obj.ClassType);
      propDs   := rType.GetProperty('DataSet');
      propName := rType.GetProperty('DataSetName');
      if (propDs <> nil) and (propName <> nil) and propName.IsReadable and
          propDs.IsWritable then
      begin
        dsName := propName.GetValue(obj).AsString;
        if SameText(dsName, 'EtiquetasArt') then
          propDs.SetValue(obj, DMArt.fxdsEtiquetasArt);
      end;
    end;
  finally
    ctx.Free;
  end;
end;

function TfrmPrintEtiqDev.RelacionarClientDataSetConQuery(
                                                 aCDS: TDataSet): TDataSet;
begin
  if Assigned(DMArt) then
    Result := DMArt.unqryArtPrint
  else
    Result := inherited RelacionarClientDataSetConQuery(aCDS);
end;

procedure TfrmPrintEtiqDev.OnGuiasAplicadas;
begin
  inherited;
  if Assigned(DMArt) and DMArt.unqryArtPrint.Active then
  begin
    DMArt.PoblarCdsEtiquetasArtDesdeUniQuery;
    if Trim(ObtenerAlmacenesCsv) <> '' then
      DMArt.ExpandirEtiquetasPorStock('STOCK_FILTRADO');
    DMArt.cdsEtiquetasArt.First;
    DMArt.fxdsEtiquetasArt.DataSet := nil;
    DMArt.fxdsEtiquetasArt.DataSet := DMArt.cdsEtiquetasArt;
    DMArt.fxdsEtiquetasArt.FieldAliases.Clear;
  end;
end;

end.
