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
    a nivel SKU en otro caso); las imagenes reales viven en
    `oAppParams.GetPath('appDirFotos')` repartidas en tres subcarpetas:

      300/   PNG redimensionado a 300 px (lado mayor)
      600/   PNG redimensionado a 600 px (lado mayor)
      real/  fichero original con su extension nativa

    El nombre de fichero base (`NOMBRE_FOT_FOT`) es estable y se genera al
    alta a partir del par (articulo, sku) y se conserva mientras la foto
    exista. Reemplazar la foto reescribe los ficheros pero mantiene el
    nombre.

    Resolucion (analogo al fallback de tarifas):
      1. Si hay foto del SKU, esa.
      2. Si no, foto del articulo padre.
      3. Si no, vacio.

  Constantes para nombres de columna SQL: vease seccion `const` mas abajo.
}

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.StrUtils, System.IOUtils,
  Vcl.Graphics, Vcl.Imaging.PngImage, Vcl.Imaging.Jpeg,
  Data.DB, DBAccess, Uni,
  frxClass;

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

  TFotoOrigen = (foSinFoto, foArticulo, foSku);

  TFotoInfo = record
    Encontrada  : Boolean;
    Origen      : TFotoOrigen;
    CodigoArt   : string;
    CodigoSku   : string;
    NombreBase  : string;          // NOMBRE_FOT_FOT (sin extension)
    ExtensionOrigen : string;      // sin punto (png, jpg, jpeg, ...)
    procedure Clear;
  end;

  /// Acceso al sistema de fotos. Vive como singleton `oFotos` igual que
  /// `oAppParams`. Reutiliza la conexion global `inLibGlobalVar.oConn`.
  TFotosArticulos = class
  private
    function DirBase: string;
    function SubdirDe(AResolucion: TFotoResolucion): string;
    function GenerarNombreBase(const ACodArt, ACodSku: string): string;
    procedure GuardarRedimensionado(const AOriginal: TGraphic;
                                    const ARutaPng: string;
                                    ALadoMayor: Integer);
    function CargarGraficoDeFichero(const ARuta: string): TGraphic;
  public
    /// Ruta del fichero para una foto resuelta, en la resolucion pedida.
    /// Devuelve '' si AInfo.Encontrada = False o si el fichero no existe.
    function RutaFoto(const AInfo: TFotoInfo;
                      AResolucion: TFotoResolucion): string;

    /// Resuelve la foto aplicable a (articulo, sku) con fallback al padre.
    /// Si ACodSku = '' busca solo a nivel articulo.
    function Resolver(const ACodArt, ACodSku: string): TFotoInfo;

    /// Importa una foto desde un fichero de origen, generando las tres
    /// resoluciones bajo appDirFotos. Inserta/actualiza la fila en
    /// fza_articulos_fotos. ACodSku = '' guarda foto a nivel articulo.
    function Guardar(const ACodArt, ACodSku, AFicheroOrigen: string): TFotoInfo;

    /// Elimina la foto (BBDD + ficheros 300/600/real).
    procedure Eliminar(const ACodArt, ACodSku: string);
  end;

/// Sustituye en el informe los TfrxPictureView llamados foto300/foto600/
/// fotoReal por la foto resuelta del par (articulo, sku) que se obtenga
/// del `DataSet` de la banda padre. Llamar tras PrepareReport o desde
/// `AfterReportLoaded`. Si el par no se puede inferir (no hay banda con
/// dataset, o el dataset no tiene los campos esperados), la imagen se
/// limpia (queda en blanco).
procedure SustituirFotosEnReport(Report: TfrxReport);

var
  oFotos: TFotosArticulos;

implementation

uses
  inLibGlobalVar, inLibAppParam;

{ TFotoInfo }

procedure TFotoInfo.Clear;
begin
  Encontrada      := False;
  Origen          := foSinFoto;
  CodigoArt       := '';
  CodigoSku       := '';
  NombreBase      := '';
  ExtensionOrigen := '';
end;

{ ----------------------------------------------------------------- }
{   Helpers de ruta y nombre                                        }
{ ----------------------------------------------------------------- }

function TFotosArticulos.DirBase: string;
begin
  Result := oAppParams.GetPath('appDirFotos');
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

function TFotosArticulos.GenerarNombreBase(const ACodArt,
                                           ACodSku: string): string;
begin
  if ACodSku = '' then
    Result := 'art_' + SanearNombre(ACodArt)
  else
    Result := 'sku_' + SanearNombre(ACodSku);
end;

{ ----------------------------------------------------------------- }
{   Persistencia BBDD                                               }
{ ----------------------------------------------------------------- }

function TFotosArticulos.Resolver(const ACodArt,
                                  ACodSku: string): TFotoInfo;
var
  q: TUniQuery;
begin
  Result.Clear;
  Result.CodigoArt := ACodArt;
  Result.CodigoSku := ACodSku;
  if ACodArt = '' then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    if ACodSku <> '' then
    begin
      // Intento foto del SKU
      q.SQL.Text :=
        ' SELECT * FROM fza_articulos_fotos ' +
        '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
        '    AND CODIGO_UNIDAD_FOT = :CODIGO_SKU ' +
        '  LIMIT 1';
      q.ParamByName('CODIGO_ART').AsString := ACodArt;
      q.ParamByName('CODIGO_SKU').AsString := ACodSku;
      q.Open;
      if not q.Eof then
      begin
        Result.Encontrada      := True;
        Result.Origen          := foSku;
        Result.NombreBase      := q.FieldByName(fnomfot).AsString;
        Result.ExtensionOrigen := q.FieldByName(fextfot).AsString;
        Exit;
      end;
      q.Close;
    end;

    // Fallback: foto del articulo
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
      Result.NombreBase      := q.FieldByName(fnomfot).AsString;
      Result.ExtensionOrigen := q.FieldByName(fextfot).AsString;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TFotosArticulos.RutaFoto(const AInfo: TFotoInfo;
                                  AResolucion: TFotoResolucion): string;
var
  sDir, sFichero, sExt: string;
begin
  Result := '';
  if not AInfo.Encontrada then Exit;
  sDir := SubdirDe(AResolucion);
  if sDir = '' then Exit;
  if AResolucion = frReal then
  begin
    sExt := AInfo.ExtensionOrigen;
    if sExt = '' then sExt := 'png';
  end
  else
    sExt := 'png';
  sFichero := sDir + AInfo.NombreBase + '.' + sExt;
  if FileExists(sFichero) then
    Result := sFichero;
end;

{ ----------------------------------------------------------------- }
{   Redimensionado GDI+                                             }
{ ----------------------------------------------------------------- }

function TFotosArticulos.CargarGraficoDeFichero(
                                          const ARuta: string): TGraphic;
var
  sExt: string;
  png : TPngImage;
  jpg : TJPEGImage;
  bmp : TBitmap;
begin
  Result := nil;
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

procedure TFotosArticulos.GuardarRedimensionado(const AOriginal: TGraphic;
                                                const ARutaPng: string;
                                                ALadoMayor: Integer);
var
  iAncho, iAlto: Integer;
  oBitmap     : TBitmap;
  oPng        : TPngImage;
  rDst        : TRect;
  dEscala     : Double;
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
  try
    oBitmap.PixelFormat := pf32bit;
    oBitmap.SetSize(iAncho, iAlto);
    // HALFTONE = mejor calidad de redimension via GDI+
    SetStretchBltMode(oBitmap.Canvas.Handle, HALFTONE);
    SetBrushOrgEx(oBitmap.Canvas.Handle, 0, 0, nil);
    rDst := Rect(0, 0, iAncho, iAlto);
    oBitmap.Canvas.StretchDraw(rDst, AOriginal);

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

{ ----------------------------------------------------------------- }
{   Guardar / eliminar                                              }
{ ----------------------------------------------------------------- }

function TFotosArticulos.Guardar(const ACodArt, ACodSku,
                                 AFicheroOrigen: string): TFotoInfo;
var
  q          : TUniQuery;
  sDirBase   : string;
  sNombreBase: string;
  sExt       : string;
  oGraphic   : TGraphic;
  bExiste    : Boolean;
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

  sNombreBase := GenerarNombreBase(ACodArt, ACodSku);
  sExt := LowerCase(ExtractFileExt(AFicheroOrigen));
  if Length(sExt) > 0 then
    sExt := Copy(sExt, 2, MaxInt);
  if sExt = '' then sExt := 'png';

  // 1. Copia real (con extension original)
  TFile.Copy(AFicheroOrigen,
             SubdirDe(frReal) + sNombreBase + '.' + sExt, True);

  // 2. Redimensionados PNG
  oGraphic := CargarGraficoDeFichero(AFicheroOrigen);
  try
    GuardarRedimensionado(oGraphic,
                          SubdirDe(frPx300) + sNombreBase + '.png',
                          cLado300);
    GuardarRedimensionado(oGraphic,
                          SubdirDe(frPx600) + sNombreBase + '.png',
                          cLado600);
  finally
    FreeAndNil(oGraphic);
  end;

  // 3. Upsert en fza_articulos_fotos
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
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
    q.FieldByName(fnomfot).AsString       := sNombreBase;
    q.FieldByName(fextfot).AsString       := sExt;
    if not bExiste then
    begin
      q.FieldByName(finstalta).AsDateTime := Now;
      q.FieldByName(fusralta).AsString    := oUser;
    end;
    q.FieldByName(fusrmodif).AsString     := oUser;
    q.Post;
  finally
    FreeAndNil(q);
  end;

  Result.Encontrada      := True;
  if ACodSku = '' then
    Result.Origen := foArticulo
  else
    Result.Origen := foSku;
  Result.CodigoArt       := ACodArt;
  Result.CodigoSku       := ACodSku;
  Result.NombreBase      := sNombreBase;
  Result.ExtensionOrigen := sExt;
end;

procedure TFotosArticulos.Eliminar(const ACodArt, ACodSku: string);
var
  q   : TUniQuery;
  info: TFotoInfo;

  procedure BorrarSiExiste(const ARuta: string);
  begin
    if (ARuta <> '') and FileExists(ARuta) then
      DeleteFile(PChar(ARuta));
  end;

begin
  info := Resolver(ACodArt, ACodSku);
  // Solo borramos si la fila resuelta era exactamente la pedida; si
  // estabamos resolviendo un SKU pero la foto venia del articulo padre,
  // no hay nada que borrar para el SKU.
  if info.Encontrada and
     (((ACodSku = '') and (info.Origen = foArticulo)) or
      ((ACodSku <> '') and (info.Origen = foSku))) then
  begin
    BorrarSiExiste(RutaFoto(info, frPx300));
    BorrarSiExiste(RutaFoto(info, frPx600));
    BorrarSiExiste(RutaFoto(info, frReal));
  end;

  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      ' DELETE FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_SKU';
    q.ParamByName('CODIGO_ART').AsString := ACodArt;
    q.ParamByName('CODIGO_SKU').AsString := ACodSku;
    q.Execute;
  finally
    FreeAndNil(q);
  end;
end;

{ ----------------------------------------------------------------- }
{   FastReports: sustitucion automatica                             }
{ ----------------------------------------------------------------- }

// Localiza la banda padre del componente y devuelve el TDataSet asociado
// si lo tiene. Sube la jerarquia hasta encontrar un TfrxDataBand u otro
// banda con DataSet asignado.
function ObtenerDataSetDeBandaPadre(AObj: TfrxComponent): TDataSet;
var
  oParent: TfrxComponent;
  oBand  : TfrxDataBand;
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
end;

// Busca en el dataset un campo cuyo nombre case con cualquiera de los
// alias indicados. Devuelve '' si no encuentra ninguno.
function LeerCampoConAlias(ADataSet: TDataSet;
                           const AAlias: array of string): string;
var
  i: Integer;
  f: TField;
begin
  Result := '';
  if ADataSet = nil then Exit;
  for i := Low(AAlias) to High(AAlias) do
  begin
    f := ADataSet.FindField(AAlias[i]);
    if Assigned(f) and (not f.IsNull) then
      Exit(f.AsString);
  end;
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
  jpg     : TJPEGImage;
  sExt    : string;
begin
  oDataSet := ObtenerDataSetDeBandaPadre(APic);
  if oDataSet = nil then
  begin
    APic.Picture.Assign(nil);
    Exit;
  end;
  sArt := LeerCampoConAlias(oDataSet, ['CODIGO_ART_ART',
                                       'CODIGO_ART_FAC',
                                       'CODIGO_ART_FACLIN',
                                       'CODIGO_ART_LIN',
                                       'CODIGO_ART_SKU',
                                       'CODIGO_ART_PEDLIN',
                                       'CODIGO_ART_ARTTAR',
                                       'CODIGO_ART_AAB',
                                       'CODIGO_ART',
                                       'CODIGO_ARTICULO']);
  sSku := LeerCampoConAlias(oDataSet, ['CODIGO_UNIDAD_SKU',
                                       'CODIGO_UNIDAD_FAC',
                                       'CODIGO_UNIDAD_FACLIN',
                                       'CODIGO_UNIDAD_LIN',
                                       'CODIGO_UNIDAD_PEDLIN',
                                       'CODIGO_UNIDAD_ARTTAR',
                                       'CODIGO_UNIDAD']);
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

  // Cargamos en la TPicture segun la extension real.
  sExt := LowerCase(ExtractFileExt(sRuta));
  if sExt = '.png' then
  begin
    png := TPngImage.Create;
    try
      png.LoadFromFile(sRuta);
      APic.Picture.Assign(png);
    finally
      FreeAndNil(png);
    end;
  end
  else if (sExt = '.jpg') or (sExt = '.jpeg') then
  begin
    jpg := TJPEGImage.Create;
    try
      jpg.LoadFromFile(sRuta);
      APic.Picture.Assign(jpg);
    finally
      FreeAndNil(jpg);
    end;
  end
  else
    APic.Picture.LoadFromFile(sRuta);
end;

type
  TFotoPicHook = class
    Resolucion: TFotoResolucion;
    procedure OnBeforePrint(Sender: TfrxComponent);
  end;

procedure TFotoPicHook.OnBeforePrint(Sender: TfrxComponent);
begin
  if Sender is TfrxPictureView then
    SustituirFotoEnPicture(TfrxPictureView(Sender), Resolucion);
end;

// Lista de hooks viva por TfrxReport para poder liberar al finalizar.
var
  oHooksReporte: TList;

procedure LiberarHooks;
var
  i: Integer;
begin
  if not Assigned(oHooksReporte) then Exit;
  for i := 0 to oHooksReporte.Count - 1 do
    TFotoPicHook(oHooksReporte[i]).Free;
  oHooksReporte.Clear;
end;

procedure SustituirFotosEnReport(Report: TfrxReport);
var
  i      : Integer;
  obj    : TfrxComponent;
  pic    : TfrxPictureView;
  hook   : TFotoPicHook;
  sName  : string;
  bMatch : Boolean;
  res    : TFotoResolucion;
begin
  if Report = nil then Exit;
  if not Assigned(oHooksReporte) then
    oHooksReporte := TList.Create
  else
    LiberarHooks;

  for i := 0 to Report.AllObjects.Count - 1 do
  begin
    obj := TfrxComponent(Report.AllObjects[i]);
    if not (obj is TfrxPictureView) then Continue;
    pic := TfrxPictureView(obj);
    sName := LowerCase(pic.Name);
    bMatch := True;
    if      sName = 'foto300'  then res := frPx300
    else if sName = 'foto600'  then res := frPx600
    else if sName = 'fotoreal' then res := frReal
    else bMatch := False;
    if not bMatch then Continue;

    hook := TFotoPicHook.Create;
    hook.Resolucion := res;
    oHooksReporte.Add(hook);
    pic.OnBeforePrint := hook.OnBeforePrint;
  end;
end;

initialization
  oFotos := TFotosArticulos.Create;
  oHooksReporte := TList.Create;

finalization
  LiberarHooks;
  FreeAndNil(oHooksReporte);
  FreeAndNil(oFotos);

end.
