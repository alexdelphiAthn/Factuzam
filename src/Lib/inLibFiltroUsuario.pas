{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFiltroUsuario                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Restricción de consulta por empresa/almacén/caja del usuario.             }
{    Lee el parámetro appRestringirEmpAlmCaja y expone helpers para que        }
{    cada pantalla filtre su precarga o la selección de caja.                  }
{******************************************************************************}
unit inLibFiltroUsuario;

interface

// Devuelve True si el usuario actual tiene activo el parámetro
// appRestringirEmpAlmCaja. Los administradores (orootGroup = 'S') quedan
// siempre exentos, igual que en inLibPermisos.
function RestriccionEmpAlmCajaActiva: Boolean;
// Valores a los que queda restringido el usuario. Devuelven '' cuando la
// restricción no está activa o cuando el usuario no tiene ese defecto
// asignado en fza_usuarios (esa dimensión no se filtra).
function EmpresaRestringida: string;
function AlmacenRestringido: string;
function CajaRestringida: string;
// Construye el fragmento SQL ' AND (<col> = ''valor'' OR <col> IS NULL)'
// para inyectar en el WHERE de la precarga de cada pantalla. Se pasa el
// nombre de columna de cada dimensión ('' para omitirla, p. ej. pantallas
// sin caja). El OR IS NULL evita excluir documentos sin esa dimensión
// (p. ej. facturas de mayor con CODIGO_CAJA_FAC NULL).
function SqlFiltroEmpAlmCaja(const AColEmpresa,
                             AColAlmacen,
                             AColCaja: string): string;
// Inyecta AFiltro (fragmentos ' AND col = valor') en el WHERE de nivel
// superior de ASql. Si la SQL no tiene WHERE de nivel superior añade
// ' WHERE 1 = 1' + AFiltro. El punto de inserción es justo antes del
// primer GROUP BY / HAVING / ORDER BY / LIMIT de nivel superior (fuera
// de paréntesis), conservando así el orden de la precarga.
function InyectarFiltroSql(const ASql, AFiltro: string): string;

implementation

uses
  System.SysUtils, inLibGlobalVar, inLibAppParam;

function RestriccionEmpAlmCajaActiva: Boolean;
begin
  // Los administradores nunca quedan restringidos
  if SameText(orootGroup, 'S') then
    Result := False
  else
    Result := (oAppParams <> nil) and
              oAppParams.GetBool('appRestringirEmpAlmCaja', False);
end;

function EmpresaRestringida: string;
begin
  if RestriccionEmpAlmCajaActiva then
    Result := oEmpresa
  else
    Result := '';
end;

function AlmacenRestringido: string;
begin
  if RestriccionEmpAlmCajaActiva then
    Result := oAlmacen
  else
    Result := '';
end;

function CajaRestringida: string;
begin
  if RestriccionEmpAlmCajaActiva then
    Result := oCaja
  else
    Result := '';
end;

function SqlFiltroEmpAlmCaja(const AColEmpresa,
                             AColAlmacen,
                             AColCaja: string): string;

  // Fragmento de una dimensión tolerante a NULL: un documento sin esa
  // dimensión (columna NULL) no se excluye, igual que un defecto vacío
  // del usuario no filtra esa dimensión.
  function Fragmento(const ACol, AValor: string): string;
  begin
    Result := ' AND (' + ACol + ' = ' + QuotedStr(AValor) +
              ' OR ' + ACol + ' IS NULL)';
  end;

begin
  Result := '';
  if not RestriccionEmpAlmCajaActiva then
  begin
    // Sin restricción: fragmento vacío, la precarga no cambia
  end
  else
  begin
    if (AColEmpresa <> '') and (oEmpresa <> '') then
      Result := Result + Fragmento(AColEmpresa, oEmpresa);
    if (AColAlmacen <> '') and (oAlmacen <> '') then
      Result := Result + Fragmento(AColAlmacen, oAlmacen);
    if (AColCaja <> '') and (oCaja <> '') then
      Result := Result + Fragmento(AColCaja, oCaja);
  end;
end;

function InyectarFiltroSql(const ASql, AFiltro: string): string;
var
  sSql, sMayus: string;
  iNivel, i, iCorte: Integer;
  bTieneWhere: Boolean;
  // Comprueba si en la posición APos de sMayus empieza el token AToken
  // como palabra completa (delimitada por espacios / saltos de línea).
  function EsToken(APos: Integer; const AToken: string): Boolean;
  var
    iFin: Integer;
  begin
    Result := False;
    if Copy(sMayus, APos, Length(AToken)) = AToken then
    begin
      iFin := APos + Length(AToken);
      if ((APos = 1) or CharInSet(sMayus[APos - 1],
                                  [' ', #9, #10, #13, ')'])) and
         ((iFin > Length(sMayus)) or CharInSet(sMayus[iFin],
                                  [' ', #9, #10, #13, '('])) then
        Result := True;
    end;
  end;
begin
  if AFiltro = '' then
    Result := ASql
  else
  begin
    // Sin el ';' final por si lo trae (mismo criterio que
    // TfrmMtoGen.PrepararBusquedaExterna).
    sSql := TrimRight(ASql);
    while (sSql <> '') and (sSql[Length(sSql)] = ';') do
      sSql := TrimRight(Copy(sSql, 1, Length(sSql) - 1));
    sMayus := UpperCase(sSql);
    // Recorremos controlando el nivel de paréntesis: solo cuentan los
    // tokens de nivel superior (los de subconsultas se ignoran).
    iNivel := 0;
    iCorte := Length(sSql) + 1;
    bTieneWhere := False;
    i := 1;
    while i <= Length(sMayus) do
    begin
      if sMayus[i] = '''' then
      begin
        // Literal de cadena: saltar hasta la comilla de cierre para que
        // sus paréntesis o palabras clave no afecten al recorrido.
        Inc(i);
        while (i <= Length(sMayus)) and (sMayus[i] <> '''') do
          Inc(i);
      end
      else if sMayus[i] = '(' then
        Inc(iNivel)
      else if sMayus[i] = ')' then
        Dec(iNivel)
      else if iNivel = 0 then
      begin
        if EsToken(i, 'WHERE') then
          bTieneWhere := True
        else if (iCorte > Length(sSql)) and
                (EsToken(i, 'GROUP BY') or EsToken(i, 'HAVING') or
                 EsToken(i, 'ORDER BY') or EsToken(i, 'LIMIT')) then
          iCorte := i;
      end;
      Inc(i);
    end;
    if bTieneWhere then
      Result := Copy(sSql, 1, iCorte - 1) + AFiltro + ' ' +
                Copy(sSql, iCorte, MaxInt)
    else
      Result := Copy(sSql, 1, iCorte - 1) + ' WHERE 1 = 1' + AFiltro + ' ' +
                Copy(sSql, iCorte, MaxInt);
  end;
end;

end.
