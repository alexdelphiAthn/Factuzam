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
  UMigEngine, UMigCatalogo;

procedure MigrarArticulosProveedores(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarArticulosProveedores(const Eng: IContextoMigracion;
                                      var Stats: TMigStats);
const
  // Enriquecemos con el ULTIMO precio de compra y su fecha. ANTES
  // usabamos OUTER APPLY con TOP 1 por articulo, pero eso obligaba a
  // SQL Server a re-ejecutar el subquery por cada fila de ocartp
  // (~52k veces). Bajo concurrencia de wave 2 esto hacia que
  // qSrc.Open tardara varios minutos y el log mostrara 0/52348
  // mientras tanto.
  //
  // Ahora precomputamos el TOP 1 con ROW_NUMBER() en un CTE: se
  // calcula UNA sola vez agrupando por (Articulo, Proveedor) y
  // luego LEFT JOIN con WHERE rn = 1. Mucho mas rapido y con
  // WITH (NOLOCK) evitamos contencion con otras waves.
  cSelectSrc =
    'WITH cte_uc AS ( ' +
    '  SELECT alp.Articulo, alb.Proveedor, alp.PrecioSIva, ' +
    '         alb.Fecha, ' +
    '         ROW_NUMBER() OVER ( ' +
    '           PARTITION BY alp.Articulo, alb.Proveedor ' +
    '           ORDER BY alb.Fecha DESC) AS rn ' +
    '  FROM dbo.ocalbproarp alp WITH (NOLOCK) ' +
    '  INNER JOIN dbo.ocalbpro alb WITH (NOLOCK) ' +
    '          ON alb.Empresa    = alp.Empresa ' +
    '         AND alb.Ejercicio  = alp.Ejercicio ' +
    '         AND alb.Serie      = alp.Serie ' +
    '         AND alb.NroAlbaran = alp.NroAlbaran ' +
    '  WHERE ISNULL(alp.PrecioSIva, 0) > 0 ' +
    ') ' +
    'SELECT a.Articulo, a.Proveedor, ISNULL(a.Modelo, '''') AS Modelo, ' +
    '       ISNULL(uc.PrecioSIva, 0) AS PrecioUltCompra, ' +
    '       uc.Fecha AS FechaCompra ' +
    'FROM dbo.ocartp a WITH (NOLOCK) ' +
    'LEFT JOIN cte_uc uc ON uc.Articulo  = a.Articulo ' +
    '                   AND uc.Proveedor = a.Proveedor ' +
    '                   AND uc.rn        = 1 ' +
    'WHERE a.Proveedor IS NOT NULL AND a.Proveedor > 0 ' +
    '  AND LTRIM(RTRIM(a.Articulo)) <> '''' ' +
    'ORDER BY a.Proveedor, a.Articulo';
  // SQL Server 2014 puede cortar el flujo TDS al materializar el ROW_NUMBER.
  // Se conserva el vinculo y la referencia; precio y fecha quedan a NULL.
  cSelectSrcCompat =
    'SELECT a.Articulo, a.Proveedor, ISNULL(a.Modelo, '''') AS Modelo, ' +
    '       CAST(NULL AS money) AS PrecioUltCompra, ' +
    '       CAST(NULL AS smalldatetime) AS FechaCompra ' +
    'FROM dbo.ocartp a WITH (NOLOCK) ' +
    'WHERE a.Proveedor IS NOT NULL AND a.Proveedor > 0 ' +
    '  AND LTRIM(RTRIM(a.Articulo)) <> '''' ' +
    'ORDER BY a.Articulo';
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
  if EsSqlServer2014OAnterior(Eng) then
  begin
    Eng.Registro.Log('  SQL Server 2014: consulta compatible sin ROW_NUMBER; ' +
            'precio/fecha de ultima compra quedaran vacios.');
    qSrc := NuevoQOrigen(Eng, cSelectSrcCompat);
  end
  else
    qSrc := NuevoQOrigen(Eng, cSelectSrc);
  bulk := TBulkInsert.Create(Eng.Datos.ConexionDestino, 'fza_articulos_proveedores',
                              cCols, 5000);
  try
    sAhora := DateTimeASQL(Now);
    sUser  := ValorOrNull(Eng.Usuario);
    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartp WITH (NOLOCK) ' +
      'WHERE Proveedor IS NOT NULL AND Proveedor > 0 ' +
      '  AND LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
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
          Eng.Registro.LogError('art_prv', sArt, E.Message,
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

initialization
  RegistrarMigracion(
    'articulos_proveedores',
    'Proveedor y modelo por artículo',
    'ocartp.Proveedor + Modelo → fza_articulos_proveedores',
    ['articulos', 'proveedores'],
    MigrarArticulosProveedores);

end.
