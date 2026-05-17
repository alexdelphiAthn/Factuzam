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
  frxClass, frxDBSet;

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
    function CargarGraficoDeFichero(const ARuta: string): TGraphic;
    procedure RotarBitmap90(ABitmap: TBitmap; AHorario: Boolean);
    procedure RotarFicheroPng(const ARuta: string; AHorario: Boolean);
    procedure RotarFicheroReal(const ARuta: string; AHorario: Boolean);
    procedure BorrarFicherosDeNombre(const ANombreBase, AExtReal: string);
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
    /// El indice incremental garantiza que cada guardado produce un
    /// nombre nuevo (`<clave>_<NNN>`) y borra los ficheros anteriores,
    /// asi se invalida cualquier cache por nombre de fichero.
    function Guardar(const ACodArt, ACodSku, AFicheroOrigen: string): TFotoInfo;

    /// Gira las tres copias de la foto (300/600/real) 90 grados en el
    /// sentido indicado y avanza el indice. La fila de BBDD apunta al
    /// nuevo nombre y los ficheros anteriores se borran.
    function Rotar(const ACodArt, ACodSku: string;
                   AHorario: Boolean): TFotoInfo;

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

procedure TFotosArticulos.BorrarFicherosDeNombre(const ANombreBase,
                                                 AExtReal: string);

  procedure BorrarSiExiste(const ARuta: string);
  begin
    if (ARuta <> '') and FileExists(ARuta) then
      DeleteFile(PChar(ARuta));
  end;

var
  sExt: string;
begin
  if ANombreBase = '' then Exit;
  BorrarSiExiste(SubdirDe(frPx300) + ANombreBase + '.png');
  BorrarSiExiste(SubdirDe(frPx600) + ANombreBase + '.png');
  sExt := AExtReal;
  if sExt = '' then sExt := 'png';
  BorrarSiExiste(SubdirDe(frReal) + ANombreBase + '.' + sExt);
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

procedure TFotosArticulos.RotarFicheroReal(const ARuta: string;
                                           AHorario: Boolean);
var
  graf : TGraphic;
  bmp  : TBitmap;
  sExt : string;
  jpg  : TJPEGImage;
  png  : TPngImage;
begin
  if not FileExists(ARuta) then Exit;
  sExt := LowerCase(ExtractFileExt(ARuta));
  graf := CargarGraficoDeFichero(ARuta);
  bmp  := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.SetSize(graf.Width, graf.Height);
    bmp.Canvas.Draw(0, 0, graf);
    RotarBitmap90(bmp, AHorario);
    // Guardamos en la misma extension original (re-encodificamos)
    if (sExt = '.jpg') or (sExt = '.jpeg') then
    begin
      jpg := TJPEGImage.Create;
      try
        jpg.Assign(bmp);
        jpg.SaveToFile(ARuta);
      finally
        FreeAndNil(jpg);
      end;
    end
    else if (sExt = '.bmp') then
      bmp.SaveToFile(ARuta)
    else
    begin
      // PNG o cualquier otra: PNG es lo mas seguro
      png := TPngImage.Create;
      try
        png.Assign(bmp);
        png.SaveToFile(ARuta);
      finally
        FreeAndNil(png);
      end;
    end;
  finally
    FreeAndNil(bmp);
    FreeAndNil(graf);
  end;
end;

{ ----------------------------------------------------------------- }
{   Guardar / eliminar / rotar                                      }
{ ----------------------------------------------------------------- }

function TFotosArticulos.Guardar(const ACodArt, ACodSku,
                                 AFicheroOrigen: string): TFotoInfo;
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
  sExt   := LowerCase(ExtractFileExt(AFicheroOrigen));
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
    q.Connection := oConn;
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

  // 2. Copia real (con extension original) y redimensionados PNG.
  TFile.Copy(AFicheroOrigen,
             SubdirDe(frReal) + sNombreNuevo + '.' + sExt, True);
  oGraphic := CargarGraficoDeFichero(AFicheroOrigen);
  try
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
    q.FieldByName(fnomfot).AsString       := sNombreNuevo;
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

  // 4. Limpieza de ficheros con el nombre previo (si lo hubiera y es
  //    distinto del nuevo). Se hace al final para que un fallo en la
  //    escritura no deje al sistema sin foto.
  if (sNombreAnterior <> '') and (sNombreAnterior <> sNombreNuevo) then
    BorrarFicherosDeNombre(sNombreAnterior, sExtAnterior);

  Result.Encontrada      := True;
  if ACodSku = '' then
    Result.Origen := foArticulo
  else
    Result.Origen := foSku;
  Result.CodigoArt       := ACodArt;
  Result.CodigoSku       := ACodSku;
  Result.NombreBase      := sNombreNuevo;
  Result.ExtensionOrigen := sExt;
end;

function TFotosArticulos.Rotar(const ACodArt, ACodSku: string;
                               AHorario: Boolean): TFotoInfo;
var
  info             : TFotoInfo;
  sClave           : string;
  sNombreAnterior  : string;
  sExtAnterior     : string;
  sNombreNuevo     : string;
  iIndice          : Integer;
  ruta300, ruta600 : string;
  rutaReal         : string;
  rutaReal300, rutaReal600: string;
  rutaRealNuevo    : string;
  q                : TUniQuery;
begin
  Result.Clear;
  info := Resolver(ACodArt, ACodSku);
  if not info.Encontrada then
    raise Exception.Create('No hay foto registrada para rotar.');

  // Si la foto resuelta venia del articulo padre y se rota desde un
  // SKU, en realidad estamos rotando la del articulo. Mantenemos la
  // fila padre.
  if info.Origen = foArticulo then
    sClave := ClaveNombre(ACodArt, '')
  else
    sClave := ClaveNombre(ACodArt, ACodSku);

  sNombreAnterior := info.NombreBase;
  sExtAnterior    := info.ExtensionOrigen;
  if sExtAnterior = '' then sExtAnterior := 'png';

  ruta300  := SubdirDe(frPx300) + sNombreAnterior + '.png';
  ruta600  := SubdirDe(frPx600) + sNombreAnterior + '.png';
  rutaReal := SubdirDe(frReal)  + sNombreAnterior + '.' + sExtAnterior;

  // Rotamos in situ sobre los ficheros existentes...
  RotarFicheroPng(ruta300,  AHorario);
  RotarFicheroPng(ruta600,  AHorario);
  RotarFicheroReal(rutaReal, AHorario);

  // ...y los renombramos al siguiente indice.
  iIndice      := ExtraerIndice(sNombreAnterior) + 1;
  if iIndice < 1 then iIndice := 1;
  sNombreNuevo := ComponerNombre(sClave, iIndice);

  rutaRealNuevo := SubdirDe(frReal) + sNombreNuevo + '.' + sExtAnterior;
  rutaReal300   := SubdirDe(frPx300) + sNombreNuevo + '.png';
  rutaReal600   := SubdirDe(frPx600) + sNombreNuevo + '.png';
  if FileExists(ruta300)  then RenameFile(ruta300,  rutaReal300);
  if FileExists(ruta600)  then RenameFile(ruta600,  rutaReal600);
  if FileExists(rutaReal) then RenameFile(rutaReal, rutaRealNuevo);

  // Actualizamos la fila correspondiente.
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      ' UPDATE fza_articulos_fotos ' +
      '    SET NOMBRE_FOT_FOT   = :NOMBRE, ' +
      '        USUARIO_MODIF    = :USUARIO ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_SKU';
    q.ParamByName('NOMBRE').AsString     := sNombreNuevo;
    q.ParamByName('USUARIO').AsString    := oUser;
    q.ParamByName('CODIGO_ART').AsString := ACodArt;
    if info.Origen = foArticulo then
      q.ParamByName('CODIGO_SKU').AsString := ''
    else
      q.ParamByName('CODIGO_SKU').AsString := ACodSku;
    q.Execute;
  finally
    FreeAndNil(q);
  end;

  Result.Encontrada      := True;
  Result.Origen          := info.Origen;
  Result.CodigoArt       := ACodArt;
  Result.CodigoSku       := ACodSku;
  Result.NombreBase      := sNombreNuevo;
  Result.ExtensionOrigen := sExtAnterior;
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
    // En FastReport 6, `OnBeforePrint` de un TfrxView es una propiedad
    // string (nombre de un proc del script). El evento Delphi para
    // engancharse en codigo nativo es `OnBeforePrintEvent`.
    pic.OnBeforePrintEvent := hook.OnBeforePrint;
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
