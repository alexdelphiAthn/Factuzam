{******************************************************************************}
{                                                                              }
{  Módulo:       UMigEngine                                                    }
{    Tipo:       Lógica sin formulario                                         }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Motor de migración SQL Server → MariaDB. Cada dominio (clientes,          }
{    artículos, etc.) registra aquí su procedimiento y el motor se encarga     }
{    de orquestar la ejecución, el log y el reporting de progreso.             }
{                                                                              }
{    Convenciones:                                                             }
{      - Una migración = un TMigProc que recibe el motor y devuelve cuántas    }
{        filas leyó / insertó / falló.                                         }
{      - El motor escribe en MariaDB siempre en una transacción por dominio.   }
{        Si revienta una fila se hace rollback completo.                       }
{      - Las cuatro columnas de auditoría (INSTANTE_ALTA/MODIF, USUARIO_*)     }
{        las rellena el motor con NOW() + el usuario configurado, jamás los   }
{        mappers, para mantener uniformidad.                                   }
{******************************************************************************}
unit UMigEngine;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, Uni;

type
  TMigLogProc = reference to procedure(const sMensaje: string);

  TMigStats = record
    Leidas:     Integer;
    Insertadas: Integer;
    Saltadas:   Integer;
    Errores:    Integer;
  end;

  TMigEngine = class;

  TMigProc = reference to procedure(Eng: TMigEngine; var Stats: TMigStats);

  TMigItem = class
  public
    Codigo:      string;  // identificador interno
    Nombre:      string;  // visible en UI
    Descripcion: string;
    Proc:        TMigProc;
  end;

  TMigEngine = class
  private
    FConSrv:    TUniConnection;
    FConDst:    TUniConnection;
    FOnLog:     TMigLogProc;
    FUsuario:   string;
    FItems:     TObjectList<TMigItem>;
    procedure DoLog(const sMensaje: string);
  public
    constructor Create(ConSrv, ConDst: TUniConnection);
    destructor  Destroy; override;

    procedure Registrar(const sCodigo, sNombre, sDescripcion: string;
                        Proc: TMigProc);
    function  Items: TObjectList<TMigItem>;

    procedure Ejecutar(const sCodigo: string; var Stats: TMigStats);

    property ConSrv:  TUniConnection read FConSrv;
    property ConDst:  TUniConnection read FConDst;
    property OnLog:   TMigLogProc    read FOnLog    write FOnLog;
    property Usuario: string         read FUsuario  write FUsuario;

    procedure Log(const sMensaje: string); overload;
    procedure Log(const sFormato: string;
                  const aArgs: array of const); overload;

    // Helpers de log "rico": prefijo "  - SALTO" / "  ! ERROR" y formato
    // consistente. sCodigo identifica el registro (PK), sMotivo
    // resume el por que, sDescOrigen / sDescDestino aportan contexto
    // para distinguir si lo que se conserva en destino es lo que se
    // quería conservar o no.
    procedure LogSalto(const sDominio, sCodigo, sMotivo: string;
                       const sDescOrigen: string = '';
                       const sDescDestino: string = '');
    procedure LogError(const sDominio, sCodigo, sError: string;
                       const sDescOrigen: string = '';
                       const sPista: string = '');
  end;

// Helpers compartidos por todos los mappers --------------------------------

// Devuelve la cadena en mayúsculas y sin espacios laterales, o cadena vacía.
function NormalizarCodigo(const s: string): string;

// Convierte 'S' / 'N' del origen a booleano destino. Si el origen es null o
// vacío, devuelve sFalse ('N' por defecto).
function BoolSN(const sValor: string; const sTrue: string = 'S';
                const sFalse: string = 'N'): string;

// Crea un TUniQuery preparado contra el origen y lo devuelve. Quien llame
// es responsable de liberarlo.
function NuevoQOrigen(Eng: TMigEngine; const sSQL: string): TUniQuery;

// Ejecuta un INSERT contra destino. Lanza si falla.
procedure EjecutarSQL(Eng: TMigEngine; const sSQL: string);

// Helpers para columnas de auditoría
procedure RellenarAuditoria(Q: TUniQuery; const sUsuario: string);

implementation

uses
  System.StrUtils;

// =========================================================================
//  TMigEngine
// =========================================================================

constructor TMigEngine.Create(ConSrv, ConDst: TUniConnection);
begin
  inherited Create;
  FConSrv  := ConSrv;
  FConDst  := ConDst;
  FItems   := TObjectList<TMigItem>.Create(True);
  FUsuario := 'MIGRADOR';
end;

destructor TMigEngine.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TMigEngine.DoLog(const sMensaje: string);
begin
  if Assigned(FOnLog) then
    FOnLog(sMensaje);
end;

procedure TMigEngine.Log(const sMensaje: string);
begin
  DoLog(sMensaje);
end;

procedure TMigEngine.Log(const sFormato: string;
                         const aArgs: array of const);
begin
  DoLog(Format(sFormato, aArgs));
end;

procedure TMigEngine.LogSalto(const sDominio, sCodigo, sMotivo: string;
                              const sDescOrigen: string = '';
                              const sDescDestino: string = '');
var s: string;
begin
  s := Format('  - SALTO %s "%s": %s', [sDominio, sCodigo, sMotivo]);
  if sDescOrigen <> '' then
    s := s + Format(' | ORIGEN="%s"', [sDescOrigen]);
  if sDescDestino <> '' then
    s := s + Format(' | DESTINO="%s"', [sDescDestino]);
  DoLog(s);
end;

procedure TMigEngine.LogError(const sDominio, sCodigo, sError: string;
                              const sDescOrigen: string = '';
                              const sPista: string = '');
var s: string;
begin
  s := Format('  ! ERROR %s "%s": %s', [sDominio, sCodigo, sError]);
  if sDescOrigen <> '' then
    s := s + Format(' | ORIGEN="%s"', [sDescOrigen]);
  if sPista <> '' then
    s := s + Format(' | PISTA: %s', [sPista]);
  DoLog(s);
end;

procedure TMigEngine.Registrar(const sCodigo, sNombre, sDescripcion: string;
                               Proc: TMigProc);
var
  oItem: TMigItem;
begin
  oItem             := TMigItem.Create;
  oItem.Codigo      := sCodigo;
  oItem.Nombre      := sNombre;
  oItem.Descripcion := sDescripcion;
  oItem.Proc        := Proc;
  FItems.Add(oItem);
end;

function TMigEngine.Items: TObjectList<TMigItem>;
begin
  Result := FItems;
end;

procedure TMigEngine.Ejecutar(const sCodigo: string; var Stats: TMigStats);
var
  i: Integer;
  oItem: TMigItem;
begin
  Stats := Default(TMigStats);
  for i := 0 to FItems.Count - 1 do
  begin
    if SameText(FItems[i].Codigo, sCodigo) then
    begin
      oItem := FItems[i];
      Log('--- %s ---', [oItem.Nombre]);
      FConDst.StartTransaction;
      try
        oItem.Proc(Self, Stats);
        FConDst.Commit;
        Log('%s: %d leidas, %d insertadas, %d saltadas, %d errores.',
            [oItem.Nombre, Stats.Leidas, Stats.Insertadas,
             Stats.Saltadas, Stats.Errores]);
      except
        on E: Exception do
        begin
          FConDst.Rollback;
          Log('ERROR en %s: %s', [oItem.Nombre, E.Message]);
          raise;
        end;
      end;
      Exit;
    end;
  end;
  raise Exception.CreateFmt('No existe migración registrada con código "%s"',
                            [sCodigo]);
end;

// =========================================================================
//  Helpers
// =========================================================================

function NormalizarCodigo(const s: string): string;
begin
  Result := UpperCase(Trim(s));
end;

function BoolSN(const sValor: string;
                const sTrue: string = 'S';
                const sFalse: string = 'N'): string;
var
  s: string;
begin
  s := UpperCase(Trim(sValor));
  if (s = 'S') or (s = '1') or (s = 'Y') or (s = 'T') then
    Result := sTrue
  else
    Result := sFalse;
end;

function NuevoQOrigen(Eng: TMigEngine; const sSQL: string): TUniQuery;
begin
  Result            := TUniQuery.Create(nil);
  Result.Connection := Eng.ConSrv;
  Result.SQL.Text   := sSQL;
end;

procedure EjecutarSQL(Eng: TMigEngine; const sSQL: string);
begin
  Eng.ConDst.ExecSQL(sSQL);
end;

procedure RellenarAuditoria(Q: TUniQuery; const sUsuario: string);
begin
  if Q.FindParam('USUARIO_ALTA')  <> nil then
    Q.ParamByName('USUARIO_ALTA').AsString  := sUsuario;
  if Q.FindParam('USUARIO_MODIF') <> nil then
    Q.ParamByName('USUARIO_MODIF').AsString := sUsuario;
  if Q.FindParam('INSTANTE_ALTA') <> nil then
    Q.ParamByName('INSTANTE_ALTA').AsDateTime  := Now;
  if Q.FindParam('INSTANTE_MODIF') <> nil then
    Q.ParamByName('INSTANTE_MODIF').AsDateTime := Now;
end;

end.
