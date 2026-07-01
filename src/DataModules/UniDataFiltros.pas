{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFiltros                                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module transversal de filtros guardados de mantenimientos           }
{    (derivados de inMtoGen). Guarda el filtro de DataController.Filter con   }
{    nombre propio y permite compartirlo con usuarios o grupos, de forma      }
{    independiente al layout de columnas. Instancia unica: dmFiltros,         }
{    creada en TfrmMtoPrincipal junto a dmPerfiles/dmConn.                    }
{******************************************************************************}
unit UniDataFiltros;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni;

type
  TFiltroGuardadoInfo = record
    Id: Int64;
    Nombre: string;
    Descripcion: string;
    Propietario: string;
    EsPropio: Boolean;
  end;

  TFiltrosGuardadosList = TList<TFiltroGuardadoInfo>;

  TDestinoCompartidoInfo = record
    Id: Int64;
    TipoDestino: string;
    UsuarioGrupo: string;
  end;

  TDestinosCompartidosList = TList<TDestinoCompartidoInfo>;

  TdmFiltros = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
  public
    // Query de solo lectura para pintar la lista en el modal de gestion.
    // Las altas/bajas/cambios se hacen siempre con SQL directo (metodos de
    // abajo) y luego se refresca con AbrirListadoParaGrid.
    unqryListado: TUniQuery;
    dsListado: TDataSource;
    procedure AbrirListadoParaGrid(const AMto, AVista: string);
    function ListarFiltros(const AMto,
                           AVista: string): TFiltrosGuardadosList;
    function GuardarFiltroNuevo(const AMto,
                                AVista,
                                ANombre,
                                ADescripcion,
                                AFiltroBase64: string): Int64;
    procedure RenombrarFiltro(AIdFiltro: Int64;
                              const ANombre, ADescripcion: string);
    procedure BorrarFiltro(AIdFiltro: Int64);
    function EsPropietario(AIdFiltro: Int64): Boolean;
    function CargarFiltroBase64(AIdFiltro: Int64): string;
    function ListarDestinosCompartidos(
                             AIdFiltro: Int64): TDestinosCompartidosList;
    procedure CompartirConDestino(AIdFiltro: Int64;
                                  const ATipoDestino, ADestino: string);
    procedure QuitarDestinoCompartido(AIdDestino: Int64);
  end;

var
  dmFiltros: TdmFiltros;

implementation

uses
  inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

// SQL comun de visibilidad: propios + compartidos conmigo (usuario, mi
// grupo o 'Todos'). El propietario siempre ve su filtro aunque no lo haya
// compartido con nadie.
const
  cSqlVisibilidad =
    ' AND ( F.USUARIO_PROPIETARIO_FILT = :USUARIO ' +
    '    OR EXISTS ( ' +
    '         SELECT 1 ' +
    '           FROM fza_filtros_guardados_compartidos C ' +
    '          WHERE C.ID_FILT_FILTC = F.ID_FILT ' +
    '            AND ( (    C.TIPO_DESTINO_FILTC = ''USUARIO'' ' +
    '                   AND C.USUARIO_GRUPO_FILTC = :USUARIO) ' +
    '               OR (    C.TIPO_DESTINO_FILTC = ''GRUPO'' ' +
    '                   AND C.USUARIO_GRUPO_FILTC = :GRUPO) ' +
    '               OR      C.TIPO_DESTINO_FILTC = ''TODOS'')) ) ';

procedure TdmFiltros.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryListado := TUniQuery.Create(Self);
  dsListado := TDataSource.Create(Self);
  dsListado.DataSet := unqryListado;
end;

procedure TdmFiltros.AbrirListadoParaGrid(const AMto, AVista: string);
begin
  if unqryListado.Active then
  begin
    unqryListado.Close;
  end;
  unqryListado.Connection := oConn;
  unqryListado.SQL.Text :=
    '  SELECT F.ID_FILT, ' +
    '         F.NOMBRE_FILT, ' +
    '         F.DESCRIPCION_FILT, ' +
    '         F.USUARIO_PROPIETARIO_FILT, ' +
    '         CASE WHEN F.USUARIO_PROPIETARIO_FILT = :USUARIO ' +
    '              THEN ''S'' ELSE ''N'' END AS ESPROPIO_FILT ' +
    '    FROM fza_filtros_guardados F ' +
    '   WHERE F.MTO_FILT = :MTO ' +
    '     AND F.VISTA_FILT = :VISTA ' +
    cSqlVisibilidad +
    'ORDER BY ESPROPIO_FILT DESC, F.NOMBRE_FILT';
  unqryListado.ParamByName('MTO').AsString := AMto;
  unqryListado.ParamByName('VISTA').AsString := AVista;
  unqryListado.ParamByName('USUARIO').AsString := oUser;
  unqryListado.ParamByName('GRUPO').AsString := oGroup;
  unqryListado.Open;
end;

function TdmFiltros.ListarFiltros(const AMto,
                                  AVista: string): TFiltrosGuardadosList;
var
  qry: TUniQuery;
  info: TFiltroGuardadoInfo;
begin
  Result := TFiltrosGuardadosList.Create;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      '  SELECT F.ID_FILT, ' +
      '         F.NOMBRE_FILT, ' +
      '         F.DESCRIPCION_FILT, ' +
      '         F.USUARIO_PROPIETARIO_FILT ' +
      '    FROM fza_filtros_guardados F ' +
      '   WHERE F.MTO_FILT = :MTO ' +
      '     AND F.VISTA_FILT = :VISTA ' +
      cSqlVisibilidad +
      'ORDER BY F.USUARIO_PROPIETARIO_FILT <> :USUARIO, F.NOMBRE_FILT';
    qry.ParamByName('MTO').AsString := AMto;
    qry.ParamByName('VISTA').AsString := AVista;
    qry.ParamByName('USUARIO').AsString := oUser;
    qry.ParamByName('GRUPO').AsString := oGroup;
    qry.Open;
    while not qry.Eof do
    begin
      info.Id := qry.FieldByName('ID_FILT').AsLargeInt;
      info.Nombre := qry.FieldByName('NOMBRE_FILT').AsString;
      info.Descripcion := qry.FieldByName('DESCRIPCION_FILT').AsString;
      info.Propietario :=
        qry.FieldByName('USUARIO_PROPIETARIO_FILT').AsString;
      info.EsPropio := SameText(info.Propietario, oUser);
      Result.Add(info);
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmFiltros.GuardarFiltroNuevo(const AMto,
                                       AVista,
                                       ANombre,
                                       ADescripcion,
                                       AFiltroBase64: string): Int64;
var
  qry: TUniQuery;
begin
  Result := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'INSERT INTO fza_filtros_guardados ' +
      '  (MTO_FILT, VISTA_FILT, NOMBRE_FILT, DESCRIPCION_FILT, ' +
      '   FILTRO_FILT, USUARIO_PROPIETARIO_FILT, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:MTO, :VISTA, :NOMBRE, :DESCRIPCION, :FILTRO, :USUARIO, ' +
      '   CURRENT_TIMESTAMP, :USUARIO, :USUARIO)';
    qry.ParamByName('MTO').AsString := AMto;
    qry.ParamByName('VISTA').AsString := AVista;
    qry.ParamByName('NOMBRE').AsString := ANombre;
    qry.ParamByName('DESCRIPCION').AsString := ADescripcion;
    // ftMemo explicito: el filtro serializado en Base64 puede superar
    // facilmente el tamano por defecto que UniDAC infiere para un
    // parametro de texto no declarado (igual que pVALUE_TEXT en
    // UniDataPerfiles.GrabarPerfil).
    qry.ParamByName('FILTRO').DataType := ftMemo;
    qry.ParamByName('FILTRO').AsString := AFiltroBase64;
    qry.ParamByName('USUARIO').AsString := oUser;
    qry.Execute;
    qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    qry.Open;
    if not qry.IsEmpty then
    begin
      Result := qry.FieldByName('ID').AsLargeInt;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmFiltros.RenombrarFiltro(AIdFiltro: Int64;
                                     const ANombre, ADescripcion: string);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'UPDATE fza_filtros_guardados ' +
      '   SET NOMBRE_FILT = :NOMBRE, ' +
      '       DESCRIPCION_FILT = :DESCRIPCION, ' +
      '       USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_FILT = :ID ' +
      '   AND USUARIO_PROPIETARIO_FILT = :USUARIO';
    qry.ParamByName('NOMBRE').AsString := ANombre;
    qry.ParamByName('DESCRIPCION').AsString := ADescripcion;
    qry.ParamByName('USUARIO').AsString := oUser;
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmFiltros.BorrarFiltro(AIdFiltro: Int64);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    // No hay FK fisica (convencion del proyecto): borramos primero los
    // destinos compartidos y despues la cabecera, en una transaccion.
    oConn.StartTransaction;
    try
      qry.SQL.Text :=
        'DELETE FROM fza_filtros_guardados_compartidos ' +
        ' WHERE ID_FILT_FILTC = :ID';
      qry.ParamByName('ID').AsLargeInt := AIdFiltro;
      qry.Execute;
      qry.SQL.Text :=
        'DELETE FROM fza_filtros_guardados ' +
        ' WHERE ID_FILT = :ID ' +
        '   AND USUARIO_PROPIETARIO_FILT = :USUARIO';
      qry.ParamByName('ID').AsLargeInt := AIdFiltro;
      qry.ParamByName('USUARIO').AsString := oUser;
      qry.Execute;
      oConn.Commit;
    except
      oConn.Rollback;
      raise;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmFiltros.EsPropietario(AIdFiltro: Int64): Boolean;
var
  qry: TUniQuery;
begin
  Result := False;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT 1 ' +
      '  FROM fza_filtros_guardados ' +
      ' WHERE ID_FILT = :ID ' +
      '   AND USUARIO_PROPIETARIO_FILT = :USUARIO';
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.ParamByName('USUARIO').AsString := oUser;
    qry.Open;
    Result := not qry.IsEmpty;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmFiltros.CargarFiltroBase64(AIdFiltro: Int64): string;
var
  qry: TUniQuery;
begin
  Result := '';
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT FILTRO_FILT ' +
      '  FROM fza_filtros_guardados ' +
      ' WHERE ID_FILT = :ID';
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.Open;
    if not qry.IsEmpty then
    begin
      Result := qry.FieldByName('FILTRO_FILT').AsString;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

function TdmFiltros.ListarDestinosCompartidos(
                              AIdFiltro: Int64): TDestinosCompartidosList;
var
  qry: TUniQuery;
  info: TDestinoCompartidoInfo;
begin
  Result := TDestinosCompartidosList.Create;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      '  SELECT ID_FILTC, TIPO_DESTINO_FILTC, USUARIO_GRUPO_FILTC ' +
      '    FROM fza_filtros_guardados_compartidos ' +
      '   WHERE ID_FILT_FILTC = :ID ' +
      'ORDER BY TIPO_DESTINO_FILTC, USUARIO_GRUPO_FILTC';
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.Open;
    while not qry.Eof do
    begin
      info.Id := qry.FieldByName('ID_FILTC').AsLargeInt;
      info.TipoDestino := qry.FieldByName('TIPO_DESTINO_FILTC').AsString;
      info.UsuarioGrupo := qry.FieldByName('USUARIO_GRUPO_FILTC').AsString;
      Result.Add(info);
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmFiltros.CompartirConDestino(AIdFiltro: Int64;
                                        const ATipoDestino,
                                              ADestino: string);
var
  qry: TUniQuery;
  sDestino: string;
begin
  sDestino := ADestino;
  if SameText(ATipoDestino, 'TODOS') then
  begin
    sDestino := '';
  end;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'INSERT INTO fza_filtros_guardados_compartidos ' +
      '  (ID_FILT_FILTC, USUARIO_GRUPO_FILTC, TIPO_DESTINO_FILTC, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:ID, :DESTINO, :TIPO, CURRENT_TIMESTAMP, :USUARIO, :USUARIO) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  USUARIO_MODIF = VALUES(USUARIO_MODIF)';
    qry.ParamByName('ID').AsLargeInt := AIdFiltro;
    qry.ParamByName('DESTINO').AsString := sDestino;
    qry.ParamByName('TIPO').AsString := UpperCase(ATipoDestino);
    qry.ParamByName('USUARIO').AsString := oUser;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmFiltros.QuitarDestinoCompartido(AIdDestino: Int64);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'DELETE FROM fza_filtros_guardados_compartidos ' +
      ' WHERE ID_FILTC = :ID';
    qry.ParamByName('ID').AsLargeInt := AIdDestino;
    qry.Execute;
  finally
    FreeAndNil(qry);
  end;
end;

initialization
  ForceReferenceToClass(TdmFiltros);
end.
