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
  inLibFTicket, inMtoPreviewTicket, inLibDir;

type
  TTraspasoTicket = class
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
                                     const ANombreImpresora: string = 'DEBUG');
  end;

implementation

uses
  inLibGlobalVar;

class procedure TTraspasoTicket.ImprimirSolicitud(AConn: TUniConnection;
                                     const ANumero, ASerie: string;
                                     const ANombreImpresora: string);
var
  Ticket: TTicketTermico;
  Preview: TFormVisualizador;
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
        Ticket.TextoColumnas('Origen (a quien pido):', sOrigen);
        Ticket.TextoColumnas('Destino (yo):', sDestino);
        Ticket.TextoColumnas('Empleado:', sEmpleado);
        Ticket.TextoColumnas('Estado:', sEstado);
        Ticket.TextoColumnas('Fecha:', FormatDateTime('dd/mm/yyyy', dFecha));
        Ticket.LineaSeparadora('-');
        Ticket.EscribirLinea('SKU / Ped(idas) / Org(en) / Des(tino)');
        Ticket.LineaSeparadora('-');
        // Lineas: por SKU, cantidad pedida y stock en origen y destino
        Q.SQL.Text :=
          'SELECT L.CODIGO_UNIDAD_TRSOLLIN AS SKU,' +
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
          Ticket.EscribirLinea(Q.FieldByName('SKU').AsString);
          Ticket.EscribirLinea(Format('  Ped:%s  Org:%s  Des:%s',
            [FormatFloat('0.###', Q.FieldByName('PED').AsFloat),
             FormatFloat('0.###', Q.FieldByName('STK_ORI').AsFloat),
             FormatFloat('0.###', Q.FieldByName('STK_DES').AsFloat)]));
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
        Preview := TFormVisualizador.Create(nil);
        try
          Preview.Hide;
          Preview.FRutaPDFReal := RutaPDF;
          Preview.CargarYMostrar(ComandosESC);
          Preview.ExportarAPDF(ComandosESC, RutaPDF);
          if UpperCase(sImpresora) = 'DEBUG' then
            Preview.ShowModal
          else
            Ticket.Imprimir;
        finally
          FreeAndNil(Preview);
        end;
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
  Preview: TFormVisualizador;
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
      Ticket.EscribirLinea('SKU / Uds / Org(en) / Des(tino)');
      Ticket.LineaSeparadora('-');
      // Recorre las lineas en memoria sin perder el registro actual.
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
            Ticket.EscribirLinea(sSku);
            Ticket.EscribirLinea(Format('  Uds:%s  Org:%s  Des:%s',
              [FormatFloat('0.###', dPed),
               FormatFloat('0.###', dOrg),
               FormatFloat('0.###', dDes)]));
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
      Preview := TFormVisualizador.Create(nil);
      try
        Preview.Hide;
        Preview.FRutaPDFReal := RutaPDF;
        Preview.CargarYMostrar(ComandosESC);
        Preview.ExportarAPDF(ComandosESC, RutaPDF);
        if UpperCase(sImpresora) = 'DEBUG' then
          Preview.ShowModal
        else
          Ticket.Imprimir;
      finally
        FreeAndNil(Preview);
      end;
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
                                   const ANombreImpresora: string);
var
  Ticket: TTicketTermico;
  Preview: TFormVisualizador;
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
        sDocRef := sSerie + '/' + sNumDoc
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
        Ticket.EscribirLinea('SKU / Uds / Org(en) / Des(tino)');
        Ticket.LineaSeparadora('-');
        // Lineas: movimientos de salida (la salida del origen).
        Q.SQL.Text :=
          'SELECT CODIGO_UNIDAD_MOV, CANTIDAD_MOV' +
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
          Ticket.EscribirLinea(sSku);
          Ticket.EscribirLinea(Format('  Uds:%s  Org:%s  Des:%s',
            [FormatFloat('0.###', dPed),
             FormatFloat('0.###', dOrg),
             FormatFloat('0.###', dDes)]));
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
        Preview := TFormVisualizador.Create(nil);
        try
          Preview.Hide;
          Preview.FRutaPDFReal := RutaPDF;
          Preview.CargarYMostrar(ComandosESC);
          Preview.ExportarAPDF(ComandosESC, RutaPDF);
          if UpperCase(sImpresora) = 'DEBUG' then
            Preview.ShowModal
          else
            Ticket.Imprimir;
        finally
          FreeAndNil(Preview);
        end;
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
