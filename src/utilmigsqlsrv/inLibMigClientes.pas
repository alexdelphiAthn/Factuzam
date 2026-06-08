{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigClientes                                              }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.occli` (SQL Server) → `fza_clientes`.                          }
{                                                                              }
{    Mapeo origen → destino (resumen):                                         }
{      Cliente              → CODIGO_CLI_CLI                                   }
{      RazonSocial          → RAZON_SOCIAL_CLI                                 }
{      NIF                  → NIF_CLI                                          }
{      TelefonoMovil        → MOVIL_CLI                                        }
{      Telefono1            → TELEFONO_CLI                                     }
{      Email                → EMAIL_CLI                                        }
{      Direccion1/2         → DIRECCION1_CLI / DIRECCION2_CLI                  }
{      Poblacion            → POBLACION_CLI                                    }
{      Provincia            → PROVINCIA_CLI (fallback: POBLACION_CLI si vacia) }
{      CodPostal            → CODIGO_POSTAL_CLI                                }
{      Pais                 → IGNORADO. Se fuerza CODIGO_PAI_CLI='ES'         }
{                              y NOMBRE_PAI_CLI='España' para TODOS los       }
{                              clientes migrados (el campo del legacy llega   }
{                              inconsistente con tildes/may-min).             }
{      PersonaContacto      → CONTACTO_CLI                                    }
{      Estado               → ESACTIVO_CLI ('S' si =='S' o vacío, 'N' si =='B')}
{      FormaPago + TipoEfecto → CODIGO_FP_CLI                                  }
{      Tarifa               → IGNORADA. TARIFA_ARTICULO_CLI='PVP' para todos. }
{      IBAN                 → IBAN_CLI                                         }
{      Observacion          → OBSERVACIONES_CLI (text)                         }
{      ReferenciaProveedor  → REFERENCIA_CLI                                  }
{                                                                              }
{    Defaults adicionales aplicados a TODOS los migrados:                     }
{      ESRETENCIONES_CLI         = 'N'  (sin IRPF)                            }
{      ESIVA_RECARGO_CLI         = 'N'                                        }
{      ESIVA_EXENTO_CLI          = 'N'                                        }
{      ESINTRACOMUNITARIO_CLI    = 'N'                                        }
{      ESPERMITE_DEUDA_CLI       = 'S'  (permite venta a credito)             }
{      TOTAL_LIMITE_CREDITO_CLI  = 10000                                      }
{                                                                              }
{    Idempotente: si el cliente ya existe se salta sin error.                  }
{******************************************************************************}
unit inLibMigClientes;

interface

uses
  UMigEngine;

procedure MigrarClientes(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarClientes(Eng: TMigEngine; var Stats: TMigStats);
const
  // Observacion es text en SQL Server; CAST a varchar para evitar problemas
  // con CHARINDEX y largos. 4000 bytes deberia bastar para una nota.
  cSelectSrc =
    'SELECT Cliente, RazonSocial, Nombre, NIF, ' +
    '       Direccion1, Direccion2, CodPostal, Poblacion, Provincia, ' +
    '       Pais, Telefono1, TelefonoMovil, Email, ' +
    '       PersonaContacto, ReferenciaProveedor, IBAN, ' +
    '       Estado, FormaPago, TipoEfecto, ' +
    '       CAST(Observacion AS varchar(4000)) AS Observacion ' +
    'FROM dbo.occli ' +
    'ORDER BY Cliente';
  cInsertDst =
    'INSERT INTO fza_clientes (' +
      'CODIGO_CLI_CLI, ESACTIVO_CLI, RAZON_SOCIAL_CLI, NIF_CLI, ' +
      'MOVIL_CLI, TELEFONO_CLI, EMAIL_CLI, ' +
      'DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, PROVINCIA_CLI, ' +
      'CODIGO_POSTAL_CLI, CODIGO_PAI_CLI, NOMBRE_PAI_CLI, ' +
      'OBSERVACIONES_CLI, REFERENCIA_CLI, CONTACTO_CLI, ' +
      'IBAN_CLI, ESIVA_RECARGO_CLI, ESRETENCIONES_CLI, ' +
      'ESIVA_EXENTO_CLI, ESINTRACOMUNITARIO_CLI, ' +
      'CODIGO_FP_CLI, TARIFA_ARTICULO_CLI, ' +
      'ESPERMITE_DEUDA_CLI, TOTAL_LIMITE_CREDITO_CLI, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_CLI_CLI, :ESACTIVO_CLI, :RAZON_SOCIAL_CLI, :NIF_CLI, ' +
      ':MOVIL_CLI, :TELEFONO_CLI, :EMAIL_CLI, ' +
      ':DIRECCION1_CLI, :DIRECCION2_CLI, :POBLACION_CLI, :PROVINCIA_CLI, ' +
      ':CODIGO_POSTAL_CLI, :CODIGO_PAI_CLI, :NOMBRE_PAI_CLI, ' +
      ':OBSERVACIONES_CLI, :REFERENCIA_CLI, :CONTACTO_CLI, ' +
      ':IBAN_CLI, :ESIVA_RECARGO_CLI, :ESRETENCIONES_CLI, ' +
      ':ESIVA_EXENTO_CLI, :ESINTRACOMUNITARIO_CLI, ' +
      ':CODIGO_FP_CLI, :TARIFA_ARTICULO_CLI, ' +
      ':ESPERMITE_DEUDA_CLI, :TOTAL_LIMITE_CREDITO_CLI, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';

  function DeducirActivo(const sEstado: string): string;
  var s: string;
  begin
    s := UpperCase(Trim(sEstado));
    // 'B' = baja en el legacy; 'A' o 'S' o vacio = activo.
    if (s = 'B') or (s = 'N') then
      Result := 'N'
    else
      Result := 'S';
  end;

var
  qSrc, qIns, qChk: TUniQuery;
  sCod, sRazon, sObs, sFP, sRazonDst: string;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.ConDst;
    // En el chk traemos la RAZON_SOCIAL_CLI para poder enseñar en el
    // log que dato hay en destino vs el del origen y ayudar a decidir
    // si la colision es un duplicado real o ruido del seed demo.
    qChk.SQL.Text   :=
      'SELECT RAZON_SOCIAL_CLI FROM fza_clientes ' +
      'WHERE CODIGO_CLI_CLI = :c';
    // Re-ejecutable: en una BBDD ya migrada borramos SOLO los clientes que
    // migro este usuario (USUARIO_ALTA) y los recreamos con los datos
    // actuales. El seed demo (otro USUARIO_ALTA) lo sigue conservando el
    // chequeo de PK de mas abajo, asi que no se toca. Sin esto, re-correr
    // 'clientes' solo saltaba los ya existentes (no refrescaba). OJO: la
    // deuda (TOTAL_DEUDA_CLI) la rellena 'ventas' despues, asi que el orden
    // de re-migracion es clientes -> ventas.
    EjecutarSQL(Eng, 'DELETE FROM fza_clientes WHERE USUARIO_ALTA = ' +
      ValorOrNull(Eng.Usuario));

    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.occli'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sCod   := Trim(qSrc.FieldByName('Cliente').AsString);
      sRazon := Trim(qSrc.FieldByName('RazonSocial').AsString);
      if sRazon = '' then
        sRazon := Trim(qSrc.FieldByName('Nombre').AsString);
      if sCod = '' then
      begin
        Inc(Stats.Saltadas);
        Eng.LogSalto('cliente', '<vacio>',
          'codigo de cliente vacio en origen (registro descartado)',
          sRazon);
        qSrc.Next;
        Continue;
      end;
      if sRazon = '' then
        sRazon := sCod;

      qChk.Close;
      qChk.ParamByName('c').AsString := sCod;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        sRazonDst := Trim(qChk.FieldByName('RAZON_SOCIAL_CLI').AsString);
        Inc(Stats.Saltadas);
        Eng.LogSalto('cliente', sCod,
          'PK ya existe en destino, se conserva destino',
          sRazon, sRazonDst);
        qChk.Close;
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      // Forma de pago: en origen viene como TipoEfecto (int) + un FormaPago
      // descriptivo. El destino usa codigo de forma_pago. Tomamos el
      // TipoEfecto como CODIGO_FP_CLI cuando hay valor; si no, NULL.
      if qSrc.FieldByName('TipoEfecto').IsNull then
        sFP := ''
      else
        sFP := IntToStr(qSrc.FieldByName('TipoEfecto').AsInteger);
      // Tarifa del legacy se ignora — pondremos 'PVP' fija para todos.
      sObs := Trim(qSrc.FieldByName('Observacion').AsString);

      qIns.ParamByName('CODIGO_CLI_CLI').AsString := sCod;
      qIns.ParamByName('ESACTIVO_CLI').AsString   :=
        DeducirActivo(qSrc.FieldByName('Estado').AsString);
      qIns.ParamByName('RAZON_SOCIAL_CLI').AsString := sRazon;
      qIns.ParamByName('NIF_CLI').AsString          :=
        Trim(qSrc.FieldByName('NIF').AsString);
      qIns.ParamByName('MOVIL_CLI').AsString        :=
        Trim(qSrc.FieldByName('TelefonoMovil').AsString);
      qIns.ParamByName('TELEFONO_CLI').AsString     :=
        Trim(qSrc.FieldByName('Telefono1').AsString);
      qIns.ParamByName('EMAIL_CLI').AsString        :=
        Trim(qSrc.FieldByName('Email').AsString);
      qIns.ParamByName('DIRECCION1_CLI').AsString   :=
        Trim(qSrc.FieldByName('Direccion1').AsString);
      qIns.ParamByName('DIRECCION2_CLI').AsString   :=
        Trim(qSrc.FieldByName('Direccion2').AsString);
      qIns.ParamByName('POBLACION_CLI').AsString    :=
        Trim(qSrc.FieldByName('Poblacion').AsString);
      // Si la provincia origen viene vacia, copiamos la poblacion.
      // En el legacy de Herreras muchos clientes solo tienen
      // Poblacion rellena y Provincia queda en blanco; en destino
      // queremos ver al menos algo en la columna Provincia.
      qIns.ParamByName('PROVINCIA_CLI').AsString    :=
        Trim(qSrc.FieldByName('Provincia').AsString);
      if qIns.ParamByName('PROVINCIA_CLI').AsString = '' then
        qIns.ParamByName('PROVINCIA_CLI').AsString :=
          Trim(qSrc.FieldByName('Poblacion').AsString);
      qIns.ParamByName('CODIGO_POSTAL_CLI').AsString :=
        Trim(qSrc.FieldByName('CodPostal').AsString);
      // Pais hardcoded a ES/España para todos los clientes migrados.
      // El campo Pais del legacy se ignora (suele venir vacio o con
      // texto inconsistente como "España" en mayusculas, minusculas,
      // con tildes...). El usuario reasigna a mano si algun cliente
      // es realmente extranjero.
      qIns.ParamByName('CODIGO_PAI_CLI').AsString := 'ES';
      qIns.ParamByName('NOMBRE_PAI_CLI').AsString := 'España';
      if sObs <> '' then
        qIns.ParamByName('OBSERVACIONES_CLI').AsString := sObs
      else
        qIns.ParamByName('OBSERVACIONES_CLI').Clear;
      qIns.ParamByName('REFERENCIA_CLI').AsString   :=
        Trim(qSrc.FieldByName('ReferenciaProveedor').AsString);
      qIns.ParamByName('CONTACTO_CLI').AsString     :=
        Trim(qSrc.FieldByName('PersonaContacto').AsString);
      qIns.ParamByName('IBAN_CLI').AsString         :=
        Trim(qSrc.FieldByName('IBAN').AsString);
      qIns.ParamByName('ESIVA_RECARGO_CLI').AsString      := 'N';
      // Sin retenciones / IRPF: el migrador no aplica retenciones a
      // ningun cliente (lo decide el usuario despues si hace falta).
      qIns.ParamByName('ESRETENCIONES_CLI').AsString      := 'N';
      qIns.ParamByName('ESIVA_EXENTO_CLI').AsString       := 'N';
      qIns.ParamByName('ESINTRACOMUNITARIO_CLI').AsString := 'N';
      if sFP <> '' then
        qIns.ParamByName('CODIGO_FP_CLI').AsString := sFP
      else
        qIns.ParamByName('CODIGO_FP_CLI').Clear;
      // Tarifa por defecto = PVP para todos los migrados.
      // El campo Tarifa del legacy se ignora: el usuario lo ajusta a
      // mano si algun cliente debe llevar tarifa diferente.
      qIns.ParamByName('TARIFA_ARTICULO_CLI').AsString := 'PVP';
      // Permite venta a credito con limite 10 000 para todos.
      qIns.ParamByName('ESPERMITE_DEUDA_CLI').AsString  := 'S';
      qIns.ParamByName('TOTAL_LIMITE_CREDITO_CLI').AsFloat := 10000;
      RellenarAuditoria(qIns, Eng.Usuario);

      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.LogError('cliente', sCod, E.Message, sRazon,
            'si dice "Data too long for column CODIGO_CLI_*", ' +
            'ejecuta DESARROLLOS EN CURSO/widen_codigo_cli.sql');
          raise;
        end;
      end;
      qSrc.Next;
    end;
  finally
    qChk.Free;
    qIns.Free;
    qSrc.Free;
  end;
end;

end.
