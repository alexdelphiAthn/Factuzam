{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigArticulosAtributos                                    }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra las ASIGNACIONES de colores y tallas por artículo. Es decir, para  }
{    cada artículo del origen genera las filas que dicen "este artículo tiene  }
{    estos colores y/o estas tallas" en `fza_articulos_atributos_basicos`.    }
{                                                                              }
{    Mapeo:                                                                    }
{      dbo.ocartcol (Articulo, Color)  → fza_articulos_atributos_basicos       }
{                                       (CODIGO_ART_AAB, ID_AV_AAB)            }
{                                       enlazando con fza_atributos_valores    }
{                                       (ID_VA_AV='CO', AV=UPPER(color))      }
{                                                                              }
{      dbo.ocarttal (Articulo, Talla)  → fza_articulos_atributos_basicos       }
{                                       (ID_VA_AV='TAL', AV=UPPER(talla))     }
{                                                                              }
{    Pre-requisito: deben estar migrados antes los CATALOGOS MAESTROS de      }
{    colores y tallas (inLibMigAtributos). En el orquestador del UI van por   }
{    delante.                                                                  }
{                                                                              }
{    El campo `ID_ATB_AAB` (atributo basico canonico) lo dejamos NULL si no   }
{    encontramos coincidencia exacta por (ID_VA, NormalizarCodigoAtb). Mejor  }
{    NULL que un valor inventado.                                              }
{                                                                              }
{    Volumetria: con 52k articulos y multiples colores/tallas por articulo    }
{    se generan facilmente >300k filas. Usamos batchs por dominio y           }
{    transacciones (las controla el motor). El INSERT individual va por       }
{    parametros para que sea rapido sin SQL Injection.                        }
{                                                                              }
{    Idempotente: la PK (CODIGO_ART_AAB, ID_AV_AAB) ya descarta duplicados   }
{    con INSERT IGNORE. Aqui hacemos pre-check + INSERT para poder contar.   }
{******************************************************************************}
unit inLibMigArticulosAtributos;

interface

uses
  UMigEngine;

// Asigna los colores que cada artículo tiene en el legacy.
procedure MigrarArticulosColores(Eng: TMigEngine; var Stats: TMigStats);

// Asigna las tallas que cada artículo tiene en el legacy.
procedure MigrarArticulosTallas(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

// =========================================================================
//  Helpers
// =========================================================================

// Devuelve el ID_AV de la pareja (ID_VA, AV) o 0 si no existe.
function BuscarIdAV(Eng: TMigEngine; const sIdVa, sAv: string): Integer;
var qLook: TUniQuery;
begin
  qLook := TUniQuery.Create(nil);
  try
    qLook.Connection := Eng.ConDst;
    qLook.SQL.Text   :=
      'SELECT ID_AV FROM fza_atributos_valores ' +
      'WHERE ID_VA_AV = :v AND AV = :av LIMIT 1';
    qLook.ParamByName('v').AsString  := sIdVa;
    qLook.ParamByName('av').AsString := sAv;
    qLook.Open;
    if qLook.IsEmpty then
      Result := 0
    else
      Result := qLook.FieldByName('ID_AV').AsInteger;
  finally
    qLook.Free;
  end;
end;

// Devuelve el ID_ATB del basico canonico (ID_VA_ATB, CODIGO_ATB) o 0 si
// no existe. Para enriquecer fza_articulos_atributos_basicos.ID_ATB_AAB.
function BuscarIdATB(Eng: TMigEngine; const sIdVa, sCodAtb: string): Integer;
var qLook: TUniQuery;
begin
  qLook := TUniQuery.Create(nil);
  try
    qLook.Connection := Eng.ConDst;
    qLook.SQL.Text   :=
      'SELECT ID_ATB FROM fza_atributos_basicos ' +
      'WHERE ID_VA_ATB = :v AND CODIGO_ATB = :c LIMIT 1';
    qLook.ParamByName('v').AsString := sIdVa;
    qLook.ParamByName('c').AsString := sCodAtb;
    qLook.Open;
    if qLook.IsEmpty then
      Result := 0
    else
      Result := qLook.FieldByName('ID_ATB').AsInteger;
  finally
    qLook.Free;
  end;
end;

// Inserta una fila en fza_articulos_atributos_basicos si no existe.
// Devuelve True si insertó.
function InsertarAsignacion(Eng: TMigEngine;
                             const sCodArt: string; iIdAv, iIdAtb: Integer;
                             const sUsuario: string): Boolean;
var qChk, qIns: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_articulos_atributos_basicos ' +
      'WHERE CODIGO_ART_AAB = :a AND ID_AV_AAB = :v';
    qChk.ParamByName('a').AsString  := sCodArt;
    qChk.ParamByName('v').AsInteger := iIdAv;
    qChk.Open;
    if not qChk.IsEmpty then Exit(False);
    qChk.Close;

    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   :=
      'INSERT INTO fza_articulos_atributos_basicos (' +
        'CODIGO_ART_AAB, ID_AV_AAB, ID_ATB_AAB, ' +
        'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES (:a, :v, :b, :ia, :im, :ua, :um)';
    qIns.ParamByName('a').AsString  := sCodArt;
    qIns.ParamByName('v').AsInteger := iIdAv;
    if iIdAtb > 0 then
      qIns.ParamByName('b').AsInteger := iIdAtb
    else
      qIns.ParamByName('b').Clear;
    qIns.ParamByName('ia').AsDateTime := Now;
    qIns.ParamByName('im').AsDateTime := Now;
    qIns.ParamByName('ua').AsString   := sUsuario;
    qIns.ParamByName('um').AsString   := sUsuario;
    qIns.ExecSQL;
    Result := True;
  finally
    qIns.Free;
    qChk.Free;
  end;
end;

// Normaliza un texto a un codigo canonico (mayusculas, _ por espacios).
function NormalizarCodigoAtb(const s: string): string;
var i: Integer; c: Char;
begin
  Result := '';
  for i := 1 to Length(s) do
  begin
    c := s[i];
    case c of
      'A'..'Z', '0'..'9', '_': Result := Result + c;
      'a'..'z':                Result := Result + UpCase(c);
      ' ', '-', '/', '.':      Result := Result + '_';
    end;
  end;
  if Result = '' then Result := 'X';
end;

// =========================================================================
//  MigrarArticulosColores  (ocartcol → fza_articulos_atributos_basicos)
// =========================================================================

procedure MigrarArticulosColores(Eng: TMigEngine; var Stats: TMigStats);
const
  // Filtramos las parejas con texto vacio. ColorBasico tiene la
  // descripcion canonica del color via JOIN con occolor.
  cSelectSrc =
    'SELECT ac.Articulo, ' +
    '       ISNULL(c.Descripcion, ac.Color) AS DescColor ' +
    'FROM dbo.ocartcol ac ' +
    'LEFT JOIN dbo.occolor c ON c.ColorBasico = ac.ColorBasico ' +
    'WHERE LTRIM(RTRIM(ac.Articulo)) <> '''' ' +
    'ORDER BY ac.Articulo, ac.Color';
var
  qSrc: TUniQuery;
  sArt, sDescColor, sAV, sCodAtb: string;
  iIdAv, iIdAtb: Integer;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  try
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocartcol ' +
      'WHERE LTRIM(RTRIM(Articulo)) <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt       := Trim(qSrc.FieldByName('Articulo').AsString);
      sDescColor := Trim(qSrc.FieldByName('DescColor').AsString);
      if (sArt = '') or (sDescColor = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;

      sAV     := UpperCase(sDescColor);
      sCodAtb := NormalizarCodigoAtb(sDescColor);
      iIdAv   := BuscarIdAV(Eng, 'CO', sAV);
      if iIdAv = 0 then
      begin
        Inc(Stats.Errores);
        Eng.Log('  ! color "%s" no esta en fza_atributos_valores ' +
                '(articulo %s)', [sAV, sArt]);
        qSrc.Next;
        Continue;
      end;
      iIdAtb := BuscarIdATB(Eng, 'CO', sCodAtb);
      // iIdAtb=0 es valido: dejamos NULL en ID_ATB_AAB

      try
        if InsertarAsignacion(Eng, sArt, iIdAv, iIdAtb, Eng.Usuario) then
          Inc(Stats.Insertadas)
        else
          Inc(Stats.Saltadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error asignando color "%s" a art "%s": %s',
                  [sAV, sArt, E.Message]);
          raise;
        end;
      end;
      qSrc.Next;
    end;
  finally
    qSrc.Free;
  end;
end;

// =========================================================================
//  MigrarArticulosTallas  (ocarttal → fza_articulos_atributos_basicos)
// =========================================================================

procedure MigrarArticulosTallas(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Articulo, Talla ' +
    'FROM dbo.ocarttal ' +
    'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
    '  AND LTRIM(RTRIM(Talla))    <> '''' ' +
    'ORDER BY Articulo, Orden, Talla';
var
  qSrc: TUniQuery;
  sArt, sTalla, sAV, sCodAtb: string;
  iIdAv, iIdAtb: Integer;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  try
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.ocarttal ' +
      'WHERE LTRIM(RTRIM(Articulo)) <> '''' ' +
      '  AND LTRIM(RTRIM(Talla))    <> '''''));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sArt   := Trim(qSrc.FieldByName('Articulo').AsString);
      sTalla := Trim(qSrc.FieldByName('Talla').AsString);
      if (sArt = '') or (sTalla = '') then
      begin
        Inc(Stats.Saltadas);
        qSrc.Next;
        Continue;
      end;

      sAV     := UpperCase(sTalla);
      sCodAtb := NormalizarCodigoAtb(sTalla);
      iIdAv   := BuscarIdAV(Eng, 'TAL', sAV);
      if iIdAv = 0 then
      begin
        Inc(Stats.Errores);
        Eng.Log('  ! talla "%s" no esta en fza_atributos_valores ' +
                '(articulo %s)', [sAV, sArt]);
        qSrc.Next;
        Continue;
      end;
      iIdAtb := BuscarIdATB(Eng, 'TAL', sCodAtb);

      try
        if InsertarAsignacion(Eng, sArt, iIdAv, iIdAtb, Eng.Usuario) then
          Inc(Stats.Insertadas)
        else
          Inc(Stats.Saltadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error asignando talla "%s" a art "%s": %s',
                  [sAV, sArt, E.Message]);
          raise;
        end;
      end;
      qSrc.Next;
    end;
  finally
    qSrc.Free;
  end;
end;

end.
