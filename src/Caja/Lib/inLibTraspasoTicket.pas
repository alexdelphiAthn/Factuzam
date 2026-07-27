{******************************************************************************}
{                                                                              }
{  Modulo:       inLibTraspasoTicket                                           }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Imprime (o previsualiza si la impresora es 'DEBUG') el ticket de una      }
{    solicitud de traspaso, listando por cada SKU la cantidad pedida y el      }
{    stock en el almacen origen y en el almacen destino. Patron clonado de     }
{    inLibArqueoTicket (TTicketTermico + preview TFormVisualizador).           }
{    Texto en ASCII a proposito para no depender del encoding del .pas.        }
{******************************************************************************}
unit inLibTraspasoTicket;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Uni,
  inLibFTicket, inLibPreviewTicket, inLibDir;

type
  TTraspasoTicket = class
  private
    // Imprime el bloque de una linea: SKU (en negrita), descripcion del
    // articulo y las tres magnitudes (unidades + stock origen/destino) con
    // etiquetas claras. El ticket no lleva precios a proposito.
    class procedure ImprimirLineaSku(ATicket: TTicketTermico;
                                     const ASku, ADescripcion,
                                     AEtiqUds: string; AUds: Double;
                                     const AEtiqOrigen: string; AOrigen: Double;
                                     const AEtiqDestino: string;
                                     ADestino: Double);
  public
    // Imprime/previsualiza el ticket de una solicitud de traspaso ya grabada.
    class procedure ImprimirSolicitud(AConn: TUniConnection;
                                      const ANumero, ASerie: string;
                                      const ANombreImpresora: string = 'DEBUG');
    // Imprime/previsualiza el ticket de un traspaso ya ejecutado (F12 con
    // ticket). Recorre las lineas en memoria (ALineas: campos CODIGO_UNIDAD y
    // CANTIDAD) y por cada SKU calcula el stock en origen y en destino.
    class procedure ImprimirTraspaso(AConn: TUniConnection;
                                     const ADocRef, AOrigen, ADestino,
                                     AEmpleado: string; ALineas: TDataSet;
                                     const ANombreImpresora: string = 'DEBUG');
    // Reimprime el ticket de un traspaso ya grabado leyendo la cabecera de la
    // operacion de caja y sus lineas (movimientos de salida) de la BBDD. Lo usa
    // el boton Reimprimir de la consulta de operaciones (TR/TA).
    class procedure ImprimirTraspasoDesdeBD(AConn: TUniConnection;
                                     const AEmpresa, AAlmacen, ACaja,
                                     ANumOperacion: string;
                                     const ANombreImpresora: string = 'DEBUG';
                                     ARutasPDF: TStrings = nil;
                                     ASoloPDF: Boolean = False);
  end;

implementation

uses
  inLibGlobalVar, inLibFormatoDocumento;

class procedure TTraspasoTicket.ImprimirLineaSku(ATicket: TTicketTermico;
                                   const ASku, ADescripcion,
                                   AEtiqUds: string; AUds: Double;
                                   const AEtiqOrigen: string; AOrigen: Double;
                                   const AEtiqDestino: string;
                                   ADestino: Double);
var
  sDesc: string;
begin
  // SKU destacado para identificar la unidad.
  ATicket.Negrita(True);
  ATicket.EscribirLinea(ASku);
  ATicket.Negrita(False);
  // Descripcion del articulo, recortada al ancho del ticket para no desbordar.
  sDesc := Trim(ADescripcion);
  if Length(sDesc) > N_CHAR_LIN then
    sDesc := Copy(sDesc, 1, N_CHAR_LIN);
  if sDesc <> '' then
    ATicket.EscribirLinea(sDesc);
  // Unidades movidas/pedidas y stock resultante en origen y destino. Sin
  // precios: el coste no aparece en el ticket.
  ATicket.TextoColumnas(AEtiqUds, FormatFloat('0.###', AUds));
  ATicket.TextoColumnas(AEtiqOrigen, FormatFloat('0.###', AOrigen));
  ATicket.TextoColumnas(AEtiqDestino, FormatFloat('0.###', ADestino));
end;

class procedure TTraspasoTicket.ImprimirSolicitud(AConn: TUniConnection;
                                     const ANumero, ASerie: string;
                                     const ANombreImpresora: string);
var
  Ticket: TTicketTermico;
  Q: TUniQuery;
  ComandosESC, RutaPDF, sImpresora: string;
  sOrigen, sDestino, sEmpleado, sEstado: string;
  dFecha: TDateTime;
  bExiste: Boolean;
begin
  if (AConn = nil) or (not AConn.Connected) then
    Exit;
  // Impresora parametrizada (vgerDefPrinter -> oNomImpresoraCaja); si viene
  // vacia, preview.
  sImpresora := ANombreImpresora;
  if Trim(sImpresora) = '' then
    sImpresora := 'DEBUG';
  sOrigen := '';
  sDestino := '';
  sEmpleado := '';
  sEstado := '';
  dFecha := 0;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    // Cabecera de la solicitud
    Q.SQL.Text :=
      'SELECT CODIGO_ALM_ORIGEN_TRSOL, CODIGO_ALM_DESTINO_TRSOL,' +
      '       CODIGO_EMPLEADO_TRSOL, ESTADO_TRSOL, FECHA_TRSOL' +
      '  FROM fza_traspasos_solicitudes' +
      ' WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
    Q.ParamByName('NUM').AsString := ANumero;
    Q.ParamByName('SER').AsString := ASerie;
    Q.Open;
    bExiste := not Q.IsEmpty;
    if bExiste then
    begin
      sOrigen := Q.FieldByName('CODIGO_ALM_ORIGEN_TRSOL').AsString;
      sDestino := Q.FieldByName('CODIGO_ALM_DESTINO_TRSOL').AsString;
      sEmpleado := Q.FieldByName('CODIGO_EMPLEADO_TRSOL').AsString;
      sEstado := Q.FieldByName('ESTADO_TRSOL').AsString;
      dFecha := Q.FieldByName('FECHA_TRSOL').AsDateTime;
    end;
    Q.Close;
    if bExiste then
    begin
      Ticket := TTicketTermico.Create(sImpresora);
      try
        Ticket.Inicializar;
        Ticket.ConfigurarEspanol;
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea('SOLICITUD DE TRASPASO');
        Ticket.EscribirLinea(ASerie + '/' + ANumero);
        Ticket.Negrita(False);
        Ticket.SaltarLineas(1);
        Ticket.Alinear(alIzquierda);
        Ticket.TextoColumnas('Origen:', sOrigen);
        Ticket.TextoColumnas('Destino:', sDestino);
        Ticket.TextoColumnas('Empleado:', sEmpleado);
        Ticket.TextoColumnas('Estado:', sEstado);
        Ticket.TextoColumnas('Fecha:', FormatDateTime('dd/mm/yyyy', dFecha));
        Ticket.LineaSeparadora('-');
        Ticket.EscribirLinea('ARTICULOS');
        Ticket.LineaSeparadora('-');
        // Lineas: por SKU, descripcion del articulo (denormalizada en la
        // propia linea, igual que en los movimientos), cantidad pedida y stock
        // disponible en origen y destino.
        Q.SQL.Text :=
          'SELECT L.CODIGO_UNIDAD_TRSOLLIN AS SKU,' +
          '       COALESCE(L.DESCRIPCION_ARTICULO_TRSOLLIN, '''')' +
          '         AS DESCRIPCION,' +
          '       L.CANTIDAD_PEDIDA_TRSOLLIN AS PED,' +
          '       (SELECT COALESCE(SUM(S.CANTIDAD_STK),0)' +
          '          FROM fza_articulos_stockactual S' +
          '         WHERE S.CODIGO_ALM_STK = :ORI' +
          '           AND S.CODIGO_UNIDAD_STK = L.CODIGO_UNIDAD_TRSOLLIN)' +
          '         AS STK_ORI,' +
          '       (SELECT COALESCE(SUM(S.CANTIDAD_STK),0)' +
          '          FROM fza_articulos_stockactual S' +
          '         WHERE S.CODIGO_ALM_STK = :DES' +
          '           AND S.CODIGO_UNIDAD_STK = L.CODIGO_UNIDAD_TRSOLLIN)' +
          '         AS STK_DES' +
          '  FROM fza_traspasos_solicitudes_lineas L' +
          ' WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUM' +
          '   AND L.SERIE_TRSOL_TRSOLLIN = :SER' +
          ' ORDER BY L.LINEA_TRSOLLIN';
        Q.ParamByName('NUM').AsString := ANumero;
        Q.ParamByName('SER').AsString := ASerie;
        Q.ParamByName('ORI').AsString := sOrigen;
        Q.ParamByName('DES').AsString := sDestino;
        Q.Open;
        while not Q.Eof do
        begin
          // Solicitud: nada se ha movido aun, el stock es la disponibilidad
          // actual en cada almacen (no lleva "tras traspaso").
          ImprimirLineaSku(Ticket,
            Q.FieldByName('SKU').AsString,
            Q.FieldByName('DESCRIPCION').AsString,
            '  Unidades pedidas:', Q.FieldByName('PED').AsFloat,
            '  Stock origen:', Q.FieldByName('STK_ORI').AsFloat,
            '  Stock destino:', Q.FieldByName('STK_DES').AsFloat);
          Q.Next;
        end;
        Q.Close;
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alCentro);
        Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
        Ticket.SaltarLineas(2);
        Ticket.CortarPapel;
        // Vista previa (DEBUG) o impresion real
        ComandosESC := Ticket.ObtenerComandos;
        RutaPDF := GetUserFolderTickets + 'SolTraspaso_' + ASerie + '_' +
                   ANumero + '.pdf';
        ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaPDF,
                                     sImpresora);
      finally
        FreeAndNil(Ticket);
      end;
    end;
  finally
    FreeAndNil(Q);
  end;
end;

class procedure TTraspasoTicket.ImprimirTraspaso(AConn: TUniConnection;
                                   const ADocRef, AOrigen, ADestino,
                                   AEmpleado: string; ALineas: TDataSet;
                                   const ANombreImpresora: string);
var
  Ticket: TTicketTermico;
  QStk: TUniQuery;
  ComandosESC, RutaPDF, sImpresora, sRefArch, sSku: string;
  dPed, dOrg, dDes: Double;
  bm: TBookmark;
  // Stock (suma de lotes) de un SKU en un almacen.
  function StockEn(const AAlm, ASku: string): Double;
  begin
    QStk.Close;
    QStk.ParamByName('ALM').AsString := AAlm;
    QStk.ParamByName('SKU').AsString := ASku;
    QStk.Open;
    Result := QStk.Fields[0].AsFloat;
    QStk.Close;
  end;
begin
  if (AConn = nil) or (not AConn.Connected) or (ALineas = nil) then
    Exit;
  sImpresora := ANombreImpresora;
  if Trim(sImpresora) = '' then
    sImpresora := 'DEBUG';
  QStk := TUniQuery.Create(nil);
  try
    QStk.Connection := AConn;
    QStk.SQL.Text :=
      'SELECT COALESCE(SUM(S.CANTIDAD_STK),0)' +
      '  FROM fza_articulos_stockactual S' +
      ' WHERE S.CODIGO_ALM_STK = :ALM' +
      '   AND S.CODIGO_UNIDAD_STK = :SKU';
    Ticket := TTicketTermico.Create(sImpresora);
    try
      Ticket.Inicializar;
      Ticket.ConfigurarEspanol;
      Ticket.Alinear(alCentro);
      Ticket.Negrita(True);
      Ticket.EscribirLinea('TRASPASO');
      Ticket.EscribirLinea(ADocRef);
      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);
      Ticket.Alinear(alIzquierda);
      Ticket.TextoColumnas('Origen:', AOrigen);
      Ticket.TextoColumnas('Destino:', ADestino);
      Ticket.TextoColumnas('Empleado:', AEmpleado);
      Ticket.TextoColumnas('Fecha:', FormatDateTime('dd/mm/yyyy', Now));
      Ticket.LineaSeparadora('-');
      Ticket.EscribirLinea('ARTICULOS');
      Ticket.LineaSeparadora('-');
      // Recorre las lineas en memoria sin perder el registro actual. El ticket
      // se imprime DESPUES de grabar, asi que el stock leido ya es el estado
      // resultante del traspaso (por eso "tras traspaso").
      bm := ALineas.GetBookmark;
      ALineas.DisableControls;
      try
        ALineas.First;
        while not ALineas.Eof do
        begin
          sSku := ALineas.FieldByName('CODIGO_UNIDAD').AsString;
          if Trim(sSku) <> '' then
          begin
            dPed := ALineas.FieldByName('CANTIDAD').AsFloat;
            dOrg := StockEn(AOrigen, sSku);
            dDes := StockEn(ADestino, sSku);
            ImprimirLineaSku(Ticket, sSku,
              ALineas.FieldByName('DESCRIPCION').AsString,
              '  Unidades:', dPed,
              '  Stock origen tras traspaso:', dOrg,
              '  Stock destino tras traspaso:', dDes);
          end;
          ALineas.Next;
        end;
      finally
        ALineas.GotoBookmark(bm);
        ALineas.FreeBookmark(bm);
        ALineas.EnableControls;
      end;
      Ticket.LineaSeparadora('-');
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
      Ticket.SaltarLineas(2);
      Ticket.CortarPapel;
      // Vista previa (DEBUG) o impresion real. El nombre de archivo no puede
      // llevar separadores: se sustituyen por '_'.
      ComandosESC := Ticket.ObtenerComandos;
      sRefArch := StringReplace(ADocRef, '/', '_', [rfReplaceAll]);
      sRefArch := StringReplace(sRefArch, '\', '_', [rfReplaceAll]);
      RutaPDF := GetUserFolderTickets + 'Traspaso_' + sRefArch + '.pdf';
      ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaPDF,
                                   sImpresora);
    finally
      FreeAndNil(Ticket);
    end;
  finally
    FreeAndNil(QStk);
  end;
end;

class procedure TTraspasoTicket.ImprimirTraspasoDesdeBD(AConn: TUniConnection;
                                   const AEmpresa, AAlmacen, ACaja,
                                   ANumOperacion: string;
                                   const ANombreImpresora: string;
                                   ARutasPDF: TStrings;
                                   ASoloPDF: Boolean);
var
  Ticket: TTicketTermico;
  Q, QStk: TUniQuery;
  ComandosESC, RutaPDF, sImpresora, sRefArch: string;
  sSerie, sNumDoc, sOrigen, sDestino, sEmpleado, sDocRef, sSku: string;
  dPed, dOrg, dDes: Double;
  bExiste: Boolean;
  // Stock (suma de lotes) de un SKU en un almacen.
  function StockEn(const AAlm, ASku: string): Double;
  begin
    QStk.Close;
    QStk.ParamByName('ALM').AsString := AAlm;
    QStk.ParamByName('SKU').AsString := ASku;
    QStk.Open;
    Result := QStk.Fields[0].AsFloat;
    QStk.Close;
  end;
begin
  if (AConn = nil) or (not AConn.Connected) then
    Exit;
  sImpresora := ANombreImpresora;
  if Trim(sImpresora) = '' then
    sImpresora := 'DEBUG';
  sSerie := '';
  sNumDoc := '';
  sOrigen := '';
  sDestino := '';
  sEmpleado := '';
  Q := TUniQuery.Create(nil);
  QStk := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    QStk.Connection := AConn;
    QStk.SQL.Text :=
      'SELECT COALESCE(SUM(S.CANTIDAD_STK),0)' +
      '  FROM fza_articulos_stockactual S' +
      ' WHERE S.CODIGO_ALM_STK = :ALM' +
      '   AND S.CODIGO_UNIDAD_STK = :SKU';
    // Cabecera: la operacion de caja del traspaso.
    Q.SQL.Text :=
      'SELECT SERIE_FAC_OPCAJA, NUMERO_FAC_OPCAJA,' +
      '       CODIGO_ALM_OPCAJA, CODIGO_ALM_CONTRA_OPCAJA,' +
      '       CODIGO_EMPLEADO_OPCAJA' +
      '  FROM fza_caja_operaciones' +
      ' WHERE CODIGO_EMP_OPCAJA = :EMP AND CODIGO_ALM_OPCAJA = :ALM' +
      '   AND CODIGO_CAJA_OPCAJA = :CAJA' +
      '   AND NUMERO_OPERACION_OPCAJA = :NUMOP';
    Q.ParamByName('EMP').AsString := AEmpresa;
    Q.ParamByName('ALM').AsString := AAlmacen;
    Q.ParamByName('CAJA').AsString := ACaja;
    Q.ParamByName('NUMOP').AsString := ANumOperacion;
    Q.Open;
    bExiste := not Q.IsEmpty;
    if bExiste then
    begin
      sSerie := Q.FieldByName('SERIE_FAC_OPCAJA').AsString;
      sNumDoc := Q.FieldByName('NUMERO_FAC_OPCAJA').AsString;
      sOrigen := Q.FieldByName('CODIGO_ALM_OPCAJA').AsString;
      sDestino := Q.FieldByName('CODIGO_ALM_CONTRA_OPCAJA').AsString;
      sEmpleado := Q.FieldByName('CODIGO_EMPLEADO_OPCAJA').AsString;
    end;
    Q.Close;
    if bExiste then
    begin
      if Trim(sSerie + sNumDoc) <> '' then
        sDocRef := FormatearDocumentoEmpresa(AConn, AEmpresa, sSerie, sNumDoc)
      else
        sDocRef := ANumOperacion;
      Ticket := TTicketTermico.Create(sImpresora);
      try
        Ticket.Inicializar;
        Ticket.ConfigurarEspanol;
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea('TRASPASO');
        Ticket.EscribirLinea(sDocRef);
        Ticket.Negrita(False);
        Ticket.SaltarLineas(1);
        Ticket.Alinear(alIzquierda);
        Ticket.TextoColumnas('Origen:', sOrigen);
        Ticket.TextoColumnas('Destino:', sDestino);
        Ticket.TextoColumnas('Empleado:', sEmpleado);
        Ticket.TextoColumnas('Operacion:', ANumOperacion);
        Ticket.LineaSeparadora('-');
        Ticket.EscribirLinea('ARTICULOS');
        Ticket.LineaSeparadora('-');
        // Lineas: movimientos de salida (la salida del origen). La descripcion
        // viene denormalizada en el propio movimiento (DESCRIPCION_ARTICULO_MOV).
        Q.SQL.Text :=
          'SELECT CODIGO_UNIDAD_MOV, CANTIDAD_MOV,' +
          '       COALESCE(DESCRIPCION_ARTICULO_MOV, '''') AS DESCRIPCION' +
          '  FROM fza_movimientos_almacen' +
          ' WHERE CODIGO_EMP_MOV = :EMP AND CODIGO_ALM_DOC_MOV = :ALM' +
          '   AND CODIGO_CAJA_DOC_MOV = :CAJA' +
          '   AND NUMERO_OPERACION_DOC_MOV = :NUMOP' +
          '   AND TIPO_MOV = ''S''' +
          ' ORDER BY LINEA_MOV';
        Q.ParamByName('EMP').AsString := AEmpresa;
        Q.ParamByName('ALM').AsString := AAlmacen;
        Q.ParamByName('CAJA').AsString := ACaja;
        Q.ParamByName('NUMOP').AsString := ANumOperacion;
        Q.Open;
        while not Q.Eof do
        begin
          sSku := Q.FieldByName('CODIGO_UNIDAD_MOV').AsString;
          dPed := Q.FieldByName('CANTIDAD_MOV').AsFloat;
          dOrg := StockEn(sOrigen, sSku);
          dDes := StockEn(sDestino, sSku);
          // Reimpresion: el stock es el actual de cada almacen (puede haber
          // variado por movimientos posteriores), por eso "actual".
          ImprimirLineaSku(Ticket, sSku,
            Q.FieldByName('DESCRIPCION').AsString,
            '  Unidades:', dPed,
            '  Stock origen actual:', dOrg,
            '  Stock destino actual:', dDes);
          Q.Next;
        end;
        Q.Close;
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alCentro);
        Ticket.EscribirLinea(FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
        Ticket.SaltarLineas(2);
        Ticket.CortarPapel;
        ComandosESC := Ticket.ObtenerComandos;
        sRefArch := StringReplace(sDocRef, '/', '_', [rfReplaceAll]);
        sRefArch := StringReplace(sRefArch, '\', '_', [rfReplaceAll]);
        RutaPDF := GetUserFolderTickets + 'Traspaso_' + sRefArch + '.pdf';
        ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaPDF,
                                     sImpresora, ASoloPDF);
        if Assigned(ARutasPDF) and FileExists(RutaPDF) then
          ARutasPDF.Add(RutaPDF);
      finally
        FreeAndNil(Ticket);
      end;
    end;
  finally
    FreeAndNil(QStk);
    FreeAndNil(Q);
  end;
end;

end.
