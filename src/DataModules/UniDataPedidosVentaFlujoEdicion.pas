{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosVentaFlujoEdicion                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptación de datasets para editar líneas de pedidos de venta.            }
{******************************************************************************}
unit UniDataPedidosVentaFlujoEdicion;

interface

uses
  System.SysUtils, Data.DB,
  inLibPedidosVentaPresentacionReglas;

procedure InicializarLineaPedidoVenta(
  ADataSet, ACabecera: TDataSet;
  const AUsuario: string;
  AInstante: TDateTime);
procedure DesempaquetarAtributosPedidoVenta(ADataSet: TDataSet);
procedure AplicarEstadoLineaPedidoVenta(
  ADataSet: TDataSet;
  const AEstado: TEstadoLineaPedidoVenta);

implementation

procedure AsignarCadenaSiExiste(
  ADataSet: TDataSet;
  const ACampo, AValor: string);
begin
  if ADataSet.FindField(ACampo) <> nil then
    ADataSet.FieldByName(ACampo).AsString := AValor;
end;

procedure AsignarEnteroSiExiste(
  ADataSet: TDataSet;
  const ACampo: string;
  AValor: Integer);
begin
  if ADataSet.FindField(ACampo) <> nil then
    ADataSet.FieldByName(ACampo).AsInteger := AValor;
end;

procedure AsignarNumeroSiExiste(
  ADataSet: TDataSet;
  const ACampo: string;
  AValor: Double);
begin
  if ADataSet.FindField(ACampo) <> nil then
    ADataSet.FieldByName(ACampo).AsFloat := AValor;
end;

procedure InicializarIdentidadLinea(
  ADataSet, ACabecera: TDataSet);
var
  i: Integer;
begin
  ADataSet.FieldByName('LINEA_PEDLIN').AsString := '0000';
  AsignarCadenaSiExiste(ADataSet, 'CODIGO_UNIDAD_PEDLIN', '');
  AsignarEnteroSiExiste(ADataSet, 'NUM_ATRIBUTOS_PEDLIN', 0);
  AsignarEnteroSiExiste(ADataSet, 'ID_AC_PIVOT_PEDLIN', 0);
  for i := 1 to 5 do
  begin
    AsignarCadenaSiExiste(
      ADataSet, 'ATTR' + IntToStr(i) + '_VALOR_PEDLIN', '');
    AsignarCadenaSiExiste(
      ADataSet, 'ATTR' + IntToStr(i) + '_NOMBRE_PEDLIN', '');
  end;
  ADataSet.FieldByName('NUMERO_PED_PEDLIN').AsString :=
    ACabecera.FieldByName('NUMERO_PED').AsString;
  ADataSet.FieldByName('SERIE_PED_PEDLIN').AsString :=
    ACabecera.FieldByName('SERIE_PED').AsString;
end;

procedure InicializarCantidadesLinea(ADataSet: TDataSet);
begin
  ADataSet.FieldByName('CANTIDAD_PEDLIN').AsFloat := 1;
  AsignarNumeroSiExiste(ADataSet, 'CANTIDAD_ENTREGADA_PEDLIN', 0);
  AsignarNumeroSiExiste(ADataSet, 'CANTIDAD_A_ALBARANAR_PEDLIN', 0);
  AsignarNumeroSiExiste(ADataSet, 'CANTIDAD_PENDIENTE_PEDLIN', 1);
  AsignarCadenaSiExiste(ADataSet, 'ESENTREGADA_PEDLIN', 'N');
end;

procedure InicializarContextoLinea(
  ADataSet, ACabecera: TDataSet;
  const AUsuario: string;
  AInstante: TDateTime);
begin
  if ADataSet.FindField('CODIGO_TAR_PEDLIN') <> nil then
    ADataSet.FieldByName('CODIGO_TAR_PEDLIN').AsString :=
      ACabecera.FieldByName(
        'TARIFA_ARTICULO_CLIENTE_PED').AsString;
  if ADataSet.FindField('ESIMP_INCL_TARIFA_PEDLIN') <> nil then
    ADataSet.FieldByName('ESIMP_INCL_TARIFA_PEDLIN').AsString :=
      ACabecera.FieldByName(
        'ESIMP_INCL_TARIFA_CLIENTE_PED').AsString;
  if ACabecera.FindField('CODIGO_ALM_PED') <> nil then
    AsignarCadenaSiExiste(
      ADataSet,
      'CODIGO_ALMACEN_PEDLIN',
      ACabecera.FieldByName('CODIGO_ALM_PED').AsString);
  AsignarCadenaSiExiste(ADataSet, 'USUARIO_ALTA', AUsuario);
  if ADataSet.FindField('INSTANTE_ALTA') <> nil then
    ADataSet.FieldByName('INSTANTE_ALTA').AsDateTime := AInstante;
  AsignarCadenaSiExiste(ADataSet, 'USUARIO_MODIF', AUsuario);
  if ADataSet.FindField('INSTANTE_MODIF') <> nil then
    ADataSet.FieldByName('INSTANTE_MODIF').AsDateTime := AInstante;
end;

procedure InicializarLineaPedidoVenta(
  ADataSet, ACabecera: TDataSet;
  const AUsuario: string;
  AInstante: TDateTime);
begin
  InicializarIdentidadLinea(ADataSet, ACabecera);
  InicializarCantidadesLinea(ADataSet);
  InicializarContextoLinea(ADataSet, ACabecera, AUsuario, AInstante);
end;

function DebeSincronizarAtributos(
  ADataSet: TDataSet;
  const APartes: TArray<string>): Boolean;
var
  i: Integer;
  sEsperado: string;
begin
  Result := ADataSet.FieldByName(
    'NUM_ATRIBUTOS_PEDLIN').AsInteger <> Length(APartes) - 1;
  for i := 1 to 5 do
  begin
    if i < Length(APartes) then
      sEsperado := APartes[i]
    else
      sEsperado := '';
    if Trim(ADataSet.FieldByName('ATTR' + IntToStr(i) +
       '_VALOR_PEDLIN').AsString) <> sEsperado then
      Result := True;
  end;
end;

procedure SincronizarAtributosLinea(
  ADataSet: TDataSet;
  const APartes: TArray<string>);
var
  i: Integer;
begin
  ADataSet.Edit;
  ADataSet.FieldByName('NUM_ATRIBUTOS_PEDLIN').AsInteger :=
    Length(APartes) - 1;
  for i := 1 to 5 do
  begin
    if i < Length(APartes) then
      ADataSet.FieldByName('ATTR' + IntToStr(i) +
        '_VALOR_PEDLIN').AsString := APartes[i]
    else
      ADataSet.FieldByName('ATTR' + IntToStr(i) +
        '_VALOR_PEDLIN').AsString := '';
  end;
  ADataSet.Post;
end;

procedure DesempaquetarAtributosPedidoVenta(ADataSet: TDataSet);
var
  aPartes: TArray<string>;
  oMarcador: TBookmark;
  sSku: string;
begin
  if ADataSet.Active and not ADataSet.IsEmpty then
  begin
    oMarcador := ADataSet.GetBookmark;
    ADataSet.DisableControls;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        sSku := ADataSet.FieldByName('CODIGO_UNIDAD_PEDLIN').AsString;
        aPartes := sSku.Split(['/']);
        if (Length(aPartes) > 1) and
           DebeSincronizarAtributos(ADataSet, aPartes) then
          SincronizarAtributosLinea(ADataSet, aPartes);
        ADataSet.Next;
      end;
      if ADataSet.BookmarkValid(oMarcador) then
        ADataSet.GotoBookmark(oMarcador);
    finally
      ADataSet.EnableControls;
      ADataSet.FreeBookmark(oMarcador);
    end;
  end;
end;

procedure AplicarEstadoLineaPedidoVenta(
  ADataSet: TDataSet;
  const AEstado: TEstadoLineaPedidoVenta);
begin
  AsignarNumeroSiExiste(
    ADataSet,
    'CANTIDAD_A_ALBARANAR_PEDLIN',
    AEstado.CantidadAAlbaranar);
  AsignarNumeroSiExiste(
    ADataSet,
    'CANTIDAD_PENDIENTE_PEDLIN',
    AEstado.CantidadPendiente);
  if AEstado.EsEntregada then
    AsignarCadenaSiExiste(ADataSet, 'ESENTREGADA_PEDLIN', 'S')
  else
    AsignarCadenaSiExiste(ADataSet, 'ESENTREGADA_PEDLIN', 'N');
end;

end.
