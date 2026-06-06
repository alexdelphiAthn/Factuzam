{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigVentas                                                }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra las operaciones de CAJA / ventas del legacy (`dbo.occaj` cabecera   }
{    + `dbo.occajarp` líneas) a la capa de caja de Factuzam:                   }
{      occaj                         → fza_caja_operaciones (cabecera)         }
{      columnas de pago de occaj     → fza_caja_pagos (formas de pago)         }
{      operaciones AL                → fza_depositos_cliente + DE              }
{                                                                              }
{    Mapeo de tipo (occaj.TipoDoc/Tipo → TIPO_OPERACION_OPCAJA):               }
{      AL (Tipo='A')   → 'DE'  (depósito; además crea fza_depositos_cliente)   }
{      cobro (Tipo='C')→ 'CB'  (cobro a cuenta = adelanto)                     }
{      TR              → 'TR'  (traspaso; ESTRASPASO='S' + almacén contra)     }
{      AT              → 'AT'  (traspaso entre empresas)                       }
{      vale (Tipo='L') → 'VL'  (vale emitido)                                  }
{      resto (ventas)  → 'VE'                                                  }
{    Regla del usuario: "las operaciones AL se convierten en depósitos y los   }
{    CB contiguos en adelantos". El AL abre UN depósito POR LÍNEA de artículo  }
{    (multilínea); el DE se enlaza al primero. Los cobros (CB) REPARTEN su     }
{    importe (waterfall) entre los depósitos PENDIENTES del cliente —en orden  }
{    de creación, rellenando cada uno hasta su precio— acumulando en           }
{    IMPORTE_ANTICIPO_DEP y dejándolos CERRADO al alcanzar el precio.          }
{    Un CB SIN cliente hereda el del DOCUMENTO ADYACENTE (último documento     }
{    con cliente en la misma caja), que es como el legacy enlaza el cobro con  }
{    su albarán/cuenta. Si aún así no hay cliente, el CB queda suelto.         }
{                                                                              }
{    Formas de pago: el legacy guarda el desglose en COLUMNAS de occaj         }
{    (Efectivo, Tarjeta, ValeTienda, ValePromocion). Cada columna no nula      }
{    genera una línea en fza_caja_pagos con su CODIGO_FP_CFP:                  }
{      Efectivo      → 'EFE'                                                   }
{      Tarjeta       → 'TARJ'                                                  }
{      ValeTienda    → 'VALE'  (se asegura la forma de pago 'VALE')           }
{      ValePromocion → 'VALE'                                                  }
{                                                                              }
{    Resolución de códigos (igual que el resto de mappers):                    }
{      CODIGO_EMP    = occaj.Empresa (entero como texto)                       }
{      CODIGO_ALM    = Abreviatura del almacén (ocalm), fallback número        }
{      CODIGO_CAJA   = occaj.Caja                                              }
{      NUMERO_OP     = occaj.Operacion a 8 dígitos                             }
{      CODIGO_EMPLEADO = occaj.Vendedor                                        }
{      CODIGO_UNIDAD (depósito) = ARTICULO/COLOR/TALLA (patrón SKUs)           }
{                                                                              }
{    Idempotente: al arrancar borra lo que haya migrado este usuario en        }
{    fza_caja_pagos / fza_caja_operaciones / fza_depositos_cliente y vuelve    }
{    a insertarlo (no hay clave de negocio única: ID_OPCAJA es autonumérico). }
{                                                                              }
{    FUERA DE ALCANCE (fase 2): la reconstrucción de líneas de venta de        }
{    occajarp como fza_facturas / fza_facturas_lineas. El stock de esas        }
{    ventas ya entra por la migración de Movimientos (ocmovarp), así que       }
{    aquí solo se migra la capa de caja (operaciones + pagos + depósitos).     }
{******************************************************************************}
unit inLibMigVentas;

interface

uses
  UMigEngine;

procedure MigrarVentas(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

// =========================================================================
//  Helpers locales
// =========================================================================

function EsColorVacio(const s: string): Boolean;
begin
  Result := Trim(s) = '';
end;

function EsTallaVacia(const s: string): Boolean;
var
  u: string;
begin
  u := UpperCase(Trim(s));
  Result := (u = '') or (u = '0') or (u = 'UNI');
end;

// Mismo patrón ARTICULO/COLOR/TALLA que SKUs/Inventarios/Movimientos.
function ConstruirCodigoUnidad(const sArt, sColor, sTalla: string): string;
var
  sC, sT: string;
begin
  sC := UpperCase(Trim(sColor));
  if EsColorVacio(sC) then
    sC := '0';
  sT := UpperCase(Trim(sTalla));
  if EsTallaVacia(sT) then
    sT := 'UNI';
  Result := sArt + '/' + sC + '/' + sT;
end;

// occaj.TipoDoc/Tipo → TIPO_OPERACION_OPCAJA de Factuzam.
function MapearTipoOp(const sTipoDoc, sTipo: string): string;
var
  d, t: string;
begin
  d := UpperCase(Trim(sTipoDoc));
  t := UpperCase(Trim(sTipo));
  if d = 'AL' then
    Result := 'DE'
  else if t = 'C' then
    Result := 'CB'
  else if d = 'TR' then
    Result := 'TR'
  else if d = 'AT' then
    Result := 'AT'
  else if t = 'L' then
    Result := 'VL'
  else
    Result := 'VE';
end;

// Combina la fecha (FechaOpe/Fecha) con la hora 'HH:MM:SS' del legacy en un
// único TDateTime. Si la hora no es parseable, se queda la fecha a medianoche.
function ComponerInstante(const dtFecha: TDateTime;
                          const sHora: string): TDateTime;
var
  h, m, s: Integer;
  partes:  TArray<string>;
begin
  Result := dtFecha;
  partes := Trim(sHora).Split([':']);
  if Length(partes) >= 2 then
  begin
    h := StrToIntDef(partes[0], 0);
    m := StrToIntDef(partes[1], 0);
    if Length(partes) >= 3 then
      s := StrToIntDef(partes[2], 0)
    else
      s := 0;
    // Defensa ante horas legacy corruptas: si EncodeTime no acepta los
    // valores, nos quedamos con la fecha a medianoche.
    if (h >= 0) and (h <= 23) and (m >= 0) and (m <= 59)
    and (s >= 0) and (s <= 59) then
      Result := Trunc(dtFecha) + EncodeTime(h, m, s, 0);
  end;
end;

// Asegura que exista la forma de pago 'VALE' (vales de tienda migrados).
// Idempotente vía INSERT IGNORE.
procedure AsegurarFormaPagoVale(Eng: TMigEngine);
const
  cSql =
    'INSERT IGNORE INTO fza_caja_formas_pago ' +
    '  (CODIGO_FP_CFP, DESCRIPCION_FORMA_PAGO_CFP, ' +
    '   ESREQ_REFERENCIA_FORMA_PAGO_CFP, ESCRIPTO_FORMA_PAGO_CFP, ' +
    '   ESDIVISA_FORMA_PAGO_CFP, ESACTIVO_FORMA_PAGO_CFP, ' +
    '   ORDEN_VISUAL_FORMA_PAGO_CFP, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (''VALE'', ''Vale tienda (migrado)'', ''N'', ''N'', ''N'', ''S'', ' +
    '        90, NOW(), NOW(), :ua, :um)';
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text   := cSql;
    q.ParamByName('ua').AsString := Eng.Usuario;
    q.ParamByName('um').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

// Borra lo migrado por este usuario en las 3 tablas de caja para que la
// migración sea re-ejecutable (no hay clave de negocio única: ID_OPCAJA es
// autonumérico, así que no sirve INSERT IGNORE para idempotencia).
procedure LimpiarMigracionPrevia(Eng: TMigEngine);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text := 'DELETE FROM fza_caja_pagos WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
    q.SQL.Text := 'DELETE FROM fza_caja_operaciones WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
    q.SQL.Text := 'DELETE FROM fza_depositos_cliente WHERE USUARIO_ALTA = :u';
    q.ParamByName('u').AsString := Eng.Usuario;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

// Crea un depósito por CADA línea de artículo del albarán (AL): una prenda
// por línea (soporte multilínea). PENDIENTE con anticipo 0; los cobros lo van
// acumulando. Usa la misma resolución del slot de color que SKUs/Movimientos.
// Devuelve el ID del PRIMER depósito (para enlazarlo a la operación DE), o
// '' si la operación no tiene líneas de artículo aprovechables. El INSERT se
// hace sobre qDep (preparado por el llamante con cInsDep).
function CrearDepositosAlbaran(Eng: TMigEngine;
                               const iEmp, iAlm, iCaja, iOpe: Integer;
                               const sEmp, sAlm, sCli, sCaja, sNum: string;
                               const dtCrea: TDateTime;
                               qDep: TUniQuery): string;
const
  cLineas =
    'SELECT l.NroLinea, l.Articulo, l.Talla, ' +
    '       ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.Cantidad, 0) AS Cantidad, ' +
    '       CASE ' +
    '         WHEN co.Descripcion IS NULL ' +
    '           OR LTRIM(RTRIM(co.Descripcion)) = '''' ' +
    '           OR UPPER(LTRIM(RTRIM(co.Descripcion))) = ''INDEFINIDO'' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         ELSE UPPER(LTRIM(RTRIM(co.Descripcion))) ' +
    '       END AS DescColor ' +
    'FROM dbo.occajarp l ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color    = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico ' +
    'WHERE l.Empresa = :e AND l.Almacen = :a ' +
    '  AND l.Caja = :c AND l.Operacion = :o ' +
    '  AND LTRIM(RTRIM(l.Articulo)) <> '''' AND l.Articulo <> ''0'' ' +
    'ORDER BY l.NroLinea';
var
  qLin:      TUniQuery;
  sArt, sId: string;
begin
  Result := '';
  qLin := TUniQuery.Create(nil);
  try
    qLin.Connection := Eng.ConSrv;
    qLin.SQL.Text   := cLineas;
    qLin.ParamByName('e').AsInteger := iEmp;
    qLin.ParamByName('a').AsInteger := iAlm;
    qLin.ParamByName('c').AsInteger := iCaja;
    qLin.ParamByName('o').AsInteger := iOpe;
    qLin.Open;
    while not qLin.Eof do
    begin
      sArt := Trim(qLin.FieldByName('Articulo').AsString);
      sId  := Format('DM%d-%d-%d-%d',
                [iEmp, iCaja, iOpe, qLin.FieldByName('NroLinea').AsInteger]);
      qDep.ParamByName('id').AsString    := sId;
      qDep.ParamByName('emp').AsString   := sEmp;
      if sCli <> '' then
        qDep.ParamByName('cli').AsString := sCli
      else
        qDep.ParamByName('cli').AsString := '0';
      qDep.ParamByName('art').AsString   := sArt;
      qDep.ParamByName('uni').AsString   := ConstruirCodigoUnidad(sArt,
        Trim(qLin.FieldByName('DescColor').AsString),
        Trim(qLin.FieldByName('Talla').AsString));
      qDep.ParamByName('alm').AsString   := sAlm;
      qDep.ParamByName('precio').AsFloat := qLin.FieldByName('PrecioCIva').AsFloat;
      qDep.ParamByName('cant').AsFloat   := qLin.FieldByName('Cantidad').AsFloat;
      qDep.ParamByName('fcrea').AsDateTime := dtCrea;
      qDep.ParamByName('caja').AsString  := sCaja;
      qDep.ParamByName('num').AsString   := sNum;
      RellenarAuditoria(qDep, Eng.Usuario);
      qDep.ExecSQL;
      if Result = '' then
        Result := sId;
      qLin.Next;
    end;
  finally
    qLin.Free;
  end;
end;

// Acumula un cobro a cuenta en el anticipo del depósito y lo cierra si el
// anticipo alcanza el precio de venta. MySQL evalúa los SET de izquierda a
// derecha, así que el IF de ESTADO ya ve el IMPORTE_ANTICIPO_DEP actualizado.
procedure AcumularAnticipo(Eng: TMigEngine; const sIdDep: string;
                           const fImporte: Double);
const
  cUpd =
    'UPDATE fza_depositos_cliente ' +
    '   SET IMPORTE_ANTICIPO_DEP = IMPORTE_ANTICIPO_DEP + :amt, ' +
    '       ESTADO_DEP = IF(PRECIO_VENTA_DEP > 0 ' +
    '                       AND IMPORTE_ANTICIPO_DEP >= PRECIO_VENTA_DEP, ' +
    '                       ''CERRADO'', ESTADO_DEP), ' +
    '       INSTANTE_MODIF = NOW() ' +
    ' WHERE ID_DEPOSITO_DEP = :id';
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text   := cUpd;
    q.ParamByName('amt').AsFloat := fImporte;
    q.ParamByName('id').AsString := sIdDep;
    q.ExecSQL;
  finally
    q.Free;
  end;
end;

// Reparte un cobro a cuenta entre los depósitos PENDIENTES del cliente
// (waterfall: rellena cada uno hasta su precio, en orden de creación, y los
// cierra al llegar). Cubre el caso de AL multilínea (varios depósitos por
// operación). Devuelve el ID del PRIMER depósito tocado (para enlazar el CB).
// Primero leemos los depósitos a memoria y luego actualizamos, para no tener
// un cursor abierto mientras lanzamos los UPDATE sobre la misma conexión.
function AplicarCobroADepositos(Eng: TMigEngine; const sCli: string;
                                const fImporte: Double): string;
const
  cSel =
    'SELECT ID_DEPOSITO_DEP, ' +
    '       (PRECIO_VENTA_DEP - IMPORTE_ANTICIPO_DEP) AS HUECO ' +
    'FROM fza_depositos_cliente ' +
    'WHERE CODIGO_CLI_DEP = :c AND ESTADO_DEP = ''PENDIENTE'' ' +
    '  AND USUARIO_ALTA = :u ' +
    'ORDER BY FECHA_CREACION_DEP, ID_DEPOSITO_DEP';
var
  q:                  TUniQuery;
  aId:                TArray<string>;
  aHueco:             TArray<Double>;
  i, n:               Integer;
  fRest, fPago, fHueco: Double;
begin
  Result := '';
  n := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text   := cSel;
    q.ParamByName('c').AsString := sCli;
    q.ParamByName('u').AsString := Eng.Usuario;
    q.Open;
    while not q.Eof do
    begin
      SetLength(aId, n + 1);
      SetLength(aHueco, n + 1);
      aId[n]    := q.FieldByName('ID_DEPOSITO_DEP').AsString;
      aHueco[n] := q.FieldByName('HUECO').AsFloat;
      Inc(n);
      q.Next;
    end;
  finally
    q.Free;
  end;
  fRest := fImporte;
  i := 0;
  while (i < n) and (fRest > 0.005) do
  begin
    fHueco := aHueco[i];
    // Depósito sin precio (hueco <= 0): absorbe lo que quede del cobro.
    if fHueco <= 0 then
      fHueco := fRest;
    fPago := fRest;
    if fPago > fHueco then
      fPago := fHueco;
    AcumularAnticipo(Eng, aId[i], fPago);
    if Result = '' then
      Result := aId[i];
    fRest := fRest - fPago;
    Inc(i);
  end;
  // Sobrante (cobro mayor que el hueco total): lo dejamos en el primero.
  if (fRest > 0.005) and (n > 0) then
  begin
    AcumularAnticipo(Eng, aId[0], fRest);
    if Result = '' then
      Result := aId[0];
  end;
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarVentas(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT c.Empresa, c.Almacen, c.Caja, c.Operacion, ' +
    '       ISNULL(alm.Abreviatura, '''')    AS AbrevAlm, ' +
    '       ISNULL(almdes.Abreviatura, '''') AS AbrevAlmDes, ' +
    '       ISNULL(c.TipoDoc, '''') AS TipoDoc, ISNULL(c.Tipo, '''') AS Tipo, ' +
    '       c.Fecha, c.FechaOpe, ISNULL(c.Hora, '''') AS Hora, ' +
    '       c.Vendedor, ISNULL(c.Cliente, '''') AS Cliente, ' +
    '       ISNULL(c.Neto, 0) AS Neto, ' +
    '       ISNULL(c.Efectivo, 0) AS Efectivo, ' +
    '       ISNULL(c.Tarjeta, 0) AS Tarjeta, ' +
    '       ISNULL(c.ValeTienda, 0) AS ValeTienda, ' +
    '       ISNULL(c.ValePromocion, 0) AS ValePromocion, ' +
    '       ISNULL(c.Descripcion, '''') AS Descripcion, ' +
    '       c.NroFactura, ISNULL(c.SerieFactura, '''') AS SerieFactura, ' +
    '       c.EmpresaDes, c.AlmacenDes ' +
    'FROM dbo.occaj c ' +
    'LEFT JOIN dbo.ocalm alm ON alm.Empresa = c.Empresa ' +
    '                       AND alm.Almacen = c.Almacen ' +
    'LEFT JOIN dbo.ocalm almdes ON almdes.Empresa = c.EmpresaDes ' +
    '                          AND almdes.Almacen = c.AlmacenDes ' +
    'ORDER BY c.Empresa, c.Almacen, c.Caja, c.Operacion';
  cInsOp =
    'INSERT INTO fza_caja_operaciones ' +
    '  (CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, CODIGO_CAJA_OPCAJA, ' +
    '   NUMERO_OPERACION_OPCAJA, NUMERO_FAC_OPCAJA, SERIE_FAC_OPCAJA, ' +
    '   FECHA_OPERACION_OPCAJA, FECHA_OP_DIA_OPCAJA, CODIGO_EMPLEADO_OPCAJA, ' +
    '   TIPO_OPERACION_OPCAJA, IMPORTE_TOTAL_OPCAJA, CODIGO_CLI_OPCAJA, ' +
    '   CONCEPTO_GASTO_INGRESO_OPCAJA, CODIGO_EMP_CONTRA_OPCAJA, ' +
    '   CODIGO_ALM_CONTRA_OPCAJA, ESTRASPASO_OPCAJA, ID_DEPOSITO_OPCAJA, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:emp, :alm, :caja, :num, :nfac, :sfac, :fop, :fdia, :empl, ' +
    '        :tipo, :imp, :cli, :concepto, :empcontra, :almcontra, ' +
    '        :estras, :iddep, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
  cInsPago =
    'INSERT INTO fza_caja_pagos ' +
    '  (CODIGO_EMP_PAGO, CODIGO_ALM_PAGO, CODIGO_CAJA_PAGO, ' +
    '   SERIE_OPERACION_PAGO, NUMERO_OPERACION_PAGO, NUMERO_LINEA_PAGO, ' +
    '   CODIGO_FP_CFP, FACTOR_CAMBIO_PAGO, IMPORTE_DIVISA_PAGO, ' +
    '   IMPORTE_ENTREGADO_PAGO, IMPORTE_CAMBIO_PAGO, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA) ' +
    'VALUES (:emp, :alm, :caja, '''', :num, :linea, :fp, 1, 0, ' +
    '        :imp, 0, :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA)';
  cInsDep =
    'INSERT INTO fza_depositos_cliente ' +
    '  (ID_DEPOSITO_DEP, CODIGO_EMP_DEP, CODIGO_CLI_DEP, CODIGO_ART_DEP, ' +
    '   CODIGO_UNIDAD_DEP, CODIGO_ALM_DEP, PRECIO_VENTA_DEP, ' +
    '   IMPORTE_ANTICIPO_DEP, ESTADO_DEP, FECHA_CREACION_DEP, ' +
    '   TIPO_IVA_DEP, PORCENTAJE_IVA_DEP, ESIMP_INCL_DEP, ' +
    '   CANTIDAD_PENDIENTE_DEP, CODIGO_CAJA_DEP, NUMERO_OPERACION_DEP, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:id, :emp, :cli, :art, :uni, :alm, :precio, 0, ''PENDIENTE'', ' +
    '        :fcrea, ''N'', 0, ''S'', :cant, :caja, :num, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qOp, qPago, qDep:    TUniQuery;
  iEmp, iAlm, iCaja, iOpe:   Integer;
  iLineaPago:                Integer;
  sEmp, sAlm, sCaja, sNum:   string;
  sTipoOp, sCli, sConcepto:  string;
  sDepSku, sIdDep:           string;
  sCajaKey, sUltimaCaja:     string;
  sUltimoCli:                string;
  dtInstante:                TDateTime;
  fNeto:                     Double;

  // Inserta una línea de pago si el importe no es ~0.
  procedure AddPago(const sFp: string; fImporte: Double);
  begin
    if Abs(fImporte) >= 0.005 then
    begin
      Inc(iLineaPago);
      qPago.ParamByName('emp').AsString    := sEmp;
      qPago.ParamByName('alm').AsString    := sAlm;
      qPago.ParamByName('caja').AsString   := sCaja;
      qPago.ParamByName('num').AsString    := sNum;
      qPago.ParamByName('linea').AsInteger := iLineaPago;
      qPago.ParamByName('fp').AsString     := sFp;
      qPago.ParamByName('imp').AsFloat     := fImporte;
      RellenarAuditoria(qPago, Eng.Usuario);
      qPago.ExecSQL;
    end;
  end;

begin
  AsegurarFormaPagoVale(Eng);
  LimpiarMigracionPrevia(Eng);
  qSrc  := NuevoQOrigen(Eng, cSelectSrc);
  qOp   := TUniQuery.Create(nil);
  qPago := TUniQuery.Create(nil);
  qDep  := TUniQuery.Create(nil);
  try
    qOp.Connection   := Eng.ConDst;   qOp.SQL.Text   := cInsOp;
    qPago.Connection := Eng.ConDst;   qPago.SQL.Text := cInsPago;
    qDep.Connection  := Eng.ConDst;   qDep.SQL.Text  := cInsDep;
    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.occaj'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      if (Stats.Leidas mod 1000 = 0) and Eng.IsCancelado then
      begin
        Eng.Log('  Cancelacion detectada en Ventas, saliendo...');
        Break;
      end;
      Inc(Stats.Leidas);
      Eng.IncRow;
      iEmp  := qSrc.FieldByName('Empresa').AsInteger;
      iAlm  := qSrc.FieldByName('Almacen').AsInteger;
      iCaja := qSrc.FieldByName('Caja').AsInteger;
      iOpe  := qSrc.FieldByName('Operacion').AsInteger;
      sEmp  := IntToStr(iEmp);
      sCaja := IntToStr(iCaja);
      sNum  := Format('%.8d', [iOpe]);
      sAlm  := UpperCase(Trim(qSrc.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(iAlm);
      // El "documento adyacente" solo vale dentro de la misma caja: al
      // cambiar de caja olvidamos el último cliente.
      sCajaKey := Format('%d|%d|%d', [iEmp, iAlm, iCaja]);
      if sCajaKey <> sUltimaCaja then
      begin
        sUltimaCaja := sCajaKey;
        sUltimoCli  := '';
      end;
      sTipoOp := MapearTipoOp(qSrc.FieldByName('TipoDoc').AsString,
                              qSrc.FieldByName('Tipo').AsString);
      sCli  := Trim(qSrc.FieldByName('Cliente').AsString);
      // Cobro SIN cliente: hereda el del documento adyacente (último
      // documento con cliente en la misma caja). Ese cliente es el que nos
      // permite localizar y enlazar su depósito abierto.
      if (sTipoOp = 'CB') and (sCli = '') and (sUltimoCli <> '') then
        sCli := sUltimoCli;
      fNeto := qSrc.FieldByName('Neto').AsFloat;
      sConcepto := Trim(qSrc.FieldByName('Descripcion').AsString);
      // Instante de la operación: FechaOpe (o Fecha) + Hora.
      if not qSrc.FieldByName('FechaOpe').IsNull then
        dtInstante := qSrc.FieldByName('FechaOpe').AsDateTime
      else if not qSrc.FieldByName('Fecha').IsNull then
        dtInstante := qSrc.FieldByName('Fecha').AsDateTime
      else
        dtInstante := Now;
      dtInstante := ComponerInstante(dtInstante,
                      qSrc.FieldByName('Hora').AsString);
      // Depósito: si es AL (→DE) creamos un depósito por línea ANTES de la
      // operación para enlazar ID_DEPOSITO_OPCAJA al primero.
      sIdDep := '';
      if sTipoOp = 'DE' then
      begin
        sIdDep := CrearDepositosAlbaran(Eng, iEmp, iAlm, iCaja, iOpe,
                    sEmp, sAlm, sCli, sCaja, sNum, dtInstante, qDep);
      end
      else if sTipoOp = 'CB' then
      begin
        // Cobro a cuenta (adelanto): se reparte (waterfall) entre los
        // depósitos PENDIENTES del cliente, cerrándolos al alcanzar su
        // precio. sIdDep apunta al primero tocado.
        if sCli <> '' then
          sIdDep := AplicarCobroADepositos(Eng, sCli, fNeto);
      end;
      // Cabecera de operación.
      qOp.ParamByName('emp').AsString  := sEmp;
      qOp.ParamByName('alm').AsString  := sAlm;
      qOp.ParamByName('caja').AsString := sCaja;
      qOp.ParamByName('num').AsString  := sNum;
      if qSrc.FieldByName('NroFactura').AsInteger > 0 then
      begin
        qOp.ParamByName('nfac').AsString :=
          IntToStr(qSrc.FieldByName('NroFactura').AsInteger);
        qOp.ParamByName('sfac').AsString :=
          Trim(qSrc.FieldByName('SerieFactura').AsString);
      end
      else
      begin
        qOp.ParamByName('nfac').Clear;
        qOp.ParamByName('sfac').Clear;
      end;
      qOp.ParamByName('fop').AsDateTime  := dtInstante;
      qOp.ParamByName('fdia').AsDateTime := Trunc(dtInstante);
      qOp.ParamByName('empl').AsString   :=
        IntToStr(qSrc.FieldByName('Vendedor').AsInteger);
      qOp.ParamByName('tipo').AsString   := sTipoOp;
      qOp.ParamByName('imp').AsFloat     := fNeto;
      if sCli <> '' then
        qOp.ParamByName('cli').AsString  := sCli
      else
        qOp.ParamByName('cli').Clear;
      if sConcepto <> '' then
        qOp.ParamByName('concepto').AsString := Copy(sConcepto, 1, 100)
      else
        qOp.ParamByName('concepto').Clear;
      // Traspasos: marcar y resolver almacén contra (destino).
      if (sTipoOp = 'TR') or (sTipoOp = 'AT') then
      begin
        qOp.ParamByName('estras').AsString := 'S';
        qOp.ParamByName('empcontra').AsString :=
          IntToStr(qSrc.FieldByName('EmpresaDes').AsInteger);
        sDepSku := UpperCase(Trim(qSrc.FieldByName('AbrevAlmDes').AsString));
        if sDepSku = '' then
          sDepSku := IntToStr(qSrc.FieldByName('AlmacenDes').AsInteger);
        qOp.ParamByName('almcontra').AsString := sDepSku;
      end
      else
      begin
        qOp.ParamByName('estras').AsString := 'N';
        qOp.ParamByName('empcontra').Clear;
        qOp.ParamByName('almcontra').Clear;
      end;
      if sIdDep <> '' then
        qOp.ParamByName('iddep').AsString := sIdDep
      else
        qOp.ParamByName('iddep').Clear;
      RellenarAuditoria(qOp, Eng.Usuario);
      try
        qOp.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('venta', sEmp + '/' + sCaja + '/' + sNum,
            E.Message, Format('tipo=%s', [sTipoOp]),
            'la operacion requiere que el almacen ya este migrado');
          raise;
        end;
      end;
      // Líneas de pago desde las columnas de occaj.
      iLineaPago := 0;
      AddPago('EFE',  qSrc.FieldByName('Efectivo').AsFloat);
      AddPago('TARJ', qSrc.FieldByName('Tarjeta').AsFloat);
      AddPago('VALE', qSrc.FieldByName('ValeTienda').AsFloat);
      AddPago('VALE', qSrc.FieldByName('ValePromocion').AsFloat);
      // Recordamos el cliente (real o heredado) para el siguiente documento
      // adyacente de la misma caja.
      if sCli <> '' then
        sUltimoCli := sCli;
      qSrc.Next;
    end;
  finally
    qDep.Free;
    qPago.Free;
    qOp.Free;
    qSrc.Free;
  end;
end;

end.
