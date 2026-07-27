{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotos                                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestion de fotos por articulo y SKU.                                      }
{    Guardado, redimensionado (300/600/real) y resolucion con fallback         }
{    SKU -> articulo, analogo al de tarifas.                                   }
{    Sustitucion de TfrxPictureView foto300/foto600/fotoReal en FastReports.   }
{******************************************************************************}
unit inLibFotos;

{
  Unidad: inLibFotos
  Descripcion:
    Encapsula la persistencia, redimensionado y resolucion de fotos de
    articulos y SKUs. La tabla fza_articulos_fotos guarda una fila por
    foto registrada (a nivel articulo cuando CODIGO_UNIDAD_FOT = '',
    a nivel SKU en otro caso); las imagenes viven en
    `ParametrosApp.GetPath('appDirFotos')` repartidas en tres subcarpetas
    siempre como PNG:

      300/   PNG redimensionado a 300 px (lado mayor)
      600/   PNG redimensionado a 600 px (lado mayor)
      real/  PNG en la resolucion original (sin redimensionar, sin
             perdida)

    El nombre de fichero base (`NOMBRE_FOT_FOT`) es estable y se genera al
    alta a partir del par (articulo, sku) y se conserva mientras la foto
    exista. Reemplazar la foto reescribe los ficheros pero mantiene el
    nombre.

    Resolucion (analogo al fallback de tarifas):
      1. Si hay foto del SKU, esa.
      2. Si no, fotos por prefijos del SKU separados por '/'.
      3. Si no, foto del articulo padre.
      4. Sin SKU, si no hay foto general, primera foto por color.
      5. Si no, vacio.

  Constantes para nombres de columna SQL: vease seccion `const` mas abajo.
}

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.StrUtils, System.IOUtils,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls, Vcl.Imaging.PngImage,
  Vcl.Imaging.Jpeg, Vcl.Imaging.GIFImg,
  Data.DB, DBAccess, Uni,
  frxClass, frxDBSet, inLibParametrosIntf;

const
  // Columnas de fza_articulos_fotos
  fcodartfot     = 'CODIGO_ART_FOT';
  fcodunidadfot  = 'CODIGO_UNIDAD_FOT';
  fnomfot        = 'NOMBRE_FOT_FOT';
  fextfot        = 'EXTENSION_ORIGEN_FOT';
  finstalta      = 'INSTANTE_ALTA';
  finstmodif     = 'INSTANTE_MODIF';
  fusralta       = 'USUARIO_ALTA';
  fusrmodif      = 'USUARIO_MODIF';

  // Sub-carpetas dentro de appDirFotos
  cSubdir300  = '300';
  cSubdir600  = '600';
  cSubdirReal = 'real';

  // Tamaños (lado mayor) que se generan al guardar
  cLado300 = 300;
  cLado600 = 600;

type
  TFotoResolucion = (frPx300, frPx600, frReal);

  TFotoOrigen = (
    foSinFoto,
    foArticulo,        // fila CODIGO_UNIDAD_FOT = ''
    foSkuPrefijo,      // fila con prefijo del SKU (ej. 'BLUS-SEDA/BLANCO')
    foSku              // fila exacta del SKU completo
  );

  TFotoInfo = record
    Encontrada      : Boolean;
    Origen          : TFotoOrigen;
    CodigoArt       : string;
    CodigoSku       : string;       // el SKU que se pidio resolver
    ClaveResuelta   : string;       // el CODIGO_UNIDAD_FOT que matcheo
                                    //   '' = articulo
                                    //   SKU completo o prefijo si no
    NombreBase      : string;       // NOMBRE_FOT_FOT (sin extension)
    ExtensionOrigen : string;       // sin punto (png, jpg, jpeg, ...)
    procedure Clear;
  end;

  /// Acceso al sistema de fotos. Vive como singleton `oFotos` igual que
  /// `ParametrosApp`. La conexión se asigna desde la raíz de composición.
  TFotosArticulos = class
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    // Caché de precarga a nivel artículo (código artículo -> foto resuelta).
    // Cuando está activa, Resolver(art, '') la consulta en vez de ir a BBDD,
    // evitando el N+1 en informes con muchas fotos. La llena PrecargarFotosLote
    // (una sola consulta) y la vacía LimpiarPrecargaFotos.
    FCachePrecarga: TDictionary<string, TFotoInfo>;
    function DirBase: string;
    function SubdirDe(AResolucion: TFotoResolucion): string;
    // Nombre base SIN el sufijo _NNN: codigo de SKU si lo hay, en su
    // defecto codigo de articulo. Sanitiza los caracteres problematicos.
    function ClaveNombre(const ACodArt, ACodSku: string): string;
    // NOMBRE_FOT_FOT completo `<clave>_<NNN>`.
    function ComponerNombre(const AClave: string;
                            AIndice: Integer): string;
    // Extrae el sufijo numerico de un NOMBRE_FOT_FOT existente. Si la
    // cadena no termina en _NNN devuelve 0.
    function ExtraerIndice(const ANombre: string): Integer;
    procedure GuardarRedimensionado(const AOriginal: TGraphic;
                                    const ARutaPng: string;
                                    ALadoMayor: Integer);
    procedure GuardarComoPng(const AOriginal: TGraphic;
                             const ARutaPng: string);
    function CargarGraficoDeFichero(const ARuta: string): TGraphic;
    procedure RotarBitmap90(ABitmap: TBitmap; AHorario: Boolean);
    procedure RotarFicheroPng(const ARuta: string; AHorario: Boolean);
    procedure BorrarFicherosDeNombre(const ANombreBase: string);
  public
    procedure AsignarConexion(
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion);
    procedure LiberarServicios;
    /// Ruta del fichero para una foto resuelta, en la resolucion pedida.
    /// Devuelve '' si AInfo.Encontrada = False o si el fichero no existe.
    function RutaFoto(const AInfo: TFotoInfo;
                      AResolucion: TFotoResolucion): string;

    /// Resuelve la foto aplicable a (articulo, sku) con fallback al padre.
    /// Si ACodSku = '', busca la foto de articulo y, si no existe, la
    /// primera foto disponible por color.
    function Resolver(const ACodArt, ACodSku: string): TFotoInfo;

    /// Resuelve en UNA sola consulta la foto a nivel articulo de una lista
    /// de articulos (evita el N+1 de llamar a Resolver por cada uno). El
    /// diccionario resultante lo libera el llamador. Aplica el mismo criterio
    /// que Resolver(art, '') sin SKU: foto de articulo (CODIGO_UNIDAD_FOT='')
    /// y, si no la hay, la primera foto disponible por color.
    function ResolverArticulosLote(
      const ACodigos: TArray<string>): TDictionary<string, TFotoInfo>;

    /// Precarga en UNA consulta las fotos a nivel artículo de la lista y deja
    /// la caché activa: las siguientes llamadas a Resolver(art, '') la usan en
    /// vez de ir a BBDD (evita el N+1 en informes con muchas fotos). Llamar
    /// antes de PrepareReport y vaciar con LimpiarPrecargaFotos al terminar.
    procedure PrecargarFotosLote(const ACodigos: TArray<string>);
    /// Vacía la caché de precarga (vuelve a resolución directa por consulta).
    procedure LimpiarPrecargaFotos;
    destructor Destroy; override;

    /// Importa una foto desde un fichero de origen, generando las tres
    /// resoluciones bajo appDirFotos. Inserta/actualiza la fila en
    /// fza_articulos_fotos. ACodSku = '' guarda foto a nivel articulo.
    /// El indice incremental garantiza que cada guardado produce un
    /// nombre nuevo (`<clave>_<NNN>`) y borra los ficheros anteriores,
    /// asi se invalida cualquier cache por nombre de fichero.
    function Guardar(const ACodArt, ACodSku, AFicheroOrigen,
      AUsuario: string): TFotoInfo;

    /// Gira las tres copias de la foto (300/600/real) 90 grados en el
    /// sentido indicado y avanza el indice. La fila de BBDD apunta al
    /// nuevo nombre y los ficheros anteriores se borran.
    function Rotar(const ACodArt, ACodSku: string;
                   AHorario: Boolean;
                   const AUsuario: string): TFotoInfo;

    /// Elimina la foto (BBDD + ficheros 300/600/real). `ACodUnidad` es
    /// el valor exacto de `CODIGO_UNIDAD_FOT`: cadena vacia para la
    /// foto del articulo, SKU completo, o prefijo de SKU.
    procedure Eliminar(const ACodArt, ACodUnidad: string);

    /// Sesiones de compra: guarda una foto contra una linea de sesion
    /// (el articulo todavia no esta en fza_articulos). Usa la misma
    /// logica de 300/600/real (todos PNG) que `Guardar`, pero contra
    /// `fza_compras_sesiones_fotos` y con prefijo de fichero
    /// `ses_<SERIE>_<NUMERO>_<LINEA>_`. `ACodUnidad` = '' guarda foto
    /// a nivel de la linea (articulo padre); != '' la asocia a un SKU
    /// concreto o prefijo dentro del codigo tentativo.
    function GuardarSesion(const ASerieSes, ANumeroSes: string;
                           ALinea: Integer;
                           const ACodArtTentativo, ACodUnidad,
                                 AFicheroOrigen, AUsuario: string): TFotoInfo;

    /// Resuelve la foto aplicable a una linea de sesion. Como `Resolver`
    /// pero contra fza_compras_sesiones_fotos. Si ACodUnidad = '' busca
    /// solo a nivel linea (articulo padre).
    function ResolverSesion(const ASerieSes, ANumeroSes: string;
                            ALinea: Integer;
                            const ACodUnidad: string = ''): TFotoInfo;

    /// Borra una foto de sesion (BBDD + ficheros 300/600/real).
    procedure EliminarSesion(const ASerieSes, ANumeroSes: string;
                             ALinea: Integer;
                             const ACodUnidad: string);

    /// Materializacion: para cada fila de fza_compras_sesiones_fotos
    /// con (SERIE, NUMERO, LINEA) -> renombra los PNG quitando el
    /// prefijo ses_<SERIE>_<NUMERO>_<LINEA>_ y poniendo
    /// <ACodigoArt>_<NNN>, inserta en fza_articulos_fotos y borra la
    /// fila de origen. Idempotente: si ya existe la fila destino
    /// (mismo CODIGO_ART_FOT + CODIGO_UNIDAD_FOT), conserva el nombre
    /// nuevo y borra ambos rastros del lado sesion.
    procedure MigrarFotosSesion(const ASerieSes, ANumeroSes: string;
                                ALinea: Integer;
                                const ACodigoArt, AUsuario: string);

    /// Handler enganchado a `TfrxReport.OnBeforePrint`. FastReport lo
    /// invoca antes de pintar cada componente del informe en cada
    /// iteracion. Si el componente es un TfrxPictureView llamado
    /// foto300/foto600/fotoreal, refresca su Picture con la foto del
    /// registro actual del DataSet de su banda padre. Es la pieza que
    /// hace que en informes iterativos (etiquetas) cada fila salga con
    /// su foto y no con la del primero.
    procedure HandlerReportBeforePrint(Component: TfrxReportComponent);
    property Conexion: TUniConnection read FConexion;
  end;

/// Engancha el evento Delphi `Report.OnBeforePrint` para que en cada
/// iteracion del informe FastReport refresque los TfrxPictureView
/// llamados foto300/foto600/fotoReal con la foto resuelta del par
/// (articulo, sku) del DataSet de la banda padre. Llamar desde
/// `AfterReportLoaded` (antes de PrepareReport). El handler se dispara
/// para cada View justo antes de pintarse, asi en informes iterativos
/// (etiquetas, tickets con detalle) cada fila se imprime con la foto
/// que toca y no con la del primer registro. Si el par no se puede
/// inferir (no hay banda con dataset, o no estan los campos), la
/// imagen se limpia (queda en blanco).
procedure EngancharFotosEnReport(Report: TfrxReport);

/// Localiza la banda padre de un componente del informe y devuelve su
/// TDataSet (con fallback al primer dataset del report). Tambien la usa
/// inLibVerifactu para resolver la factura del registro activo al
/// sustituir el QR tributario ('qrverifactu').
function ObtenerDataSetDeBandaPadre(AObj: TfrxComponent): TDataSet;

/// Genera la lista de claves candidatas para `CODIGO_UNIDAD_FOT` a partir
/// de un `CODIGO_UNIDAD_SKU`, en orden de mas a menos especifica:
///   ['BLUS-SEDA/BLANCO/L', 'BLUS-SEDA/BLANCO']
/// Se cortan los segmentos por '/'. Se descarta cualquier prefijo sin
/// '/' (corresponderia al codigo de articulo, que se busca via fila
/// con CODIGO_UNIDAD_FOT = ''). Si ACodSku = '' o no contiene '/'
/// devuelve `[ACodSku]` o vacio.
function GenerarPrefijosSku(const ACodSku: string): TArray<string>;

/// Lee el codigo de articulo y de SKU del registro activo de un
/// DataSet, recorriendo los alias canonicos del esquema (CODIGO_ART_*,
/// CODIGO_UNIDAD_*). Esta funcion es la fuente unica de aliases para
/// el subsistema de fotos: la usan
///   - `TfrmMtoGen.ResolverArtSkuActivo` (sobre dsTablaG)
///   - Los overrides en Facturas / Tarifas / Pedidos / Albaranes (sobre
///     el dataset del sub-grid de detalle)
///   - `inMtoCajaOpe.RefrescarFotoStock` (sobre dsLineas)
///   - `inMtoConsultaOpe.ResolverArtSkuDeFacLin` (sobre cxViewFacLin)
///   - `SustituirFotoEnPicture` (sobre el dataset de la banda padre)
///   - `TFotoEmbebida.OnDataChange` (sobre el dataset hookeado)
/// Si el dataset es nil, no esta activo o esta vacio devuelve '' / ''.
procedure LeerArtSkuDeDataSet(ADataSet: TDataSet;
                              out ACodArt, ACodSku: string);

type
  /// Helper para poner una foto embebida en un Mto. Engancha el
  /// `OnDataChange` del DataSource (encadenando el handler previo si
  /// lo habia) y mantiene un `TImage` cargado con la foto a 300 px del
  /// articulo / SKU activo. Liberar con FreeAndNil restaura el handler
  /// previo.
  ///
  /// Patron de uso en un Mto:
  ///   - DFM: TPanel + TcxSplitter + TImage (Align = alClient)
  ///   - FormCreate: FFoto := TFotoEmbebida.Create(imgFoto, dsLineas);
  ///   - FormDestroy: FreeAndNil(FFoto);
  ///   - Layout persist: GuardarAnchoPanel / RestaurarAnchoPanel sobre
  ///     el panel contenedor (vease inLibLayoutForm).
  TFotoEmbebida = class
  private
    FImage          : TImage;
    FDataSource     : TDataSource;
    FPrevDataChange : TDataChangeEvent;
    procedure OnDataChange(Sender: TObject; Field: TField);
  public
    constructor Create(AImage: TImage; ADataSource: TDataSource);
    destructor  Destroy; override;
    /// Recarga la foto a 300 px del articulo / SKU activo. Lo llama
    /// el hook OnDataChange en cada cambio de registro, pero tambien
    /// se puede invocar a mano (p.ej. tras un Refresh externo).
    procedure Refrescar;
  end;

var
  oFotos: TFotosArticulos;

implementation

uses
  inLibArticulosValidador,
  Winapi.GDIPOBJ, Winapi.GDIPAPI;

{ TFotoInfo }

procedure TFotoInfo.Clear;
begin
  Encontrada      := False;
  Origen          := foSinFoto;
  CodigoArt       := '';
  CodigoSku       := '';
  ClaveResuelta   := '';
  NombreBase      := '';
  ExtensionOrigen := '';
end;

function GenerarPrefijosSku(const ACodSku: string): TArray<string>;
var
  sActual: string;
  iSep   : Integer;
begin
  SetLength(Result, 0);
  if ACodSku = '' then Exit;
  Result := Result + [ACodSku];           // 1. el SKU completo
  sActual := ACodSku;
  while True do
  begin
    iSep := LastDelimiter('/', sActual);
    if iSep = 0 then Break;
    sActual := Copy(sActual, 1, iSep - 1);
    if Pos('/', sActual) = 0 then Break;  // ya no es prefijo, es el articulo
    Result := Result + [sActual];
  end;
end;

procedure TFotosArticulos.AsignarConexion(
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion);
begin
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
end;

procedure TFotosArticulos.LiberarServicios;
begin
  FConexion := nil;
  FParametrosApp := nil;
end;

{ ----------------------------------------------------------------- }
{   Helpers de ruta y nombre                                        }
{ ----------------------------------------------------------------- }

function TFotosArticulos.DirBase: string;
begin
  Result := FParametrosApp.GetPath('appDirFotos');
  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
end;

function TFotosArticulos.SubdirDe(AResolucion: TFotoResolucion): string;
var
  sBase: string;
begin
  sBase := DirBase;
  if sBase = '' then Exit('');
  case AResolucion of
    frPx300 : Result := sBase + cSubdir300;
    frPx600 : Result := sBase + cSubdir600;
    frReal  : Result := sBase + cSubdirReal;
  end;
  Result := IncludeTrailingPathDelimiter(Result);
end;

// Sanea SKU para usarlo como nombre de fichero. Reemplaza separadores
// problematicos (/, \, :, *, ?, ", <, >, |) por '_'.
function SanearNombre(const AOriginal: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  for i := 1 to Length(AOriginal) do
  begin
    c := AOriginal[i];
    case c of
      '/', '\', ':', '*', '?', '"', '<', '>', '|':
        Result := Result + '_';
    else
      Result := Result + c;
    end;
  end;
end;

function TFotosArticulos.ClaveNombre(const ACodArt,
                                     ACodSku: string): string;
begin
  if ACodSku = '' then
    Result := SanearNombre(ACodArt)
  else
    Result := SanearNombre(ACodSku);
end;

function TFotosArticulos.ComponerNombre(const AClave: string;
                                        AIndice: Integer): string;
begin
  Result := AClave + '_' + Format('%.3d', [AIndice]);
end;

function TFotosArticulos.ExtraerIndice(const ANombre: string): Integer;
var
  iPos: Integer;
  sNum: string;
begin
  Result := 0;
  iPos := LastDelimiter('_', ANombre);
  if iPos = 0 then Exit;
  sNum := Copy(ANombre, iPos + 1, MaxInt);
  if not TryStrToInt(sNum, Result) then
    Result := 0;
end;

procedure TFotosArticulos.BorrarFicherosDeNombre(const ANombreBase: string);

  procedure BorrarSiExiste(const ARuta: string);
  begin
    if (ARuta <> '') and FileExists(ARuta) then
      DeleteFile(PChar(ARuta));
  end;

begin
  if ANombreBase = '' then Exit;
  BorrarSiExiste(SubdirDe(frPx300) + ANombreBase + '.png');
  BorrarSiExiste(SubdirDe(frPx600) + ANombreBase + '.png');
  BorrarSiExiste(SubdirDe(frReal)  + ANombreBase + '.png');
end;

{ ----------------------------------------------------------------- }
{   Persistencia BBDD                                               }
{ ----------------------------------------------------------------- }

function TFotosArticulos.Resolver(const ACodArt,
                                  ACodSku: string): TFotoInfo;
var
  q        : TUniQuery;
  prefijos : TArray<string>;
  i        : Integer;
  sInList  : string;
  sClave   : string;
begin
  Result.Clear;
  Result.CodigoArt := ACodArt;
  Result.CodigoSku := ACodSku;
  if ACodArt = '' then Exit;

  // Caché de precarga (solo nivel artículo, sin SKU): si está activa y el
  // artículo se precargó, se devuelve sin tocar la BBDD (evita el N+1).
  if (FCachePrecarga <> nil) and (ACodSku = '') and
     FCachePrecarga.TryGetValue(ACodArt, Result) then
    Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;

    // 1. SKU completo o prefijo: una sola consulta con IN y ORDER BY
    //    LENGTH(CODIGO_UNIDAD_FOT) DESC para que la mas especifica gane.
    prefijos := GenerarPrefijosSku(ACodSku);
    if Length(prefijos) > 0 then
    begin
      sInList := '';
      for i := 0 to High(prefijos) do
      begin
        if sInList <> '' then sInList := sInList + ', ';
        sInList := sInList + ':P' + IntToStr(i);
      end;
      q.SQL.Text :=
        ' SELECT * FROM fza_articulos_fotos '             +
        '  WHERE CODIGO_ART_FOT    = :CODIGO_ART '        +
        '    AND CODIGO_UNIDAD_FOT IN (' + sInList + ') ' +
        '  ORDER BY LENGTH(CODIGO_UNIDAD_FOT) DESC '      +
        '  LIMIT 1';
      q.ParamByName('CODIGO_ART').AsString := ACodArt;
      for i := 0 to High(prefijos) do
        q.ParamByName('P' + IntToStr(i)).AsString := prefijos[i];
      q.Open;
      if not q.Eof then
      begin
        sClave := q.FieldByName(fcodunidadfot).AsString;
        Result.Encontrada      := True;
        if sClave = ACodSku then
          Result.Origen := foSku
        else
          Result.Origen := foSkuPrefijo;
        Result.ClaveResuelta   := sClave;
        Result.NombreBase      := q.FieldByName(fnomfot).AsString;
        Result.ExtensionOrigen := q.FieldByName(fextfot).AsString;
        Exit;
      end;
      q.Close;
    end;

    // 2. Fallback: foto del articulo (CODIGO_UNIDAD_FOT = '')
    q.SQL.Text :=
      ' SELECT * FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = '''' ' +
      '  LIMIT 1';
    q.ParamByName('CODIGO_ART').AsString := ACodArt;
    q.Open;
    if not q.Eof then
    begin
      Result.Encontrada      := True;
      Result.Origen          := foArticulo;
      Result.ClaveResuelta   := '';
      Result.NombreBase      := q.FieldByName(fnomfot).AsString;
      Result.ExtensionOrigen := q.FieldByName(fextfot).AsString;
    end;

    // 3. Si no hay foto general, mostramos la primera foto por color.
    //    El orden explicito mantiene el mismo resultado entre llamadas.
    if (ACodSku = '') and not Result.Encontrada then
    begin
      q.Close;
      q.SQL.Text :=
        ' SELECT * FROM fza_articulos_fotos ' +
        '  WHERE CODIGO_ART_FOT = :CODIGO_ART ' +
        '    AND CODIGO_UNIDAD_FOT <> '''' ' +
        '  ORDER BY CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT ' +
        '  LIMIT 1';
      q.ParamByName('CODIGO_ART').AsString := ACodArt;
      q.Open;
      if not q.Eof then
      begin
        Result.Encontrada      := True;
        Result.Origen          := foSkuPrefijo;
        Result.ClaveResuelta   := q.FieldByName(fcodunidadfot).AsString;
        Result.NombreBase      := q.FieldByName(fnomfot).AsString;
        Result.ExtensionOrigen := q.FieldByName(fextfot).AsString;
      end;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TFotosArticulos.ResolverArticulosLote(
  const ACodigos: TArray<string>): TDictionary<string, TFotoInfo>;
var
  q: TUniQuery;
  i, cnt: Integer;
  sIn, sArtCur, sArt, sUni: string;
  artFound: Boolean;
  artNom, artExt, uniClave, uniNom, uniExt: string;
  dict: TDictionary<string, TFotoInfo>;

  // Cierra el artículo en curso: elige la foto general o, si no existe,
  // la primera foto por color. Usa los acumuladores del bucle.
  procedure Finalizar(const APrevArt: string);
  var
    info: TFotoInfo;
  begin
    if APrevArt <> '' then
    begin
      info.Clear;
      info.CodigoArt := APrevArt;
      if artFound then
      begin
        info.Encontrada      := True;
        info.Origen          := foArticulo;
        info.ClaveResuelta   := '';
        info.NombreBase      := artNom;
        info.ExtensionOrigen := artExt;
      end
      else if cnt > 0 then
      begin
        info.Encontrada    := True;
        if uniClave = '' then
          info.Origen := foArticulo
        else
          info.Origen := foSkuPrefijo;
        info.ClaveResuelta   := uniClave;
        info.NombreBase      := uniNom;
        info.ExtensionOrigen := uniExt;
      end;
      if info.Encontrada then
        dict.AddOrSetValue(APrevArt, info);
    end;
  end;

begin
  dict := TDictionary<string, TFotoInfo>.Create;
  Result := dict;
  if Length(ACodigos) > 0 then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := FConexion;
      sIn := '';
      for i := 0 to High(ACodigos) do
      begin
        if sIn <> '' then
          sIn := sIn + ', ';
        sIn := sIn + ':A' + IntToStr(i);
      end;
      q.SQL.Text :=
        ' SELECT ' + fcodartfot + ', ' + fcodunidadfot + ', ' +
                     fnomfot + ', ' + fextfot +
        '   FROM fza_articulos_fotos ' +
        '  WHERE ' + fcodartfot + ' IN (' + sIn + ') ' +
        '  ORDER BY ' + fcodartfot + ', ' + fcodunidadfot + ', ' +
                       fnomfot;
      for i := 0 to High(ACodigos) do
        q.ParamByName('A' + IntToStr(i)).AsString := ACodigos[i];
      q.Open;
      sArtCur  := '';
      cnt      := 0;
      artFound := False;
      uniClave := '';
      uniNom   := '';
      uniExt   := '';
      artNom   := '';
      artExt   := '';
      while not q.Eof do
      begin
        sArt := q.FieldByName(fcodartfot).AsString;
        sUni := q.FieldByName(fcodunidadfot).AsString;
        if sArt <> sArtCur then
        begin
          Finalizar(sArtCur);
          sArtCur  := sArt;
          cnt      := 0;
          artFound := False;
        end;
        Inc(cnt);
        if cnt = 1 then
        begin
          uniClave := sUni;
          uniNom   := q.FieldByName(fnomfot).AsString;
          uniExt   := q.FieldByName(fextfot).AsString;
        end;
        if sUni = '' then
        begin
          artFound := True;
          artNom   := q.FieldByName(fnomfot).AsString;
          artExt   := q.FieldByName(fextfot).AsString;
        end;
        q.Next;
      end;
      Finalizar(sArtCur);
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TFotosArticulos.PrecargarFotosLote(const ACodigos: TArray<string>);
var
  i   : Integer;
  info: TFotoInfo;
begin
  FreeAndNil(FCachePrecarga);
  // ResolverArticulosLote hace UNA consulta y devuelve solo los artículos CON
  // foto. La caché se queda con ese diccionario y, para los códigos SIN foto,
  // se añade una entrada "no encontrada": así un acierto de caché significa
  // "ya consultado" (con o sin foto) y Resolver no vuelve a la BBDD.
  FCachePrecarga := ResolverArticulosLote(ACodigos);
  for i := 0 to High(ACodigos) do
    if (ACodigos[i] <> '') and
       (not FCachePrecarga.ContainsKey(ACodigos[i])) then
    begin
      info.Clear;
      info.CodigoArt := ACodigos[i];
      FCachePrecarga.AddOrSetValue(ACodigos[i], info);
    end;
end;

procedure TFotosArticulos.LimpiarPrecargaFotos;
begin
  FreeAndNil(FCachePrecarga);
end;

destructor TFotosArticulos.Destroy;
begin
  FreeAndNil(FCachePrecarga);
  inherited Destroy;
end;

function TFotosArticulos.RutaFoto(const AInfo: TFotoInfo;
                                  AResolucion: TFotoResolucion): string;
var
  sDir, sFichero: string;
begin
  // Las tres copias son PNG (real/ conserva la resolucion original).
  Result := '';
  if not AInfo.Encontrada then Exit;
  sDir := SubdirDe(AResolucion);
  if sDir = '' then Exit;
  sFichero := sDir + AInfo.NombreBase + '.png';
  if FileExists(sFichero) then
    Result := sFichero;
end;

{ ----------------------------------------------------------------- }
{   Redimensionado GDI+                                             }
{ ----------------------------------------------------------------- }

function TFotosArticulos.CargarGraficoDeFichero(
                                          const ARuta: string): TGraphic;
// Lee el fichero original del disco y devuelve un TGraphic listo para
// volcar via Canvas.Draw / StretchDraw. Acepta PNG, JPG/JPEG, GIF, BMP
// y WebP (este via TWICImage, decodificador WIC de Windows; en Win10+
// el codec viene de serie, en Win7/8 se instala por separado).
var
  sExt : string;
  png  : TPngImage;
  jpg  : TJPEGImage;
  gif  : TGIFImage;
  wic  : TWICImage;
  bmp  : TBitmap;
begin
  sExt := LowerCase(ExtractFileExt(ARuta));
  if (sExt = '.png') then
  begin
    png := TPngImage.Create;
    try
      png.LoadFromFile(ARuta);
      Result := png;
    except
      FreeAndNil(png);
      raise;
    end;
  end
  else if (sExt = '.jpg') or (sExt = '.jpeg') then
  begin
    jpg := TJPEGImage.Create;
    try
      jpg.LoadFromFile(ARuta);
      Result := jpg;
    except
      FreeAndNil(jpg);
      raise;
    end;
  end
  else if (sExt = '.gif') then
  begin
    gif := TGIFImage.Create;
    try
      gif.LoadFromFile(ARuta);
      Result := gif;
    except
      FreeAndNil(gif);
      raise;
    end;
  end
  else if (sExt = '.webp') or (sExt = '.avif') or (sExt = '.heic') or
          (sExt = '.heif') then
  begin
    // WebP, AVIF, HEIC, HEIF: todos via Windows Imaging Component
    // (TWICImage). Los codecs son extensiones que pueden faltar:
    //   .webp -> "WebP Imaging Extensions" (Microsoft Store, gratis)
    //   .avif -> "AV1 Video Extension" (Microsoft Store, gratis)
    //   .heic / .heif -> "HEIF Image Extensions" (gratis)
    // Si el codec no esta instalado en Windows, LoadFromFile lanza
    // EInvalidGraphic con 0xC00D5212 ("Imagen no valida"). Capturamos
    // y damos un mensaje accionable.
    wic := TWICImage.Create;
    try
      try
        wic.LoadFromFile(ARuta);
      except
        on E: Exception do
        begin
          FreeAndNil(wic);
          var sCodec: string;
          if sExt = '.webp' then sCodec := 'WebP Imaging Extensions'
          else if sExt = '.avif' then sCodec := 'AV1 Video Extension'
          else sCodec := 'HEIF Image Extensions';
          raise EInvalidGraphic.Create(
            'No se puede importar ' + UpperCase(Copy(sExt, 2, MaxInt)) +
            ' en este equipo: falta el codec "' + sCodec + '".' +
            sLineBreak + sLineBreak +
            'Instálalo gratis desde Microsoft Store y reintenta.' +
            sLineBreak + sLineBreak +
            'Alternativa: guarda la imagen en PNG o JPG y vuelve a' +
            ' subirla.' +
            sLineBreak + sLineBreak +
            'Error original: ' + E.Message);
        end;
      end;
      Result := wic;
    except
      if Assigned(wic) then FreeAndNil(wic);
      raise;
    end;
  end
  else
  begin
    bmp := TBitmap.Create;
    try
      bmp.LoadFromFile(ARuta);
      Result := bmp;
    except
      FreeAndNil(bmp);
      raise;
    end;
  end;
end;

procedure TFotosArticulos.GuardarComoPng(const AOriginal: TGraphic;
                                         const ARutaPng: string);
// Guarda el grafico tal cual (resolucion original) como PNG. Para los
// formatos que ya son PNG es directo; para JPG/BMP/otros se hace un
// pase a TBitmap pf32bit y luego TPngImage.Assign.
var
  oBitmap: TBitmap;
  oPng   : TPngImage;
begin
  if (AOriginal = nil) or
     (AOriginal.Width = 0) or (AOriginal.Height = 0) then Exit;
  if AOriginal is TPngImage then
  begin
    TPngImage(AOriginal).SaveToFile(ARutaPng);
    Exit;
  end;
  oBitmap := TBitmap.Create;
  try
    oBitmap.PixelFormat := pf32bit;
    oBitmap.SetSize(AOriginal.Width, AOriginal.Height);
    oBitmap.Canvas.Draw(0, 0, AOriginal);
    oPng := TPngImage.Create;
    try
      oPng.Assign(oBitmap);
      oPng.SaveToFile(ARutaPng);
    finally
      FreeAndNil(oPng);
    end;
  finally
    FreeAndNil(oBitmap);
  end;
end;

procedure TFotosArticulos.GuardarRedimensionado(const AOriginal: TGraphic;
                                                const ARutaPng: string;
                                                ALadoMayor: Integer);
var
  iAncho, iAlto: Integer;
  oBitmap     : TBitmap;
  oSrc        : TBitmap;
  oPng        : TPngImage;
  dEscala     : Double;
  gpGfx       : TGPGraphics;
  gpSrc       : TGPBitmap;
begin
  if (AOriginal.Width = 0) or (AOriginal.Height = 0) then Exit;
  // Mantener proporciones, lado mayor = ALadoMayor.
  if AOriginal.Width >= AOriginal.Height then
  begin
    dEscala := ALadoMayor / AOriginal.Width;
    iAncho := ALadoMayor;
    iAlto  := Round(AOriginal.Height * dEscala);
  end
  else
  begin
    dEscala := ALadoMayor / AOriginal.Height;
    iAlto  := ALadoMayor;
    iAncho := Round(AOriginal.Width * dEscala);
  end;
  if iAncho  < 1 then iAncho  := 1;
  if iAlto   < 1 then iAlto   := 1;
  oBitmap := TBitmap.Create;
  oSrc    := TBitmap.Create;
  try
    // Pasamos el origen a un TBitmap pf32 para envolverlo en GDI+ via su
    // HBITMAP (TGPBitmap). El redimension lo hace GDI+ con interpolacion
    // bicubica de alta calidad (mejor que el StretchBlt/HALFTONE de GDI).
    oSrc.PixelFormat := pf32bit;
    oSrc.SetSize(AOriginal.Width, AOriginal.Height);
    oSrc.Canvas.Draw(0, 0, AOriginal);
    oBitmap.PixelFormat := pf32bit;
    oBitmap.SetSize(iAncho, iAlto);
    gpSrc := TGPBitmap.Create(oSrc.Handle, 0);
    try
      gpGfx := TGPGraphics.Create(oBitmap.Canvas.Handle);
      try
        gpGfx.SetInterpolationMode(InterpolationModeHighQualityBicubic);
        gpGfx.SetPixelOffsetMode(PixelOffsetModeHighQuality);
        gpGfx.SetSmoothingMode(SmoothingModeHighQuality);
        gpGfx.DrawImage(gpSrc, 0, 0, iAncho, iAlto);
      finally
        gpGfx.Free;
      end;
    finally
      gpSrc.Free;
    end;
    oPng := TPngImage.Create;
    try
      oPng.Assign(oBitmap);
      oPng.SaveToFile(ARutaPng);
    finally
      FreeAndNil(oPng);
    end;
  finally
    FreeAndNil(oSrc);
    FreeAndNil(oBitmap);
  end;
end;

{ ----------------------------------------------------------------- }
{   Rotacion GDI (ScanLine)                                         }
{ ----------------------------------------------------------------- }

procedure TFotosArticulos.RotarBitmap90(ABitmap: TBitmap; AHorario: Boolean);
var
  rotado : TBitmap;
  src    : PRGBQuad;
  fila   : PRGBQuad;
  x, y   : Integer;
  iW, iH : Integer;
begin
  if (ABitmap = nil) or (ABitmap.Width = 0) or (ABitmap.Height = 0) then Exit;
  // Normalizamos a 32 bits para que ScanLine devuelva PRGBQuad.
  ABitmap.PixelFormat := pf32bit;
  iW := ABitmap.Width;
  iH := ABitmap.Height;
  rotado := TBitmap.Create;
  try
    rotado.PixelFormat := pf32bit;
    rotado.SetSize(iH, iW);
    for y := 0 to iH - 1 do
    begin
      src := PRGBQuad(ABitmap.ScanLine[y]);
      for x := 0 to iW - 1 do
      begin
        if AHorario then
        begin
          // (x, y) -> (iH - 1 - y, x): rotacion 90 horario
          fila := PRGBQuad(rotado.ScanLine[x]);
          Inc(fila, iH - 1 - y);
        end
        else
        begin
          // (x, y) -> (y, iW - 1 - x): rotacion 90 anti-horario
          fila := PRGBQuad(rotado.ScanLine[iW - 1 - x]);
          Inc(fila, y);
        end;
        fila^ := src^;
        Inc(src);
      end;
    end;
    ABitmap.Assign(rotado);
  finally
    FreeAndNil(rotado);
  end;
end;

procedure TFotosArticulos.RotarFicheroPng(const ARuta: string;
                                          AHorario: Boolean);
var
  png    : TPngImage;
  bmp    : TBitmap;
  pngOut : TPngImage;
begin
  if not FileExists(ARuta) then Exit;
  png := TPngImage.Create;
  bmp := TBitmap.Create;
  try
    png.LoadFromFile(ARuta);
    bmp.PixelFormat := pf32bit;
    bmp.SetSize(png.Width, png.Height);
    bmp.Canvas.Draw(0, 0, png);
    RotarBitmap90(bmp, AHorario);
    pngOut := TPngImage.Create;
    try
      pngOut.Assign(bmp);
      pngOut.SaveToFile(ARuta);
    finally
      FreeAndNil(pngOut);
    end;
  finally
    FreeAndNil(bmp);
    FreeAndNil(png);
  end;
end;

// Las tres copias son PNG, asi que rotar `real/` es exactamente lo
// mismo que rotar `300/` o `600/`. Dejamos el alias por claridad en
// el sitio de llamada.

{ ----------------------------------------------------------------- }
{   Guardar / eliminar / rotar                                      }
{ ----------------------------------------------------------------- }

function TFotosArticulos.Guardar(const ACodArt, ACodSku,
                                 AFicheroOrigen, AUsuario: string): TFotoInfo;
var
  q              : TUniQuery;
  sDirBase       : string;
  sClave         : string;
  sNombreNuevo   : string;
  sExt           : string;
  oGraphic       : TGraphic;
  bExiste        : Boolean;
  iIndice        : Integer;
  sNombreAnterior: string;
  sExtAnterior   : string;
begin
  Result.Clear;
  if (ACodArt = '') then
    raise Exception.Create('No se puede guardar foto sin codigo de articulo.');
  if not FileExists(AFicheroOrigen) then
    raise Exception.Create('El fichero origen no existe: ' + AFicheroOrigen);

  sDirBase := DirBase;
  if sDirBase = '' then
    raise Exception.Create('El parametro appDirFotos no esta configurado.');

  ForceDirectories(sDirBase + cSubdir300);
  ForceDirectories(sDirBase + cSubdir600);
  ForceDirectories(sDirBase + cSubdirReal);

  sClave := ClaveNombre(ACodArt, ACodSku);
  // La extension de origen ya no se usa para almacenar (todo es PNG)
  // pero la dejamos rellena en BBDD para trazabilidad.
  sExt := LowerCase(ExtractFileExt(AFicheroOrigen));
  if Length(sExt) > 0 then
    sExt := Copy(sExt, 2, MaxInt);
  if sExt = '' then sExt := 'png';

  // 1. Resolvemos el indice siguiente y los nombres anteriores que hay
  //    que limpiar tras la escritura.
  sNombreAnterior := '';
  sExtAnterior    := '';
  iIndice         := 1;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      ' SELECT * FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_SKU';
    q.ParamByName('CODIGO_ART').AsString := ACodArt;
    q.ParamByName('CODIGO_SKU').AsString := ACodSku;
    q.Open;
    bExiste := not q.Eof;
    if bExiste then
    begin
      sNombreAnterior := q.FieldByName(fnomfot).AsString;
      sExtAnterior    := q.FieldByName(fextfot).AsString;
      iIndice         := ExtraerIndice(sNombreAnterior) + 1;
      if iIndice < 1 then iIndice := 1;
    end;
  finally
    FreeAndNil(q);
  end;
  sNombreNuevo := ComponerNombre(sClave, iIndice);

  // 2. Generamos los tres PNG: 300, 600 y real (en su resolucion
  //    nativa). La copia real ya no es un volcado byte-a-byte: se
  //    re-encodifica a PNG, manteniendo las dimensiones originales,
  //    para que las tres copias se traten igual (mismo formato, sin
  //    perdida).
  oGraphic := CargarGraficoDeFichero(AFicheroOrigen);
  try
    GuardarComoPng(oGraphic,
                   SubdirDe(frReal) + sNombreNuevo + '.png');
    GuardarRedimensionado(oGraphic,
                          SubdirDe(frPx300) + sNombreNuevo + '.png',
                          cLado300);
    GuardarRedimensionado(oGraphic,
                          SubdirDe(frPx600) + sNombreNuevo + '.png',
                          cLado600);
  finally
    FreeAndNil(oGraphic);
  end;

  // 3. Upsert en fza_articulos_fotos
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      ' SELECT * FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_SKU';
    q.ParamByName('CODIGO_ART').AsString := ACodArt;
    q.ParamByName('CODIGO_SKU').AsString := ACodSku;
    q.Open;
    bExiste := not q.Eof;
    if bExiste then q.Edit else q.Insert;
    q.FieldByName(fcodartfot).AsString    := ACodArt;
    q.FieldByName(fcodunidadfot).AsString := ACodSku;
    q.FieldByName(fnomfot).AsString       := sNombreNuevo;
    q.FieldByName(fextfot).AsString       := sExt;
    if not bExiste then
    begin
      q.FieldByName(finstalta).AsDateTime := Now;
      q.FieldByName(fusralta).AsString    := AUsuario;
    end;
    q.FieldByName(fusrmodif).AsString     := AUsuario;
    q.Post;
  finally
    FreeAndNil(q);
  end;

  // 4. Limpieza de ficheros con el nombre previo (si lo hubiera y es
  //    distinto del nuevo). Se hace al final para que un fallo en la
  //    escritura no deje al sistema sin foto.
  if (sNombreAnterior <> '') and (sNombreAnterior <> sNombreNuevo) then
    BorrarFicherosDeNombre(sNombreAnterior);

  Result.Encontrada      := True;
  if ACodSku = '' then
    Result.Origen := foArticulo
  else
    Result.Origen := foSku;     // si fuera prefijo, foSku sigue valiendo
                                //   ya que la fila exacta matcheara
  Result.CodigoArt       := ACodArt;
  Result.CodigoSku       := ACodSku;
  Result.ClaveResuelta   := ACodSku;
  Result.NombreBase      := sNombreNuevo;
  Result.ExtensionOrigen := sExt;
end;

function TFotosArticulos.Rotar(const ACodArt, ACodSku: string;
                               AHorario: Boolean;
                               const AUsuario: string): TFotoInfo;
var
  info             : TFotoInfo;
  sClave           : string;
  sNombreAnterior  : string;
  sNombreNuevo     : string;
  iIndice          : Integer;
  ruta300, ruta600 : string;
  rutaReal         : string;
  rutaReal300, rutaReal600, rutaRealNuevo: string;
  q                : TUniQuery;
begin
  Result.Clear;
  info := Resolver(ACodArt, ACodSku);
  if not info.Encontrada then
    raise Exception.Create('No hay foto registrada para rotar.');

  // Rotamos la fila que resolvio, sea cual sea su nivel: foto del
  // articulo, prefijo, o SKU exacto. Asi una rotacion desde un SKU que
  // hereda del padre afecta a la fila padre y todos los SKUs que la
  // heredaban ven la imagen rotada.
  sClave := ClaveNombre(ACodArt, info.ClaveResuelta);
  sNombreAnterior := info.NombreBase;

  ruta300  := SubdirDe(frPx300) + sNombreAnterior + '.png';
  ruta600  := SubdirDe(frPx600) + sNombreAnterior + '.png';
  rutaReal := SubdirDe(frReal)  + sNombreAnterior + '.png';

  // Las tres copias son PNG; mismo procedimiento.
  RotarFicheroPng(ruta300,  AHorario);
  RotarFicheroPng(ruta600,  AHorario);
  RotarFicheroPng(rutaReal, AHorario);

  // Renombramos al siguiente indice.
  iIndice      := ExtraerIndice(sNombreAnterior) + 1;
  if iIndice < 1 then iIndice := 1;
  sNombreNuevo := ComponerNombre(sClave, iIndice);

  rutaReal300   := SubdirDe(frPx300) + sNombreNuevo + '.png';
  rutaReal600   := SubdirDe(frPx600) + sNombreNuevo + '.png';
  rutaRealNuevo := SubdirDe(frReal)  + sNombreNuevo + '.png';
  if FileExists(ruta300)  then RenameFile(ruta300,  rutaReal300);
  if FileExists(ruta600)  then RenameFile(ruta600,  rutaReal600);
  if FileExists(rutaReal) then RenameFile(rutaReal, rutaRealNuevo);

  // Actualizamos la fila correspondiente.
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      ' UPDATE fza_articulos_fotos ' +
      '    SET NOMBRE_FOT_FOT   = :NOMBRE, ' +
      '        USUARIO_MODIF    = :USUARIO ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    q.ParamByName('NOMBRE').AsString        := sNombreNuevo;
    q.ParamByName('USUARIO').AsString       := AUsuario;
    q.ParamByName('CODIGO_ART').AsString    := ACodArt;
    q.ParamByName('CODIGO_UNIDAD').AsString := info.ClaveResuelta;
    q.Execute;
  finally
    FreeAndNil(q);
  end;

  Result.Encontrada      := True;
  Result.Origen          := info.Origen;
  Result.CodigoArt       := ACodArt;
  Result.CodigoSku       := ACodSku;
  Result.ClaveResuelta   := info.ClaveResuelta;
  Result.NombreBase      := sNombreNuevo;
  Result.ExtensionOrigen := info.ExtensionOrigen;
end;

procedure TFotosArticulos.Eliminar(const ACodArt, ACodUnidad: string);
// Borra la fila exacta (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT) y los tres
// ficheros PNG que cuelgan de ella. ACodUnidad = '' borra la foto a
// nivel articulo; un valor concreto borra esa fila de SKU o prefijo
// independientemente de si hay heredadas por debajo.
var
  q       : TUniQuery;
  sNombre : string;
begin
  // Localizamos el nombre del fichero asociado a la fila exacta antes
  // de borrar el registro.
  sNombre := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      ' SELECT NOMBRE_FOT_FOT '                  +
      '   FROM fza_articulos_fotos '             +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    q.ParamByName('CODIGO_ART').AsString    := ACodArt;
    q.ParamByName('CODIGO_UNIDAD').AsString := ACodUnidad;
    q.Open;
    if not q.Eof then
      sNombre := q.FieldByName(fnomfot).AsString;
  finally
    FreeAndNil(q);
  end;

  BorrarFicherosDeNombre(sNombre);

  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      ' DELETE FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    q.ParamByName('CODIGO_ART').AsString    := ACodArt;
    q.ParamByName('CODIGO_UNIDAD').AsString := ACodUnidad;
    q.Execute;
  finally
    FreeAndNil(q);
  end;
end;

{ ----------------------------------------------------------------- }
{   FastReports: sustitucion automatica                             }
{ ----------------------------------------------------------------- }

// ============================================================================
//   Aliases canonicos de las columnas (single source of truth)
// ============================================================================

const
  cAliasArt: array[0..19] of string = (
    'CODIGO_ART_ART',  'CODIGO_ART_FAC',     'CODIGO_ART_FACLIN',
    'CODIGO_ART_LIN',  'CODIGO_ART_SKU',     'CODIGO_ART_PEDLIN',
    'CODIGO_ART_ALBLIN', 'CODIGO_ART_ARTTAR', 'CODIGO_ART_AAB',
    // Compras: lineas de albaran, pedido, factura y devolucion.
    'CODIGO_ART_ALBCLIN', 'CODIGO_ART_PEDCLIN',
    'CODIGO_ART_FACCLIN',
    'CODIGO_ART_DEVCLIN',
    // Inventarios + movimientos de almacen + depositos cliente.
    'CODIGO_ART_INVLIN', 'CODIGO_ART_MOV', 'CODIGO_ART_DEP',
    'CODIGO_ART_DTL',
    // Sesiones de compras: el codigo puede ser tentativo (articulo
    // todavia no creado, ver fza_compras_sesiones_fotos).
    'CODIGO_ART_TENTATIVO_SESLIN',
    'CODIGO_ART',      'CODIGO_ARTICULO');
  cAliasSku: array[0..15] of string = (
    'CODIGO_UNIDAD_SKU',    'CODIGO_UNIDAD_FAC',
    'CODIGO_UNIDAD_FACLIN', 'CODIGO_UNIDAD_LIN',
    'CODIGO_UNIDAD_PEDLIN', 'CODIGO_UNIDAD_ALBLIN',
    // Compras: lineas de albaran, pedido, factura y devolucion.
    'CODIGO_UNIDAD_ALBCLIN', 'CODIGO_UNIDAD_PEDCLIN',
    'CODIGO_UNIDAD_FACCLIN',
    'CODIGO_UNIDAD_DEVCLIN',
    'CODIGO_UNIDAD_ARTTAR',
    'CODIGO_UNIDAD_INVLIN', 'CODIGO_UNIDAD_MOV',
    'CODIGO_UNIDAD_DEP', 'CODIGO_UNIDAD_DTL',
    'CODIGO_UNIDAD');
  cAliasCodBarras: array[0..0] of string = (
    'CODBAR_ART_PEDLIN');

procedure CompletarSkuDesdeCodigoBarras(ADataSet: TDataSet;
                                        var ACodArt, ACodSku: string);
var
  i        : Integer;
  f        : TField;
  sCodigo  : string;
  validador: TArticulosValidador;
  res      : TArtResolucionEntrada;
begin
  if (ACodSku = '') and (ADataSet <> nil) and ADataSet.Active and
     (oFotos.Conexion <> nil) then
  begin
    sCodigo := '';
    for i := Low(cAliasCodBarras) to High(cAliasCodBarras) do
    begin
      f := ADataSet.FindField(cAliasCodBarras[i]);
      if Assigned(f) and (not f.IsNull) then
      begin
        sCodigo := Trim(f.AsString);
        if sCodigo <> '' then
          Break;
      end;
    end;
    if sCodigo <> '' then
    begin
      validador := TArticulosValidador.Create(oFotos.Conexion);
      try
        res := validador.ResolverCodigoBarras(sCodigo);
        if res.Encontrado and (res.CodigoSku <> '') and
           ((ACodArt = '') or SameText(res.CodigoArticulo, ACodArt)) then
        begin
          ACodArt := res.CodigoArticulo;
          ACodSku := res.CodigoSku;
        end;
      finally
        FreeAndNil(validador);
      end;
    end;
  end;
end;

procedure LeerArtSkuDeDataSet(ADataSet: TDataSet;
                              out ACodArt, ACodSku: string);
var
  i: Integer;
  f: TField;
begin
  ACodArt := '';
  ACodSku := '';
  if (ADataSet = nil) or (not ADataSet.Active) or ADataSet.IsEmpty then
    Exit;
  for i := Low(cAliasArt) to High(cAliasArt) do
  begin
    f := ADataSet.FindField(cAliasArt[i]);
    if Assigned(f) and (not f.IsNull) then
    begin
      ACodArt := f.AsString;
      Break;
    end;
  end;
  for i := Low(cAliasSku) to High(cAliasSku) do
  begin
    f := ADataSet.FindField(cAliasSku[i]);
    if Assigned(f) and (not f.IsNull) then
    begin
      ACodSku := f.AsString;
      Break;
    end;
  end;
  CompletarSkuDesdeCodigoBarras(ADataSet, ACodArt, ACodSku);
end;

// Localiza la banda padre del componente y devuelve el TDataSet asociado
// si lo tiene. Sube la jerarquia hasta encontrar un TfrxDataBand u otro
// banda con DataSet asignado.
function ObtenerDataSetDeBandaPadre(AObj: TfrxComponent): TDataSet;
var
  oParent: TfrxComponent;
  oBand  : TfrxDataBand;
  oReport: TfrxReport;
  i      : Integer;
begin
  Result := nil;
  oParent := AObj.Parent;
  while Assigned(oParent) do
  begin
    if (oParent is TfrxDataBand) then
    begin
      oBand := TfrxDataBand(oParent);
      if Assigned(oBand.DataSet) and
         (oBand.DataSet is TfrxDBDataset) and
         Assigned(TfrxDBDataset(oBand.DataSet).DataSet) then
        Exit(TfrxDBDataset(oBand.DataSet).DataSet);
    end;
    oParent := oParent.Parent;
  end;
  // Fallback para Picture en bandas sin DataSet (p.ej. cabecera de grupo):
  // al pintar la cabecera, el registro activo del primer TfrxDBDataset del
  // report es la primera fila del grupo (el articulo cuya foto queremos).
  // Solo se ejecuta si la subida por bandas no encontro DataSet, asi que no
  // altera el comportamiento de los informes que llevan la foto en una
  // banda de datos (etiquetas, tickets).
  oReport := AObj.Report;
  if oReport <> nil then
    for i := 0 to oReport.Datasets.Count - 1 do
      if (oReport.Datasets[i].DataSet is TfrxDBDataset) and
         Assigned(TfrxDBDataset(oReport.Datasets[i].DataSet).DataSet) then
        Exit(TfrxDBDataset(oReport.Datasets[i].DataSet).DataSet);
end;

procedure SustituirFotoEnPicture(APic: TfrxPictureView;
                                 AResolucion: TFotoResolucion);
var
  oDataSet: TDataSet;
  sArt    : string;
  sSku    : string;
  info    : TFotoInfo;
  sRuta   : string;
  png     : TPngImage;
begin
  oDataSet := ObtenerDataSetDeBandaPadre(APic);
  if oDataSet = nil then
  begin
    APic.Picture.Assign(nil);
    Exit;
  end;
  LeerArtSkuDeDataSet(oDataSet, sArt, sSku);
  if sArt = '' then
  begin
    APic.Picture.Assign(nil);
    Exit;
  end;
  info  := oFotos.Resolver(sArt, sSku);
  sRuta := oFotos.RutaFoto(info, AResolucion);
  if sRuta = '' then
  begin
    APic.Picture.Assign(nil);
    Exit;
  end;
  // Las tres copias son siempre PNG.
  png := TPngImage.Create;
  try
    png.LoadFromFile(sRuta);
    APic.Picture.Assign(png);
  finally
    FreeAndNil(png);
  end;
end;

// ============================================================================
//   FastReport: sustitucion de fotos
// ============================================================================
//
// `TfrxView.OnBeforePrint` es una propiedad STRING (nombre de un proc
// del script del .frx) en esta version de FastReport, por lo que no se
// puede enganchar codigo Delphi a nivel de View. Sin embargo
// `TfrxReport.OnBeforePrint` SI es un evento Delphi nativo que se
// dispara para cada View en cada iteracion, justo antes de pintarse.
// Esa es la pieza que usamos para refrescar los TfrxPictureView por
// fila (etiquetas, tickets con detalle): el handler se invoca tantas
// veces como (objetos x filas) y solo actua sobre los Picture llamados
// foto300/foto600/fotoreal. La logica de carga (resolucion del par
// articulo+SKU del DataSet de la banda padre) vive en
// `SustituirFotoEnPicture`, que se reutiliza desde aqui.

procedure TFotosArticulos.HandlerReportBeforePrint(
  Component: TfrxReportComponent);
var
  pic    : TfrxPictureView;
  sName  : string;
  res    : TFotoResolucion;
  bMatch : Boolean;
begin
  if not (Component is TfrxPictureView) then
    Exit;
  pic := TfrxPictureView(Component);
  sName := LowerCase(pic.Name);
  res := frPx300;
  bMatch := True;
  if      sName = 'foto300'  then res := frPx300
  else if sName = 'foto600'  then res := frPx600
  else if sName = 'fotoreal' then res := frReal
  else
    bMatch := False;
  if not bMatch then
    Exit;
  SustituirFotoEnPicture(pic, res);
end;

procedure EngancharFotosEnReport(Report: TfrxReport);
begin
  if Report = nil then
    Exit;
  Report.OnBeforePrint := oFotos.HandlerReportBeforePrint;
end;

// ============================================================================
//   TFotoEmbebida — foto pegada a un grid de Mto
// ============================================================================

constructor TFotoEmbebida.Create(AImage: TImage; ADataSource: TDataSource);
begin
  inherited Create;
  FImage      := AImage;
  FDataSource := ADataSource;
  if Assigned(FDataSource) then
  begin
    FPrevDataChange := FDataSource.OnDataChange;
    FDataSource.OnDataChange := OnDataChange;
  end;
  Refrescar;
end;

destructor TFotoEmbebida.Destroy;
begin
  if Assigned(FDataSource) then
    FDataSource.OnDataChange := FPrevDataChange;
  inherited;
end;

procedure TFotoEmbebida.OnDataChange(Sender: TObject; Field: TField);
begin
  if Assigned(FPrevDataChange) then
    FPrevDataChange(Sender, Field);
  if Field = nil then Refrescar;
end;

procedure TFotoEmbebida.Refrescar;
var
  sArt, sSku: string;
  info      : TFotoInfo;
  sRuta     : string;
  png       : TPngImage;
begin
  if not Assigned(FImage) then Exit;
  FImage.Picture.Assign(nil);
  if not Assigned(FDataSource) then Exit;
  LeerArtSkuDeDataSet(FDataSource.DataSet, sArt, sSku);
  if sArt = '' then Exit;
  info  := oFotos.Resolver(sArt, sSku);
  sRuta := oFotos.RutaFoto(info, frPx300);
  if sRuta = '' then Exit;
  png := TPngImage.Create;
  try
    png.LoadFromFile(sRuta);
    FImage.Picture.Assign(png);
  finally
    FreeAndNil(png);
  end;
end;

// ---------------------------------------------------------------------------
//   Fotos de sesion de compra (articulos todavia no materializados)
// ---------------------------------------------------------------------------
//
// Pattern paralelo a Guardar/Resolver/Eliminar pero contra
// fza_compras_sesiones_fotos. Mismos PNG en 300/600/real, mismo directorio
// base appDirFotos. Diferencia: el nombre base lleva el prefijo
// ses_<SERIE>_<NUMERO>_<LINEA>_ para que no colisione con los nombres
// definitivos del articulo. Al materializar, MigrarFotosSesion renombra
// los ficheros y persiste en fza_articulos_fotos.

function ClaveNombreSesion(const ASerieSes, ANumeroSes: string;
                            ALinea: Integer;
                            const ACodUnidad: string): string;
var
  sSku: string;
  i   : Integer;
begin
  // ses_<SERIE>_<NUMERO>_<LINEA>[ _<SKU sanitizado> ]
  Result := 'ses_' + ASerieSes + '_' + ANumeroSes + '_' +
            Format('%.4d', [ALinea]);
  sSku := ACodUnidad;
  if sSku <> '' then
  begin
    for i := 1 to Length(sSku) do
      if not CharInSet(sSku[i], ['A'..'Z', 'a'..'z', '0'..'9',
                                 '-', '_']) then
        sSku[i] := '_';
    Result := Result + '_' + sSku;
  end;
end;

function TFotosArticulos.GuardarSesion(
  const ASerieSes, ANumeroSes: string;
  ALinea: Integer;
  const ACodArtTentativo, ACodUnidad,
        AFicheroOrigen, AUsuario: string): TFotoInfo;
var
  q              : TUniQuery;
  sDirBase       : string;
  sClave         : string;
  sNombreNuevo   : string;
  sExt           : string;
  oGraphic       : TGraphic;
  bExiste        : Boolean;
  iIndice        : Integer;
  sNombreAnterior: string;
begin
  Result.Clear;
  if ASerieSes = '' then
    raise Exception.Create('Foto de sesion: falta SERIE_SES.');
  if ANumeroSes = '' then
    raise Exception.Create('Foto de sesion: falta NUMERO_SES.');
  if ALinea <= 0 then
    raise Exception.Create('Foto de sesion: LINEA debe ser > 0.');
  if not FileExists(AFicheroOrigen) then
    raise Exception.Create('El fichero origen no existe: ' + AFicheroOrigen);

  sDirBase := DirBase;
  if sDirBase = '' then
    raise Exception.Create('El parametro appDirFotos no esta configurado.');
  ForceDirectories(sDirBase + cSubdir300);
  ForceDirectories(sDirBase + cSubdir600);
  ForceDirectories(sDirBase + cSubdirReal);

  sClave := ClaveNombreSesion(ASerieSes, ANumeroSes, ALinea, ACodUnidad);
  sExt := LowerCase(ExtractFileExt(AFicheroOrigen));
  if Length(sExt) > 0 then sExt := Copy(sExt, 2, MaxInt);
  if sExt = '' then sExt := 'png';

  // Indice incremental: si ya hay foto para esta (sesion, linea, unidad),
  // se borran los PNG anteriores y se sube el numero.
  sNombreAnterior := '';
  iIndice := 1;
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT NOMBRE_FOT_CSF FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF     = :s ' +
      '   AND NUMERO_SES_CSF    = :n ' +
      '   AND LINEA_CSF         = :l ' +
      '   AND CODIGO_UNIDAD_CSF = :u';
    q.ParamByName('s').AsString := ASerieSes;
    q.ParamByName('n').AsString := ANumeroSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('u').AsString := ACodUnidad;
    q.Open;
    bExiste := not q.Eof;
    if bExiste then
    begin
      sNombreAnterior := q.FieldByName('NOMBRE_FOT_CSF').AsString;
      iIndice         := ExtraerIndice(sNombreAnterior) + 1;
      if iIndice < 1 then iIndice := 1;
    end;
  finally
    FreeAndNil(q);
  end;
  sNombreNuevo := ComponerNombre(sClave, iIndice);

  oGraphic := CargarGraficoDeFichero(AFicheroOrigen);
  try
    GuardarComoPng(oGraphic,
                   SubdirDe(frReal) + sNombreNuevo + '.png');
    GuardarRedimensionado(oGraphic,
                          SubdirDe(frPx300) + sNombreNuevo + '.png',
                          cLado300);
    GuardarRedimensionado(oGraphic,
                          SubdirDe(frPx600) + sNombreNuevo + '.png',
                          cLado600);
  finally
    FreeAndNil(oGraphic);
  end;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'INSERT INTO fza_compras_sesiones_fotos ' +
      '  (SERIE_SES_CSF, NUMERO_SES_CSF, LINEA_CSF, CODIGO_UNIDAD_CSF, ' +
      '   CODIGO_ART_TENTATIVO_CSF, NOMBRE_FOT_CSF, EXTENSION_ORIGEN_CSF, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:s, :n, :l, :u, :a, :nom, :ext, NOW(), :usr, NOW(), :usr) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  CODIGO_ART_TENTATIVO_CSF = :a, ' +
      '  NOMBRE_FOT_CSF           = :nom, ' +
      '  EXTENSION_ORIGEN_CSF     = :ext, ' +
      '  INSTANTE_MODIF           = NOW(), ' +
      '  USUARIO_MODIF            = :usr';
    q.ParamByName('s').AsString   := ASerieSes;
    q.ParamByName('n').AsString   := ANumeroSes;
    q.ParamByName('l').AsInteger  := ALinea;
    q.ParamByName('u').AsString   := ACodUnidad;
    q.ParamByName('a').AsString   := ACodArtTentativo;
    q.ParamByName('nom').AsString := sNombreNuevo;
    q.ParamByName('ext').AsString := sExt;
    q.ParamByName('usr').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;

  // Tras escribir la nueva, limpiar los PNG del nombre anterior.
  if (sNombreAnterior <> '') and (sNombreAnterior <> sNombreNuevo) then
    BorrarFicherosDeNombre(sNombreAnterior);

  Result.Encontrada      := True;
  Result.Origen          := foSku;
  Result.CodigoArt       := ACodArtTentativo;
  Result.CodigoSku       := ACodUnidad;
  Result.ClaveResuelta   := ACodUnidad;
  Result.NombreBase      := sNombreNuevo;
  Result.ExtensionOrigen := sExt;
end;

function TFotosArticulos.ResolverSesion(
  const ASerieSes, ANumeroSes: string;
  ALinea: Integer;
  const ACodUnidad: string = ''): TFotoInfo;
var
  q : TUniQuery;
  prefijos: TArray<string>;
  i : Integer;
begin
  Result.Clear;
  if (ASerieSes = '') or (ANumeroSes = '') or (ALinea <= 0) then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;

    // 1. Match exacto por SKU (o cadena vacia = padre)
    q.SQL.Text :=
      'SELECT * FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF     = :s ' +
      '   AND NUMERO_SES_CSF    = :n ' +
      '   AND LINEA_CSF         = :l ' +
      '   AND CODIGO_UNIDAD_CSF = :u';
    q.ParamByName('s').AsString := ASerieSes;
    q.ParamByName('n').AsString := ANumeroSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('u').AsString := ACodUnidad;
    q.Open;
    if not q.Eof then
    begin
      Result.Encontrada    := True;
      if ACodUnidad = '' then Result.Origen := foArticulo
      else Result.Origen := foSku;
      Result.CodigoArt     :=
                       q.FieldByName('CODIGO_ART_TENTATIVO_CSF').AsString;
      Result.CodigoSku     := ACodUnidad;
      Result.ClaveResuelta := ACodUnidad;
      Result.NombreBase    := q.FieldByName('NOMBRE_FOT_CSF').AsString;
      Result.ExtensionOrigen :=
                       q.FieldByName('EXTENSION_ORIGEN_CSF').AsString;
      Exit;
    end;
    q.Close;

    // 2. Fallback por prefijos (mismo esquema que Resolver). Solo si
    //    nos pidieron un SKU concreto.
    if ACodUnidad <> '' then
    begin
      prefijos := GenerarPrefijosSku(ACodUnidad);
      for i := 0 to High(prefijos) do
      begin
        if prefijos[i] = ACodUnidad then Continue;
        q.SQL.Text :=
          'SELECT * FROM fza_compras_sesiones_fotos ' +
          ' WHERE SERIE_SES_CSF     = :s ' +
          '   AND NUMERO_SES_CSF    = :n ' +
          '   AND LINEA_CSF         = :l ' +
          '   AND CODIGO_UNIDAD_CSF = :u';
        q.ParamByName('s').AsString  := ASerieSes;
        q.ParamByName('n').AsString  := ANumeroSes;
        q.ParamByName('l').AsInteger := ALinea;
        q.ParamByName('u').AsString  := prefijos[i];
        q.Open;
        if not q.Eof then
        begin
          Result.Encontrada    := True;
          Result.Origen        := foSkuPrefijo;
          Result.CodigoArt     :=
                       q.FieldByName('CODIGO_ART_TENTATIVO_CSF').AsString;
          Result.CodigoSku     := ACodUnidad;
          Result.ClaveResuelta := prefijos[i];
          Result.NombreBase    := q.FieldByName('NOMBRE_FOT_CSF').AsString;
          Result.ExtensionOrigen :=
                       q.FieldByName('EXTENSION_ORIGEN_CSF').AsString;
          Exit;
        end;
        q.Close;
      end;
    end;

    // 3. Fallback a foto de la linea (CODIGO_UNIDAD_CSF = '')
    if ACodUnidad <> '' then
    begin
      q.SQL.Text :=
        'SELECT * FROM fza_compras_sesiones_fotos ' +
        ' WHERE SERIE_SES_CSF     = :s ' +
        '   AND NUMERO_SES_CSF    = :n ' +
        '   AND LINEA_CSF         = :l ' +
        '   AND CODIGO_UNIDAD_CSF = ''''';
      q.ParamByName('s').AsString  := ASerieSes;
      q.ParamByName('n').AsString  := ANumeroSes;
      q.ParamByName('l').AsInteger := ALinea;
      q.Open;
      if not q.Eof then
      begin
        Result.Encontrada    := True;
        Result.Origen        := foArticulo;
        Result.CodigoArt     :=
                       q.FieldByName('CODIGO_ART_TENTATIVO_CSF').AsString;
        Result.CodigoSku     := ACodUnidad;
        Result.ClaveResuelta := '';
        Result.NombreBase    := q.FieldByName('NOMBRE_FOT_CSF').AsString;
        Result.ExtensionOrigen :=
                       q.FieldByName('EXTENSION_ORIGEN_CSF').AsString;
      end;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TFotosArticulos.EliminarSesion(
  const ASerieSes, ANumeroSes: string;
  ALinea: Integer;
  const ACodUnidad: string);
var
  q          : TUniQuery;
  sNombreBase: string;
begin
  if (ASerieSes = '') or (ANumeroSes = '') or (ALinea <= 0) then Exit;
  sNombreBase := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConexion;
    q.SQL.Text :=
      'SELECT NOMBRE_FOT_CSF FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF     = :s ' +
      '   AND NUMERO_SES_CSF    = :n ' +
      '   AND LINEA_CSF         = :l ' +
      '   AND CODIGO_UNIDAD_CSF = :u';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumeroSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('u').AsString  := ACodUnidad;
    q.Open;
    if not q.Eof then
      sNombreBase := q.FieldByName('NOMBRE_FOT_CSF').AsString;
    q.Close;
    if sNombreBase = '' then Exit;

    q.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF     = :s ' +
      '   AND NUMERO_SES_CSF    = :n ' +
      '   AND LINEA_CSF         = :l ' +
      '   AND CODIGO_UNIDAD_CSF = :u';
    q.ParamByName('s').AsString  := ASerieSes;
    q.ParamByName('n').AsString  := ANumeroSes;
    q.ParamByName('l').AsInteger := ALinea;
    q.ParamByName('u').AsString  := ACodUnidad;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
  BorrarFicherosDeNombre(sNombreBase);
end;

procedure TFotosArticulos.MigrarFotosSesion(
  const ASerieSes, ANumeroSes: string;
  ALinea: Integer;
  const ACodigoArt, AUsuario: string);
var
  qSrc, qIns, qDel: TUniQuery;
  sClave, sNombreNuevo, sNombreSrc, sExt, sCodUnidad: string;
  iIndice: Integer;
begin
  if (ASerieSes = '') or (ANumeroSes = '') or (ALinea <= 0) then Exit;
  if Trim(ACodigoArt) = '' then Exit;

  qSrc := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  qDel := TUniQuery.Create(nil);
  try
    qSrc.Connection := FConexion;
    qIns.Connection := FConexion;
    qDel.Connection := FConexion;

    qSrc.SQL.Text :=
      'SELECT * FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF  = :s ' +
      '   AND NUMERO_SES_CSF = :n ' +
      '   AND LINEA_CSF      = :l';
    qSrc.ParamByName('s').AsString  := ASerieSes;
    qSrc.ParamByName('n').AsString  := ANumeroSes;
    qSrc.ParamByName('l').AsInteger := ALinea;
    qSrc.Open;

    while not qSrc.Eof do
    begin
      sCodUnidad := qSrc.FieldByName('CODIGO_UNIDAD_CSF').AsString;
      sNombreSrc := qSrc.FieldByName('NOMBRE_FOT_CSF').AsString;
      sExt       := qSrc.FieldByName('EXTENSION_ORIGEN_CSF').AsString;
      sClave     := ClaveNombre(ACodigoArt, sCodUnidad);

      // Indice siguiente segun lo que ya haya en fza_articulos_fotos
      // para no machacar fotos previas del mismo articulo+unidad.
      iIndice := 1;
      qIns.SQL.Text :=
        'SELECT NOMBRE_FOT_FOT FROM fza_articulos_fotos ' +
        ' WHERE CODIGO_ART_FOT    = :a ' +
        '   AND CODIGO_UNIDAD_FOT = :u';
      qIns.ParamByName('a').AsString := ACodigoArt;
      qIns.ParamByName('u').AsString := sCodUnidad;
      qIns.Open;
      if not qIns.Eof then
        iIndice := ExtraerIndice(qIns.FieldByName('NOMBRE_FOT_FOT').AsString) + 1;
      qIns.Close;
      if iIndice < 1 then iIndice := 1;
      sNombreNuevo := ComponerNombre(sClave, iIndice);

      // Renombrar los tres PNG (real, 600, 300) — si alguno no existe
      // por lo que sea, no abortamos, solo seguimos.
      if FileExists(SubdirDe(frReal) + sNombreSrc + '.png') then
        RenameFile(SubdirDe(frReal) + sNombreSrc + '.png',
                   SubdirDe(frReal) + sNombreNuevo + '.png');
      if FileExists(SubdirDe(frPx600) + sNombreSrc + '.png') then
        RenameFile(SubdirDe(frPx600) + sNombreSrc + '.png',
                   SubdirDe(frPx600) + sNombreNuevo + '.png');
      if FileExists(SubdirDe(frPx300) + sNombreSrc + '.png') then
        RenameFile(SubdirDe(frPx300) + sNombreSrc + '.png',
                   SubdirDe(frPx300) + sNombreNuevo + '.png');

      // Upsert en fza_articulos_fotos
      qIns.SQL.Text :=
        'INSERT INTO fza_articulos_fotos ' +
        '  (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT, ' +
        '   EXTENSION_ORIGEN_FOT, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:a, :u, :nom, :ext, NOW(), :usr, NOW(), :usr) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  NOMBRE_FOT_FOT       = :nom, ' +
        '  EXTENSION_ORIGEN_FOT = :ext, ' +
        '  INSTANTE_MODIF       = NOW(), ' +
        '  USUARIO_MODIF        = :usr';
      qIns.ParamByName('a').AsString   := ACodigoArt;
      qIns.ParamByName('u').AsString   := sCodUnidad;
      qIns.ParamByName('nom').AsString := sNombreNuevo;
      qIns.ParamByName('ext').AsString := sExt;
      qIns.ParamByName('usr').AsString := AUsuario;
      qIns.ExecSQL;

      qSrc.Next;
    end;
    qSrc.Close;

    // Borrar de un golpe todas las filas migradas
    qDel.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF  = :s ' +
      '   AND NUMERO_SES_CSF = :n ' +
      '   AND LINEA_CSF      = :l';
    qDel.ParamByName('s').AsString  := ASerieSes;
    qDel.ParamByName('n').AsString  := ANumeroSes;
    qDel.ParamByName('l').AsInteger := ALinea;
    qDel.ExecSQL;
  finally
    FreeAndNil(qSrc);
    FreeAndNil(qIns);
    FreeAndNil(qDel);
  end;
end;

initialization
  oFotos := TFotosArticulos.Create;

finalization
  FreeAndNil(oFotos);

end.
