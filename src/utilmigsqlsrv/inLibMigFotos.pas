{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigFotos                                                 }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.3.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Importa las fotos legacy de `dbo.ocartcol.ArchivoFoto` al sistema de      }
{    fotos de Factuzam (fza_articulos_fotos + ficheros PNG en disco).          }
{                                                                              }
{    El legacy guarda la ruta SIN la carpeta raíz, p.ej.                       }
{    `\temp.34\85san francisco\3834.jpg`; la raíz real (normalmente            }
{    `C:\fotos`) se indica en la UI del migrador y llega en                    }
{    Eng.DirFotosOrigen. El destino (Eng.DirFotosDestino) es la carpeta        }
{    `appDirFotos` del Factuzam destino, p.ej. `$(PUBLICO)\Factuzam\fotos`     }
{    ya expandida a ruta absoluta por la UI.                                   }
{                                                                              }
{    Para cada (Articulo, Color) con foto se generan los TRES PNG del          }
{    esquema de fotos (el mismo trío que TFotosArticulos.Guardar y que las     }
{    fotos descargadas de la nube):                                            }
{      <destino>\300\<nombre>.png    lado mayor 300 px                         }
{      <destino>\600\<nombre>.png    lado mayor 600 px                         }
{      <destino>\real\<nombre>.png   resolución original re-encodificada       }
{                                                                              }
{    y se inserta la fila en fza_articulos_fotos con:                          }
{      CODIGO_ART_FOT    = Articulo                                            }
{      CODIGO_UNIDAD_FOT = ARTICULO/COLORSLOT (prefijo del SKU; mismo slot     }
{                          de color que inLibMigArticulosSkus)                 }
{      NOMBRE_FOT_FOT    = saneado(ARTICULO/COLORSLOT) + '_001'                }
{                                                                              }
{    Paralelismo: la conversión de imagen (decodificar + 3 PNG) corre en       }
{    un pool propio de hilos (Eng.HilosFotos, 2-5 recomendado). Los hilos      }
{    solo tocan ficheros y encolan las filas de INSERT; el hilo del            }
{    dominio (dueño de las conexiones UniDAC, que no admiten uso               }
{    concurrente) las drena hacia el TBulkInsert y lleva el progreso.          }
{    Las claves que comparten fichero se agrupan: el primer éxito genera       }
{    el trío y el resto lo copia.                                              }
{                                                                              }
{    Memoria: el original decodificado se vuelca UNA sola vez a un             }
{    bitmap base del que salen los tres PNG y se libera antes de               }
{    encodificar (las fotos de móvil de 12+ MP en varios hilos a la vez        }
{    agotaban el espacio de direcciones del proceso de 32 bits). Si aun        }
{    así una conversión falla por falta de memoria o de recursos GDI,          }
{    se reintenta una vez en serie antes de contarla como error.               }
{                                                                              }
{    Idempotente: si la pareja (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT) ya          }
{    existe en destino se salta sin tocar ficheros. Si no existe la fila       }
{    pero ya esta el trio 300/600/real en disco, se registra directamente      }
{    sin reconvertirlo. Las filas cuyo fichero origen no existe se             }
{    contabilizan como saltadas con aviso.                                     }
{******************************************************************************}
unit inLibMigFotos;

interface

uses
  UMigEngine;

procedure MigrarFotos(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  Winapi.Windows, Winapi.ActiveX, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  System.SysUtils, System.Classes, System.IOUtils, System.SyncObjs,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Imaging.PngImage, Vcl.Imaging.Jpeg, Vcl.Imaging.GIFImg,
  Data.DB, Uni;

const
  // Subcarpetas y lados, mismos valores que inLibFotos (exe principal).
  cSubdir300  = '300';
  cSubdir600  = '600';
  cSubdirReal = 'real';
  cLado300    = 300;
  cLado600    = 600;
  // Tope de hilos del pool de conversion (la UI sugiere 2-5).
  cMaxHilosFotos = 8;

type
  // Un (articulo, color) pendiente de importar, con su nombre de
  // fichero destino y extension de origen ya calculados.
  TFotoClave = record
    CodArt:    string;
    CodUnidad: string;
    Nombre:    string;     // NOMBRE_FOT_FOT (sin extension)
    Ext:       string;     // EXTENSION_ORIGEN_FOT
  end;

  // Grupo de claves que comparten el MISMO fichero origen (en el
  // legacy varios colores apuntan a la misma foto). El primer exito
  // del grupo genera el trio PNG y el resto lo copia.
  TFotoGrupo = class
  public
    Fichero: string;                 // ruta absoluta en la raiz legacy
    Claves:  TList<TFotoClave>;
    constructor Create(const AFichero: string);
    destructor  Destroy; override;
  end;

  // Estado compartido del pool de hilos de conversion. Los hilos
  // consumen grupos via indice atomico (FSiguiente) y encolan las
  // filas de INSERT en FPendientes; el hilo del dominio las drena
  // hacia el TBulkInsert (la conexion UniDAC no admite concurrencia).
  TImportadorFotos = class
  private
    FEng:        TMigEngine;
    FGrupos:     TObjectList<TFotoGrupo>;
    FDir300:     string;
    FDir600:     string;
    FDirReal:    string;
    FAhoraSQL:   string;
    FUserSQL:    string;
    FPendientes: TStringList;
    FLock:       TCriticalSection;
    FLockRecursos: TCriticalSection;
    FSiguiente:  Integer;
    FGeneradas:  Integer;
    FSaltadas:   Integer;
    FErrores:    Integer;
    FProcesadas: Integer;
    FParar:      Integer;
    function  Parado: Boolean;
    procedure ProcesarGrupo(AGrupo: TFotoGrupo);
    procedure GenerarTrioClave(const AFichero: string;
                               const AClave: TFotoClave);
    procedure EncolarFila(const AClave: TFotoClave);
  public
    constructor Create(Eng: TMigEngine;
                       AGrupos: TObjectList<TFotoGrupo>;
                       const ADir300, ADir600, ADirReal,
                             AAhoraSQL, AUserSQL: string);
    destructor  Destroy; override;
    // Cuerpo de cada hilo del pool: consume grupos hasta agotarlos,
    // hasta cancelacion del engine o hasta Parar.
    procedure TrabajoHilo;
    // Para el pool (los hilos sueltan el trabajo en el proximo grupo).
    procedure Parar;
    // Vuelca las filas encoladas al bulk. Llamar SOLO desde el hilo
    // del dominio.
    procedure DrenarHacia(ABulk: TBulkInsert);
    // Contadores (lecturas atomicas, validas con el pool vivo).
    function Generadas: Integer;
    function Saltadas: Integer;
    function Errores: Integer;
    function Procesadas: Integer;
  end;

// =========================================================================
//  Helpers de imagen (versión standalone de los de inLibFotos, aptos
//  para correr en los hilos del pool: los canvas VCL se bloquean con
//  Canvas.Lock fuera del hilo principal)
// =========================================================================

// Sanea la clave (ART/COLOR) para usarla como nombre de fichero: los
// separadores problematicos se sustituyen por '_'. Identica a
// inLibFotos.SanearNombre para que el nombre cuadre con el del exe.
function SanearNombreFichero(const AOriginal: string): string;
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

// Carga el fichero origen segun su extension: PNG, JPG/JPEG, GIF o BMP.
// Cualquier otra extension se intenta via TWICImage (codec WIC de
// Windows: TIFF, WEBP... si esta instalado); si no se puede, lanza.
function CargarGrafico(const ARuta: string): TGraphic;
var
  sExt: string;
  png:  TPngImage;
  jpg:  TJPEGImage;
  gif:  TGIFImage;
  bmp:  TBitmap;
  wic:  TWICImage;
begin
  Result := nil;
  sExt := LowerCase(ExtractFileExt(ARuta));
  if sExt = '.png' then
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
  else if sExt = '.gif' then
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
  else if sExt = '.bmp' then
  begin
    bmp := TBitmap.Create;
    try
      bmp.LoadFromFile(ARuta);
      Result := bmp;
    except
      FreeAndNil(bmp);
      raise;
    end;
  end
  else
  begin
    wic := TWICImage.Create;
    try
      wic.LoadFromFile(ARuta);
      Result := wic;
    except
      FreeAndNil(wic);
      raise;
    end;
  end;
end;

// Vuelca el grafico origen en un TBitmap pf32bit del mismo tamaño.
// El Lock es obligatorio: corremos en hilos de trabajo y el canvas
// VCL puede perder su DC si no se bloquea fuera del hilo principal.
procedure VolcarEnBitmap(const AOriginal: TGraphic; ADestino: TBitmap);
begin
  ADestino.PixelFormat := pf32bit;
  ADestino.SetSize(AOriginal.Width, AOriginal.Height);
  ADestino.Canvas.Lock;
  try
    ADestino.Canvas.Draw(0, 0, AOriginal);
  finally
    ADestino.Canvas.Unlock;
  end;
end;

// Guarda el bitmap base (pf32bit) como PNG. El Assign duplica los
// pixeles del bitmap: es la unica copia extra viva en ese momento.
procedure GuardarBitmapComoPng(ABase: TBitmap; const ARutaPng: string);
var
  oPng: TPngImage;
begin
  oPng := TPngImage.Create;
  try
    oPng.Assign(ABase);
    oPng.SaveToFile(ARutaPng);
  finally
    FreeAndNil(oPng);
  end;
end;

// Redimensiona el bitmap base manteniendo proporciones (lado mayor =
// ALadoMayor) y guarda como PNG. El reescalado lo hace GDI+ con
// interpolacion bicubica de alta calidad, igual que inLibFotos.
procedure GuardarRedimensionado(ABase: TBitmap; const ARutaPng: string;
                                ALadoMayor: Integer);
var
  iAncho, iAlto: Integer;
  dEscala:       Double;
  oDst:          TBitmap;
  gpSrc:         TGPBitmap;
  gpGfx:         TGPGraphics;
begin
  if ABase.Width >= ABase.Height then
  begin
    dEscala := ALadoMayor / ABase.Width;
    iAncho  := ALadoMayor;
    iAlto   := Round(ABase.Height * dEscala);
  end
  else
  begin
    dEscala := ALadoMayor / ABase.Height;
    iAlto   := ALadoMayor;
    iAncho  := Round(ABase.Width * dEscala);
  end;
  if iAncho < 1 then
    iAncho := 1;
  if iAlto < 1 then
    iAlto := 1;
  oDst := TBitmap.Create;
  try
    oDst.PixelFormat := pf32bit;
    oDst.SetSize(iAncho, iAlto);
    oDst.Canvas.Lock;
    try
      gpSrc := TGPBitmap.Create(ABase.Handle, 0);
      try
        gpGfx := TGPGraphics.Create(oDst.Canvas.Handle);
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
      GuardarBitmapComoPng(oDst, ARutaPng);
    finally
      oDst.Canvas.Unlock;
    end;
  finally
    FreeAndNil(oDst);
  end;
end;

// Genera el trio completo (real + 300 + 600) desde el fichero origen.
// El original decodificado se vuelca UNA sola vez a un bitmap base y
// se libera antes de encodificar; los tres PNG salen de ese bitmap.
// Asi el pico de memoria por foto es ~1 copia en vez de ~3 (critico
// con fotos de movil de 12+ MP y varios hilos en un exe de 32 bits).
procedure GenerarTrioPng(const AFicheroOrigen, ARuta300, ARuta600,
                         ARutaReal: string);
var
  oGraphic:    TGraphic;
  oBase:       TBitmap;
  bPngDirecto: Boolean;
begin
  oBase := TBitmap.Create;
  try
    oGraphic := CargarGrafico(AFicheroOrigen);
    try
      if (oGraphic.Width = 0) or (oGraphic.Height = 0) then
        raise Exception.Create('Imagen vacia o no valida.');
      // La copia "real" de un PNG de origen se guarda tal cual,
      // sin re-encodificar (mismo criterio que la version 1.1).
      bPngDirecto := oGraphic is TPngImage;
      if bPngDirecto then
        TPngImage(oGraphic).SaveToFile(ARutaReal);
      VolcarEnBitmap(oGraphic, oBase);
    finally
      FreeAndNil(oGraphic);
    end;
    if not bPngDirecto then
      GuardarBitmapComoPng(oBase, ARutaReal);
    GuardarRedimensionado(oBase, ARuta300, cLado300);
    GuardarRedimensionado(oBase, ARuta600, cLado600);
  finally
    FreeAndNil(oBase);
  end;
end;

// Errores por agotamiento de memoria o de recursos GDI: EOutOfResources
// ("out of resources") hereda de EOutOfMemory y los fallos de la API
// Win32 ("no hay suficientes recursos de memoria...") llegan como
// EOSError. Son transitorios cuando varios hilos convierten fotos
// grandes a la vez, asi que merecen reintento en serie.
function EsErrorDeRecursos(E: Exception): Boolean;
begin
  Result := (E is EOutOfMemory) or (E is EOSError);
end;

// Copia el trio ya generado de otra clave del MISMO grupo (mismo
// fichero origen). Evita re-decodificar y re-encodificar la imagen,
// que es lo caro.
procedure CopiarTrioPng(const ADir300, ADir600, ADirReal,
                        ANombreOrigen, ANombreDestino: string);
begin
  TFile.Copy(ADir300  + ANombreOrigen  + '.png',
             ADir300  + ANombreDestino + '.png', True);
  TFile.Copy(ADir600  + ANombreOrigen  + '.png',
             ADir600  + ANombreDestino + '.png', True);
  TFile.Copy(ADirReal + ANombreOrigen  + '.png',
             ADirReal + ANombreDestino + '.png', True);
end;

// Compone la ruta absoluta del fichero legacy: raiz + ruta relativa.
// La relativa del legacy empieza por '\'; si alguna fila trae ya una
// ruta absoluta (unidad o UNC) se respeta tal cual.
function ComponerRutaOrigen(const ARaizSinBarra, ARelativa: string): string;
var
  sRel: string;
begin
  sRel := StringReplace(Trim(ARelativa), '/', '\', [rfReplaceAll]);
  if (Length(sRel) >= 2) and
     ((sRel[2] = ':') or (Copy(sRel, 1, 2) = '\\')) then
    Result := sRel
  else
  begin
    if (sRel <> '') and (sRel[1] <> '\') then
      sRel := '\' + sRel;
    Result := ARaizSinBarra + sRel;
  end;
end;

// Construye la fila SQL tanto para fotos nuevas como para las recuperadas
// desde los ficheros que ya existen en la carpeta destino.
function ConstruirFilaFoto(const AClave: TFotoClave;
                           const AAhoraSQL, AUserSQL: string): string;
begin
  Result := Format('%s, %s, %s, %s, %s, %s, %s, %s',
    [ValorOrNull(AClave.CodArt), ValorOrNull(AClave.CodUnidad),
     ValorOrNull(AClave.Nombre), ValorOrNull(AClave.Ext),
     AAhoraSQL, AAhoraSQL, AUserSQL, AUserSQL]);
end;

// Carga solo el nombre base de cada PNG para comprobar en memoria si el trio
// 300/600/real ya fue generado en una migracion anterior.
procedure CargarIndicePng(const ADirectorio: string; ANombres: TStringList);
var
  aFicheros: TArray<string>;
  sFichero:  string;
begin
  ANombres.Clear;
  ANombres.CaseSensitive := False;
  ANombres.Sorted := True;
  ANombres.Duplicates := dupIgnore;
  aFicheros := TDirectory.GetFiles(ADirectorio, '*.png',
                                   TSearchOption.soTopDirectoryOnly);
  for sFichero in aFicheros do
    ANombres.Add(ChangeFileExt(ExtractFileName(sFichero), ''));
end;

function ExisteTrioDestino(const ANombre: string;
                           ANombres300, ANombres600,
                           ANombresReal: TStringList): Boolean;
begin
  Result := (ANombres300.IndexOf(ANombre) >= 0) and
            (ANombres600.IndexOf(ANombre) >= 0) and
            (ANombresReal.IndexOf(ANombre) >= 0);
end;

// =========================================================================
//  TFotoGrupo
// =========================================================================

constructor TFotoGrupo.Create(const AFichero: string);
begin
  inherited Create;
  Fichero := AFichero;
  Claves  := TList<TFotoClave>.Create;
end;

destructor TFotoGrupo.Destroy;
begin
  FreeAndNil(Claves);
  inherited Destroy;
end;

// =========================================================================
//  TImportadorFotos (pool de conversion)
// =========================================================================

constructor TImportadorFotos.Create(Eng: TMigEngine;
                                    AGrupos: TObjectList<TFotoGrupo>;
                                    const ADir300, ADir600, ADirReal,
                                          AAhoraSQL, AUserSQL: string);
begin
  inherited Create;
  FEng        := Eng;
  FGrupos     := AGrupos;
  FDir300     := ADir300;
  FDir600     := ADir600;
  FDirReal    := ADirReal;
  FAhoraSQL   := AAhoraSQL;
  FUserSQL    := AUserSQL;
  FPendientes := TStringList.Create;
  FLock       := TCriticalSection.Create;
  FLockRecursos := TCriticalSection.Create;
  FSiguiente  := -1;
end;

destructor TImportadorFotos.Destroy;
begin
  FreeAndNil(FLockRecursos);
  FreeAndNil(FLock);
  FreeAndNil(FPendientes);
  inherited Destroy;
end;

procedure TImportadorFotos.Parar;
begin
  TInterlocked.Exchange(FParar, 1);
end;

function TImportadorFotos.Parado: Boolean;
begin
  Result := TInterlocked.CompareExchange(FParar, 0, 0) = 1;
end;

procedure TImportadorFotos.EncolarFila(const AClave: TFotoClave);
var
  sFila: string;
begin
  sFila := ConstruirFilaFoto(AClave, FAhoraSQL, FUserSQL);
  FLock.Enter;
  try
    FPendientes.Add(sFila);
  finally
    FLock.Leave;
  end;
end;

procedure TImportadorFotos.DrenarHacia(ABulk: TBulkInsert);
var
  oLote: TStringList;
  j:     Integer;
begin
  // Se intercambia el contenido bajo el lock y el bulk.Add (que puede
  // disparar un Flush con ExecSQL) se hace fuera, para no bloquear a
  // los hilos del pool mientras dura el INSERT.
  oLote := TStringList.Create;
  try
    FLock.Enter;
    try
      oLote.Assign(FPendientes);
      FPendientes.Clear;
    finally
      FLock.Leave;
    end;
    for j := 0 to oLote.Count - 1 do
      ABulk.Add(oLote[j]);
  finally
    FreeAndNil(oLote);
  end;
end;

function TImportadorFotos.Generadas: Integer;
begin
  Result := TInterlocked.CompareExchange(FGeneradas, 0, 0);
end;

function TImportadorFotos.Saltadas: Integer;
begin
  Result := TInterlocked.CompareExchange(FSaltadas, 0, 0);
end;

function TImportadorFotos.Errores: Integer;
begin
  Result := TInterlocked.CompareExchange(FErrores, 0, 0);
end;

function TImportadorFotos.Procesadas: Integer;
begin
  Result := TInterlocked.CompareExchange(FProcesadas, 0, 0);
end;

// Genera el trio PNG de una clave. Si falla por falta de memoria o de
// recursos GDI (punta transitoria con varios hilos convirtiendo fotos
// grandes a la vez) se reintenta UNA vez en serie bajo FLockRecursos,
// para que la foto no quede sin migrar por una punta puntual.
procedure TImportadorFotos.GenerarTrioClave(const AFichero: string;
                                            const AClave: TFotoClave);
begin
  try
    GenerarTrioPng(AFichero,
                   FDir300  + AClave.Nombre + '.png',
                   FDir600  + AClave.Nombre + '.png',
                   FDirReal + AClave.Nombre + '.png');
  except
    on E: Exception do
    begin
      if not EsErrorDeRecursos(E) then
        raise;
      FLockRecursos.Enter;
      try
        GenerarTrioPng(AFichero,
                       FDir300  + AClave.Nombre + '.png',
                       FDir600  + AClave.Nombre + '.png',
                       FDirReal + AClave.Nombre + '.png');
      finally
        FLockRecursos.Leave;
      end;
    end;
  end;
end;

procedure TImportadorFotos.ProcesarGrupo(AGrupo: TFotoGrupo);
var
  k:          Integer;
  oClave:     TFotoClave;
  sNombreGen: string;
begin
  if not FileExists(AGrupo.Fichero) then
  begin
    for k := 0 to AGrupo.Claves.Count - 1 do
    begin
      oClave := AGrupo.Claves[k];
      TInterlocked.Increment(FSaltadas);
      TInterlocked.Increment(FProcesadas);
      FEng.LogSalto('Fotos', oClave.CodUnidad,
                    'fichero no encontrado', AGrupo.Fichero);
    end;
  end
  else
  begin
    // El primer exito genera el trio PNG; el resto de colores que
    // comparten fichero lo copia. Si la generacion falla (imagen
    // corrupta), la siguiente clave vuelve a intentarla y cada una
    // queda anotada en el log, como en la version secuencial.
    sNombreGen := '';
    for k := 0 to AGrupo.Claves.Count - 1 do
    begin
      oClave := AGrupo.Claves[k];
      try
        if sNombreGen = '' then
        begin
          GenerarTrioClave(AGrupo.Fichero, oClave);
          sNombreGen := oClave.Nombre;
        end
        else
          CopiarTrioPng(FDir300, FDir600, FDirReal,
                        sNombreGen, oClave.Nombre);
        EncolarFila(oClave);
        TInterlocked.Increment(FGeneradas);
      except
        on E: Exception do
        begin
          TInterlocked.Increment(FErrores);
          FEng.LogError('Fotos', oClave.CodUnidad, E.Message,
                        AGrupo.Fichero);
        end;
      end;
      TInterlocked.Increment(FProcesadas);
    end;
  end;
end;

procedure TImportadorFotos.TrabajoHilo;
var
  iIdx:     Integer;
  bComInit: Boolean;
begin
  // WIC (formatos exoticos via TWICImage) requiere COM en cada hilo.
  bComInit := Succeeded(CoInitializeEx(nil, COINIT_MULTITHREADED));
  try
    iIdx := TInterlocked.Increment(FSiguiente);
    while (iIdx < FGrupos.Count) and
          (not FEng.IsCancelado) and (not Parado) do
    begin
      ProcesarGrupo(FGrupos[iIdx]);
      iIdx := TInterlocked.Increment(FSiguiente);
    end;
  finally
    if bComInit then
      CoUninitialize;
  end;
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarFotos(Eng: TMigEngine; var Stats: TMigStats);
const
  // ColorSlot identico al de inLibMigArticulosSkus: codigo interno de
  // ocartcol.Color. Asi CODIGO_UNIDAD_FOT casa como
  // prefijo exacto del CODIGO_UNIDAD_SKU migrado (ART/COLOR/TALLA).
  cSelectSrc =
    'SELECT col.Articulo, col.Color, col.ArchivoFoto, ' +
    '       CASE ' +
    '         WHEN col.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(col.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(col.Color))) ' +
    '         ELSE ''0'' ' +
    '       END AS ColorSlot ' +
    'FROM dbo.ocartcol col ' +
    'WHERE col.Articulo IS NOT NULL ' +
    '  AND LTRIM(RTRIM(col.Articulo)) <> '''' ' +
    '  AND col.ArchivoFoto IS NOT NULL ' +
    '  AND LTRIM(RTRIM(col.ArchivoFoto)) <> '''' ' +
    'ORDER BY col.Articulo, col.Color';
  cSelectCount =
    'SELECT COUNT(*) FROM dbo.ocartcol ' +
    'WHERE Articulo IS NOT NULL ' +
    '  AND LTRIM(RTRIM(Articulo)) <> '''' ' +
    '  AND ArchivoFoto IS NOT NULL ' +
    '  AND LTRIM(RTRIM(ArchivoFoto)) <> ''''';
  cColsFotos =
    'CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT, ' +
    'EXTENSION_ORIGEN_FOT, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qSrc:        TUniQuery;
  qDst:        TUniQuery;
  bulk:        TBulkInsert;
  oExistentes: TDictionary<string, Boolean>;
  oReutilizadas: TList<TFotoClave>;
  oGrupos:     TObjectList<TFotoGrupo>;
  oPorFichero: TDictionary<string, TFotoGrupo>;
  oNombres300: TStringList;
  oNombres600: TStringList;
  oNombresReal: TStringList;
  oImp:        TImportadorFotos;
  aHilos:      TArray<TThread>;
  oGrupo:      TFotoGrupo;
  oClave:      TFotoClave;
  iNumHilos:   Integer;
  iPend:       Integer;
  iAhora:      Integer;
  iUltProg:    Integer;
  iUltLog:     Integer;
  i:           Integer;
  bVivos:      Boolean;
  sRaiz:       string;
  sDestino:    string;
  sDir300:     string;
  sDir600:     string;
  sDirReal:    string;
  sArt:        string;
  sColorSlot:  string;
  sRel:        string;
  sCodUnidad:  string;
  sKey:        string;
  sFichero:    string;
  sExt:        string;
  sAhora:      string;
  sUser:       string;
begin
  // ---- Validacion de carpetas y configuracion --------------------------
  sRaiz := ExcludeTrailingPathDelimiter(Trim(Eng.DirFotosOrigen));
  if sRaiz = '' then
    raise Exception.Create(
      'Falta la carpeta raiz de las fotos legacy (p.ej. C:\fotos). ' +
      'Rellena el campo "Raiz fotos legacy" del migrador.');
  if not TDirectory.Exists(sRaiz) then
    raise Exception.CreateFmt(
      'La carpeta raiz de fotos legacy no existe: %s', [sRaiz]);
  sDestino := ExcludeTrailingPathDelimiter(Trim(Eng.DirFotosDestino));
  if sDestino = '' then
    raise Exception.Create(
      'Falta la carpeta destino de fotos (appDirFotos), p.ej. ' +
      '$(PUBLICO)\Factuzam\fotos.');
  sDir300  := IncludeTrailingPathDelimiter(sDestino) + cSubdir300  + '\';
  sDir600  := IncludeTrailingPathDelimiter(sDestino) + cSubdir600  + '\';
  sDirReal := IncludeTrailingPathDelimiter(sDestino) + cSubdirReal + '\';
  ForceDirectories(sDir300);
  ForceDirectories(sDir600);
  ForceDirectories(sDirReal);
  if not (TDirectory.Exists(sDir300) and TDirectory.Exists(sDir600) and
          TDirectory.Exists(sDirReal)) then
    raise Exception.CreateFmt(
      'No se pudieron crear las subcarpetas 300/600/real en: %s',
      [sDestino]);
  iNumHilos := Eng.HilosFotos;
  if iNumHilos < 1 then
    iNumHilos := 1;
  if iNumHilos > cMaxHilosFotos then
    iNumHilos := cMaxHilosFotos;
  Eng.Log('  raiz legacy: %s', [sRaiz]);
  Eng.Log('  destino fotos: %s', [sDestino]);

  oExistentes := TDictionary<string, Boolean>.Create;
  oReutilizadas := TList<TFotoClave>.Create;
  oGrupos     := TObjectList<TFotoGrupo>.Create(True);
  oPorFichero := TDictionary<string, TFotoGrupo>.Create;
  oNombres300 := TStringList.Create;
  oNombres600 := TStringList.Create;
  oNombresReal := TStringList.Create;
  oImp := nil;
  qSrc := nil;
  bulk := nil;
  SetLength(aHilos, 0);
  try
    // Inventariar primero los PNG conservados de corridas anteriores. Solo un
    // trio completo es reutilizable; uno parcial se vuelve a generar.
    CargarIndicePng(sDir300, oNombres300);
    CargarIndicePng(sDir600, oNombres600);
    CargarIndicePng(sDirReal, oNombresReal);
    Eng.Log('  destino disco: %d PNG en 300, %d en 600 y %d en real',
            [oNombres300.Count, oNombres600.Count, oNombresReal.Count]);
    // Pre-cargar las fotos ya registradas en destino (idempotencia O(1)).
    qDst := TUniQuery.Create(nil);
    try
      qDst.Connection := Eng.ConDst;
      qDst.SQL.Text   :=
        'SELECT CONCAT(CODIGO_ART_FOT, ''|'', CODIGO_UNIDAD_FOT) ' +
        'FROM fza_articulos_fotos';
      qDst.Open;
      while not qDst.Eof do
      begin
        oExistentes.AddOrSetValue(qDst.Fields[0].AsString, True);
        qDst.Next;
      end;
    finally
      qDst.Free;
    end;
    Eng.Log('  destino: %d fotos ya registradas', [oExistentes.Count]);

    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);

    // ---- Fase 1: cargar el trabajo pendiente agrupado por fichero ------
    // La consulta es rapida; lo caro (decodificar + 3 PNG) se reparte
    // despues entre los hilos del pool.
    iPend := 0;
    qSrc  := NuevoQOrigen(Eng, cSelectSrc);
    Eng.SetTotal(Eng.ContarOrigen(cSelectCount));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      if Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en fotos, saliendo...');
        Break;
      end;
      Inc(Stats.Leidas);
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sColorSlot := Trim(qSrc.FieldByName('ColorSlot').AsString);
      sRel       := Trim(qSrc.FieldByName('ArchivoFoto').AsString);
      if sColorSlot = '' then
        sColorSlot := '0';
      sCodUnidad := sArt + '/' + sColorSlot;
      sKey       := sArt + '|' + sCodUnidad;
      if oExistentes.ContainsKey(sKey) then
      begin
        // Ya importada en una corrida previa: cuenta como hecha.
        Inc(Stats.Saltadas);
        Eng.IncRow;
      end
      else
      begin
        sFichero := ComponerRutaOrigen(sRaiz, sRel);
        // Extension de origen solo por trazabilidad (todo acaba PNG).
        sExt := LowerCase(ExtractFileExt(sFichero));
        if sExt <> '' then
          sExt := Copy(sExt, 2, MaxInt);
        if sExt = '' then
          sExt := 'png';
        oClave.CodArt    := sArt;
        oClave.CodUnidad := sCodUnidad;
        // Nombre estilo inLibFotos: clave saneada + indice _001.
        oClave.Nombre    := SanearNombreFichero(sCodUnidad) + '_001';
        oClave.Ext       := sExt;
        if ExisteTrioDestino(oClave.Nombre, oNombres300, oNombres600,
                             oNombresReal) then
        begin
          // La BBDD se ha rehecho pero los PNG siguen migrados: recuperar la
          // asociacion sin leer ni convertir otra vez el fichero legacy.
          oReutilizadas.Add(oClave);
          Eng.IncRow;
        end
        else
        begin
          if not oPorFichero.TryGetValue(sFichero, oGrupo) then
          begin
            oGrupo := TFotoGrupo.Create(sFichero);
            oGrupos.Add(oGrupo);
            oPorFichero.Add(sFichero, oGrupo);
          end;
          oGrupo.Claves.Add(oClave);
          Inc(iPend);
        end;
        oExistentes.AddOrSetValue(sKey, True);
      end;
      qSrc.Next;
    end;
    Eng.Log('  reutilizadas: %d fotos ya completas en disco',
            [oReutilizadas.Count]);
    Eng.Log('  pendientes: %d fotos en %d ficheros; %d hilos de ' +
            'conversion', [iPend, oGrupos.Count, iNumHilos]);

    // ---- Fase 2: pool de hilos convirtiendo; este hilo drena a BBDD ----
    bulk := TBulkInsert.Create(Eng.ConDst, 'fza_articulos_fotos',
                               cColsFotos, 500);
    for i := 0 to oReutilizadas.Count - 1 do
      bulk.Add(ConstruirFilaFoto(oReutilizadas[i], sAhora, sUser));
    Inc(Stats.Insertadas, oReutilizadas.Count);
    if oGrupos.Count > 0 then
    begin
      if iNumHilos > oGrupos.Count then
        iNumHilos := oGrupos.Count;
      oImp := TImportadorFotos.Create(Eng, oGrupos, sDir300, sDir600,
                                      sDirReal, sAhora, sUser);
      SetLength(aHilos, iNumHilos);
      for i := 0 to iNumHilos - 1 do
      begin
        aHilos[i] := TThread.CreateAnonymousThread(oImp.TrabajoHilo);
        aHilos[i].FreeOnTerminate := False;
        aHilos[i].Start;
      end;
      // Mientras el pool trabaja, este hilo (dueño de la conexion)
      // vuelca a BBDD lo encolado y refresca progreso y log.
      iUltProg := 0;
      iUltLog  := 0;
      repeat
        bVivos := False;
        for i := 0 to High(aHilos) do
          if not aHilos[i].Finished then
            bVivos := True;
        oImp.DrenarHacia(bulk);
        iAhora := oImp.Procesadas;
        if iAhora > iUltProg then
        begin
          Eng.IncRow(iAhora - iUltProg);
          iUltProg := iAhora;
        end;
        if (iAhora div 250) > (iUltLog div 250) then
        begin
          Eng.Log('  fotos: %d procesadas (%d generadas, %d saltadas, ' +
                  '%d errores)',
                  [iAhora, oImp.Generadas,
                   Stats.Saltadas + oImp.Saltadas, oImp.Errores]);
          iUltLog := iAhora;
        end;
        if bVivos then
          Sleep(200);
      until not bVivos;
      oImp.DrenarHacia(bulk);
      Inc(Stats.Insertadas, oImp.Generadas);
      Inc(Stats.Saltadas,   oImp.Saltadas);
      Inc(Stats.Errores,    oImp.Errores);
    end;
    bulk.FlushPendiente;
  finally
    // Si salimos por excepcion con el pool vivo, pararlo y esperar a
    // los hilos antes de liberar el estado compartido.
    if oImp <> nil then
      oImp.Parar;
    for i := 0 to High(aHilos) do
      if aHilos[i] <> nil then
      begin
        aHilos[i].WaitFor;
        aHilos[i].Free;
      end;
    FreeAndNil(oImp);
    bulk.Free;
    qSrc.Free;
    oNombresReal.Free;
    oNombres600.Free;
    oNombres300.Free;
    oPorFichero.Free;
    oGrupos.Free;
    oReutilizadas.Free;
    oExistentes.Free;
  end;
end;

end.
