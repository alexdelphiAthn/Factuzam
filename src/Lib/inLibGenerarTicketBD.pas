{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenerarTicketBD                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generación de tickets recuperando los datos desde la BBDD.                }
{    Imprime ticket de venta, resguardo de depósito y recordatorios al cliente.}
{******************************************************************************}
unit inLibGenerarTicketBD;

interface

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Uni,
  inLibFTicket,        // Donde está tu TTicketTermico
  inLibData,
  inLibUnidadesMedida, // Decimales por unidad en la cantidad
  inLibDir,            // Para GetUserFolderTickets
  inLibParametrosIntf;

  /// <summary>
  /// Genera un resguardo no fiscal con las prendas que el cliente
  ///tiene apartadas.
  /// </summary>
  procedure ImprimirResguardoDeposito(AConexion: TUniConnection;
                                      const ACodigoEmpresa,
                                            ACodigoAlmacen,
                                            ACodigoCaja,
                                            AOperacion: string;
                                      const ANombreImpresora: string = 'DEBUG';
                                      ARutasPDF: TStrings = nil;
                                      ASoloPDF: Boolean = False);
  /// <summary>
  /// Genera e imprime un ticket recuperando todos los datos
  /// directamente de la Base de Datos.
  /// </summary>
  procedure ImprimirTicketDesdeBD(
                                  const AParametrosApp:
                                  IParametrosAplicacion;
                                  AConexion: TUniConnection;
                                  const ACodigoEmpresa,
                                        ACodigoAlmacen,
                                        ACodigoCaja,
                                        ANumeroOperacion: string;
                                  const ANombreImpresora: string = 'DEBUG';
                                  ARutasPDF: TStrings = nil;
                                  ASoloPDF: Boolean = False);
  procedure ImprimirRecordatorio(AConexion: TUniConnection;
                                 const ACodigoEmpresa: string;
                                 CodigoCliente:string;
                                 NombreImpresora:string='DEBUG';
                                 ARutasPDF: TStrings = nil;
                                 ASoloPDF: Boolean = False);
implementation

uses
  inLibVerifactu, inLibFormatoDocumento, inLibGenerarTicket;

// Función auxiliar para rellenar con ceros (LPAD)
function LPAD(const AValue: string;
              ALength: Integer;
              const APadChar: Char = '0'): string;
var
  CurrentLength: Integer;
begin
  CurrentLength := Length(AValue);
  if CurrentLength >= ALength then
    Result := AValue
  else
    Result := StringOfChar(APadChar, ALength - CurrentLength) + AValue;
end;

procedure ImprimirResguardoDeposito(AConexion: TUniConnection;
                                    const ACodigoEmpresa,
                                          ACodigoAlmacen,
                                          ACodigoCaja,
                                          AOperacion: string;
                                    const ANombreImpresora: string = 'DEBUG';
                                    ARutasPDF: TStrings = nil;
                                    ASoloPDF: Boolean = False);
var
  QrySec, QryEmp: TUniQuery;
  Ticket: TTicketTermico;
  ComandosESC, RutaFicheroPDF: string;
  TotalNuevos,
  TotalEntregas,
  TotalDevoluciones,
  TotalDevueltos,
  TotalPagadoCaja: Currency;
  FechaOperacion: TDateTime;
begin
  FechaOperacion := 0;
  if Trim(AOperacion) = '' then
    Exit;
  QrySec := TUniQuery.Create(nil);
  QryEmp := TUniQuery.Create(nil);
  try
    QrySec.Connection := AConexion;
    QryEmp.Connection := AConexion;
    // 1. Datos de la empresa para la cabecera
    QryEmp.SQL.Text := 'SELECT RAZON_SOCIAL_EMP ' +
                       '  FROM fza_empresas ' +
                       ' WHERE CODIGO_EMP_EMP = :EMP';
    QryEmp.ParamByName('EMP').AsString := ACodigoEmpresa;
    QryEmp.Open;
    QrySec.SQL.Text := 'SELECT FECHA_OPERACION_OPCAJA ' +
                       '  FROM fza_caja_operaciones ' +
                       ' WHERE CODIGO_EMP_OPCAJA = :EMP ' +
                       '   AND CODIGO_ALM_OPCAJA = :ALM ' +
                       '   AND CODIGO_CAJA_OPCAJA = :CAJ ' +
                       '   AND NUMERO_OPERACION_OPCAJA = :OPE';
    QrySec.ParamByName('EMP').AsString := ACodigoEmpresa;
    QrySec.ParamByName('ALM').AsString := ACodigoAlmacen;
    QrySec.ParamByName('CAJ').AsString := ACodigoCaja;
    QrySec.ParamByName('OPE').AsString := AOperacion;
    QrySec.Open;
    if not QrySec.IsEmpty then
      FechaOperacion := QrySec.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
    QrySec.Close;
    QrySec.SQL.Text :=
      '   SELECT d.CODIGO_UNIDAD_DEP, ' +
      '          a.DESCRIPCION_ART, ' +
      '          d.CODIGO_CLI_DEP, ' +
      '          (d.PRECIO_VENTA_DEP * ' +
      '           d.CANTIDAD_PENDIENTE_DEP) AS TOTAL_PVP ' +
      '     FROM fza_depositos_cliente d ' +
      'LEFT JOIN fza_articulos a ' +
      '       ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP' +
      '    WHERE d.CODIGO_EMP_DEP = :EMP ' +
      '      AND d.CODIGO_ALM_DEP = :ALM ' +
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
        Ticket.EscribirLinea(QryEmp.FieldByName(
                                               'RAZON_SOCIAL_EMP').AsString);
      Ticket.SaltarLineas(1);
      Ticket.EscribirLinea('*** RESUMEN DE LA OPERACIÓN ***');
      Ticket.EscribirLinea('DEPÓSITOS Y ENTREGAS');
      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);
      Ticket.Alinear(alIzquierda);
      Ticket.TextoColumnas('CÓDIGO CLIENTE:',
                           QrySec.FieldByName('CODIGO_CLI_DEP').AsString);
      Ticket.TextoColumnas('FECHA:', FormatDateTime('dd/mm/yyyy hh:nn',
                           FechaOperacion));
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
          var Desc := QrySec.FieldByName('DESCRIPCION_ART').AsString;
          var Sku := QrySec.FieldByName('CODIGO_UNIDAD_DEP').AsString;
          var Pvp := QrySec.FieldByName('TOTAL_PVP').AsCurrency;
          TotalNuevos := TotalNuevos + Pvp;
          if Desc <> '' then
            Ticket.EscribirLinea(Copy(Desc, 1, 40));
          Ticket.EscribirLinea(Sku);
          Ticket.Alinear(alDerecha);
          Ticket.EscribirLinea('Valor Artículo: ' +
                                           FormatFloat('#,##0.00', Pvp) + ' €');
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
        '   SELECT o.TIPO_OPERACION_OPCAJA, ' +
        '          o.IMPORTE_TOTAL_OPCAJA, ' +
        '          a.DESCRIPCION_ART ' +
        '     FROM fza_caja_operaciones o ' +
        'LEFT JOIN fza_depositos_cliente d ON d.ID_DEPOSITO_DEP = ' +
        'o.ID_DEPOSITO_OPCAJA ' +
        'LEFT JOIN fza_articulos a ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP ' +
        '    WHERE o.CODIGO_EMP_OPCAJA = :EMP ' +
        '      AND o.CODIGO_ALM_OPCAJA = :ALM ' +
        '      AND o.CODIGO_CAJA_OPCAJA = :CAJ ' +
        '      AND o.NUMERO_OPERACION_OPCAJA = :OPE ' +
        '      AND o.TIPO_OPERACION_OPCAJA IN (''CB'', ''DE'') ' +
        '      AND o.IMPORTE_TOTAL_OPCAJA > 0';
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
          var NombreArticulo := QrySec.FieldByName('DESCRIPCION_ART').AsString;
          TotalEntregas := TotalEntregas + Importe;
          var Concepto := '';
          // Si conseguimos leer el nombre del artículo, lo mostramos
          if Trim(NombreArticulo) <> '' then
          begin
            if TipoOp = 'CB' then
              Concepto := 'A cuenta: ' + NombreArticulo
            else if TipoOp = 'DE' then
              Concepto := 'A cta. inicial: ' + NombreArticulo;
          end
          else
          // Textos por defecto si por algún motivo no encuentra el artículo
          begin
            if TipoOp = 'CB' then
              Concepto := 'A cuenta para artículo pendiente'
            else if TipoOp = 'DE' then
              Concepto := 'A cuenta inicial';
          end;
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
                          '          a.DESCRIPCION_ART, ' +
                          '          d.CODIGO_CLI_DEP, ' +
                          '          (d.PRECIO_VENTA_DEP * ' +
                          '           d.CANTIDAD_PENDIENTE_DEP) AS TOTAL ' +
                          '     FROM fza_depositos_cliente d ' +
                          'LEFT JOIN fza_articulos a ' +
                         '       ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP' +
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
        'WHERE CODIGO_EMP_OPCAJA = :EMP ' +
        '  AND CODIGO_ALM_OPCAJA = :ALM ' +
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
      if (TotalNuevos = 0) and (TotalEntregas = 0) and
         (TotalDevueltos = 0) and (TotalDevoluciones = 0) then
        Exit;
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
          var Desc := QryDev.FieldByName('DESCRIPCION_ART').AsString;
          var Sku := QryDev.FieldByName('CODIGO_UNIDAD_DEP').AsString;
          var Pvp := QryDev.FieldByName('TOTAL_PVP').AsCurrency;
          TotalDevueltos := TotalDevueltos + Pvp;
          if Desc <> '' then
            Ticket.EscribirLinea(Copy(Desc, 1, 40));
          Ticket.EscribirLinea(Sku);
          Ticket.Alinear(alDerecha);
          Ticket.EscribirLinea('Valor Artículo: ' +
                                           FormatFloat('#,##0.00', Pvp) + ' €');
          Ticket.Alinear(alIzquierda);
          QryDev.Next;
        end;
        Ticket.SaltarLineas(1);
      end;
      FreeAndNil(qryDev);
      // =======================================================================
      // CIFRA FINAL DE LA OPERACIÓN
      // =======================================================================
      // Calculamos TODO el efectivo real cobrado consultando los pagos
      TotalPagadoCaja := 0;
      var qryPagos := TUniQuery.Create(nil);
      try
        qryPagos.Connection := QrySec.Connection;
        qryPagos.SQL.Text := 'SELECT SUM(IMPORTE_ENTREGADO_PAGO - ' +
                             '           IMPORTE_CAMBIO_PAGO) AS TOTAL ' +
                             '  FROM fza_caja_pagos ' +
                             ' WHERE CODIGO_EMP_PAGO = :EMP ' +
                             '   AND CODIGO_ALM_PAGO = :ALM ' +
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
        FreeAndNil(qryPagos);
      end;
      Ticket.LineaSeparadora('=');
      Ticket.SaltarLineas(1);
      Ticket.Alinear(alDerecha);
      if TotalNuevos > 0 then
        Ticket.EscribirLinea('TOTAL NUEVOS DEPÓSITOS: ' +
                                   FormatFloat('#,##0.00', TotalNuevos) + ' €');
      if TotalDevueltos <> 0 then
        Ticket.EscribirLinea('TOTAL DEPÓSITOS DEVUELTOS: ' +
                                FormatFloat('#,##0.00', TotalDevueltos) + ' €');
      Ticket.EscribirLinea('ANTICIPOS ENTREGADOS AHORA: ' +
                                 FormatFloat('#,##0.00', TotalEntregas) + ' €');
      if TotalDevoluciones < 0 then
        Ticket.EscribirLinea('DEVUELTO EN ESTA OPERACIÓN: ' +
                             FormatFloat('#,##0.00', TotalDevoluciones) + ' €');
      Ticket.SaltarLineas(1);
      Ticket.Negrita(True);
      // IMPRIMIMOS EL TOTAL REAL COBRADO (Los 150 €)
      Ticket.EscribirLinea('TOTAL PAGADO (TICKET + DEPÓSITOS): ' +
                               FormatFloat('#,##0.00', TotalPagadoCaja) + ' €');
      Ticket.Negrita(False);
      Ticket.SaltarLineas(2);
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea('Conforme, el cliente');
      Ticket.SaltarLineas(4);
      Ticket.LineaSeparadora('_');
      EscribirPieTicketCaja(AConexion, Ticket, ACodigoEmpresa);
      Ticket.CortarPapel;
      // =======================================================================
      // IMPRESIÓN / VISUALIZACIÓN
      // =======================================================================
      ComandosESC := Ticket.ObtenerComandos;
      RutaFicheroPDF := GetUserFolderTickets + 'ResguardoDep_' +
                            FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
      ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaFicheroPDF,
                                   ANombreImpresora, ASoloPDF);
      if (ARutasPDF <> nil) and FileExists(RutaFicheroPDF) then
        ARutasPDF.Add(RutaFicheroPDF);
    finally
      FreeAndNil(Ticket);
    end;
  finally
    FreeAndNil(QrySec);
    FreeAndNil(QryEmp);
  end;
end;

procedure ImprimirTicketDesdeBD(
                                const AParametrosApp:
                                IParametrosAplicacion;
                                AConexion: TUniConnection;
                                const ACodigoEmpresa,
                                      ACodigoAlmacen,
                                      ACodigoCaja,
                                      ANumeroOperacion: string;
                                const ANombreImpresora: string = 'DEBUG';
                                ARutasPDF: TStrings = nil;
                                ASoloPDF: Boolean = False);
var
  QryCab, QryLin, QryPagos: TUniQuery;
  Ticket: TTicketTermico;
  ComandosESC, RutaFicheroPDF: string;
  QRTexto: string;
  DocumentoFac, SerieFac, NroFac: string;
  FechaOperacion: TDateTime;
begin
  QryCab   := TUniQuery.Create(nil);
  QryLin   := TUniQuery.Create(nil);
  QryPagos := TUniQuery.Create(nil);

  try
    QryCab.Connection   := AConexion;
    QryLin.Connection   := AConexion;
    QryPagos.Connection := AConexion;

    // 1. OBTENER CABECERA DE OPERACIÓN Y FACTURA
    QryCab.SQL.Text :=
      'SELECT o.TIPO_OPERACION_OPCAJA, ' +
      '       o.FECHA_OPERACION_OPCAJA, ' +
      '       o.INSTANTE_ALTA AS INSTANTE_ALTA_OPCAJA, ' +
      '       o.CODIGO_EMPLEADO_OPCAJA, ' +
      '       o.CODIGO_CLI_OPCAJA, ' +
      '       o.CONCEPTO_GASTO_INGRESO_OPCAJA, ' +
      '       o.IMPORTE_TOTAL_OPCAJA, ' +
      '       f.* ' +
      '  FROM fza_caja_operaciones o ' +
      '  LEFT JOIN fza_facturas f ' +
      '         ON f.SERIE_FAC = o.SERIE_FAC_OPCAJA ' +
      '        AND f.NUMERO_FAC   = o.NUMERO_FAC_OPCAJA ' +
      ' WHERE o.CODIGO_EMP_OPCAJA   = :EMP ' +
      '   AND o.CODIGO_ALM_OPCAJA   = :ALM ' +
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
    FechaOperacion :=
      QryCab.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
    if (Frac(FechaOperacion) = 0) and
       (not QryCab.FieldByName('INSTANTE_ALTA_OPCAJA').IsNull) then
      FechaOperacion := Trunc(FechaOperacion) + Frac(
        QryCab.FieldByName('INSTANTE_ALTA_OPCAJA').AsDateTime);
    SerieFac := QryCab.FieldByName('SERIE_FAC').AsString;
    NroFac   := QryCab.FieldByName('NUMERO_FAC').AsString;
    DocumentoFac := FormatearDocumentoEmpresa(AConexion, ACodigoEmpresa,
      SerieFac, NroFac);
    // 2. INICIALIZAR IMPRESORA
    // QR tributario fiscal en la reimpresión: misma URL de cotejo/remisión
    // que en el ticket original (se genera en local desde la factura)
    QRTexto := '';
    if (not SinVerifactuActivo(AParametrosApp)) and (SerieFac <> '') and
       (NroFac <> '') then
      QRTexto := ConstruirUrlQR(AParametrosApp,
                   QryCab.FieldByName('NIF_EMPRESA_FAC').AsString,
                   SerieFac,
                   NroFac,
                   QryCab.FieldByName('FECHA_FAC').AsDateTime,
                   QryCab.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency);
    Ticket := TTicketTermico.Create(ANombreImpresora);
    try
      Ticket.Inicializar;

      // === QR TRIBUTARIO AL PRINCIPIO (modo fiscal activo) ===
      if QRTexto <> '' then
      begin
        Ticket.Alinear(alCentro);
        Ticket.SaltarLineas(1);
        Ticket.EscribirLinea('QR tributario:');
        // Nivel de corrección M (49) exigido por la AEAT para el QR
        Ticket.ImprimirQRNativo(QRTexto, 6, 49);
        if VerifactuActivo(AParametrosApp) then
        begin
          Ticket.Alinear(alCentro);
          Ticket.EscribirLinea('VERI*FACTU - Factura verificable');
          Ticket.EscribirLinea('en la sede electrónica de la AEAT');
        end;
        Ticket.Alinear(alIzquierda);
      end;

      Ticket.SaltarLineas(1);
      Ticket.Negrita(True);

      if (SerieFac <> '') and (NroFac <> '') then
        Ticket.EscribirLinea('FACTURA SIMPLIFICADA Nro. ' + DocumentoFac)
      else
        Ticket.EscribirLinea('TICKET DE OPERACIÓN Nro. ' + ANumeroOperacion);

      Ticket.Negrita(False);
      Ticket.SaltarLineas(1);

      // === DATOS DE LA EMPRESA ===
      Ticket.Alinear(alCentro);
      Ticket.EscribirLinea(QryCab.FieldByName(
                                       'RAZON_SOCIAL_EMPRESA_FAC').AsString);
      Ticket.EscribirLinea(QryCab.FieldByName(
                                        'DIRECCION1_EMPRESA_FAC').AsString);
      Ticket.EscribirLinea(QryCab.FieldByName(
                                     'CODIGO_POSTAL_EMPRESA_FAC').AsString + ' ' +
                           QryCab.FieldByName(
                                         'POBLACION_EMPRESA_FAC').AsString);
      Ticket.EscribirLinea('CIF/NIF: ' +
                            QryCab.FieldByName('NIF_EMPRESA_FAC').AsString);
      if Trim(QryCab.FieldByName('MOVIL_EMPRESA_FAC').AsString) <> '' then
        Ticket.EscribirLinea('TELÉFONO: ' +
                          QryCab.FieldByName('MOVIL_EMPRESA_FAC').AsString);

      Ticket.SaltarLineas(1);

      // === DATOS DE LA OPERACIÓN ===
      Ticket.Alinear(alIzquierda);
      Ticket.TextoColumnas('OPERACIÓN NRO.', ANumeroOperacion);
      Ticket.SaltarLineas(1);
      Ticket.TextoColumnas(FormatDateTime('dd/mm/yyyy hh:nn',
                       FechaOperacion),
                                             LPAD(ACodigoEmpresa, 3) + ' Tda.' +
                          LPAD(ACodigoAlmacen, 3) + '-' + LPAD(ACodigoCaja, 2));

      // === ARTÍCULOS (Solo si hay factura vinculada) ===
      if (SerieFac <> '') and (NroFac <> '') then
      begin
        Ticket.LineaSeparadora('-');
        Ticket.EscribirLinea('Artículo/Sku                Uds    Total');
        Ticket.LineaSeparadora('-');

        QryLin.SQL.Text := 'SELECT * FROM fza_facturas_lineas ' +
                           ' WHERE SERIE_FAC_FACLIN = :SERIE ' +
                           '   AND NUMERO_FAC_FACLIN = :NRO ' +
                           ' ORDER BY LINEA_FACLIN';
        QryLin.ParamByName('SERIE').AsString := SerieFac;
        QryLin.ParamByName('NRO').AsString   := NroFac;
        QryLin.Open;
        while not QryLin.Eof do
        begin
          var sArt := Format('%-26s', [Copy(QryLin.FieldByName(
                              'CODIGO_UNIDAD_FACLIN').AsString, 1, 26)]);
          var sUni := '';
          if QryLin.FindField('TIPO_CANTIDAD_ARTICULO_FACLIN') <> nil then
            sUni := QryLin.FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString;
          var sUds := Format('%4s', [oUnidades.Formatear(QryLin.FieldByName(
                                           'CANTIDAD_FACLIN').AsFloat, sUni)]);
          var sPre := FormatFloat('#,##0.00',
                   QryLin.FieldByName('TOTAL_FACLIN').AsCurrency) + ' €';
          Ticket.TextoColumnas(sArt + sUds, sPre);
          Ticket.EscribirLinea(Copy(QryLin.FieldByName(
                        'DESCRIPCION_ARTICULO_FACLIN').AsString, 1, 42));
          QryLin.Next;
        end;
        QryLin.Close;
        Ticket.LineaSeparadora('-');
        Ticket.SaltarLineas(1);
        // === TOTALES ===
        Ticket.Alinear(alIzquierda);
        Ticket.Negrita(True);
        var Liquido    := QryCab.FieldByName(
                                            'TOTAL_LIQUIDO_FAC').AsCurrency;
        Ticket.TextoColumnas('A PAGAR',
                                       FormatFloat('#,##0.00', Liquido) + ' €');
        Ticket.Negrita(False);
      end;
      // === FORMAS DE PAGO ===
      Ticket.Alinear(alIzquierda);
      Ticket.Negrita(True);
      QryPagos.SQL.Text := 'SELECT CODIGO_FP_CFP, ' +
                           '       IMPORTE_ENTREGADO_PAGO, ' +
                           '       IMPORTE_CAMBIO_PAGO ' +
                           '  FROM fza_caja_pagos ' +
                           ' WHERE CODIGO_EMP_PAGO = :EMP ' +
                           '   AND CODIGO_ALM_PAGO = :ALM ' +
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
        var FPName := QryPagos.FieldByName('CODIGO_FP_CFP').AsString;
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
      // === VALE(S) EMITIDO(S) ===
      // En la reimpresion no hay datos en memoria: se leen de
      // fza_caja_vales por la operacion, para mostrar importe y codigo
      // igual que en el ticket de venta.
      QryPagos.SQL.Text := 'SELECT CODIGO_VL, IMPORTE_NOMINAL_VL ' +
                           '  FROM fza_caja_vales ' +
                           ' WHERE CODIGO_EMP_EMI_VL  = :EMP ' +
                           '   AND CODIGO_ALM_EMI_VL  = :ALM ' +
                           '   AND CODIGO_CAJA_EMI_VL = :CAJA ' +
                           '   AND NUMERO_OPERACION_EMI_VL = :OP ' +
                           ' ORDER BY CODIGO_VL';
      QryPagos.ParamByName('EMP').AsString  := ACodigoEmpresa;
      QryPagos.ParamByName('ALM').AsString  := ACodigoAlmacen;
      QryPagos.ParamByName('CAJA').AsString := ACodigoCaja;
      QryPagos.ParamByName('OP').AsString   := ANumeroOperacion;
      QryPagos.Open;
      while not QryPagos.Eof do
      begin
        var CodVale := QryPagos.FieldByName('CODIGO_VL').AsString;
        Ticket.SaltarLineas(1);
        Ticket.Negrita(True);
        Ticket.TextoColumnas('VALE EMITIDO A SU FAVOR',
          FormatFloat('#,##0.00',
            QryPagos.FieldByName('IMPORTE_NOMINAL_VL').AsCurrency) + ' €');
        if Length('CÓDIGO VALE EMITIDO: ' + CodVale) <= 42 then
          Ticket.TextoColumnas('CÓDIGO VALE EMITIDO: ', CodVale)
        else
        begin
          Ticket.EscribirLinea('CÓDIGO VALE EMITIDO:');
          Ticket.EscribirLinea(CodVale);
        end;
        Ticket.Negrita(False);
        QryPagos.Next;
      end;
      QryPagos.Close;
      Ticket.SaltarLineas(1);
      // === DESGLOSE DE IMPUESTOS (Si hay factura) ===
      if (SerieFac <> '') and (NroFac <> '') then
      begin
        if QryCab.FieldByName('TOTAL_IVAN_FAC').AsCurrency > 0 then
        begin
          Ticket.TextoColumnas('BASE IMPONIBLE', FormatFloat('#,##0.00',
             QryCab.FieldByName('TOTAL_BASEI_IVAN_FAC').AsCurrency) + ' €');
          Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)',
                           [QryCab.FieldByName('PORCENTAJE_IVAN_FAC').AsFloat]),
                            FormatFloat('#,##0.00',
                   QryCab.FieldByName('TOTAL_IVAN_FAC').AsCurrency) + ' €');
        end;
        if QryCab.FieldByName('TOTAL_IVAR_FAC').AsCurrency > 0 then
        begin
          Ticket.TextoColumnas('BASE IMPONIBLE RED.', FormatFloat('#,##0.00',
             QryCab.FieldByName('TOTAL_BASEI_IVAR_FAC').AsCurrency) + ' €');
          Ticket.TextoColumnas(Format('TOTAL IVA(%.0f%%)',
                           [QryCab.FieldByName('PORCENTAJE_IVAR_FAC').AsFloat]),
                            FormatFloat('#,##0.00', QryCab.FieldByName(
                                      'TOTAL_IVAR_FAC').AsCurrency) + ' €');
        end;
      end;
      // === PIE DE TICKET ===
      Ticket.SaltarLineas(2);
      Ticket.Alinear(alCentro);
      // Mostramos el diminutivo de ticket del vendedor (fza_empleados) en
      // lugar de su codigo, igual que en la impresion de la venta.
      Ticket.EscribirLinea('LE ATENDIÓ: ' +
        ObtenerDiminutivoVendedor(AConexion,
          QryCab.FieldByName('CODIGO_EMPLEADO_OPCAJA').AsString));
      Ticket.EscribirLinea('IVA INCLUIDO');
      Ticket.EscribirLinea('GRACIAS POR SU VISITA');
      // Textos legales (si están rellenos en la DB)
      if Trim(QryCab.FieldByName(
                     'TEXTO_LEGAL_EMPRESA_FAC').AsString) <> '' then
      begin
        Ticket.SaltarLineas(1);
        Ticket.EscribirLinea(QryCab.FieldByName(
                               'TEXTO_LEGAL_EMPRESA_FAC').AsString);
      end;
      EscribirPieTicketCaja(AConexion, Ticket, ACodigoEmpresa);
      var CodigoCliente := qryCab.FieldByName('CODIGO_CLI_FAC').AsString;
//      ImprimirRecordatorio(CodigoCliente);
      Ticket.CortarPapel;
      Ticket.AbrirCajon;
      // === PROCESO DE IMPRESIÓN / PREVIEW ===
      ComandosESC := Ticket.ObtenerComandos;
      RutaFicheroPDF := GetUserFolderTickets + 'TicketBD_' +
                            FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
      ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaFicheroPDF,
                                   ANombreImpresora, ASoloPDF);
      if (ARutasPDF <> nil) and FileExists(RutaFicheroPDF) then
        ARutasPDF.Add(RutaFicheroPDF);
    finally
      FreeAndNil(Ticket);
    end;
  finally
    FreeAndNil(QryCab);
    FreeAndNil(QryLin);
    FreeAndNil(QryPagos);
  end;
end;

procedure ImprimirRecordatorio(AConexion: TUniConnection;
                               const ACodigoEmpresa: string;
                               CodigoCliente:   string;
                               NombreImpresora: string = 'DEBUG';
                               ARutasPDF: TStrings = nil;
                               ASoloPDF: Boolean = False);
var
  Ticket: TTicketTermico;
  TotalPendienteCliente: Currency;
  CodEmp, RazonEmp: string;
  HayDatos: boolean;
begin
  if Trim(CodigoCliente) = '' then
    Exit;
  Ticket := TTicketTermico.Create(NombreImpresora);
  try
    Ticket.Inicializar;
    Ticket.Alinear(alCentro);
    Ticket.Negrita(True);
    Ticket.SaltarLineas(3);

    // ── Datos de la empresa del contexto ─────────────────────────────────
    var QryEmp := TUniQuery.Create(nil);
    try
      QryEmp.Connection := AConexion;
      QryEmp.SQL.Text :=
        'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP ' +
        '  FROM fza_empresas ' +
        ' WHERE CODIGO_EMP_EMP = :EMP';
      QryEmp.ParamByName('EMP').AsString := ACodigoEmpresa;
      QryEmp.Open;
      if not QryEmp.IsEmpty then
      begin
        CodEmp   := QryEmp.FieldByName('CODIGO_EMP_EMP').AsString;
        RazonEmp := QryEmp.FieldByName('RAZON_SOCIAL_EMP').AsString;
      end;
    finally
      FreeAndNil(QryEmp);
    end;

    // ── Depósitos pendientes del cliente con sus cobros ───────────────────
    var QryAnticipo := TUniQuery.Create(nil);
    try
      QryAnticipo.Connection := AConexion;
      QryAnticipo.SQL.Text :=
          'SELECT o.TIPO_OPERACION_OPCAJA, ' +
          '       o.IMPORTE_TOTAL_OPCAJA, ' +
          '       o.FECHA_OPERACION_OPCAJA, ' +
          '       o.CODIGO_EMP_OPCAJA, ' +
          '       o.CODIGO_ALM_OPCAJA, ' +
          '       o.CODIGO_CAJA_OPCAJA ' +
          '  FROM fza_caja_operaciones o ' +
          ' WHERE o.TIPO_OPERACION_OPCAJA IN (''CB'', ''DE'') ' +
          '   AND o.IMPORTE_TOTAL_OPCAJA   > 0 ' +
          '   AND o.ID_DEPOSITO_OPCAJA     = :IDDEP ' +
          ' ORDER BY o.FECHA_OPERACION_OPCAJA';
      var QryDep := TUniQuery.Create(nil);
      try
        QryDep.Connection := AConexion;
        QryDep.SQL.Text :=
          'SELECT dep.ID_DEPOSITO_DEP, ' +
          '       dep.CODIGO_UNIDAD_DEP, ' +
          '       dep.CODIGO_EMP_DEP, ' +
          '       dep.CODIGO_ALM_DEP, ' +
          '       dep.CODIGO_CAJA_DEP, ' +
          '       a.DESCRIPCION_ART, ' +
          '       dep.PRECIO_VENTA_DEP, ' +
          '       dep.FECHA_CREACION_DEP, ' +
          '       dep.IMPORTE_ANTICIPO_DEP, ' +
          '       dep.CANTIDAD_PENDIENTE_DEP, ' +
          '       cli.CODIGO_CLI_CLI, ' +
          '       cli.RAZON_SOCIAL_CLI ' +
          '  FROM fza_depositos_cliente dep ' +
          '  LEFT JOIN fza_articulos a ' +
          '    ON a.CODIGO_ART_ART = dep.CODIGO_ART_DEP ' +
          '  LEFT JOIN fza_clientes cli ' +
          '    ON cli.CODIGO_CLI_CLI = dep.CODIGO_CLI_DEP ' +
          ' WHERE dep.CODIGO_CLI_DEP = :CLI ' +
          '   AND dep.ESTADO_DEP         = ''PENDIENTE'' ' +
          ' ORDER BY dep.FECHA_CREACION_DEP';
        QryDep.ParamByName('CLI').AsString := CodigoCliente;
        QryDep.Open;
        HayDatos := not QryDep.IsEmpty;
        if not QryDep.IsEmpty then
        begin
          var CodCli   := QryDep.FieldByName('CODIGO_CLI_CLI').AsString;
          var RazonCli := QryDep.FieldByName('RAZON_SOCIAL_CLI').AsString;

          Ticket.Alinear(alCentro);
          Ticket.Negrita(True);
          Ticket.EscribirLinea('ESTADO DE SU CUENTA ENTREGAS/DEPÓSITOS');
          Ticket.EscribirLinea(
                     FormatDateTime('dddd, d "de" mmmm "de" yyyy, hh:nn', Now));
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
            var IdDep    := QryDep.FieldByName('ID_DEPOSITO_DEP').AsString;
            var FechaHora := FormatDateTime('dd/mm/yy HH:nn',
                             QryDep.FieldByName(
                               'FECHA_CREACION_DEP').AsDateTime);
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
            var EmpDep := QryDep.FieldByName('CODIGO_EMP_DEP').AsString;
            var AlmDep := QryDep.FieldByName('CODIGO_ALM_DEP').AsString;
            var CajDep := QryDep.FieldByName('CODIGO_CAJA_DEP').AsString;
            var OrigenDep := EmpDep;
            if AlmDep <> '' then OrigenDep := OrigenDep + '/' + AlmDep;
            if CajDep <> '' then OrigenDep := OrigenDep + '/' + CajDep;
            // Cabecera del depósito
            Ticket.Alinear(alIzquierda);
            Ticket.EscribirLinea(Format('%-14s %13s %13s', [
              FechaHora,
              FormatFloat('#,##0.00 €', TotalDep),
              FormatFloat('#,##0.00 €', Pendiente)
            ]));
            Ticket.EscribirLinea('  ' + Copy(SkuDep, 1, 40));
            Ticket.EscribirLinea('  ' + Copy(
              QryDep.FieldByName('DESCRIPCION_ART').AsString, 1, 40));
            Ticket.EscribirLinea('  RETIRADO EN (' + OrigenDep + ')');
            QryAnticipo.Close;
            QryAnticipo.ParamByName('IDDEP').AsString := IdDep;
            QryAnticipo.Open;
            while not QryAnticipo.Eof do
            begin
              var TipoOp   :=
                QryAnticipo.FieldByName('TIPO_OPERACION_OPCAJA').AsString;
              var Importe  :=
                QryAnticipo.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
              var FechaOpe :=
                QryAnticipo.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
              var EmpOpe   :=
                QryAnticipo.FieldByName('CODIGO_EMP_OPCAJA').AsString;
              var AlmOpe   :=
                QryAnticipo.FieldByName('CODIGO_ALM_OPCAJA').AsString;
              var CajOpe   :=
                QryAnticipo.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
              var Concepto := '';
              if TipoOp = 'DE' then
                Concepto := '  > Entrega inicial'
              else if TipoOp = 'CB' then
                Concepto := '  > A cuenta';
              var Origen := EmpOpe;
              if AlmOpe <> '' then Origen := Origen + '/' + AlmOpe;
              if CajOpe <> '' then Origen := Origen + '/' + CajOpe;
              Ticket.Alinear(alIzquierda);
              Ticket.EscribirLinea(Concepto + '  ' +
                     FormatDateTime('dd/mm/yy HH:nn', FechaOpe));
              Ticket.EscribirLinea(Format('   %-10s %13s',
                     ['(' + Origen + ')',
                      '-' + FormatFloat('#,##0.00',
                                        Importe
                      ) + ' €']));              Ticket.Alinear(alDerecha);
              QryAnticipo.Next;
            end;
            Ticket.SaltarLineas(1);
            QryDep.Next;
          end;
          Ticket.Alinear(alIzquierda);
          Ticket.LineaSeparadora('-');
          Ticket.Negrita(True);
          Ticket.TextoColumnas('TOTAL PDTE. DE PAGO:',
                         FormatFloat('#,##0.00', TotalPendienteCliente) + ' €');
          Ticket.Negrita(False);
        end;
      finally
        FreeAndNil(QryDep);
      end;
    finally
      FreeAndNil(QryAnticipo);
    end;
    if not HayDatos then
      Exit;
    // ── Generar PDF y mostrar / imprimir ─────────────────────────────────
    var ComandosESC    := Ticket.ObtenerComandos;
    var RutaFicheroPDF := GetUserFolderTickets + 'Recordatorio_' +
                          FormatDateTime('yyyy_mm_dd_hh_nn_ss', Now) + '.pdf';
    ImprimirOPrevisualizarTicket(Ticket, ComandosESC, RutaFicheroPDF,
                                 NombreImpresora, ASoloPDF);
    if (ARutasPDF <> nil) and FileExists(RutaFicheroPDF) then
      ARutasPDF.Add(RutaFicheroPDF);
  finally
    FreeAndNil(Ticket);
  end;
end;

end.
