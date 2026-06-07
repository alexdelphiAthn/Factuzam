{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigEmpresas                                              }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocemp` (SQL Server) → `fza_empresas`.                          }
{                                                                              }
{    Mapeo origen → destino:                                                   }
{      Empresa       (int)        → CODIGO_EMP_EMP (texto)                     }
{      RazonSocial   (varchar 60) → RAZON_SOCIAL_EMP                           }
{      NIF                         → NIF_EMP                                   }
{      Direccion1                  → DIRECCION1_EMP                            }
{      Direccion2                  → DIRECCION2_EMP                            }
{      CodPostal                   → CODIGO_POSTAL_EMP                         }
{      Poblacion                   → POBLACION_EMP                             }
{      Provincia                   → PROVINCIA_EMP                             }
{      Telefono1                   → MOVIL_EMP   (mejor que dejar NULL)        }
{      Email                       → EMAIL_EMP                                 }
{      Estado (<>'B')              → ESACTIVO_EMP = 'S' por defecto ('B'→'N')   }
{      IBAN                        → IBAN_EMP                                  }
{                                                                              }
{    Idempotente: si la empresa ya existe (mismo CODIGO_EMP_EMP) se salta.    }
{******************************************************************************}
unit inLibMigEmpresas;

interface

uses
  UMigEngine;

procedure MigrarEmpresas(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

procedure MigrarEmpresas(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Empresa, RazonSocial, Nombre, NIF, ' +
    '       Direccion1, Direccion2, CodPostal, Poblacion, Provincia, ' +
    '       Telefono1, Email, Estado, IBAN ' +
    'FROM dbo.ocemp ' +
    'ORDER BY Empresa';
  cInsertDst =
    'INSERT INTO fza_empresas (' +
      'CODIGO_EMP_EMP, ESACTIVO_EMP, RAZON_SOCIAL_EMP, NIF_EMP, ' +
      'MOVIL_EMP, EMAIL_EMP, DIRECCION1_EMP, DIRECCION2_EMP, ' +
      'CODIGO_POSTAL_EMP, POBLACION_EMP, PROVINCIA_EMP, ' +
      'CODIGO_PAI_EMP, NOMBRE_PAI_EMP, IBAN_EMP, GRUPO_ZONA_IVA_EMP, ' +
      'ESRETENCIONES_EMP, ESREGIMENESPECIALAGRICOLA_EMP, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_EMP_EMP, :ESACTIVO_EMP, :RAZON_SOCIAL_EMP, :NIF_EMP, ' +
      ':MOVIL_EMP, :EMAIL_EMP, :DIRECCION1_EMP, :DIRECCION2_EMP, ' +
      ':CODIGO_POSTAL_EMP, :POBLACION_EMP, :PROVINCIA_EMP, ' +
      ':CODIGO_PAI_EMP, :NOMBRE_PAI_EMP, :IBAN_EMP, :GRUPO_ZONA_IVA_EMP, ' +
      ':ESRETENCIONES_EMP, :ESREGIMENESPECIALAGRICOLA_EMP, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
  // Activo por defecto: en el legacy 'B' = baja; cualquier otro valor
  // (incluido vacio o 'A') se considera ACTIVO. Antes se usaba BoolSN, que
  // exige 'S', y como ocemp.Estado no usa 'S' todas las empresas salian 'N'.
  function DeducirActivo(const sEstado: string): string;
  begin
    if UpperCase(Trim(sEstado)) = 'B' then
      Result := 'N'
    else
      Result := 'S';
  end;
var
  qSrc, qIns, qChk: TUniQuery;
  sCod, sRazon, sRazonDst: string;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT RAZON_SOCIAL_EMP FROM fza_empresas ' +
      'WHERE CODIGO_EMP_EMP = :c';

    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocemp'));
    qSrc.Open;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      sCod   := IntToStr(qSrc.FieldByName('Empresa').AsInteger);
      sRazon := Trim(qSrc.FieldByName('RazonSocial').AsString);
      if sRazon = '' then
        sRazon := Trim(qSrc.FieldByName('Nombre').AsString);
      if sRazon = '' then
        sRazon := 'Empresa ' + sCod;

      qChk.Close;
      qChk.ParamByName('c').AsString := sCod;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        sRazonDst := Trim(qChk.FieldByName('RAZON_SOCIAL_EMP').AsString);
        Inc(Stats.Saltadas);
        Eng.LogSalto('empresa', sCod,
          'PK ya existe (probable seed AGRICULTOR de ' +
          'factuzam_original.sql), se conserva destino',
          sRazon, sRazonDst);
        qChk.Close;
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      qIns.ParamByName('CODIGO_EMP_EMP').AsString  := sCod;
      qIns.ParamByName('ESACTIVO_EMP').AsString    :=
        DeducirActivo(qSrc.FieldByName('Estado').AsString);
      qIns.ParamByName('RAZON_SOCIAL_EMP').AsString := sRazon;
      qIns.ParamByName('NIF_EMP').AsString          :=
        Trim(qSrc.FieldByName('NIF').AsString);
      qIns.ParamByName('MOVIL_EMP').AsString        :=
        Trim(qSrc.FieldByName('Telefono1').AsString);
      qIns.ParamByName('EMAIL_EMP').AsString        :=
        Trim(qSrc.FieldByName('Email').AsString);
      qIns.ParamByName('DIRECCION1_EMP').AsString   :=
        Trim(qSrc.FieldByName('Direccion1').AsString);
      qIns.ParamByName('DIRECCION2_EMP').AsString   :=
        Trim(qSrc.FieldByName('Direccion2').AsString);
      qIns.ParamByName('CODIGO_POSTAL_EMP').AsString :=
        Trim(qSrc.FieldByName('CodPostal').AsString);
      qIns.ParamByName('POBLACION_EMP').AsString    :=
        Trim(qSrc.FieldByName('Poblacion').AsString);
      qIns.ParamByName('PROVINCIA_EMP').AsString    :=
        Trim(qSrc.FieldByName('Provincia').AsString);
      qIns.ParamByName('CODIGO_PAI_EMP').AsString   := 'ES';
      qIns.ParamByName('NOMBRE_PAI_EMP').AsString   := 'España';
      qIns.ParamByName('IBAN_EMP').AsString         :=
        Trim(qSrc.FieldByName('IBAN').AsString);
      qIns.ParamByName('GRUPO_ZONA_IVA_EMP').AsString := '1';
      qIns.ParamByName('ESRETENCIONES_EMP').AsString  := 'S';
      qIns.ParamByName('ESREGIMENESPECIALAGRICOLA_EMP').AsString := 'N';
      RellenarAuditoria(qIns, Eng.Usuario);

      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error insertando empresa "%s": %s',
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
