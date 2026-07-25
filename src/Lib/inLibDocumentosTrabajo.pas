{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDocumentosTrabajo                                        }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       21/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Operaciones compartidas para Documentos de Trabajo.                       }
{    Permite agregar articulos/SKUs desde stock o desde formularios que ya     }
{    resuelven el articulo activo igual que Ctrl+U / Ctrl+F.                   }
{******************************************************************************}
unit inLibDocumentosTrabajo;

interface

uses
  System.SysUtils, System.Classes, Data.DB, DBAccess, Uni,
  inLibContextoSesionIntf;

type
  TResolverDocTrabajoArtSku = procedure(out ACodArt, ACodSku: string) of object;

  TDocTrabajoLineaOrigen = record
    CodigoArticulo: string;
    CodigoSku: string;
    CodigoAlmacen: string;
    Lote: string;
    DescripcionArticulo: string;
    DescripcionSku: string;
    Origen: string;
    FechaCaducidad: TDateTime;
    CantidadStock: Double;
    Cantidad: Double;
    procedure Clear;
  end;

function AgregarUnidadADocumentoTrabajo(AOwner: TComponent;
                                        AConexion: TUniConnection;
                                        const AContextoSesion:
                                        IContextoSesionAplicacion;
                                        const ALinea: TDocTrabajoLineaOrigen):
                                        Boolean;
function AgregarArticuloActivoADocumentoTrabajo(AOwner: TComponent;
                                                AConexion: TUniConnection;
                                                const AContextoSesion:
                                                IContextoSesionAplicacion;
                                                AResolver:
                                                TResolverDocTrabajoArtSku):
                                                Boolean;

implementation

uses
  Vcl.Dialogs, Vcl.Forms, Winapi.Windows,
  inLibGenBusq, inLibArticulosResolver;

procedure TDocTrabajoLineaOrigen.Clear;
begin
  CodigoArticulo := '';
  CodigoSku := '';
  CodigoAlmacen := '';
  Lote := '';
  DescripcionArticulo := '';
  DescripcionSku := '';
  Origen := '';
  FechaCaducidad := 0;
  CantidadStock := 0;
  Cantidad := 0;
end;

function ConnTrabajo(AConexion: TUniConnection): TUniConnection;
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  Result := AConexion;
end;

function CrearDocumentoTrabajo(AConexion: TUniConnection;
                               const AContextoSesion:
                               IContextoSesionAplicacion;
                               const ATitulo: string): Int64;
var
  q: TUniQuery;
  Identidad: TIdentidadSesion;
  Ubicacion: TUbicacionSesion;
begin
  Result := 0;
  Identidad := AContextoSesion.Identidad;
  Ubicacion := AContextoSesion.Ubicacion;
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConnTrabajo(AConexion);
    q.SQL.Text :=
      'INSERT INTO fza_documentos_trabajo ' +
      '  (TITULO_DTR, TIPO_DTR, ESTADO_DTR, CODIGO_EMP_DTR, ' +
      '   CODIGO_ALM_DTR, USUARIO_DTR, INSTANTE_DOCUMENTO_DTR, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:TITULO, ''GENERAL'', ''ABIERTO'', :EMPRESA, :ALMACEN, ' +
      '   :USUARIO, NOW(), NOW(), :USUARIO_ALTA, :USUARIO_MODIF)';
    q.ParamByName('TITULO').AsString := ATitulo;
    q.ParamByName('EMPRESA').AsString := Ubicacion.Empresa;
    q.ParamByName('ALMACEN').AsString := Ubicacion.Almacen;
    q.ParamByName('USUARIO').AsString := Identidad.Usuario;
    q.ParamByName('USUARIO_ALTA').AsString := Identidad.Usuario;
    q.ParamByName('USUARIO_MODIF').AsString := Identidad.Usuario;
    q.Execute;
    q.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    q.Open;
    if not q.IsEmpty then
    begin
      Result := q.FieldByName('ID').AsLargeInt;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function SeleccionarDocumentoTrabajo(AOwner: TComponent;
                                     AConexion: TUniConnection;
                                     const AContextoSesion:
                                     IContextoSesionAplicacion;
                                     out AIdDtr: Int64): Boolean;
var
  iResp: Integer;
  sTitulo: string;
  sId: string;
  sSql: string;
  frmParent: TCustomForm;
begin
  Result := False;
  AIdDtr := 0;
  frmParent := nil;
  if AOwner is TCustomForm then
  begin
    frmParent := TCustomForm(AOwner);
  end;
  iResp := Application.MessageBox(
    'Si = crear un Documento de Trabajo nuevo.' + sLineBreak +
    'No = agregar a uno abierto existente.',
    'Agregar a Documento de Trabajo',
    MB_YESNOCANCEL + MB_ICONQUESTION + MB_DEFBUTTON2);
  if iResp = IDYES then
  begin
    sTitulo := 'Documento de trabajo ' + FormatDateTime('dd/mm/yyyy hh:nn', Now);
    if InputQuery('Nuevo Documento de Trabajo', 'Titulo', sTitulo) then
    begin
      if Trim(sTitulo) <> '' then
      begin
        AIdDtr := CrearDocumentoTrabajo(AConexion, AContextoSesion,
          Trim(sTitulo));
        Result := AIdDtr > 0;
      end;
    end;
  end
  else if iResp = IDNO then
  begin
    sSql :=
      'SELECT ID_DTR, TITULO_DTR, USUARIO_DTR, ' +
      '       INSTANTE_DOCUMENTO_DTR, ESTADO_DTR ' +
      '  FROM fza_documentos_trabajo ' +
      ' WHERE ESTADO_DTR = ''ABIERTO'' ' +
      '   AND USUARIO_DTR = ' +
      QuotedStr(AContextoSesion.Identidad.Usuario) + ' ' +
      ' ORDER BY INSTANTE_DOCUMENTO_DTR DESC, ID_DTR DESC';
    if TBusquedaUtils.EjecutarBusqueda(AConexion,
                                       'Documentos de Trabajo abiertos',
                                       sSql, 'ID_DTR', sId,
                                       'frmBuscarDocumentosTrabajo',
                                       frmParent) then
    begin
      AIdDtr := StrToInt64Def(sId, 0);
      Result := AIdDtr > 0;
    end;
  end;
end;

function SiguienteLinea(AConexion: TUniConnection; AIdDtr: Int64): string;
var
  q: TUniQuery;
  iLinea: Integer;
begin
  iLinea := 1;
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConnTrabajo(AConexion);
    q.SQL.Text :=
      'SELECT COALESCE(MAX(CAST(LINEA_DTL AS UNSIGNED)), 0) + 1 AS LINEA ' +
      '  FROM fza_documentos_trabajo_lineas ' +
      ' WHERE ID_DTR_DTL = :ID_DTR';
    q.ParamByName('ID_DTR').AsLargeInt := AIdDtr;
    q.Open;
    if not q.IsEmpty then
    begin
      iLinea := q.FieldByName('LINEA').AsInteger;
    end;
  finally
    FreeAndNil(q);
  end;
  Result := Format('%.8d', [iLinea]);
end;

procedure CompletarDatosArticulo(AConexion: TUniConnection;
                                 var ALinea: TDocTrabajoLineaOrigen);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConnTrabajo(AConexion);
    q.SQL.Text :=
      'SELECT a.DESCRIPCION_ART, ' +
      '       (SELECT GROUP_CONCAT(av.AV ORDER BY av.ORDEN_AV ' +
      '               SEPARATOR '' / '') ' +
      '          FROM fza_atributos_sku sa ' +
      '          JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
      '         WHERE sa.CODIGO_UNIDAD_SKU_SA = :SKU) AS DESCRIPCION_SKU ' +
      '  FROM fza_articulos a ' +
      ' WHERE a.CODIGO_ART_ART = :ART';
    q.ParamByName('ART').AsString := ALinea.CodigoArticulo;
    q.ParamByName('SKU').AsString := ALinea.CodigoSku;
    q.Open;
    if not q.IsEmpty then
    begin
      if Trim(ALinea.DescripcionArticulo) = '' then
      begin
        ALinea.DescripcionArticulo := q.FieldByName('DESCRIPCION_ART').AsString;
      end;
      if Trim(ALinea.DescripcionSku) = '' then
      begin
        ALinea.DescripcionSku := q.FieldByName('DESCRIPCION_SKU').AsString;
      end;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure ResolverSkuSiEsUnico(AConexion: TUniConnection;
                               var ALinea: TDocTrabajoLineaOrigen);
var
  oResolver: TArticulosResolver;
  oDatos: TArticuloDatos;
begin
  if (Trim(ALinea.CodigoArticulo) <> '') and (Trim(ALinea.CodigoSku) = '') then
  begin
    oResolver := TArticulosResolver.Create(ConnTrabajo(AConexion));
    try
      oDatos := oResolver.ResolverDatos(ALinea.CodigoArticulo, '',
                                        '', Date, ALinea.CodigoAlmacen);
      if oDatos.Encontrado and (not oDatos.RequiereSku) then
      begin
        ALinea.CodigoSku := oDatos.CodigoSku;
        if Trim(ALinea.DescripcionArticulo) = '' then
        begin
          ALinea.DescripcionArticulo := oDatos.DescripcionArticulo;
        end;
        if Trim(ALinea.DescripcionSku) = '' then
        begin
          ALinea.DescripcionSku := oDatos.DescripcionSku;
        end;
      end;
    finally
      FreeAndNil(oResolver);
    end;
  end;
end;

procedure InsertarLineaDocumentoTrabajo(AConexion: TUniConnection;
                                        const AContextoSesion:
                                        IContextoSesionAplicacion;
                                        AIdDtr: Int64;
                                        const ALinea:
                                        TDocTrabajoLineaOrigen);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConnTrabajo(AConexion);
    q.SQL.Text :=
      'INSERT INTO fza_documentos_trabajo_lineas ' +
      '  (ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
      '   CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
      '   DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
      '   CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
      '   ORIGEN_DTL, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:ID_DTR, :LINEA, :ART, :SKU, :ALM, :LOTE, :CADUCIDAD, ' +
      '   :DESC_ART, :DESC_SKU, :CANTIDAD_STOCK, :CANTIDAD, NOW(), ' +
      '   :ORIGEN, NOW(), :USUARIO_ALTA, :USUARIO_MODIF)';
    q.ParamByName('ID_DTR').AsLargeInt := AIdDtr;
    q.ParamByName('LINEA').AsString := SiguienteLinea(AConexion, AIdDtr);
    q.ParamByName('ART').AsString := ALinea.CodigoArticulo;
    q.ParamByName('SKU').AsString := ALinea.CodigoSku;
    q.ParamByName('ALM').AsString := ALinea.CodigoAlmacen;
    q.ParamByName('LOTE').AsString := ALinea.Lote;
    if ALinea.FechaCaducidad = 0 then
    begin
      q.ParamByName('CADUCIDAD').Clear;
    end
    else
    begin
      q.ParamByName('CADUCIDAD').AsDate := ALinea.FechaCaducidad;
    end;
    q.ParamByName('DESC_ART').AsString := ALinea.DescripcionArticulo;
    q.ParamByName('DESC_SKU').AsString := ALinea.DescripcionSku;
    q.ParamByName('CANTIDAD_STOCK').AsFloat := ALinea.CantidadStock;
    q.ParamByName('CANTIDAD').AsFloat := ALinea.Cantidad;
    q.ParamByName('ORIGEN').AsString := ALinea.Origen;
    q.ParamByName('USUARIO_ALTA').AsString :=
      AContextoSesion.Identidad.Usuario;
    q.ParamByName('USUARIO_MODIF').AsString :=
      AContextoSesion.Identidad.Usuario;
    q.Execute;
  finally
    FreeAndNil(q);
  end;
end;

function AgregarUnidadADocumentoTrabajo(AOwner: TComponent;
                                        AConexion: TUniConnection;
                                        const AContextoSesion:
                                        IContextoSesionAplicacion;
                                        const ALinea: TDocTrabajoLineaOrigen):
                                        Boolean;
var
  rLinea: TDocTrabajoLineaOrigen;
  iIdDtr: Int64;
begin
  Result := False;
  rLinea := ALinea;
  ResolverSkuSiEsUnico(AConexion, rLinea);
  if Trim(rLinea.CodigoArticulo) = '' then
  begin
    raise Exception.Create('No hay articulo activo para agregar.');
  end;
  if Trim(rLinea.CodigoSku) = '' then
  begin
    raise Exception.Create('El articulo tiene varios SKUs. Selecciona una unidad concreta.');
  end;
  CompletarDatosArticulo(AConexion, rLinea);
  if Trim(rLinea.Origen) = '' then
  begin
    rLinea.Origen := 'MANUAL';
  end;
  if SeleccionarDocumentoTrabajo(AOwner, AConexion, AContextoSesion,
    iIdDtr) then
  begin
    InsertarLineaDocumentoTrabajo(AConexion, AContextoSesion, iIdDtr,
      rLinea);
    Application.MessageBox('Unidad agregada al Documento de Trabajo.',
                           'Documento de Trabajo',
                           MB_OK + MB_ICONINFORMATION);
    Result := True;
  end;
end;

function AgregarArticuloActivoADocumentoTrabajo(AOwner: TComponent;
                                                AConexion: TUniConnection;
                                                const AContextoSesion:
                                                IContextoSesionAplicacion;
                                                AResolver:
                                                TResolverDocTrabajoArtSku):
                                                Boolean;
var
  rLinea: TDocTrabajoLineaOrigen;
begin
  rLinea.Clear;
  if Assigned(AResolver) then
  begin
    AResolver(rLinea.CodigoArticulo, rLinea.CodigoSku);
  end;
  rLinea.CodigoAlmacen := AContextoSesion.Ubicacion.Almacen;
  rLinea.CantidadStock := 0;
  rLinea.Cantidad := 1;
  rLinea.Origen := 'MTO';
  Result := AgregarUnidadADocumentoTrabajo(AOwner, AConexion,
    AContextoSesion, rLinea);
end;

end.
