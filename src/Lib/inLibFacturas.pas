{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturas                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lógica de cálculo y persistencia de facturas.                             }
{    Totales de IVA, recargo de equivalencia y generación de líneas.           }
{******************************************************************************}
unit inLibFacturas;

interface

uses
  Uni, System.StrUtils, System.SysUtils, System.Classes, Data.DB, System.Math,
  Datasnap.DBClient, Datasnap.Provider;

const
  fnrofaclin = 'NUMERO_FAC_FACLIN';
  fserielin = 'SERIE_FAC_FACLIN';
  fnrolin = 'LINEA_FACLIN';
  fescon = 'ESCONSOLIDADA_FAC';
  fcodart = 'CODIGO_ART_FACLIN';
  fdesart = 'DESCRIPCION_ARTICULO_FACLIN';
  fcodprov = 'CODIGO_PRV_FACLIN';
  frazprov = 'RAZON_SOCIAL_PROVEEDOR_FACLIN';
  fpprov = 'ESPROVEEDORPRINCIPAL_FACLIN';
  fcodfam = 'CODIGO_FAM_FACLIN';
  fnomfam = 'NOMBRE_FAM_FACLIN';
  ffechentr = 'FECHA_ENTREGA_FACLIN';
  ftipocant = 'TIPO_CANTIDAD_ARTICULO_FACLIN';
  fimpcl = 'ESIMP_INCL_TARIFA_FACLIN';
  ftipiva = 'TIPO_IVA_ARTICULO_FACLIN';
  fdescripcion = 'DESCRIPCION_ARTICULO_FACLIN';
  fcodtariflin = 'CODIGO_TAR_FACLIN';
  fcant = 'CANTIDAD_FACLIN';
  fpreciosal = 'PRECIO_SALIDA_FACLIN';
  fprecultc = 'PRECIO_ULT_COMPRA_FACLIN';
  fpordto = 'PORCENTAJE_DTO_FACLIN';
  fdto = 'PRECIO_DTO_FACLIN';
  fpresiva = 'PRECIO_VENTA_SIVA_ARTICULO_FACLIN';
  fporiva = 'PORCENTAJE_IVA_FACLIN';
  fpreciva = 'PRECIO_VENTA_CIVA_ARTICULO_FACLIN';
  ftotciva = 'TOTAL_FACLIN';
  ftotsiva = 'TOTAL_FAC_SIVA_FACLIN';

  ffechfac = 'FECHA_FAC';
  fnrofac = 'NUMERO_FAC';
  fseriefac = 'SERIE_FAC';
  ftipofac = 'TIPO_FAC';
  ffasefac = 'FASE_FAC';
  fcodemp = 'CODIGO_EMP_FAC';
  fcodcli = 'CODIGO_CLI_FAC';
  factfij = 'ESVENTA_ACTIVO_FIJO_FAC';
  fcreart = 'ESCREARARTICULOS_FAC';
  fporivan = 'PORCENTAJE_IVAN_FAC';
  ftotivan = 'TOTAL_IVAN_FAC';
  fporren = 'PORCENTAJE_REN_FAC';
  ftotren = 'TOTAL_REN_FAC';
  ftotbasen = 'TOTAL_BASEI_IVAN_FAC';
  fporivar = 'PORCENTAJE_IVAR_FAC';
  ftotivar = 'TOTAL_IVAR_FAC';
  fporrer = 'PORCENTAJE_RER_FAC';
  ftotrer = 'TOTAL_RER_FAC';
  ftotbaser = 'TOTAL_BASEI_IVAR_FAC';
  fporivas = 'PORCENTAJE_IVAS_FAC';
  ftotivas = 'TOTAL_IVAS_FAC';
  fporres = 'PORCENTAJE_RES_FAC';
  ftotres = 'TOTAL_RES_FAC';
  ftotbases = 'TOTAL_BASEI_IVAS_FAC';
  fporivae = 'PORCENTAJE_IVAE_FAC';
  ftotivae = 'TOTAL_IVAE_FAC';
  fporree = 'PORCENTAJE_REE_FAC';
  ftotree = 'TOTAL_REE_FAC';
  ftotbasee = 'TOTAL_BASEI_IVAE_FAC';
  ftotallifac = 'TOTAL_LIQUIDO_FAC';
  fporirpf = 'PORCENTAJE_RETENCION_FAC';
  ftotirpf = 'TOTAL_RETENCION_FAC';
  ftotimp = 'TOTAL_IMPUESTOS_FAC';
  ftotbasefac = 'TOTAL_BASES_FAC';

type
  TTipoIVA = (tivaNormal, tivaReducido, tivaSuperReducido, tivaExento);

  TTotalesIVA = record
    BaseImponible: Currency;
    PorcentajeIVA: Currency;
    ImporteIVA: Currency;
    PorcentajeRE: Currency;
    ImporteRE: Currency;
  end;

  TTotalesFactura = record
    BaseNormal,
    BaseReducida,
    BaseSuper,
    BaseExenta: Currency;
    CuotaIVANormal,
    CuotaIVAReducida,
    CuotaIVASuper,
    CuotaIVAExenta: Currency;
    CuotaRENormal,
    CuotaREReducida,
    CuotaRESuper,
    CuotaREExenta: Currency;
    TotalBases: Currency;
    TotalImpuestos: Currency;
    TotalRetencion: Currency;
    TotalLiquido: Currency;
    TotalIVANormal: Currency;
    TotalIVAReducido: Currency;
    TotalIVASuperReducido: Currency;
    TotalIVAExento: Currency;
    TotalREcargo: Currency;
    TotalCantidades:Currency;
    IVAN: TTotalesIVA;
    IVAR: TTotalesIVA;
    IVAS: TTotalesIVA;
    IVAE: TTotalesIVA;

    TotalBruto: Currency;
    TotalDescuentosLineas: Currency;
  end;

  TConfiguracionFactura = record
    EsFacturaSimplificada: Boolean;
    EsRegimenAgricolaEmpresa: Boolean;
    EsRegimenAgricolaCliente: Boolean;
    EsIntracomunitario: Boolean;
    EsVentaActivoFijo: Boolean;
    AplicaRecargo: Boolean;
    AplicaRetencionesCliente: Boolean;
    AplicaRetencionesEmpresa: Boolean;
    IVAExento: Boolean;
    IRPFImpuestoIncluido: Boolean;
    IVARecargo: Boolean;
  end;

  TPorcentajesImpuestos = record
    IVANormal: Currency;
    IVAReducido: Currency;
    IVASuperReducido: Currency;
    IVAExento: Currency;
    REcNormal: Currency;
    REcReducido: Currency;
    REcSuperReducido: Currency;
    REcExento: Currency;
  end;

  TFacturaTotales = class;

  TLinFac = class
  private
    _unqryLin: TDataset;
    _unqryFac: TDataset;
    _sImpcl: string;
    _sTipIva: string;
    _sNumLin: String;
    _dPrecioSal: currency;
    _dPorDto: currency;
    _dDto: currency;
    _dPreSiva: currency;
    _dPreCiva: currency;
    _dPoriva: currency;
    _dCant: currency;
    _dTotCiva: currency;
    _dTotSiva: currency;
    _dPorIvaN: currency;
    _dPorIvaR: currency;
    _dPorIvaS: currency;
    _dPorIvaE: currency;
    _sMensajeError: string;
    function GetPrecioSal: Currency;
    procedure SetPrecioSal(const Value: Currency);
    function GetPorDto: Currency;
    procedure SetPorDto(const Value: Currency);
    function GetDto: Currency;
    procedure SetDto(const Value: Currency);
    function GetPreSiva: Currency;
    procedure SetPreSiva(const Value: Currency);
    function GetPreCiva: Currency;
    procedure SetPreCiva(const Value: Currency);
    function GetCant: Currency;
    procedure SetCant(const Value: Currency);
    function GetPorIva: Currency;
    procedure SetPorIva(const Value: Currency);
    function GetTotCiva: Currency;
    procedure SetTotCiva(const Value: Currency);
    function GetTotSiva: Currency;
    procedure SetTotSiva(const Value: Currency);
    function GetImpcl: String;
    procedure SetImpcl(const Value: String);
    function GetTipoIVa: String;
    procedure SetTipoIva(const Value: String);
  public
    Property PrecioSal: Currency read GetPrecioSal write SetPrecioSal;
    Property PorDto: Currency read GetPorDto write SetPorDto;
    Property Dto: Currency read GetDto write SetDto;
    Property PorIva: Currency read GetPorIva write SetPorIva;
    Property TipoIva: String read GetTipoIVa write SetTipoIva;
    Property PreSiva: Currency read GetPreSiva write SetPreSiva;
    Property PreCiva: Currency read GetPreCiva write SetPreCiva;
    Property Cant: Currency read GetCant write SetCant;
    Property TotCiva: Currency read GetTotCiva write SetTotCiva;
    Property TotSiva: Currency read GetTotSiva write SetTotSiva;
    Property Impcl: String read GetImpcl write SetImpcl;
    Property MensajeError: String read _sMensajeError;
  public
    constructor Create(AUnqryLin: TDataset); overload;
    constructor Create(AUnqryLin, AUnqryFac: TDataset;
                       bCalcularFactura:boolean = false); overload;
    procedure CopyToDataSetLin;
    procedure CopyToDataSetFac;
    procedure CopyToObjectLin;
    procedure CopyToObjectFac;
    procedure SetInit(AUnqryLin: TDataset);
    procedure CalcularLinea;
    function ValidarDatos: Boolean;
    function EsDevolucion: Boolean;
  end;

  TFacturaTotales = class
  private
    _conexion: TUniConnection;
    _unqryFac: TDataset;
    _unqryLineas: TDataset;
    _totales: TTotalesFactura;
    _configuracion: TConfiguracionFactura;
    _porcentajes: TPorcentajesImpuestos;
    _dPorRetencion: Currency;
    _fechaFactura: TDateTime;
    _codigoEmpresa: string;
    _grupoZonaIVA: string;
    _codigoIVA: string;
    _mensajeError: string;
    _LineaenEdicion:TLinFac;
    function LineaActualPendienteDeResolver: Boolean;
    procedure InicializarTotales;
    procedure InicializarConfiguracion;
    procedure LeerDatosFactura;
    procedure LeerPorcentajesDesdeFactura;
    procedure AplicarReglas;
    procedure RecorrerYCalcularLineasConClientDataSet;
    procedure AcumularTotalesPorTipoIVA(ALinea: TLinFac);
    procedure CalcularTotalesGenerales;
    procedure CalcularRetenciones;
    procedure ValidarConfiguracion;
    procedure VerificarYCompletarDatosEmpresa;
    procedure CargarConfiguracionIVA(sGrupoZona: string);
    procedure VerificarYCompletarDatosCliente;
    function ObtenerPorcentajePorTipo(tipo: string): Currency;
    function ObtenerPorcentajeREPorTipo(tipo: string): Currency;
    function BuscarPorcenRetencion(CodEmpresa: string): Currency;
    function BuscarDatosIVAAgricola(CodEmpresa: string): Boolean;
  public
    FTieneLineasNegativas:Boolean;
    constructor Create(AConexion: TUniConnection;
                       AUnqryFac: TDataset;
                       unqryLineas: TDataset;
                       LineaEnEdicion:TLinFac = nil);
    function ProcesarFacturaCompleta: Boolean;
    procedure CalcularTotalesFactura;
    procedure ActualizarTotalesEnDataSet;
    function ValidarFactura: Boolean;
    property Totales: TTotalesFactura read _totales;
    property Configuracion: TConfiguracionFactura read _configuracion;
    property Porcentajes: TPorcentajesImpuestos read _porcentajes;
    property PorcentajeRetencion: Currency read _dPorRetencion write _dPorRetencion;
    property MensajeError: string read _mensajeError;
    property Cabecera:TDataSet read _unqryFac;
    property Lineas:TDataset read _unqryLineas;
  end;
  function IfThen(AValue: Boolean;
                const ATrue: string;
                AFalse: string = ''): string;


implementation

uses inLibLog, inLibMsg;

function IfThen(AValue: Boolean;
                const ATrue: string;
                AFalse: string = ''): string;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

{ TLinFac - Implementación completa }

constructor TLinFac.Create(AUnqryLin: TDataset);
begin
  inherited Create;
  _unqryLin := AUnqryLin;
  Self.CopyToObjectLin;
end;

constructor TLinFac.Create(AUnqryLin, AUnqryFac: TDataset;
                           bCalcularFactura:boolean = false);
begin
  inherited Create;
  _unqryLin := AUnqryLin;
  _unqryFac := AUnqryFac;
  _sMensajeError := '';
  Self.CopyToObjectLin;
  Self.CopyToObjectFac;
end;

function TLinFac.ValidarDatos: Boolean;
begin
  Result := True;
  _sMensajeError := '';
  if (_dPorIva < 0) or (_dPorIva > 100) then
  begin
    _sMensajeError := SErrorPorcentajeIvaFueraRango;
    raise Exception.Create(_sMensajeError);
    Result := False;
    Exit;
  end;
  if (_dPreSiva < 0) or (_dPreCiva < 0) then
  begin
    _sMensajeError := SErrorPrecioFacturaNegativo;
    raise Exception.Create(_sMensajeError);
    Result := False;
    Exit;
  end;
end;

function TLinFac.EsDevolucion: Boolean;
begin
  Result := _dCant < 0;
end;

procedure TLinFac.CalcularLinea;
begin
  if not ValidarDatos then
    raise Exception.Create(_sMensajeError);
  if (SameText(_sImpcl, 'S')) then
  begin
    // Precio con IVA incluido
    if (_dPreCiva = 0) and (_dPrecioSal <> 0) then
    begin
      // Línea nueva: calcular precio desde PrecioSalida y descuento porcentual
      _dDto    := _dPrecioSal * (_dPorDto / 100);
      _dPreCiva := _dPrecioSal - _dDto;
    end
    else if (_dPrecioSal <> 0) then
    begin
      // Línea existente: recalcular descuento desde precio actual
      _dDto    := _dPrecioSal - _dPreCiva;
      _dPorDto := (_dDto / _dPrecioSal) * 100;
    end;
    if _dPorIva = 0 then
      _dPreSiva := _dPreCiva
    else
      _dPreSiva := _dPreCiva / (1 + _dPorIva / 100);
    _dTotSiva := _dPreSiva * _dCant;
    _dTotCiva := _dPreCiva * _dCant;
  end
  else
  begin
    // Precio sin IVA
    if (_dPreSiva = 0) and (_dPrecioSal <> 0) then
    begin
      _dDto    := _dPrecioSal * (_dPorDto / 100);
      _dPreSiva := _dPrecioSal - _dDto;
    end
    else if (_dPrecioSal <> 0) then
    begin
      _dDto    := _dPrecioSal - _dPreSiva;
      _dPorDto := (_dDto / _dPrecioSal) * 100;
    end;

    _dPreCiva := _dPreSiva * (1 + _dPorIva / 100);
    _dTotCiva := _dPreCiva * _dCant;
    _dTotSiva := _dPreSiva * _dCant;
  end;
end;

procedure TLinFac.CopyToDataSetLin;
begin
  if not Assigned(_unqryLin) then
    Exit;
  with _unqryLin do
  begin
    if State = dsBrowse then Edit;
    FieldByName(fcant).AsFloat := _dCant;
    FieldByName(fpreciosal).AsFloat := _dPrecioSal;
    FieldByName(fPorDto).AsFloat := _dPorDto;
    FieldByName(fDto).AsFloat := _dDto;
    FieldByName(fImpcl).AsString := _sImpcl;
    FieldByName(fTipIVa).AsString := _sTipIva;
    FieldByName(fPorIva).AsFloat := _dPorIVa;
    FieldByName(fPreSiva).AsFloat := _dPreSiva;
    FieldByName(fPreCiva).AsFloat := _dPreCiva;
    FieldByName(fTotCiva).AsFloat := _dTotCiva;
    FieldByName(fTotSiva).AsFloat := _dTotSiva;
  end;
end;

procedure TLinFac.CopyToDataSetFac;
begin
  // Implementar si es necesario para actualizar campos de la factura
end;

procedure TLinFac.CopyToObjectLin;
begin
  with _unqryLin do
  begin
    _sNumLin := FieldByName(fnrolin).AsString;
    _dCant := FieldByName(fcant).AsFloat;
    if FieldByName(fImpcl).AsString = '' then
      _sImpcl := 'S'
    else
      _sImpcl := FieldByName(fImpcl).AsString;
    _sTipIVA := FieldByName(fTipIva).AsString;
    _dPorIVa := FieldByName(fPorIva).AsFloat;
    _dPrecioSal := FieldByName(fpreciosal).AsFloat;
    _dPorDto := FieldByName(fPorDto).AsFloat;
    _dDto := FieldByName(fDto).AsFloat;
    _dPreSiva := FieldByName(fPreSiva).AsFloat;
    _dPreCiva := FieldByName(fPreCiva).AsFloat;
    _dTotCiva := FieldByName(fTotCiva).AsFloat;
    _dTotSiva := FieldByName(fTotSiva).AsFloat;
  end;
end;

procedure TLinFac.CopyToObjectFac;
begin
  //if not Assigned(_unqryFac) then Exit;
  with _unqryFac do
  begin
    _dPorIvaN := FieldByName(fPorIvaN).AsFloat;
    _dPorIvaR := FieldByName(fPorIVAR).AsFloat;
    _dPorIvaS := FieldByName(fPorIVAS).AsFloat;
    _dPorIVAE := FieldByName(fPorIVAE).AsFloat;
  end;
end;

procedure TLinFac.SetInit(AUnqryLin: TDataset);
begin
  _unqryLin := AUnqryLin;
end;

// Getters y Setters
function TLinFac.GetCant: Currency;
begin
  Result := _dCant;
end;

procedure TLinFac.SetCant(const Value: Currency);
begin
  _dCant := Value;
  if _dPreSiva <> 0 then
    _dTotSiva := _dCant * _dPreSiva;
  if _dPreCiva <> 0 then
    _dTotCiva := _dCant * _dPreCiva;
end;

function TLinFac.GetDto: Currency;
begin
  Result := _dDto;
end;

procedure TLinFac.SetDto(const Value: Currency);
var
  dPrecioFinal:Currency;
begin
  _dDto := Value;
  if (_dPrecioSal <> 0) then
  begin
    _dPorDto := (_dDto / _dPrecioSal) * 100;
    dPrecioFinal := _dPrecioSal - _dDto;
    if SameText(Impcl, 'S') then
    begin
      SetPreCiva(dPrecioFinal); //recalculo el precio con y sin IVA
    end
    else
    begin
      SetPreSiva(dPrecioFinal);
    end;
  end;
end;

function TLinFac.GetImpcl: String;
begin
  Result := _sImpcl;
end;

procedure TLinFac.SetImpcl(const Value: String);
begin
  _sImpcl := Value;
end;

function TLinFac.GetPorDto: Currency;
begin
  Result := _dPorDto;
end;

procedure TLinFac.SetPorDto(const Value: Currency);
var
  dPrecioFinal:Currency;
begin
  _dPorDto := Value;
  if _dPrecioSal <> 0 then
  begin
    _dDto := _dPrecioSal * (_dPorDto / 100);
    dPrecioFinal := _dPrecioSal - _dDto;
    if SameText(Impcl, 'S') then
    begin
      SetPreCiva(dPrecioFinal); //recalculo el precio con y sin IVA
    end
    else
    begin
      SetPreSiva(dPrecioFinal);
    end;
  end;
end;

function TLinFac.GetPorIva: Currency;
begin
  Result := _dPorIva;
end;

procedure TLinFac.SetPorIva(const Value: Currency);
begin
  _dPorIVa := Value;
end;

function TLinFac.GetPrecioSal: Currency;
begin
  Result := _dPrecioSal;
end;

procedure TLinFac.SetPrecioSal(const Value: Currency);
var
  dPrecioFinal: Currency;
begin
  _dPrecioSal := Value;
  SetPorDto(_dPorDto);   //recalculo el dto
  dPrecioFinal := _dPrecioSal - _dDto;
  if SameText(Impcl, 'S') then
  begin
    SetPreCiva(dPrecioFinal); //recalculo el precio con y sin IVA
  end
  else
  begin
    SetPreSiva(dPrecioFinal);
  end;
end;

function TLinFac.GetPreCiva: Currency;
begin
  Result := _dPreCiva;
end;

procedure TLinFac.SetPreCiva(const Value: Currency);
begin
  _dPreCiva := Value;
  _dPreSiva := _dPreCiva / (1 + _dPorIva/100);
  if _dCant <> 0 then
  begin
    _dTotCiva := _dCant * _dPreCiva;
    _dTotSiva := _dCant * _dPreSiva;
  end;
end;

function TLinFac.GetPreSiva: Currency;
begin
  Result := _dPreSiva;
end;

procedure TLinFac.SetPreSiva(const Value: Currency);
begin
  _dPreSiva := Value;
  _dPreCiva := _dPreSiva * (1 + _dPorIva/100);
  if _dCant <> 0 then
  begin
    _dTotSiva := _dCant * _dPreSiva;
    _dTotCiva := _dCant * _dPreCiva;
  end;
end;

function TLinFac.GetTipoIVa: String;
begin
  Result := _sTipIva;
end;

procedure TLinFac.SetTipoIva(const Value: String);
var
  dPorcen: Currency;
begin
  _sTipIVa := Value;
  dPorcen := 0;
  if Assigned(_unqryFac) then
  begin
    with _unqryFac do
    begin
      case IndexStr(_sTipIVA, ['N', 'R', 'S', 'E']) of
        0: if FindField(fPorIvaN) <> nil then
             dPorcen := FieldByName(fPorIvaN).AsCurrency;
        1: if FindField(fPorIVAR) <> nil then
             dPorcen := FieldByName(fPorIVAR).AsCurrency;
        2: if FindField(fPorIVAS) <> nil then
             dPorcen := FieldByName(fPorIVAS).AsCurrency;
        3: if FindField(fPorIVAE) <> nil then
             dPorcen := FieldByName(fPorIVAE).AsCurrency;
      end;
    end;
  end;
  Self.PorIva := dPorcen;
end;

function TLinFac.GetTotCiva: Currency;
begin
  Result := _dTotCiva;
end;

procedure TLinFac.SetTotCiva(const Value: Currency);
begin
  _dTotCiva := Value;
end;

function TLinFac.GetTotSiva: Currency;
begin
  Result := _dTotSiva;
end;

procedure TLinFac.SetTotSiva(const Value: Currency);
begin
  _dTotSiva := Value;
end;

{ TFacturaTotales - Implementación completa }

constructor TFacturaTotales.Create(AConexion: TUniConnection;
                                   AUnqryFac: TDataset;
                                   unqryLineas: TDataset;
                                   LineaEnEdicion:TLinFac = nil);
begin
  inherited Create;
  _conexion := AConexion;
  _unqryFac := AUnqryFac;
  _unqryLineas := unqryLineas;
  _LineaEnEdicion := LineaEnEdicion;
  //_unqryLineasTemp := nil;
  _dPorRetencion := 0;
  _mensajeError := '';
  //_lineaEnEdicion := '';
  // _excluirLineaEnEdicion := False;

  InicializarTotales;
  InicializarConfiguracion;

  //ProcesarFacturaCompleta;
end;

procedure TFacturaTotales.InicializarTotales;
begin
  FillChar(_totales, SizeOf(_totales), 0);
end;

procedure TFacturaTotales.InicializarConfiguracion;
begin
  FillChar(_configuracion, SizeOf(_configuracion), 0);
  FillChar(_porcentajes, SizeOf(_porcentajes), 0);
  _grupoZonaIVA := '';
  _codigoIVA := '';
  _codigoEmpresa := '';
  _fechaFactura := 0;
  _mensajeError := '';
end;

procedure TFacturaTotales.LeerDatosFactura;
begin
  with _unqryFac do
  begin
    _fechaFactura      := FieldByName('FECHA_FAC').AsDateTime;
    _codigoEmpresa := FieldByName('CODIGO_EMP_FAC').AsString;
    _configuracion.EsFacturaSimplificada :=
                 SameText(FieldByName('TIPO_FAC').AsString, 'SIMPLIFICADA');
    VerificarYCompletarDatosEmpresa;
    VerificarYCompletarDatosCliente;
    _configuracion.EsRegimenAgricolaEmpresa :=
      (FieldByName('ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString = 'S');
    _configuracion.EsRegimenAgricolaCliente :=
      (FieldByName('ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString = 'S');
    _configuracion.EsIntracomunitario       :=
             (FieldByName('ESINTRACOMUNITARIO_CLIENTE_FAC').AsString = 'S');
    _configuracion.EsVentaActivoFijo        :=
                    (FieldByName('ESVENTA_ACTIVO_FIJO_FAC').AsString = 'S');
    _configuracion.AplicaRetencionesCliente :=
                  (FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString = 'S');
    _configuracion.AplicaRetencionesEmpresa :=
                  (FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString = 'S');
    _configuracion.IVAExento  :=
                   (FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString = 'S');
    _configuracion.IVARecargo :=
                  (FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString = 'S');
    if FindField('ESIRPF_IMP_INCL_ZONA_IVA_FAC') <> nil then
       _configuracion.IRPFImpuestoIncluido :=
                (FieldByName('ESIRPF_IMP_INCL_ZONA_IVA_FAC').AsString = 'S')
    else
       _configuracion.IRPFImpuestoIncluido := False;
    if SameText(FindField('ESAPLICA_RE_ZONA_IVA_FAC').AsString, 'N') then
       _configuracion.AplicaRecargo := false;
    _grupoZonaIVA := FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString;
    _CodigoIVA    := FieldByName('CODIGO_IVA_FAC').AsString;
    _dPorRetencion := FieldByName('PORCENTAJE_RETENCION_FAC').AsFloat;
  end;
  LeerPorcentajesDesdeFactura;
end;

procedure TFacturaTotales.LeerPorcentajesDesdeFactura;
begin
  if not Assigned(_unqryFac) or not _unqryFac.Active then
    Exit;
  with _unqryFac do
  begin
    _porcentajes.IVANormal := FieldByName('PORCENTAJE_IVAN_FAC').AsFloat;
    _porcentajes.IVAReducido := FieldByName('PORCENTAJE_IVAR_FAC').AsFloat;
    _porcentajes.IVASuperReducido := FieldByName('PORCENTAJE_IVAS_FAC').AsFloat;
    _porcentajes.IVAExento := FieldByName('PORCENTAJE_IVAE_FAC').AsFloat;
    // Leer recargos de equivalencia
    _porcentajes.REcNormal := FieldByName('PORCENTAJE_REN_FAC').AsFloat;
    _porcentajes.REcReducido := FieldByName('PORCENTAJE_RER_FAC').AsFloat;
    _porcentajes.REcSuperReducido := FieldByName('PORCENTAJE_RES_FAC').AsFloat;
    _porcentajes.REcExento := FieldByName('PORCENTAJE_REE_FAC').AsFloat;
  end;
end;

procedure TFacturaTotales.CargarConfiguracionIVA(sGrupoZona: string);
var
  Qry: TUniQuery;
begin
  if sGrupoZona = '' then Exit;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := _conexion;
    Qry.SQL.Text := 'SELECT * FROM vi_ivas ' +
                    ' WHERE IVA_IVAGRP = :grupo ' +
                    '   AND FECHA_DESDE_IVA <= :fecha ' +
                    '   AND (FECHA_HASTA_IVA >= :fecha OR FECHA_HASTA_IVA IS ' +
                    'NULL)';
    Qry.ParamByName('grupo').AsString := sGrupoZona;
    Qry.ParamByName('fecha').AsDateTime := _fechaFactura;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      if _unqryFac.State = dsBrowse then _unqryFac.Edit;
      // Asignación al DataSet de la Factura (Persistencia)
      _unqryFac.FieldByName('PORCENTAJE_IVAN_FAC').AsFloat :=
        Qry.FieldByName('PORCENTAJE_NORMAL_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_REN_FAC').AsFloat  :=
        Qry.FieldByName('PORCENTAJE_NORMAL_RE_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_IVAR_FAC').AsFloat :=
        Qry.FieldByName('PORCENTAJE_REDUCIDO_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_RER_FAC').AsFloat  :=
        Qry.FieldByName('PORCENTAJE_REDUCIDO_RE_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_IVAS_FAC').AsFloat :=
        Qry.FieldByName('PORCENTAJE_SUPERREDUCIDO_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_RES_FAC').AsFloat  :=
        Qry.FieldByName('PORCENTAJE_SUPERREDUCIDO_RE_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_IVAE_FAC').AsFloat :=
        Qry.FieldByName('PORCENTAJE_EXENTO_IVA').AsFloat;
      _unqryFac.FieldByName('PORCENTAJE_REE_FAC').AsFloat  :=
        Qry.FieldByName('PORCENTAJE_EXENTO_RE_IVA').AsFloat;
      _unqryFac.FieldByName('ESIRPF_IMP_INCL_ZONA_IVA_FAC').AsString :=
        Qry.FieldByName('ESIRPF_IMP_INCL_IVA_IVAGRP').AsString;
      _unqryFac.FieldByName('ESAPLICA_RE_ZONA_IVA_FAC').AsString     :=
        Qry.FieldByName('ESAPLICA_RE_IVA_IVAGRP').AsString;
      _unqryFac.FieldByName('CODIGO_IVA_FAC').AsString               :=
        Qry.FieldByName('CODIGO_IVA').AsString;
      _unqryFac.FieldByName('ESIVAAGRICOLA_ZONA_IVA_FAC').AsString   :=
        Qry.FieldByName('ESIVAAGRICOLA_IVA_IVAGRP').AsString;
      // Actualizar también la estructura interna de trabajo (_configuracion y
      // _porcentajes)
      _configuracion.AplicaRecargo        :=
        (Qry.FieldByName('ESAPLICA_RE_IVA_IVAGRP').AsString = 'S');
      _configuracion.IRPFImpuestoIncluido :=
        (Qry.FieldByName('ESIRPF_IMP_INCL_IVA_IVAGRP').AsString = 'S');
      _grupoZonaIVA                       := sGrupoZona;
      _codigoIVA := Qry.FieldByName('CODIGO_IVA').AsString;
      // Sincroniza _porcentajes con los nuevos valores del DataSet
      LeerPorcentajesDesdeFactura;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TFacturaTotales.AplicarReglas;
begin
  // 1. Régimen Especial Agrícola Empresa
  if _configuracion.EsRegimenAgricolaEmpresa then
  begin
    _configuracion.AplicaRetencionesEmpresa := True;
    _configuracion.IVARecargo := False;
    if BuscarDatosIVAAgricola(_codigoEmpresa) then
    begin
    end;
  end;
  // 2. Intracomunitario
  if _configuracion.EsIntracomunitario then
  begin
    _configuracion.IVAExento := True;
    _configuracion.AplicaRetencionesCliente := False;
    _configuracion.EsRegimenAgricolaCliente := False;
  end;
  // 3. Venta Activo Fijo + REAGP Empresa
  if ((_configuracion.EsVentaActivoFijo) and
      (_configuracion.EsRegimenAgricolaEmpresa)) then
  begin
    _configuracion.IVAExento := True;
  end;
  // 4. REAGP Empresa + REAGP Cliente
  if ((_configuracion.EsRegimenAgricolaEmpresa) and
      (_configuracion.EsRegimenAgricolaCliente)) then
  begin
    _configuracion.AplicaRetencionesCliente := True;
    _configuracion.IVAExento := True;
  end;
  // 5. REAGP Empresa + Cliente Normal sin retenciones
  if _configuracion.EsRegimenAgricolaEmpresa and
     not _configuracion.EsRegimenAgricolaCliente and
     not _configuracion.AplicaRetencionesCliente then
  begin
    _configuracion.IVAExento := True;
  end;
  if _configuracion.IVAExento then
  begin
    _porcentajes.IVANormal        := _porcentajes.IVAExento;
    _porcentajes.IVAReducido      := _porcentajes.IVAExento;
    _porcentajes.IVASuperReducido := _porcentajes.IVAExento;
    // Anulamos cualquier Recargo de Equivalencia
    _porcentajes.REcNormal        := 0;
    _porcentajes.REcReducido      := 0;
    _porcentajes.REcSuperReducido := 0;
    _porcentajes.REcExento        := 0;
  end;
end;

function TFacturaTotales.ObtenerPorcentajePorTipo(tipo: string): Currency;
begin
  case IndexStr(tipo, ['N', 'R', 'S', 'E']) of
    0: Result := _porcentajes.IVANormal;
    1: Result := _porcentajes.IVAReducido;
    2: Result := _porcentajes.IVASuperReducido;
    3: Result := _porcentajes.IVAExento;
  else
    Result := _porcentajes.IVANormal;
  end;
end;

function TFacturaTotales.ObtenerPorcentajeREPorTipo(tipo: string): Currency;
var
  sNif, sRazon, sDir: string;
  tieneDatosMinimos: Boolean;
begin
  // Primero verificamos los datos mínimos del cliente
  sNif   := Trim(_unqryFac.FieldByName('NIF_CLIENTE_FAC').AsString);
  sRazon := Trim(_unqryFac.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString);
  sDir   := Trim(_unqryFac.FieldByName('DIRECCION1_CLIENTE_FAC').AsString);
  tieneDatosMinimos := (sNif <> '') and (sRazon <> '') and (sDir <> '');
  // Si es Simplificada O no tiene datos mínimos O no aplica recargo por config:
  // devolvemos 0
  if _configuracion.EsFacturaSimplificada or
     (not tieneDatosMinimos) or
     not (_configuracion.AplicaRecargo and _configuracion.IVARecargo) then
  begin
    Result := 0;
  end
  else
  begin
    case IndexStr(tipo, ['N', 'R', 'S', 'E']) of
      0: Result := _porcentajes.REcNormal;
      1: Result := _porcentajes.REcReducido;
      2: Result := _porcentajes.REcSuperReducido;
      3: Result := _porcentajes.REcExento;
    else
      Result := 0;
    end;
  end;
end;

function TFacturaTotales.LineaActualPendienteDeResolver: Boolean;
var
  CampoCodigo: TField;
  CampoDescripcion: TField;
  CampoNumeroAtributos: TField;
  CampoSku: TField;
begin
  Result := False;
  if Assigned(_unqryLineas) and _unqryLineas.Active and
     (_unqryLineas.State in dsEditModes) then
  begin
    CampoCodigo := _unqryLineas.FindField(fcodart);
    CampoDescripcion := _unqryLineas.FindField(fdesart);
    CampoNumeroAtributos := _unqryLineas.FindField(
      'NUM_ATRIBUTOS_REQ_FACTURA_LINEA');
    CampoSku := _unqryLineas.FindField('CODIGO_UNIDAD_FACLIN');
    if Assigned(CampoCodigo) and Assigned(CampoDescripcion) then
      Result := (Trim(CampoCodigo.AsString) <> '') and
                (Trim(CampoDescripcion.AsString) = '');
    if not Result and Assigned(CampoNumeroAtributos) and Assigned(CampoSku) then
      Result := (CampoNumeroAtributos.AsInteger > 0) and
                (Pos('/', Trim(CampoSku.AsString)) = 0);
  end;
end;

function TFacturaTotales.ProcesarFacturaCompleta: Boolean;
begin
  _mensajeError := '';
  Result := True;
  // La búsqueda puede escribir el artículo antes de que el editor termine de
  // resolver la descripción o el SKU con atributos. No se fuerza el Post de
  // esa línea intermedia; el evento final volverá a solicitar el cálculo.
  if not LineaActualPendienteDeResolver then
  begin
    try
      // Leer configuración de la factura
      LeerDatosFactura;
      // Aplicar reglas de negocio
      AplicarReglas;
      // Validar configuración
      ValidarConfiguracion;
      // Procesar líneas y calcular totales
      RecorrerYCalcularLineasConClientDataSet;
      CalcularTotalesFactura;
      // Actualizar en la base de datos
      if _unqryFac.State <> dsEdit then
        _unqryFac.Edit;
      ActualizarTotalesEnDataSet;
    except
      on E: Exception do
      begin
        _mensajeError := E.Message;
        // Se registra la causa original; el llamante decide si aborta
        if Assigned(Log) then
          Log.LogError('TFacturaTotales.ProcesarFacturaCompleta (' +
                       E.ClassName + '): ' + E.Message);
        Result := False;
      end;
    end;
  end;
end;

procedure TFacturaTotales.AcumularTotalesPorTipoIVA(ALinea: TLinFac);
var
  porcentajeIVA, porcentajeRE: Currency;
  baseImponible, importeIVA, importeRE: Currency;
  totalLineaCIVA: Currency;
begin
  // 1. Calcular base imponible y total de la línea forzando el redondeo a 2
  // decimales
  baseImponible := SimpleRoundTo(ALinea.TotSiva, -2);
  totalLineaCIVA := SimpleRoundTo(ALinea.TotCiva, -2);
  // Obtener porcentajes según el tipo de IVA
  porcentajeIVA := ObtenerPorcentajePorTipo(ALinea.TipoIva);
  porcentajeRE := ObtenerPorcentajeREPorTipo(ALinea.TipoIva);
  // 2. Calcular importes aplicando la regla contable de diferencia si tiene IVA
  // incluido
  if SameText(ALinea.Impcl, 'S') then
  begin
    importeIVA := totalLineaCIVA - baseImponible;
    importeRE := SimpleRoundTo(baseImponible * (porcentajeRE / 100), -2);
  end
  else
  begin
    importeIVA := SimpleRoundTo(baseImponible * (porcentajeIVA / 100), -2);
    importeRE := SimpleRoundTo(baseImponible * (porcentajeRE / 100), -2);
  end;
  if ALinea._dCant < 0 then
    Self.FTieneLineasNegativas := True;
  _totales.TotalCantidades := _totales.TotalCantidades + ALinea.Cant;
  _totales.TotalBruto := _totales.TotalBruto + (ALinea.PrecioSal * ALinea.Cant);
  _totales.TotalDescuentosLineas := _totales.TotalDescuentosLineas +
                                    (ALinea.Dto * ALinea.Cant);
  case IndexStr(ALinea.TipoIva, ['N', 'R', 'S', 'E']) of
    0: // IVA Normal
      begin
        _totales.IVAN.BaseImponible :=
          _totales.IVAN.BaseImponible + baseImponible;
        _totales.IVAN.PorcentajeIVA := porcentajeIVA;
        _totales.IVAN.PorcentajeRE := porcentajeRE;
        _totales.IVAN.ImporteIVA := _totales.IVAN.ImporteIVA + importeIVA;
        _totales.IVAN.ImporteRE := _totales.IVAN.ImporteRE + importeRE;
      end;
    1: // IVA Reducido
      begin
        _totales.IVAR.BaseImponible :=
          _totales.IVAR.BaseImponible + baseImponible;
        _totales.IVAR.PorcentajeIVA := porcentajeIVA;
        _totales.IVAR.PorcentajeRE := porcentajeRE;
        _totales.IVAR.ImporteIVA := _totales.IVAR.ImporteIVA + importeIVA;
        _totales.IVAR.ImporteRE := _totales.IVAR.ImporteRE + importeRE;
      end;
    2: // IVA SuperReducido
      begin
        _totales.IVAS.BaseImponible :=
          _totales.IVAS.BaseImponible + baseImponible;
        _totales.IVAS.PorcentajeIVA := porcentajeIVA;
        _totales.IVAS.PorcentajeRE := porcentajeRE;
        _totales.IVAS.ImporteIVA := _totales.IVAS.ImporteIVA + importeIVA;
        _totales.IVAS.ImporteRE := _totales.IVAS.ImporteRE + importeRE;
      end;
    3: // IVA Exento
      begin
        _totales.IVAE.BaseImponible :=
          _totales.IVAE.BaseImponible + baseImponible;
        _totales.IVAE.PorcentajeIVA := porcentajeIVA;
        _totales.IVAE.PorcentajeRE := porcentajeRE;
        _totales.IVAE.ImporteIVA := _totales.IVAE.ImporteIVA + importeIVA;
        _totales.IVAE.ImporteRE := _totales.IVAE.ImporteRE + importeRE;
      end;
  end;
end;

procedure TFacturaTotales.CalcularTotalesGenerales;
begin
  _totales.TotalBases := _totales.IVAN.BaseImponible +
                         _totales.IVAR.BaseImponible +
                         _totales.IVAS.BaseImponible +
                         _totales.IVAE.BaseImponible;
  _totales.TotalIVANormal := _totales.IVAN.ImporteIVA;
  _totales.TotalIVAReducido := _totales.IVAR.ImporteIVA;
  _totales.TotalIVASuperReducido := _totales.IVAS.ImporteIVA;
  _totales.TotalIVAExento := _totales.IVAE.ImporteIVA;
  _totales.TotalREcargo := _totales.IVAN.ImporteRE + _totales.IVAR.ImporteRE +
                          _totales.IVAS.ImporteRE + _totales.IVAE.ImporteRE;
  _totales.TotalImpuestos := _totales.TotalIVANormal +
                             _totales.TotalIVAReducido +
                             _totales.TotalIVASuperReducido +
                             _totales.TotalIVAExento +
                             _totales.TotalREcargo;
end;

procedure TFacturaTotales.CalcularRetenciones;
var
  baseCalculo: Currency;
  sNif, sRazon, sDir: string;
  tieneDatosMinimos: Boolean;
begin
  if _configuracion.EsFacturaSimplificada then
  begin
    _totales.TotalRetencion := 0;
    Exit;
  end;
  sNif   := Trim(_unqryFac.FieldByName('NIF_CLIENTE_FAC').AsString);
  sRazon := Trim(_unqryFac.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString);
  sDir   := Trim(_unqryFac.FieldByName('DIRECCION1_CLIENTE_FAC').AsString);
  tieneDatosMinimos := (sNif <> '') and (sRazon <> '') and (sDir <> '');
  if not tieneDatosMinimos then
  begin
    _totales.TotalRetencion := 0;
    // _mensajeError := 'Cliente no cualificado: faltan datos fiscales.
    //                   IRPF no aplicado.';
    Exit;
  end;
  if not (_configuracion.AplicaRetencionesCliente and
          _configuracion.AplicaRetencionesEmpresa) then
  begin
    _totales.TotalRetencion := 0;
    Exit;
  end;
  if (_configuracion.EsVentaActivoFijo and
      _configuracion.EsRegimenAgricolaEmpresa) then
  begin
    _dPorRetencion := 0;
    _totales.TotalRetencion := 0;
    Exit;
  end;
  if (_dPorRetencion = 0) and (_configuracion.AplicaRetencionesCliente and
          _configuracion.AplicaRetencionesEmpresa) then
  begin
    _dPorRetencion := BuscarPorcenRetencion(_codigoEmpresa);
  end;
  if _configuracion.IRPFImpuestoIncluido then
    baseCalculo := _totales.TotalBases + _totales.TotalImpuestos
  else
    baseCalculo := _totales.TotalBases;
  _totales.TotalRetencion := baseCalculo * (_dPorRetencion / 100);
end;

procedure TFacturaTotales.CalcularTotalesFactura;
begin
  CalcularTotalesGenerales;
  CalcularRetenciones;
  _totales.TotalLiquido := _totales.TotalBases +
                           _totales.TotalImpuestos -
                           _totales.TotalRetencion;
end;

procedure TFacturaTotales.ActualizarTotalesEnDataSet;
begin
  with _unqryFac do
  begin
    if State = dsBrowse then Edit;
    // Bases imponibles
    FieldByName('TOTAL_BASEI_IVAN_FAC').AsFloat :=
                                         _totales.IVAN.BaseImponible;
    FieldByName('TOTAL_BASEI_IVAR_FAC').AsFloat :=
                                         _totales.IVAR.BaseImponible;
    FieldByName('TOTAL_BASEI_IVAS_FAC').AsFloat :=
                                         _totales.IVAS.BaseImponible;
    FieldByName('TOTAL_BASEI_IVAE_FAC').AsFloat :=
                                         _totales.IVAE.BaseImponible;
    FieldByName('TOTAL_BASES_FAC').AsFloat := _totales.TotalBases;
    // Importes de IVA
    FieldByName('TOTAL_IVAN_FAC').AsFloat := _totales.TotalIVANormal;
    FieldByName('TOTAL_IVAR_FAC').AsFloat := _totales.TotalIVAReducido;
    FieldByName('TOTAL_IVAS_FAC').AsFloat :=
                                            _totales.TotalIVASuperReducido;
    FieldByName('TOTAL_IVAE_FAC').AsFloat := _totales.TotalIVAExento;
    // Importes de Recargo Equivalencia
    FieldByName('TOTAL_REN_FAC').AsFloat := _totales.IVAN.ImporteRE;
    FieldByName('TOTAL_RER_FAC').AsFloat := _totales.IVAR.ImporteRE;
    FieldByName('TOTAL_RES_FAC').AsFloat := _totales.IVAS.ImporteRE;
    FieldByName('TOTAL_REE_FAC').AsFloat := _totales.IVAE.ImporteRE;
    // Totales generales
    FieldByName('TOTAL_IMPUESTOS_FAC').AsFloat := _totales.TotalImpuestos;
    FieldByName('TOTAL_RETENCION_FAC').AsFloat := _totales.TotalRetencion;
    FieldByName('PORCENTAJE_RETENCION_FAC').AsFloat := _dPorRetencion;
    FieldByName('TOTAL_LIQUIDO_FAC').AsFloat := _totales.TotalLiquido;
    // Actualizar configuración aplicada
    FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString :=
      IfThen(_configuracion.IVAExento, 'S', 'N');
    FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString :=
      IfThen(_configuracion.AplicaRetencionesCliente, 'S', 'N');
    FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString :=
      IfThen(_configuracion.AplicaRetencionesEmpresa, 'S', 'N');
    if FindField('ESAPLICA_RE_ZONA_IVA_FAC') <> nil then
      _configuracion.AplicaRecargo :=
                 SameText(FieldByName('ESAPLICA_RE_ZONA_IVA_FAC').AsString, 'S')
    else
      _configuracion.AplicaRecargo := False;
    // Actualizar porcentajes aplicados
    FieldByName('PORCENTAJE_IVAN_FAC').AsFloat := _porcentajes.IVANormal;
    FieldByName('PORCENTAJE_IVAR_FAC').AsFloat := _porcentajes.IVAReducido;
    FieldByName('PORCENTAJE_IVAS_FAC').AsFloat :=
                                              _porcentajes.IVASuperReducido;
    FieldByName('PORCENTAJE_IVAE_FAC').AsFloat := _porcentajes.IVAExento;
  end;
end;

procedure TFacturaTotales.ValidarConfiguracion;
begin
end;

function TFacturaTotales.ValidarFactura: Boolean;
begin
  Result := True;
  _mensajeError := '';
  try
    ValidarConfiguracion;
  except
    on E: Exception do
    begin
      _mensajeError := E.Message;
      Result := False;
    end;
  end;
end;

procedure TFacturaTotales.RecorrerYCalcularLineasConClientDataSet;
var
  lineaActual: TLinFac;
  bookmark: TBookmark;
  WasInsert, WasEdit, WasEmptyInsert: Boolean;
begin
  if not Assigned(_unqryLineas) or not _unqryLineas.Active then
    Exit;

  _unqryLineas.DisableControls;
  try
    WasInsert := (_unqryLineas.State = dsInsert);
    WasEdit := (_unqryLineas.State = dsEdit);
    WasEmptyInsert := False;
    // ======================================================================
    // 1. PREPARAMOS EL DATASET PARA CALCULAR (SIN ERRORES)
    // ======================================================================
    if WasInsert or WasEdit then
    begin
      if Trim(_unqryLineas.FieldByName(fcodart).AsString) = '' then
      begin
        WasEmptyInsert := True;
        _unqryLineas.Cancel;
      end
      else
        _unqryLineas.Post;
    end;
    if _unqryLineas.IsEmpty then
    begin
      if WasEmptyInsert then _unqryLineas.Append;
      Exit;
    end;
    // ======================================================================
    // 2. HACEMOS LA SUMA FISCAL
    // ======================================================================
    bookmark := _unqryLineas.GetBookmark;
    _unqryLineas.First;
    while not _unqryLineas.Eof do
    begin
      lineaActual := TLinFac.Create(_unqryLineas, _unqryFac, False);
      if _configuracion.IVAExento then
        lineaActual.TipoIva := 'E';
      lineaActual.PorIva := ObtenerPorcentajePorTipo(lineaActual.TipoIva);
      lineaActual.CalcularLinea;
      AcumularTotalesPorTipoIVA(lineaActual);
      lineaActual.CopyToDataSetLin;
      FreeAndNil(lineaActual);
      _unqryLineas.Next;
    end;
    if _unqryLineas.BookmarkValid(bookmark) then
    begin
      _unqryLineas.GotoBookmark(bookmark);
      _unqryLineas.FreeBookmark(bookmark);
    end;
    if WasEmptyInsert then
      _unqryLineas.Append  
    else if WasEdit then
      _unqryLineas.Edit;
  finally
    _unqryLineas.EnableControls;
  end;
end;

function TFacturaTotales.BuscarPorcenRetencion(CodEmpresa: string): Currency;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := _conexion;
    Qry.SQL.Text := 'SELECT PORCENTAJE_EMPRET ' +
                    '  FROM fza_empresas_retenciones ' +
                    ' WHERE CODIGO_EMP_EMPRET = :EMP ' +
                    '   AND FECHA_DESDE_EMPRET <= :FECHA ' +
                    '   AND (FECHA_HASTA_EMPRET >= :FECHA ' +
                    '        OR FECHA_HASTA_EMPRET IS NULL) ' +
                    ' ORDER BY FECHA_DESDE_EMPRET DESC LIMIT 1';
    Qry.ParamByName('EMP').AsString := CodEmpresa;
    Qry.ParamByName('FECHA').AsDateTime := _FechaFactura;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.Fields[0].AsCurrency;
  finally
    FreeAndNil(Qry);
  end;
end;

function TFacturaTotales.BuscarDatosIVAAgricola(CodEmpresa: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := _conexion;
    Qry.SQL.Text := 'SELECT IVA_IVAGRP, CODIGO_IVA, ' +
                    '       PORCENTAJE_NORMAL_IVA, PORCENTAJE_EXENTO_IVA, ' +
                    '       PORCENTAJE_REDUCIDO_IVA, ' +
                    'PORCENTAJE_SUPERREDUCIDO_IVA ' +
                    '  FROM vi_ivas_empresa ' +
                    ' WHERE ESIVAAGRICOLA_IVA_IVAGRP = ''S'' ' +
                    '   AND CODIGO_EMP_EMP = :EMP ' +
                    '   AND FECHA_DESDE_IVA <= :FECHA ' +
                    '   AND (   FECHA_HASTA_IVA IS NULL ' +
                    '        OR FECHA_HASTA_IVA >= :FECHA)';
    Qry.ParamByName('EMP').AsString := CodEmpresa;
    Qry.ParamByName('FECHA').AsDateTime := _FechaFactura;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      _GrupoZonaIVA := Qry.FieldByName('IVA_IVAGRP').AsString;
      _CodigoIVA    := Qry.FieldByName('CODIGO_IVA').AsString;
      _porcentajes.IVANormal :=
        Qry.FieldByName('PORCENTAJE_NORMAL_IVA').AsCurrency;
      _porcentajes.IVAExento :=
        Qry.FieldByName('PORCENTAJE_EXENTO_IVA').AsCurrency;
      _porcentajes.IVAReducido :=
                               Qry.FieldByName(
                                 'PORCENTAJE_REDUCIDO_IVA').AsCurrency;
      _porcentajes.IVASuperReducido :=
                          Qry.FieldByName(
                            'PORCENTAJE_SUPERREDUCIDO_IVA').AsCurrency;
      Result := True;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TFacturaTotales.VerificarYCompletarDatosCliente;
var
  Qry: TUniQuery;
  sCodCli: string;
begin
  sCodCli := _unqryFac.FieldByName('CODIGO_CLI_FAC').AsString;
  if (sCodCli = '') or
     (sCodCli = '0') or
     (sCodCli = 'VENTA CONTADO') or //no hay cliente
     (_unqryFac.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString <> '') then
    Exit;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := _conexion;
    Qry.SQL.Text := '    SELECT * ' +
                    '      FROM fza_clientes ' +
                    ' LEFT JOIN fza_tarifas ' +
                    '        ON fza_clientes.TARIFA_ARTICULO_CLI = ' +
                    '           fza_tarifas.CODIGO_TAR_ARTTAR ' +
                    '     WHERE CODIGO_CLI_CLI = :cliente';
    Qry.ParamByName('cliente').AsString := sCodCli;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      if (_unqryFac.State = dsBrowse) then
        _unqryFac.Edit;
      _unqryFac.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString :=
                                Qry.FieldByName('RAZON_SOCIAL_CLI').AsString;
      _unqryFac.FieldByName('NIF_CLIENTE_FAC').AsString         :=
                                        Qry.FieldByName('NIF_CLI').AsString;
      _unqryFac.FieldByName('MOVIL_CLIENTE_FAC').AsString       :=
                                      Qry.FieldByName('MOVIL_CLI').AsString;
      _unqryFac.FieldByName('EMAIL_CLIENTE_FAC').AsString       :=
                                      Qry.FieldByName('EMAIL_CLI').AsString;
      _unqryFac.FieldByName('DIRECCION1_CLIENTE_FAC').AsString  :=
                                 Qry.FieldByName('DIRECCION1_CLI').AsString;
      _unqryFac.FieldByName('DIRECCION2_CLIENTE_FAC').AsString  :=
                                 Qry.FieldByName('DIRECCION2_CLI').AsString;
      _unqryFac.FieldByName('POBLACION_CLIENTE_FAC').AsString   :=
                                  Qry.FieldByName('POBLACION_CLI').AsString;
      _unqryFac.FieldByName('PROVINCIA_CLIENTE_FAC').AsString   :=
                                  Qry.FieldByName('PROVINCIA_CLI').AsString;
      _unqryFac.FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString     :=
                                    Qry.FieldByName(
                                      'CODIGO_POSTAL_CLI').AsString;
      _unqryFac.FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString :=
                                Qry.FieldByName('NOMBRE_PAI_CLI').AsString;
      _unqryFac.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString :=
                                Qry.FieldByName('CODIGO_PAI_CLI').AsString;
      _unqryFac.FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString :=
                              Qry.FieldByName('ESIVA_RECARGO_CLI').AsString;
      _unqryFac.FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString  :=
                               Qry.FieldByName('ESIVA_EXENTO_CLI').AsString;
      _unqryFac.FieldByName(
                        'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString :=
                  Qry.FieldByName('ESREGIMENESPECIALAGRICOLA_CLI').AsString;
      _unqryFac.FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString :=
                              Qry.FieldByName('ESRETENCIONES_CLI').AsString;
      _unqryFac.FieldByName('ESINTRACOMUNITARIO_CLIENTE_FAC').AsString :=
                         Qry.FieldByName('ESINTRACOMUNITARIO_CLI').AsString;
      _unqryFac.FieldByName('FORMA_PAGO_FAC').AsString :=
                          Qry.FieldByName('CODIGO_FP_CLI').AsString;
      _unqryFac.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
                            Qry.FieldByName('TARIFA_ARTICULO_CLI').AsString;
      if Qry.FindField('ESIMP_INCL_TAR').AsString <> '' then
        _unqryFac.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
                                    Qry.FindField('ESIMP_INCL_TAR').AsString;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TFacturaTotales.VerificarYCompletarDatosEmpresa;
var
  Qry: TUniQuery;
begin
  if (_unqryFac.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString <> '') then
    Exit;
  if _codigoEmpresa = '' then
    Exit;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := _conexion;
    Qry.SQL.Text := 'SELECT * ' +
                    '  FROM fza_empresas ' +
                    ' WHERE CODIGO_EMP_EMP = :empresa';
    Qry.ParamByName('empresa').AsString := _codigoEmpresa;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      if (_unqryFac.State = dsBrowse) then
        _unqryFac.Edit;
      _unqryFac.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString :=
                                Qry.FieldByName('RAZON_SOCIAL_EMP').AsString;
      _unqryFac.FieldByName('NIF_EMPRESA_FAC').AsString         :=
                                        Qry.FieldByName('NIF_EMP').AsString;
      _unqryFac.FieldByName('MOVIL_EMPRESA_FAC').AsString       :=
                                      Qry.FieldByName('MOVIL_EMP').AsString;
      _unqryFac.FieldByName('EMAIL_EMPRESA_FAC').AsString       :=
                                      Qry.FieldByName('EMAIL_EMP').AsString;
      _unqryFac.FieldByName('DIRECCION1_EMPRESA_FAC').AsString  :=
                                 Qry.FieldByName('DIRECCION1_EMP').AsString;
      _unqryFac.FieldByName('DIRECCION2_EMPRESA_FAC').AsString  :=
                                 Qry.FieldByName('DIRECCION2_EMP').AsString;
      _unqryFac.FieldByName('POBLACION_EMPRESA_FAC').AsString   :=
                                  Qry.FieldByName('POBLACION_EMP').AsString;
      _unqryFac.FieldByName('PROVINCIA_EMPRESA_FAC').AsString   :=
                                  Qry.FieldByName('PROVINCIA_EMP').AsString;
      _unqryFac.FieldByName('CODIGO_POSTAL_EMPRESA_FAC').AsString     :=
                                    Qry.FieldByName(
                                      'CODIGO_POSTAL_EMP').AsString;
      _unqryFac.FieldByName('NOMBRE_PAI_EMPRESA_FAC').AsString :=
                                Qry.FieldByName('NOMBRE_PAI_EMP').AsString;
      _unqryFac.FieldByName('CODIGO_PAI_EMPRESA_FAC').AsString :=
                                Qry.FieldByName('CODIGO_PAI_EMP').AsString;
      _unqryFac.FieldByName('GRUPO_ZONA_IVA_EMPRESA_FAC').AsString :=
                             Qry.FieldByName('GRUPO_ZONA_IVA_EMP').AsString;
      _unqryFac.FieldByName('ESRETENCIONES_EMPRESA_FAC').AsString :=
                              Qry.FieldByName('ESRETENCIONES_EMP').AsString;
      _unqryFac.FieldByName(
                        'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC').AsString :=
                  Qry.FieldByName('ESREGIMENESPECIALAGRICOLA_EMP').AsString;
      _unqryFac.FieldByName('TEXTO_LEGAL_EMPRESA_FAC').AsString :=
                        Qry.FieldByName('TEXTO_LEGAL_FACTURA_EMP').AsString;
      var sGrupo := _unqryFac.FieldByName(
                                     'GRUPO_ZONA_IVA_EMPRESA_FAC').AsString;
      CargarConfiguracionIVA(sGrupo);
    end;
  finally
    FreeAndNil(Qry);
  end;
end;
end.
