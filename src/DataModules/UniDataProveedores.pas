{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataProveedores                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de proveedores.                                               }
{    Mantenimiento de fza_proveedores y consulta de artículos y líneas de      }
{    facturas asociadas.                                                       }
{******************************************************************************}
unit UniDataProveedores;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TdmProveedores = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryArticulos: TUniQuery;
    dsArticulos: TDataSource;
    unqryLinFacturasArticulos: TUniQuery;
    dsLinFacturasArticulos: TDataSource;
    // Pestaña Compras: lookup de sistemas de tallas (conjuntos TAL) y
    // biblioteca de kits del proveedor (cantidades por talla) que las
    // Sesiones de Compra aplican sobre la linea con foco.
    unqryConjuntosTallas: TUniQuery;
    dsConjuntosTallas: TDataSource;
    unqryKits: TUniQuery;
    dsKits: TDataSource;
    unqryKitsDet: TUniQuery;
    dsKitsDet: TDataSource;
    // Pestaña Pagos: lookups de forma de pago y de cuentas bancarias de
    // empresa (defectos de pago por proveedor).
    unqryFormaPago: TUniQuery;
    dsFormasPago: TDataSource;
    unqryEmpresasBancos: TUniQuery;
    dsEmpresasBancos: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryKitsBeforeInsert(DataSet: TDataSet);
    procedure unqryKitsAfterInsert(DataSet: TDataSet);
    procedure unqryKitsBeforePost(DataSet: TDataSet);
    procedure unqryKitsBeforeDelete(DataSet: TDataSet);
    procedure unqryKitsDetBeforeInsert(DataSet: TDataSet);
    procedure unqryKitsDetAfterInsert(DataSet: TDataSet);
    procedure unqryKitsDetBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoProveedor;
    // Override: ya no abre nada en el flujo inicial. Las dos queries
    // detail (Articulos, LinFacturasArticulos) son lazy por sub-pestaña.
    procedure AbrirDetalles; override;
    procedure AsegurarArticulosAbierta;
    procedure AsegurarVentasAbierta;
    procedure AsegurarComprasAbierta;
    // Abre los lookups de la pestaña Pagos (forma de pago y bancos de empresa).
    procedure AsegurarPagosAbierta;
    // Genera una fila de detalle (cantidad 0) por cada talla del sistema
    // del kit seleccionado. INSERT IGNORE: no pisa cantidades ya tecleadas.
    procedure GenerarTallasKitActual;
  end;

//var
//  dmmProveedores: TdmProveedores;

implementation

uses
  inMtoProveedores, inLibGlobalVar, inLibLog, System.Diagnostics;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmProveedores.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo Connection. Los .Open se han movido a AbrirDetalles.
  unstrdprcContador.Connection := oConn;
  unqryArticulos.Connection := oConn;
  unqryLinFacturasArticulos.Connection := oConn;
  unqryConjuntosTallas.Connection := oConn;
  unqryKits.Connection := oConn;
  unqryKitsDet.Connection := oConn;
  // Lookups de la pestaña Pagos: solo Connection; se abren al activar la
  // pestaña (AsegurarPagosAbierta), igual que el resto de detalles lazy.
  unqryFormaPago.Connection := oConn;
  unqryEmpresasBancos.Connection := oConn;
end;

procedure TdmProveedores.AbrirDetalles;
const
  TAG = 'Proveedores.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
  var swQ: TStopwatch;
  begin
    if qry.Active then Exit;
    swQ := TStopwatch.StartNew;
    try
      qry.Open;
      inLibLog.Log.LogPerf(TAG, Nombre + ' OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG, Nombre + ' ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;

var sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // Ambas queries son lazy. AbrirDetalles solo registra el TOTAL para
  // mantener consistencia con los demas Mtos.
  inLibLog.Log.LogPerf(TAG, 'TOTAL (todo lazy)', sw.ElapsedMilliseconds);
end;

procedure TdmProveedores.AsegurarArticulosAbierta;
var swQ: TStopwatch;
begin
  if unqryArticulos.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqryArticulos.Open;
    inLibLog.Log.LogPerf('Proveedores.Lazy', 'unqryArticulos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Proveedores.Lazy',
        'unqryArticulos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmProveedores.AsegurarVentasAbierta;
var swQ: TStopwatch;
begin
  if unqryLinFacturasArticulos.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqryLinFacturasArticulos.Open;
    inLibLog.Log.LogPerf('Proveedores.Lazy', 'unqryLinFacturasArticulos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Proveedores.Lazy',
        'unqryLinFacturasArticulos ERROR=' + E.Message,
        swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmProveedores.AsegurarComprasAbierta;
var swQ: TStopwatch;
begin
  if unqryKits.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqryConjuntosTallas.Open;
    unqryKits.Open;
    unqryKitsDet.Open;
    inLibLog.Log.LogPerf('Proveedores.Lazy', 'unqryKits OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Proveedores.Lazy',
        'unqryKits ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmProveedores.AsegurarPagosAbierta;
var swQ: TStopwatch;
begin
  if unqryFormaPago.Active and unqryEmpresasBancos.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    if not unqryFormaPago.Active then
      unqryFormaPago.Open;
    if not unqryEmpresasBancos.Active then
      unqryEmpresasBancos.Open;
    inLibLog.Log.LogPerf('Proveedores.Lazy', 'unqryPagos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Proveedores.Lazy',
        'unqryPagos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

// ===========================================================================
//   Kits de cantidades por talla (fza_proveedores_kits / _det)
// ===========================================================================

procedure TdmProveedores.unqryKitsBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  if unqryTablaG.IsEmpty then
    raise Exception.Create('Selecciona un proveedor antes de crear kits.');
  if unqryTablaG.State = dsInsert then
    raise Exception.Create('Graba el proveedor antes de crear kits.');
end;

procedure TdmProveedores.unqryKitsAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryKits do
  begin
    FieldByName('CODIGO_PRV_PRVKIT').AsString :=
      unqryTablaG.FieldByName('CODIGO_PRV_PRV').AsString;
    FieldByName('ORDEN_PRVKIT').AsInteger   := 0;
    FieldByName('USUARIO_ALTA').AsString    := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  end;
end;

procedure TdmProveedores.unqryKitsBeforePost(DataSet: TDataSet);
begin
  inherited;
  if Trim(unqryKits.FieldByName('CODIGO_PRVKIT').AsString) = '' then
    raise Exception.Create('El kit necesita un código (p. ej. CURVA-STD).');
  if Trim(unqryKits.FieldByName('NOMBRE_PRVKIT').AsString) = '' then
    raise Exception.Create('El kit necesita un nombre.');
  unqryKits.FieldByName('USUARIO_MODIF').AsString    := oUser;
  unqryKits.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmProveedores.unqryKitsBeforeDelete(DataSet: TDataSet);
var
  q : TUniQuery;
begin
  inherited;
  // Cascade en aplicación (no hay FK en BBDD): borrar el detalle del kit.
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'DELETE FROM fza_proveedores_kits_det ' +
      ' WHERE CODIGO_PRV_PRVKITD = :prv ' +
      '   AND CODIGO_PRVKIT_PRVKITD = :kit';
    q.ParamByName('prv').AsString :=
      unqryKits.FieldByName('CODIGO_PRV_PRVKIT').AsString;
    q.ParamByName('kit').AsString :=
      unqryKits.FieldByName('CODIGO_PRVKIT').AsString;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmProveedores.unqryKitsDetBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  if unqryKits.IsEmpty then
    raise Exception.Create('Crea o selecciona un kit antes de añadir tallas.');
  if unqryKits.State in [dsInsert, dsEdit] then
    unqryKits.Post;
end;

procedure TdmProveedores.unqryKitsDetAfterInsert(DataSet: TDataSet);
var
  q      : TUniQuery;
  iOrden : Integer;
begin
  inherited;
  // Orden siguiente con pasos de 10 (huecos para intercalar).
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'SELECT COALESCE(MAX(ORDEN_PRVKITD), 0) + 10 AS NEXT_ORDEN ' +
      '  FROM fza_proveedores_kits_det ' +
      ' WHERE CODIGO_PRV_PRVKITD = :prv ' +
      '   AND CODIGO_PRVKIT_PRVKITD = :kit';
    q.ParamByName('prv').AsString :=
      unqryKits.FieldByName('CODIGO_PRV_PRVKIT').AsString;
    q.ParamByName('kit').AsString :=
      unqryKits.FieldByName('CODIGO_PRVKIT').AsString;
    q.Open;
    iOrden := q.FieldByName('NEXT_ORDEN').AsInteger;
  finally
    FreeAndNil(q);
  end;
  with unqryKitsDet do
  begin
    FieldByName('CODIGO_PRV_PRVKITD').AsString :=
      unqryKits.FieldByName('CODIGO_PRV_PRVKIT').AsString;
    FieldByName('CODIGO_PRVKIT_PRVKITD').AsString :=
      unqryKits.FieldByName('CODIGO_PRVKIT').AsString;
    FieldByName('CANTIDAD_PRVKITD').AsFloat   := 0;
    FieldByName('ORDEN_PRVKITD').AsInteger    := iOrden;
    FieldByName('USUARIO_ALTA').AsString      := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime   := Now;
  end;
end;

procedure TdmProveedores.unqryKitsDetBeforePost(DataSet: TDataSet);
begin
  inherited;
  if Trim(unqryKitsDet.FieldByName('VALOR_DESTINO_PRVKITD').AsString) = '' then
    raise Exception.Create('La fila del kit necesita la talla destino ' +
      '(p. ej. 38, M).');
  unqryKitsDet.FieldByName('USUARIO_MODIF').AsString    := oUser;
  unqryKitsDet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
end;

procedure TdmProveedores.GenerarTallasKitActual;
var
  q   : TUniQuery;
  iAc : Integer;
begin
  if unqryKits.IsEmpty then
    raise Exception.Create('Selecciona o crea un kit primero.');
  if unqryKits.State in [dsInsert, dsEdit] then
    unqryKits.Post;
  iAc := unqryKits.FieldByName('ID_AC_TALLAS_PRVKIT').AsInteger;
  if iAc <= 0 then
    raise Exception.Create('El kit no tiene sistema de tallas. Asigna uno ' +
      'en la columna "Sistema tallas" para poder generar sus tallas.');
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'INSERT IGNORE INTO fza_proveedores_kits_det ' +
      '  (CODIGO_PRV_PRVKITD, CODIGO_PRVKIT_PRVKITD, VALOR_DESTINO_PRVKITD, ' +
      '   CANTIDAD_PRVKITD, ORDEN_PRVKITD, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT :prv, :kit, AV.AV, 0, ACD.ORDEN_ACD, NOW(), :usu, NOW(), :usu ' +
      '  FROM fza_atributos_conjuntos_det ACD ' +
      '  JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
      ' WHERE ACD.ID_AC_ACD = :ac';
    q.ParamByName('prv').AsString :=
      unqryKits.FieldByName('CODIGO_PRV_PRVKIT').AsString;
    q.ParamByName('kit').AsString :=
      unqryKits.FieldByName('CODIGO_PRVKIT').AsString;
    q.ParamByName('usu').AsString := oUser;
    q.ParamByName('ac').AsInteger := iAc;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
  unqryKitsDet.Refresh;
end;

procedure TdmProveedores.GetCodigoAutoProveedor;
begin
  if unqryTablaG.FindField('CODIGO_PRV_PRV').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'PV';
      ExecProc;
      unqryTablaG.FindField('CODIGO_PRV_PRV').AsString :=
        ParamByName('pcont').AsString;
    end;
  end;
    if unqryTablaG.FindField('ORDEN_PRV').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'PO';
      ExecProc;
      unqryTablaG.FindField('ORDEN_PRV').AsString :=
        ParamByName('pcont').AsString;
    end;
  end;
end;

procedure TdmProveedores.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_PRV_PRV').AsString := '0';
  unqryTablaG.FindField('ORDEN_PRV').AsString := '0';
end;

procedure TdmProveedores.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  GetCodigoAutoProveedor;
end;

initialization
  ForceReferenceToClass(TdmProveedores);
end.
