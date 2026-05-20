{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosProveedores                                  }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Vincula cada articulo con su proveedor principal del legacy y la         }
{    referencia que el proveedor usaba (Modelo en ocartp).                    }
{                                                                              }
{    Mapeo:                                                                    }
{      ocartp.Articulo   → fza_articulos_proveedores.CODIGO_ART_AP            }
{      ocartp.Proveedor  → fza_articulos_proveedores.CODIGO_PRV_AP            }
{      ocartp.Modelo     → fza_articulos_proveedores.REF_PROVEEDOR_AP         }
{      <constante>        → ESPROVEEDORPRINCIPAL_AP = 'S'                      }
{                                                                              }
{    Solo procesa articulos con Proveedor > 0. Si el proveedor no esta        }
{    migrado en fza_proveedores el INSERT no falla (no hay FK declarada);     }
{    el usuario tendra una fila huerfana que es facil de detectar luego.     }
{                                                                              }
{    Idempotente: PK (CODIGO_PRV_AP, CODIGO_ART_AP) + INSERT IGNORE en el     }
{    bulk insert.                                                              }
{******************************************************************************}
unit inLibMigArticulosProveedores;

interface

uses
  UMigEngine;

procedure MigrarArticulosProveedores(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarArticulosProveedores(Eng: TMigEngine;
                                      var Stats: TMigStats);
const
  // Enriquecemos con el ULTIMO precio de compra y su fecha:
  // joinear ocalbproarp (lineas albaran proveedor) con ocalbpro
  // (cabecera, que tiene Proveedor + Fecha), filtrar por proveedor
  // del articulo y quedarnos con la fila mas reciente. OUTER APPLY
  // permite hacer ese TOP 1 dependiente por cada articulo.
  cSelectSrc =
    'SELECT a.Articulo, a.Proveedor, ISNULL(a.Modelo, '''') AS Modelo, ' +
    '       ISNULL(uc.PrecioSIva, 0) AS PrecioUltCompra, ' +
    '       uc.FechaCompra ' +
    'FROM dbo.ocartp a ' +
    'OUTER APPLY (' +
    '  SELECT TOP 1 alp.PrecioSIva, alb.Fecha AS FechaCompra ' +
    '  FROM dbo.ocalbproarp alp ' +
    '  INNER JOIN dbo.ocalbpro alb ' +
    '          ON alb.Empresa    = alp.Empresa ' +
    '         AND alb.Ejercicio  = alp.Ejercicio ' +
    '         AND alb.Serie      = alp.Serie ' +
    '         AND alb.NroAlbaran = alp.NroAlbaran ' +
    '  WHERE alp.Articulo  = a.Articulo ' +
    '    AND alb.Proveedor = a.Proveedor ' +
    '    AND ISNULL(alp.PrecioSIva, 0) > 0 ' +
    '  ORDER BY alb.Fecha DESC ' +
    ') uc ' +
    'WHERE a.Proveedor IS NOT NULL AND a.Proveedor > 0 ' +
    '  AND LTRIM(RTRIM(a.Articulo)) <> '''' ' +
    'ORDER BY a.Proveedor, a.Articulo';
  cCols =
    'CODIGO_PRV_AP, CODIGO_ART_AP, REF_PROVEEDOR_AP, ' +
    'PRECIO_ULT_COMPRA_AP, FECHA_VALIDEZ_AP, ' +
    'ESPROVEEDORPRINCIPAL_AP, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
var
  qSrc:                       TUniQuery;
  bulk:                       TBulkInsert;
  sArt, sProv, sModelo:       string;
  sFila, sAhora, sUser, sRef: string;
  sPrecio, sFecha:            string;
  fPrecioCompra:              Double;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  bulk := TBulkInsert.Create(Eng.ConDst, 'fza_articulos_proveedores',
                              cCols, 5000);
  try
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartp ' +
      'WHERE Proveedor IS NOT NULL AND Proveedor > 0 ' +
      '  AND LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt    := Trim(qSrc.FieldByName('Articulo').AsString);
      sProv   := IntToStr(qSrc.FieldByName('Proveedor').AsInteger);
      sModelo := Trim(qSrc.FieldByName('Modelo').AsString);
      if (sArt = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;
      if sModelo = '' then
        sRef := 'NULL'
      else
        sRef := ValorOrNull(sModelo);

      // Precio ultima compra + fecha (puede ser NULL si nunca se
      // compro este articulo a este proveedor)
      fPrecioCompra :=
        qSrc.FieldByName('PrecioUltCompra').AsFloat;
      if fPrecioCompra > 0 then
        sPrecio := FloatToStr(fPrecioCompra,
                    TFormatSettings.Create('en-US'))
      else
        sPrecio := 'NULL';
      if qSrc.FieldByName('FechaCompra').IsNull then
        sFecha := 'NULL'
      else
        sFecha := DateTimeASQL(
          qSrc.FieldByName('FechaCompra').AsDateTime);

      // 10 columnas en cCols, una literal ('S' = ESPROVEEDORPRINCIPAL_AP),
      // 9 placeholders %s.
      sFila := Format('%s, %s, %s, %s, %s, ''S'', %s, %s, %s, %s',
        [ValorOrNull(sProv),   // CODIGO_PRV_AP
         ValorOrNull(sArt),    // CODIGO_ART_AP
         sRef,                 // REF_PROVEEDOR_AP
         sPrecio,              // PRECIO_ULT_COMPRA_AP
         sFecha,               // FECHA_VALIDEZ_AP
                               // 'S' -> ESPROVEEDORPRINCIPAL_AP
         sAhora, sAhora,       // INSTANTE_ALTA, INSTANTE_MODIF
         sUser, sUser]);       // USUARIO_ALTA, USUARIO_MODIF
      try
        bulk.Add(sFila);
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('art_prv', sArt, E.Message,
            Format('prv=%s modelo=%s', [sProv, sModelo]), '');
          raise;
        end;
      end;
      qSrc.Next;
    end;
    bulk.FlushPendiente;
  finally
    bulk.Free;
    qSrc.Free;
  end;
end;

end.
