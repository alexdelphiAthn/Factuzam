{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigProveedores                                           }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocpro` (SQL Server) → `fza_proveedores`.                       }
{                                                                              }
{    El destino almacena dos columnas separadas:                               }
{      RAZON_SOCIAL_PRV → denominación legal (ej "FRANK SAUL FASHIONS LTD")    }
{      NOMBRE_PRV       → nombre comercial / alias corto (ej "MASCARA")        }
{    (NOMBRE_PRV se anade con DESARROLLOS EN CURSO/proveedores_nombre.sql      }
{     en BBDD ya creadas; en BBDD nuevas viene en factuzam_original.sql).      }
{                                                                              }
{    Mapeo origen → destino (resumen):                                         }
{      Proveedor (int)        → CODIGO_PRV_PRV                                 }
{      Nombre                 → NOMBRE_PRV                                     }
{      RazonSocial            → RAZON_SOCIAL_PRV                               }
{      NIF                    → NIF_PRV                                        }
{      TelefonoMovil          → MOVIL_PRV                                      }
{      Telefono1              → TELEFONO_PRV                                   }
{      Email                  → EMAIL_PRV                                      }
{      Direccion1/2           → DIRECCION1_PRV / DIRECCION2_PRV                }
{      Poblacion              → POBLACION_PRV                                  }
{      Provincia              → PROVINCIA_PRV                                  }
{      CodPostal              → CODIGO_POSTAL_PRV                              }
{      Pais                   → PAIS_PRV                                       }
{      PersonaContacto        → CONTACTO_PRV                                   }
{      IBAN                   → IBAN_PRV                                       }
{      Observacion (text)     → OBSERVACIONES_PRV                              }
{      Estado='B'             → ESACTIVO_PRV='N', resto 'S'                    }
{      Abreviatura            → REFERENCIA_PRV                                 }
{                                                                              }
{    Idempotente: si el proveedor ya existe (mismo CODIGO_PRV_PRV) se salta.  }
{******************************************************************************}
unit inLibMigProveedores;

interface

uses
  UMigEngine;

procedure MigrarProveedores(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarProveedores(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Proveedor, Nombre, RazonSocial, NIF, ' +
    '       Direccion1, Direccion2, CodPostal, Poblacion, Provincia, ' +
    '       Pais, Telefono1, TelefonoMovil, Email, ' +
    '       PersonaContacto, Abreviatura, IBAN, Estado, ' +
    '       CAST(Observacion AS varchar(4000)) AS Observacion ' +
    'FROM dbo.ocpro ' +
    'ORDER BY Proveedor';
  cInsertDst =
    'INSERT INTO fza_proveedores (' +
      'CODIGO_PRV_PRV, ESACTIVO_PRV, RAZON_SOCIAL_PRV, NOMBRE_PRV, ' +
      'NIF_PRV, MOVIL_PRV, TELEFONO_PRV, EMAIL_PRV, ' +
      'DIRECCION1_PRV, DIRECCION2_PRV, POBLACION_PRV, PROVINCIA_PRV, ' +
      'CODIGO_POSTAL_PRV, PAIS_PRV, ' +
      'OBSERVACIONES_PRV, REFERENCIA_PRV, CONTACTO_PRV, IBAN_PRV, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_PRV_PRV, :ESACTIVO_PRV, :RAZON_SOCIAL_PRV, :NOMBRE_PRV, ' +
      ':NIF_PRV, :MOVIL_PRV, :TELEFONO_PRV, :EMAIL_PRV, ' +
      ':DIRECCION1_PRV, :DIRECCION2_PRV, :POBLACION_PRV, :PROVINCIA_PRV, ' +
      ':CODIGO_POSTAL_PRV, :PAIS_PRV, ' +
      ':OBSERVACIONES_PRV, :REFERENCIA_PRV, :CONTACTO_PRV, :IBAN_PRV, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';

  function DeducirActivo(const sEstado: string): string;
  var s: string;
  begin
    s := UpperCase(Trim(sEstado));
    if s = 'B' then
      Result := 'N'
    else
      Result := 'S';
  end;

var
  qSrc, qIns, qChk:                  TUniQuery;
  sCod, sNombre, sRazon, sObs:       string;
  sRazonDst:                         string;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT RAZON_SOCIAL_PRV FROM fza_proveedores ' +
      'WHERE CODIGO_PRV_PRV = :c';

    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocpro'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sCod    := IntToStr(qSrc.FieldByName('Proveedor').AsInteger);
      sNombre := Trim(qSrc.FieldByName('Nombre').AsString);
      sRazon  := Trim(qSrc.FieldByName('RazonSocial').AsString);
      if sRazon  = '' then sRazon  := sNombre;
      if sRazon  = '' then sRazon  := 'Proveedor ' + sCod;
      if sNombre = '' then sNombre := sRazon;

      qChk.Close;
      qChk.ParamByName('c').AsString := sCod;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        sRazonDst := Trim(qChk.FieldByName('RAZON_SOCIAL_PRV').AsString);
        Inc(Stats.Saltadas);
        Eng.LogSalto('proveedor', sCod,
          'PK ya existe (cuidado: seed Northwind 3-23 colisiona con ' +
          'codigos reales del legacy), se conserva destino',
          sRazon, sRazonDst);
        qChk.Close;
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      sObs := Trim(qSrc.FieldByName('Observacion').AsString);

      qIns.ParamByName('CODIGO_PRV_PRV').AsString  := sCod;
      qIns.ParamByName('ESACTIVO_PRV').AsString    :=
        DeducirActivo(qSrc.FieldByName('Estado').AsString);
      qIns.ParamByName('RAZON_SOCIAL_PRV').AsString := sRazon;
      qIns.ParamByName('NOMBRE_PRV').AsString       := sNombre;
      qIns.ParamByName('NIF_PRV').AsString          :=
        Trim(qSrc.FieldByName('NIF').AsString);
      qIns.ParamByName('MOVIL_PRV').AsString        :=
        Trim(qSrc.FieldByName('TelefonoMovil').AsString);
      qIns.ParamByName('TELEFONO_PRV').AsString     :=
        Trim(qSrc.FieldByName('Telefono1').AsString);
      qIns.ParamByName('EMAIL_PRV').AsString        :=
        Trim(qSrc.FieldByName('Email').AsString);
      qIns.ParamByName('DIRECCION1_PRV').AsString   :=
        Trim(qSrc.FieldByName('Direccion1').AsString);
      qIns.ParamByName('DIRECCION2_PRV').AsString   :=
        Trim(qSrc.FieldByName('Direccion2').AsString);
      qIns.ParamByName('POBLACION_PRV').AsString    :=
        Trim(qSrc.FieldByName('Poblacion').AsString);
      qIns.ParamByName('PROVINCIA_PRV').AsString    :=
        Trim(qSrc.FieldByName('Provincia').AsString);
      qIns.ParamByName('CODIGO_POSTAL_PRV').AsString :=
        Trim(qSrc.FieldByName('CodPostal').AsString);
      qIns.ParamByName('PAIS_PRV').AsString         :=
        Trim(qSrc.FieldByName('Pais').AsString);
      if sObs <> '' then
        qIns.ParamByName('OBSERVACIONES_PRV').AsString := sObs
      else
        qIns.ParamByName('OBSERVACIONES_PRV').Clear;
      qIns.ParamByName('REFERENCIA_PRV').AsString   :=
        Trim(qSrc.FieldByName('Abreviatura').AsString);
      qIns.ParamByName('CONTACTO_PRV').AsString     :=
        Trim(qSrc.FieldByName('PersonaContacto').AsString);
      qIns.ParamByName('IBAN_PRV').AsString         :=
        Trim(qSrc.FieldByName('IBAN').AsString);
      RellenarAuditoria(qIns, Eng.Usuario);

      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error insertando proveedor "%s": %s',
                  [sCod, E.Message]);
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
