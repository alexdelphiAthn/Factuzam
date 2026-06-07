{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigVales                                                 }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra los vales de tienda del legacy → fza_caja_vales.                    }
{      Origen:  dbo.occajvale (un vale por fila; emitido en una operación y    }
{               opcionalmente "recogido"/redimido en otra).                    }
{      Destino: fza_caja_vales (cabecera del vale: emisión + redención).       }
{                                                                              }
{    CODIGO_VL = 'VALE_<emp>_<almAbrev>_<caja>_<operacion a 8 dígitos>',       }
{    igual que el formato que genera la app, único por operación de emisión.   }
{    ESTADO_VL = 'REDIMIDO' si el vale tiene operación de recogida             }
{    (OperacionRcgdo>0), 'PENDIENTE' en caso contrario.                        }
{                                                                              }
{    Idempotente: PK (CODIGO_VL) + INSERT IGNORE; re-ejecutar no duplica.      }
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
var
  qSrc, qIns:           TUniQuery;
  iEmp, iAlm, iCaja, iOpe: Integer;
  sEmp, sAlm, sCaja, sNumOp, sCod, sObs: string;
  fImporte:             Double;
  bRedimido:            Boolean;
begin
  qIns := TUniQuery.Create(nil);
  qSrc := NuevoQOrigen(Eng, cSel);
  qSrc.UniDirectional := True;
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cIns;
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
      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('vale', sCod, E.Message, '',
            'requiere occajvale en el origen');
        end;
      end;
      qSrc.Next;
    end;
  finally
    qIns.Free;
    qSrc.Free;
  end;
end;
end.
