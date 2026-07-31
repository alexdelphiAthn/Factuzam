{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalEtiqArt                                             }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       12/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion de etiquetas de articulo / SKU.                        }
{    Permite elegir tarifa, fecha de aplicacion y uno o varios almacenes       }
{    para filtrar el stock que entra en la impresion.                          }
{    Persiste la geometria del formulario via inLibLayoutForm.                 }
{******************************************************************************}
unit inMtoModalEtiqArt;

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
  cxCheckBox, ComCtrls, UniDataArticulos, inLibLayoutForm,
  JvComponentBase, JvEnterTab, frxSmartMemo, frLocalization, frLanguageSpanish,
  dxCore, System.Actions, Vcl.ActnList, frxExportBaseImageSettingsDialog,
  frCoreClasses, system.Rtti;

type
  TCrearDataSetEtiquetasProc = procedure(ADmArt: TObject;
                                          const ACodTarifa,
                                                AAlmacenesCsv: string;
                                          AFecha: TDateTime) of object;
  TCargarAlmacenesEtiquetasProc = procedure(ALV: TcxListView) of object;

  TfrmPrintEtiqArt = class(TfrmPrint)
    pnlOpciones: TPanel;
    cxlblTarifa: TcxLabel;
    cbbTarifa: TcxComboBox;
    cxlblFecha: TcxLabel;
    dtFechaAplicacion: TcxDateEdit;
    cxlblAlmacenes: TcxLabel;
    lvAlmacenes: TcxListView;
    cxlblArticulo: TcxLabel;
    edtCodArt: TcxTextEdit;
    chkSoloEsteArt: TcxCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnEditarClick(Sender: TObject);
  private
    FCrearDataSetExterno: TCrearDataSetEtiquetasProc;
    FCargarAlmacenesExterno: TCargarAlmacenesEtiquetasProc;
    FTextoOrigenExterno: string;
    FCodigosTarifa: TStringList;
    FLayout: TLayoutLoader;
    procedure AplicarOrigenExterno;
    procedure RestaurarLayout;
    procedure GuardarLayout;
    function ObtenerCodigoTarifa: string;
    function ObtenerAlmacenesCsv: string;
  public
    // Data module asignado por el Mto Articulos que invoca este modal
    // (campo de instancia del form padre, no variable global, para que
    // funcione cuando hay dos ventanas Articulos abiertas a la vez).
    DM: TdmArticulos;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
    function RelacionarClientDataSetConQuery(aCDS: TDataSet): TDataSet; override; // <-- AÑADIR
    procedure OnGuiasAplicadas; override;
    property CrearDataSetExterno: TCrearDataSetEtiquetasProc
      read FCrearDataSetExterno write FCrearDataSetExterno;
    property CargarAlmacenesExterno: TCargarAlmacenesEtiquetasProc
      read FCargarAlmacenesExterno write FCargarAlmacenesExterno;
    property TextoOrigenExterno: string
      read FTextoOrigenExterno write FTextoOrigenExterno;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgArticulos;

procedure TfrmPrintEtiqArt.AfterReportLoaded;
var
  i: Integer;
  obj: TfrxComponent;
  ctx: TRttiContext;
  rType: TRttiType;
  propDs, propName: TRttiProperty;
  dsName: string;
begin
  inherited;
  if Assigned(DM) then
  begin
    // 1. Si está cerrado (ej: al entrar a Diseñar), forzamos la estructura de columnas
    if not DM.cdsEtiquetasArt.Active then
      DM.CrearDataSetEtiquetasArt('DUMMY_DISENO', '', '', Date);

    // 2. Limpieza de cachés del puente de FastReport
    DM.fxdsEtiquetasArt.DataSet := nil;
    DM.fxdsEtiquetasArt.DataSet := DM.cdsEtiquetasArt;
    DM.fxdsEtiquetasArt.FieldAliases.Clear;

    // 3. Forzamos el registro del Dataset global del informe
    frxrprt1.DataSets.Clear;
    frxrprt1.DataSets.Add(DM.fxdsEtiquetasArt);

    // 4. SOLUCIÓN AL "PREDETERMINADO VACÍO": Re-enlazamos componentes por Nombre vía RTTI
    ctx := TRttiContext.Create;
    try
      for i := 0 to frxrprt1.AllObjects.Count - 1 do
      begin
        obj := TfrxComponent(frxrprt1.AllObjects[i]);
        rType := ctx.GetType(obj.ClassType);

        propDs   := rType.GetProperty('DataSet');
        propName := rType.GetProperty('DataSetName');

        if (propDs <> nil) and (propName <> nil) and propName.IsReadable and propDs.IsWritable then
        begin
          dsName := propName.GetValue(obj).AsString;
          if SameText(dsName, 'EtiquetasArt') then
            propDs.SetValue(obj, DM.fxdsEtiquetasArt);
        end;
      end;
    finally
      ctx.Free;
    end;
  end;
end;

function TfrmPrintEtiqArt.RelacionarClientDataSetConQuery(aCDS: TDataSet): TDataSet;
begin
  // Le decimos a la clase base que cuando vea el ClientDataSet, aplique el LEFT JOIN a la Query física
  if Assigned(DM) then
    Result := DM.unqryArtPrint
  else
    Result := inherited RelacionarClientDataSetConQuery(aCDS);
end;

procedure TfrmPrintEtiqArt.OnGuiasAplicadas;
begin
  inherited;
  if Assigned(DM) then
  begin
    if Assigned(FCrearDataSetExterno) then
    begin
      FCrearDataSetExterno(DM, ObtenerCodigoTarifa, ObtenerAlmacenesCsv,
                           dtFechaAplicacion.Date);
      DM.fxdsEtiquetasArt.DataSet := nil;
      DM.fxdsEtiquetasArt.DataSet := DM.cdsEtiquetasArt;
      DM.fxdsEtiquetasArt.FieldAliases.Clear;
    end
    else if DM.unqryArtPrint.Active then
    begin
      // 1. Esto destruye y recrea el ClientDataSet bajo nuestros pies
      DM.PoblarCdsEtiquetasArtDesdeUniQuery;

      // 2. Expandimos por stock si es necesario
      if Trim(ObtenerAlmacenesCsv) <> '' then
        DM.ExpandirEtiquetasPorStock('STOCK_FILTRADO');

      DM.cdsEtiquetasArt.First;

      // 3. PARCHE: Refrescamos la caché del puente de FastReport
      // Como el paso 1 acaba de destruir la estructura en memoria,
      // forzamos al componente de FastReport a re-leerla.
      DM.fxdsEtiquetasArt.DataSet := nil;
      DM.fxdsEtiquetasArt.DataSet := DM.cdsEtiquetasArt;
      DM.fxdsEtiquetasArt.FieldAliases.Clear;
    end;
  end;
end;

//procedure TfrmPrintEtiqArt.AfterReportLoaded;
//begin
//  // 1. Llamamos al inherited para mantener la lógica base (como la carga de fotos)
//  inherited;
//
//  if Assigned(DM) then
//  begin
//    // 2. DETECCIÓN DE MODO DISEÑO:
//    // Si el ClientDataSet está cerrado, es que venimos del botón "Editar".
//    // Inicializamos su estructura llamando a tu método del DataModule.
//    if not DM.cdsEtiquetasArt.Active then
//    begin
//      // Usamos un código de artículo inexistente para que la base de datos responda
//      // en 0 milisegundos, pero genere el catálogo completo de columnas en el dataset.
//      DM.CrearDataSetEtiquetasArt('DUMMY_DISENO', '', '', Date);
//    end;
//
//    // 3. Re-enlazamos los datasets del informe a nuestra instancia de DM
//    RebindReportDataSetsByDataModule(frxrprt1, DM);
//
//    // 4. FORZAR ACTUALIZACIÓN EN EL DISEÑADOR:
//    // Al vaciar los FieldAliases, obligamos a FastReport a descartar su caché estática
//    // y re-escanear en vivo los campos del ClientDataSet que acabamos de estructurar.
//    DM.fxdsEtiquetasArt.DataSet := nil;
//    DM.fxdsEtiquetasArt.DataSet := DM.cdsEtiquetasArt;
//    DM.fxdsEtiquetasArt.FieldAliases.Clear;
//  end;
//end;

procedure TfrmPrintEtiqArt.btnEditarClick(Sender: TObject);
begin
  inherited;
  AfterReportLoaded;
end;

procedure TfrmPrintEtiqArt.FormCreate(Sender: TObject);
begin
  inherited;
  FCodigosTarifa := TStringList.Create;
  FLayout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  dtFechaAplicacion.Date := Date;
end;

procedure TfrmPrintEtiqArt.FormShow(Sender: TObject);
var
  Idx: Integer;
begin
  inherited;
  AplicarOrigenExterno;
  // Las cargas que dependen de DM se hacen aqui (no en FormCreate)
  // porque la asignacion formulario.DM := dmmArticulos en el invocador
  // ocurre DESPUES del Create y ANTES del ShowModal.
  if Assigned(DM) then
  begin
    Idx := -1;
    DM.CargarTarifasEtiquetas(cbbTarifa.Properties.Items, FCodigosTarifa, Idx);
    if Idx >= 0 then
      cbbTarifa.ItemIndex := Idx;
    if Assigned(FCargarAlmacenesExterno) then
    begin
      FCargarAlmacenesExterno(lvAlmacenes);
    end
    else
    begin
      DM.CargarAlmacenesEtiquetas(lvAlmacenes);
    end;
  end;
  RestaurarLayout;
end;

procedure TfrmPrintEtiqArt.AplicarOrigenExterno;
begin
  if Trim(FTextoOrigenExterno) <> '' then
  begin
    cxlblArticulo.Caption := SCaptionDocumentoEtiqueta;
    edtCodArt.Text := FTextoOrigenExterno;
    chkSoloEsteArt.Checked := False;
    chkSoloEsteArt.Visible := False;
  end;
end;

procedure TfrmPrintEtiqArt.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLayout);
  FreeAndNil(FCodigosTarifa);
  inherited;
end;

procedure TfrmPrintEtiqArt.FormKeyDown(Sender: TObject; var Key: Word;
                                                        Shift: TShiftState);
begin
  // Alt+F12 -> guardar layout
  if (Key = VK_F12) and (ssAlt in Shift) and not (ssCtrl in Shift) then
    GuardarLayout;
  // Ctrl+F12 -> resetear layout
  if (Key = VK_F12) and (ssCtrl in Shift) and not (ssAlt in Shift) then
    ResetearLayout(
      Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
end;

procedure TfrmPrintEtiqArt.RestaurarLayout;
begin
  if not FLayout.Disponible then Exit;
  FLayout.RestaurarGeometria(Self);
end;

procedure TfrmPrintEtiqArt.GuardarLayout;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(
    Self.Name, PerfilesEscritura, SolicitudPermisoLayout);
  try
    Layout.GuardarGeometria(Self);
    if Layout.PreguntarYGrabar('Personalizacion Impresion Etiquetas Articulo')
      then ShowMessage(SInfoLayoutEtiquetasGuardado);
  finally
    FreeAndNil(Layout);
  end;
end;

function TfrmPrintEtiqArt.ObtenerCodigoTarifa: string;
begin
  Result := '';
  if (cbbTarifa.ItemIndex >= 0) and
     (cbbTarifa.ItemIndex < FCodigosTarifa.Count) then
    Result := FCodigosTarifa[cbbTarifa.ItemIndex];
end;

function TfrmPrintEtiqArt.ObtenerAlmacenesCsv: string;
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

procedure TfrmPrintEtiqArt.preparar_consulta;
var
  sCodArt: string;
begin
  if ObtenerCodigoTarifa = '' then
  begin
    ShowMessage(SErrorTarifaEtiquetasNoSeleccionada);
    Abort;
  end;
  if Assigned(FCrearDataSetExterno) then
  begin
    FCrearDataSetExterno(DM,
                         ObtenerCodigoTarifa,
                         ObtenerAlmacenesCsv,
                         dtFechaAplicacion.Date);
  end
  else
  begin
    // chkSoloEsteArt limita a un unico articulo. Si esta sin marcar la consulta
    // ataca a todos los articulos activos del catalogo.
    sCodArt := '';
    if chkSoloEsteArt.Checked then
      sCodArt := Trim(edtCodArt.Text);
    DM.CrearDataSetEtiquetasArt(sCodArt,
                                ObtenerCodigoTarifa,
                                ObtenerAlmacenesCsv,
                                dtFechaAplicacion.Date);
  end;
end;

end.
