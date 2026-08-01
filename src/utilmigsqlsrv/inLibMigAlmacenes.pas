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
  UMigEngine, UMigCatalogo;

procedure MigrarAlmacenes(const Eng: IContextoMigracion; var Stats: TMigStats);

implementation

uses
  System.SysUtils,
  Data.DB, Uni;

function NombreSugiereDeposito(const Q: TUniQuery): Boolean;
var
  sNombre: string;
begin
  sNombre := UpperCase(Trim(Q.FieldByName('Nombre').AsString)) + '|' +
             UpperCase(Trim(Q.FieldByName('Abreviatura').AsString));
  Result := Pos('DEPO', sNombre) > 0;
end;

// La selección de la UI tiene prioridad sobre los flags del origen.
function DeducirTipoUso(const Q: TUniQuery;
                        EsDepositoSeleccionado: Boolean): string;
begin
  if EsDepositoSeleccionado then
    Result := 'DEPÓSITO'
  else if BoolSN(Q.FieldByName('Transito').AsString) = 'S' then
    Result := 'TRÁNSITO'
  else if BoolSN(Q.FieldByName('Auxiliar').AsString) = 'S' then
    Result := 'AUXILIAR'
  else
    Result := 'ESTANDAR';
end;

procedure MigrarAlmacenes(const Eng: IContextoMigracion; var Stats: TMigStats);
const
  cSelectSrc =
    'SELECT Empresa, Almacen, Nombre, Abreviatura, Activo, ' +
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
  qSrc, qIns, qChk, qUpd: TUniQuery;
  sCod, sCli, sTipoUso:   string;
  sTipoUsoExistente:      string;
  iEmpresa, iAlmacen:     Integer;
  iOrden:                 Integer;
  EsDeposito:             Boolean;
begin
  qSrc := NuevoQOrigen(Eng, cSelectSrc);
  qIns := TUniQuery.Create(nil);
  qChk := TUniQuery.Create(nil);
  qUpd := TUniQuery.Create(nil);
  try
    qIns.Connection := Eng.Datos.ConexionDestino;
    qIns.SQL.Text   := cInsertDst;
    qChk.Connection := Eng.Datos.ConexionDestino;
    qChk.SQL.Text   :=
      'SELECT TIPO_USO_ALM FROM fza_almacenes ' +
      'WHERE CODIGO_ALM_ALM = :c';
    qUpd.Connection := Eng.Datos.ConexionDestino;
    qUpd.SQL.Text :=
      'UPDATE fza_almacenes SET TIPO_USO_ALM = :tipo, ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :usuario ' +
      'WHERE CODIGO_ALM_ALM = :codigo';

    Eng.Progreso.EstablecerTotal(Eng.Datos.ContarOrigen('SELECT COUNT(*) FROM dbo.ocalm'));
    qSrc.Open;
    iOrden := 10;
    while not qSrc.Eof do
    begin
      Inc(Stats.Leidas);
      Eng.Progreso.Avanzar;
      iEmpresa := qSrc.FieldByName('Empresa').AsInteger;
      iAlmacen := qSrc.FieldByName('Almacen').AsInteger;
      // CODIGO_ALM_ALM: usamos la Abreviatura del legacy (MARTA, MERE,
      // LEMON, LABRADORES, TARAS, DEPOSITOS...) que es como el
      // cliente identifica sus almacenes en la operativa. Si esta
      // vacia, fallback al numero de Almacen como texto.
      sCod := UpperCase(Trim(qSrc.FieldByName('Abreviatura').AsString));
      if sCod = '' then
        sCod := IntToStr(iAlmacen);
      if Eng.Almacenes.TieneDeposito(iEmpresa) then
        EsDeposito := Eng.Almacenes.EsDeposito(iEmpresa, iAlmacen)
      else
        EsDeposito :=
          (BoolSN(qSrc.FieldByName('Deposito').AsString) = 'S') or
          NombreSugiereDeposito(qSrc);
      sTipoUso := DeducirTipoUso(qSrc, EsDeposito);

      qChk.Close;
      qChk.ParamByName('c').AsString := sCod;
      qChk.Open;
      if not qChk.IsEmpty then
      begin
        sTipoUsoExistente := Trim(
          qChk.FieldByName('TIPO_USO_ALM').AsString);
        qChk.Close;
        // Una reimportación también corrige almacenes ya creados con el
        // valor antiguo sin tilde. Si la UI eligió otro, deja un único
        // almacén de depósitos por empresa.
        if (not SameText(sTipoUsoExistente, sTipoUso)) and
           (EsDeposito or
           (Eng.Almacenes.TieneDeposito(iEmpresa) and
            SameText(sTipoUsoExistente, 'DEPOSITO')) or
           (Eng.Almacenes.TieneDeposito(iEmpresa) and
            SameText(sTipoUsoExistente, 'DEPÓSITO'))) then
        begin
          qUpd.ParamByName('tipo').AsString := sTipoUso;
          qUpd.ParamByName('usuario').AsString := Eng.Usuario;
          qUpd.ParamByName('codigo').AsString := sCod;
          qUpd.ExecSQL;
        end;
        Inc(Stats.Saltadas);
        Eng.Registro.Log('  - almacen "%s" ya existe, se omite', [sCod]);
        qSrc.Next;
        Continue;
      end;
      qChk.Close;

      sCli := Trim(qSrc.FieldByName('Cliente').AsString);
      qIns.ParamByName('CODIGO_ALM_ALM').AsString  := sCod;
      qIns.ParamByName('CODIGO_EMP_ALM').AsString  :=
        IntToStr(iEmpresa);
      // Todos los almacenes migrados arrancan activos. El campo
      // Activo del legacy usa 'A' (no 'S') y se interpretaria como
      // baja; ademas el usuario quiere editarlos en destino partiendo
      // de "habilitado".
      qIns.ParamByName('ESACTIVO_ALM').AsString    := 'S';
      qIns.ParamByName('NOMBRE_ALM_ALM').AsString  :=
        Trim(qSrc.FieldByName('Nombre').AsString);
      qIns.ParamByName('ESFISICO_ALM').AsString    := 'S';
      qIns.ParamByName('TIPO_USO_ALM').AsString    := sTipoUso;
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
          Eng.Registro.Log('  ! error insertando almacen "%s": %s',
                  [sCod, E.Message]);
          raise;
        end;
      end;
      qSrc.Next;
    end;
  finally
    qUpd.Free;
    qChk.Free;
    qIns.Free;
    qSrc.Free;
  end;
end;

initialization
  RegistrarMigracion(
    'almacenes',
    'Almacenes',
    'dbo.ocalm → fza_almacenes',
    ['empresas'],
    MigrarAlmacenes);

end.
