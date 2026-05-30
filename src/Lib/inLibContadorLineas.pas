unit inLibContadorLineas;

{
  Unidad: inLibContadorLineas
  Helper generico para asignar el siguiente numero de LINEA en documentos
  (facturas, sesiones de compra, pedidos, albaranes).

  Patron unificado: la cabecera de cada documento tiene una columna
  CONTADOR_LINEAS_X (X = FAC, SES, PED, ALB) que actua como contador
  monotono. Cada nueva linea pide al helper el siguiente valor y este
  hace un UPDATE atomico sobre la cabecera (CONTADOR_X += 10) usando el
  truco de LAST_INSERT_ID() para devolver el nuevo valor sin riesgo de
  carrera con otros clientes.

  Equivalente generico al SP PRC_FNC_GET_NEXT_LINEA_FACTURA que ya existia
  solo para facturas; lo sustituye en sesiones desde inicio y queda
  disponible para migrar pedidos / albaranes / facturas cuando interese.

  El campo CONTADOR_LINEAS_X puede ser varchar (FAC/PED/ALB) o int (SES);
  el CAST(... AS UNSIGNED) en el UPDATE absorbe la diferencia.
}

interface

type
  TInfoContadorLineas = record
    TablaHdr     : string;
    ColContador  : string;
    ColSerieHdr  : string;
    ColNumeroHdr : string;
  end;

const
  CONT_FACTURAS : TInfoContadorLineas = (
    TablaHdr     : 'fza_facturas';
    ColContador  : 'CONTADOR_LINEAS_FAC';
    ColSerieHdr  : 'SERIE_FAC';
    ColNumeroHdr : 'NUMERO_FAC'
  );
  CONT_SESIONES : TInfoContadorLineas = (
    TablaHdr     : 'fza_compras_sesiones';
    ColContador  : 'CONTADOR_LINEAS_SES';
    ColSerieHdr  : 'SERIE_SES';
    ColNumeroHdr : 'NUMERO_SES'
  );
  CONT_PEDIDOS : TInfoContadorLineas = (
    TablaHdr     : 'fza_pedidos';
    ColContador  : 'CONTADOR_LINEAS_PED';
    ColSerieHdr  : 'SERIE_PED';
    ColNumeroHdr : 'NUMERO_PED'
  );
  CONT_ALBARANES : TInfoContadorLineas = (
    TablaHdr     : 'fza_albaranes';
    ColContador  : 'CONTADOR_LINEAS_ALB';
    ColSerieHdr  : 'SERIE_ALB';
    ColNumeroHdr : 'NUMERO_ALB'
  );
  CONT_ALBARANES_COMPRA : TInfoContadorLineas = (
    TablaHdr     : 'fza_albaranes_compra';
    ColContador  : 'CONTADOR_LINEAS_ALBC';
    ColSerieHdr  : 'SERIE_ALBC';
    ColNumeroHdr : 'NUMERO_ALBC'
  );
  CONT_PEDIDOS_COMPRA : TInfoContadorLineas = (
    TablaHdr     : 'fza_pedidos_compra';
    ColContador  : 'CONTADOR_LINEAS_PEDC';
    ColSerieHdr  : 'SERIE_PEDC';
    ColNumeroHdr : 'NUMERO_PEDC'
  );

// Devuelve la siguiente LINEA libre para el documento (sSerie, sNumero) y
// actualiza CONTADOR_LINEAS_X en BD atomicamente al mismo valor devuelto.
// Devuelve 0 si la cabecera no existe (caller decide fallback).
function GetSiguienteLineaDoc(
  const Info: TInfoContadorLineas;
  const sSerie, sNumero: string
): Integer;

implementation

uses
  System.SysUtils, Uni,
  inLibGlobalVar;

function GetSiguienteLineaDoc(
  const Info: TInfoContadorLineas;
  const sSerie, sNumero: string
): Integer;
var
  q       : TUniQuery;
  iFilas  : Integer;
begin
  Result := 0;
  if (sSerie = '') or (sNumero = '') then Exit;

  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    // UPDATE atomico: CONTADOR_X = CAST(CONTADOR_X AS UNSIGNED) + 10. El
    // truco LAST_INSERT_ID(expr) guarda 'expr' en la variable session-scoped
    // LAST_INSERT_ID, que recuperamos justo despues en la misma conexion.
    // Asi obtenemos el nuevo valor sin condiciones de carrera con otros
    // clientes (cada conexion tiene su propio LAST_INSERT_ID).
    q.SQL.Text :=
      'UPDATE ' + Info.TablaHdr + ' ' +
      '   SET ' + Info.ColContador + ' = LAST_INSERT_ID(' +
      '             IFNULL(CAST(' + Info.ColContador + ' AS UNSIGNED), 0) + 10' +
      '         ) ' +
      ' WHERE ' + Info.ColSerieHdr  + ' = :pserie ' +
      '   AND ' + Info.ColNumeroHdr + ' = :pnumero';
    q.ParamByName('pserie').AsString  := sSerie;
    q.ParamByName('pnumero').AsString := sNumero;
    q.ExecSQL;
    iFilas := q.RowsAffected;
    if iFilas = 0 then Exit;

    q.SQL.Text := 'SELECT LAST_INSERT_ID() AS NV';
    q.Open;
    try
      Result := q.FieldByName('NV').AsInteger;
    finally
      q.Close;
    end;
  finally
    FreeAndNil(q);
  end;
end;

end.
