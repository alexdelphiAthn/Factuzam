{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasMovimientos                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera movimientos de salida de stock para facturas de venta.             }
{******************************************************************************}
unit inLibFacturasMovimientos;

interface

uses
  Uni, inLibFacturasServiciosIntf;

type
  TServicioMovimientosFactura = class(
    TInterfacedObject,
    IServicioMovimientosFactura)
  private
    FConexion: TUniConnection;
    procedure ConfigurarInsercion(AProcedimiento: TUniStoredProc);
    procedure InsertarMovimiento(
      AProcedimiento: TUniStoredProc;
      const ASolicitud: TSolicitudMovimientosFactura;
      const ANumeroMovimiento, ALinea, ASku,
      AAlmacen, AArticulo: string;
      ACantidad: Double);
  public
    constructor Create(AConexion: TUniConnection);
    function GenerarSalidas(
      const ASolicitud: TSolicitudMovimientosFactura): Integer;
  end;

implementation

uses
  System.SysUtils, Data.DB, inLibValoresAutomaticos;

constructor TServicioMovimientosFactura.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TServicioMovimientosFactura.ConfigurarInsercion(
  AProcedimiento: TUniStoredProc);
begin
  AProcedimiento.Connection := FConexion;
  AProcedimiento.StoredProcName :=
    'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
  AProcedimiento.Params.Clear;
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_NUMERO_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_TIPO_DOC_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_SERIE_DOC_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_NRO_DOC_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_LINEA_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_CODIGO_EMPRESA_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_CODIGO_ALMACEN_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_CODIGO_ALMACEN_CONTRA_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_CODIGO_UNIDAD_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_TIPO_MOVIMIENTO_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftBCD,
    'p_CANTIDAD_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftBCD,
    'p_PRECIO_MEDIO_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftBCD,
    'p_TOTAL_COSTE_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_USUARIO',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_ALMACEN_DOC',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_NUMOP_DOC',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_CODIGO_CAJA_DOC_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_CODCLIENTE',
    ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_CODARTICULO',
    ptInput);
end;

procedure TServicioMovimientosFactura.InsertarMovimiento(
  AProcedimiento: TUniStoredProc;
  const ASolicitud: TSolicitudMovimientosFactura;
  const ANumeroMovimiento, ALinea, ASku,
  AAlmacen, AArticulo: string;
  ACantidad: Double);
begin
  AProcedimiento.ParamByName('p_NUMERO_MOV').AsString :=
    ANumeroMovimiento;
  AProcedimiento.ParamByName('p_TIPO_DOC_MOV').AsString := 'FC';
  AProcedimiento.ParamByName('p_SERIE_DOC_MOV').AsString :=
    ASolicitud.Serie;
  AProcedimiento.ParamByName('p_NRO_DOC_MOV').AsString :=
    ASolicitud.Numero;
  AProcedimiento.ParamByName('p_LINEA_MOV').AsString := ALinea;
  AProcedimiento.ParamByName('p_CODIGO_EMPRESA_MOV').AsString :=
    ASolicitud.Empresa;
  AProcedimiento.ParamByName('p_CODIGO_ALMACEN_MOV').AsString :=
    AAlmacen;
  AProcedimiento.ParamByName(
    'p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
  AProcedimiento.ParamByName('p_CODIGO_UNIDAD_MOV').AsString := ASku;
  AProcedimiento.ParamByName(
    'p_TIPO_MOVIMIENTO_MOV').AsString := 'S';
  AProcedimiento.ParamByName('p_CANTIDAD_MOV').AsFloat := ACantidad;
  AProcedimiento.ParamByName('p_PRECIO_MEDIO_MOV').AsFloat := 0;
  AProcedimiento.ParamByName('p_TOTAL_COSTE_MOV').AsFloat := 0;
  AProcedimiento.ParamByName('p_USUARIO').AsString :=
    ASolicitud.Usuario;
  AProcedimiento.ParamByName('p_ALMACEN_DOC').AsString := AAlmacen;
  AProcedimiento.ParamByName('p_NUMOP_DOC').AsString :=
    ASolicitud.NumeroOperacion;
  AProcedimiento.ParamByName(
    'p_CODIGO_CAJA_DOC_MOV').AsString := ASolicitud.Caja;
  AProcedimiento.ParamByName('p_CODCLIENTE').AsString :=
    ASolicitud.Cliente;
  AProcedimiento.ParamByName('p_CODARTICULO').AsString := AArticulo;
  AProcedimiento.ExecProc;
end;

function TServicioMovimientosFactura.GenerarSalidas(
  const ASolicitud: TSolicitudMovimientosFactura): Integer;
var
  QryLineas: TUniQuery;
  QryExiste: TUniQuery;
  QryActualizar: TUniQuery;
  Procedimiento: TUniStoredProc;
  Linea: string;
  Sku: string;
  Almacen: string;
  Articulo: string;
  NumeroMovimiento: string;
  Cantidad: Double;
  TransaccionPropia: Boolean;
begin
  Result := 0;
  QryLineas := nil;
  QryExiste := nil;
  QryActualizar := nil;
  Procedimiento := nil;
  TransaccionPropia := not FConexion.InTransaction;
  if TransaccionPropia then
    FConexion.StartTransaction;
  try
    try
      QryLineas := TUniQuery.Create(nil);
      QryExiste := TUniQuery.Create(nil);
      QryActualizar := TUniQuery.Create(nil);
      Procedimiento := TUniStoredProc.Create(nil);
      QryLineas.Connection := FConexion;
      QryLineas.SQL.Text :=
        'SELECT LINEA_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
        '       CODIGO_ART_FACLIN, CANTIDAD_FACLIN, ' +
        '       CODIGO_ALM_FACLIN, NUMERO_MOV_FACLIN ' +
        '  FROM fza_facturas_lineas ' +
        ' WHERE NUMERO_FAC_FACLIN = :numero ' +
        '   AND SERIE_FAC_FACLIN = :serie ' +
        ' ORDER BY LINEA_FACLIN';
      QryLineas.ParamByName('numero').AsString := ASolicitud.Numero;
      QryLineas.ParamByName('serie').AsString := ASolicitud.Serie;
      QryLineas.Open;
      QryExiste.Connection := FConexion;
      QryExiste.SQL.Text :=
        'SELECT NUMERO_MOV ' +
        '  FROM fza_movimientos_almacen ' +
        ' WHERE TIPO_DOC_MOV IN (''FC'', ''VE'') ' +
        '   AND SERIE_DOC_MOV = :serie ' +
        '   AND NUMERO_DOC_MOV = :numero ' +
        '   AND LINEA_MOV = :linea ' +
        ' ORDER BY CASE TIPO_DOC_MOV ' +
        '          WHEN ''VE'' THEN 0 ELSE 1 END, NUMERO_MOV ' +
        ' LIMIT 1';
      QryActualizar.Connection := FConexion;
      QryActualizar.SQL.Text :=
        'UPDATE fza_facturas_lineas ' +
        '   SET NUMERO_MOV_FACLIN = :movimiento, ' +
        '       INSTANTE_MODIF = NOW(), ' +
        '       USUARIO_MODIF = :usuario ' +
        ' WHERE SERIE_FAC_FACLIN = :serie ' +
        '   AND NUMERO_FAC_FACLIN = :numero ' +
        '   AND LINEA_FACLIN = :linea';
      ConfigurarInsercion(Procedimiento);
      QryLineas.First;
      while not QryLineas.Eof do
      begin
        Linea := QryLineas.FieldByName('LINEA_FACLIN').AsString;
        Sku := Trim(
          QryLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString);
        Articulo :=
          QryLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
        Cantidad :=
          QryLineas.FieldByName('CANTIDAD_FACLIN').AsFloat;
        Almacen :=
          QryLineas.FieldByName('CODIGO_ALM_FACLIN').AsString;
        if (Sku <> '') and
           (Cantidad > 0) then
        begin
          NumeroMovimiento := '';
          QryExiste.Close;
          QryExiste.ParamByName('serie').AsString :=
            ASolicitud.Serie;
          QryExiste.ParamByName('numero').AsString :=
            ASolicitud.Numero;
          QryExiste.ParamByName('linea').AsString := Linea;
          QryExiste.Open;
          if not QryExiste.IsEmpty then
          begin
            NumeroMovimiento :=
              QryExiste.FieldByName('NUMERO_MOV').AsString;
          end
          else
          begin
            NumeroMovimiento := ObtenerSiguienteContador(
              FConexion,
              'MV',
              ASolicitud.Usuario);
            InsertarMovimiento(
              Procedimiento,
              ASolicitud,
              NumeroMovimiento,
              Linea,
              Sku,
              Almacen,
              Articulo,
              Cantidad);
            Inc(Result);
          end;
          QryExiste.Close;
          if (NumeroMovimiento <> '') and
             (QryLineas.FieldByName(
               'NUMERO_MOV_FACLIN').AsString <> NumeroMovimiento) then
          begin
            QryActualizar.ParamByName('movimiento').AsString :=
              NumeroMovimiento;
            QryActualizar.ParamByName('usuario').AsString :=
              ASolicitud.Usuario;
            QryActualizar.ParamByName('serie').AsString :=
              ASolicitud.Serie;
            QryActualizar.ParamByName('numero').AsString :=
              ASolicitud.Numero;
            QryActualizar.ParamByName('linea').AsString := Linea;
            QryActualizar.ExecSQL;
          end;
        end;
        QryLineas.Next;
      end;
    finally
      FreeAndNil(QryLineas);
      FreeAndNil(QryExiste);
      FreeAndNil(QryActualizar);
      FreeAndNil(Procedimiento);
    end;
    if TransaccionPropia then
      FConexion.Commit;
  except
    if TransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

end.
