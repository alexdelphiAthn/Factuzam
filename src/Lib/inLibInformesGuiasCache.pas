{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInformesGuiasCache                                       }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       24/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Cache en memoria de fza_informes_guias indexada por INFORME_INFGUI.       }
{    Se precarga al login (igual que PrecargarPerfilesUsuario) para que        }
{    AbrirGuiasRuntime en los TfrmPrint no tenga que volver a consultar la     }
{    BBDD en cada click de Imprimir / PDF / Excel / Vista Preliminar /         }
{    Editar. La tabla es pequeña (decenas de filas como mucho), asi que la     }
{    carga completa cuesta lo mismo que una consulta puntual y elimina los     }
{    8 s recurrentes que se veian en log por la primera consulta caliente.    }
{******************************************************************************}
unit inLibInformesGuiasCache;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DBAccess, Uni;

type
  TInformeGuiaItem = record
    Codigo:        string;
    Informe:       string;
    Formato:       string;
    DatasetMaster: string;
    Tipo:          string;
    Tabla:         string;
    SqlStr:        string;
    MasterFields:  string;
    DetailFields:      string;
    Orden:             Integer;
    ColumnasVisibles:  string;
  end;

  TListaGuias      = TList<TInformeGuiaItem>;
  TGuiasPorInforme = TObjectDictionary<string, TListaGuias>;

  TInformesGuiasCache = class
  private
    FPorInforme: TGuiasPorInforme;
    FCargada:    Boolean;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   Precargar;
    procedure   Invalidar;
    // Devuelve las guias activas que aplican al (Informe, Formato) dado,
    // replicando el filtro del SELECT original: FORMATO_INFGUI = '' (guia
    // global) o FORMATO_INFGUI = aFormato (atada al .frx editado). El
    // resultado viene ordenado por ORDEN_INFGUI, CODIGO_INFGUI.
    function    Obtener(const aInforme,
                        aFormato: string): TArray<TInformeGuiaItem>;
    property    Cargada: Boolean read FCargada;
  end;

implementation

uses
  inLibGlobalVar;

constructor TInformesGuiasCache.Create;
begin
  inherited Create;
  FPorInforme := TGuiasPorInforme.Create([doOwnsValues]);
  FCargada    := False;
end;

destructor TInformesGuiasCache.Destroy;
begin
  FreeAndNil(FPorInforme);
  inherited;
end;

procedure TInformesGuiasCache.Invalidar;
begin
  FPorInforme.Clear;
  FCargada := False;
end;

procedure TInformesGuiasCache.Precargar;
var
  qry:         TUniQuery;
  item:        TInformeGuiaItem;
  sInformeKey: string;
  lst:         TListaGuias;
begin
  FPorInforme.Clear;
  FCargada := False;
  if (oConn = nil) or (not oConn.Connected) then
    Exit;
  try
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConn;
      // Cargamos solo las guias activas. ORDER BY (INFORME, ORDEN, CODIGO)
      // permite que Obtener pueda devolver el slice ya ordenado sin tener
      // que reordenar en memoria.
      qry.SQL.Text :=
        'SELECT CODIGO_INFGUI, INFORME_INFGUI, FORMATO_INFGUI, '       +
        '       DATASET_MASTER_INFGUI, TIPO_INFGUI, TABLA_INFGUI, '    +
        '       SQL_INFGUI, MASTER_FIELDS_INFGUI, DETAIL_FIELDS_INFGUI,' +
        '       ORDEN_INFGUI, COLUMNAS_VISIBLES_INFGUI '               +
        '  FROM fza_informes_guias '                                    +
        ' WHERE ESACTIVO_INFGUI = ''S'' '                               +
        ' ORDER BY INFORME_INFGUI, ORDEN_INFGUI, CODIGO_INFGUI';
      qry.Open;
      while not qry.Eof do
      begin
        item.Codigo        := qry.FieldByName('CODIGO_INFGUI').AsString;
        item.Informe       := qry.FieldByName('INFORME_INFGUI').AsString;
        item.Formato       := qry.FieldByName('FORMATO_INFGUI').AsString;
        item.DatasetMaster := qry.FieldByName('DATASET_MASTER_INFGUI').AsString;
        item.Tipo          := qry.FieldByName('TIPO_INFGUI').AsString;
        item.Tabla         := qry.FieldByName('TABLA_INFGUI').AsString;
        item.SqlStr        := qry.FieldByName('SQL_INFGUI').AsString;
        item.MasterFields  := qry.FieldByName('MASTER_FIELDS_INFGUI').AsString;
        item.DetailFields  := qry.FieldByName('DETAIL_FIELDS_INFGUI').AsString;
        item.Orden         := qry.FieldByName('ORDEN_INFGUI').AsInteger;
        item.ColumnasVisibles :=
          qry.FieldByName('COLUMNAS_VISIBLES_INFGUI').AsString;
        // Indexamos por nombre de informe en minusculas porque el INFORME
        // viene de Self.Name del TfrmPrint y el campo DB es varchar con
        // collation case-insensitive por defecto en MariaDB.
        sInformeKey := LowerCase(item.Informe);
        if not FPorInforme.TryGetValue(sInformeKey, lst) then
        begin
          lst := TListaGuias.Create;
          FPorInforme.Add(sInformeKey, lst);
        end;
        lst.Add(item);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
    FCargada := True;
  except
    // Si la precarga falla dejamos FCargada=False; AbrirGuiasRuntime
    // detecta el estado y sigue como si no hubiera guias (la app no
    // necesita guias para imprimir, solo se pierde el enriquecido).
    FPorInforme.Clear;
  end;
end;

function TInformesGuiasCache.Obtener(const aInforme,
                                     aFormato: string): TArray<TInformeGuiaItem>;
var
  lst:  TListaGuias;
  i, n: Integer;
  it:   TInformeGuiaItem;
begin
  SetLength(Result, 0);
  if not FCargada then
    Exit;
  if not FPorInforme.TryGetValue(LowerCase(aInforme), lst) then
    Exit;
  SetLength(Result, lst.Count);
  n := 0;
  for i := 0 to lst.Count - 1 do
  begin
    it := lst[i];
    // Replica el filtro del SELECT original: guia global ('' = aplica a
    // cualquier formato) o atada exactamente al formato pasado.
    if (it.Formato = '') or SameText(it.Formato, aFormato) then
    begin
      Result[n] := it;
      Inc(n);
    end;
  end;
  SetLength(Result, n);
end;

end.
