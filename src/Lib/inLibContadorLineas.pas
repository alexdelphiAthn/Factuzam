unit inLibContadorLineas;

{
  Unidad: inLibContadorLineas
  Helper generico para asignar el siguiente numero de LINEA en documentos
  (facturas, sesiones de compra, pedidos, albaranes).

  Patron unificado: la cabecera de cada documento tiene una columna
  CONTADOR_LINEAS_X (X = FAC, SES, PED, ALB) que actua como contador
  monotono. Cada nueva linea pide al helper el siguiente valor y este
  bloquea la cabecera, calcula CONTADOR_X + 10 y actualiza la cabecera
  dentro de la transaccion activa.

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
  CONT_DEVOLUCIONES_COMPRA : TInfoContadorLineas = (
    TablaHdr     : 'fza_devoluciones_compra';
    ColContador  : 'CONTADOR_LINEAS_DEVC';
    ColSerieHdr  : 'SERIE_DEVC';
    ColNumeroHdr : 'NUMERO_DEVC'
  );
  CONT_FACTURAS_COMPRA : TInfoContadorLineas = (
    TablaHdr     : 'fza_facturas_compra';
    ColContador  : 'CONTADOR_LINEAS_FACC';
    ColSerieHdr  : 'SERIE_FACC';
    ColNumeroHdr : 'NUMERO_FACC'
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
  q             : TUniQuery;
  iFilas        : Integer;
  bTransPropia  : Boolean;
begin
  Result := 0;
  if (sSerie = '') or (sNumero = '') then Exit;

  bTransPropia := not inLibGlobalVar.oConn.InTransaction;
  if bTransPropia then
    inLibGlobalVar.oConn.StartTransaction;
  q := TUniQuery.Create(nil);
  try
    try
      q.Connection := inLibGlobalVar.oConn;
      // Bloqueo pesimista de la cabecera: el contador de lineas vive en el
      // propio documento. Si el llamador ya abrio una transaccion, el
      // bloqueo queda dentro de ella.
      q.SQL.Text :=
        'SELECT IFNULL(CAST(NULLIF(CAST(' + Info.ColContador +
        ' AS CHAR), '''') AS UNSIGNED), 0) AS NV ' +
        '  FROM ' + Info.TablaHdr + ' ' +
        ' WHERE ' + Info.ColSerieHdr  + ' = :pserie ' +
        '   AND ' + Info.ColNumeroHdr + ' = :pnumero ' +
        ' FOR UPDATE';
      q.ParamByName('pserie').AsString  := sSerie;
      q.ParamByName('pnumero').AsString := sNumero;
      q.Open;
      try
        if not q.Eof then
          Result := q.FieldByName('NV').AsInteger + 10;
      finally
        q.Close;
      end;

      if Result > 0 then
      begin
        q.SQL.Text :=
          'UPDATE ' + Info.TablaHdr + ' ' +
          '   SET ' + Info.ColContador + ' = :pnuevo ' +
          ' WHERE ' + Info.ColSerieHdr  + ' = :pserie ' +
          '   AND ' + Info.ColNumeroHdr + ' = :pnumero';
        q.ParamByName('pnuevo').AsString  := Format('%.8d', [Result]);
        q.ParamByName('pserie').AsString  := sSerie;
        q.ParamByName('pnumero').AsString := sNumero;
        q.ExecSQL;
        iFilas := q.RowsAffected;
        if iFilas = 0 then
          Result := 0;
      end;

      if bTransPropia and inLibGlobalVar.oConn.InTransaction then
        inLibGlobalVar.oConn.Commit;
    except
      if bTransPropia and inLibGlobalVar.oConn.InTransaction then
        inLibGlobalVar.oConn.Rollback;
      raise;
    end;
  finally
    FreeAndNil(q);
  end;
end;

end.
