{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataComprasSesionesPresentacionRepositorio                 }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Consultas de enlace de los colaboradores de presentacion de sesiones      }
{    de compra.                                                                }
{******************************************************************************}
unit UniDataComprasSesionesPresentacionRepositorio;

interface

uses
  Uni,
  inLibGridTallasInline;

function CrearConsultaModelosProveedorUniDAC(
  AConexion: TUniConnection): TUniQuery;
function ListarConjuntosTallasUniDAC(
  AConexion: TUniConnection): TArray<TOpcionConjuntoTalla>;

implementation

uses
  System.Classes,
  System.SysUtils,
  Data.DB;

const
  SQL_MODELOS_PROVEEDOR =
    'SELECT ap.REF_PROVEEDOR_AP AS REFPRV,' +
    '       ap.CODIGO_ART_AP    AS CODART,' +
    '       a.DESCRIPCION_ART   AS DESCRIPCION,' +
    '       ap.PRECIO_ULT_COMPRA_AP AS PCOMPRA,' +
    '       COALESCE((SELECT acn.NOMBRE_AC' +
    '                   FROM fza_articulos_conjuntos_asign aca' +
    '                   JOIN fza_atributos_conjuntos acn' +
    '                     ON acn.ID_AC = aca.ID_AC_ACA' +
    '                  WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART' +
    '                    AND aca.ID_VA_ACA = ''TAL''' +
    '                  ORDER BY aca.ID_VA_ACA LIMIT 1), '''') AS SISTEMA,' +
    '       COALESCE((SELECT GROUP_CONCAT(DISTINCT av.AV ORDER BY av.AV' +
    '                                     SEPARATOR '', '')' +
    '                   FROM fza_articulos_skus sk' +
    '                   JOIN fza_atributos_sku sa' +
    '                     ON sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU' +
    '                   JOIN fza_atributos_valores av' +
    '                     ON av.ID_AV = sa.ID_AV_SA AND av.ID_VA_AV = ''CO''' +
    '                  WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART' +
    '                    AND sk.ESACTIVO_SKU = ''S''), '''') AS COLORES' +
    '  FROM fza_articulos_proveedores ap' +
    '  JOIN fza_articulos a ON a.CODIGO_ART_ART = ap.CODIGO_ART_AP' +
    '                       AND a.ESACTIVO_ART = ''S''' +
    ' WHERE ap.CODIGO_PRV_AP = :prv' +
    '   AND ap.REF_PROVEEDOR_AP IS NOT NULL' +
    '   AND ap.REF_PROVEEDOR_AP <> ''''' +
    ' GROUP BY ap.REF_PROVEEDOR_AP, ap.CODIGO_ART_AP, a.DESCRIPCION_ART,' +
    '          ap.PRECIO_ULT_COMPRA_AP' +
    ' ORDER BY ap.REF_PROVEEDOR_AP';
  SQL_CONJUNTOS_TALLAS =
    'SELECT AC.ID_AC, AC.NOMBRE_AC, ' +
    '  (SELECT AV.AV FROM fza_atributos_conjuntos_det ACD ' +
    '     JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
    '    WHERE ACD.ID_AC_ACD = AC.ID_AC ' +
    '    ORDER BY ACD.ORDEN_ACD, AV.AV LIMIT 1) AS PRIMERA, ' +
    '  (SELECT AV.AV FROM fza_atributos_conjuntos_det ACD ' +
    '     JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
    '    WHERE ACD.ID_AC_ACD = AC.ID_AC ' +
    '    ORDER BY ACD.ORDEN_ACD DESC, AV.AV DESC LIMIT 1) AS ULTIMA ' +
    '  FROM fza_atributos_conjuntos AC ' +
    ' WHERE AC.ESACTIVO_AC = ''S'' ' +
    '   AND AC.ID_VA_AC = ''TAL'' ' +
    ' ORDER BY AC.NOMBRE_AC';

function CrearConsultaModelosProveedorUniDAC(
  AConexion: TUniConnection): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := AConexion;
    Result.SQL.Text := SQL_MODELOS_PROVEEDOR;
  except
    Result.Free;
    raise;
  end;
end;

function ListarConjuntosTallasUniDAC(
  AConexion: TUniConnection): TArray<TOpcionConjuntoTalla>;
var
  Consulta: TUniQuery;
  Indice: Integer;
begin
  SetLength(Result, 0);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text := SQL_CONJUNTOS_TALLAS;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Indice := Length(Result);
      SetLength(Result, Indice + 1);
      Result[Indice].IdAc := Consulta.FieldByName('ID_AC').AsInteger;
      Result[Indice].Nombre :=
        Consulta.FieldByName('NOMBRE_AC').AsString;
      Result[Indice].Primera :=
        Consulta.FieldByName('PRIMERA').AsString;
      Result[Indice].Ultima :=
        Consulta.FieldByName('ULTIMA').AsString;
      Consulta.Next;
    end;
  finally
    Consulta.Free;
  end;
end;

end.
