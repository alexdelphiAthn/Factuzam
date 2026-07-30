{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturas                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       29/07/2026                                                    }
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
  Datasnap.DBClient, Datasnap.Provider, inLibMotorFiscalVenta;

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
  TActualizarTotalFacturaEvent = procedure(Sender: TObject;
    ANuevoTotal: Currency) of object;
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

  TAlcanceRecalculoFactura = (
    arfSoloLinea,
    arfLineaYDocumento);

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
    FCampoNumeroLinea: TField;
    FCampoCantidad: TField;
    FCampoImpuestosIncluidos: TField;
    FCampoTipoIva: TField;
    FCampoPorcentajeIva: TField;
    FCampoPrecioSalida: TField;
    FCampoPorcentajeDto: TField;
    FCampoPrecioDto: TField;
    FCampoPrecioSinIva: TField;
    FCampoPrecioConIva: TField;
    FCampoTotalConIva: TField;
    FCampoTotalSinIva: TField;
    function CampoCurrencyDistinto(
      ACampo: TField; AValor: Currency): Boolean;
    function CampoStringDistinto(
      ACampo: TField; const AValor: string): Boolean;
    function NecesitaActualizarDataSetLin: Boolean;
    procedure CachearCamposLinea;
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
    _lineasMotorFiscal: TLineasMotorFiscalVenta;
    function LineaActualPendienteDeResolver: Boolean;
    function ClienteTieneDatosFiscales: Boolean;
    function CrearConfiguracionMotorFiscal:
      TConfiguracionMotorFiscalVenta;
    procedure InicializarTotales;
    procedure InicializarConfiguracion;
    procedure LeerDatosFactura;
    procedure LeerPorcentajesDesdeFactura;
    procedure AplicarReglas;
    procedure RecorrerYCalcularLineasConClientDataSet;
    procedure AcumularTotalesPorTipoIVA(
      ALinea: TLinFac; AIndice: Integer);
    procedure AplicarResultadoMotorFiscal(
      const AResultado: TResultadoMotorFiscalVenta);
    procedure CalcularTotalesGenerales;
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
    property PorcentajeRetencion: Currency
      read _dPorRetencion write _dPorRetencion;
    property MensajeError: string read _mensajeError;
    property Cabecera:TDataSet read _unqryFac;
    property Lineas:TDataset read _unqryLineas;
  end;
  function RecalcularLineaFactura(
    ALineas: TDataSet;
    ACabecera: TDataSet;
    const ACampo: string;
    const AValor: Variant): Boolean;
  procedure ActualizarLineaFactura(
    AConexion: TUniConnection;
    ALineas: TDataSet;
    ACabecera: TDataSet;
    const ACampo: string;
    const AValor: Variant;
    AAlActualizarTotal: TActualizarTotalFacturaEvent = nil);
  function IfThen(AValue: Boolean;
                 const ATrue: string;
                 AFalse: string = ''): string;
  procedure GuardarCambiosPendientesFactura(
    AConexion: TUniConnection;
    ACabecera, ALineas, ARecibos: TDataSet);
  function ArticuloFacturaDebeMostrarSku(
    AConexion: TUniConnection;
    const ACodigoArticulo: string): Boolean;
  function ContarLineasFactura(
    AConexion: TUniConnection;
    const ASerie, ANumero: string): Integer;


implementation

uses
  System.Variants,
  inLibLog, inLibMsgFacturas;

procedure PostearSiPendiente(ADataSet: TDataSet);
begin
  if Assigned(ADataSet) and ADataSet.Active and
     (ADataSet.State in [dsEdit, dsInsert]) then
  begin
    if (ADataSet.State = dsInsert) or ADataSet.Modified then
      ADataSet.Post
    else
      ADataSet.Cancel;
  end;
end;

procedure GuardarCambiosPendientesFactura(
  AConexion: TUniConnection;
  ACabecera, ALineas, ARecibos: TDataSet);
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not AConexion.InTransaction;
  if bTransaccionPropia then
    AConexion.StartTransaction;
  try
    if Assigned(ACabecera) and
       (ACabecera.State = dsInsert) then
      PostearSiPendiente(ACabecera);
    PostearSiPendiente(ALineas);
    PostearSiPendiente(ARecibos);
    PostearSiPendiente(ACabecera);
    if bTransaccionPropia and AConexion.InTransaction then
      AConexion.Commit;
  except
    if bTransaccionPropia and AConexion.InTransaction then
      AConexion.Rollback;
    raise;
  end;
end;

function ArticuloFacturaDebeMostrarSku(
  AConexion: TUniConnection;
  const ACodigoArticulo: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Result := True;
  if ACodigoArticulo <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'SELECT A.ESVARIACION_ART, ' +
        '       (SELECT COUNT(*) FROM fza_articulos_skus S ' +
        '         WHERE S.CODIGO_ART_SKU = A.CODIGO_ART_ART ' +
        '           AND S.ESACTIVO_SKU = ''S'') AS NSKU ' +
        '  FROM fza_articulos A ' +
        ' WHERE A.CODIGO_ART_ART = :art ' +
        ' LIMIT 1';
      Consulta.ParamByName('art').AsString := ACodigoArticulo;
      Consulta.Open;
      Result := Consulta.IsEmpty or
        (Consulta.FieldByName('ESVARIACION_ART').AsString = 'S') or
        (Consulta.FieldByName('NSKU').AsInteger > 1);
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

function ContarLineasFactura(
  AConexion: TUniConnection;
  const ASerie, ANumero: string): Integer;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_facturas_lineas ' +
      ' WHERE NUMERO_FAC_FACLIN = :numero ' +
      '   AND SERIE_FAC_FACLIN = :serie';
    Consulta.ParamByName('numero').AsString := ANumero;
    Consulta.ParamByName('serie').AsString := ASerie;
    Consulta.Open;
    Result := Consulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
end;

function IfThen(AValue: Boolean;
                const ATrue: string;
                AFalse: string = ''): string;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

procedure AplicarTotalEditado(ALinea: TLinFac; ATotal: Currency);
var
  nDiferencia: Currency;
  nTotalBruto: Currency;
begin
  nTotalBruto := ALinea.PrecioSal * ALinea.Cant;
  if (nTotalBruto <> 0) and (ALinea.Cant <> 0) then
    nDiferencia := (nTotalBruto - ATotal) / ALinea.Cant
  else
    nDiferencia := 0;
  ALinea.Dto := nDiferencia;
end;

function RecalcularLineaFactura(
  ALineas: TDataSet;
  ACabecera: TDataSet;
  const ACampo: string;
  const AValor: Variant): Boolean;
var
  oLinea: TLinFac;
  nValor: Currency;
begin
  Result := Assigned(ALineas);
  if Result then
    Result := ALineas.Active and ALineas.CanModify;
  if Result then
  begin
    if not (ALineas.State in [dsEdit, dsInsert]) then
      ALineas.Edit;
    nValor := StrToCurrDef(VarToStr(AValor), 0);
    oLinea := TLinFac.Create(ALineas, ACabecera, True);
    try
      if SameText(ACampo, fpreciosal) then
        oLinea.PrecioSal := nValor
      else if SameText(ACampo, fcant) then
        oLinea.Cant := nValor
      else if SameText(ACampo, fpordto) then
        oLinea.PorDto := nValor
      else if SameText(ACampo, fdto) then
        oLinea.Dto := nValor
      else if SameText(ACampo, fpresiva) then
        oLinea.PreSiva := nValor
      else if SameText(ACampo, fpreciva) then
        oLinea.PreCiva := nValor
      else if SameText(ACampo, ftipiva) then
        oLinea.TipoIva := VarToStr(AValor)
      else if SameText(ACampo, ftotciva) or
              SameText(ACampo, ftotsiva) then
        AplicarTotalEditado(oLinea, nValor);
      oLinea.CopyToDataSetLin;
    finally
      FreeAndNil(oLinea);
    end;
  end;
end;

procedure ActualizarLineaFactura(
  AConexion: TUniConnection;
  ALineas: TDataSet;
  ACabecera: TDataSet;
  const ACampo: string;
  const AValor: Variant;
  AAlActualizarTotal: TActualizarTotalFacturaEvent);
var
  oTotales: TFacturaTotales;
begin
  if RecalcularLineaFactura(
       ALineas,
       ACabecera,
       ACampo,
       AValor) then
  begin
    oTotales := TFacturaTotales.Create(
      AConexion,
      ACabecera,
      ALineas);
    try
      if not oTotales.ProcesarFacturaCompleta then
      begin
        raise Exception.CreateFmt(
          SErrorRecalcularTotalesFactura,
          [oTotales.MensajeError]);
      end;
      if Assigned(AAlActualizarTotal) then
      begin
        AAlActualizarTotal(
          nil,
          oTotales.Totales.TotalLiquido);
      end;
    finally
      FreeAndNil(oTotales);
    end;
  end;
end;

{ TLinFac - Implementación completa }

constructor TLinFac.Create(AUnqryLin: TDataset);
begin
  inherited Create;
  SetInit(AUnqryLin);
  Self.CopyToObjectLin;
end;

constructor TLinFac.Create(AUnqryLin, AUnqryFac: TDataset;
                           bCalcularFactura:boolean = false);
begin
  inherited Create;
  SetInit(AUnqryLin);
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
  if Assigned(_unqryLin) and NecesitaActualizarDataSetLin then
  begin
    if _unqryLin.State = dsBrowse then
      _unqryLin.Edit;
    FCampoCantidad.AsCurrency := _dCant;
    FCampoPrecioSalida.AsCurrency := _dPrecioSal;
    FCampoPorcentajeDto.AsCurrency := _dPorDto;
    FCampoPrecioDto.AsCurrency := _dDto;
    FCampoImpuestosIncluidos.AsString := _sImpcl;
    FCampoTipoIva.AsString := _sTipIva;
    FCampoPorcentajeIva.AsCurrency := _dPorIVa;
    FCampoPrecioSinIva.AsCurrency := _dPreSiva;
    FCampoPrecioConIva.AsCurrency := _dPreCiva;
    FCampoTotalConIva.AsCurrency := _dTotCiva;
    FCampoTotalSinIva.AsCurrency := _dTotSiva;
  end;
end;

function TLinFac.CampoCurrencyDistinto(
  ACampo: TField; AValor: Currency): Boolean;
begin
  Result := ACampo.IsNull or (ACampo.AsCurrency <> AValor);
end;

function TLinFac.CampoStringDistinto(
  ACampo: TField; const AValor: string): Boolean;
begin
  Result := ACampo.IsNull or (ACampo.AsString <> AValor);
end;

function TLinFac.NecesitaActualizarDataSetLin: Boolean;
begin
  Result :=
    CampoCurrencyDistinto(FCampoCantidad, _dCant) or
    CampoCurrencyDistinto(FCampoPrecioSalida, _dPrecioSal) or
    CampoCurrencyDistinto(FCampoPorcentajeDto, _dPorDto) or
    CampoCurrencyDistinto(FCampoPrecioDto, _dDto) or
    CampoStringDistinto(FCampoImpuestosIncluidos, _sImpcl) or
    CampoStringDistinto(FCampoTipoIva, _sTipIva) or
    CampoCurrencyDistinto(FCampoPorcentajeIva, _dPorIVa) or
    CampoCurrencyDistinto(FCampoPrecioSinIva, _dPreSiva) or
    CampoCurrencyDistinto(FCampoPrecioConIva, _dPreCiva) or
    CampoCurrencyDistinto(FCampoTotalConIva, _dTotCiva) or
    CampoCurrencyDistinto(FCampoTotalSinIva, _dTotSiva);
end;

procedure TLinFac.CopyToDataSetFac;
begin
  // Implementar si es necesario para actualizar campos de la factura
end;

procedure TLinFac.CopyToObjectLin;
begin
  _sNumLin := FCampoNumeroLinea.AsString;
  _dCant := FCampoCantidad.AsCurrency;
  if FCampoImpuestosIncluidos.AsString = '' then
    _sImpcl := 'S'
  else
    _sImpcl := FCampoImpuestosIncluidos.AsString;
  _sTipIVA := FCampoTipoIva.AsString;
  _dPorIVa := FCampoPorcentajeIva.AsCurrency;
  _dPrecioSal := FCampoPrecioSalida.AsCurrency;
  _dPorDto := FCampoPorcentajeDto.AsCurrency;
  _dDto := FCampoPrecioDto.AsCurrency;
  _dPreSiva := FCampoPrecioSinIva.AsCurrency;
  _dPreCiva := FCampoPrecioConIva.AsCurrency;
  _dTotCiva := FCampoTotalConIva.AsCurrency;
  _dTotSiva := FCampoTotalSinIva.AsCurrency;
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
  CachearCamposLinea;
end;

procedure TLinFac.CachearCamposLinea;
begin
  FCampoNumeroLinea := _unqryLin.FieldByName(fnrolin);
  FCampoCantidad := _unqryLin.FieldByName(fcant);
  FCampoImpuestosIncluidos := _unqryLin.FieldByName(fimpcl);
  FCampoTipoIva := _unqryLin.FieldByName(ftipiva);
  FCampoPorcentajeIva := _unqryLin.FieldByName(fporiva);
  FCampoPrecioSalida := _unqryLin.FieldByName(fpreciosal);
  FCampoPorcentajeDto := _unqryLin.FieldByName(fpordto);
  FCampoPrecioDto := _unqryLin.FieldByName(fdto);
  FCampoPrecioSinIva := _unqryLin.FieldByName(fpresiva);
  FCampoPrecioConIva := _unqryLin.FieldByName(fpreciva);
  FCampoTotalConIva := _unqryLin.FieldByName(ftotciva);
  FCampoTotalSinIva := _unqryLin.FieldByName(ftotsiva);
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
  SetLength(_lineasMotorFiscal, 0);
  FTieneLineasNegativas := False;
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

function TFacturaTotales.ClienteTieneDatosFiscales: Boolean;
var
  Direccion: string;
  Nif: string;
  RazonSocial: string;
begin
  Nif := Trim(
    _unqryFac.FieldByName('NIF_CLIENTE_FAC').AsString);
  RazonSocial := Trim(
    _unqryFac.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString);
  Direccion := Trim(
    _unqryFac.FieldByName('DIRECCION1_CLIENTE_FAC').AsString);
  Result :=
    (Nif <> '') and
    (RazonSocial <> '') and
    (Direccion <> '');
end;

function TFacturaTotales.CrearConfiguracionMotorFiscal:
  TConfiguracionMotorFiscalVenta;
var
  PuedeAplicarRetencion: Boolean;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.RedondearPorLinea := True;
  Result.CalcularIvaIncluidoPorDiferencia := True;
  Result.AplicaRecargo :=
    _configuracion.AplicaRecargo and
    _configuracion.IVARecargo;
  Result.EsFacturaSimplificada :=
    _configuracion.EsFacturaSimplificada;
  Result.ClienteConDatosFiscales :=
    ClienteTieneDatosFiscales;
  Result.RetencionIncluyeImpuestos :=
    _configuracion.IRPFImpuestoIncluido;
  PuedeAplicarRetencion :=
    _configuracion.AplicaRetencionesCliente and
    _configuracion.AplicaRetencionesEmpresa and
    not (
      _configuracion.EsVentaActivoFijo and
      _configuracion.EsRegimenAgricolaEmpresa);
  Result.AplicaRetencion := PuedeAplicarRetencion;
  if _configuracion.EsVentaActivoFijo and
     _configuracion.EsRegimenAgricolaEmpresa then
    _dPorRetencion := 0;
  if PuedeAplicarRetencion and
     not Result.EsFacturaSimplificada and
     Result.ClienteConDatosFiscales and
     (_dPorRetencion = 0) then
    _dPorRetencion :=
      BuscarPorcenRetencion(_codigoEmpresa);
  Result.PorcentajeRetencion := _dPorRetencion;
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
        if Log() <> nil then
          Log.LogError('TFacturaTotales.ProcesarFacturaCompleta (' +
                       E.ClassName + '): ' + E.Message);
        Result := False;
      end;
    end;
  end;
end;

procedure TFacturaTotales.AcumularTotalesPorTipoIVA(
  ALinea: TLinFac; AIndice: Integer);
var
  LineaMotor: TLineaMotorFiscalVenta;
begin
  FillChar(LineaMotor, SizeOf(LineaMotor), 0);
  LineaMotor.TipoIva := ALinea.TipoIva;
  LineaMotor.Base := ALinea.TotSiva;
  LineaMotor.TotalConIva := ALinea.TotCiva;
  LineaMotor.PorcentajeIva :=
    ObtenerPorcentajePorTipo(ALinea.TipoIva);
  LineaMotor.PorcentajeRecargo :=
    ObtenerPorcentajeREPorTipo(ALinea.TipoIva);
  LineaMotor.Bruto := ALinea.PrecioSal * ALinea.Cant;
  LineaMotor.Descuento := ALinea.Dto * ALinea.Cant;
  LineaMotor.Cantidad := ALinea.Cant;
  LineaMotor.ImpuestosIncluidos :=
    SameText(ALinea.Impcl, 'S');
  _lineasMotorFiscal[AIndice] := LineaMotor;
end;

procedure TFacturaTotales.AplicarResultadoMotorFiscal(
  const AResultado: TResultadoMotorFiscalVenta);
begin
  _totales.IVAN.BaseImponible := AResultado.Normal.Base;
  _totales.IVAN.PorcentajeIVA := AResultado.Normal.PorcentajeIva;
  _totales.IVAN.ImporteIVA := AResultado.Normal.ImporteIva;
  _totales.IVAN.PorcentajeRE :=
    AResultado.Normal.PorcentajeRecargo;
  _totales.IVAN.ImporteRE := AResultado.Normal.ImporteRecargo;
  _totales.IVAR.BaseImponible := AResultado.Reducido.Base;
  _totales.IVAR.PorcentajeIVA := AResultado.Reducido.PorcentajeIva;
  _totales.IVAR.ImporteIVA := AResultado.Reducido.ImporteIva;
  _totales.IVAR.PorcentajeRE :=
    AResultado.Reducido.PorcentajeRecargo;
  _totales.IVAR.ImporteRE := AResultado.Reducido.ImporteRecargo;
  _totales.IVAS.BaseImponible := AResultado.SuperReducido.Base;
  _totales.IVAS.PorcentajeIVA :=
    AResultado.SuperReducido.PorcentajeIva;
  _totales.IVAS.ImporteIVA :=
    AResultado.SuperReducido.ImporteIva;
  _totales.IVAS.PorcentajeRE :=
    AResultado.SuperReducido.PorcentajeRecargo;
  _totales.IVAS.ImporteRE :=
    AResultado.SuperReducido.ImporteRecargo;
  _totales.IVAE.BaseImponible := AResultado.Exento.Base;
  _totales.IVAE.PorcentajeIVA := AResultado.Exento.PorcentajeIva;
  _totales.IVAE.ImporteIVA := AResultado.Exento.ImporteIva;
  _totales.IVAE.PorcentajeRE :=
    AResultado.Exento.PorcentajeRecargo;
  _totales.IVAE.ImporteRE := AResultado.Exento.ImporteRecargo;
  _totales.BaseNormal := AResultado.Normal.Base;
  _totales.BaseReducida := AResultado.Reducido.Base;
  _totales.BaseSuper := AResultado.SuperReducido.Base;
  _totales.BaseExenta := AResultado.Exento.Base;
  _totales.CuotaIVANormal := AResultado.Normal.ImporteIva;
  _totales.CuotaIVAReducida := AResultado.Reducido.ImporteIva;
  _totales.CuotaIVASuper := AResultado.SuperReducido.ImporteIva;
  _totales.CuotaIVAExenta := AResultado.Exento.ImporteIva;
  _totales.CuotaRENormal := AResultado.Normal.ImporteRecargo;
  _totales.CuotaREReducida := AResultado.Reducido.ImporteRecargo;
  _totales.CuotaRESuper :=
    AResultado.SuperReducido.ImporteRecargo;
  _totales.CuotaREExenta := AResultado.Exento.ImporteRecargo;
  _totales.TotalBases := AResultado.TotalBases;
  _totales.TotalIVANormal := AResultado.Normal.ImporteIva;
  _totales.TotalIVAReducido := AResultado.Reducido.ImporteIva;
  _totales.TotalIVASuperReducido :=
    AResultado.SuperReducido.ImporteIva;
  _totales.TotalIVAExento := AResultado.Exento.ImporteIva;
  _totales.TotalREcargo := AResultado.TotalRecargo;
  _totales.TotalImpuestos := AResultado.TotalImpuestos;
  _totales.TotalRetencion := AResultado.TotalRetencion;
  _totales.TotalLiquido := AResultado.TotalLiquido;
  _totales.TotalBruto := AResultado.TotalBruto;
  _totales.TotalDescuentosLineas :=
    AResultado.TotalDescuentos;
  _totales.TotalCantidades := AResultado.TotalCantidades;
  FTieneLineasNegativas := AResultado.TieneImportesNegativos;
end;

procedure TFacturaTotales.CalcularTotalesGenerales;
var
  ConfiguracionMotor: TConfiguracionMotorFiscalVenta;
  ResultadoMotor: TResultadoMotorFiscalVenta;
begin
  ConfiguracionMotor := CrearConfiguracionMotorFiscal;
  ResultadoMotor := CalcularTotalesMotorFiscalVenta(
    _lineasMotorFiscal, ConfiguracionMotor);
  AplicarResultadoMotorFiscal(ResultadoMotor);
end;

procedure TFacturaTotales.CalcularTotalesFactura;
begin
  CalcularTotalesGenerales;
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
  bookmark: TBookmark;
  iIndiceMotor: Integer;
  lineaActual: TLinFac;
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
    SetLength(_lineasMotorFiscal, _unqryLineas.RecordCount);
    iIndiceMotor := 0;
    lineaActual := TLinFac.Create(_unqryLineas, _unqryFac, False);
    try
      while not _unqryLineas.Eof do
      begin
        lineaActual.CopyToObjectLin;
        if _configuracion.IVAExento then
          lineaActual.TipoIva := 'E';
        lineaActual.PorIva :=
          ObtenerPorcentajePorTipo(lineaActual.TipoIva);
        lineaActual.CalcularLinea;
        AcumularTotalesPorTipoIVA(lineaActual, iIndiceMotor);
        lineaActual.CopyToDataSetLin;
        Inc(iIndiceMotor);
        _unqryLineas.Next;
      end;
    finally
      FreeAndNil(lineaActual);
    end;
    SetLength(_lineasMotorFiscal, iIndiceMotor);
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
