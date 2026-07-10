{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigInventarios                                           }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Genera un INVENTARIO INICIAL en destino a partir del stock historico      }
{    almacenado en `dbo.ocartacp` (SQL Server, una fila por                    }
{    Articulo+Color+Talla+Empresa+Almacen).                                    }
{                                                                              }
{    Estrategia:                                                               }
{      - Por cada combinacion (Empresa, Almacen) en ocartacp se crea UN        }
{        documento de inventario en `fza_inventarios` con SERIE='IN' y        }
{        NUMERO secuencial.                                                    }
{      - Por cada fila de stock no-cero se inserta una linea en               }
{        `fza_inventarios_lineas`:                                             }
{          CANTIDAD_TEORICA = 0       (no habia stock en el destino)          }
{          CANTIDAD_FISICA  = UnidadesStock origen                            }
{          CANTIDAD_DIFERENCIA = UnidadesStock                                 }
{          PRECIO_MEDIO_INVLIN = PrecioMedio origen                           }
{                                                                             }
{    Al estar el inventario en ESTADO='APLICADO' (lo dejamos directamente     }
{    aplicado), generamos los movimientos de regularizacion 'IN'.        }
{                                                                             }
{    Solo se incluyen filas con UnidadesStock <> 0. Si el usuario quiere      }
{    mantener las filas con stock 0 (utiles para forzar la creacion del      }
{    SKU como vimos en ocartbap) puede cambiar el WHERE del SELECT.          }
{                                                                             }
{    Resolucion de codigos:                                                   }
{      CODIGO_EMP_INVLIN = origen.Empresa (entero como texto)                 }
{      CODIGO_ALM_INVLIN = "E<Empresa>-A<Almacen>" (igual que                 }
{                          inLibMigAlmacenes)                                  }
{      CODIGO_UNIDAD_INVLIN = ARTICULO[/COLOR[/TALLA]] (igual que             }
{                              inLibMigArticulosSkus)                          }
{      CODIGO_ART_INVLIN    = el articulo                                     }
{                                                                             }
{    Idempotente: si ya existe la cabecera (mismo EMP+ALM+SERIE+NUMERO)       }
{    se salta entera (no se vuelve a procesar el almacen).                    }
{******************************************************************************}
unit inLibMigInventarios;

interface

uses
  UMigEngine;

procedure MigrarInventarios(Eng: TMigEngine; var Stats: TMigStats);
// Migra los inventarios/recuentos REALES del legacy (dbo.ocinv + ocinvarp)
// como documentos en fza_inventarios + lineas. Sus movimientos de
// regularizacion NO se generan aqui: ya estan en ocmovarp y los trae el
// dominio 'movimientos', enlazados por Serie + Numero. Complementario, no
// alternativo, al inventario inicial sintetico de arriba.
procedure MigrarInventariosLegacy(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni,
  inLibMigMovimientos;

// =========================================================================
//  Helpers locales
// =========================================================================

// '0' y '00' son colores REALES en el legacy (no placeholders).
function EsColorVacio(const s: string): Boolean;
begin
  Result := Trim(s) = '';
end;

function EsTallaVacia(const s: string): Boolean;
var u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'UNI');
end;

// MISMO patron que inLibMigArticulosSkus: siempre ART/COL/TAL con
// placeholders (0 para color, UNI para talla) cuando vienen vacios.
function ConstruirCodigoUnidad(const sArt, sColor, sTalla: string): string;
var sC, sT: string;
begin
  sC := UpperCase(Trim(sColor));
  if EsColorVacio(sC) then sC := '0';
  sT := UpperCase(Trim(sTalla));
  if EsTallaVacia(sT) then sT := 'UNI';
  Result := sArt + '/' + sC + '/' + sT;
end;

// Inserta una cabecera de inventario si no existe ya. Devuelve True si
// la insertó.
function InsertarCabecera(Eng: TMigEngine; const sEmp, sAlm,
                          sSerie, sNumero: string;
                          fTotalDif: Double): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_inventarios ' +
      'WHERE CODIGO_EMP_INV = :e AND CODIGO_ALM_INV = :a ' +
      '  AND SERIE_INV = :s AND NUMERO_INV = :n';
    qChk.ParamByName('e').AsString := sEmp;
    qChk.ParamByName('a').AsString := sAlm;
    qChk.ParamByName('s').AsString := sSerie;
    qChk.ParamByName('n').AsString := sNumero;
    qChk.Open;
    if not qChk.IsEmpty then Exit(False);
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_inventarios (' +
        'CODIGO_EMP_INV, CODIGO_ALM_INV, SERIE_INV, NUMERO_INV, ' +
        'TIPO_DOC_INV, FECHA_INV, ESTADO_INV, ' +
        'DESCRIPCION_INV, ' +
        'TOTAL_UNIDADES_DIFERENCIA_INV, TOTAL_EUROS_DIFERENCIA_INV, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:e, :a, :s, :n, ''IN'', :f, ''APLICADO'', ' +
              ':d, :td, 0, ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    qIns.ParamByName('e').AsString    := sEmp;
    qIns.ParamByName('a').AsString    := sAlm;
    qIns.ParamByName('s').AsString    := sSerie;
    qIns.ParamByName('n').AsString    := sNumero;
    qIns.ParamByName('f').AsDateTime  := Now;
    qIns.ParamByName('d').AsString    := Format(
      'Inventario inicial migrado desde ocartacp (%s/%s)', [sEmp, sAlm]);
    qIns.ParamByName('td').AsFloat    := fTotalDif;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
    Result := True;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

procedure InsertarLinea(Eng: TMigEngine; const sEmp, sAlm, sSerie,
                        sNumero, sLinea, sCodArt, sCodUnidad,
                        sDesc: string;
                        fCantidad, fPrecioMedio: Double);
var qIns: TUniQuery;
begin
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_inventarios_lineas (' +
        'CODIGO_EMP_INVLIN, CODIGO_ALM_INVLIN, SERIE_INV_INVLIN, ' +
        'NUMERO_INV_INVLIN, LINEA_INVLIN, ' +
        'CODIGO_ART_INVLIN, CODIGO_UNIDAD_INVLIN, ' +
        'DESCRIPCION_ARTICULO_INVLIN, ' +
        'CANTIDAD_TEORICA_INVLIN, CANTIDAD_FISICA_INVLIN, ' +
        'CANTIDAD_DIFERENCIA_INVLIN, PRECIO_MEDIO_INVLIN, ' +
        'PRECIO_MEDIO_NUEVO_INVLIN, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:e, :a, :s, :n, :l, :ca, :u, :d, ' +
              '0, :c, :c, :pm, :pm, ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    qIns.ParamByName('e').AsString  := sEmp;
    qIns.ParamByName('a').AsString  := sAlm;
    qIns.ParamByName('s').AsString  := sSerie;
    qIns.ParamByName('n').AsString  := sNumero;
    qIns.ParamByName('l').AsString  := sLinea;
    qIns.ParamByName('ca').AsString := sCodArt;
    qIns.ParamByName('u').AsString  := sCodUnidad;
    qIns.ParamByName('d').AsString  := sDesc;
    qIns.ParamByName('c').AsFloat   := fCantidad;
    qIns.ParamByName('pm').AsFloat  := fPrecioMedio;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
  finally
    qIns.Free;
  end;
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarInventarios(Eng: TMigEngine; var Stats: TMigStats);
const
  // Resolvemos el codigo interno de color via ocartcol. Filtramos las
  // filas con stock 0 para mantener el inventario reducido; los SKUs con
  // stock 0 ya los cubre el dominio de SKUs desde ocartacp.
  cSelectSrc =
    'SELECT acp.Empresa, acp.Almacen, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbreviaturaAlm, ' +
    '       acp.Articulo, acp.Color, acp.Talla, ' +
    '       acp.UnidadesStock, ' +
    '       ISNULL(acp.PrecioMedio, 0) AS PrecioMedio, ' +
    // Mismo criterio que SKUs: codigo interno de ocartcol.Color.
    '       CASE ' +
    '         WHEN ac.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '         WHEN acp.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(acp.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(acp.Color))) ' +
    '         ELSE ''0'' ' +
    '       END AS DescColor, ' +
    '       ISNULL(art.DescripcionLarga, ' +
    '              ISNULL(art.DescripcionCorta, '''')) AS DescArt ' +
    'FROM dbo.ocartacp acp ' +
    'LEFT JOIN dbo.ocalm    alm ON alm.Empresa  = acp.Empresa ' +
    '                          AND alm.Almacen  = acp.Almacen ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = acp.Articulo ' +
    '                         AND ac.Color    = acp.Color ' +
    'LEFT JOIN dbo.occolor  c  ON c.ColorBasico = ac.ColorBasico ' +
    'LEFT JOIN dbo.ocartp   art ON art.Articulo = acp.Articulo ' +
    'WHERE acp.UnidadesStock IS NOT NULL ' +
    '  AND acp.UnidadesStock <> 0 ' +
    '  AND LTRIM(RTRIM(acp.Articulo)) <> '''' ' +
    'ORDER BY acp.Empresa, acp.Almacen, acp.Articulo, ' +
    '         acp.Color, acp.Talla';
  // Columnas de fza_movimientos_almacen para el bulk de regularizacion.
  // Mismo juego (26 columnas) que usa inLibMigMovimientos, asi stockactual
  // se reconstruye con identico criterio.
  cColsMov =
    'NUMERO_MOV, TIPO_DOC_MOV, SERIE_DOC_MOV, NUMERO_DOC_MOV, LINEA_MOV, ' +
    'CODIGO_EMP_MOV, CODIGO_ALM_MOV, FECHA_MOV, CODIGO_ART_MOV, ' +
    'CODIGO_UNIDAD_MOV, DESCRIPCION_ARTICULO_MOV, TIPO_MOV, CANTIDAD_MOV, ' +
    'PRECIO_COSTE_UNITARIO_MOV, TOTAL_COSTE_MOV, PRECIO_MEDIO_MOV, ' +
    'CODIGO_ALM_CONTRA_MOV, CODIGO_CLI_MOV, ESACTIVO_MOV, ' +
    'CODIGO_ALM_DOC_MOV, CODIGO_CAJA_DOC_MOV, NUMERO_OPERACION_DOC_MOV, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF';
  BATCH_MOV = 5000;
var
  qSrc:                 TUniQuery;
  iEmp, iAlm:           Integer;
  iEmpAnt, iAlmAnt:     Integer;
  iLinea:               Integer;
  sEmp, sAlm:           string;
  sArt, sDescColor:     string;
  sCodUnidad:           string;
  sDesc:                string;
  sNumero:              string;
  fCantidad, fPrecio:   Double;
  fAcumDif, fImporte:   Double;
  bCabecera:            Boolean;
  bulkMov:              TBulkInsert;
  fs:                   TFormatSettings;
  sLineaPad:            string;
  sNumeroMov, sFilaMov: string;
  sAhora, sUser:        string;
begin
  fs     := TFormatSettings.Create('en-US');
  sAhora := DateTimeASQL(Now);
  sUser  := ValorOrNull(Eng.Usuario);
  // Re-ejecutable: borramos SOLO el inventario sintetico de ESTE usuario
  // (NUMERO_INV 'MIG%', exclusivo de este dominio — no toca los inventarios
  // legacy de ocinv ni las regularizaciones de la app) y sus movimientos
  // 'IV-MIG%', para recrearlos limpios y no duplicar stock en cada pasada.
  EjecutarSQL(Eng, 'DELETE FROM fza_inventarios_lineas WHERE USUARIO_ALTA = '
    + sUser + ' AND NUMERO_INV_INVLIN LIKE ''MIG%''');
  EjecutarSQL(Eng, 'DELETE FROM fza_inventarios WHERE USUARIO_ALTA = ' +
    sUser + ' AND NUMERO_INV LIKE ''MIG%''');
  EjecutarSQL(Eng, 'DELETE FROM fza_movimientos_almacen ' +
    'WHERE NUMERO_MOV LIKE ''IV-MIG%''');
  qSrc    := NuevoQOrigen(Eng, cSelectSrc);
  bulkMov := TBulkInsert.Create(Eng.ConDst, 'fza_movimientos_almacen',
                                cColsMov, BATCH_MOV);
  try
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartacp ' +
      'WHERE UnidadesStock IS NOT NULL AND UnidadesStock <> 0 ' +
      '  AND LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    iEmpAnt    := -1;
    iAlmAnt    := -1;
    iLinea     := 0;
    fAcumDif   := 0;
    sNumero    := '';
    bCabecera  := False;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      iEmp       := qSrc.FieldByName('Empresa').AsInteger;
      iAlm       := qSrc.FieldByName('Almacen').AsInteger;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sDescColor := Trim(qSrc.FieldByName('DescColor').AsString);
      fCantidad  := qSrc.FieldByName('UnidadesStock').AsFloat;
      fPrecio    := qSrc.FieldByName('PrecioMedio').AsFloat;
      sDesc      := Trim(qSrc.FieldByName('DescArt').AsString);

      // Detectamos cambio de (Empresa, Almacen) → cabecera nueva
      if (iEmp <> iEmpAnt) or (iAlm <> iAlmAnt) then
      begin
        iEmpAnt   := iEmp;
        iAlmAnt   := iAlm;
        iLinea    := 0;
        fAcumDif  := 0;
        sNumero   := Format('MIG%.4d', [iAlm]);
        sEmp      := IntToStr(iEmp);
        // CODIGO_ALM_INVLIN: misma convencion que inLibMigAlmacenes
        // (Abreviatura del legacy en mayusculas), con fallback al
        // numero. Asi las lineas referencian el almacen migrado
        // correctamente.
        sAlm := UpperCase(Trim(
                  qSrc.FieldByName('AbreviaturaAlm').AsString));
        if sAlm = '' then sAlm := IntToStr(iAlm);
        bCabecera := InsertarCabecera(Eng, sEmp, sAlm, 'IN', sNumero,
                                       0);
        // Si la cabecera ya existia, saltamos todo el bloque del
        // almacen (el inventario ya estaba creado en una corrida
        // previa).
        if not bCabecera then
        begin
          Eng.LogSalto('inventario', sEmp + '/' + sAlm,
            'cabecera ya existe, se omite todo el almacen',
            '', sNumero);
        end;
      end;

      if not bCabecera then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;

      Inc(iLinea);
      sCodUnidad := ConstruirCodigoUnidad(sArt, UpperCase(sDescColor),
        UpperCase(Trim(qSrc.FieldByName('Talla').AsString)));
      // LINEA_INVLIN tras widen_linea_invlin.sql es varchar(8). Padding a 8
      // digitos para que el orden lexicografico coincida con el numerico
      // (linea 9 < linea 10 < linea 100).
      sLineaPad := Format('%.8d', [iLinea]);
      try
        InsertarLinea(Eng, sEmp, sAlm, 'IN', sNumero, sLineaPad,
                      sArt, sCodUnidad, sDesc, fCantidad, fPrecio);
        Inc(Stats.Insertadas);
        fAcumDif := fAcumDif + fCantidad;
        // Movimiento de regularizacion (entrada) que CUADRA el stock: la
        // misma fila que generaria PRC_FZA_INVENTARIOS_APLICAR al regularizar
        // en la app (TIPO_DOC='IN', TIPO_MOV='E'). En migracion la teorica es
        // 0, por eso solo hay entrada. NUMERO_MOV 'IV-MIG....-NNNNNNNNE' (<=20)
        // identifica el origen migrador y lo separa de las regularizaciones
        // que haga luego la app. ESACTIVO_MOV literal 'S'.
        sNumeroMov := 'IV-' + sNumero + '-' + sLineaPad + 'E';
        fImporte   := fCantidad * fPrecio;
        sFilaMov := Format(
          '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, ' +
          '%s, %s, %s, %s, NULL, NULL, ''S'', %s, NULL, NULL, ' +
          '%s, %s, %s, %s',
          [ValorOrNull(sNumeroMov), ValorOrNull('IN'),
           ValorOrNull('IN'), ValorOrNull(sNumero),
           ValorOrNull(sLineaPad), ValorOrNull(sEmp),
           ValorOrNull(sAlm), sAhora, ValorOrNull(sArt),
           ValorOrNull(sCodUnidad), ValorOrNull(sDesc),
           ValorOrNull('E'), FloatToStr(fCantidad, fs),
           FloatToStr(fPrecio, fs), FloatToStr(fImporte, fs),
           FloatToStr(fPrecio, fs), ValorOrNull(sAlm),
           sAhora, sAhora, sUser, sUser]);
        bulkMov.Add(sFilaMov);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('inventario_linea', sCodUnidad, E.Message,
            Format('emp=%s alm=%s linea=%.8d cantidad=%g',
                   [sEmp, sAlm, iLinea, fCantidad]),
            'la linea requiere que el almacen y el SKU ya esten ' +
            'migrados — corre antes Almacenes y SKUs');
        end;
      end;
      qSrc.Next;
    end;
    bulkMov.FlushPendiente;
    // Stock activo: lo reconstruimos desde los movimientos (incluidas las
    // regularizaciones 'IV' recien creadas), igual que hace 'movimientos'.
    // OJO: inventarios y movimientos son ALTERNATIVOS — si corres ambos el
    // stock se duplica (cada uno reconstruye desde TODO el historico activo).
    if not Eng.IsCancelado then
      ReconstruirStockDesdeMovimientos(Eng);
  finally
    bulkMov.Free;
    qSrc.Free;
  end;
end;

// =========================================================================
//  Inventarios LEGACY (recuentos reales: dbo.ocinv + dbo.ocinvarp)
// =========================================================================
// A diferencia del inventario inicial sintetico (ocartacp), aqui migramos
// los inventarios que REALMENTE existieron en el legacy. Solo el DOCUMENTO
// (cabecera + lineas): los movimientos de regularizacion ya viven en
// ocmovarp y los trae 'movimientos', enlazados por Serie + Numero.

// Inserta la cabecera del inventario legacy si no existe. Devuelve True si
// la inserto (False = ya existia, se omite el inventario entero).
function InsertarCabeceraLegacy(Eng: TMigEngine; const sEmp, sAlm, sSerie,
                                sNumero, sDesc: string;
                                dFecha: TDateTime): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_inventarios ' +
      'WHERE CODIGO_EMP_INV = :e AND CODIGO_ALM_INV = :a ' +
      '  AND SERIE_INV = :s AND NUMERO_INV = :n';
    qChk.ParamByName('e').AsString := sEmp;
    qChk.ParamByName('a').AsString := sAlm;
    qChk.ParamByName('s').AsString := sSerie;
    qChk.ParamByName('n').AsString := sNumero;
    qChk.Open;
    Result := qChk.IsEmpty;
    qChk.Close;
    if Result then
    begin
      qIns.Connection := Eng.ConDst;
      qIns.SQL.Text   :=
        'INSERT INTO fza_inventarios (' +
          'CODIGO_EMP_INV, CODIGO_ALM_INV, SERIE_INV, NUMERO_INV, ' +
          'TIPO_DOC_INV, FECHA_INV, ESTADO_INV, DESCRIPCION_INV, ' +
          'TOTAL_UNIDADES_DIFERENCIA_INV, TOTAL_EUROS_DIFERENCIA_INV, ' +
          'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:e, :a, :s, :n, ''IN'', :f, ''APLICADO'', :d, 0, 0, ' +
                ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
                ':USUARIO_MODIF)';
      qIns.ParamByName('e').AsString   := sEmp;
      qIns.ParamByName('a').AsString   := sAlm;
      qIns.ParamByName('s').AsString   := sSerie;
      qIns.ParamByName('n').AsString   := sNumero;
      qIns.ParamByName('f').AsDateTime := dFecha;
      qIns.ParamByName('d').AsString   := sDesc;
      RellenarAuditoria(qIns, Eng.Usuario);
      qIns.ExecSQL;
    end;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

procedure InsertarLineaLegacy(Eng: TMigEngine; const sEmp, sAlm, sSerie,
                              sNumero, sLinea, sCodArt, sCodUnidad,
                              sDesc: string;
                              fTeorica, fFisica, fDif, fPre,
                              fPreNue: Double);
var qIns: TUniQuery;
begin
  qIns := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_inventarios_lineas (' +
        'CODIGO_EMP_INVLIN, CODIGO_ALM_INVLIN, SERIE_INV_INVLIN, ' +
        'NUMERO_INV_INVLIN, LINEA_INVLIN, ' +
        'CODIGO_ART_INVLIN, CODIGO_UNIDAD_INVLIN, ' +
        'DESCRIPCION_ARTICULO_INVLIN, ' +
        'CANTIDAD_TEORICA_INVLIN, CANTIDAD_FISICA_INVLIN, ' +
        'CANTIDAD_DIFERENCIA_INVLIN, PRECIO_MEDIO_INVLIN, ' +
        'PRECIO_MEDIO_NUEVO_INVLIN, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:e, :a, :s, :n, :l, :ca, :u, :d, ' +
              ':ct, :cf, :cd, :pm, :pn, ' +
              ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, ' +
              ':USUARIO_MODIF)';
    qIns.ParamByName('e').AsString  := sEmp;
    qIns.ParamByName('a').AsString  := sAlm;
    qIns.ParamByName('s').AsString  := sSerie;
    qIns.ParamByName('n').AsString  := sNumero;
    qIns.ParamByName('l').AsString  := sLinea;
    qIns.ParamByName('ca').AsString := sCodArt;
    qIns.ParamByName('u').AsString  := sCodUnidad;
    qIns.ParamByName('d').AsString  := sDesc;
    qIns.ParamByName('ct').AsFloat  := fTeorica;
    qIns.ParamByName('cf').AsFloat  := fFisica;
    qIns.ParamByName('cd').AsFloat  := fDif;
    qIns.ParamByName('pm').AsFloat  := fPre;
    qIns.ParamByName('pn').AsFloat  := fPreNue;
    RellenarAuditoria(qIns, Eng.Usuario);
    qIns.ExecSQL;
  finally
    qIns.Free;
  end;
end;

procedure MigrarInventariosLegacy(Eng: TMigEngine; var Stats: TMigStats);
const
  // Cabecera (ocinv) + lineas (ocinvarp). Unidades = stock teorico al
  // recuento; UnidadesNuevas = recuento fisico. Resolvemos el color con el
  // mismo criterio que el resto (literal del proveedor primero).
  cSel =
    'SELECT inv.Empresa, inv.Serie, inv.NroInventario, ' +
    '       ISNULL(arp.Almacen, inv.Almacen) AS Almacen, ' +
    '       inv.Fecha, ' +
    '       ISNULL(CAST(inv.Observaciones AS nvarchar(200)), '''') AS Obs, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbreviaturaAlm, ' +
    '       arp.Articulo, arp.Color, arp.Talla, ' +
    '       ISNULL(arp.Unidades, 0)        AS Unidades, ' +
    '       ISNULL(arp.UnidadesNuevas, 0)  AS UnidadesNuevas, ' +
    '       ISNULL(arp.Precio, 0)          AS Precio, ' +
    '       ISNULL(arp.PrecioNuevo, 0)     AS PrecioNuevo, ' +
    '       CASE ' +
    '         WHEN ac.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '         WHEN arp.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(arp.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(arp.Color))) ' +
    '         ELSE ''0'' ' +
    '       END AS DescColor, ' +
    '       ISNULL(art.DescripcionLarga, ' +
    '              ISNULL(art.DescripcionCorta, '''')) AS DescArt ' +
    'FROM dbo.ocinvarp arp ' +
    'JOIN dbo.ocinv inv ON inv.Empresa = arp.Empresa ' +
    '                  AND inv.Ejercicio = arp.Ejercicio ' +
    '                  AND inv.Serie = arp.Serie ' +
    '                  AND inv.NroInventario = arp.NroInventario ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = arp.Empresa ' +
    '                       AND alm.Almacen = ISNULL(arp.Almacen, ' +
    '                                                inv.Almacen) ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = arp.Articulo ' +
    '                         AND ac.Color = arp.Color ' +
    'LEFT JOIN dbo.occolor c ON c.ColorBasico = ac.ColorBasico ' +
    'LEFT JOIN dbo.ocartp art ON art.Articulo = arp.Articulo ' +
    'WHERE LTRIM(RTRIM(arp.Articulo)) <> '''' ' +
    'ORDER BY arp.Empresa, arp.Serie, arp.NroInventario, ' +
    '         arp.Articulo, arp.Color, arp.Talla';
var
  qSrc:                    TUniQuery;
  iEmp, iNro, iAlm:        Integer;
  iLinea:                  Integer;
  sEmp, sAlm, sSerie:      string;
  sNumero, sKey, sKeyAnt:  string;
  sArt, sDescColor:        string;
  sCodUnidad, sDesc, sObs: string;
  dFecha:                  TDateTime;
  fTeorica, fFisica:       Double;
  fDif, fPre, fPreNue:     Double;
  bCab:                    Boolean;
begin
  qSrc := NuevoQOrigen(Eng, cSel);
  try
    // El total debe contar las MISMAS filas que devuelve cSel: el INNER JOIN
    // a ocinv descarta lineas huerfanas (ocinvarp sin cabecera ocinv). Si
    // contaramos solo ocinvarp, el total saldria mayor que las filas reales
    // y la barra nunca llegaria al 100% (pareceria colgado al final).
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocinvarp arp ' +
      'JOIN dbo.ocinv inv ON inv.Empresa = arp.Empresa ' +
      '                  AND inv.Ejercicio = arp.Ejercicio ' +
      '                  AND inv.Serie = arp.Serie ' +
      '                  AND inv.NroInventario = arp.NroInventario ' +
      'WHERE LTRIM(RTRIM(arp.Articulo)) <> '''''));
    qSrc.Open;
    sKeyAnt := '';
    iLinea  := 0;
    bCab    := False;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      iEmp       := qSrc.FieldByName('Empresa').AsInteger;
      sSerie     := Trim(qSrc.FieldByName('Serie').AsString);
      iNro       := qSrc.FieldByName('NroInventario').AsInteger;
      iAlm       := qSrc.FieldByName('Almacen').AsInteger;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sDescColor := Trim(qSrc.FieldByName('DescColor').AsString);
      sDesc      := Trim(qSrc.FieldByName('DescArt').AsString);
      fTeorica   := qSrc.FieldByName('Unidades').AsFloat;
      fFisica    := qSrc.FieldByName('UnidadesNuevas').AsFloat;
      fPre       := qSrc.FieldByName('Precio').AsFloat;
      fPreNue    := qSrc.FieldByName('PrecioNuevo').AsFloat;
      fDif       := fFisica - fTeorica;
      sKey       := IntToStr(iEmp) + '|' + sSerie + '|' + IntToStr(iNro);
      // Cambio de inventario (Empresa+Serie+Nro) → cabecera nueva.
      if sKey <> sKeyAnt then
      begin
        sKeyAnt := sKey;
        iLinea  := 0;
        sEmp    := IntToStr(iEmp);
        sNumero := IntToStr(iNro);
        sAlm    := UpperCase(Trim(
                     qSrc.FieldByName('AbreviaturaAlm').AsString));
        if sAlm = '' then
          sAlm := IntToStr(iAlm);
        sObs := Trim(qSrc.FieldByName('Obs').AsString);
        if sObs = '' then
          sObs := Format('Inventario legacy %s/%d migrado', [sSerie, iNro]);
        if qSrc.FieldByName('Fecha').IsNull then
          dFecha := Now
        else
          dFecha := qSrc.FieldByName('Fecha').AsDateTime;
        bCab := InsertarCabeceraLegacy(Eng, sEmp, sAlm, sSerie, sNumero,
                                       sObs, dFecha);
        if not bCab then
          Eng.LogSalto('inventario_legacy',
            sEmp + '/' + sSerie + '/' + sNumero,
            'cabecera ya existe, se omite el inventario', '', sNumero);
      end;
      if bCab then
      begin
        Inc(iLinea);
        sCodUnidad := ConstruirCodigoUnidad(sArt, UpperCase(sDescColor),
          UpperCase(Trim(qSrc.FieldByName('Talla').AsString)));
        try
          InsertarLineaLegacy(Eng, sEmp, sAlm, sSerie, sNumero,
            Format('%.8d', [iLinea]), sArt, sCodUnidad, sDesc,
            fTeorica, fFisica, fDif, fPre, fPreNue);
          Inc(Stats.Insertadas);
        except
          on E: Exception do
          begin
            Inc(Stats.Errores);
            Eng.LogError('inventario_legacy_linea', sCodUnidad, E.Message,
              Format('emp=%s serie=%s nro=%s', [sEmp, sSerie, sNumero]),
              'la linea requiere que el almacen y el SKU ya esten ' +
              'migrados — corre antes Almacenes y SKUs');
          end;
        end;
      end
      else
        Inc(Stats.Saltadas);
      qSrc.Next;
    end;
  finally
    qSrc.Free;
  end;
end;

end.
