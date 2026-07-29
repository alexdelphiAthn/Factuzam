{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasRepositorio                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia y consultas de negocio necesarias para editar facturas.      }
{******************************************************************************}
unit inLibFacturasRepositorio;

interface

uses
  System.SysUtils, Data.DB, Uni, inLibFacturasServiciosIntf;

type
  TRepositorioFacturas = class(
    TInterfacedObject,
    IRepositorioFacturas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ExisteSerieOtraEmpresa(
      const ASerie, AEmpresa, ATipoDocumento: string): Boolean;
    function EsPaisUE(const ACodigoPais: string): Boolean;
    function ObtenerOperacionFiscal(
      const ACodigo: string;
      out AOperacion: TOperacionFiscalFactura): Boolean;
    function UltimaFechaSerie(
      const ASerie, AEmpresa, ANumero: string): TDateTime;
    function HayHuecoNumeracion(
      const ASerie, AEmpresa, ANumero: string): Boolean;
    procedure GuardarCliente(
      const ASolicitud: TSolicitudClienteFactura);
    procedure GuardarEmpresa(
      const ASolicitud: TSolicitudEmpresaFactura);
  end;

implementation

constructor TRepositorioFacturas.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioFacturas.ExisteSerieOtraEmpresa(
  const ASerie, AEmpresa, ATipoDocumento: string): Boolean;
var
  Consulta: TUniQuery;
  EmpresaEncontrada: string;
begin
  Result := False;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT EMPRESA_CON FROM fza_contadores ' +
      'WHERE SERIE_CON = :Serie ' +
      'AND TIPO_DOC_CON = :TipoDoc ' +
      'AND EMPRESA_CON <> :Empresa ' +
      'AND EMPRESA_CON <> :EmpresaSinAsignar';
    Consulta.ParamByName('Serie').AsString := ASerie;
    Consulta.ParamByName('TipoDoc').AsString := ATipoDocumento;
    Consulta.ParamByName('Empresa').AsString := AEmpresa;
    Consulta.ParamByName('EmpresaSinAsignar').AsString := '-';
    Consulta.Open;
    if not Consulta.IsEmpty then
    begin
      EmpresaEncontrada :=
        Consulta.FieldByName('EMPRESA_CON').AsString;
      Result := (EmpresaEncontrada = '') or
        (not SameText(EmpresaEncontrada, AEmpresa));
    end;
  finally
    Consulta.Free;
  end;
end;

function TRepositorioFacturas.EsPaisUE(
  const ACodigoPais: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Result := False;
  if Trim(ACodigoPais) <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := FConexion;
      Consulta.SQL.Text :=
        'SELECT ESMIEMBRO_UE_PAI FROM fza_paises ' +
        'WHERE CODIGO_PAI_PAI = :pais';
      Consulta.ParamByName('pais').AsString := Trim(ACodigoPais);
      Consulta.Open;
      Result := (not Consulta.IsEmpty) and
        SameText(
          Trim(
            Consulta.FieldByName(
              'ESMIEMBRO_UE_PAI').AsString),
          'S');
    finally
      Consulta.Free;
    end;
  end;
end;

function TRepositorioFacturas.ObtenerOperacionFiscal(
  const ACodigo: string;
  out AOperacion: TOperacionFiscalFactura): Boolean;
var
  Consulta: TUniQuery;
begin
  Result := False;
  AOperacion.Ambito := '';
  AOperacion.RepercuteIva := True;
  if Trim(ACodigo) <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := FConexion;
      Consulta.SQL.Text :=
        'SELECT AMBITO_VFO, ESREPERCUTE_IVA_VFO ' +
        'FROM fza_verifactu_operaciones ' +
        'WHERE CODIGO_VFO = :codigo';
      Consulta.ParamByName('codigo').AsString := Trim(ACodigo);
      Consulta.Open;
      if not Consulta.IsEmpty then
      begin
        AOperacion.Ambito :=
          Trim(Consulta.FieldByName('AMBITO_VFO').AsString);
        AOperacion.RepercuteIva :=
          not SameText(
            Trim(
              Consulta.FieldByName(
                'ESREPERCUTE_IVA_VFO').AsString),
            'N');
        Result := True;
      end;
    finally
      Consulta.Free;
    end;
  end;
end;

function TRepositorioFacturas.UltimaFechaSerie(
  const ASerie, AEmpresa, ANumero: string): TDateTime;
var
  Consulta: TUniQuery;
begin
  Result := 0;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT MAX(FECHA_FAC) AS ULTIMA FROM fza_facturas ' +
      'WHERE SERIE_FAC = :serie AND CODIGO_EMP_FAC = :empresa ' +
      'AND NUMERO_FAC <> :numero AND FECHA_FAC IS NOT NULL ' +
      'AND FASE_FAC <> ''BORRADOR''';
    Consulta.ParamByName('serie').AsString := ASerie;
    Consulta.ParamByName('empresa').AsString := AEmpresa;
    Consulta.ParamByName('numero').AsString := ANumero;
    Consulta.Open;
    if (not Consulta.IsEmpty) and
       (not Consulta.FieldByName('ULTIMA').IsNull) then
    begin
      Result := Consulta.FieldByName('ULTIMA').AsDateTime;
    end;
  finally
    Consulta.Free;
  end;
end;

function TRepositorioFacturas.HayHuecoNumeracion(
  const ASerie, AEmpresa, ANumero: string): Boolean;
var
  Consulta: TUniQuery;
  NumeroAsignado: Int64;
  NumeroMaximo: Int64;
begin
  Result := False;
  NumeroAsignado := StrToInt64Def(Trim(ANumero), 0);
  if NumeroAsignado > 1 then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := FConexion;
      Consulta.SQL.Text :=
        'SELECT MAX(CAST(NUMERO_FAC AS UNSIGNED)) AS MAXNUM ' +
        'FROM fza_facturas WHERE SERIE_FAC = :serie ' +
        'AND CODIGO_EMP_FAC = :empresa ' +
        'AND CAST(NUMERO_FAC AS UNSIGNED) < :asignado';
      Consulta.ParamByName('serie').AsString := ASerie;
      Consulta.ParamByName('empresa').AsString := AEmpresa;
      Consulta.ParamByName('asignado').AsLargeInt := NumeroAsignado;
      Consulta.Open;
      if (not Consulta.IsEmpty) and
         (not Consulta.FieldByName('MAXNUM').IsNull) then
      begin
        NumeroMaximo :=
          Consulta.FieldByName('MAXNUM').AsLargeInt;
        Result := (NumeroAsignado - NumeroMaximo) > 1;
      end;
    finally
      Consulta.Free;
    end;
  end;
end;

procedure TRepositorioFacturas.GuardarCliente(
  const ASolicitud: TSolicitudClienteFactura);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'CALL PRC_CREAR_ACTUALIZAR_CLIENTE(' +
      ':pCODIGO_CLIENTE, :pRAZONSOCIAL_CLIENTE, :pNIF_CLIENTE, ' +
      ':pMOVIL_CLIENTE, :pEMAIL_CLIENTE, :pDIRECCION1_CLIENTE, ' +
      ':pDIRECCION2_CLIENTE, :pPOBLACION_CLIENTE, ' +
      ':pPROVINCIA_CLIENTE, :pCPOSTAL_CLIENTE, ' +
      ':pCOD_PAIS_CLIENTE, :pPAIS_CLIENTE, ' +
      ':pESIVA_EXENTO_CLIENTE, :pESRETENCIONES_CLIENTE, ' +
      ':pESIVA_RECARGO_CLIENTE, :pESINTRACOMUNITARIO_CLIENTE, ' +
      ':pESREGIMENESPECIALAGRICOLA_CLIENTE, ' +
      ':pTARIFA_ARTICULO_CLIENTE, :pUSUARIO)';
    Consulta.ParamByName('pCODIGO_CLIENTE').AsString :=
      ASolicitud.Codigo;
    Consulta.ParamByName('pRAZONSOCIAL_CLIENTE').AsString :=
      ASolicitud.RazonSocial;
    Consulta.ParamByName('pNIF_CLIENTE').AsString :=
      ASolicitud.Nif;
    Consulta.ParamByName('pMOVIL_CLIENTE').AsString :=
      ASolicitud.Movil;
    Consulta.ParamByName('pEMAIL_CLIENTE').AsString :=
      ASolicitud.Email;
    Consulta.ParamByName('pDIRECCION1_CLIENTE').AsString :=
      ASolicitud.Direccion1;
    Consulta.ParamByName('pDIRECCION2_CLIENTE').AsString :=
      ASolicitud.Direccion2;
    Consulta.ParamByName('pPOBLACION_CLIENTE').AsString :=
      ASolicitud.Poblacion;
    Consulta.ParamByName('pPROVINCIA_CLIENTE').AsString :=
      ASolicitud.Provincia;
    Consulta.ParamByName('pCPOSTAL_CLIENTE').AsString :=
      ASolicitud.CodigoPostal;
    Consulta.ParamByName('pPAIS_CLIENTE').AsString :=
      ASolicitud.NombrePais;
    Consulta.ParamByName('pCOD_PAIS_CLIENTE').AsString :=
      ASolicitud.CodigoPais;
    Consulta.ParamByName('pESINTRACOMUNITARIO_CLIENTE').AsString :=
      ASolicitud.EsIntracomunitario;
    Consulta.ParamByName('pESIVA_EXENTO_CLIENTE').AsString :=
      ASolicitud.EsIvaExento;
    Consulta.ParamByName('pESRETENCIONES_CLIENTE').AsString :=
      ASolicitud.EsRetenciones;
    Consulta.ParamByName('pESIVA_RECARGO_CLIENTE').AsString :=
      ASolicitud.EsIvaRecargo;
    Consulta.ParamByName(
      'pESREGIMENESPECIALAGRICOLA_CLIENTE').AsString :=
      ASolicitud.EsRegimenEspecialAgricola;
    Consulta.ParamByName('pTARIFA_ARTICULO_CLIENTE').AsString :=
      ASolicitud.TarifaArticulo;
    Consulta.ParamByName('pUSUARIO').AsString :=
      ASolicitud.Usuario;
    Consulta.ExecSQL;
  finally
    Consulta.Free;
  end;
end;

procedure TRepositorioFacturas.GuardarEmpresa(
  const ASolicitud: TSolicitudEmpresaFactura);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'CALL PRC_CREAR_ACTUALIZAR_EMPRESA(' +
      ':pCODIGO_EMPRESA, :pRAZONSOCIAL_EMPRESA, :pNIF_EMPRESA, ' +
      ':pMOVIL_EMPRESA, :pEMAIL_EMPRESA, :pDIRECCION1_EMPRESA, ' +
      ':pDIRECCION2_EMPRESA, :pPOBLACION_EMPRESA, ' +
      ':pPROVINCIA_EMPRESA, :pCPOSTAL_EMPRESA, :pPAIS_EMPRESA, ' +
      ':pCODPAIS_EMPRESA, :pRETENCIONES_EMPRESA, ' +
      ':pIVA_RECARGO_EMPRESA, :pREGIMENESPECIALAGRICOLA_EMPRESA, ' +
      ':pGRUPO_ZONA_IVA_EMPRESA, :pUSUARIO)';
    Consulta.ParamByName('pCODIGO_EMPRESA').AsString :=
      ASolicitud.Codigo;
    Consulta.ParamByName('pRAZONSOCIAL_EMPRESA').AsString :=
      ASolicitud.RazonSocial;
    Consulta.ParamByName('pNIF_EMPRESA').AsString :=
      ASolicitud.Nif;
    Consulta.ParamByName('pMOVIL_EMPRESA').AsString :=
      ASolicitud.Movil;
    Consulta.ParamByName('pEMAIL_EMPRESA').AsString :=
      ASolicitud.Email;
    Consulta.ParamByName('pDIRECCION1_EMPRESA').AsString :=
      ASolicitud.Direccion1;
    Consulta.ParamByName('pDIRECCION2_EMPRESA').AsString :=
      ASolicitud.Direccion2;
    Consulta.ParamByName('pPOBLACION_EMPRESA').AsString :=
      ASolicitud.Poblacion;
    Consulta.ParamByName('pPROVINCIA_EMPRESA').AsString :=
      ASolicitud.Provincia;
    Consulta.ParamByName('pCPOSTAL_EMPRESA').AsString :=
      ASolicitud.CodigoPostal;
    Consulta.ParamByName('pPAIS_EMPRESA').AsString :=
      ASolicitud.NombrePais;
    Consulta.ParamByName('pCODPAIS_EMPRESA').AsString :=
      ASolicitud.CodigoPais;
    Consulta.ParamByName('pRETENCIONES_EMPRESA').AsString :=
      ASolicitud.EsRetenciones;
    Consulta.ParamByName('pIVA_RECARGO_EMPRESA').AsString :=
      ASolicitud.EsIvaRecargo;
    Consulta.ParamByName(
      'pREGIMENESPECIALAGRICOLA_EMPRESA').AsString :=
      ASolicitud.EsRegimenEspecialAgricola;
    Consulta.ParamByName('pGRUPO_ZONA_IVA_EMPRESA').AsString :=
      ASolicitud.GrupoZonaIva;
    Consulta.ParamByName('pUSUARIO').AsString :=
      ASolicitud.Usuario;
    Consulta.ExecSQL;
  finally
    Consulta.Free;
  end;
end;

end.
