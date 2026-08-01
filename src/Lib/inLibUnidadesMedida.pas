{******************************************************************************}
{                                                                              }
{  Módulo:       inLibUnidadesMedida                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caché de unidades de medida (fza_unidades_medida) y utilidades de         }
{    formato. Centraliza cuántos decimales muestra cada unidad y la            }
{    conversión a la unidad estándar de su magnitud (cm/mm->m, g->kg...).      }
{    Lo usan ficha de artículo, líneas de documento, tickets e informes.       }
{******************************************************************************}
unit inLibUnidadesMedida;

interface

uses
  System.Generics.Collections, System.Generics.Defaults, System.SysUtils, Uni;

type
  TUnidadInfo = class
  public
    Codigo     : string;
    Descripcion: string;
    Decimales  : Integer;
    Magnitud   : string;
    EsBase     : Boolean;
    FactorBase : Double;
  end;

  TUnidadesMedida = class
  private
    FConexion: TUniConnection;
    FUnidades: TObjectDictionary<string, TUnidadInfo>;
    FDecimalesPorDefecto: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AsignarConexion(AConexion: TUniConnection);
    // (Re)carga la cache desde fza_unidades_medida. Tolera tabla ausente o
    // conexion cerrada: deja la cache vacia y aplican los valores por defecto.
    procedure Cargar;
    function Existe(const ACodigo: string): Boolean;
    // Info de la unidad o nil si no esta en la cache.
    function Info(const ACodigo: string): TUnidadInfo;
    // Decimales de la unidad; DecimalesPorDefecto si no se conoce.
    function Decimales(const ACodigo: string): Integer;
    // Mascara FormatFloat / DisplayFormat: '0', '0.00', '0.000'...
    function Mascara(const ACodigo: string): string;
    // Cantidad ya formateada con los decimales de su unidad.
    function Formatear(const AValor: Double; const ACodigo: string): string;
    // True si origen y destino pertenecen a la misma magnitud (convertibles).
    function MismaMagnitud(const AOrigen, ADestino: string): Boolean;
    // Convierte un valor entre unidades de la misma magnitud. Si no son
    // convertibles (magnitud distinta o desconocida) devuelve el valor tal cual.
    function Convertir(const AValor: Double;
                       const AOrigen, ADestino: string): Double;
    // Decimales que se aplican cuando la unidad es vacia o desconocida.
    // Por defecto 0 (comportamiento "Unidades", sin decimales).
    property DecimalesPorDefecto: Integer read FDecimalesPorDefecto
                                          write FDecimalesPorDefecto;
  end;
  IProveedorUnidadesMedida = interface
    ['{5B714E5F-795D-4DDB-A3C0-6CFB54F535D9}']
    function GetUnidadesMedida: TUnidadesMedida;
    property UnidadesMedida: TUnidadesMedida
      read GetUnidadesMedida;
  end;

implementation

uses
  inLibLog;

{ TUnidadesMedida }

constructor TUnidadesMedida.Create;
begin
  inherited;
  FConexion := nil;
  // Comparador sin distincion de mayusculas: 'Uds' y 'uds' son la misma unidad.
  FUnidades := TObjectDictionary<string, TUnidadInfo>.Create([doOwnsValues],
                                                  TIStringComparer.Ordinal);
  FDecimalesPorDefecto := 0;
end;

destructor TUnidadesMedida.Destroy;
begin
  FreeAndNil(FUnidades);
  inherited;
end;

procedure TUnidadesMedida.AsignarConexion(AConexion: TUniConnection);
begin
  FConexion := AConexion;
end;

procedure TUnidadesMedida.Cargar;
var
  qry: TUniQuery;
  oInfo: TUnidadInfo;
  sCod: string;
begin
  FUnidades.Clear;
  if (FConexion = nil) or (not FConexion.Connected) then
    Exit;
  qry := TUniQuery.Create(nil);
  try
    try
      qry.Connection := FConexion;
      qry.SQL.Text :=
        'SELECT CODIGO_UNIMED, DESCRIPCION_UNIMED, DECIMALES_UNIMED,' +
        '       MAGNITUD_UNIMED, ESBASE_UNIMED, FACTOR_BASE_UNIMED' +
        '  FROM fza_unidades_medida';
      qry.Open;
      while not qry.Eof do
      begin
        sCod := Trim(qry.FieldByName('CODIGO_UNIMED').AsString);
        if sCod <> '' then
        begin
          oInfo := TUnidadInfo.Create;
          oInfo.Codigo      := sCod;
          oInfo.Descripcion := qry.FieldByName('DESCRIPCION_UNIMED').AsString;
          oInfo.Decimales   := qry.FieldByName('DECIMALES_UNIMED').AsInteger;
          oInfo.Magnitud    := qry.FieldByName('MAGNITUD_UNIMED').AsString;
          oInfo.EsBase      := SameText(
                            qry.FieldByName('ESBASE_UNIMED').AsString, 'S');
          oInfo.FactorBase  := qry.FieldByName('FACTOR_BASE_UNIMED').AsFloat;
          FUnidades.AddOrSetValue(sCod, oInfo);
        end;
        qry.Next;
      end;
    except
      // Tabla aun no creada o error de lectura: no rompemos el arranque,
      // la cache queda vacia y se usan los decimales por defecto.
      on E: Exception do
      begin
        if Log() <> nil then
          Log.LogWarning('inLibUnidadesMedida.Cargar: ' + E.Message);
      end;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

function TUnidadesMedida.Existe(const ACodigo: string): Boolean;
begin
  Result := FUnidades.ContainsKey(Trim(ACodigo));
end;

function TUnidadesMedida.Info(const ACodigo: string): TUnidadInfo;
begin
  if not FUnidades.TryGetValue(Trim(ACodigo), Result) then
    Result := nil;
end;

function TUnidadesMedida.Decimales(const ACodigo: string): Integer;
var
  oInfo: TUnidadInfo;
begin
  oInfo := Info(ACodigo);
  if oInfo <> nil then
    Result := oInfo.Decimales
  else
    Result := FDecimalesPorDefecto;
end;

function TUnidadesMedida.Mascara(const ACodigo: string): string;
var
  iDec: Integer;
begin
  iDec := Decimales(ACodigo);
  if iDec <= 0 then
    Result := '0'
  else
    Result := '0.' + StringOfChar('0', iDec);
end;

function TUnidadesMedida.Formatear(const AValor: Double;
                                   const ACodigo: string): string;
begin
  Result := FormatFloat(Mascara(ACodigo), AValor);
end;

function TUnidadesMedida.MismaMagnitud(const AOrigen, ADestino: string): Boolean;
var
  oOri, oDes: TUnidadInfo;
begin
  oOri := Info(AOrigen);
  oDes := Info(ADestino);
  Result := (oOri <> nil) and (oDes <> nil) and
            SameText(oOri.Magnitud, oDes.Magnitud);
end;

function TUnidadesMedida.Convertir(const AValor: Double;
                                   const AOrigen, ADestino: string): Double;
var
  oOri, oDes: TUnidadInfo;
begin
  oOri := Info(AOrigen);
  oDes := Info(ADestino);
  // Solo convertimos dentro de la misma magnitud y con factor destino valido.
  if (oOri = nil) or (oDes = nil) or
     (not SameText(oOri.Magnitud, oDes.Magnitud)) or
     (oDes.FactorBase = 0) then
    Result := AValor
  else
    Result := AValor * oOri.FactorBase / oDes.FactorBase;
end;

end.
