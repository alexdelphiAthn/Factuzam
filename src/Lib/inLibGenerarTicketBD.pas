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
  procedure ImprimirRecordatorio(Ticket: TTicketTermico;
                                 CodigoCliente:string);
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
  TotalNuevos, TotalEntregas, TotalDevoluciones, NetoOperacion: Currency;
begin
  if Trim(AOperacion) = '' then
    Exit;

  QrySec := TUniQuery.Create(nil);
  QryEmp := TUniQuery.Create(nil);
  try
    QrySec.Connection := inLibGlobalVar.oConn;
    QryEmp.Connection := inLibGlobalVar.oConn;

    // 1. Datos de la empresa para la cabecera
    QryEmp.SQL.Text := 'SELECT RAZONSOCIAL_EMPRESA FROM fza_empresas WHERE CODIGO_EMPRESA = :EMP';
    QryEmp.ParamByName('EMP').AsString := ACodigoEmpresa;
    QryEmp.Open;

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
      Ticket.TextoColumnas('FECHA:', FormatDateTime('dd/mm/yyyy hh:nn', Now));
      Ticket.TextoColumnas('Nº OPERACIÓN:', AOperacion);
      Ticket.SaltarLineas(1);

      TotalNuevos := 0;
      TotalEntregas := 0;
      TotalDevoluciones := 0;

      // =======================================================================
      // SECCIÓN 1: NUEVOS DEPÓSITOS
      // =======================================================================
      QrySec.Close;
      QrySec.SQL.Text :=
        'SELECT d.CODIGO_UNIDAD_DEP, a.DESCRIPCION_ARTICULO, ' +
        '       (d.PRECIO_VENTA_DEP * d.CANTIDAD_PENDIENTE_DEP) AS TOTAL_PVP ' +
        'FROM fza_depositos_cliente d ' +
        'LEFT JOIN fza_articulos a ON a.CODIGO_ARTICULO = d.CODIGO_ARTICULO_DEP ' +
        'WHERE d.CODIGO_EMPRESA_DEP = :EMP AND d.NUMERO_OPERACION_DEP = :OPE';
      QrySec.ParamByName('EMP').AsString := ACodigoEmpresa;
      QrySec.ParamByName('OPE').AsString := AOperacion;
      QrySec.Open;

      if not QrySec.IsEmpty then
      begin
        Ticket.LineaSeparadora('=');
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea('NUEVOS DEPÓSITOS');
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
            Ticket.EscribirLinea(Copy(Desc + ' (' + Sku + ')', 1, 40))
          else
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
        'SELECT CONCEPTO_OPERACION, IMPORTE_OPERACION ' +
        'FROM fza_operaciones_caja ' +
        'WHERE CODIGO_EMPRESA = :EMP AND NUMERO_OPERACION = :OPE ' +
        '  AND TIPO_OPERACION IN (''DE'', ''CB'') AND IMPORTE_OPERACION > 0';
      QrySec.ParamByName('EMP').AsString := ACodigoEmpresa;
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
          var Concepto := QrySec.FieldByName('CONCEPTO_OPERACION').AsString;
          var Importe := QrySec.FieldByName('IMPORTE_OPERACION').AsCurrency;
          TotalEntregas := TotalEntregas + Importe;

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
      QrySec.Close;
      QrySec.SQL.Text :=
        'SELECT CONCEPTO_OPERACION, IMPORTE_OPERACION ' +
        'FROM fza_operaciones_caja ' +
        'WHERE CODIGO_EMPRESA = :EMP AND NUMERO_OPERACION = :OPE ' +
        '  AND TIPO_OPERACION = ''DV''';
      QrySec.ParamByName('EMP').AsString := ACodigoEmpresa;
      QrySec.ParamByName('OPE').AsString := AOperacion;
      QrySec.Open;

      if not QrySec.IsEmpty then
      begin
        Ticket.LineaSeparadora('=');
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea('DEVOLUCIONES');
        Ticket.Negrita(False);
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alIzquierda);

        while not QrySec.Eof do
        begin
          var Concepto := QrySec.FieldByName('CONCEPTO_OPERACION').AsString;
          var Importe := QrySec.FieldByName('IMPORTE_OPERACION').AsCurrency;
          TotalDevoluciones := TotalDevoluciones + Importe; // Como se guardó en negativo, sumamos el negativo.

          Ticket.EscribirLinea(Copy(Concepto, 1, 40));
          Ticket.Alinear(alDerecha);
          Ticket.EscribirLinea(FormatFloat('#,##0.00', Importe) + ' €');
          Ticket.Alinear(alIzquierda);
          QrySec.Next;
        end;
        Ticket.SaltarLineas(1);
      end;

      // =======================================================================
      // CIFRA FINAL DE LA OPERACIÓN
      // =======================================================================
      // TotalEntregas es positivo, TotalDevoluciones viene en negativo desde tu función InsertarOperacionCaja('DV', -ImporteDevuelto...)
      NetoOperacion := TotalEntregas + TotalDevoluciones;

      Ticket.LineaSeparadora('=');
      Ticket.SaltarLineas(1);
      Ticket.Alinear(alDerecha);

      Ticket.EscribirLinea('VALOR TOTAL NUEVOS DEPÓSITOS: ' + FormatFloat('#,##0.00', TotalNuevos) + ' €');
      Ticket.EscribirLinea('ENTREGADO EN ESTA OPERACIÓN: ' + FormatFloat('#,##0.00', TotalEntregas) + ' €');

      if TotalDevoluciones < 0 then
        Ticket.EscribirLinea('DEVUELTO EN ESTA OPERACIÓN: ' + FormatFloat('#,##0.00', TotalDevoluciones) + ' €');

      Ticket.SaltarLineas(1);
      Ticket.Negrita(True);
      Ticket.EscribirLinea('NETO ABONADO HOY: ' + FormatFloat('#,##0.00', NetoOperacion) + ' €');
      Ticket.Negrita(False);

      Ticket.SaltarLineas(2);
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea('Acepto el compromiso de pago. Firma del cliente');
      Ticket.SaltarLineas(4);
      Ticket.LineaSeparadora('-');
      Ticket.CortarPapel;

      // =======================================================================
      // IMPRESIÓN / VISUALIZACIÓN
      // =======================================================================
      ComandosESC := Ticket.ObtenerComandos;
      RutaFicheroPDF := GetUserFolderTickets + 'ResguardoDep_' +
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
        Ticket.EscribirLinea('FACTURA SIMPLIFICADA Nro. ' + SerieFac + '\' + NroFac)
      else
        Ticket.EscribirLinea('TICKET DE OPERACIÓN Nro. ' + ANumeroOperacion);

      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);

      // === DATOS DE LA EMPRESA ===
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea(QryCab.FieldByName('RAZONSOCIAL_EMPRESA_FACTURA').AsString);
      Ticket.EscribirLinea(QryCab.FieldByName('DIRECCION1_EMPRESA_FACTURA').AsString);
      Ticket.EscribirLinea(QryCab.FieldByName('CPOSTAL_EMPRESA_FACTURA').AsString + ' ' +
                           QryCab.FieldByName('POBLACION_EMPRESA_FACTURA').AsString);
      Ticket.EscribirLinea('CIF/NIF: ' + QryCab.FieldByName('NIF_EMPRESA_FACTURA').AsString);

      if Trim(QryCab.FieldByName('MOVIL_EMPRESA_FACTURA').AsString) <> '' then
        Ticket.EscribirLinea('TELÉFONO: ' + QryCab.FieldByName('MOVIL_EMPRESA_FACTURA').AsString);

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
          var sArt := Format('%-26s', [Copy(QryLin.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString, 1, 26)]);
          var sUds := Format('%4s', [FloatToStr(QryLin.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat)]);
          var sPre := FormatFloat('#,##0.00', QryLin.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency) + ' €';
          Ticket.TextoColumnas(sArt + sUds, sPre);
          Ticket.EscribirLinea(Copy(QryLin.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString, 1, 42));
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
        var TotalImp   := QryCab.FieldByName('TOTAL_IMPUESTOS_FACTURA').AsCurrency;
        var Liquido    := QryCab.FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency;
        Ticket.TextoColumnas('A PAGAR', FormatFloat('#,##0.00', Liquido) + ' €');
        Ticket.Negrita(False);
      end;
      // === FORMAS DE PAGO ===
      Ticket.Alinear(alIzquierda);
      Ticket.Negrita(True);
      QryPagos.SQL.Text := 'SELECT CODIGO_FORMAP, IMPORTE_ENTREGADO_PAGO, IMPORTE_CAMBIO_PAGO ' +
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
        var FPAmount := QryPagos.FieldByName('IMPORTE_ENTREGADO_PAGO').AsCurrency;
        TotalCambio := TotalCambio + QryPagos.FieldByName('IMPORTE_CAMBIO_PAGO').AsCurrency;
        if FPAmount <> 0 then
          Ticket.TextoColumnas(UpperCase(FPName), FormatFloat('#,##0.00', FPAmount) + ' €');
        QryPagos.Next;
      end;
      QryPagos.Close;
      if TotalCambio > 0 then
        Ticket.TextoColumnas('CAMBIO EFECTIVO', FormatFloat('#,##0.00', TotalCambio) + ' €');
      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);
      // === DESGLOSE DE IMPUESTOS (Si hay factura) ===
      if (SerieFac <> '') and (NroFac <> '') then
      begin
        if QryCab.FieldByName('TOTAL_IVAN_FACTURA').AsCurrency > 0 then
        begin
          Ticket.TextoColumnas('BASE IMPONIBLE', FormatFloat('#,##0.00', QryCab.FieldByName('TOTAL_BASEI_IVAN_FACTURA').AsCurrency) + ' €');
          Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)', [QryCab.FieldByName('PORCEN_IVAN_FACTURA').AsFloat]),
                               FormatFloat('#,##0.00', QryCab.FieldByName('TOTAL_IVAN_FACTURA').AsCurrency) + ' €');
        end;
        if QryCab.FieldByName('TOTAL_IVAR_FACTURA').AsCurrency > 0 then
        begin
          Ticket.TextoColumnas('BASE IMPONIBLE RED.', FormatFloat('#,##0.00', QryCab.FieldByName('TOTAL_BASEI_IVAR_FACTURA').AsCurrency) + ' €');
          Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)', [QryCab.FieldByName('PORCEN_IVAR_FACTURA').AsFloat]),
                               FormatFloat('#,##0.00', QryCab.FieldByName('TOTAL_IVAR_FACTURA').AsCurrency) + ' €');
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
      ImprimirRecordatorio(Ticket, CodigoCliente);
      Ticket.CortarPapel;
      Ticket.AbrirCajon;
      // === PROCESO DE IMPRESIÓN / PREVIEW ===
      ComandosESC := Ticket.ObtenerComandos;
      RutaFicheroPDF := GetUserFolderTickets + 'TicketBD_' + FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
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

procedure ImprimirRecordatorio(Ticket: TTicketTermico;
                               CodigoCliente:string);
begin
  Ticket.SaltarLineas(3);
  Ticket.CortarPapel(True);
  if Trim(CodigoCliente) <> '' then
  begin
    var QryDep := TUniQuery.Create(nil);
    try
      QryDep.Connection := inLibGlobalVar.oConn;
      // Consultamos tu tabla de depósitos
      QryDep.SQL.Text :=
        'SELECT CODIGO_UNIDAD_DEP, PRECIO_VENTA_DEP, FECHA_CREACION_DEP, ' +
        '       IMPORTE_ANTICIPO_DEP, CANTIDAD_PENDIENTE_DEP ' +
        '  FROM fza_depositos_cliente ' +
        ' WHERE CODIGO_CLIENTE_DEP = :CLI ' +
        '   AND ESTADO_DEP = ''PENDIENTE''';
      QryDep.ParamByName('CLI').AsString := CodigoCliente;
      QryDep.Open;
      if not QryDep.IsEmpty then
      begin
        Ticket.SaltarLineas(1);
        Ticket.LineaSeparadora('=');
        Ticket.Alinear(alCentro);
        Ticket.Negrita(True);
        Ticket.EscribirLinea('ESTADO DE SUS APARTADOS / DEPÓSITOS');
        Ticket.Negrita(False);
        Ticket.LineaSeparadora('-');
        Ticket.Alinear(alIzquierda);
        Ticket.EscribirLinea('Fecha  SKU/Artículo   Total   Pdte');
        Ticket.LineaSeparadora('-');
        var TotalPendienteCliente: Currency := 0;
        while not QryDep.Eof do
        begin
          var Fecha    := FormatDateTime('dd/mm/yy',
                       QryDep.FieldByName('FECHA_CREACION_DEP').AsDateTime);
          var SkuDep   :=
              Copy(QryDep.FieldByName('CODIGO_UNIDAD_DEP').AsString, 1, 15);
          var Precio   := QryDep.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
          var Cantidad :=
                       QryDep.FieldByName('CANTIDAD_PENDIENTE_DEP').AsFloat;
          if Cantidad = 0 then
            Cantidad := 1; // Seguridad
          var TotalDep := Precio * Cantidad;
          var Anticipo :=
                      QryDep.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
          var Pendiente:= TotalDep - Anticipo;
          TotalPendienteCliente := TotalPendienteCliente + Pendiente;
          // Formatear en columnas tabuladas
          var LineaDep := Format('%8s %-15s %7s %9s', [
            Fecha,
            SkuDep,
            FormatFloat('#,##0.00', TotalDep),
            FormatFloat('#,##0.00', Pendiente)
          ]);
          Ticket.EscribirLinea(LineaDep);
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
  end;
end;

end.
