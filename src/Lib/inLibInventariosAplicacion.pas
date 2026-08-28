{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventariosAplicacion                                    }
{    Tipo:       Aplicacion                                                    }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Orquesta la entrada y la importacion de recuentos de inventario           }
{    sin conocer formularios, datasets concretos ni SQL.                       }
{******************************************************************************}
unit inLibInventariosAplicacion;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  inLibArticulosValidadorIntf,
  inLibInventariosAplicacionIntf;

function CrearAplicacionEntradaInventario(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaInventario):
  IAplicacionEntradaInventario;
// Lector CSV del recuento: cada linea es "UNIDAD;CANTIDAD" o
// "UNIDAD=CANTIDAD". Sin cantidad legible se asume una unidad, que es el
// comportamiento historico del lector de la pantalla.
function LeerLineasImportacionCsvInventario(
  const ATextos: TArray<string>): TLineasImportacionInventario;
// Reparte las lineas leidas entre actualizacion de recuento y alta
// pendiente. No conoce datasets: escribe a traves del puerto.
function AplicarImportacionInventario(
  const ALineas: TLineasImportacionInventario;
  const AOperaciones: IOperacionesImportacionInventario):
  TResumenImportacionInventario;

function CompletarFechasRecuentoInventario(
  var ALineas: TLineasImportacionInventario;
  const ASolicitar: TSolicitarFechaRecuentoInventario): Boolean;

function FechaHoraRecuentoInventarioValida(
  AFechaHora, AFechaReferencia: TDateTime): Boolean;

function ValidarIdentidadImportacionInventario(
  const AIdentidad: TIdentidadImportacionInventario;
  const AInventario: TClaveInventario):
  TEstadoIdentidadImportacionInventario;

function ConsolidarLineasSinIdentidadInventario(
  const ALineas: TLineasImportacionInventario):
  TLineasImportacionInventario;

function ConsolidarLineasNuevasInventario(
  const ALineas: TLineasImportacionInventario;
  const ANuevas: TStrings): TLineasImportacionInventario;
// Adaptador del puerto de importacion sobre el dataset de lineas. No
// conoce VCL ni UniDAC: recibe el dataset, la lista de altas pendientes
// y las dos acciones propias del data module.
function CrearOperacionesImportacionInventario(
  ALineas: TDataSet; ANuevas: TStrings;
  const AAlConfirmarLinea: TProc;
  const AConsolidar: TProc): IOperacionesImportacionInventario;

implementation

uses
  inLibInventariosEntrada;

const
  CAMPO_LINEA_IMPORTACION = 'LINEA_INVLIN';
  CAMPO_UNIDAD_IMPORTACION = 'CODIGO_UNIDAD_INVLIN';
  CAMPO_CANTIDAD_IMPORTACION = 'CANTIDAD_FISICA_INVLIN';
  CAMPO_PRECIO_IMPORTACION = 'PRECIO_MEDIO_NUEVO_INVLIN';
  CAMPO_PRECIO_CORREGIDO = 'ESPRECIO_MEDIO_CORREGIDO_INVLIN';
  CAMPO_FECHA_RECUENTO = 'FECHA_RECUENTO_INVLIN';

type
  TOperacionesImportacionInventarioDataSet = class(
    TInterfacedObject,
    IOperacionesImportacionInventario)
  private
    FLineas: TDataSet;
    FNuevas: TStrings;
    FAlConfirmarLinea: TProc;
    FConsolidar: TProc;
  public
    constructor Create(
      ALineas: TDataSet; ANuevas: TStrings;
      const AAlConfirmarLinea: TProc;
      const AConsolidar: TProc);
    function LocalizarLinea(
      const ACodigoLinea, ACodigoUnidad: string): Boolean;
    procedure IniciarEdicionLinea;
    procedure EscribirCantidadFisica(ACantidad: Double);
    procedure EscribirPrecioMedioNuevo(APrecio: Double);
    procedure EscribirFechaRecuento(AFecha: TDateTime);
    procedure UsarPrecioMedioHistorico;
    procedure ConfirmarLinea;
    procedure ConsolidarCambios;
    procedure AnadirUnidadPendiente(const ATextoOriginal: string);
  end;

  TAplicacionEntradaInventario = class(
    TInterfacedObject,
    IAplicacionEntradaInventario)
  private
    FValidador: IArticulosValidador;
    FOperaciones: IOperacionesEntradaInventario;
  public
    constructor Create(
      const AValidador: IArticulosValidador;
      const AOperaciones: IOperacionesEntradaInventario);
    function Procesar(
      const AEntrada: string): TResultadoEntradaInventario;
  end;

constructor TAplicacionEntradaInventario.Create(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaInventario);
begin
  inherited Create;
  if not Assigned(AValidador) then
    raise EArgumentNilException.Create('AValidador');
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  FValidador := AValidador;
  FOperaciones := AOperaciones;
end;

function TAplicacionEntradaInventario.Procesar(
  const AEntrada: string): TResultadoEntradaInventario;
var
  bMuestraAtributos: Boolean;
  iNumeroAtributos: Integer;
  Resolucion: TArtResolucionEntrada;
  Decision: TDecisionEntradaInventario;
begin
  Result := Default(TResultadoEntradaInventario);
  Resolucion := FValidador.Resolver(Trim(AEntrada));
  if not Resolucion.Encontrado then
    Result.Error := eeiArticuloNoEncontrado;
  if Result.Error = eeiNinguno then
  begin
    Result.CodigoArticulo := Resolucion.CodigoArticulo;
    Result.CodigoSku := Resolucion.CodigoSku;
    Result.Descripcion := Resolucion.DescripcionArticulo;
    Result.TipoArticulo := Resolucion.TipoArticulo;
  end;
  if (Result.Error = eeiNinguno) and
     (not SameText(Resolucion.TipoArticulo, 'ESTANDAR')) then
    Result.Error := eeiTipoArticuloSinStock;
  bMuestraAtributos := FOperaciones.MuestraAtributos;
  iNumeroAtributos := 0;
  if (Result.Error = eeiNinguno) and
     (not bMuestraAtributos) and
     (Resolucion.CodigoSku = '') then
  begin
    iNumeroAtributos := FOperaciones.ObtenerNumeroAtributos(
      Resolucion.CodigoArticulo);
    if iNumeroAtributos > 0 then
      Result.Error := eeiAtributosRequierenSku;
  end;
  if Result.Error = eeiNinguno then
    Result.Error := FOperaciones.AsegurarEdicion;
  if Result.Error = eeiNinguno then
  begin
    FOperaciones.EscribirArticulo(
      Result.CodigoArticulo,
      Result.Descripcion);
    FOperaciones.ActualizarColumnas(Result.CodigoArticulo);
    if bMuestraAtributos then
      iNumeroAtributos := FOperaciones.NumeroAtributosActual;
    Result.Error := FOperaciones.AsegurarEdicion;
  end;
  if Result.Error = eeiNinguno then
  begin
    Decision := ResolverEntradaInventario(
      Result.CodigoArticulo,
      Result.CodigoSku,
      iNumeroAtributos);
    Result.CodigoUnidad := Decision.CodigoUnidad;
    FOperaciones.EscribirUnidad(Result.CodigoUnidad);
    if Decision.CargarStock then
      FOperaciones.CargarStock(Result.CodigoUnidad);
    if Decision.RellenarAtributos then
      FOperaciones.RellenarAtributos(Result.CodigoUnidad);
  end;
end;

function CrearAplicacionEntradaInventario(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaInventario):
  IAplicacionEntradaInventario;
begin
  Result := TAplicacionEntradaInventario.Create(
    AValidador,
    AOperaciones);
end;

function LeerLineasImportacionCsvInventario(
  const ATextos: TArray<string>): TLineasImportacionInventario;
var
  iLinea: Integer;
  iSeparador: Integer;
  iResultado: Integer;
  sTexto: string;
  sUnidad: string;
  sCantidad: string;
begin
  SetLength(Result, 0);
  for iLinea := 0 to High(ATextos) do
  begin
    // El separador ';' del CSV se normaliza a '=' antes de partir, igual
    // que hacia la pantalla al cargar el fichero.
    sTexto := StringReplace(ATextos[iLinea], ';', '=', [rfReplaceAll]);
    iSeparador := Pos('=', sTexto);
    sUnidad := '';
    sCantidad := '';
    if iSeparador > 0 then
    begin
      sUnidad := Copy(sTexto, 1, iSeparador - 1);
      sCantidad := Copy(sTexto, iSeparador + 1, Length(sTexto));
    end;
    iResultado := Length(Result);
    SetLength(Result, iResultado + 1);
    Result[iResultado].CodigoUnidad := sUnidad;
    Result[iResultado].CodigoLinea := '';
    Result[iResultado].Cantidad := StrToFloatDef(sCantidad, 1);
    Result[iResultado].PrecioMedioNuevo := 0;
    Result[iResultado].TienePrecioMedio := False;
    Result[iResultado].TextoOriginal := sTexto;
  end;
end;

function AplicarImportacionInventario(
  const ALineas: TLineasImportacionInventario;
  const AOperaciones: IOperacionesImportacionInventario):
  TResumenImportacionInventario;
var
  iLinea: Integer;
begin
  Result := Default(TResumenImportacionInventario);
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  for iLinea := 0 to High(ALineas) do
  begin
    if ALineas[iLinea].CodigoUnidad <> '' then
    begin
      if AOperaciones.LocalizarLinea(
           ALineas[iLinea].CodigoLinea,
           ALineas[iLinea].CodigoUnidad) then
      begin
        AOperaciones.IniciarEdicionLinea;
        AOperaciones.EscribirCantidadFisica(ALineas[iLinea].Cantidad);
        if ALineas[iLinea].TienePrecioMedio then
          AOperaciones.EscribirPrecioMedioNuevo(
            ALineas[iLinea].PrecioMedioNuevo)
        else
          AOperaciones.UsarPrecioMedioHistorico;
        if ALineas[iLinea].TieneFechaRecuento then
          AOperaciones.EscribirFechaRecuento(
            ALineas[iLinea].FechaRecuento);
        AOperaciones.ConfirmarLinea;
        Inc(Result.Actualizadas);
      end
      else
      begin
        AOperaciones.AnadirUnidadPendiente(ALineas[iLinea].TextoOriginal);
        Inc(Result.Nuevas);
      end;
    end;
  end;
  if Result.Actualizadas > 0 then
    AOperaciones.ConsolidarCambios;
end;

function CompletarFechasRecuentoInventario(
  var ALineas: TLineasImportacionInventario;
  const ASolicitar: TSolicitarFechaRecuentoInventario): Boolean;
var
  FechaRecuento: TDateTime;
  FaltanFechas: Boolean;
  iLinea: Integer;
begin
  if not Assigned(ASolicitar) then
    raise EArgumentNilException.Create('ASolicitar');
  FaltanFechas := False;
  for iLinea := 0 to High(ALineas) do
    if not ALineas[iLinea].TieneFechaRecuento then
      FaltanFechas := True;
  Result := True;
  if FaltanFechas then
  begin
    Result := ASolicitar(FechaRecuento);
    if Result then
      Result := FechaHoraRecuentoInventarioValida(
        FechaRecuento,
        Now);
    if Result then
      for iLinea := 0 to High(ALineas) do
        if not ALineas[iLinea].TieneFechaRecuento then
        begin
          ALineas[iLinea].FechaRecuento := FechaRecuento;
          ALineas[iLinea].TieneFechaRecuento := True;
        end;
  end;
end;

function FechaHoraRecuentoInventarioValida(
  AFechaHora, AFechaReferencia: TDateTime): Boolean;
begin
  Result := (AFechaHora >= EncodeDate(2000, 1, 1)) and
    (AFechaHora <= AFechaReferencia + EncodeTime(0, 5, 0, 0));
end;

function ValidarIdentidadImportacionInventario(
  const AIdentidad: TIdentidadImportacionInventario;
  const AInventario: TClaveInventario):
  TEstadoIdentidadImportacionInventario;
begin
  Result := eiiiCorrecta;
  if AIdentidad.TieneConflictos then
    Result := eiiiContradictoria
  else if (not AIdentidad.TieneEmpresa) or
          (not AIdentidad.TieneAlmacen) or
          (not AIdentidad.TieneSerie) or
          (not AIdentidad.TieneNumero) or
          (Trim(AIdentidad.Clave.Empresa) = '') or
          (Trim(AIdentidad.Clave.Almacen) = '') or
          (Trim(AIdentidad.Clave.Serie) = '') or
          (Trim(AIdentidad.Clave.Numero) = '') then
    Result := eiiiIncompleta
  else if (not SameText(
             Trim(AIdentidad.Clave.Empresa),
             Trim(AInventario.Empresa))) or
          (not SameText(
             Trim(AIdentidad.Clave.Almacen),
             Trim(AInventario.Almacen))) or
          (not SameText(
             Trim(AIdentidad.Clave.Serie),
             Trim(AInventario.Serie))) or
          (not SameText(
             Trim(AIdentidad.Clave.Numero),
             Trim(AInventario.Numero))) then
    Result := eiiiInventarioDistinto;
end;

procedure AcumularLineaImportacionInventario(
  var ADestino: TLineaImportacionInventario;
  const AOrigen: TLineaImportacionInventario);
begin
  ADestino.Cantidad := ADestino.Cantidad + AOrigen.Cantidad;
  if AOrigen.TienePrecioMedio then
  begin
    ADestino.PrecioMedioNuevo := AOrigen.PrecioMedioNuevo;
    ADestino.TienePrecioMedio := True;
  end;
  if AOrigen.TieneFechaRecuento and
     ((not ADestino.TieneFechaRecuento) or
      (AOrigen.FechaRecuento > ADestino.FechaRecuento)) then
  begin
    ADestino.FechaRecuento := AOrigen.FechaRecuento;
    ADestino.TieneFechaRecuento := True;
  end;
end;

function ConsolidarLineasSinIdentidadInventario(
  const ALineas: TLineasImportacionInventario):
  TLineasImportacionInventario;
var
  iExistente: Integer;
  iLinea: Integer;
  iResultado: Integer;
begin
  SetLength(Result, 0);
  for iLinea := 0 to High(ALineas) do
  begin
    iExistente := -1;
    if Trim(ALineas[iLinea].CodigoLinea) = '' then
      for iResultado := 0 to High(Result) do
        if (Trim(Result[iResultado].CodigoLinea) = '') and
           SameText(
             Result[iResultado].CodigoUnidad,
             ALineas[iLinea].CodigoUnidad) then
          iExistente := iResultado;
    if iExistente < 0 then
    begin
      iResultado := Length(Result);
      SetLength(Result, iResultado + 1);
      Result[iResultado] := ALineas[iLinea];
      iExistente := iResultado;
    end
    else
      AcumularLineaImportacionInventario(
        Result[iExistente],
        ALineas[iLinea]);
    if Trim(Result[iExistente].CodigoLinea) = '' then
      Result[iExistente].TextoOriginal :=
        Result[iExistente].CodigoUnidad + '=' +
        FloatToStr(Result[iExistente].Cantidad);
  end;
end;

function ConsolidarLineasNuevasInventario(
  const ALineas: TLineasImportacionInventario;
  const ANuevas: TStrings): TLineasImportacionInventario;
var
  iExistente: Integer;
  iLinea: Integer;
  iResultado: Integer;
begin
  SetLength(Result, 0);
  if ANuevas = nil then
    raise EArgumentNilException.Create('ANuevas');
  for iLinea := 0 to High(ALineas) do
    if ANuevas.IndexOfName(ALineas[iLinea].CodigoUnidad) >= 0 then
    begin
      iExistente := -1;
      for iResultado := 0 to High(Result) do
        if SameText(
             Result[iResultado].CodigoUnidad,
             ALineas[iLinea].CodigoUnidad) then
          iExistente := iResultado;
      if iExistente < 0 then
      begin
        iResultado := Length(Result);
        SetLength(Result, iResultado + 1);
        Result[iResultado] := ALineas[iLinea];
        Result[iResultado].CodigoLinea := '';
      end
      else
        AcumularLineaImportacionInventario(
          Result[iExistente],
          ALineas[iLinea]);
    end;
end;

constructor TOperacionesImportacionInventarioDataSet.Create(
  ALineas: TDataSet; ANuevas: TStrings;
  const AAlConfirmarLinea: TProc;
  const AConsolidar: TProc);
begin
  inherited Create;
  if ALineas = nil then
    raise EArgumentNilException.Create('ALineas');
  if ANuevas = nil then
    raise EArgumentNilException.Create('ANuevas');
  FLineas := ALineas;
  FNuevas := ANuevas;
  FAlConfirmarLinea := AAlConfirmarLinea;
  FConsolidar := AConsolidar;
end;

function TOperacionesImportacionInventarioDataSet.LocalizarLinea(
  const ACodigoLinea, ACodigoUnidad: string): Boolean;
begin
  if Trim(ACodigoLinea) = '' then
    Result := FLineas.Locate(
      CAMPO_UNIDAD_IMPORTACION,
      ACodigoUnidad,
      [loCaseInsensitive])
  else
  begin
    Result := FLineas.Locate(
      CAMPO_LINEA_IMPORTACION,
      ACodigoLinea,
      [loCaseInsensitive]);
    if Result then
      Result := SameText(
        FLineas.FieldByName(CAMPO_UNIDAD_IMPORTACION).AsString,
        ACodigoUnidad);
  end;
end;

procedure TOperacionesImportacionInventarioDataSet.IniciarEdicionLinea;
begin
  FLineas.Edit;
end;

procedure TOperacionesImportacionInventarioDataSet.EscribirCantidadFisica(
  ACantidad: Double);
begin
  FLineas.FieldByName(CAMPO_CANTIDAD_IMPORTACION).AsFloat := ACantidad;
end;

procedure TOperacionesImportacionInventarioDataSet.
  EscribirPrecioMedioNuevo(APrecio: Double);
begin
  FLineas.FieldByName(CAMPO_PRECIO_IMPORTACION).AsFloat := APrecio;
  FLineas.FieldByName(CAMPO_PRECIO_CORREGIDO).AsString := 'S';
end;

procedure TOperacionesImportacionInventarioDataSet.EscribirFechaRecuento(
  AFecha: TDateTime);
begin
  FLineas.FieldByName(CAMPO_FECHA_RECUENTO).AsDateTime := AFecha;
end;

procedure TOperacionesImportacionInventarioDataSet.UsarPrecioMedioHistorico;
begin
  FLineas.FieldByName(CAMPO_PRECIO_CORREGIDO).AsString := 'N';
end;

procedure TOperacionesImportacionInventarioDataSet.ConfirmarLinea;
begin
  if Assigned(FAlConfirmarLinea) then
    FAlConfirmarLinea();
  FLineas.Post;
end;

procedure TOperacionesImportacionInventarioDataSet.ConsolidarCambios;
begin
  if Assigned(FConsolidar) then
    FConsolidar();
end;

procedure TOperacionesImportacionInventarioDataSet.AnadirUnidadPendiente(
  const ATextoOriginal: string);
begin
  FNuevas.Add(ATextoOriginal);
end;

function CrearOperacionesImportacionInventario(
  ALineas: TDataSet; ANuevas: TStrings;
  const AAlConfirmarLinea: TProc;
  const AConsolidar: TProc): IOperacionesImportacionInventario;
begin
  Result := TOperacionesImportacionInventarioDataSet.Create(
    ALineas, ANuevas, AAlConfirmarLinea, AConsolidar);
end;

end.
