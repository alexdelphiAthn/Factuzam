{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigFotos                                                 }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
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
{    Así el resolutor del exe principal (inLibFotos.Resolver) encuentra la     }
{    foto por prefijo para cualquier talla de ese color, igual que las         }
{    fotos por color que llegan del servidor de fotos_nube.                    }
{                                                                              }
{    Idempotente: si la pareja (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT) ya          }
{    existe en destino se salta sin tocar ficheros. Las filas cuyo             }
{    fichero origen no existe se contabilizan como saltadas con aviso.         }
{******************************************************************************}
unit inLibMigFotos;

interface

uses
  UMigEngine;

procedure MigrarFotos(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  Winapi.Windows, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  System.SysUtils, System.Classes, System.IOUtils,
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

// =========================================================================
//  Helpers de imagen (versión standalone de los de inLibFotos, aptos
//  para correr en los hilos de trabajo del migrador: los canvas VCL se
//  bloquean con Canvas.Lock fuera del hilo principal)
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

// Guarda el grafico en su resolucion original como PNG (la copia
// "real" del trio). Para PNG de origen es directo; para el resto se
// pasa por TBitmap pf32bit.
procedure GuardarComoPng(const AOriginal: TGraphic;
                         const ARutaPng: string);
var
  oBitmap: TBitmap;
  oPng:    TPngImage;
begin
  if (AOriginal = nil) or
     (AOriginal.Width = 0) or (AOriginal.Height = 0) then
    raise Exception.Create('Imagen vacia o no valida.');
  if AOriginal is TPngImage then
    TPngImage(AOriginal).SaveToFile(ARutaPng)
  else
  begin
    oBitmap := TBitmap.Create;
    try
      VolcarEnBitmap(AOriginal, oBitmap);
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
end;

// Redimensiona manteniendo proporciones (lado mayor = ALadoMayor) y
// guarda como PNG. El reescalado lo hace GDI+ con interpolacion
// bicubica de alta calidad, igual que inLibFotos.
procedure GuardarRedimensionado(const AOriginal: TGraphic;
                                const ARutaPng: string;
                                ALadoMayor: Integer);
var
  iAncho, iAlto: Integer;
  dEscala:       Double;
  oSrc, oDst:    TBitmap;
  oPng:          TPngImage;
  gpSrc:         TGPBitmap;
  gpGfx:         TGPGraphics;
begin
  if (AOriginal = nil) or
     (AOriginal.Width = 0) or (AOriginal.Height = 0) then
    raise Exception.Create('Imagen vacia o no valida.');
  if AOriginal.Width >= AOriginal.Height then
  begin
    dEscala := ALadoMayor / AOriginal.Width;
    iAncho  := ALadoMayor;
    iAlto   := Round(AOriginal.Height * dEscala);
  end
  else
  begin
    dEscala := ALadoMayor / AOriginal.Height;
    iAlto   := ALadoMayor;
    iAncho  := Round(AOriginal.Width * dEscala);
  end;
  if iAncho < 1 then
    iAncho := 1;
  if iAlto < 1 then
    iAlto := 1;
  oSrc := TBitmap.Create;
  oDst := TBitmap.Create;
  try
    VolcarEnBitmap(AOriginal, oSrc);
    oDst.PixelFormat := pf32bit;
    oDst.SetSize(iAncho, iAlto);
    oDst.Canvas.Lock;
    try
      gpSrc := TGPBitmap.Create(oSrc.Handle, 0);
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
      oPng := TPngImage.Create;
      try
        oPng.Assign(oDst);
        oPng.SaveToFile(ARutaPng);
      finally
        FreeAndNil(oPng);
      end;
    finally
      oDst.Canvas.Unlock;
    end;
  finally
    FreeAndNil(oDst);
    FreeAndNil(oSrc);
  end;
end;

// Genera el trio completo (real + 300 + 600) desde el fichero origen.
procedure GenerarTrioPng(const AFicheroOrigen, ARuta300, ARuta600,
                         ARutaReal: string);
var
  oGraphic: TGraphic;
begin
  oGraphic := CargarGrafico(AFicheroOrigen);
  try
    GuardarComoPng(oGraphic, ARutaReal);
    GuardarRedimensionado(oGraphic, ARuta300, cLado300);
    GuardarRedimensionado(oGraphic, ARuta600, cLado600);
  finally
    FreeAndNil(oGraphic);
  end;
end;

// Copia el trio ya generado de otra fila con el MISMO fichero origen
// (varios colores comparten foto en el legacy). Evita re-decodificar
// y re-encodificar la imagen, que es lo caro.
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

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarFotos(Eng: TMigEngine; var Stats: TMigStats);
const
  // ColorSlot identico al de inLibMigArticulosSkus: codigo legacy del
  // color si viene relleno; descripcion del basico (occolor) si es
  // significativa; '0' en ultimo caso. Asi CODIGO_UNIDAD_FOT casa como
  // prefijo exacto del CODIGO_UNIDAD_SKU migrado (ART/COLOR/TALLA).
  // ORDER BY ArchivoFoto: las filas que comparten fichero quedan
  // consecutivas y el trio PNG se copia en vez de regenerarse.
  cSelectSrc =
    'SELECT col.Articulo, col.Color, col.ArchivoFoto, ' +
    '       CASE ' +
    '         WHEN col.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(col.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(col.Color))) ' +
    '         WHEN c.Descripcion IS NOT NULL ' +
    '           AND UPPER(LTRIM(RTRIM(c.Descripcion))) <> ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(c.Descripcion))) ' +
    '         ELSE ''0'' ' +
    '       END AS ColorSlot ' +
    'FROM dbo.ocartcol col ' +
    'LEFT JOIN dbo.occolor c ON c.ColorBasico = col.ColorBasico ' +
    'WHERE col.Articulo IS NOT NULL ' +
    '  AND LTRIM(RTRIM(col.Articulo)) <> '''' ' +
    '  AND col.ArchivoFoto IS NOT NULL ' +
    '  AND LTRIM(RTRIM(col.ArchivoFoto)) <> '''' ' +
    'ORDER BY col.ArchivoFoto, col.Articulo, col.Color';
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
  qSrc:           TUniQuery;
  bulk:           TBulkInsert;
  oExistentes:    TDictionary<string, Boolean>;
  qDst:           TUniQuery;
  sRaiz:          string;
  sDestino:       string;
  sDir300:        string;
  sDir600:        string;
  sDirReal:       string;
  sArt:           string;
  sColorSlot:     string;
  sRel:           string;
  sCodUnidad:     string;
  sKey:           string;
  sFichero:       string;
  sNombre:        string;
  sExt:           string;
  sUltimoFichero: string;
  sUltimoNombre:  string;
  sAhora, sUser:  string;
begin
  // ---- Validacion de carpetas ------------------------------------------
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
  Eng.Log('  raiz legacy: %s', [sRaiz]);
  Eng.Log('  destino fotos: %s', [sDestino]);

  oExistentes := TDictionary<string, Boolean>.Create;
  qSrc := nil;
  bulk := nil;
  try
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
    sUltimoFichero := '';
    sUltimoNombre  := '';

    qSrc := NuevoQOrigen(Eng, cSelectSrc);
    bulk := TBulkInsert.Create(Eng.ConDst, 'fza_articulos_fotos',
                               cColsFotos, 500);
    Eng.SetTotal(Eng.ContarOrigen(cSelectCount));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      // El trabajo por fila es pesado (decodificar + 3 PNG): chequeamos
      // la cancelacion en cada iteracion.
      if Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en fotos, saliendo...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sColorSlot := Trim(qSrc.FieldByName('ColorSlot').AsString);
      sRel       := Trim(qSrc.FieldByName('ArchivoFoto').AsString);
      if sColorSlot = '' then
        sColorSlot := '0';
      sCodUnidad := sArt + '/' + sColorSlot;
      sKey       := sArt + '|' + sCodUnidad;
      sFichero   := ComponerRutaOrigen(sRaiz, sRel);
      if oExistentes.ContainsKey(sKey) then
        // Ya importada en una corrida previa: ni ficheros ni fila.
        Inc(Stats.Saltadas)
      else if not FileExists(sFichero) then
      begin
        Inc(Stats.Saltadas);
        Eng.LogSalto('Fotos', sCodUnidad, 'fichero no encontrado',
                     sFichero);
      end
      else
      begin
        try
          // Nombre estilo inLibFotos: clave saneada + indice _001.
          sNombre := SanearNombreFichero(sCodUnidad) + '_001';
          if SameText(sFichero, sUltimoFichero) and
             (sUltimoNombre <> '') then
            // Mismo fichero que la fila anterior: copiar el trio.
            CopiarTrioPng(sDir300, sDir600, sDirReal,
                          sUltimoNombre, sNombre)
          else
          begin
            GenerarTrioPng(sFichero,
                           sDir300  + sNombre + '.png',
                           sDir600  + sNombre + '.png',
                           sDirReal + sNombre + '.png');
            sUltimoFichero := sFichero;
            sUltimoNombre  := sNombre;
          end;
          // Extension de origen solo por trazabilidad (todo acaba PNG).
          sExt := LowerCase(ExtractFileExt(sFichero));
          if sExt <> '' then
            sExt := Copy(sExt, 2, MaxInt);
          if sExt = '' then
            sExt := 'png';
          bulk.Add(Format('%s, %s, %s, %s, %s, %s, %s, %s',
            [ValorOrNull(sArt), ValorOrNull(sCodUnidad),
             ValorOrNull(sNombre), ValorOrNull(sExt),
             sAhora, sAhora, sUser, sUser]));
          oExistentes.AddOrSetValue(sKey, True);
          Inc(Stats.Insertadas);
        except
          on E: Exception do
          begin
            // Imagen corrupta / formato sin codec / disco lleno: se
            // anota y se sigue con la siguiente foto.
            Inc(Stats.Errores);
            sUltimoFichero := '';
            sUltimoNombre  := '';
            Eng.LogError('Fotos', sCodUnidad, E.Message, sFichero);
          end;
        end;
      end;
      // El IncRow del engine solo refresca cada 2000 filas; con fotos
      // (lentas) dejamos rastro periodico en el log.
      if Stats.Leidas mod 250 = 0 then
        Eng.Log('  fotos: %d procesadas (%d generadas, %d saltadas, ' +
                '%d errores)',
                [Stats.Leidas, Stats.Insertadas, Stats.Saltadas,
                 Stats.Errores]);
      qSrc.Next;
    end;
    bulk.FlushPendiente;
  finally
    bulk.Free;
    qSrc.Free;
    oExistentes.Free;
  end;
end;

end.
