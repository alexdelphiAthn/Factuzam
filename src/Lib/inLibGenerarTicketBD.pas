unit inLibGenerarTicketBD;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Uni,
  inLibGlobalVar,      // Donde está tu oConn
  inLibFTicket,        // Donde está tu TTicketTermico
  inMtoPreviewTicket,  // Donde está tu TFormVisualizador
  inLibData,
  inLibDir;            // Para GetUserFolderTickets

  /// <summary>
  /// Genera un resguardo no fiscal con las prendas que el cliente tiene apartadas.
  /// </summary>
  procedure ImprimirResguardoDeposito(const ACodigoEmpresa,
                                            ACodigoAlmacen,
                                            ACodigoCaja,
                                            AOperacion: string;
                                      const ANombreImpresora: string = 'DEBUG');
  /// <summary>
  /// Genera e imprime un ticket recuperando todos los datos directamente de la Base de Datos.
  /// </summary>
  procedure ImprimirTicketDesdeBD(const ACodigoEmpresa,
                                        ACodigoAlmacen,
                                        ACodigoCaja,
                                        ANumeroOperacion: string;
                                  const ANombreImpresora: string = 'DEBUG');
  procedure ImprimirRecordatorio(CodigoCliente:string;
                                 NombreImpresora:string='DEBUG');
implementation


// Función auxiliar para rellenar con ceros (LPAD)
function LPAD(const AValue: string; ALength: Integer; const APadChar: Char = '0'): string;
var
  CurrentLength: Integer;
begin
  CurrentLength := Length(AValue);
  if CurrentLength >= ALength then
    Result := AValue
  else
    Result := StringOfChar(APadChar, ALength - CurrentLength) + AValue;
end;

procedure ImprimirResguardoDeposito(const ACodigoEmpresa,
                                          ACodigoAlmacen,
                                          ACodigoCaja,
                                          AOperacion: string;
                                    const ANombreImpresora: string = 'DEBUG');
var
  QrySec, QryEmp: TUniQuery;
  Ticket: TTicketTermico;
  FormPreview: TFormVisualizador;
  ComandosESC, RutaFicheroPDF: string;
  TotalNuevos,
  TotalEntregas,
  TotalDevoluciones,
  TotalDevueltos,
  TotalPagadoCaja: Currency; // <--- NUEVA VARIABLE PARA EL EFECTIVO REAL
begin
  if Trim(AOperacion) = '' then
    Exit;
  QrySec := TUniQuery.Create(nil);
  QryEmp := TUniQuery.Create(nil);
  try
    QrySec.Connection := inLibGlobalVar.oConn;
    QryEmp.Connection := inLibGlobalVar.oConn;
    // 1. Datos de la empresa para la cabecera
    QryEmp.SQL.Text := 'SELECT RAZONSOCIAL_EMPRESA ' +
                       '  FROM fza_empresas ' +
                       ' WHERE CODIGO_EMPRESA = :EMP';
    QryEmp.ParamByName('EMP').AsString := ACodigoEmpresa;
    QryEmp.Open;
    QrySec.SQL.Text :=
      '   SELECT d.CODIGO_UNIDAD_DEP, ' +
      '          a.DESCRIPCION_ARTICULO, ' +
      '          d.CODIGO_CLIENTE_DEP, ' +
      '          (d.PRECIO_VENTA_DEP * ' +
      '           d.CANTIDAD_PENDIENTE_DEP) AS TOTAL_PVP ' +
      '     FROM fza_depositos_cliente d ' +
      'LEFT JOIN fza_articulos a ' +
      '       ON a.CODIGO_ARTICULO = d.CODIGO_ARTICULO_DEP' +
      '    WHERE d.CODIGO_EMPRESA_DEP = :EMP ' +
      '      AND d.CODIGO_ALMACEN_DEP = :ALM ' +
      '      AND d.CODIGO_CAJA_DEP = :CAJ ' +
      '      AND d.NUMERO_OPERACION_DEP = :OPE';
    QrySec.ParamByName('EMP').AsString := ACodigoEmpresa;
    QrySec.ParamByName('ALM').AsString := ACodigoAlmacen;
    QrySec.ParamByName('CAJ').AsString := ACodigoCaja;
    QrySec.ParamByName('OPE').AsString := AOperacion;
    QrySec.Open;
    Ticket := TTicketTermico.Create(ANombreImpresora);
    try
      Ticket.Inicializar;
      Ticket.Alinear(alCentro);
      Ticket.Negrita(True);
      if not QryEmp.IsEmpty then
        Ticket.EscribirLinea(QryEmp.FieldByName('RAZONSOCIAL_EMPRESA').AsString);
      Ticket.SaltarLineas(1);
      Ticket.EscribirLinea('*** RESUMEN DE LA OPERACIÓN ***');
      Ticket.EscribirLinea('DEPÓSITOS Y ENTREGAS');
      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);
      Ticket.Alinear(alIzquierda);
      Ticket.TextoColumnas('CÓDIGO CLIENTE:', QrySec.FieldByName('CODIGO_CLIENTE_DEP').AsString);
      Ticket.TextoColumnas('FECHA:', FormatDateTime('dd/mm/yyyy hh:nn', Now));
      Ticket.TextoColumnas('Nº OPERACIÓN:', AOperacion);
      Ticket.SaltarLineas(1);

      TotalNuevos := 0;
      TotalEntregas := 0;
      TotalDevoluciones := 0;
      TotalDevueltos := 0;

      // =======================================================================
      // SECCIÓN 1: NUEVOS DEPÓSITOS
      // =======================================================================
      if not QrySec.IsEmpty then
      begin
        Ticket.LineaSeparadora('=');
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea('MOVIMIENTO DE DEPÓSITOS/PRÉSTAMOS');
        Ticket.Negrita(False);
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alIzquierda);
        while not QrySec.Eof do
        begin
          var Desc := QrySec.FieldByName('DESCRIPCION_ARTICULO').AsString;
          var Sku := QrySec.FieldByName('CODIGO_UNIDAD_DEP').AsString;
          var Pvp := QrySec.FieldByName('TOTAL_PVP').AsCurrency;
          TotalNuevos := TotalNuevos + Pvp;
          if Desc <> '' then
            Ticket.EscribirLinea(Copy(Desc, 1, 40));
          Ticket.EscribirLinea(Sku);
          Ticket.Alinear(alDerecha);
          Ticket.EscribirLinea('Valor Artículo: ' + FormatFloat('#,##0.00', Pvp) + ' €');
          Ticket.Alinear(alIzquierda);
          QrySec.Next;
        end;
        Ticket.SaltarLineas(1);
      end;

      // =======================================================================
      // SECCIÓN 2: ENTREGAS A CUENTA
      // =======================================================================
      QrySec.Close;
      QrySec.SQL.Text :=
        'SELECT TIPO_OPERACION_OPCAJA, IMPORTE_TOTAL_OPCAJA ' +
        'FROM fza_caja_operaciones ' +
        'WHERE CODIGO_EMPRESA_OPCAJA = :EMP ' +
        '  AND CODIGO_ALMACEN_OPCAJA = :ALM ' +
        '  AND CODIGO_CAJA_OPCAJA = :CAJ ' +
        '  AND NUMERO_OPERACION_OPCAJA = :OPE ' +
        '  AND TIPO_OPERACION_OPCAJA IN (''CB'', ''DE'') ' + // <--- ¡CORREGIDO: AÑADIDO 'DE'!
        '  AND IMPORTE_TOTAL_OPCAJA > 0';
      QrySec.ParamByName('EMP').AsString := ACodigoEmpresa;
      QrySec.ParamByName('ALM').AsString := ACodigoAlmacen;
      QrySec.ParamByName('CAJ').AsString := ACodigoCaja;
      QrySec.ParamByName('OPE').AsString := AOperacion;
      QrySec.Open;
      if not QrySec.IsEmpty then
      begin
        Ticket.LineaSeparadora('=');
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea('ENTREGAS A CUENTA');
        Ticket.Negrita(False);
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alIzquierda);
        while not QrySec.Eof do
        begin
          var TipoOp  := QrySec.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
          var Importe := QrySec.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
          TotalEntregas := TotalEntregas + Importe;
          var Concepto := '';
          if TipoOp = 'CB' then
            Concepto := 'A cuenta para artículo pendiente'
          else if TipoOp = 'DE' then
            Concepto := 'A cuenta inicial';

          Ticket.EscribirLinea(Copy(Concepto, 1, 40));
          Ticket.Alinear(alDerecha);
          Ticket.EscribirLinea(FormatFloat('#,##0.00', Importe) + ' €');
          Ticket.Alinear(alIzquierda);
          QrySec.Next;
        end;
        Ticket.SaltarLineas(1);
      end;

      // =======================================================================
      // SECCIÓN 3: DEVOLUCIONES
      // =======================================================================
      var qryDev := TUniQuery.Create(nil);
      qryDev.Connection := qrySec.Connection;
      qryDev.sql.Text := '   SELECT d.CODIGO_UNIDAD_DEP, ' +
                          '          a.DESCRIPCION_ARTICULO, ' +
                          '          d.CODIGO_CLIENTE_DEP, ' +
                          '          (d.PRECIO_VENTA_DEP * ' +
                          '           d.CANTIDAD_PENDIENTE_DEP) AS TOTAL ' +
                          '     FROM fza_depositos_cliente d ' +
                          'LEFT JOIN fza_articulos a ' +
                         '       ON a.CODIGO_ARTICULO = d.CODIGO_ARTICULO_DEP' +
                          '    WHERE d.EMPRESA_CANCEL_DEP = :EMP ' +
                          '      AND d.ALMACEN_CANCEL_DEP = :ALM ' +
                          '      AND d.CAJA_CANCEL_DEP = :CAJ ' +
                          '      AND d.NUMERO_OPERACION_CANCEL_DEP = :OPE';
      qryDev.ParamByName('EMP').AsString := ACodigoEmpresa;
      qryDev.ParamByName('ALM').AsString := ACodigoAlmacen;
      qryDev.ParamByName('CAJ').AsString := ACodigoCaja;
      qryDev.ParamByName('OPE').AsString := AOperacion;
      qryDev.Open;

      QrySec.SQL.Text :=
        'SELECT TIPO_OPERACION_OPCAJA, IMPORTE_TOTAL_OPCAJA ' +
        'FROM fza_caja_operaciones ' +
        'WHERE CODIGO_EMPRESA_OPCAJA = :EMP ' +
        '  AND CODIGO_ALMACEN_OPCAJA = :ALM ' +
        '  AND CODIGO_CAJA_OPCAJA = :CAJ ' +
        '  AND NUMERO_OPERACION_OPCAJA = :OPE ' +
        '  AND TIPO_OPERACION_OPCAJA IN (''DV'')';
      QrySec.ParamByName('EMP').AsString := ACodigoEmpresa;
      QrySec.ParamByName('ALM').AsString := ACodigoAlmacen;
      QrySec.ParamByName('CAJ').AsString := ACodigoCaja;
      QrySec.ParamByName('OPE').AsString := AOperacion;
      QrySec.Open;

      if not QrySec.IsEmpty then
      begin
        Ticket.LineaSeparadora('=');
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea('DEVOLUCIÓN ECONÓMICA');
        Ticket.Negrita(False);
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alIzquierda);
        while not QrySec.Eof do
        begin
          var Concepto := QrySec.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
          var Importe := QrySec.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
          TotalDevoluciones := TotalDevoluciones + Importe;
          Ticket.EscribirLinea(Copy(Concepto, 1, 40));
          Ticket.Alinear(alDerecha);
          Ticket.EscribirLinea(FormatFloat('#,##0.00', Importe) + ' €');
          Ticket.Alinear(alIzquierda);
          QrySec.Next;
        end;
      end;
      if not QryDev.IsEmpty then
      begin
        Ticket.SaltarLineas(1);
        Ticket.LineaSeparadora('=');
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea('DEVOLUCIÓN DE ARTÍCULOS');
        Ticket.Negrita(False);
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alIzquierda);
        while not QryDev.Eof do
        begin
          var Desc := QryDev.FieldByName('DESCRIPCION_ARTICULO').AsString;
          var Sku := QryDev.FieldByName('CODIGO_UNIDAD_DEP').AsString;
          var Pvp := QryDev.FieldByName('TOTAL_PVP').AsCurrency;
          TotalDevueltos := TotalDevueltos + Pvp;
          if Desc <> '' then
            Ticket.EscribirLinea(Copy(Desc, 1, 40));
          Ticket.EscribirLinea(Sku);
          Ticket.Alinear(alDerecha);
          Ticket.EscribirLinea('Valor Artículo: ' + FormatFloat('#,##0.00', Pvp) + ' €');
          Ticket.Alinear(alIzquierda);
          QryDev.Next;
        end;
        Ticket.SaltarLineas(1);
      end;
      qryDev.Free;
      // =======================================================================
      // CIFRA FINAL DE LA OPERACIÓN
      // =======================================================================
      // Calculamos TODO el efectivo real cobrado consultando los pagos
      TotalPagadoCaja := 0;
      var qryPagos := TUniQuery.Create(nil);
      try
        qryPagos.Connection := QrySec.Connection;
        qryPagos.SQL.Text := 'SELECT SUM(IMPORTE_ENTREGADO_PAGO - IMPORTE_CAMBIO_PAGO) AS TOTAL ' +
                             '  FROM fza_caja_pagos ' +
                             ' WHERE CODIGO_EMPRESA_PAGO = :EMP ' +
                             '   AND CODIGO_ALMACEN_PAGO = :ALM ' +
                             '   AND CODIGO_CAJA_PAGO = :CAJ ' +
                             '   AND NUMERO_OPERACION_PAGO = :OPE';
        qryPagos.ParamByName('EMP').AsString := ACodigoEmpresa;
        qryPagos.ParamByName('ALM').AsString := ACodigoAlmacen;
        qryPagos.ParamByName('CAJ').AsString := ACodigoCaja;
        qryPagos.ParamByName('OPE').AsString := AOperacion;
        qryPagos.Open;
        if not qryPagos.IsEmpty then
          TotalPagadoCaja := qryPagos.FieldByName('TOTAL').AsCurrency;
      finally
        qryPagos.Free;
      end;
      Ticket.LineaSeparadora('=');
      Ticket.SaltarLineas(1);
      Ticket.Alinear(alDerecha);
      if TotalNuevos > 0 then
        Ticket.EscribirLinea('TOTAL NUEVOS DEPÓSITOS: ' + FormatFloat('#,##0.00', TotalNuevos) + ' €');
      if TotalDevueltos <> 0 then
        Ticket.EscribirLinea('TOTAL DEPÓSITOS DEVUELTOS: ' + FormatFloat('#,##0.00', TotalDevueltos) + ' €');
      Ticket.EscribirLinea('ANTICIPOS ENTREGADOS AHORA: ' + FormatFloat('#,##0.00', TotalEntregas) + ' €');
      if TotalDevoluciones < 0 then
        Ticket.EscribirLinea('DEVUELTO EN ESTA OPERACIÓN: ' + FormatFloat('#,##0.00', TotalDevoluciones) + ' €');
      Ticket.SaltarLineas(1);
      Ticket.Negrita(True);
      // IMPRIMIMOS EL TOTAL REAL COBRADO (Los 150 €)
      Ticket.EscribirLinea('TOTAL PAGADO (TICKET + DEPÓSITOS): ' + FormatFloat('#,##0.00', TotalPagadoCaja) + ' €');
      Ticket.Negrita(False);
      Ticket.SaltarLineas(2);
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea('Conforme, el cliente');
      Ticket.SaltarLineas(4);
      Ticket.LineaSeparadora('_');
      Ticket.CortarPapel;
      // =======================================================================
      // IMPRESIÓN / VISUALIZACIÓN
      // =======================================================================
      ComandosESC := Ticket.ObtenerComandos;
      RutaFicheroPDF := GetUserFolderTickets + 'ResguardoDep_' + FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
      FormPreview := TFormVisualizador.Create(nil);
      try
        FormPreview.Hide;
        FormPreview.CargarYMostrar(ComandosESC);
        FormPreview.ExportarAPDF(ComandosESC, RutaFicheroPDF);
        if UpperCase(ANombreImpresora) = 'DEBUG' then
          FormPreview.ShowModal
        else
          Ticket.Imprimir;
      finally
        FormPreview.Free;
      end;
    finally
      Ticket.Free;
    end;
  finally
    QrySec.Free;
    QryEmp.Free;
  end;
end;

procedure ImprimirTicketDesdeBD(const ACodigoEmpresa,
                                      ACodigoAlmacen,
                                      ACodigoCaja,
                                      ANumeroOperacion: string;
                                const ANombreImpresora: string = 'DEBUG');
var
  QryCab, QryLin, QryPagos: TUniQuery;
  Ticket: TTicketTermico;
  FormPreview: TFormVisualizador;
  ComandosESC, RutaFicheroPDF: string;
  ModoQR, QRTexto: string;
  SerieFac, NroFac: string;
begin
  QryCab   := TUniQuery.Create(nil);
  QryLin   := TUniQuery.Create(nil);
  QryPagos := TUniQuery.Create(nil);

  try
    QryCab.Connection   := inLibGlobalVar.oConn;
    QryLin.Connection   := inLibGlobalVar.oConn;
    QryPagos.Connection := inLibGlobalVar.oConn;

    // 1. OBTENER CABECERA DE OPERACIÓN Y FACTURA
    QryCab.SQL.Text :=
      'SELECT o.TIPO_OPERACION_OPCAJA, ' +
      '       o.FECHA_OPERACION_OPCAJA, ' +
      '       o.CODIGO_EMPLEADO_OPCAJA, ' +
      '       o.CODIGO_CLIENTE_OPCAJA, ' +
      '       o.CONCEPTO_GASTO_INGRESO_OPCAJA, ' +
      '       o.IMPORTE_TOTAL_OPCAJA, ' +
      '       f.* ' +
      '  FROM fza_caja_operaciones o ' +
      '  LEFT JOIN fza_facturas f ' +
      '         ON f.SERIE_FACTURA = o.SERIE_FACTURA_OPCAJA ' +
      '        AND f.NRO_FACTURA   = o.NRO_FACTURA_OPCAJA ' +
      ' WHERE o.CODIGO_EMPRESA_OPCAJA   = :EMP ' +
      '   AND o.CODIGO_ALMACEN_OPCAJA   = :ALM ' +
      '   AND o.CODIGO_CAJA_OPCAJA      = :CAJA ' +
      '   AND o.NUMERO_OPERACION_OPCAJA = :OP';
    QryCab.ParamByName('EMP').AsString  := ACodigoEmpresa;
    QryCab.ParamByName('ALM').AsString  := ACodigoAlmacen;
    QryCab.ParamByName('CAJA').AsString := ACodigoCaja;
    QryCab.ParamByName('OP').AsString   := ANumeroOperacion;
    QryCab.Open;
    if QryCab.IsEmpty then
      raise Exception.Create('No se ha encontrado la operación en la caja ' +
                             'especificada.');
    SerieFac := QryCab.FieldByName('SERIE_FACTURA').AsString;
    NroFac   := QryCab.FieldByName('NRO_FACTURA').AsString;
    // 2. INICIALIZAR IMPRESORA
    ModoQR := 'NATIVO';
    QRTexto := 'http://hacienda.com?nro=' + SerieFac + NroFac;
    Ticket := TTicketTermico.Create(ANombreImpresora);
    try
      Ticket.Inicializar;

      // === QR AL PRINCIPIO ===
      Ticket.Alinear(alCentro);
      Ticket.SaltarLineas(1);

      if ModoQR = 'NATIVO' then
        Ticket.ImprimirQRNativo(QRTexto, 6);

      Ticket.SaltarLineas(1);
      Ticket.Negrita(True);

      if (SerieFac <> '') and (NroFac <> '') then
        Ticket.EscribirLinea('FACTURA SIMPLIFICADA Nro. ' + SerieFac + '\' +
                             NroFac)
      else
        Ticket.EscribirLinea('TICKET DE OPERACIÓN Nro. ' + ANumeroOperacion);

      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);

      // === DATOS DE LA EMPRESA ===
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea(QryCab.FieldByName(
                                       'RAZONSOCIAL_EMPRESA_FACTURA').AsString);
      Ticket.EscribirLinea(QryCab.FieldByName(
                                        'DIRECCION1_EMPRESA_FACTURA').AsString);
      Ticket.EscribirLinea(QryCab.FieldByName(
                                     'CPOSTAL_EMPRESA_FACTURA').AsString + ' ' +
                           QryCab.FieldByName(
                                         'POBLACION_EMPRESA_FACTURA').AsString);
      Ticket.EscribirLinea('CIF/NIF: ' +
                            QryCab.FieldByName('NIF_EMPRESA_FACTURA').AsString);
      if Trim(QryCab.FieldByName('MOVIL_EMPRESA_FACTURA').AsString) <> '' then
        Ticket.EscribirLinea('TELÉFONO: ' +
                          QryCab.FieldByName('MOVIL_EMPRESA_FACTURA').AsString);

      Ticket.SaltarLineas(1);

      // === DATOS DE LA OPERACIÓN ===
      Ticket.Alinear(alIzquierda);
      Ticket.TextoColumnas('OPERACIÓN NRO.', ANumeroOperacion);
      Ticket.SaltarLineas(1);
      Ticket.TextoColumnas(FormatDateTime('dd/mm/yyyy hh:nn',
                       QryCab.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime),
                                             LPAD(ACodigoEmpresa, 3) + ' Tda.' +
                          LPAD(ACodigoAlmacen, 3) + '-' + LPAD(ACodigoCaja, 2));

      // === ARTÍCULOS (Solo si hay factura vinculada) ===
      if (SerieFac <> '') and (NroFac <> '') then
      begin
        Ticket.LineaSeparadora('-');
        Ticket.EscribirLinea('Artículo/Sku                Uds    Total');
        Ticket.LineaSeparadora('-');

        QryLin.SQL.Text := 'SELECT * FROM fza_facturas_lineas ' +
                           ' WHERE SERIE_FACTURA_LINEA = :SERIE ' +
                           '   AND NRO_FACTURA_LINEA = :NRO ' +
                           ' ORDER BY LINEA_FACTURA_LINEA';
        QryLin.ParamByName('SERIE').AsString := SerieFac;
        QryLin.ParamByName('NRO').AsString   := NroFac;
        QryLin.Open;
        while not QryLin.Eof do
        begin
          var sArt := Format('%-26s', [Copy(QryLin.FieldByName(
                              'CODIGO_UNIDAD_FACTURA_LINEA').AsString, 1, 26)]);
          var sUds := Format('%4s', [FloatToStr(QryLin.FieldByName(
                                           'CANTIDAD_FACTURA_LINEA').AsFloat)]);
          var sPre := FormatFloat('#,##0.00',
                   QryLin.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency) + ' €';
          Ticket.TextoColumnas(sArt + sUds, sPre);
          Ticket.EscribirLinea(Copy(QryLin.FieldByName(
                        'DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString, 1, 42));
          QryLin.Next;
        end;
        QryLin.Close;
        Ticket.LineaSeparadora('-');
        Ticket.SaltarLineas(1);
        // === TOTALES ===
        Ticket.Alinear(alIzquierda);
        Ticket.Negrita(True);
        // Descuentos globales (Calculado matemáticamente por diferencia si es necesario o desde campo)
        var TotalBases := QryCab.FieldByName('TOTAL_BASES_FACTURA').AsCurrency;
        var TotalImp   := QryCab.FieldByName(
                                          'TOTAL_IMPUESTOS_FACTURA').AsCurrency;
        var Liquido    := QryCab.FieldByName(
                                            'TOTAL_LIQUIDO_FACTURA').AsCurrency;
        Ticket.TextoColumnas('A PAGAR',
                                       FormatFloat('#,##0.00', Liquido) + ' €');
        Ticket.Negrita(False);
      end;
      // === FORMAS DE PAGO ===
      Ticket.Alinear(alIzquierda);
      Ticket.Negrita(True);
      QryPagos.SQL.Text := 'SELECT CODIGO_FORMAP, ' +
                           '       IMPORTE_ENTREGADO_PAGO, ' +
                           '       IMPORTE_CAMBIO_PAGO ' +
                           '  FROM fza_caja_pagos ' +
                           ' WHERE CODIGO_EMPRESA_PAGO = :EMP ' +
                           '   AND CODIGO_ALMACEN_PAGO = :ALM ' +
                           '   AND CODIGO_CAJA_PAGO = :CAJA ' +
                           '   AND NUMERO_OPERACION_PAGO = :OP ' +
                           ' ORDER BY NUMERO_LINEA_PAGO';
      QryPagos.ParamByName('EMP').AsString  := ACodigoEmpresa;
      QryPagos.ParamByName('ALM').AsString  := ACodigoAlmacen;
      QryPagos.ParamByName('CAJA').AsString := ACodigoCaja;
      QryPagos.ParamByName('OP').AsString   := ANumeroOperacion;
      QryPagos.Open;
      var TotalCambio: Currency := 0;
      while not QryPagos.Eof do
      begin
        var FPName := QryPagos.FieldByName('CODIGO_FORMAP').AsString;
        var FPAmount := QryPagos.FieldByName(
                                           'IMPORTE_ENTREGADO_PAGO').AsCurrency;
        TotalCambio := TotalCambio + QryPagos.FieldByName(
                                              'IMPORTE_CAMBIO_PAGO').AsCurrency;
        if FPAmount <> 0 then
          Ticket.TextoColumnas(UpperCase(FPName),
                                      FormatFloat('#,##0.00', FPAmount) + ' €');
        QryPagos.Next;
      end;
      QryPagos.Close;
      if TotalCambio > 0 then
        Ticket.TextoColumnas('CAMBIO EFECTIVO',
                                   FormatFloat('#,##0.00', TotalCambio) + ' €');
      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);
      // === DESGLOSE DE IMPUESTOS (Si hay factura) ===
      if (SerieFac <> '') and (NroFac <> '') then
      begin
        if QryCab.FieldByName('TOTAL_IVAN_FACTURA').AsCurrency > 0 then
        begin
          Ticket.TextoColumnas('BASE IMPONIBLE', FormatFloat('#,##0.00',
             QryCab.FieldByName('TOTAL_BASEI_IVAN_FACTURA').AsCurrency) + ' €');
          Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)',
                           [QryCab.FieldByName('PORCEN_IVAN_FACTURA').AsFloat]),
                            FormatFloat('#,##0.00',
                   QryCab.FieldByName('TOTAL_IVAN_FACTURA').AsCurrency) + ' €');
        end;
        if QryCab.FieldByName('TOTAL_IVAR_FACTURA').AsCurrency > 0 then
        begin
          Ticket.TextoColumnas('BASE IMPONIBLE RED.', FormatFloat('#,##0.00',
             QryCab.FieldByName('TOTAL_BASEI_IVAR_FACTURA').AsCurrency) + ' €');
          Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)',
                           [QryCab.FieldByName('PORCEN_IVAR_FACTURA').AsFloat]),
                            FormatFloat('#,##0.00', QryCab.FieldByName(
                                      'TOTAL_IVAR_FACTURA').AsCurrency) + ' €');
        end;
      end;
      // === PIE DE TICKET ===
      Ticket.SaltarLineas(2);
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea('LE ATENDIÓ: ' +
                         QryCab.FieldByName('CODIGO_EMPLEADO_OPCAJA').AsString);
      Ticket.EscribirLinea('IVA INCLUIDO');
      Ticket.EscribirLinea('GRACIAS POR SU VISITA');
      // Textos legales (si están rellenos en la DB)
      if Trim(QryCab.FieldByName(
                     'TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA').AsString) <> '' then
      begin
        Ticket.SaltarLineas(1);
        Ticket.EscribirLinea(QryCab.FieldByName(
                               'TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA').AsString);
      end;
      var CodigoCliente := qryCab.FieldByName('CODIGO_CLIENTE_FACTURA').AsString;
//      ImprimirRecordatorio(CodigoCliente);
      Ticket.CortarPapel;
      Ticket.AbrirCajon;
      // === PROCESO DE IMPRESIÓN / PREVIEW ===
      ComandosESC := Ticket.ObtenerComandos;
      RutaFicheroPDF := GetUserFolderTickets + 'TicketBD_' +
                            FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
      FormPreview := TFormVisualizador.Create(nil);
      try
        FormPreview.Hide;
        FormPreview.CargarYMostrar(ComandosESC);
        FormPreview.ExportarAPDF(ComandosESC, RutaFicheroPDF);
        if UpperCase(ANombreImpresora) = 'DEBUG' then
          FormPreview.ShowModal
        else
          Ticket.Imprimir;
      finally
        FormPreview.Free;
      end;
    finally
      Ticket.Free;
    end;
  finally
    QryCab.Free;
    QryLin.Free;
    QryPagos.Free;
  end;
end;

procedure ImprimirRecordatorio(CodigoCliente:   string;
                               NombreImpresora: string = 'DEBUG');
var
  Ticket: TTicketTermico;
  FormPreview: TFormVisualizador;
  TotalPendienteCliente: Currency;
  CodEmp, RazonEmp: string;
begin
  if (Trim(CodigoCliente) <> '') then
  begin
    Ticket := TTicketTermico.Create(NombreImpresora);
    try
      Ticket.Inicializar;
      Ticket.Alinear(alCentro);
      Ticket.Negrita(True);
      Ticket.SaltarLineas(3);
      // ── Datos de la empresa del contexto ─────────────────────
      var QryEmp := TUniQuery.Create(nil);
      try
        QryEmp.Connection := inLibGlobalVar.oConn;
        QryEmp.SQL.Text :=
          'SELECT CODIGO_EMPRESA, RAZONSOCIAL_EMPRESA ' +
          '  FROM fza_empresas ' +
          ' WHERE CODIGO_EMPRESA = :EMP';
        QryEmp.ParamByName('EMP').AsString := oEmpresa;
        QryEmp.Open;
        if not QryEmp.IsEmpty then
        begin
          CodEmp   := QryEmp.FieldByName('CODIGO_EMPRESA').AsString;
          RazonEmp := QryEmp.FieldByName('RAZONSOCIAL_EMPRESA').AsString;
        end;
      finally
        QryEmp.Free;
      end;
      // ── Depósitos de TODAS las empresas del cliente ───────────
      var QryDep := TUniQuery.Create(nil);
      try
        QryDep.Connection := inLibGlobalVar.oConn;
        QryDep.SQL.Text :=
          'SELECT dep.CODIGO_UNIDAD_DEP, ' +
          '       dep.CODIGO_EMPRESA_DEP, ' +
          '       dep.CODIGO_ALMACEN_DEP, ' +
          '       dep.CODIGO_CAJA_DEP, ' +
          '       a.DESCRIPCION_ARTICULO, ' +
          '       dep.PRECIO_VENTA_DEP, ' +
          '       dep.FECHA_CREACION_DEP, ' +
          '       dep.IMPORTE_ANTICIPO_DEP, ' +
          '       dep.CANTIDAD_PENDIENTE_DEP, ' +
          '       cli.CODIGO_CLIENTE, ' +
          '       cli.RAZONSOCIAL_CLIENTE ' +
          '  FROM fza_depositos_cliente dep ' +
          '  LEFT JOIN fza_articulos a' +
          '    ON dep.CODIGO_ARTICULO_DEP = a.CODIGO_ARTICULO ' +
          '  LEFT JOIN fza_clientes cli' +
          '    ON dep.CODIGO_CLIENTE_DEP = cli.CODIGO_CLIENTE ' +
          ' WHERE dep.CODIGO_CLIENTE_DEP = :CLI ' +
          '   AND dep.ESTADO_DEP         = ''PENDIENTE'' ' +
          ' ORDER BY dep.FECHA_CREACION_DEP';
        QryDep.ParamByName('CLI').AsString := CodigoCliente;
        QryDep.Open;
        if not QryDep.IsEmpty then
        begin
          var CodCli   := QryDep.FieldByName('CODIGO_CLIENTE').AsString;
          var RazonCli := QryDep.FieldByName('RAZONSOCIAL_CLIENTE').AsString;
          Ticket.Alinear(alCentro);
          Ticket.Negrita(True);
          Ticket.EscribirLinea('ESTADO DE SU CUENTA ENTREGAS/DEPÓSITOS');
          Ticket.Negrita(False);
          Ticket.LineaSeparadora('-');
          Ticket.Alinear(alIzquierda);
          Ticket.Negrita(True);
          Ticket.EscribirLinea('EMPRESA:');
          Ticket.Negrita(False);
          Ticket.EscribirLinea(Format('%-4s %s',
                                              [CodEmp, Copy(RazonEmp, 1, 36)]));
          Ticket.Negrita(True);
          Ticket.EscribirLinea('CLIENTE:');
          Ticket.Negrita(False);
          Ticket.EscribirLinea(Format('%-4s %s',
                                              [CodCli, Copy(RazonCli, 1, 36)]));
          Ticket.LineaSeparadora('-');
          Ticket.EscribirLinea(Format('%-14s %13s %13s',
                                         ['Fecha/Hora', 'Total', 'Pendiente']));
          Ticket.LineaSeparadora('-');
          TotalPendienteCliente := 0;
          while not QryDep.Eof do
          begin
            var FechaHora := FormatDateTime('dd/mm/yy HH:nn',
                           QryDep.FieldByName('FECHA_CREACION_DEP').AsDateTime);
            var SkuDep   := QryDep.FieldByName('CODIGO_UNIDAD_DEP').AsString;
            var Precio   := QryDep.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
            var Cantidad :=
                           QryDep.FieldByName('CANTIDAD_PENDIENTE_DEP').AsFloat;
            if Cantidad = 0 then Cantidad := 1;
            var TotalDep  := Precio * Cantidad;
            var Anticipo  :=
                          QryDep.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
            var Pendiente := TotalDep - Anticipo;
            TotalPendienteCliente := TotalPendienteCliente + Pendiente;
            // Origen de la operación
            var EmpDep := QryDep.FieldByName('CODIGO_EMPRESA_DEP').AsString;
            var AlmDep := QryDep.FieldByName('CODIGO_ALMACEN_DEP').AsString;
            var CajDep := QryDep.FieldByName('CODIGO_CAJA_DEP').AsString;
            // Construir etiqueta "EMP / ALM / CAJ" omitiendo los vacíos
            var OrigenDep := EmpDep;
            if AlmDep <> '' then OrigenDep := OrigenDep + ' / ' + AlmDep;
            if CajDep <> '' then OrigenDep := OrigenDep + ' / ' + CajDep;

            Ticket.EscribirLinea(Format('%-14s %13s %13s', [
              FechaHora,
              FormatFloat('#,##0.00 €', TotalDep),
              FormatFloat('#,##0.00 €', Pendiente)
            ]));
            Ticket.EscribirLinea('  ' + Copy(SkuDep, 1, 40));
            Ticket.EscribirLinea('  ' + Copy(
              QryDep.FieldByName('DESCRIPCION_ARTICULO').AsString, 1, 40));
            Ticket.EscribirLinea('  ' + 'RETIRADO EN (' + OrigenDep + ')');
            Ticket.SaltarLineas(1);
            QryDep.Next;
          end;
          Ticket.LineaSeparadora('-');
          Ticket.Negrita(True);
          Ticket.TextoColumnas('TOTAL PDTE. DE PAGO:',
            FormatFloat('#,##0.00', TotalPendienteCliente) + ' €');
          Ticket.Negrita(False);
        end;
      finally
        QryDep.Free;
      end;
      var RutaFicheroPDF := GetUserFolderTickets + 'Recordatorio_' +
                            FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
      FormPreview := TFormVisualizador.Create(nil);
      try
        FormPreview.Hide;
        var ComandosESC := Ticket.ObtenerComandos;
        FormPreview.CargarYMostrar(ComandosESC);
        FormPreview.ExportarAPDF(ComandosESC, RutaFicheroPDF);
        if UpperCase(NombreImpresora) = 'DEBUG' then
          FormPreview.ShowModal
        else
          Ticket.Imprimir;
      finally
        FormPreview.Free;
      end;
    finally
      Ticket.Free;
    end;
  end;
end;

end.
