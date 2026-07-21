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
{      operaciones almacén depósito  → fza_depositos_cliente + DE              }
{                                                                              }
{    Mapeo de tipo (occaj.TipoDoc/Tipo → TIPO_OPERACION_OPCAJA):               }
{      almacén depósito → 'DE'  (además crea fza_depositos_cliente)            }
{      AL (Tipo='A')    → 'DE'  (respaldo si ocalm no está definido)           }
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
{    El valor de los depósitos se prorratea contra el neto real del AL para    }
{    respetar descuentos del legacy; al final se reconcilia la deuda abierta   }
{    contra DE-CB para no dejar saldos inflados por devoluciones históricas.   }
{    Un CB SIN cliente hereda el del DOCUMENTO ADYACENTE (último documento     }
{    con cliente en la misma caja), que es como el legacy enlaza el cobro con  }
{    su albarán/cuenta. Si aún así no hay cliente, el CB queda suelto.         }
{                                                                              }
{    Formas de pago: el legacy guarda el desglose en COLUMNAS de occaj         }
{    (Efectivo, Tarjeta, ValeTienda, ValePromocion). Cada columna no nula      }
{    genera una línea en fza_caja_pagos con su CODIGO_FP_CFP:                  }
{      Efectivo      → 'EFE'                                                   }
{      Tarjeta       → 'TARJ'+TipoTarjeta (TARJETA n; sin tipo: 'TARJ')        }
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

function NombreSugiereDeposito(const sNombre,
                               sAbreviatura: string): Boolean;
var
  sTexto: string;
begin
  sTexto := UpperCase(Trim(sNombre)) + '|' +
            UpperCase(Trim(sAbreviatura));
  Result := Pos('DEPO', sTexto) > 0;
end;

// El almacén de depósitos es la señal principal del legacy. TipoDoc='AL'
// se conserva como respaldo para bases que no tengan bien definido ocalm.
function MapearTipoOp(const sTipoDoc, sTipo: string;
                      EsAlmacenDeposito: Boolean): string;
var
  d, t: string;
begin
  d := UpperCase(Trim(sTipoDoc));
  t := UpperCase(Trim(sTipo));
  if d = 'TR' then
    Result := 'TR'
  else if d = 'AT' then
    Result := 'AT'
  else if t = 'C' then
    Result := 'CB'
  else if t = 'L' then
    Result := 'VL'
  else if EsAlmacenDeposito or (d = 'AL') then
    Result := 'DE'
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

// Codigo de forma de pago para un TipoTarjeta del legacy: 'TARJ'+n (TARJETA n).
// TipoTarjeta=0 (sin tipo) cae en la 'TARJ' generica del seed.
function CodigoTarjeta(iTipo: Integer): string;
begin
  if iTipo > 0 then
    Result := 'TARJ' + IntToStr(iTipo)
  else
    Result := 'TARJ';
  // CODIGO_FP_CFP en los pagos es varchar(10): un TipoTarjeta anomalo muy
  // grande (>6 digitos) desbordaria, asi que esos caen en la 'TARJ' generica.
  if Length(Result) > 10 then
    Result := 'TARJ';
end;
// Asegura las formas de pago de caja que usa la migracion: 'EFE' (Efectivo) y
// una 'TARJ<n>' por cada TipoTarjeta distinto del legacy. La descripcion se
// toma de octarcre.Nombre, que guarda nombres como Visa, MasterCard o banco.
procedure AsegurarFormasPagoCaja(Eng: TMigEngine);
const
  cInsFP =
    'INSERT IGNORE INTO fza_caja_formas_pago ' +
    '  (CODIGO_FP_CFP, DESCRIPCION_FORMA_PAGO_CFP, ' +
    '   ESREQ_REFERENCIA_FORMA_PAGO_CFP, ESCRIPTO_FORMA_PAGO_CFP, ' +
    '   ESDIVISA_FORMA_PAGO_CFP, ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP, ' +
    '   ESABRE_CAJON_FORMA_PAGO_CFP, ESACTIVO_FORMA_PAGO_CFP, ' +
    '   ORDEN_VISUAL_FORMA_PAGO_CFP, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:cod, :desc, ''N'', ''N'', ''N'', :cambio, :cajon, ''S'', ' +
    '        :orden, NOW(), NOW(), :ua, :um)';
  cSelTar =
    'SELECT t.TipoTarjeta, ' +
    '       COALESCE(NULLIF(LTRIM(RTRIM(tc.Nombre)), ''''), ' +
    '                NULLIF(LTRIM(RTRIM(tc.Abreviatura)), ''''), ' +
    '                ''TARJETA '' + CAST(t.TipoTarjeta AS varchar(10))) ' +
    '         AS NombreTarjeta ' +
    'FROM ( ' +
    '  SELECT DISTINCT TipoTarjeta FROM dbo.occaj ' +
    '  WHERE TipoTarjeta IS NOT NULL AND TipoTarjeta <> 0 ' +
    ') t ' +
    'LEFT JOIN dbo.octarcre tc ON tc.Tarjeta = t.TipoTarjeta ' +
    'ORDER BY t.TipoTarjeta';
  cUpdDescGenerica =
    'UPDATE fza_caja_formas_pago ' +
    'SET DESCRIPCION_FORMA_PAGO_CFP = :desc, ' +
    '    INSTANTE_MODIF = NOW(), USUARIO_MODIF = :um ' +
    'WHERE CODIGO_FP_CFP = :cod ' +
    '  AND UPPER(TRIM(DESCRIPCION_FORMA_PAGO_CFP)) = UPPER(:generica)';
var
  qDst: TUniQuery;
  qUpd: TUniQuery;
  qTar: TUniQuery;
  iTipo: Integer;
  sDesc: string;
  sDescGenerica: string;
  procedure InsertarFP(const sCod, sDesc, sCambio, sCajon: string;
    iOrden: Integer);
  begin
    qDst.ParamByName('cod').AsString    := sCod;
    qDst.ParamByName('desc').AsString   := sDesc;
    qDst.ParamByName('cambio').AsString := sCambio;
    qDst.ParamByName('cajon').AsString  := sCajon;
    qDst.ParamByName('orden').AsInteger := iOrden;
    qDst.ParamByName('ua').AsString     := Eng.Usuario;
    qDst.ParamByName('um').AsString     := Eng.Usuario;
    qDst.ExecSQL;
  end;
  procedure ActualizarDescripcionGenerica(const sCod, sDesc,
    sGenerica: string);
  begin
    if Trim(sDesc) <> '' then
    begin
      qUpd.ParamByName('cod').AsString      := sCod;
      qUpd.ParamByName('desc').AsString     := sDesc;
      qUpd.ParamByName('um').AsString       := Eng.Usuario;
      qUpd.ParamByName('generica').AsString := sGenerica;
      qUpd.ExecSQL;
    end;
  end;
begin
  qDst := TUniQuery.Create(nil);
  qUpd := TUniQuery.Create(nil);
  try
    qDst.Connection := Eng.ConDst;
    qDst.SQL.Text   := cInsFP;
    qUpd.Connection := Eng.ConDst;
    qUpd.SQL.Text   := cUpdDescGenerica;
    // Efectivo: da cambio y abre cajon. Orden 1 (primer boton en F12).
    InsertarFP('EFE', 'Efectivo', 'S', 'S', 1);
    // Tarjeta generica: respaldo para pagos con tarjeta sin tipo (TipoTarjeta
    // 0) o con un tipo anomalo demasiado largo (ver CodigoTarjeta).
    InsertarFP('TARJ', 'TARJETA', 'N', 'N', 9);
    // Una forma de pago por cada TipoTarjeta del legacy. Si ya existia de una
    // migracion anterior como TARJETA n, se renombra con el maestro origen.
    qTar := NuevoQOrigen(Eng, cSelTar);
    try
      qTar.Open;
      while not qTar.Eof do
      begin
        iTipo := qTar.FieldByName('TipoTarjeta').AsInteger;
        sDesc := Trim(qTar.FieldByName('NombreTarjeta').AsString);
        sDescGenerica := 'TARJETA ' + IntToStr(iTipo);
        InsertarFP(CodigoTarjeta(iTipo), Copy(sDesc, 1, 100),
          'N', 'N', 10 + iTipo);
        ActualizarDescripcionGenerica(CodigoTarjeta(iTipo),
          Copy(sDesc, 1, 100), sDescGenerica);
        qTar.Next;
      end;
    finally
      qTar.Free;
    end;
  finally
    qUpd.Free;
    qDst.Free;
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
// Si el neto de la operación no coincide con el total de líneas, prorratea el
// neto para que la deuda de depósitos cuadre con el DE migrado.
// Devuelve el ID del PRIMER depósito (para enlazarlo a la operación DE), o
// '' si la operación no tiene líneas de artículo aprovechables. El INSERT se
// hace sobre qDep (preparado por el llamante con cInsDep).
function CrearDepositosAlbaran(Eng: TMigEngine;
                               const iEmp, iAlm, iCaja, iOpe: Integer;
                               const sEmp, sAlm, sCli, sCaja, sNum: string;
                               const dtCrea: TDateTime;
                               const fNetoOperacion: Double;
                               qDep: TUniQuery): string;
const
  cLineas =
    'SELECT l.NroLinea, l.Articulo, l.Talla, ' +
    '       ISNULL(l.PrecioCIva, 0) AS PrecioCIva, ' +
    '       ISNULL(l.Cantidad, 0) AS Cantidad, ' +
    '       CASE ' +
    '         WHEN ac.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(ac.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(ac.Color))) ' +
    '         WHEN l.Color IS NOT NULL ' +
    '           AND LTRIM(RTRIM(l.Color)) <> '''' ' +
    '           THEN UPPER(LTRIM(RTRIM(l.Color))) ' +
    '         ELSE ''0'' ' +
    '       END AS DescColor ' +
    'FROM dbo.occajarp l ' +
    'LEFT JOIN dbo.ocartcol ac ON ac.Articulo = l.Articulo ' +
    '                         AND ac.Color    = l.Color ' +
    'LEFT JOIN dbo.occolor co ON co.ColorBasico = ac.ColorBasico ' +
    'WHERE l.Empresa = :e AND l.Almacen = :a ' +
    '  AND l.Caja = :c AND l.Operacion = :o ' +
    '  AND LTRIM(RTRIM(l.Articulo)) <> '''' AND l.Articulo <> ''0'' ' +
    'ORDER BY l.NroLinea';
type
  TLineaDeposito = record
    NroLinea:     Integer;
    Articulo:     string;
    CodigoUnidad: string;
    PrecioBruto:  Double;
    Cantidad:     Double;
    ImporteBruto: Double;
    ImporteNeto:  Double;
  end;
var
  qLin: TUniQuery;
  aLineas: TArray<TLineaDeposito>;
  i, iUltima: Integer;
  n: Integer;
  sArt, sId: string;
  fFactor: Double;
  fPrecio: Double;
  fTotalAjustado: Double;
  fTotalBruto: Double;
  bMismoSigno: Boolean;
begin
  Result := '';
  fTotalBruto := 0;
  iUltima := -1;
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
      n := Length(aLineas);
      SetLength(aLineas, n + 1);
      sArt := Trim(qLin.FieldByName('Articulo').AsString);
      aLineas[n].NroLinea := qLin.FieldByName('NroLinea').AsInteger;
      aLineas[n].Articulo := sArt;
      aLineas[n].CodigoUnidad := ConstruirCodigoUnidad(sArt,
        Trim(qLin.FieldByName('DescColor').AsString),
        Trim(qLin.FieldByName('Talla').AsString));
      aLineas[n].PrecioBruto := qLin.FieldByName('PrecioCIva').AsFloat;
      aLineas[n].Cantidad := qLin.FieldByName('Cantidad').AsFloat;
      aLineas[n].ImporteBruto := aLineas[n].PrecioBruto *
        aLineas[n].Cantidad;
      aLineas[n].ImporteNeto := aLineas[n].ImporteBruto;
      fTotalBruto := fTotalBruto + aLineas[n].ImporteBruto;
      if Abs(aLineas[n].Cantidad) > 0.000001 then
        iUltima := n;
      qLin.Next;
    end;
  finally
    qLin.Free;
  end;
  bMismoSigno := ((fTotalBruto > 0) and (fNetoOperacion >= 0)) or
    ((fTotalBruto < 0) and (fNetoOperacion <= 0));
  if (Length(aLineas) > 0)
  and (iUltima >= 0)
  and (Abs(fTotalBruto) > 0.005)
  and (Abs(fNetoOperacion - fTotalBruto) > 0.005)
  and bMismoSigno then
  begin
    fFactor := fNetoOperacion / fTotalBruto;
    fTotalAjustado := 0;
    for i := 0 to High(aLineas) do
    begin
      if i = iUltima then
        aLineas[i].ImporteNeto := fNetoOperacion - fTotalAjustado
      else
      begin
        aLineas[i].ImporteNeto := aLineas[i].ImporteBruto * fFactor;
        fTotalAjustado := fTotalAjustado + aLineas[i].ImporteNeto;
      end;
    end;
  end;
  for i := 0 to High(aLineas) do
  begin
    sArt := aLineas[i].Articulo;
    if Abs(aLineas[i].Cantidad) > 0.000001 then
      fPrecio := aLineas[i].ImporteNeto / aLineas[i].Cantidad
    else
      fPrecio := aLineas[i].PrecioBruto;
    if Abs(fPrecio) < 0.000001 then
      fPrecio := 0;
    // El ALMACEN va en el ID: occaj.Operacion se numera por (Empresa,
    // Almacen, Caja), asi que el mismo nº de operacion existe en varios
    // almacenes. Sin el almacen, DM<emp>-<caja>-<op>-<linea> colisiona
    // entre tiendas (Duplicate entry para la PK del deposito).
    sId  := Format('DM%d-%d-%d-%d-%d',
              [iEmp, iAlm, iCaja, iOpe, aLineas[i].NroLinea]);
      qDep.ParamByName('id').AsString    := sId;
      qDep.ParamByName('emp').AsString   := sEmp;
      if sCli <> '' then
        qDep.ParamByName('cli').AsString := sCli
      else
        qDep.ParamByName('cli').AsString := '0';
      qDep.ParamByName('art').AsString   := sArt;
      qDep.ParamByName('uni').AsString   := aLineas[i].CodigoUnidad;
      qDep.ParamByName('alm').AsString   := sAlm;
      qDep.ParamByName('precio').AsFloat := fPrecio;
      qDep.ParamByName('cant').AsFloat   := aLineas[i].Cantidad;
      qDep.ParamByName('fcrea').AsDateTime := dtCrea;
      qDep.ParamByName('caja').AsString  := sCaja;
      qDep.ParamByName('num').AsString   := sNum;
      RellenarAuditoria(qDep, Eng.Usuario);
      qDep.ExecSQL;
      if Result = '' then
        Result := sId;
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
    '       ESTADO_DEP = IF(COALESCE(CANTIDAD_PENDIENTE_DEP, 1) > 0 ' +
    '                       AND IMPORTE_ANTICIPO_DEP >= ' +
    '                         (PRECIO_VENTA_DEP ' +
    '                          * COALESCE(CANTIDAD_PENDIENTE_DEP, 1)), ' +
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
// (waterfall: rellena cada uno hasta su importe, en orden de creación, y los
// cierra al llegar). Cubre el caso de AL multilínea (varios depósitos por
// operación). Devuelve el ID del PRIMER depósito tocado (para enlazar el CB).
// Primero leemos los depósitos a memoria y luego actualizamos, para no tener
// un cursor abierto mientras lanzamos los UPDATE sobre la misma conexión.
function AplicarCobroADepositos(Eng: TMigEngine; const sCli: string;
                                const fImporte: Double): string;
const
  cSel =
    'SELECT ID_DEPOSITO_DEP, ' +
    '       ((PRECIO_VENTA_DEP * COALESCE(CANTIDAD_PENDIENTE_DEP, 1)) ' +
    '        - IMPORTE_ANTICIPO_DEP) AS HUECO ' +
    'FROM fza_depositos_cliente ' +
    'WHERE CODIGO_CLI_DEP = :c AND ESTADO_DEP = ''PENDIENTE'' ' +
    '  AND COALESCE(CANTIDAD_PENDIENTE_DEP, 1) > 0 ' +
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
    // Solo acreditamos hasta el HUECO real del deposito (importe - anticipo).
    // Si no tiene hueco (precio 0 o ya cubierto) lo saltamos: nunca dejamos
    // anticipo > precio. Y el SOBRANTE (cobro mayor que la deuda de los
    // depositos del cliente) se DESCARTA — antes se volcaba en el primer
    // deposito sobre-acreditandolo. El cobro sigue registrado como pago.
    if fHueco > 0 then
    begin
      fPago := fRest;
      if fPago > fHueco then
        fPago := fHueco;
      AcumularAnticipo(Eng, aId[i], fPago);
      if Result = '' then
        Result := aId[i];
      fRest := fRest - fPago;
    end;
    Inc(i);
  end;
end;

// Ajuste final de deuda abierta contra el saldo contable migrado:
// saldo operaciones = DE - CB. No crea cobros ficticios; reparte el exceso
// de deuda como anticipo tecnico sobre los prestamos pendientes FIFO. Cubre
// descuentos migrados y devoluciones que reducen deuda pero no son efectivo.
procedure RegularizarDeudaDepositosAOperaciones(Eng: TMigEngine);
const
  cSel =
    'SELECT dep.CODIGO_CLI_DEP, dep.deuda_dep, ' +
    '       GREATEST(COALESCE(ops.saldo_ops, 0), 0) AS deuda_ops, ' +
    '       dep.deuda_dep - GREATEST(COALESCE(ops.saldo_ops, 0), 0) ' +
    '         AS exceso ' +
    'FROM ( ' +
    '  SELECT CODIGO_CLI_DEP, ' +
    '         SUM((PRECIO_VENTA_DEP ' +
    '              * COALESCE(CANTIDAD_PENDIENTE_DEP, 1)) ' +
    '             - IMPORTE_ANTICIPO_DEP) AS deuda_dep ' +
    '  FROM fza_depositos_cliente ' +
    '  WHERE ESTADO_DEP = ''PENDIENTE'' ' +
    '    AND COALESCE(CANTIDAD_PENDIENTE_DEP, 1) > 0 ' +
    '    AND CODIGO_CLI_DEP IS NOT NULL ' +
    '    AND CODIGO_CLI_DEP <> '''' ' +
    '    AND CODIGO_CLI_DEP <> ''0'' ' +
    '    AND USUARIO_ALTA = :u_dep ' +
    '  GROUP BY CODIGO_CLI_DEP ' +
    ') dep ' +
    'LEFT JOIN ( ' +
    '  SELECT CODIGO_CLI_OPCAJA, ' +
    '         SUM(CASE ' +
    '               WHEN TIPO_OPERACION_OPCAJA = ''DE'' ' +
    '               THEN IMPORTE_TOTAL_OPCAJA ' +
    '               WHEN TIPO_OPERACION_OPCAJA = ''CB'' ' +
    '               THEN -IMPORTE_TOTAL_OPCAJA ' +
    '               ELSE 0 ' +
    '             END) AS saldo_ops ' +
    '  FROM fza_caja_operaciones ' +
    '  WHERE TIPO_OPERACION_OPCAJA IN (''DE'', ''CB'') ' +
    '    AND CODIGO_CLI_OPCAJA IS NOT NULL ' +
    '    AND CODIGO_CLI_OPCAJA <> '''' ' +
    '    AND CODIGO_CLI_OPCAJA <> ''0'' ' +
    '    AND USUARIO_ALTA = :u_ops ' +
    '  GROUP BY CODIGO_CLI_OPCAJA ' +
    ') ops ON ops.CODIGO_CLI_OPCAJA = dep.CODIGO_CLI_DEP ' +
    'WHERE dep.deuda_dep > GREATEST(COALESCE(ops.saldo_ops, 0), 0) + 0.005 ' +
    'ORDER BY dep.CODIGO_CLI_DEP';
var
  q: TUniQuery;
  iAjustes: Integer;
  fExceso: Double;
  fTotal: Double;
  sCli: string;
begin
  iAjustes := 0;
  fTotal := 0;
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text := cSel;
    q.ParamByName('u_dep').AsString := Eng.Usuario;
    q.ParamByName('u_ops').AsString := Eng.Usuario;
    q.Open;
    while not q.Eof do
    begin
      sCli := q.FieldByName('CODIGO_CLI_DEP').AsString;
      fExceso := q.FieldByName('exceso').AsFloat;
      if fExceso > 0.005 then
      begin
        AplicarCobroADepositos(Eng, sCli, fExceso);
        Inc(iAjustes);
        fTotal := fTotal + fExceso;
      end;
      q.Next;
    end;
  finally
    q.Free;
  end;
  if iAjustes > 0 then
    Eng.Log('  depositos: %d clientes regularizados contra DE-CB (%.2f).',
      [iAjustes, fTotal])
  else
    Eng.Log('  depositos: deuda abierta ya cuadra contra DE-CB.');
end;

// Netea las devoluciones de deposito (-1) con su prestamo (+1) del mismo
// cliente y SKU (FIFO por fecha): cierra AMBOS. Las lineas AL de devolucion
// creaban un deposito -1 PENDIENTE que no cerraba su +1 original; aqui se
// cuadran. Idempotente (re-ejecutar no encuentra devoluciones PENDIENTE).
// ORDEN: primero cerramos los +1 (mientras las -1 siguen PENDIENTE para poder
// contarlas) y luego las -1 (incluidas las huerfanas sin +1).
procedure NetearDevolucionesDeposito(Eng: TMigEngine);
var
  sU: string;
begin
  sU := ValorOrNull(Eng.Usuario);
  // 1) Cerrar los N prestamos +1 mas antiguos por (cliente, SKU), donde
  //    N = nº de devoluciones de ese SKU.
  EjecutarSQL(Eng,
    'UPDATE fza_depositos_cliente d ' +
    'JOIN ( ' +
    '  SELECT p.ID_DEPOSITO_DEP ' +
    '  FROM ( ' +
    '    SELECT ID_DEPOSITO_DEP, CODIGO_CLI_DEP, CODIGO_UNIDAD_DEP, ' +
    '           ROW_NUMBER() OVER ( ' +
    '             PARTITION BY CODIGO_CLI_DEP, CODIGO_UNIDAD_DEP ' +
    '             ORDER BY FECHA_CREACION_DEP, ID_DEPOSITO_DEP) AS rn ' +
    '    FROM fza_depositos_cliente ' +
    '    WHERE CANTIDAD_PENDIENTE_DEP > 0 AND ESTADO_DEP = ''PENDIENTE'' ' +
    '      AND USUARIO_ALTA = ' + sU + ' ' +
    '  ) p ' +
    '  JOIN ( ' +
    '    SELECT CODIGO_CLI_DEP, CODIGO_UNIDAD_DEP, COUNT(*) AS n_ret ' +
    '    FROM fza_depositos_cliente ' +
    '    WHERE CANTIDAD_PENDIENTE_DEP < 0 AND ESTADO_DEP = ''PENDIENTE'' ' +
    '      AND USUARIO_ALTA = ' + sU + ' ' +
    '    GROUP BY CODIGO_CLI_DEP, CODIGO_UNIDAD_DEP ' +
    '  ) r ON r.CODIGO_CLI_DEP = p.CODIGO_CLI_DEP ' +
    '     AND r.CODIGO_UNIDAD_DEP = p.CODIGO_UNIDAD_DEP ' +
    '  WHERE p.rn <= r.n_ret ' +
    ') m ON m.ID_DEPOSITO_DEP = d.ID_DEPOSITO_DEP ' +
    'SET d.ESTADO_DEP = ''CERRADO'', d.INSTANTE_MODIF = NOW()');
  // 2) Cerrar todas las devoluciones -1 (incluidas las huerfanas sin +1).
  EjecutarSQL(Eng,
    'UPDATE fza_depositos_cliente ' +
    'SET ESTADO_DEP = ''CERRADO'', INSTANTE_MODIF = NOW() ' +
    'WHERE CANTIDAD_PENDIENTE_DEP < 0 AND ESTADO_DEP = ''PENDIENTE'' ' +
    '  AND USUARIO_ALTA = ' + sU);
  Eng.Log('  depositos: devoluciones (-1) neteadas con su prestamo (FIFO).');
end;

// Calcula la deuda actual de cada cliente = suma de (importe - anticipo) de
// sus prestamos PENDIENTE (positivos) y la guarda en TOTAL_DEUDA_CLI.
// Va DESPUES del neteo y la regularizacion DE-CB. Requiere que el dominio
// 'clientes' ya este migrado; si no, no actualiza nada (join vacio).
procedure ActualizarDeudaClientes(Eng: TMigEngine);
var
  sU: string;
begin
  sU := ValorOrNull(Eng.Usuario);
  EjecutarSQL(Eng,
    'UPDATE fza_clientes c ' +
    'LEFT JOIN ( ' +
    '  SELECT CODIGO_CLI_DEP, ' +
    '         SUM((PRECIO_VENTA_DEP ' +
    '              * COALESCE(CANTIDAD_PENDIENTE_DEP, 1)) ' +
    '             - IMPORTE_ANTICIPO_DEP) AS deuda ' +
    '  FROM fza_depositos_cliente ' +
    '  WHERE ESTADO_DEP = ''PENDIENTE'' ' +
    '    AND COALESCE(CANTIDAD_PENDIENTE_DEP, 1) > 0 ' +
    '    AND USUARIO_ALTA = ' + sU + ' ' +
    '  GROUP BY CODIGO_CLI_DEP ' +
    ') d ON d.CODIGO_CLI_DEP = c.CODIGO_CLI_CLI ' +
    'SET c.TOTAL_DEUDA_CLI = COALESCE(d.deuda, 0), c.INSTANTE_MODIF = NOW() ' +
    'WHERE c.USUARIO_ALTA = ' + sU);
  Eng.Log('  clientes: deuda actual (prestamos abiertos) actualizada.');
end;

// =========================================================================
//  Migrador principal
// =========================================================================

procedure MigrarVentas(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT c.Empresa, c.Almacen, c.Caja, c.Operacion, ' +
    '       ISNULL(alm.Abreviatura, '''')    AS AbrevAlm, ' +
    '       ISNULL(alm.Nombre, '''')         AS NombreAlm, ' +
    '       ISNULL(alm.Deposito, '''')       AS EsDepositoAlm, ' +
    '       ISNULL(almdes.Abreviatura, '''') AS AbrevAlmDes, ' +
    '       ISNULL(c.TipoDoc, '''') AS TipoDoc, ISNULL(c.Tipo, '''') AS Tipo, ' +
    '       c.Fecha, c.FechaOpe, ISNULL(c.Hora, '''') AS Hora, ' +
    '       c.Vendedor, ISNULL(c.Cliente, '''') AS Cliente, ' +
    '       ISNULL(c.Neto, 0) AS Neto, ' +
    '       ISNULL(c.Efectivo, 0) AS Efectivo, ' +
    '       ISNULL(c.Tarjeta, 0) AS Tarjeta, ' +
    '       ISNULL(c.TipoTarjeta, 0) AS TipoTarjeta, ' +
    '       ISNULL(c.ValeTienda, 0) AS ValeTienda, ' +
    '       ISNULL(c.ValePromocion, 0) AS ValePromocion, ' +
    '       ISNULL(c.Descripcion, '''') AS Descripcion, ' +
    '       c.NroFactura, ISNULL(c.SerieFactura, '''') AS SerieFactura, ' +
    '       ISNULL(c.NroDoc, 0) AS NroDoc, ' +
    '       c.Ejercicio, ISNULL(c.Serie, '''') AS Serie, ' +
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
  iNroDoc:                   Integer;
  iLineaPago:                Integer;
  sEmp, sAlm, sCaja, sNum:   string;
  sTipoOp, sCli, sConcepto:  string;
  sDepSku, sIdDep:           string;
  sCajaKey, sUltimaCaja:     string;
  sUltimoCli:                string;
  dtInstante:                TDateTime;
  fNeto:                     Double;
  EsAlmacenDeposito:         Boolean;

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
  AsegurarFormasPagoCaja(Eng);
  LimpiarMigracionPrevia(Eng);
  qSrc  := NuevoQOrigen(Eng, cSelectSrc);
  // Streaming: occaj puede ser enorme; no cacheamos todo en memoria.
  qSrc.UniDirectional := True;
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
      iNroDoc := qSrc.FieldByName('NroDoc').AsInteger;
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
      if Eng.TieneAlmacenDeposito(iEmp) then
        EsAlmacenDeposito := Eng.EsAlmacenDeposito(iEmp, iAlm)
      else
        EsAlmacenDeposito :=
          (BoolSN(qSrc.FieldByName('EsDepositoAlm').AsString) = 'S') or
          NombreSugiereDeposito(
            qSrc.FieldByName('NombreAlm').AsString,
            qSrc.FieldByName('AbrevAlm').AsString);
      sTipoOp := MapearTipoOp(qSrc.FieldByName('TipoDoc').AsString,
                              qSrc.FieldByName('Tipo').AsString,
                              EsAlmacenDeposito);
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
                    sEmp, sAlm, sCli, sCaja, sNum, dtInstante, fNeto,
                    qDep);
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
      // SERIE_FAC_OPCAJA / NUMERO_FAC_OPCAJA deben CUADRAR con la clave que
      // genera la migracion de facturas (SERIE = '<Ejercicio>.<Serie>',
      // NUMERO = NroDoc, el nº de factura del legacy), porque el ticket y la
      // consulta de operaciones enlazan operacion -> factura por esas columnas.
      // Solo las VENTA (TipoDoc='VE' y Tipo<>'C') generan factura; el resto la
      // deja vacia. (NroFactura/SerieFactura del legacy vienen vacios en venta
      // detalle; el numero real de factura es NroDoc.)
      if (UpperCase(Trim(qSrc.FieldByName('TipoDoc').AsString)) = 'VE')
      and (UpperCase(Trim(qSrc.FieldByName('Tipo').AsString)) <> 'C') then
      begin
        qOp.ParamByName('sfac').AsString :=
          Format('%d.%s', [qSrc.FieldByName('Ejercicio').AsInteger,
                 Trim(qSrc.FieldByName('Serie').AsString)]);
        qOp.ParamByName('nfac').AsString := IntToStr(iNroDoc);
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
      AddPago(CodigoTarjeta(qSrc.FieldByName('TipoTarjeta').AsInteger),
              qSrc.FieldByName('Tarjeta').AsFloat);
      AddPago('VALE', qSrc.FieldByName('ValeTienda').AsFloat);
      AddPago('VALE', qSrc.FieldByName('ValePromocion').AsFloat);
      // Recordamos el cliente (real o heredado) para el siguiente documento
      // adyacente de la misma caja.
      if sCli <> '' then
        sUltimoCli := sCli;
      qSrc.Next;
    end;
    // Cuadrar depositos: netear las devoluciones (-1) con su prestamo (+1),
    // reconciliar la deuda abierta con el saldo DE-CB y volcar la deuda a la
    // ficha del cliente (TOTAL_DEUDA_CLI).
    NetearDevolucionesDeposito(Eng);
    RegularizarDeudaDepositosAOperaciones(Eng);
    ActualizarDeudaClientes(Eng);
  finally
    qDep.Free;
    qPago.Free;
    qOp.Free;
    qSrc.Free;
  end;
end;

end.
