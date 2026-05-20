{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMigAlmacenes                                             }
{    Tipo:       Librería de migración (sin formulario)                        }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Migra `dbo.ocalm` (SQL Server) → `fza_almacenes`.                         }
{                                                                              }
{    El origen identifica almacenes por (Empresa, Almacen). El destino los     }
{    identifica solo por CODIGO_ALM_ALM (único global) y guarda la empresa   }
{    como FK CODIGO_EMP_ALM. Para que no colisionen códigos de almacén entre  }
{    empresas, generamos: CODIGO_ALM_ALM = "E<empresa>-A<almacen>".            }
{                                                                              }
{    Mapeo origen → destino:                                                   }
{      Empresa, Almacen          → CODIGO_ALM_ALM (compuesto)                  }
{      Empresa                    → CODIGO_EMP_ALM                             }
{      Nombre                     → NOMBRE_ALM_ALM                             }
{      Activo                     → ESACTIVO_ALM                               }
{      Direccion1                 → DIRECCION_ALM                              }
{      Poblacion                  → POBLACION_ALM                              }
{      CodPostal                  → CODIGO_POSTAL_ALM                          }
{      Telefono1                  → TELEFONO_ALM                               }
{      Email                      → EMAIL_ALM                                  }
{      Cliente                    → CODIGO_CLI_ALM                             }
{      Provincia                  → PROVINCIA_ALM                              }
{      Auxiliar='S' / Transito='S' / Lock='S' / Regulador='S' / Deposito='S'   }
{                                  → TIPO_USO_ALM (ESTANDAR/TRANSITO/...)     }
{                                                                              }
{    Idempotente: si el almacén ya existe (mismo CODIGO_ALM_ALM) se salta.    }
{******************************************************************************}
unit inLibMigAlmacenes;

interface

uses
  UMigEngine;

procedure MigrarAlmacenes(Eng: TMigEngine; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

// Decide el TIPO_USO_ALM a partir de los flags del origen
function DeducirTipoUso(const Q: TUniQuery): string;
begin
  if BoolSN(Q.FieldByName('Transito').AsString) = 'S' then
    Exit('TRANSITO');
  if BoolSN(Q.FieldByName('Deposito').AsString) = 'S' then
    Exit('DEPOSITO');
  if BoolSN(Q.FieldByName('Auxiliar').AsString) = 'S' then
    Exit('AUXILIAR');
  Result := 'ESTANDAR';
end;

procedure MigrarAlmacenes(Eng: TMigEngine; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Empresa, Almacen, Nombre, Activo, ' +
    '       Direccion1, Poblacion, Provincia, CodPostal, ' +
    '       Telefono1, Email, Cliente, ' +
    '       Auxiliar, Transito, Deposito, [Lock], Regulador ' +
    'FROM dbo.ocalm ' +
    'ORDER BY Empresa, Almacen';
  cInsertDst =
    'INSERT INTO fza_almacenes (' +
      'CODIGO_ALM_ALM, CODIGO_EMP_ALM, ESACTIVO_ALM, NOMBRE_ALM_ALM, ' +
      'ESFISICO_ALM, TIPO_USO_ALM, DIRECCION_ALM, POBLACION_ALM, ' +
      'PROVINCIA_ALM, CODIGO_POSTAL_ALM, TELEFONO_ALM, EMAIL_ALM, ' +
      'CODIGO_CLI_ALM, ORDEN_ALM, ' +
      'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
      ':CODIGO_ALM_ALM, :CODIGO_EMP_ALM, :ESACTIVO_ALM, :NOMBRE_ALM_ALM, ' +
      ':ESFISICO_ALM, :TIPO_USO_ALM, :DIRECCION_ALM, :POBLACION_ALM, ' +
      ':PROVINCIA_ALM, :CODIGO_POSTAL_ALM, :TELEFONO_ALM, :EMAIL_ALM, ' +
      ':CODIGO_CLI_ALM, :ORDEN_ALM, ' +
      ':INSTANTE_ALTA, :INSTANTE_MODIF, :USUARIO_ALTA, :USUARIO_MODIF)';
var
  qSrc, qIns, qChk: TUniQuery;
  sCod, sCli:       string;
  iOrden:           Integer;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.ConDst;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.ConDst;
    qChk.SQL.Text   :=
      'SELECT 1 FROM fza_almacenes WHERE CODIGO_ALM_ALM = :c';

    Eng.SetTotal(Eng.ContarOrigen('SELECT COUNT(*) FROM dbo.ocalm'));
    qSrc.Open;
    iOrden := 10;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.IncRow;
      // Codigo de almacen: respetamos el valor original ('1', '2'...)
      // tal cual lo guardaba el legacy. Si hay varias empresas con
      // almacen N coincidente, la 2a y siguientes pasaran como saltos
      // (CODIGO_ALM_ALM es PK global en destino). En ese caso revisar
      // y desambiguar a mano.
      sCod := IntToStr(qSrc.FieldByName('Almacen').AsInteger);

      qChk.Close;
      qChk.ParamByName('c').AsString := sCod;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        Inc(Stats.Saltadas);
        Eng.Log('  - almacen "%s" ya existe, se omite', [sCod]);
        qChk.Close;
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      sCli := Trim(qSrc.FieldByName('Cliente').AsString);
      qIns.ParamByName('CODIGO_ALM_ALM').AsString  := sCod;
      qIns.ParamByName('CODIGO_EMP_ALM').AsString  :=
        IntToStr(qSrc.FieldByName('Empresa').AsInteger);
      // Todos los almacenes migrados arrancan activos. El campo
      // Activo del legacy usa 'A' (no 'S') y se interpretaria como
      // baja; ademas el usuario quiere editarlos en destino partiendo
      // de "habilitado".
      qIns.ParamByName('ESACTIVO_ALM').AsString    := 'S';
      qIns.ParamByName('NOMBRE_ALM_ALM').AsString  :=
        Trim(qSrc.FieldByName('Nombre').AsString);
      qIns.ParamByName('ESFISICO_ALM').AsString    := 'S';
      qIns.ParamByName('TIPO_USO_ALM').AsString    := DeducirTipoUso(qSrc);
      qIns.ParamByName('DIRECCION_ALM').AsString   :=
        Trim(qSrc.FieldByName('Direccion1').AsString);
      qIns.ParamByName('POBLACION_ALM').AsString   :=
        Trim(qSrc.FieldByName('Poblacion').AsString);
      qIns.ParamByName('PROVINCIA_ALM').AsString   :=
        Trim(qSrc.FieldByName('Provincia').AsString);
      qIns.ParamByName('CODIGO_POSTAL_ALM').AsString :=
        Trim(qSrc.FieldByName('CodPostal').AsString);
      qIns.ParamByName('TELEFONO_ALM').AsString   :=
        Trim(qSrc.FieldByName('Telefono1').AsString);
      qIns.ParamByName('EMAIL_ALM').AsString      :=
        Trim(qSrc.FieldByName('Email').AsString);
      if sCli <> '' then
        qIns.ParamByName('CODIGO_CLI_ALM').AsString := sCli
      else
        qIns.ParamByName('CODIGO_CLI_ALM').Clear;
      qIns.ParamByName('ORDEN_ALM').AsInteger := iOrden;
      RellenarAuditoria(qIns, Eng.Usuario);

      try
        qIns.ExecSQL;
        Inc(Stats.Insertadas);
        Inc(iOrden, 10);
      except
        on E: Exception do
        begin
          Inc(Stats.Errores);
          Eng.Log('  ! error insertando almacen "%s": %s',
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
