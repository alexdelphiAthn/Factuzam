{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionProveedor                     }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Proveedor de la sesion de compra: busqueda, rotulo, ficha, defectos       }
{    de compras y kits de cantidades por talla. Incluye el selector de         }
{    color basico de la linea, que comparte paleta y swatch.                   }
{                                                                              }
{    Recibe el data module de sesiones porque las operaciones de kit           }
{    (UniDataComprasSesionesOperaciones) estan escritas contra el.             }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionProveedor;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Types,
  System.Variants,
  System.UITypes,
  Data.DB,
  Uni,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Menus,
  cxGraphics,
  cxEdit,
  cxButtonEdit,
  cxGridCustomTableView,
  cxGridTableView,
  cxGridDBTableView,
  inLibComprasSesiones,
  inLibGenBusq,
  inLibGridTallasInline,
  UniDataComprasSesiones;

type
  TEntornoProveedorSesion = record
    Conexion: TUniConnection;
    Servicio: TServicioComprasSesiones;
    Datos: TdmComprasSesiones;
    BusquedaVisual: IBusquedaVisual;
    Vista: TcxGridDBTableView;
    ColumnaColorBasico: TcxGridDBColumn;
    BotonKits: TControl;
    ObtenerGestorTallas: TFunc<TGestorGridTallas>;
    MostrarNombreProveedor: TProc<string>;
    RefrescarVisibilidadTipoIva: TProc;
    AbrirDistribuidor: TProc<string>;
    Registrar: TProc<string>;
  end;

  TCoordinadorProveedorSesion = class
  private
    FEntorno: TEntornoProveedorSesion;
    FBasicosColor: TArray<string>;
    FFichaCargada: string;
    FMenuKits: TPopupMenu;
    FCodigosKits: TArray<string>;
    FSwatch: TBitmap;
    function GestorTallas: TGestorGridTallas;
    function CodigoProveedorCabecera: string;
    function EsFormatoDistribuido: Boolean;
    procedure KitDelMenuElegido(ASender: TObject);
    procedure ConstruirMenuKits;
    procedure Anotar(const ATexto: string);
  public
    constructor Create(const AEntorno: TEntornoProveedorSesion);
    destructor Destroy; override;
    // Codigos de color basico activos; alimentan la paleta de la linea.
    procedure CargarBasicosColor;
    // Buscador generico sobre vi_proveedores; vuelca el codigo elegido
    // en la cabecera de la sesion.
    procedure BuscarProveedor;
    procedure ActualizarRotuloProveedor;
    // Reabre ficha y kits solo si cambia el proveedor o si la consulta
    // quedo cerrada tras un ResetForm.
    procedure RecargarProveedorSesion;
    // Copia a la cabecera los defectos de compras del proveedor.
    procedure CopiarDefectosProveedor;
    procedure AplicarKitALineaActual(const ACodigoKit: string);
    // Despliega el popup con los kits del proveedor sobre la linea con
    // foco. False si no hay linea o el proveedor no tiene kits.
    function MostrarMenuKits: Boolean;
    procedure ElegirColorBasico(ASender: TObject);
    // Swatch en el boton del editor de color basico de la linea.
    procedure PrepararEditorColorBasico(
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    // True si la celda de color basico ya queda pintada aqui.
    function DibujarCeldaColor(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
  end;

implementation

uses
  Vcl.Dialogs,
  inLibAtributosPaleta,
  inLibMsgArticulos,
  inLibMsgCompras,
  inLibPresentacionDocumento,
  UniDataComprasSesionesOperaciones;

const
  // Eje de variacion de color en fza_atributos_valores.
  cIdVaColor = 'CO';
  cAnchoPaleta = 160;
  cLadoSwatch = 14;

constructor TCoordinadorProveedorSesion.Create(
  const AEntorno: TEntornoProveedorSesion);
begin
  inherited Create;
  if not Assigned(AEntorno.Servicio) then
    raise EArgumentNilException.Create('AEntorno.Servicio');
  if not Assigned(AEntorno.Datos) then
    raise EArgumentNilException.Create('AEntorno.Datos');
  FEntorno := AEntorno;
  FSwatch := TBitmap.Create;
end;

destructor TCoordinadorProveedorSesion.Destroy;
begin
  FreeAndNil(FSwatch);
  FreeAndNil(FMenuKits);
  inherited Destroy;
end;

function TCoordinadorProveedorSesion.GestorTallas: TGestorGridTallas;
begin
  Result := nil;
  if Assigned(FEntorno.ObtenerGestorTallas) then
    Result := FEntorno.ObtenerGestorTallas();
end;

procedure TCoordinadorProveedorSesion.Anotar(const ATexto: string);
begin
  if Assigned(FEntorno.Registrar) then
    FEntorno.Registrar(ATexto);
end;

function TCoordinadorProveedorSesion.CodigoProveedorCabecera: string;
begin
  Result := '';
  if FEntorno.Datos.unqryTablaG.Active and
     (not FEntorno.Datos.unqryTablaG.IsEmpty) then
    Result := Trim(FEntorno.Datos.unqryTablaG.FieldByName(
      'CODIGO_PRV_SES').AsString);
end;

function TCoordinadorProveedorSesion.EsFormatoDistribuido: Boolean;
begin
  Result := (not FEntorno.Datos.unqryTablaG.IsEmpty) and
            (FEntorno.Datos.unqryTablaG.FieldByName(
              'ESFORMATO_DISTRIBUIDO_SES').AsString = 'S');
end;

procedure TCoordinadorProveedorSesion.CargarBasicosColor;
begin
  FBasicosColor := FEntorno.Servicio.ConsultarCodigosBasicosActivos(
    cIdVaColor);
end;

procedure TCoordinadorProveedorSesion.BuscarProveedor;
var
  sCodigo: string;
begin
  if FEntorno.Datos.unqryTablaG.IsEmpty then
    MessageDlg(SErrorSesionElegirProveedorNoSeleccionada,
               mtInformation, [mbOk], 0)
  else if FEntorno.BusquedaVisual.EjecutarBusqueda(
    FEntorno.Conexion,
    'Busqueda de proveedores',
    'SELECT * FROM vi_proveedores ORDER BY RAZON_SOCIAL_PRV',
    'CODIGO_PRV_PRV',
    sCodigo,
    'frmMtoSesProvSearch') then
  begin
    if not (FEntorno.Datos.unqryTablaG.State in [dsInsert, dsEdit]) then
      FEntorno.Datos.unqryTablaG.Edit;
    FEntorno.Datos.unqryTablaG.FieldByName(
      'CODIGO_PRV_SES').AsString := sCodigo;
    ActualizarRotuloProveedor;
  end;
end;

procedure TCoordinadorProveedorSesion.ActualizarRotuloProveedor;
begin
  if Assigned(FEntorno.MostrarNombreProveedor) then
    FEntorno.MostrarNombreProveedor(
      TextoProveedorDocumento(
        FEntorno.Datos.unqryTablaG,
        FEntorno.Datos.unqryProveedores,
        'CODIGO_PRV_SES'));
end;

procedure TCoordinadorProveedorSesion.RecargarProveedorSesion;
var
  sProveedor: string;
begin
  sProveedor := CodigoProveedorCabecera;
  if (not SameText(sProveedor, FFichaCargada)) or
     ((sProveedor <> '') and
      (not FEntorno.Datos.unqryPrvFicha.Active)) then
  begin
    FFichaCargada := sProveedor;
    FEntorno.Datos.RecargarProveedorSesion(sProveedor);
  end;
end;

// El margen solo pisa cuando el proveedor tiene valor. El sistema de
// tallas del proveedor no tiene columna en la cabecera: fija el
// tallaje-defecto del documento que propone la siguiente linea nueva.
procedure TCoordinadorProveedorSesion.CopiarDefectosProveedor;
var
  Ficha: TDataSet;
  Cabecera: TDataSet;
begin
  Ficha := FEntorno.Datos.unqryPrvFicha;
  Cabecera := FEntorno.Datos.unqryTablaG;
  if Ficha.Active and (not Ficha.IsEmpty) then
  begin
    if Ficha.FieldByName('PORCENTAJE_MARGEN_PRV').AsFloat > 0 then
    begin
      if not (Cabecera.State in [dsInsert, dsEdit]) then
        Cabecera.Edit;
      Cabecera.FieldByName('PORCENTAJE_MARGEN_SES').AsFloat :=
        Ficha.FieldByName('PORCENTAJE_MARGEN_PRV').AsFloat;
    end;
    if (Ficha.FindField('ID_AC_TALLAS_PRV') <> nil) and
       (Ficha.FieldByName('ID_AC_TALLAS_PRV').AsInteger > 0) then
      FEntorno.Datos.TallajeDefectoActual :=
        Ficha.FieldByName('ID_AC_TALLAS_PRV').AsInteger;
    if (Ficha.FindField('CODIGO_FP_PRV') <> nil) and
       (Cabecera.FindField('FORMA_PAGO_SES') <> nil) and
       (Trim(Cabecera.FieldByName('FORMA_PAGO_SES').AsString) = '') and
       (Trim(Ficha.FieldByName('CODIGO_FP_PRV').AsString) <> '') then
    begin
      if not (Cabecera.State in [dsInsert, dsEdit]) then
        Cabecera.Edit;
      Cabecera.FieldByName('FORMA_PAGO_SES').AsString :=
        Trim(Ficha.FieldByName('CODIGO_FP_PRV').AsString);
    end;
    if (Ficha.FindField('ESVARIOS_TIPOS_IVA_PRV') <> nil) and
       (Cabecera.FindField('ESVARIOS_TIPOS_IVA_SES') <> nil) then
    begin
      if not (Cabecera.State in [dsInsert, dsEdit]) then
        Cabecera.Edit;
      Cabecera.FieldByName('ESVARIOS_TIPOS_IVA_SES').AsString :=
        UpperCase(Trim(Ficha.FieldByName(
          'ESVARIOS_TIPOS_IVA_PRV').AsString));
      if Cabecera.FieldByName(
         'ESVARIOS_TIPOS_IVA_SES').AsString = '' then
        Cabecera.FieldByName(
          'ESVARIOS_TIPOS_IVA_SES').AsString := 'N';
      if Assigned(FEntorno.RefrescarVisibilidadTipoIva) then
        FEntorno.RefrescarVisibilidadTipoIva();
    end;
    if (Ficha.FindField('ESIVA_EXENTO_INTRACOMUNITARIO_PRV') <> nil) and
       (Cabecera.FindField(
         'ESIVA_EXENTO_INTRACOMUNITARIO_SES') <> nil) then
    begin
      if not (Cabecera.State in [dsInsert, dsEdit]) then
        Cabecera.Edit;
      Cabecera.FieldByName(
        'ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString :=
        UpperCase(Trim(Ficha.FieldByName(
          'ESIVA_EXENTO_INTRACOMUNITARIO_PRV').AsString));
      if Cabecera.FieldByName(
         'ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString = '' then
        Cabecera.FieldByName(
          'ESIVA_EXENTO_INTRACOMUNITARIO_SES').AsString := 'N';
      FEntorno.Datos.RefrescarTotalesSesion;
    end;
  end;
end;

// Formato distribuido: el kit se aplica desde la matriz de almacenes.
// Formato simple: vuelca las cantidades sobre la linea con foco y
// repinta la fila igual que tras teclear a mano.
procedure TCoordinadorProveedorSesion.AplicarKitALineaActual(
  const ACodigoKit: string);
var
  sProveedor: string;
  sResumen: string;
  iLinea: Integer;
  iFila: Integer;
  Gestor: TGestorGridTallas;
begin
  sProveedor := CodigoProveedorCabecera;
  Gestor := GestorTallas;
  if EsFormatoDistribuido then
  begin
    if ValidarKitSobreLineaActual(
      FEntorno.Datos,
      FEntorno.Servicio,
      sProveedor,
      ACodigoKit,
      sResumen) then
    begin
      Anotar(Format(
        'AplicarKit %s -> distribuidor (formato distribuido)',
        [ACodigoKit]));
      if Assigned(FEntorno.AbrirDistribuidor) then
        FEntorno.AbrirDistribuidor(ACodigoKit);
    end
    else
      MessageDlg(sResumen, mtWarning, [mbOk], 0);
  end
  else if AplicarKitProveedorALinea(
    FEntorno.Datos,
    Gestor,
    FEntorno.Servicio,
    sProveedor,
    ACodigoKit,
    sResumen) then
  begin
    iLinea := FEntorno.Datos.unqrySesionLin.FieldByName(
      'LINEA_SESLIN').AsInteger;
    if Assigned(Gestor) then
    begin
      Gestor.RefrescarTotalesLineaActual;
      iFila := FEntorno.Vista.Controller.FocusedRecordIndex;
      if iFila >= 0 then
        Gestor.CargarCantidadesUnaLinea(iFila, iLinea);
    end;
    FEntorno.Datos.RefrescarTotalesSesion;
    Anotar(Format('AplicarKit %s sobre linea %d',
                  [ACodigoKit, iLinea]));
    // Aviso solo si alguna talla del kit no caso con el sistema.
    if sResumen <> '' then
      MessageDlg(sResumen, mtInformation, [mbOk], 0);
  end
  else
    MessageDlg(sResumen, mtWarning, [mbOk], 0);
end;

procedure TCoordinadorProveedorSesion.KitDelMenuElegido(ASender: TObject);
begin
  if ASender is TMenuItem then
  begin
    if (TMenuItem(ASender).Tag >= 0) and
       (TMenuItem(ASender).Tag <= High(FCodigosKits)) then
      AplicarKitALineaActual(FCodigosKits[TMenuItem(ASender).Tag]);
  end;
end;

procedure TCoordinadorProveedorSesion.ConstruirMenuKits;
var
  Item: TMenuItem;
  Kits: TDataSet;
begin
  // Sin propietario VCL: lo libera el destructor de este colaborador,
  // que corre antes de que el formulario destruya sus componentes.
  if FMenuKits = nil then
    FMenuKits := TPopupMenu.Create(nil);
  FMenuKits.Items.Clear;
  SetLength(FCodigosKits, 0);
  Kits := FEntorno.Datos.unqryPrvKits;
  Kits.DisableControls;
  try
    Kits.First;
    while not Kits.Eof do
    begin
      Item := TMenuItem.Create(FMenuKits);
      Item.Caption := StringReplace(
        Kits.FieldByName('CODIGO_PRVKIT').AsString + ' - ' +
        Kits.FieldByName('NOMBRE_PRVKIT').AsString,
        '&', '&&', [rfReplaceAll]);
      Item.Tag := Length(FCodigosKits);
      Item.OnClick := KitDelMenuElegido;
      FMenuKits.Items.Add(Item);
      SetLength(FCodigosKits, Length(FCodigosKits) + 1);
      FCodigosKits[High(FCodigosKits)] :=
        Kits.FieldByName('CODIGO_PRVKIT').AsString;
      Kits.Next;
    end;
    Kits.First;
  finally
    Kits.EnableControls;
  end;
end;

function TCoordinadorProveedorSesion.MostrarMenuKits: Boolean;
var
  Punto: TPoint;
begin
  Result := False;
  if FEntorno.Datos.unqrySesionLin.IsEmpty then
    MessageDlg(SErrorLineaArticuloSesionNoSeleccionada,
               mtInformation, [mbOk], 0)
  else if (not FEntorno.Datos.unqryPrvKits.Active) or
          FEntorno.Datos.unqryPrvKits.IsEmpty then
    MessageDlg(SErrorProveedorSesionSinKits,
               mtInformation, [mbOk], 0)
  else
  begin
    ConstruirMenuKits;
    Punto := FEntorno.BotonKits.ClientToScreen(
      Point(0, FEntorno.BotonKits.Height));
    FMenuKits.Popup(Punto.X, Punto.Y);
    Result := True;
  end;
end;

procedure TCoordinadorProveedorSesion.ElegirColorBasico(
  ASender: TObject);
var
  sActual: string;
  sNuevo: string;
  Lineas: TDataSet;
  Editor: TWinControl;
  Punto: TPoint;
  iAncho: Integer;
begin
  Lineas := FEntorno.Datos.unqrySesionLin;
  if Length(FBasicosColor) = 0 then
    MessageDlg(SErrorColoresBasicosSesionNoDisponibles,
               mtInformation, [mbOk], 0)
  else if not Lineas.IsEmpty then
  begin
    sActual := Lineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;
    Punto.X := -1;
    Punto.Y := -1;
    iAncho := cAnchoPaleta;
    if ASender is TWinControl then
    begin
      Editor := TWinControl(ASender);
      Punto := Editor.ClientToScreen(Point(0, Editor.Height));
      iAncho := Editor.Width;
    end;
    if SeleccionarAvConPaleta(
      FEntorno.Conexion,
      cIdVaColor,
      FBasicosColor,
      sActual,
      sNuevo,
      Punto.X,
      Punto.Y,
      iAncho) then
    begin
      if not (Lineas.State in [dsEdit, dsInsert]) then
        Lineas.Edit;
      Lineas.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString := sNuevo;
      if ASender is TcxCustomEdit then
        TcxCustomEdit(ASender).EditValue := sNuevo;
    end;
  end;
end;

procedure TCoordinadorProveedorSesion.PrepararEditorColorBasico(
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
var
  BotonEdit: TcxButtonEdit;
  Boton: TcxEditButton;
  sActual: string;
  Info: TInfoBasico;
begin
  if (AItem = FEntorno.ColumnaColorBasico) and
     (AEdit is TcxButtonEdit) then
  begin
    BotonEdit := TcxButtonEdit(AEdit);
    if BotonEdit.Properties.Buttons.Count > 0 then
    begin
      Boton := BotonEdit.Properties.Buttons[0];
      sActual := '';
      if FEntorno.Datos.unqrySesionLin.Active and
         (not FEntorno.Datos.unqrySesionLin.IsEmpty) then
        sActual := FEntorno.Datos.unqrySesionLin.FieldByName(
          'CODIGO_ATB_COLOR_SESLIN').AsString;
      Info := Default(TInfoBasico);
      if Trim(sActual) <> '' then
        ObtenerInfoBasico(FEntorno.Conexion, cIdVaColor, sActual, Info);
      if Info.EsValido and
         PintarSwatchEnBitmap(FSwatch, Info, cLadoSwatch) then
      begin
        Boton.Glyph.Assign(FSwatch);
        Boton.Kind := bkGlyph;
      end
      else
        Boton.Kind := bkEllipsis;
    end;
  end;
end;

function TCoordinadorProveedorSesion.DibujarCeldaColor(
  ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
var
  sActual: string;
  Info: TInfoBasico;
begin
  Result := False;
  if (AViewInfo.GridRecord <> nil) and
     (AViewInfo.Item = FEntorno.ColumnaColorBasico) then
  begin
    sActual := VarToStr(
      AViewInfo.GridRecord.Values[AViewInfo.Item.Index]);
    if Trim(sActual) <> '' then
    begin
      Info := Default(TInfoBasico);
      if ObtenerInfoBasico(FEntorno.Conexion, cIdVaColor, sActual, Info)
         and Info.EsValido then
        Result := PintarCeldaConCuadradoColor(ACanvas, AViewInfo, Info);
    end;
  end;
end;

end.
