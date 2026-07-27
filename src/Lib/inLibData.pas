{******************************************************************************}
{                                                                              }
{  Módulo:       inLibData                                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de acceso a datos auxiliares.                                  }
{    Lecturas puntuales sobre una conexión proporcionada por el consumidor.   }
{******************************************************************************}
unit inLibData;

interface
uses
  Uni, System.SysUtils, System.Variants, Data.DB;

function AlmacenPerteneceEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): Boolean;
function PrimerAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;
function ResolverAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): string;
procedure AjustarEmpresaAlmacenDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoEmpresa, ACampoAlmacen: string);
procedure AjustarEmpresasAlmacenesDocumento(AConexion: TUniConnection;
  ADataSet: TDataSet);
function ObtenerAlmacenDepositoEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;
// Locate generico sobre la clave primaria (uno o varios campos
// separados por coma). Lo usan TfrmMtoGen.LocalizarYEnfocar y las
// busquedas externas entre pantallas. Antes vivia en inLibShowMto.
function BuscarTabla(AQuery: TUniQuery;
                     const AClavePrimaria,
                     AValoresBusqueda: string): Boolean;

implementation

uses
  inLibMsg;

function BuscarTabla(AQuery: TUniQuery;
                     const AClavePrimaria,
                     AValoresBusqueda: string): Boolean;
var
  ValArr: TArray<string>;
  bIsOnlyOne: Boolean;
  i: Integer;
  miArray: array of Variant;
begin
  bIsOnlyOne := False;
  Result := False;
  ValArr := AValoresBusqueda.Split([',']);
  if Length(ValArr) = 1 then
    bIsOnlyOne := True
  else
  begin
    SetLength(miArray, Length(ValArr));
    for i := 0 to Length(ValArr) - 1 do
      miArray[i] := Trim(ValArr[i]);
  end;
  if AQuery.Active then
  begin
    if bIsOnlyOne then
    begin
      if AQuery.Locate(AClavePrimaria, AValoresBusqueda, []) then
        Result := True;
    end
    else
    begin
      if AQuery.Locate(AClavePrimaria, miArray, []) then
      begin
        Finalize(ValArr);
        Finalize(miArray);
        Result := True;
      end;
    end;
  end;
end;

function AlmacenPerteneceEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): Boolean;
var
  QryAlm: TUniQuery;
begin
  Result := False;
  if (AConexion <> nil) and (Trim(AEmpresa) <> '') and
     (Trim(AAlmacen) <> '') then
  begin
    QryAlm := TUniQuery.Create(nil);
    try
      QryAlm.Connection := AConexion;
      QryAlm.SQL.Text :=
        'SELECT 1 ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_EMP_ALM = :EMPRESA ' +
        '   AND CODIGO_ALM_ALM = :ALMACEN ' +
        ' LIMIT 1';
      QryAlm.ParamByName('EMPRESA').AsString := Trim(AEmpresa);
      QryAlm.ParamByName('ALMACEN').AsString := Trim(AAlmacen);
      QryAlm.Open;
      Result := not QryAlm.IsEmpty;
    finally
      FreeAndNil(QryAlm);
    end;
  end;
end;

function PrimerAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;
var
  QryAlm: TUniQuery;
begin
  Result := '';
  if (AConexion <> nil) and (Trim(AEmpresa) <> '') then
  begin
    QryAlm := TUniQuery.Create(nil);
    try
      QryAlm.Connection := AConexion;
      QryAlm.SQL.Text :=
        'SELECT CODIGO_ALM_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_EMP_ALM = :EMPRESA ' +
        '   AND COALESCE(ESACTIVO_ALM, ''S'') = ''S'' ' +
        ' ORDER BY COALESCE(ORDEN_ALM, 2147483647), CODIGO_ALM_ALM ' +
        ' LIMIT 1';
      QryAlm.ParamByName('EMPRESA').AsString := Trim(AEmpresa);
      QryAlm.Open;
      if not QryAlm.IsEmpty then
        Result := QryAlm.FieldByName('CODIGO_ALM_ALM').AsString;
    finally
      FreeAndNil(QryAlm);
    end;
  end;
end;

function ResolverAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): string;
begin
  Result := Trim(AAlmacen);
  if (AConexion <> nil) and (Trim(AEmpresa) <> '') and
     (Trim(AEmpresa) <> '0') and
     not AlmacenPerteneceEmpresa(AConexion, AEmpresa, AAlmacen) then
  begin
    Result := PrimerAlmacenEmpresa(AConexion, AEmpresa);
    if Result = '' then
      raise Exception.Create(Format(SErrorEmpresaSinAlmacenActivo,
                                    [Trim(AEmpresa)]));
  end;
end;

procedure AjustarEmpresaAlmacenDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoEmpresa, ACampoAlmacen: string);
var
  CampoAlmacen: TField;
  CampoEmpresa: TField;
  AlmacenCorrecto: string;
begin
  if (ADataSet <> nil) and (AConexion <> nil) then
  begin
    CampoEmpresa := ADataSet.FindField(ACampoEmpresa);
    CampoAlmacen := ADataSet.FindField(ACampoAlmacen);
    if (CampoEmpresa <> nil) and (CampoAlmacen <> nil) then
    begin
      AlmacenCorrecto := ResolverAlmacenEmpresa(AConexion,
        CampoEmpresa.AsString, CampoAlmacen.AsString);
      if not SameText(Trim(CampoAlmacen.AsString), AlmacenCorrecto) then
        CampoAlmacen.AsString := AlmacenCorrecto;
    end;
  end;
end;

procedure AjustarEmpresasAlmacenesDocumento(AConexion: TUniConnection;
  ADataSet: TDataSet);
begin
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_ALB', 'CODIGO_ALM_ALB');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_PED', 'CODIGO_ALM_PED');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_FAC', 'CODIGO_ALM_FAC');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_ALBC', 'CODIGO_ALM_ALBC');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_PEDC', 'CODIGO_ALM_PEDC');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_FACC', 'CODIGO_ALM_FACC');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_DEVC', 'CODIGO_ALM_DEVC');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_SES', 'CODIGO_ALM_SES');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_SESDOC', 'CODIGO_ALM_SESDOC');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_INV', 'CODIGO_ALM_INV');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_DTR', 'CODIGO_ALM_DTR');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_PDR', 'CODIGO_ALM_PDR');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_DEP', 'CODIGO_ALM_DEP');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_ARQ', 'CODIGO_ALM_ARQ');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_PAGO', 'CODIGO_ALM_PAGO');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_OPCAJA', 'CODIGO_ALM_OPCAJA');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_CONTRA_OPCAJA', 'CODIGO_ALM_CONTRA_OPCAJA');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_EMI_VL', 'CODIGO_ALM_EMI_VL');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_RED_VL', 'CODIGO_ALM_RED_VL');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_TRSOL', 'CODIGO_ALM_ORIGEN_TRSOL');
  AjustarEmpresaAlmacenDataSet(AConexion, ADataSet,
    'CODIGO_EMP_CONTRA_TRSOL', 'CODIGO_ALM_DESTINO_TRSOL');
end;

function ObtenerAlmacenDepositoEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;
var
  QryAlm: TUniQuery;
begin
  Result := '';
  QryAlm := TUniQuery.Create(nil);
  try
    // Usamos la conexión global del sistema
    QryAlm.Connection := AConexion;
    QryAlm.SQL.Text :=
      'SELECT CODIGO_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE CODIGO_EMP_ALM = :EMP ' +
      '   AND ESACTIVO_ALM = ''S'' ' +
      '   AND TIPO_USO_ALM IN (''DEPÓSITO'', ''DEPOSITO'') ' +
      ' LIMIT 1';
    QryAlm.ParamByName('EMP').AsString := AEmpresa;
    QryAlm.Open;
    if not QryAlm.IsEmpty then
      Result := QryAlm.FieldByName('CODIGO_ALM_ALM').AsString
    else
      // Lanzamos excepción para que la transacción de caja se detenga si hay un
      // error de configuración
      raise Exception.Create(Format(SErrorAlmacenDepositosEmpresaNoEncontrado,
                                    [AEmpresa]));
  finally
    FreeAndNil(QryAlm);
  end;
end;


end.
