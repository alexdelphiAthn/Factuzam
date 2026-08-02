{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionCopiaLineas                   }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Copia de lineas de una sesion de compra: duplicado desde los botones      }
{    "Otro color" / "Otro precio" y copia diferida cuando se repite un         }
{    modelo ya tecleado. Las reglas comerciales viven en                       }
{    inLibGestorCopiaLineasCompra; aqui solo queda el efecto sobre el grid,    }
{    las cantidades por talla y el modal de decision.                          }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionCopiaLineas;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  Data.DB,
  cxEdit,
  cxGridCustomTableView,
  cxGridTableView,
  cxGridDBTableView,
  inLibComprasSesiones,
  inLibComprasSesionesIntf,
  inLibComprasSesionesPresentacion,
  inLibComprasSesionesPresentacionIntf,
  inLibGestorCopiaLineasCompra,
  inLibGridTallasInline;

type
  TEntornoCopiaLineasSesion = record
    Propietario: TComponent;
    Servicio: TServicioComprasSesiones;
    Usuario: string;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Vista: TcxGridDBTableView;
    ColumnasTallas: TArray<TcxGridDBColumn>;
    ColumnaColor: TcxGridDBColumn;
    ColumnaPrecioCompra: TcxGridDBColumn;
    ObtenerGestorTallas: TFunc<TGestorGridTallas>;
    RefrescarTotalesSesion: TProc;
    RegistrarAviso: TProc<string>;
  end;

  TCoordinadorCopiaLineasSesion = class
  private
    FEntorno: TEntornoCopiaLineasSesion;
    FGestor: TGestorCopiaLineasCompra;
    FPlanificadorModal: IPlanificadorDiferido;
    function GestorTallas: TGestorGridTallas;
    function EsFormatoDistribuido: Boolean;
    function ObtenerSiguienteLinea(ALineaOrigen: Integer): Integer;
    function LeerCantidadesLineaActiva: TArray<Double>;
    procedure CopiarCeldasDistribuidas(
      ALineaOrigen, ALineaDestino: Integer);
    procedure CopiarCantidadesEntreLineas(
      ALineaOrigen, ALineaDestino: Integer);
    procedure ReponerCantidadesDuplicado(
      const AResultado: TResultadoCopiaLineaCompra;
      const ACantidades: TArray<Double>);
    procedure ColocarFocoEnCopia(ALineaDestino: Integer;
      AModo: TModoCopiaLineaCompra);
    procedure RecargarTallasDiferido;
    procedure AplicarCopiaEnLineaActual(AModo: TModoCopiaLineaCompra);
    procedure PreguntarCopiaPendiente;
    procedure CerrarEditorEnCurso;
  public
    constructor Create(const AEntorno: TEntornoCopiaLineasSesion);
    destructor Destroy; override;
    // 'C' = otro color (copia precios y cantidades, deja el color
    // vacio); 'P' = otro rango de precios (copia el color, deja coste,
    // PVP y cantidades vacios).
    procedure DuplicarLineaActiva(const AOpcion: string);
    // Guarda la linea origen detectada al repetir un modelo y difiere
    // el modal de decision: no puede abrirse dentro del editor in-place.
    procedure PrepararCopiaPendiente(
      const AModelo: string;
      ALineaOrigen: Integer;
      const AColorTexto: string;
      const AColorBasico: string;
      AMargen: Double);
  end;

implementation

uses
  inMtoComprasSesionesPresentacionPlanificador,
  inMtoModalRepetirModelo;

const
  cIntervaloModalMs = 1;

constructor TCoordinadorCopiaLineasSesion.Create(
  const AEntorno: TEntornoCopiaLineasSesion);
begin
  inherited Create;
  if not Assigned(AEntorno.Servicio) then
    raise EArgumentNilException.Create('AEntorno.Servicio');
  if not Assigned(AEntorno.Cabecera) then
    raise EArgumentNilException.Create('AEntorno.Cabecera');
  if not Assigned(AEntorno.Lineas) then
    raise EArgumentNilException.Create('AEntorno.Lineas');
  FEntorno := AEntorno;
  FGestor := TGestorCopiaLineasCompra.Create(
    FEntorno.Cabecera,
    FEntorno.Lineas,
    ObtenerSiguienteLinea);
  FPlanificadorModal := TPlanificadorDiferidoTimer.Create(
    cIntervaloModalMs,
    procedure
    begin
      PreguntarCopiaPendiente;
    end);
end;

destructor TCoordinadorCopiaLineasSesion.Destroy;
begin
  FPlanificadorModal := nil;
  FreeAndNil(FGestor);
  inherited Destroy;
end;

function TCoordinadorCopiaLineasSesion.GestorTallas: TGestorGridTallas;
begin
  Result := nil;
  if Assigned(FEntorno.ObtenerGestorTallas) then
    Result := FEntorno.ObtenerGestorTallas();
end;

function TCoordinadorCopiaLineasSesion.EsFormatoDistribuido: Boolean;
begin
  Result := (not FEntorno.Cabecera.IsEmpty) and
            (FEntorno.Cabecera.FieldByName(
              'ESFORMATO_DISTRIBUIDO_SES').AsString = 'S');
end;

function TCoordinadorCopiaLineasSesion.ObtenerSiguienteLinea(
  ALineaOrigen: Integer): Integer;
begin
  Result := 0;
  if not FEntorno.Cabecera.IsEmpty then
    Result := FEntorno.Servicio.ObtenerSiguienteLinea(
      FEntorno.Cabecera.FieldByName('SERIE_SES').AsString,
      FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString,
      ALineaOrigen);
end;

// Las cantidades por talla viven en los Values[] no-bound del grid: hay
// que leerlas ANTES de insertar la copia, porque el insert repinta la
// fila y las borra.
function TCoordinadorCopiaLineasSesion.LeerCantidadesLineaActiva:
  TArray<Double>;
var
  iColumna: Integer;
  iFila: Integer;
  vValor: Variant;
begin
  iFila := FEntorno.Vista.Controller.FocusedRecordIndex;
  SetLength(Result, Length(FEntorno.ColumnasTallas));
  for iColumna := 0 to High(FEntorno.ColumnasTallas) do
  begin
    Result[iColumna] := 0;
    if Assigned(FEntorno.ColumnasTallas[iColumna]) and (iFila >= 0) then
    begin
      vValor := FEntorno.Vista.DataController.Values[
        iFila, FEntorno.ColumnasTallas[iColumna].Index];
      if (not VarIsNull(vValor)) and
         (not VarIsEmpty(vValor)) and
         VarIsNumeric(vValor) then
        Result[iColumna] := vValor;
    end;
  end;
end;

procedure TCoordinadorCopiaLineasSesion.CopiarCeldasDistribuidas(
  ALineaOrigen, ALineaDestino: Integer);
begin
  FEntorno.Servicio.CopiarCeldasDistribuidas(
    FEntorno.Cabecera.FieldByName('SERIE_SES').AsString,
    FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString,
    FEntorno.Cabecera.FieldByName('CODIGO_ALM_SES').AsString,
    FEntorno.Usuario,
    ALineaOrigen,
    ALineaDestino);
end;

procedure TCoordinadorCopiaLineasSesion.CopiarCantidadesEntreLineas(
  ALineaOrigen, ALineaDestino: Integer);
var
  sSerie: string;
  sNumero: string;
  Cantidades: TCantidadesPivotSesion;
  Cantidad: TCantidadPivotSesion;
begin
  sSerie := FEntorno.Cabecera.FieldByName('SERIE_SES').AsString;
  sNumero := FEntorno.Cabecera.FieldByName('NUMERO_SES').AsString;
  if EsFormatoDistribuido then
    CopiarCeldasDistribuidas(ALineaOrigen, ALineaDestino)
  else
  begin
    FEntorno.Servicio.BorrarCeldasLinea(sSerie, sNumero, ALineaDestino);
    Cantidades := FEntorno.Servicio.ConsultarCantidadesLinea(
      sSerie, sNumero, ALineaOrigen);
    for Cantidad in Cantidades do
    begin
      if (Cantidad.Cantidad > 0) and Assigned(GestorTallas) then
        GestorTallas.PersistirCantidad(
          ALineaDestino,
          Cantidad.IdValorPivot,
          Cantidad.Cantidad);
    end;
  end;
end;

procedure TCoordinadorCopiaLineasSesion.ReponerCantidadesDuplicado(
  const AResultado: TResultadoCopiaLineaCompra;
  const ACantidades: TArray<Double>);
var
  Posiciones: TArrPosConjunto;
  iPosicion: Integer;
begin
  if EsFormatoDistribuido then
  begin
    CopiarCeldasDistribuidas(
      AResultado.LineaOrigen,
      AResultado.LineaDestino);
    FEntorno.Lineas.Refresh;
    FEntorno.Lineas.Locate(
      'LINEA_SESLIN', AResultado.LineaDestino, []);
  end
  else if AResultado.IdConjuntoPivot > 0 then
  begin
    Posiciones := GestorTallas.GetPosicionesConjunto(
      AResultado.IdConjuntoPivot);
    for iPosicion := 0 to High(Posiciones) do
    begin
      if (iPosicion <= High(ACantidades)) and
         (ACantidades[iPosicion] > 0) then
        GestorTallas.PersistirCantidad(
          AResultado.LineaDestino,
          Posiciones[iPosicion].IdAv,
          ACantidades[iPosicion]);
    end;
  end;
end;

procedure TCoordinadorCopiaLineasSesion.ColocarFocoEnCopia(
  ALineaDestino: Integer;
  AModo: TModoCopiaLineaCompra);
begin
  if FEntorno.Lineas.Locate('LINEA_SESLIN', ALineaDestino, []) then
    FEntorno.Vista.Controller.FocusedRecordIndex :=
      FEntorno.Lineas.RecNo - 1;
  if DestinoFocoCopiaSesion(AModo) = dfcPrecioCompra then
    FEntorno.Vista.Controller.FocusedColumn := FEntorno.ColumnaPrecioCompra
  else
    FEntorno.Vista.Controller.FocusedColumn := FEntorno.ColumnaColor;
  if Assigned(FEntorno.Vista.Controller.EditingController) then
    FEntorno.Vista.Controller.EditingController.ShowEdit;
  RecargarTallasDiferido;
end;

// El repintado del grid puede llegar despues de cargar las cantidades y
// volver a borrar los Values[] no-bound: la recarga diferida tiene la
// ultima palabra.
procedure TCoordinadorCopiaLineasSesion.RecargarTallasDiferido;
begin
  TThread.ForceQueue(nil,
    procedure
    var
      Gestor: TGestorGridTallas;
    begin
      Gestor := GestorTallas;
      if Assigned(Gestor) then
        Gestor.CargarCantidadesTodasLineas;
    end);
end;

procedure TCoordinadorCopiaLineasSesion.DuplicarLineaActiva(
  const AOpcion: string);
var
  Modo: TModoCopiaLineaCompra;
  Resultado: TResultadoCopiaLineaCompra;
  Cantidades: TArray<Double>;
begin
  Modo := ModoCopiaLineaSesion(AOpcion);
  if Assigned(GestorTallas) and
     (not FEntorno.Lineas.IsEmpty) and
     (not FEntorno.Cabecera.IsEmpty) then
  begin
    Cantidades := LeerCantidadesLineaActiva;
    Resultado := FGestor.DuplicarLineaActual(Modo);
    if Resultado.Aplicada then
    begin
      if Resultado.CopiarCantidades then
        ReponerCantidadesDuplicado(Resultado, Cantidades);
      GestorTallas.RefrescarTotalesLineaActual;
      if Assigned(FEntorno.RefrescarTotalesSesion) then
        FEntorno.RefrescarTotalesSesion();
      GestorTallas.RecalcularMaxColumnas;
      GestorTallas.CargarCantidadesTodasLineas;
      ColocarFocoEnCopia(Resultado.LineaDestino, Modo);
    end;
  end;
end;

// Completa la linea ACTUAL (donde se acaba de teclear el modelo
// repetido) como copia de la linea origen conservada por el gestor.
procedure TCoordinadorCopiaLineasSesion.AplicarCopiaEnLineaActual(
  AModo: TModoCopiaLineaCompra);
var
  Resultado: TResultadoCopiaLineaCompra;
begin
  Resultado := FGestor.AplicarCopiaPendiente(AModo);
  if Resultado.Aplicada then
  begin
    if Resultado.CopiarCantidades then
      CopiarCantidadesEntreLineas(
        Resultado.LineaOrigen,
        Resultado.LineaDestino);
    FEntorno.Lineas.Refresh;
    FEntorno.Lineas.Locate('LINEA_SESLIN', Resultado.LineaDestino, []);
    if Assigned(GestorTallas) then
    begin
      GestorTallas.RecalcularMaxColumnas;
      GestorTallas.CargarCantidadesTodasLineas;
      GestorTallas.RefrescarTotalesLineaActual;
    end;
    if Assigned(FEntorno.RefrescarTotalesSesion) then
      FEntorno.RefrescarTotalesSesion();
    ColocarFocoEnCopia(Resultado.LineaDestino, AModo);
  end;
end;

procedure TCoordinadorCopiaLineasSesion.PrepararCopiaPendiente(
  const AModelo: string;
  ALineaOrigen: Integer;
  const AColorTexto: string;
  const AColorBasico: string;
  AMargen: Double);
begin
  FGestor.PrepararCopiaPendiente(
    AModelo,
    ALineaOrigen,
    AColorTexto,
    AColorBasico,
    AMargen);
  FPlanificadorModal.Rearmar;
end;

procedure TCoordinadorCopiaLineasSesion.CerrarEditorEnCurso;
begin
  if FEntorno.Vista.Controller.EditingController.IsEditing then
    try
      FEntorno.Vista.Controller.EditingController.HideEdit(True);
    except
      on E: EInvalidOperation do
        if Assigned(FEntorno.RegistrarAviso) then
          FEntorno.RegistrarAviso(
            'ComprasSesiones.CopiaLineas: HideEdit ignorado: ' +
            E.Message);
    end;
end;

// Pregunta diferida: repetir la linea origen en otro color, en otro
// rango de precios, o dejar la herencia REUSAR tal cual (cancelar).
procedure TCoordinadorCopiaLineasSesion.PreguntarCopiaPendiente;
var
  Modal: TfrmModalRepetirModelo;
  sOpcion: string;
begin
  if FGestor.HayCopiaPendiente and (not FEntorno.Lineas.IsEmpty) then
  begin
    CerrarEditorEnCurso;
    sOpcion := 'N';
    Modal := TfrmModalRepetirModelo.Create(FEntorno.Propietario);
    try
      Modal.PrepararMensaje(
        FGestor.ModeloPendiente,
        FGestor.LineaOrigenPendiente);
      Modal.ShowModal;
      sOpcion := Modal.sOpcion;
    finally
      FreeAndNil(Modal);
    end;
    if EsOpcionCopiaLineaSesion(sOpcion) then
      AplicarCopiaEnLineaActual(ModoCopiaLineaSesion(sOpcion));
  end;
  FGestor.DescartarCopiaPendiente;
end;

end.
