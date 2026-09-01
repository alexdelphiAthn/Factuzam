{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionModelo                        }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Busqueda incremental de modelos del proveedor sobre la columna            }
{    "Modelo prov." y reutilizacion de articulos ya existentes al teclear      }
{    familia, codigo o referencia. El estado del debounce y de la              }
{    resolucion diferida vive en inLibComprasSesionesPresentacion; aqui        }
{    solo queda el efecto sobre el grid y los datasets.                        }
{                                                                              }
{    Recibe un entorno explicito con las capacidades que usa. No conoce el     }
{    formulario de sesiones ni ningun contexto general de repositorios.        }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionModelo;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  Data.DB,
  Uni,
  Vcl.Controls,
  cxEdit,
  cxDropDownEdit,
  cxEditRepositoryItems,
  cxDBExtLookupComboBox,
  cxGrid,
  cxGridCustomTableView,
  cxGridTableView,
  cxGridDBTableView,
  inLibComprasSesiones,
  inLibComprasSesionesIntf,
  inLibComprasSesionesPresentacion;

type
  // Peticion de copia completa de la linea origen detectada al repetir
  // un modelo. La atiende el coordinador de copia de lineas; aqui solo
  // se conoce como una capacidad inyectada.
  TSolicitarCopiaLineaSesion = reference to procedure(
    const AModelo: string;
    ALineaOrigen: Integer;
    const AColorTexto: string;
    const AColorBasico: string;
    AMargen: Double);

  TOrigenGeneracionCodigoArticuloSesion = (
    ogcaFamilia,
    ogcaModelo);

  TGenerarCodigoArticuloSesion = reference to function(
    AOrigen: TOrigenGeneracionCodigoArticuloSesion): Boolean;

  TEntornoModeloProveedorSesion = record
    Propietario: TComponent;
    Conexion: TUniConnection;
    Servicio: TServicioComprasSesiones;
    Usuario: string;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Vista: TcxGridDBTableView;
    ColumnaModelo: TcxGridDBColumn;
    RefrescarTallas: TProc;
    FijarTallajeDefecto: TProc<Integer>;
    SolicitarCopiaLinea: TSolicitarCopiaLineaSesion;
    GenerarCodigoArticulo: TGenerarCodigoArticuloSesion;
    RegistrarAviso: TProc<string>;
  end;

  TBuscadorModeloProveedorSesion = class
  private
    FEntorno: TEntornoModeloProveedorSesion;
    FNucleo: TNucleoBusquedaModeloSesion;
    FConsulta: TUniQuery;
    FFuente: TDataSource;
    FRepositorioVistas: TcxGridViewRepository;
    FVistaModelos: TcxGridDBTableView;
    FColumnaReferencia: TcxGridDBColumn;
    FColumnaCodigoArticulo: TcxGridDBColumn;
    FRepositorioEdicion: TcxEditRepository;
    FCombo: TcxEditRepositoryExtLookupComboBoxItem;
    procedure ConstruirConsulta;
    procedure ConstruirVistaModelos;
    procedure AnadirColumnaModelos(const ACaption, ACampo: string;
      AAncho: Integer);
    procedure ConstruirCombo;
    procedure ComboCambiado(ASender: TObject);
    procedure ComboCerrado(ASender: TObject);
    procedure ComboValidado(ASender: TObject;
      var ADisplayValue: Variant; var AErrorText: TCaption;
      var AError: Boolean);
    procedure ObtenerPropiedadesCelda(ASender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AProperties: TcxCustomEditProperties);
    procedure AbrirDesplegableFiltrado;
    procedure ResolverPendiente;
    procedure GenerarCodigoPorModelo(const AModelo: string);
    procedure AplicarReferenciaResuelta(const AModelo: string;
      const ADuplicado: TResolverDuplicadoSesion);
    procedure CerrarEditorEnCurso;
    procedure RefrescarColumnasTallas;
    function ProveedorCabecera: string;
    function HayLineaEditable: Boolean;
  public
    constructor Create(const AEntorno: TEntornoModeloProveedorSesion);
    destructor Destroy; override;
    // (Re)abre la lista del desplegable acotada al proveedor de la
    // cabecera. Solo relanza si el proveedor cambia.
    procedure RecargarModelos;
    // Engancha el debounce al editor in-place cuando el editor que abre
    // el grid es el desplegable de busqueda incremental.
    function EngancharEditor(AItem: TcxCustomGridTableItem;
      AEdit: TcxCustomEdit): Boolean;
    // Reutiliza otra linea de la MISMA sesion. True si la linea actual
    // ha quedado marcada REUSAR.
    function AplicarDuplicadoDeSesion(const AModelo: string;
      const ACodigoArticulo: string): Boolean;
    procedure ResolverFamiliaTecleada(ASender: TObject);
    procedure ResolverCodigoTecleado(ASender: TObject);
    procedure ConfirmarReferenciaTecleada(const AReferencia: string);
    procedure ExpandirCodigoFamiliaActiva(const ACodigoFamilia: string;
      const ANombreFamilia: string = '');
    // Abre el picker jerarquico de familias y expande la eleccion.
    procedure ElegirFamiliaConModal;
    procedure ProponerPrecioVenta;
  end;

implementation

uses
  inLibComprasSesionesPresentacionIntf,
  inLibMsgCompras,
  inMtoComprasSesionesPresentacionPlanificador,
  inMtoModalSelFamilia,
  UniDataComprasSesionesPresentacionRepositorio;

const
  // Debounce de apertura del desplegable y resolucion inmediata pero
  // fuera del editor in-place (no se puede tocar el dataset mientras el
  // editor se esta cerrando).
  cIntervaloDebounceMs = 350;
  cIntervaloResolucionMs = 1;

constructor TBuscadorModeloProveedorSesion.Create(
  const AEntorno: TEntornoModeloProveedorSesion);
var
  PlanificadorBusqueda: IPlanificadorDiferido;
  PlanificadorResolucion: IPlanificadorDiferido;
begin
  inherited Create;
  if not Assigned(AEntorno.Servicio) then
    raise EArgumentNilException.Create('AEntorno.Servicio');
  if not Assigned(AEntorno.Vista) then
    raise EArgumentNilException.Create('AEntorno.Vista');
  if not Assigned(AEntorno.GenerarCodigoArticulo) then
    raise EArgumentNilException.Create('AEntorno.GenerarCodigoArticulo');
  FEntorno := AEntorno;
  PlanificadorBusqueda := TPlanificadorDiferidoTimer.Create(
    cIntervaloDebounceMs,
    procedure
    begin
      AbrirDesplegableFiltrado;
    end);
  PlanificadorResolucion := TPlanificadorDiferidoTimer.Create(
    cIntervaloResolucionMs,
    procedure
    begin
      ResolverPendiente;
    end);
  FNucleo := TNucleoBusquedaModeloSesion.Create(
    PlanificadorBusqueda,
    PlanificadorResolucion);
  ConstruirConsulta;
  ConstruirVistaModelos;
  ConstruirCombo;
  if Assigned(FEntorno.ColumnaModelo) then
    FEntorno.ColumnaModelo.OnGetProperties := ObtenerPropiedadesCelda;
end;

destructor TBuscadorModeloProveedorSesion.Destroy;
begin
  if Assigned(FEntorno.ColumnaModelo) then
    FEntorno.ColumnaModelo.OnGetProperties := nil;
  FreeAndNil(FNucleo);
  FreeAndNil(FRepositorioEdicion);
  FreeAndNil(FRepositorioVistas);
  FreeAndNil(FFuente);
  if Assigned(FConsulta) then
  begin
    if FConsulta.Active then
      FConsulta.Close;
    FConsulta.Connection := nil;
  end;
  FreeAndNil(FConsulta);
  inherited Destroy;
end;

// Un modelo por fila: descripcion, sistema de tallas, colores ya dados
// de alta y ultimo precio de compra. El filtrado "empieza por" mientras
// se teclea lo hace IncrementalFiltering en cliente; :prv lo fija
// RecargarModelos.
procedure TBuscadorModeloProveedorSesion.ConstruirConsulta;
begin
  FConsulta := CrearConsultaModelosProveedorUniDAC(FEntorno.Conexion);
  FFuente := TDataSource.Create(nil);
  FFuente.DataSet := FConsulta;
end;

procedure TBuscadorModeloProveedorSesion.AnadirColumnaModelos(
  const ACaption, ACampo: string; AAncho: Integer);
var
  Columna: TcxGridDBColumn;
begin
  Columna := FVistaModelos.CreateColumn;
  Columna.Caption := ACaption;
  Columna.DataBinding.FieldName := ACampo;
  Columna.Width := AAncho;
end;

// View del desplegable, en su propio repositorio (no en pantalla).
procedure TBuscadorModeloProveedorSesion.ConstruirVistaModelos;
begin
  FRepositorioVistas := TcxGridViewRepository.Create(nil);
  FVistaModelos := FRepositorioVistas.CreateItem(TcxGridDBTableView)
                     as TcxGridDBTableView;
  FVistaModelos.DataController.DataSource := FFuente;
  FVistaModelos.DataController.KeyFieldNames := 'REFPRV';
  FVistaModelos.OptionsView.GroupByBox := False;
  FVistaModelos.OptionsSelection.CellSelect := False;
  FVistaModelos.OptionsBehavior.IncSearch := False;
  FColumnaReferencia := FVistaModelos.CreateColumn;
  FColumnaReferencia.Caption := SCaptionModeloCompra;
  FColumnaReferencia.DataBinding.FieldName := 'REFPRV';
  FColumnaReferencia.Width := 130;
  FColumnaCodigoArticulo := FVistaModelos.CreateColumn;
  FColumnaCodigoArticulo.Caption := SCaptionCodigoCompra;
  FColumnaCodigoArticulo.DataBinding.FieldName := 'CODART';
  FColumnaCodigoArticulo.Width := 110;
  AnadirColumnaModelos('Descripcion', 'DESCRIPCION', 220);
  AnadirColumnaModelos('Tallas', 'SISTEMA', 110);
  AnadirColumnaModelos('Colores', 'COLORES', 180);
  AnadirColumnaModelos('Ult. compra', 'PCOMPRA', 80);
end;

// Item de edicion ExtLookupComboBox que usa ese view. DropDownListStyle
// lsEditList permite teclear modelos nuevos; OnValidate es el unico
// evento fiable cuando el modelo se confirma con Tab/Enter sin pasar
// por el desplegable.
procedure TBuscadorModeloProveedorSesion.ConstruirCombo;
begin
  FRepositorioEdicion := TcxEditRepository.Create(nil);
  FCombo := FRepositorioEdicion.CreateItem(
              TcxEditRepositoryExtLookupComboBoxItem)
              as TcxEditRepositoryExtLookupComboBoxItem;
  FCombo.Properties.View := FVistaModelos;
  FCombo.Properties.KeyFieldNames := 'REFPRV';
  FCombo.Properties.ListFieldItem := FColumnaReferencia;
  FCombo.Properties.DropDownListStyle := lsEditList;
  FCombo.Properties.IncrementalFiltering := True;
  FCombo.Properties.DropDownRows := 15;
  FCombo.Properties.DropDownAutoWidth := True;
  // No abrir el desplegable en cada tecla: lo abre el debounce ya filtrado.
  FCombo.Properties.ImmediateDropDownWhenKeyPressed := False;
  FCombo.Properties.OnCloseUp := ComboCerrado;
  FCombo.Properties.OnValidate := ComboValidado;
end;

procedure TBuscadorModeloProveedorSesion.RecargarModelos;
var
  sProveedor: string;
begin
  if Assigned(FConsulta) then
  begin
    sProveedor := ProveedorCabecera;
    if FNucleo.DebeRecargarLista(sProveedor, FConsulta.Active) then
    begin
      FNucleo.MarcarListaCargada(sProveedor);
      if FConsulta.Active then
        FConsulta.Close;
      FConsulta.ParamByName('prv').AsString := sProveedor;
      FConsulta.Open;
    end;
  end;
end;

// Editor por celda: celda vacia y enfocada -> ExtLookupComboBox; en otro
// caso el editor de texto por defecto de la columna, que confirma el
// valor mediante OnValidate.
procedure TBuscadorModeloProveedorSesion.ObtenerPropiedadesCelda(
  ASender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
var
  vValor: Variant;
  bVacia: Boolean;
  bEnfocada: Boolean;
begin
  if (ARecord <> nil) and (FCombo <> nil) then
  begin
    vValor := ARecord.Values[ASender.Index];
    bVacia := VarIsNull(vValor) or (Trim(VarToStr(vValor)) = '');
    bEnfocada := (FEntorno.Vista.Controller.FocusedRecord = ARecord) and
                 (FEntorno.Vista.Controller.FocusedItem = ASender);
    if bVacia and bEnfocada then
      AProperties := FCombo.Properties;
  end;
end;

function TBuscadorModeloProveedorSesion.EngancharEditor(
  AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit): Boolean;
begin
  Result := (AItem = FEntorno.ColumnaModelo) and
            (AEdit is TcxExtLookupComboBox);
  if Result then
    TcxExtLookupComboBox(AEdit).Properties.OnChange := ComboCambiado;
end;

procedure TBuscadorModeloProveedorSesion.ComboCambiado(ASender: TObject);
begin
  FNucleo.RegistrarTecleo;
end;

// Al saltar el debounce abre el desplegable ya filtrado por lo tecleado.
procedure TBuscadorModeloProveedorSesion.AbrirDesplegableFiltrado;
var
  Editor: TcxCustomEdit;
  Combo: TcxExtLookupComboBox;
begin
  if FEntorno.Vista.Controller.EditingController.IsEditing then
  begin
    Editor := FEntorno.Vista.Controller.EditingController.Edit;
    if Editor is TcxExtLookupComboBox then
    begin
      Combo := TcxExtLookupComboBox(Editor);
      if (Trim(VarToStr(Combo.EditingValue)) <> '') and
         (not Combo.DroppedDown) then
        Combo.DroppedDown := True;
    end;
  end;
end;

// Al cerrar el desplegable con una eleccion guardamos el modelo y el
// codigo de articulo de la fila elegida; la resolucion se difiere para
// no tocar el dataset mientras se cierra el editor in-place.
procedure TBuscadorModeloProveedorSesion.ComboCerrado(ASender: TObject);
var
  Fila: TcxCustomGridRecord;
  sModelo: string;
  sCodigoArticulo: string;
begin
  if ASender is TcxCustomEdit then
  begin
    sModelo := VarToStr(TcxCustomEdit(ASender).EditValue);
    sCodigoArticulo := '';
    if (FVistaModelos <> nil) and (FColumnaCodigoArticulo <> nil) then
    begin
      Fila := FVistaModelos.Controller.FocusedRecord;
      if Fila <> nil then
        sCodigoArticulo := VarToStr(
          Fila.Values[FColumnaCodigoArticulo.Index]);
    end;
    FNucleo.RegistrarSeleccion(sModelo, sCodigoArticulo);
  end;
end;

// Confirmacion del valor del combo (Tab / Enter / clic fuera). Cubre el
// modelo tecleado a mano que no paso por el desplegable, p. ej. uno que
// solo existe en lineas de ESTA sesion, aun sin materializar.
procedure TBuscadorModeloProveedorSesion.ComboValidado(ASender: TObject;
  var ADisplayValue: Variant; var AErrorText: TCaption;
  var AError: Boolean);
begin
  AError := False;
  AErrorText := '';
  ConfirmarReferenciaTecleada(VarToStr(ADisplayValue));
end;

function TBuscadorModeloProveedorSesion.ProveedorCabecera: string;
begin
  Result := '';
  if Assigned(FEntorno.Cabecera) and FEntorno.Cabecera.Active and
     (not FEntorno.Cabecera.IsEmpty) then
    Result := Trim(FEntorno.Cabecera.FieldByName(
      'CODIGO_PRV_SES').AsString);
end;

function TBuscadorModeloProveedorSesion.HayLineaEditable: Boolean;
begin
  Result := Assigned(FEntorno.Cabecera) and
            Assigned(FEntorno.Lineas) and
            (not FEntorno.Cabecera.IsEmpty) and
            (not FEntorno.Lineas.IsEmpty);
end;

procedure TBuscadorModeloProveedorSesion.RefrescarColumnasTallas;
begin
  if Assigned(FEntorno.RefrescarTallas) then
    FEntorno.RefrescarTallas();
end;

// Cierra el editor in-place para que la celda muestre el valor resuelto.
// El EInvalidOperation del editor es ruido conocido: se registra y se
// sigue, nunca se convierte el fallo en exito silencioso.
procedure TBuscadorModeloProveedorSesion.CerrarEditorEnCurso;
begin
  if FEntorno.Vista.Controller.EditingController.IsEditing then
    try
      FEntorno.Vista.Controller.EditingController.HideEdit(True);
    except
      on E: EInvalidOperation do
        if Assigned(FEntorno.RegistrarAviso) then
          FEntorno.RegistrarAviso(
            'ComprasSesiones.ResolverModelo: HideEdit ignorado: ' +
            E.Message);
    end;
end;

function TBuscadorModeloProveedorSesion.AplicarDuplicadoDeSesion(
  const AModelo: string;
  const ACodigoArticulo: string): Boolean;
var
  rDuplicado: TResolverDuplicadoSesion;
  iLinea: Integer;
begin
  Result := False;
  if HayLineaEditable then
  begin
    iLinea := FEntorno.Lineas.FieldByName('LINEA_SESLIN').AsInteger;
    rDuplicado := FEntorno.Servicio.ResolverDuplicadoIntraSesion(
      Trim(FEntorno.Cabecera.FieldByName('SERIE_SES').AsString),
      Trim(FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString),
      iLinea,
      AModelo,
      ACodigoArticulo);
    if rDuplicado.Encontrado then
    begin
      if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
        FEntorno.Lineas.Edit;
      FEntorno.Servicio.AplicarDuplicadoEnLinea(rDuplicado);
      if (rDuplicado.IdAcPivot > 0) and
         Assigned(FEntorno.FijarTallajeDefecto) then
        FEntorno.FijarTallajeDefecto(rDuplicado.IdAcPivot);
      RefrescarColumnasTallas;
      // Copia completa opcional (otro color / otro rango de precios):
      // la decide el usuario en un modal que no puede abrirse aqui,
      // seguimos dentro del editor in-place.
      if (rDuplicado.LineaOrigen > 0) and
         Assigned(FEntorno.SolicitarCopiaLinea) then
        FEntorno.SolicitarCopiaLinea(
          AModelo,
          rDuplicado.LineaOrigen,
          rDuplicado.ColorTexto,
          rDuplicado.CodigoAtbColor,
          rDuplicado.MargenPorcentaje);
      Result := True;
    end;
  end;
end;

procedure TBuscadorModeloProveedorSesion.AplicarReferenciaResuelta(
  const AModelo: string;
  const ADuplicado: TResolverDuplicadoSesion);
begin
  if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
    FEntorno.Lineas.Edit;
  // El modelo tecleado se conserva como REF de la linea: la rama REF de
  // la resolucion no la toca.
  FEntorno.Lineas.FieldByName('REF_PRV_SESLIN').AsString := AModelo;
  FEntorno.Servicio.AplicarDuplicadoEnLinea(ADuplicado);
  RefrescarColumnasTallas;
end;

procedure TBuscadorModeloProveedorSesion.GenerarCodigoPorModelo(
  const AModelo: string);
begin
  if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
    FEntorno.Lineas.Edit;
  FEntorno.Lineas.FieldByName(
    'REF_PRV_SESLIN').AsString := AModelo;
  FEntorno.GenerarCodigoArticulo(ogcaModelo);
end;

procedure TBuscadorModeloProveedorSesion.ResolverPendiente;
var
  sModelo: string;
  sCodigoArticulo: string;
  sProveedor: string;
  bResuelto: Boolean;
  rDuplicado: TResolverDuplicadoSesion;
begin
  bResuelto := False;
  if FNucleo.TomarPendiente(sModelo, sCodigoArticulo) and
     HayLineaEditable then
  begin
    if Trim(sModelo) = '' then
    begin
      GenerarCodigoPorModelo('');
      bResuelto := True;
    end
    else
    begin
      sProveedor := ProveedorCabecera;
      if sProveedor <> '' then
        bResuelto := AplicarDuplicadoDeSesion(
          sModelo, sCodigoArticulo);
      if (sProveedor <> '') and (not bResuelto) then
      begin
        rDuplicado := FEntorno.Servicio.ResolverDuplicado(
          sModelo,
          sProveedor,
          True,
          sCodigoArticulo);
        if rDuplicado.Encontrado then
        begin
          AplicarReferenciaResuelta(sModelo, rDuplicado);
          bResuelto := True;
        end;
      end;
      if (sProveedor <> '') and (not bResuelto) then
      begin
        GenerarCodigoPorModelo(sModelo);
        bResuelto := True;
      end;
    end;
  end;
  if bResuelto then
    CerrarEditorEnCurso;
end;

// 1. Reusar datos de otra linea del mismo documento. 2. Reusar un
// articulo existente. 3. Generar el codigo con la formula configurada.
procedure TBuscadorModeloProveedorSesion.ResolverFamiliaTecleada(
  ASender: TObject);
var
  sFamilia: string;
  bPendiente: Boolean;
  rDuplicado: TResolverDuplicadoSesion;
begin
  sFamilia := '';
  if (ASender is TcxCustomEdit) and Assigned(FEntorno.Lineas) then
  begin
    TcxCustomEdit(ASender).PostEditValue;
    sFamilia := Trim(FEntorno.Lineas.FieldByName(
      'CODIGO_FAM_SESLIN').AsString);
  end;
  bPendiente := sFamilia <> '';
  if (sFamilia = '') and Assigned(FEntorno.Lineas) and
     (not FEntorno.Lineas.IsEmpty) then
    FEntorno.GenerarCodigoArticulo(ogcaFamilia);
  if bPendiente and AplicarDuplicadoDeSesion('', sFamilia) then
    bPendiente := False;
  if bPendiente then
  begin
    rDuplicado := FEntorno.Servicio.ResolverDuplicado(
      sFamilia,
      ProveedorCabecera);
    if rDuplicado.Encontrado then
    begin
      FEntorno.Servicio.AplicarDuplicadoEnLinea(rDuplicado);
      RefrescarColumnasTallas;
      bPendiente := False;
    end;
  end;
  if bPendiente then
    ExpandirCodigoFamiliaActiva(sFamilia);
end;

// El codigo tecleado se conserva como manual salvo cuando coincide con
// una familia. En ese caso se genera mediante la formula configurada.
procedure TBuscadorModeloProveedorSesion.ResolverCodigoTecleado(
  ASender: TObject);
var
  Editor: TcxCustomEdit;
  sTecleado: string;
  sNombre: string;
  bPendiente: Boolean;
begin
  Editor := nil;
  sTecleado := '';
  if (ASender is TcxCustomEdit) and Assigned(FEntorno.Lineas) and
     (not FEntorno.Lineas.IsEmpty) then
  begin
    Editor := TcxCustomEdit(ASender);
    Editor.PostEditValue;
    sTecleado := Trim(FEntorno.Lineas.FieldByName(
      'CODIGO_ART_TENTATIVO_SESLIN').AsString);
  end;
  bPendiente := sTecleado <> '';
  if bPendiente and AplicarDuplicadoDeSesion('', sTecleado) then
    bPendiente := False;
  if bPendiente then
  begin
    sNombre := FEntorno.Servicio.ObtenerNombreFamilia(sTecleado);
    if sNombre = '' then
      bPendiente := False;
  end;
  if bPendiente then
  begin
    if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
      FEntorno.Lineas.Edit;
    FEntorno.Lineas.FieldByName('CODIGO_FAM_SESLIN').AsString :=
      sTecleado;
    FEntorno.GenerarCodigoArticulo(ogcaFamilia);
    Editor.EditValue := FEntorno.Lineas.FieldByName(
      'CODIGO_ART_TENTATIVO_SESLIN').AsString;
    if FEntorno.Lineas.FieldByName('DESCRIPCION_SESLIN').AsString = '' then
      FEntorno.Lineas.FieldByName('DESCRIPCION_SESLIN').AsString :=
        sNombre;
  end;
end;

procedure TBuscadorModeloProveedorSesion.ConfirmarReferenciaTecleada(
  const AReferencia: string);
begin
  FNucleo.RegistrarConfirmacion(Trim(AReferencia));
end;

// Helper compartido por F3 y por el tecleo en Familia: guarda la familia,
// genera el codigo con la formula y prerellena la descripcion.
procedure TBuscadorModeloProveedorSesion.ExpandirCodigoFamiliaActiva(
  const ACodigoFamilia: string;
  const ANombreFamilia: string);
var
  sNombre: string;
begin
  if (Trim(ACodigoFamilia) <> '') and Assigned(FEntorno.Lineas) and
     (not FEntorno.Lineas.IsEmpty) then
  begin
    if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
      FEntorno.Lineas.Edit;
    FEntorno.Lineas.FieldByName('CODIGO_FAM_SESLIN').AsString :=
      ACodigoFamilia;
    FEntorno.GenerarCodigoArticulo(ogcaFamilia);
    if FEntorno.Lineas.FieldByName('DESCRIPCION_SESLIN').AsString = '' then
    begin
      sNombre := ANombreFamilia;
      if sNombre = '' then
        sNombre := FEntorno.Servicio.ObtenerNombreFamilia(ACodigoFamilia);
      if sNombre <> '' then
        FEntorno.Lineas.FieldByName('DESCRIPCION_SESLIN').AsString :=
          sNombre;
    end;
  end;
end;

procedure TBuscadorModeloProveedorSesion.ElegirFamiliaConModal;
var
  Modal: TfrmModalSelFamilia;
begin
  Modal := TfrmModalSelFamilia.Create(FEntorno.Propietario);
  try
    if Modal.ShowModal = mrOk then
      ExpandirCodigoFamiliaActiva(Modal.CodigoFamilia, Modal.NombreFamilia);
  finally
    FreeAndNil(Modal);
  end;
end;

procedure TBuscadorModeloProveedorSesion.ProponerPrecioVenta;
var
  rCoste: Double;
  rMargen: Double;
  rMultiplo: Double;
  rAjuste: Double;
begin
  if HayLineaEditable then
  begin
    rCoste := FEntorno.Lineas.FieldByName(
      'PRECIO_COMPRA_SESLIN').AsFloat;
    rMargen := FEntorno.Cabecera.FieldByName(
      'PORCENTAJE_MARGEN_SES').AsFloat;
    rMultiplo := FEntorno.Cabecera.FieldByName(
      'MULTIPLO_REDONDEO_SES').AsFloat;
    rAjuste := FEntorno.Cabecera.FieldByName(
      'AJUSTE_FINAL_SES').AsFloat;
    if not (FEntorno.Lineas.State in [dsEdit, dsInsert]) then
      FEntorno.Lineas.Edit;
    FEntorno.Lineas.FieldByName('PRECIO_VENTA_SESLIN').AsFloat :=
      CalcularPrecioVenta(rCoste, rMargen, rMultiplo, rAjuste);
  end;
end;

end.
