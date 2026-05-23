{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranesCompra                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de albaranes de COMPRA.                                       }
{    Espejo simplificado de UniDataAlbaranes adaptado a documentos de          }
{    compra (proveedor en lugar de cliente, precio de compra en lugar          }
{    de venta). Sin generacion de movimientos de stock ni de factura           }
{    en esta version inicial: se anadiran en hitos posteriores.                }
{******************************************************************************}
unit UniDataAlbaranesCompra;

interface

uses
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser, inMtoPrincipal;

type
  TdmAlbaranesCompra = class(TdmBase)
    unqryAlbaranesCompraLineas: TUniQuery;
    dsAlbaranesCompraLineas:    TDataSource;
    unqryEmpDataAlbc:           TUniQuery;
    unqryPrvDataAlbc:           TUniQuery;
    unqryArtDataLinAlbc:        TUniQuery;
    unqrySkusAlbc:              TUniQuery;
    unstrdprcGetContadorAlbc:   TUniStoredProc;
    // Definicion de atributos del articulo padre (para columnas
    // dinamicas ATTR1..ATTR5 en modo "atributo por columna").
    unqryDefArticuloAlbc:       TUniQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasAfterPost(DataSet: TDataSet);
  public
    procedure GetCodigoAutoAlbaranCompra;
    procedure CalcularTotalesAlbaranCompra;
    procedure OpenTables;
    // Override: abre las queries detalle tras unqryTablaG. Llamada
    // desde TfrmMtoGen.AbrirTablaPrincipalAsync.
    procedure AbrirDetalles; override;
  end;

implementation

uses
  inLibGlobalVar, inLibLog, System.Diagnostics,
  inMtoAlbaranesCompra;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmAlbaranesCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection                := inLibGlobalVar.oConn;
  unqryAlbaranesCompraLineas.Connection := inLibGlobalVar.oConn;
  unqryEmpDataAlbc.Connection           := inLibGlobalVar.oConn;
  unqryPrvDataAlbc.Connection           := inLibGlobalVar.oConn;
  unqryArtDataLinAlbc.Connection        := inLibGlobalVar.oConn;
  unqrySkusAlbc.Connection              := inLibGlobalVar.oConn;
  unstrdprcGetContadorAlbc.Connection   := inLibGlobalVar.oConn;
  unqryDefArticuloAlbc.Connection       := inLibGlobalVar.oConn;
  // Master-detail server-side: el WHERE del SQL toma los valores de
  // dsTablaG (master), evitando descargar fza_albaranes_compra_lineas
  // entera y filtrar en cliente.
  unqryAlbaranesCompraLineas.MasterSource :=
    (GetOwnerForm<TfrmMtoAlbaranesCompra>).dsTablaG;
end;

procedure TdmAlbaranesCompra.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryAlbaranesCompraLineas) and
     unqryAlbaranesCompraLineas.Active then
    unqryAlbaranesCompraLineas.Close;
  inherited;
end;

procedure TdmAlbaranesCompra.OpenTables;
begin
  // Delegamos en AbrirDetalles para unificar logging y cronometro.
  AbrirDetalles;
end;

procedure TdmAlbaranesCompra.AbrirDetalles;
const
  TAG = 'AlbaranesCompra.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
  var
    swQ: TStopwatch;
  begin
    if qry.Active then Exit;
    swQ := TStopwatch.StartNew;
    try
      qry.Open;
      inLibLog.Log.LogPerf(TAG, Nombre + ' OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG,
          Nombre + ' ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;

var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  AbrirConTiempo(unqryAlbaranesCompraLineas,
                 'unqryAlbaranesCompraLineas');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmAlbaranesCompra.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('NUMERO_ALBC').AsString := '0';
    if FindField('SERIE_ALBC') <> nil then
      FieldByName('SERIE_ALBC').AsString := 'C1';
    FieldByName('FECHA_ALBC').AsDateTime := Date;
    if FindField('ESTADO_ALBC') <> nil then
      FieldByName('ESTADO_ALBC').AsString := 'ABIERTO';
    FieldByName('CODIGO_EMP_ALBC').AsString := '0';
    FieldByName('CODIGO_PRV_ALBC').AsString := '0';
  end;
end;

procedure TdmAlbaranesCompra.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if (unqryTablaG.FieldByName('NUMERO_ALBC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_ALBC').AsString = '') then
    GetCodigoAutoAlbaranCompra;
  CalcularTotalesAlbaranCompra;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
begin
  inherited;
  with unqryAlbaranesCompraLineas do
  begin
    FieldByName('NUMERO_ALBC_ALBCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
    FieldByName('SERIE_ALBC_ALBCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_ALBC').AsString;
    FieldByName('CANTIDAD_ALBCLIN').AsFloat := 1;
    if FindField('ESFACTURADA_ALBCLIN') <> nil then
      FieldByName('ESFACTURADA_ALBCLIN').AsString := 'N';
  end;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasBeforePost(
                                                       DataSet: TDataSet);
var
  sSku, sArt: string;
begin
  inherited;
  with unqryAlbaranesCompraLineas do
  begin
    if (FindField('CANTIDAD_ALBCLIN') <> nil) and
       (FindField('PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN') <> nil) and
       (FindField('TOTAL_ALBCLIN') <> nil) then
      FieldByName('TOTAL_ALBCLIN').AsFloat :=
        FieldByName('CANTIDAD_ALBCLIN').AsFloat *
        FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN').AsFloat;

    // Si el usuario tecleo un SKU pero no el articulo, lo deducimos
    // consultando fza_articulos_skus (mismo patron que en venta).
    if (FindField('CODIGO_UNIDAD_ALBCLIN') <> nil) and
       (FindField('CODIGO_ART_ALBCLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_ALBCLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_ALBCLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusAlbc.Close;
        unqrySkusAlbc.ParamByName('pSKU').AsString := sSku;
        unqrySkusAlbc.Open;
        if not unqrySkusAlbc.Eof then
          FieldByName('CODIGO_ART_ALBCLIN').AsString :=
            unqrySkusAlbc.FieldByName('CODIGO_ART_SKU').AsString;
        unqrySkusAlbc.Close;
      end;
    end;
  end;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterPost(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesAlbaranCompra;
end;

procedure TdmAlbaranesCompra.GetCodigoAutoAlbaranCompra;
begin
  with unstrdprcGetContadorAlbc do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    ParamByName('pserie').AsString :=
      unqryTablaG.FieldByName('SERIE_ALBC').AsString;
    ParamByName('ptipodoc').AsString := 'AB';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_ALBC').AsString;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_ALBC').AsString :=
      ParamByName('pcont').AsString;
  end;
end;

procedure TdmAlbaranesCompra.CalcularTotalesAlbaranCompra;
var
  fBase, fIva, fTotal, fPorIva: Double;
  bk: TBookmark;
begin
  if not unqryAlbaranesCompraLineas.Active then Exit;
  fBase  := 0;
  fIva   := 0;
  fTotal := 0;
  bk := unqryAlbaranesCompraLineas.GetBookmark;
  try
    unqryAlbaranesCompraLineas.DisableControls;
    unqryAlbaranesCompraLineas.First;
    while not unqryAlbaranesCompraLineas.Eof do
    begin
      fPorIva := unqryAlbaranesCompraLineas.
                   FieldByName('PORCENTAJE_IVA_ALBCLIN').AsFloat;
      fTotal  := unqryAlbaranesCompraLineas.
                   FieldByName('TOTAL_ALBCLIN').AsFloat;
      fBase   := fBase + fTotal;
      fIva    := fIva  + (fTotal * fPorIva / 100);
      unqryAlbaranesCompraLineas.Next;
    end;
  finally
    if unqryAlbaranesCompraLineas.BookmarkValid(bk) then
      unqryAlbaranesCompraLineas.GotoBookmark(bk);
    unqryAlbaranesCompraLineas.FreeBookmark(bk);
    unqryAlbaranesCompraLineas.EnableControls;
  end;
  if not (unqryTablaG.State in dsEditModes) then
    unqryTablaG.Edit;
  unqryTablaG.FieldByName('TOTAL_BASES_ALBC').AsFloat     := fBase;
  unqryTablaG.FieldByName('TOTAL_IMPUESTOS_ALBC').AsFloat := fIva;
  unqryTablaG.FieldByName('TOTAL_LIQUIDO_ALBC').AsFloat   := fBase + fIva;
end;

end.
