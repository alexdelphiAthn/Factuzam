{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigVales                                                 }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra los vales de tienda del legacy → fza_caja_vales y registra su      }
{    emisión como pago negativo VALE en fza_caja_pagos.                       }
{      Origen:  dbo.occajvale (un vale por fila; emitido en una operación y    }
{               opcionalmente "recogido"/redimido en otra).                    }
{      Destino: fza_caja_vales (cabecera del vale: emisión + redención).       }
{                                                                              }
{    CODIGO_VL = 'VALE_<emp>_<almAbrev>_<caja>_<operacion a 8 dígitos>',       }
{    igual que el formato que genera la app, único por operación de emisión.   }
{    ESTADO_VL = 'REDIMIDO' si el vale tiene operación de recogida             }
{    (OperacionRcgdo>0), 'PENDIENTE' en caso contrario.                        }
{                                                                              }
{    Idempotente: PK (CODIGO_VL) + referencia del pago; re-ejecutar no         }
{    duplica vales ni apuntes de pago.                                         }
{******************************************************************************}
unit inLibMigVales;
interface
uses
  UMigEngine;
procedure MigrarVales(Eng: TMigEngine; var Stats: TMigStats);
implementation
uses
  System.SysUtils,
  Data.DB, Uni;
procedure MigrarVales(Eng: TMigEngine; var Stats: TMigStats);
const
  cSel =
    'SELECT v.Empresa, v.Almacen, v.Caja, v.Operacion, v.Fecha, ' +
    '       ISNULL(alm.Abreviatura, '''') AS AbrevAlm, ' +
    '       ISNULL(v.ValeEmitido, 0) AS ValeEmitido, ' +
    '       ISNULL(v.Descripcion, '''') AS Descripcion, ' +
    '       ISNULL(v.EmpresaRcgdo, 0) AS EmpresaRcgdo, ' +
    '       ISNULL(v.AlmacenRcgdo, 0) AS AlmacenRcgdo, ' +
    '       ISNULL(v.CajaRcgdo, 0) AS CajaRcgdo, ' +
    '       ISNULL(v.OperacionRcgdo, 0) AS OperacionRcgdo, v.FechaRcgdo, ' +
    '       ISNULL(almr.Abreviatura, '''') AS AbrevAlmR ' +
    'FROM dbo.occajvale v ' +
    'LEFT JOIN dbo.ocalm alm  ON alm.Empresa  = v.Empresa ' +
    '                       AND alm.Almacen  = v.Almacen ' +
    'LEFT JOIN dbo.ocalm almr ON almr.Empresa = v.EmpresaRcgdo ' +
    '                       AND almr.Almacen = v.AlmacenRcgdo ' +
    'WHERE ISNULL(v.ValeEmitido, 0) <> 0';
  cIns =
    'INSERT IGNORE INTO fza_caja_vales ' +
    '  (CODIGO_VL, PIN_SEGURIDAD_VL, ESTADO_VL, IMPORTE_NOMINAL_VL, ' +
    '   FECHA_EMISION_VL, CODIGO_EMP_EMI_VL, CODIGO_ALM_EMI_VL, ' +
    '   CODIGO_CAJA_EMI_VL, NUMERO_OPERACION_EMI_VL, FECHA_REDENCION_VL, ' +
    '   IMPORTE_REDIMIDO_VL, CODIGO_EMP_RED_VL, CODIGO_ALM_RED_VL, ' +
    '   CODIGO_CAJA_RED_VL, NUMERO_OPERACION_RED_VL, OBSERVACIONES_VL, ' +
    '   INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:cod, '''', :estado, :imp, :femi, :emp, :alm, :caja, :num, ' +
    '        :fred, :impred, :empr, :almr, :cajar, :numr, :obs, ' +
    '        :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
  cInsFormaPagoVale =
    'INSERT IGNORE INTO fza_caja_formas_pago ' +
    '  (CODIGO_FP_CFP, DESCRIPCION_FORMA_PAGO_CFP, ' +
    '   ESREQ_REFERENCIA_FORMA_PAGO_CFP, ESCRIPTO_FORMA_PAGO_CFP, ' +
    '   ESDIVISA_FORMA_PAGO_CFP, ESACTIVO_FORMA_PAGO_CFP, ' +
    '   ORDEN_VISUAL_FORMA_PAGO_CFP, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    '   USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (''VALE'', ''Vale tienda'', ''S'', ''N'', ''N'', ''S'', 90, ' +
    '        NOW(), NOW(), :ua, :um)';
  cInsPago =
    'INSERT INTO fza_caja_pagos ' +
    '  (CODIGO_EMP_PAGO, CODIGO_ALM_PAGO, CODIGO_CAJA_PAGO, ' +
    '   SERIE_OPERACION_PAGO, NUMERO_OPERACION_PAGO, ' +
    '   NUMERO_LINEA_PAGO, CODIGO_FP_CFP, IMPORTE_ENTREGADO_PAGO, ' +
    '   IMPORTE_CAMBIO_PAGO, CODIGO_DIVISA_PAGO, RED_BLOCKCHAIN_PAGO, ' +
    '   FACTOR_CAMBIO_PAGO, IMPORTE_DIVISA_PAGO, REFERENCIA_FACPAG, ' +
    '   OBSERVACIONES_PAGO, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    '   USUARIO_ALTA) ' +
    'SELECT :emp, :alm, :caja, '''', :num, ' +
    '       COALESCE((SELECT MAX(pm.NUMERO_LINEA_PAGO) + 1 ' +
    '                   FROM fza_caja_pagos pm ' +
    '                  WHERE pm.CODIGO_EMP_PAGO = :emp ' +
    '                    AND pm.CODIGO_ALM_PAGO = :alm ' +
    '                    AND pm.CODIGO_CAJA_PAGO = :caja ' +
    '                    AND pm.NUMERO_OPERACION_PAGO = :num), 1), ' +
    '       ''VALE'', -ABS(:imp), 0, NULL, NULL, 1, 0, :cod, ' +
    '       :obs, :INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA ' +
    ' WHERE NOT EXISTS ( ' +
    '       SELECT 1 FROM fza_caja_pagos p ' +
    '        WHERE p.CODIGO_EMP_PAGO = :emp ' +
    '          AND p.CODIGO_ALM_PAGO = :alm ' +
    '          AND p.CODIGO_CAJA_PAGO = :caja ' +
    '          AND p.NUMERO_OPERACION_PAGO = :num ' +
    '          AND p.CODIGO_FP_CFP = ''VALE'' ' +
    '          AND p.IMPORTE_ENTREGADO_PAGO < 0 ' +
    '          AND (p.REFERENCIA_FACPAG = :cod ' +
    '               OR ABS(p.IMPORTE_ENTREGADO_PAGO + ABS(:imp)) < 0.005))';
var
  qSrc, qIns, qPago:    TUniQuery;
  iEmp, iAlm, iCaja, iOpe: Integer;
  sEmp, sAlm, sCaja, sNumOp, sCod, sObs: string;
  fImporte:             Double;
  bRedimido:            Boolean;
  bValeGrabado:         Boolean;
begin
  qIns := TUniQuery.Create(nil);
  qPago := TUniQuery.Create(nil);
  qSrc := NuevoQOrigen(Eng, cSel);
  qSrc.UniDirectional := True;
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cIns;
    qPago.Connection := Eng.ConDst;
    qPago.SQL.Text := cInsFormaPagoVale;
    qPago.ParamByName('ua').AsString := Eng.Usuario;
    qPago.ParamByName('um').AsString := Eng.Usuario;
    qPago.ExecSQL;
    qPago.SQL.Text := cInsPago;
    Eng.SetTotal(Eng.ContarOrigen(
      'SELECT COUNT(*) FROM dbo.occajvale WHERE ISNULL(ValeEmitido, 0) <> 0'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      iEmp  := qSrc.FieldByName('Empresa').AsInteger;
      iAlm  := qSrc.FieldByName('Almacen').AsInteger;
      iCaja := qSrc.FieldByName('Caja').AsInteger;
      iOpe  := qSrc.FieldByName('Operacion').AsInteger;
      sEmp  := IntToStr(iEmp);
      sAlm  := UpperCase(Trim(qSrc.FieldByName('AbrevAlm').AsString));
      if sAlm = '' then
        sAlm := IntToStr(iAlm);
      sCaja  := IntToStr(iCaja);
      sNumOp := Format('%.8d', [iOpe]);
      // CODIGO_VL unico por operacion de emision (mismo formato que la app).
      sCod   := Format('VALE_%s_%s_%s_%s', [sEmp, sAlm, sCaja, sNumOp]);
      fImporte := qSrc.FieldByName('ValeEmitido').AsFloat;
      sObs   := Trim(qSrc.FieldByName('Descripcion').AsString);
      // Redimido = tiene operacion de recogida (OperacionRcgdo > 0).
      bRedimido := qSrc.FieldByName('OperacionRcgdo').AsInteger > 0;
      qIns.ParamByName('cod').AsString    := sCod;
      qIns.ParamByName('imp').AsFloat     := fImporte;
      qIns.ParamByName('femi').AsDateTime := qSrc.FieldByName('Fecha').AsDateTime;
      qIns.ParamByName('emp').AsString    := sEmp;
      qIns.ParamByName('alm').AsString    := sAlm;
      qIns.ParamByName('caja').AsString   := sCaja;
      qIns.ParamByName('num').AsString    := sNumOp;
      if sObs <> '' then
        qIns.ParamByName('obs').AsString := Copy(sObs, 1, 200)
      else
        qIns.ParamByName('obs').Clear;
      if bRedimido then
      begin
        qIns.ParamByName('estado').AsString := 'REDIMIDO';
        qIns.ParamByName('impred').AsFloat  := fImporte;
        qIns.ParamByName('empr').AsString   :=
          IntToStr(qSrc.FieldByName('EmpresaRcgdo').AsInteger);
        sAlm := UpperCase(Trim(qSrc.FieldByName('AbrevAlmR').AsString));
        if sAlm = '' then
          sAlm := IntToStr(qSrc.FieldByName('AlmacenRcgdo').AsInteger);
        qIns.ParamByName('almr').AsString  := sAlm;
        qIns.ParamByName('cajar').AsString :=
          IntToStr(qSrc.FieldByName('CajaRcgdo').AsInteger);
        qIns.ParamByName('numr').AsString  :=
          Format('%.8d', [qSrc.FieldByName('OperacionRcgdo').AsInteger]);
        // FechaRcgdo del legacy: real solo cuando se redimio.
        if (not qSrc.FieldByName('FechaRcgdo').IsNull)
        and (qSrc.FieldByName('FechaRcgdo').AsDateTime > EncodeDate(1990, 1, 1))
        then
          qIns.ParamByName('fred').AsDateTime :=
            qSrc.FieldByName('FechaRcgdo').AsDateTime
        else
          qIns.ParamByName('fred').Clear;
      end
      else
      begin
        qIns.ParamByName('estado').AsString := 'PENDIENTE';
        qIns.ParamByName('impred').AsFloat  := 0;
        qIns.ParamByName('fred').Clear;
        qIns.ParamByName('empr').Clear;
        qIns.ParamByName('almr').Clear;
        qIns.ParamByName('cajar').Clear;
        qIns.ParamByName('numr').Clear;
      end;
      RellenarAuditoria(qIns, Eng.Usuario);
      bValeGrabado := True;
      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          bValeGrabado := False;
          Inc(Stats.Errores);
          Eng.LogError('vale', sCod, E.Message, '',
            'requiere occajvale en el origen');
        end;
      end;
      if bValeGrabado then
      begin
        qPago.ParamByName('emp').AsString := sEmp;
        qPago.ParamByName('alm').AsString := sAlm;
        qPago.ParamByName('caja').AsString := sCaja;
        qPago.ParamByName('num').AsString := sNumOp;
        qPago.ParamByName('imp').AsFloat := fImporte;
        qPago.ParamByName('cod').AsString := sCod;
        qPago.ParamByName('obs').AsString := 'Vale emitido: ' + sCod;
        RellenarAuditoria(qPago, Eng.Usuario);
        try
          qPago.ExecSQL;
        except
          on E: Exception do
          begin
            Inc(Stats.Errores);
            Eng.LogError('pago_vale', sCod, E.Message, '',
              'requiere la forma de pago VALE en el destino');
          end;
        end;
      end;
      qSrc.Next;
    end;
  finally
    qPago.Free;
    qIns.Free;
    qSrc.Free;
  end;
end;
end.
