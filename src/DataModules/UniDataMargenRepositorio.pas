{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataMargenRepositorio                                     }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del coste y precio calculados por el modal de margen. }
{******************************************************************************}
unit UniDataMargenRepositorio;

interface

uses
  Uni, inLibMargenPersistenciaIntf;

function CrearRepositorioMargenUniDAC(
  AConexion: TUniConnection): IRepositorioMargen;

implementation

uses
  System.SysUtils;

const
  SQL_GUARDAR_COSTE_SKU =
    'INSERT INTO fza_articulos_skus_costes ' +
    '(CODIGO_UNIDAD_SKU_SKUC, PRECIO_ULT_COMPRA_SKUC, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:p_sku, :p_coste, CURRENT_TIMESTAMP, :p_usuario, :p_usuario) ' +
    'ON DUPLICATE KEY UPDATE ' +
    'PRECIO_ULT_COMPRA_SKUC = VALUES(PRECIO_ULT_COMPRA_SKUC), ' +
    'USUARIO_MODIF = VALUES(USUARIO_MODIF)';
  SQL_GUARDAR_COSTE_ARTICULO =
    'UPDATE fza_articulos_proveedores SET ' +
    'PRECIO_ULT_COMPRA_AP = :p_coste, USUARIO_MODIF = :p_usuario, ' +
    'INSTANTE_MODIF = NOW() WHERE CODIGO_ART_AP = :p_art ' +
    'AND ESPROVEEDORPRINCIPAL_AP = ''S''';
  SQL_GUARDAR_PRECIO_SALIDA =
    'UPDATE fza_articulos_tarifas SET ' +
    'PRECIO_SALIDA_ARTTAR = :p_salida, ' +
    'PRECIO_FINAL_ARTTAR = :p_salida - COALESCE(PRECIO_DTO_ARTTAR, 0), ' +
    'PORCENTAJE_DTO_ARTTAR = CASE WHEN :p_salida > 0 THEN ' +
    '(COALESCE(PRECIO_DTO_ARTTAR, 0) / :p_salida) * 100 ELSE 0 END, ' +
    'USUARIO_MODIF = :p_usuario, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_UNICO_ARTTAR = :p_unico';

type
  TRepositorioMargenUniDAC = class(
    TInterfacedObject,
    IRepositorioMargen)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Guardar(
      const ASolicitud: TSolicitudPersistenciaMargen
    ): TResultadoPersistenciaMargen;
  end;

constructor TRepositorioMargenUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioMargenUniDAC.Guardar(
  const ASolicitud: TSolicitudPersistenciaMargen
): TResultadoPersistenciaMargen;
var
  oConsulta: TUniQuery;
begin
  Result.Guardado := False;
  Result.FaltaProveedorPrincipal := False;
  Result.MensajeError := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      if ASolicitud.CodigoUnidad <> '' then
      begin
        oConsulta.SQL.Text := SQL_GUARDAR_COSTE_SKU;
        oConsulta.ParamByName('p_sku').AsString :=
          ASolicitud.CodigoUnidad;
      end
      else
      begin
        oConsulta.SQL.Text := SQL_GUARDAR_COSTE_ARTICULO;
        oConsulta.ParamByName('p_art').AsString :=
          ASolicitud.CodigoArticulo;
      end;
      oConsulta.ParamByName('p_coste').AsFloat :=
        ASolicitud.PrecioCoste;
      oConsulta.ParamByName('p_usuario').AsString :=
        ASolicitud.Usuario;
      oConsulta.Execute;
      if (ASolicitud.CodigoUnidad = '') and
         (oConsulta.RowsAffected = 0) then
      begin
        Result.FaltaProveedorPrincipal := True;
        FConexion.Rollback;
      end
      else
      begin
        oConsulta.SQL.Text := SQL_GUARDAR_PRECIO_SALIDA;
        oConsulta.ParamByName('p_salida').AsFloat :=
          ASolicitud.PrecioSalida;
        oConsulta.ParamByName('p_usuario').AsString :=
          ASolicitud.Usuario;
        oConsulta.ParamByName('p_unico').AsInteger :=
          ASolicitud.CodigoUnicoTarifa;
        oConsulta.Execute;
        FConexion.Commit;
        Result.Guardado := True;
      end;
    except
      on E: Exception do
      begin
        FConexion.Rollback;
        Result.MensajeError := E.Message;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioMargenUniDAC(
  AConexion: TUniConnection): IRepositorioMargen;
begin
  Result := TRepositorioMargenUniDAC.Create(AConexion);
end;

end.
