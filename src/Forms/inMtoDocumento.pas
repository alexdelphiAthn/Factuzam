{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDocumento                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ancestro común para mantenimientos de documentos de compra y venta.       }
{******************************************************************************}
unit inMtoDocumento;

interface

uses
  Data.DB, Vcl.ExtCtrls, cxButtons, cxLabel, cxGridDBTableView, cxPC,
  inMtoGen, inLibDocumentoIntf, inLibValidacionDocumento,
  inLibVentanaEmbebidaIntf, inLibPrecargaComprasIntf,
  inLibPrecargaCompras;

type
  TfrmMtoDocumento = class(TfrmMtoGen, IMantenimientoConPrecarga)
  private
    FConfiguracionDocumento: TConfiguracionDocumento;
    FEstrategiaDocumento: IEstrategiaDocumento;
    FVistaLineasDocumento: TcxGridDBTableView;
    FRepositorioPrecarga: IRepositorioPrecargaCompras;
    FPrecargaCompras: TPrecargaCompras;
    FPanelPrecarga: TPanel;
    FBotonPrecarga: TcxButton;
    FBotonGuardarPrecarga: TcxButton;
    FResumenPrecarga: TcxLabel;
    FPrecargaAceptada: Boolean;
    FPerfilPrecargaLeido: Boolean;
    FRolPrecarga: TRolAperturaMantenimiento;
    FConsultaDesdePerfil: Boolean;
    FRolListaPrecarga: TRolAperturaMantenimiento;
    FRetornoListaPendiente: Boolean;
    FRestaurandoLista: Boolean;
    FEventoRetornoInstalado: Boolean;
    FEventoCambioPaginaAnterior: TcxPageChangingEvent;
    function UsaPrecargaCompras: Boolean;
    function RestriccionUsuarioDocumento: string;
    procedure AsegurarPrecargaCompras;
    procedure CrearPanelPrecarga;
    procedure ActualizarPanelPrecarga;
    procedure CambiarSeriesPrecarga;
    procedure PrecargaSeriesClick(Sender: TObject);
    procedure LeerPerfilPrecarga;
    function HayConsultaPrincipalEnPerfil: Boolean;
    procedure GuardarPrecarga;
    procedure GuardarPrecargaClick(Sender: TObject);
    procedure ValidarCambioConsultaPrecarga;
    procedure PrepararRetornoDeBusqueda(const ABusq: string);
    procedure InstalarEventoRetornoLista;
    function DebeRestaurarLista(ANuevaPagina: TcxTabSheet): Boolean;
    procedure RetornarAListaNormal;
    procedure PaginaPrecargaCambiando(Sender: TObject;
      NewPage: TcxTabSheet; var AllowChange: Boolean);
    function SeleccionarSeriesPrecarga(
      const ACatalogo: TSeriesPrecargaCompra;
      const ASeleccion: TArray<string>;
      out ANuevaSeleccion: TArray<string>): Boolean;
  protected
    procedure InicializarDocumento(
      const AConfiguracion: TConfiguracionDocumento);
    function ConfiguracionPersistenciaDocumento(
      const AMensajeCabeceraNoDisponible: string
    ): TConfiguracionDocumento;
    function ConfiguracionTallasDocumento:
      TConfiguracionDocumento;
    procedure AsignarVistaLineasDocumento(
      AVista: TcxGridDBTableView);
    procedure RestaurarListaNormalCompras(
      ARol: TRolAperturaMantenimiento); virtual;
    property ConfiguracionDocumento: TConfiguracionDocumento
      read FConfiguracionDocumento;
    property EstrategiaDocumento: IEstrategiaDocumento
      read FEstrategiaDocumento;
  public
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResolverArtSkuActivo(
      out ACodArt, ACodSku: string); override;
    function DataSourcesParaFoto: TArray<TDataSource>; override;
    function SqlRestriccionUsuario: string; override;
    function PrepararPrecarga(
      ARol: TRolAperturaMantenimiento): Boolean;
    procedure PrepararBusquedaExterna(const ABusq: string); override;
  end;

implementation

uses
  System.SysUtils, System.Classes, Winapi.Windows, Vcl.Controls, Vcl.Dialogs,
  inLibColumnasDocumento, inLibDocumento, inLibDatasets,
  inLibFiltroUsuario, inLibMsgCompras, inLibMsgComun,
  inLibPerfilesUsuarioIntf, inLibPerfilesUsuarioValores,
  inLibPrecargaMantenimientos, inMtoGenPresentacionPerfilesVcl,
  UniDataGen, UniDataPrecargaCompras, inMtoModalFiltroCompras;

const
  CLAVE_PRECARGA_COMPRAS = 'oPrecargaSeriesPrimeraLista';

{$R *.dfm}

destructor TfrmMtoDocumento.Destroy;
begin
  FreeAndNil(FPrecargaCompras);
  FRepositorioPrecarga := nil;
  FEstrategiaDocumento := nil;
  FVistaLineasDocumento := nil;
  inherited;
end;

procedure TfrmMtoDocumento.InicializarDocumento(
  const AConfiguracion: TConfiguracionDocumento);
begin
  ValidarConfiguracionDocumento(AConfiguracion);
  FConfiguracionDocumento := AConfiguracion;
  FEstrategiaDocumento :=
    CrearEstrategiaDocumento(FConfiguracionDocumento);
end;

procedure TfrmMtoDocumento.AsignarVistaLineasDocumento(
  AVista: TcxGridDBTableView);
begin
  FVistaLineasDocumento := AVista;
end;

function TfrmMtoDocumento.ConfiguracionPersistenciaDocumento(
  const AMensajeCabeceraNoDisponible: string
): TConfiguracionDocumento;
begin
  Result := FConfiguracionDocumento;
  Result.MensajeCabeceraNoDisponible :=
    AMensajeCabeceraNoDisponible;
end;

function TfrmMtoDocumento.ConfiguracionTallasDocumento:
  TConfiguracionDocumento;
begin
  Result := FConfiguracionDocumento;
  Result.MensajeCabeceraNoDisponible := Format(
    SErrorCrearSeleccionarDocumentoAntesLineas,
    [FConfiguracionDocumento.NombreSingular]);
  Result.DocumentoConArticulo :=
    FConfiguracionDocumento.NombreSingular;
  Result.CampoEstadoCabecera :=
    FConfiguracionDocumento.CampoPivoteCabecera;
  Result.ValorEstadoCabecera := 'N';
  Result.CancelarLineaSoloSinNumero := True;
end;

procedure TfrmMtoDocumento.ResolverArtSkuActivo(
  out ACodArt, ACodSku: string);
begin
  ResolverArtSkuActivoDocumento(
    FVistaLineasDocumento, ACodArt, ACodSku);
end;

function TfrmMtoDocumento.DataSourcesParaFoto:
  TArray<TDataSource>;
begin
  Result := DataSourcesParaFotoDocumento(
    dsTablaG, FVistaLineasDocumento);
end;

function TfrmMtoDocumento.SqlRestriccionUsuario: string;
begin
  Result := RestriccionUsuarioDocumento;
  if UsaPrecargaCompras and (tdmDataModule is TdmBase) then
    Result := CualificarRestriccionPrecargaCompras(
      TdmBase(tdmDataModule).unqryTablaG, FConfiguracionDocumento, Result);
end;

function TfrmMtoDocumento.RestriccionUsuarioDocumento: string;
begin
  Result := SqlFiltroDocumento(
    ContextoSesion,
    ParametrosApp,
    FConfiguracionDocumento.PrefijoCabecera,
    FConfiguracionDocumento.FiltraCaja);
end;

function TfrmMtoDocumento.UsaPrecargaCompras: Boolean;
begin
  Result := (FConfiguracionDocumento.Sentido = sdCompra) and
    (FConfiguracionDocumento.TipoDocumento in [tdPedido, tdAlbaran]);
end;

procedure TfrmMtoDocumento.CrearTablaPrincipal;
begin
  FreeAndNil(FPrecargaCompras);
  FRepositorioPrecarga := nil;
  FPerfilPrecargaLeido := False;
  FPrecargaAceptada := False;
  FConsultaDesdePerfil := False;
  FRetornoListaPendiente := False;
  FRolListaPrecarga := ramPrimeraLista;
  if Assigned(FPanelPrecarga) then
    FPanelPrecarga.Visible := False;
  inherited;
end;

procedure TfrmMtoDocumento.AsegurarPrecargaCompras;
begin
  if not Assigned(FPrecargaCompras) and UsaPrecargaCompras and
     (tdmDataModule is TdmBase) then
  begin
    FRepositorioPrecarga := CrearRepositorioPrecargaCompras(
      TdmBase(tdmDataModule).unqryTablaG, FConfiguracionDocumento,
      RestriccionUsuarioDocumento);
    FPrecargaCompras := TPrecargaCompras.Create(FRepositorioPrecarga);
  end;
end;

function TfrmMtoDocumento.PrepararPrecarga(
  ARol: TRolAperturaMantenimiento): Boolean;
begin
  if ARol = ramBusqueda then
    ValidarCambioConsultaPrecarga;
  Result := True;
  FRolPrecarga := ARol;
  if ARol <> ramBusqueda then
  begin
    FRolListaPrecarga := ARol;
    if UsaPrecargaCompras and (tdmDataModule is TdmBase) then
      TdmBase(tdmDataModule).RestaurarListaTrasBusquedaExterna;
    AsegurarPrecargaCompras;
  end;
  if Assigned(FPrecargaCompras) then
  begin
    if (ARol = ramPrimeraLista) and not FPerfilPrecargaLeido then
      LeerPerfilPrecarga;
    Result := FPrecargaCompras.Preparar(ARol, SeleccionarSeriesPrecarga);
    if Result then
      FPrecargaAceptada := ARol <> ramBusqueda;
    ActualizarPanelPrecarga;
  end;
  if (ARol <> ramBusqueda) and not FRestaurandoLista then
    FRetornoListaPendiente := False;
end;

procedure TfrmMtoDocumento.PrepararBusquedaExterna(const ABusq: string);
begin
  if (tdmDataModule is TdmBase) and (ABusq <> '') and
     (pkFieldName <> '') then
  begin
    ValidarCambioConsultaPrecarga;
    if Assigned(FPrecargaCompras) then
    begin
      FPrecargaCompras.PrepararBusquedaExterna;
      FPrecargaAceptada := False;
      FRolPrecarga := ramBusqueda;
      ActualizarPanelPrecarga;
    end;
    // UniDataGen debe guardar como base el SQL sin el filtro de precarga.
    inherited;
    PrepararRetornoDeBusqueda(ABusq);
  end;
end;

procedure TfrmMtoDocumento.ValidarCambioConsultaPrecarga;
var
  Modulo: TdmBase;
  CabeceraEnEdicion: Boolean;
begin
  if UsaPrecargaCompras and (tdmDataModule is TdmBase) then
  begin
    Modulo := TdmBase(tdmDataModule);
    CabeceraEnEdicion := Assigned(Modulo.unqryTablaG) and
      (Modulo.unqryTablaG.State in dsEditModes);
    if CabeceraEnEdicion or CheckOpenDatasets(Modulo) then
      raise EDatabaseError.Create(SErrorPrecargaComprasEnEdicion);
  end;
end;

procedure TfrmMtoDocumento.PrepararRetornoDeBusqueda(const ABusq: string);
begin
  if UsaPrecargaCompras and (tdmDataModule is TdmBase) and
     (ABusq <> '') and (pkFieldName <> '') and Assigned(tsLista) and
     tsLista.TabVisible and not EsInstanciaBusqueda then
  begin
    FRetornoListaPendiente := True;
    InstalarEventoRetornoLista;
  end;
end;

procedure TfrmMtoDocumento.InstalarEventoRetornoLista;
begin
  if not FEventoRetornoInstalado then
  begin
    FEventoCambioPaginaAnterior := pcPantalla.OnPageChanging;
    pcPantalla.OnPageChanging := PaginaPrecargaCambiando;
    FEventoRetornoInstalado := True;
  end;
end;

function TfrmMtoDocumento.DebeRestaurarLista(
  ANuevaPagina: TcxTabSheet): Boolean;
begin
  Result := FRetornoListaPendiente and not FRestaurandoLista and
    UsaPrecargaCompras and not EsInstanciaBusqueda and
    Assigned(tsLista) and (ANuevaPagina = tsLista) and
    tsLista.TabVisible and not (csLoading in ComponentState) and
    not (csDestroying in ComponentState);
end;

procedure TfrmMtoDocumento.PaginaPrecargaCambiando(Sender: TObject;
  NewPage: TcxTabSheet; var AllowChange: Boolean);
begin
  if Assigned(FEventoCambioPaginaAnterior) then
    FEventoCambioPaginaAnterior(Sender, NewPage, AllowChange);
  if AllowChange and DebeRestaurarLista(NewPage) then
    RetornarAListaNormal;
end;

procedure TfrmMtoDocumento.RetornarAListaNormal;
var
  RolLista: TRolAperturaMantenimiento;
begin
  ValidarCambioConsultaPrecarga;
  RolLista := FRolListaPrecarga;
  if RolLista = ramBusqueda then
    RolLista := ramPrimeraLista;
  FRestaurandoLista := True;
  try
    RestaurarListaNormalCompras(RolLista);
    // Cancelar permite ver la Lista pendiente, pero nunca la abre sin filtro.
    FRetornoListaPendiente := False;
  finally
    FRestaurandoLista := False;
  end;
end;

procedure TfrmMtoDocumento.RestaurarListaNormalCompras(
  ARol: TRolAperturaMantenimiento);
begin
  if PrepararPrecarga(ARol) then
    AbrirTablaPrincipal(False);
end;

function TfrmMtoDocumento.SeleccionarSeriesPrecarga(
  const ACatalogo: TSeriesPrecargaCompra;
  const ASeleccion: TArray<string>;
  out ANuevaSeleccion: TArray<string>): Boolean;
begin
  Result := TfrmModalFiltroCompras.Ejecutar(
    Self, FConfiguracionDocumento.NombreSingular, ACatalogo,
    ASeleccion, FRepositorioPrecarga, ANuevaSeleccion);
end;

procedure TfrmMtoDocumento.CrearPanelPrecarga;
begin
  FPanelPrecarga := TPanel.Create(Self);
  FPanelPrecarga.Parent := tsLista;
  FPanelPrecarga.Align := alTop;
  FPanelPrecarga.Height := MulDiv(48, CurrentPPI, 96);
  FPanelPrecarga.BevelOuter := bvNone;
  FBotonPrecarga := TcxButton.Create(Self);
  FBotonPrecarga.Parent := FPanelPrecarga;
  FBotonPrecarga.Align := alLeft;
  FBotonPrecarga.AlignWithMargins := True;
  FBotonPrecarga.Margins.SetBounds(
    MulDiv(6, CurrentPPI, 96), MulDiv(6, CurrentPPI, 96),
    MulDiv(10, CurrentPPI, 96), MulDiv(6, CurrentPPI, 96));
  FBotonPrecarga.Width := MulDiv(176, CurrentPPI, 96);
  FBotonPrecarga.Caption := SCaptionFiltrosPrecargaCompras;
  FBotonPrecarga.OnClick := PrecargaSeriesClick;
  FBotonGuardarPrecarga := TcxButton.Create(Self);
  FBotonGuardarPrecarga.Parent := FPanelPrecarga;
  FBotonGuardarPrecarga.Align := alRight;
  FBotonGuardarPrecarga.AlignWithMargins := True;
  FBotonGuardarPrecarga.Margins.Assign(FBotonPrecarga.Margins);
  FBotonGuardarPrecarga.Width := MulDiv(178, CurrentPPI, 96);
  FBotonGuardarPrecarga.Caption := SCaptionGuardarPrecargaCompras;
  FBotonGuardarPrecarga.OnClick := GuardarPrecargaClick;
  FResumenPrecarga := TcxLabel.Create(Self);
  FResumenPrecarga.Parent := FPanelPrecarga;
  FResumenPrecarga.Align := alClient;
  FResumenPrecarga.AutoSize := False;
  FResumenPrecarga.AlignWithMargins := True;
  FResumenPrecarga.Margins.SetBounds(
    0, MulDiv(6, CurrentPPI, 96), MulDiv(6, CurrentPPI, 96), 0);
  FResumenPrecarga.Properties.WordWrap := True;
  FResumenPrecarga.ShowHint := True;
end;

procedure TfrmMtoDocumento.ActualizarPanelPrecarga;
var
  aSeries: TArray<string>;
begin
  if FRolPrecarga <> ramBusqueda then
  begin
    if not Assigned(FPanelPrecarga) then
      CrearPanelPrecarga;
    aSeries := FPrecargaCompras.SeriesSeleccionadas;
    if not FPrecargaAceptada then
      FResumenPrecarga.Caption := SInfoPrecargaComprasPendiente
    else if FConsultaDesdePerfil then
      FResumenPrecarga.Caption := SInfoPrecargaComprasPerfil
    else if Length(aSeries) = 0 then
      FResumenPrecarga.Caption := SInfoPrecargaComprasTodas
    else if Length(aSeries) = 1 then
      FResumenPrecarga.Caption := Format(
        SInfoPrecargaComprasSerie, [aSeries[0]])
    else
      FResumenPrecarga.Caption := Format(
        SInfoPrecargaComprasVarias, [Length(aSeries)]);
    FResumenPrecarga.Hint := string.Join(', ', aSeries);
  end;
  if Assigned(FPanelPrecarga) then
  begin
    FPanelPrecarga.Visible := FRolPrecarga <> ramBusqueda;
    FBotonGuardarPrecarga.Visible := FRolPrecarga = ramPrimeraLista;
    FBotonGuardarPrecarga.Enabled :=
      FPrecargaAceptada and not FConsultaDesdePerfil;
  end;
end;

procedure TfrmMtoDocumento.CambiarSeriesPrecarga;
begin
  if CheckOpenDatasets(TdmBase(tdmDataModule)) then
    ShowMessage(SErrorPrecargaComprasEnEdicion)
  else if FPrecargaCompras.CambiarSeries(SeleccionarSeriesPrecarga) then
  begin
    FPrecargaAceptada := True;
    FConsultaDesdePerfil := False;
    ActualizarPanelPrecarga;
    AbrirTablaPrincipal(False);
  end;
end;

procedure TfrmMtoDocumento.PrecargaSeriesClick(Sender: TObject);
begin
  CambiarSeriesPrecarga;
end;

function TfrmMtoDocumento.HayConsultaPrincipalEnPerfil: Boolean;
var
  oModulo: TdmBase;
begin
  oModulo := TdmBase(tdmDataModule);
  Result := SameText(GetPerfilValueDef(
    oPerfilDic, 'oGetSQLFromDB', 'False'), 'True') and
    (Trim(GetPerfilValueTextDef(
      oModulo.FoPerfilDic, 'unqryTablaG', '')) <> '');
end;

procedure TfrmMtoDocumento.LeerPerfilPrecarga;
var
  aSeries: TArray<string>;
  sPreferencia: string;
begin
  sPreferencia := GetPerfilValueTextDef(
    oPerfilDic, CLAVE_PRECARGA_COMPRAS, '');
  if LeerSeleccionPrecarga(sPreferencia, aSeries) then
    FPrecargaCompras.EstablecerFiltroUsuario(aSeries)
  else if Assigned(oPerfilDic) and
          oPerfilDic.ContainsKey(CLAVE_PRECARGA_COMPRAS) then
    raise EConvertError.Create(SErrorPrecargaComprasPerfilVacio)
  else if HayConsultaPrincipalEnPerfil then
  begin
    // Nunca imponer un valor automatico sobre una configuracion explicita.
    FPrecargaCompras.RespetarFiltroExistente;
    FConsultaDesdePerfil := True;
  end;
  FPerfilPrecargaLeido := True;
end;

procedure TfrmMtoDocumento.GuardarPrecarga;
var
  sPermisos: string;
  sSeleccion: string;
  oValor: TDictValue;
begin
  if FPrecargaAceptada and SolicitarDestinoPerfilMto(
    Self, Name, SDescripcionGuardarPrecargaCompras, False, sPermisos) then
  begin
    sSeleccion := SerializarSeleccionPrecarga(
      FPrecargaCompras.SeriesSeleccionadas);
    // VALUE_TEXT permite muchas series sin el limite de 200 caracteres.
    PerfilesEscritura.GrabarPerfil(
      sPermisos, Name, CLAVE_PRECARGA_COMPRAS, 'S', sSeleccion);
    if Assigned(oPerfilDic) then
    begin
      oValor.sValue := 'S';
      oValor.sValueText := sSeleccion;
      oPerfilDic.AddOrSetValue(CLAVE_PRECARGA_COMPRAS, oValor);
    end;
    ShowMessage(SInfoPrecargaComprasGuardada);
  end;
end;

procedure TfrmMtoDocumento.GuardarPrecargaClick(Sender: TObject);
begin
  GuardarPrecarga;
end;

end.
