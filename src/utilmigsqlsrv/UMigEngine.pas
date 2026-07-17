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

  // (sDominio, iRow, iTotal). iTotal=-1 cuando aun no se sabe (al
  // arrancar la migracion); luego se actualiza con el COUNT(*).
  TMigProgressProc = reference to procedure(const sDominio: string;
                                            iRow, iTotal: Integer);

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
    FConSrv:         TUniConnection;
    FConDst:         TUniConnection;
    FOnLog:          TMigLogProc;
    FOnProgress:     TMigProgressProc;
    FUsuario:        string;
    // Config del dominio de fotos (inLibMigFotos): carpeta raiz local
    // de las fotos legacy, carpeta destino appDirFotos (ya expandida
    // por la UI, sin tokens $(...)) y tamaño del pool de hilos de
    // conversion de imagenes.
    FDirFotosOrigen: string;
    FDirFotosDestino: string;
    FHilosFotos:     Integer;
    FItems:          TObjectList<TMigItem>;
    FItemsCompartidos: Boolean;  // True si FItems no nos pertenece
    FCurrentDominio:      string;
    FCurrentTotal:        Integer;
    FCurrentRow:          Integer;
    // Flag de cancelacion atomico. Vive en el master engine; los
    // clones reenvian Cancelar/IsCancelado a su master.
    FCancelado:           Integer;
    FMaster:              TMigEngine;
    procedure DoLog(const sMensaje: string);
    procedure DoProgress;
  public
    constructor Create(ConSrv, ConDst: TUniConnection);
    // Constructor "clon" para hilos de trabajo. Reutiliza la lista de
    // items y las callbacks del motor maestro (que vive en la UI),
    // pero usa CONEXIONES propias — pensado para que cada hilo tenga
    // su pareja origen/destino. Settings (Usuario) se copian del
    // maestro en este momento.
    constructor CreateClone(ConSrv, ConDst: TUniConnection;
                            Master: TMigEngine);
    destructor  Destroy; override;

    // Cancelacion: la UI marca FCancelado en el master; los clones
    // reenvian a su master via FMaster. Los mappers chequean
    // periodicamente con IsCancelado. ResetCancel limpia el flag al
    // arrancar una nueva corrida.
    procedure Cancelar;
    procedure ResetCancel;
    function  IsCancelado: Boolean;

    procedure Registrar(const sCodigo, sNombre, sDescripcion: string;
                        Proc: TMigProc);
    function  Items: TObjectList<TMigItem>;

    procedure Ejecutar(const sCodigo: string; var Stats: TMigStats);

    // Llamadas por los mappers al arrancar para fijar el total y luego
    // por cada fila procesada para que la UI vea avanzar la barra.
    // SetTotal recibe el total real del dominio. Puede ser 0 si el
    // origen no trae filas; -1 queda reservado para total desconocido.
    procedure SetTotal(iTotal: Integer);
    procedure IncRow(iCount: Integer = 1);

    // Recalcula las estadisticas del optimizador en todas las tablas base
    // fza_* despues de una carga masiva. Devuelve el numero de tablas.
    function AnalizarTablasDestino: Integer;

    // Helper: cuenta filas que devolveria un SELECT, ejecutandolo
    // sobre la conexion origen. Usado por los mappers como
    // 'SELECT COUNT(*) FROM dbo.X' equivalente al SELECT que abren.
    function  ContarOrigen(const sSelectCount: string): Integer;

    property ConSrv:    TUniConnection   read FConSrv;
    property ConDst:    TUniConnection   read FConDst;
    property OnLog:     TMigLogProc      read FOnLog      write FOnLog;
    property OnProgress:TMigProgressProc read FOnProgress write FOnProgress;
    property Usuario:   string           read FUsuario    write FUsuario;
    property DirFotosOrigen: string      read FDirFotosOrigen
                                         write FDirFotosOrigen;
    property DirFotosDestino: string     read FDirFotosDestino
                                         write FDirFotosDestino;
    property HilosFotos: Integer         read FHilosFotos
                                         write FHilosFotos;

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

type
  // Buffer para INSERT masivo. Acumula filas en memoria y las suelta
  // contra el destino con una sola sentencia
  // "INSERT IGNORE INTO X (cols) VALUES (...), (...), ..."
  // cuando llega al tope o cuando se llama a Flush. El "IGNORE"
  // hace que las filas duplicadas no aborten el batch — clave para
  // idempotencia. Cada mapper pesado puede usar uno.
  TBulkInsert = class
  private
    FCon:      TUniConnection;
    FTabla:    string;
    FColumnas: string;       // "col1, col2, col3"
    FSufijoSQL: string;      // ON DUPLICATE KEY UPDATE opcional
    FFilas:    TStringList;  // cada entrada = "(val1, val2, val3)"
    FBatchMax: Integer;      // tamano de batch (default 1000)
    FTotalIns: Integer;
    procedure Flush;
  public
    constructor Create(Con: TUniConnection; const sTabla,
                       sColumnas: string; iBatchMax: Integer = 5000;
                       const sSufijoSQL: string = '');
    destructor  Destroy; override;

    // Anade una fila ya formateada (sin parentesis). Ej:
    //   Add(QuotedStr('foo') + ', 123, NULL');
    procedure Add(const sValores: string);

    // Suelta lo que quede pendiente. Llamar al final del bucle.
    procedure FlushPendiente;

    property TotalInsertadas: Integer read FTotalIns;
  end;

// Escapa un string para usar dentro de un literal SQL ' ... '
// segun MySQL/MariaDB.
function EscaparSQL(const s: string): string;

// Formato de literal SQL: NULL si esta vacia, 'cadena escapada' si no.
function ValorOrNull(const s: string): string;

// Formato YYYY-MM-DD HH:MM:SS para datetime.
function DateTimeASQL(const dt: TDateTime): string;

// Busca un valor en fza_atributos_valores por (ID_VA, AV). Devuelve
// ID_AV o 0 si no existe. Usado para enlazar SKUs con sus colores y
// tallas en fza_atributos_sku.
function BuscarIdAV(Eng: TMigEngine; const sIdVa, sAv: string): Integer;

// Busca un atributo basico canonico por (ID_VA_ATB, CODIGO_ATB).
// Devuelve ID_ATB o 0.
function BuscarIdATB(Eng: TMigEngine; const sIdVa,
                     sCodAtb: string): Integer;

// Convierte texto a codigo canonico mayusculas+_ (sin acentos ni
// caracteres especiales). Usado para CODIGO_ATB y para el nombre de
// la talla/color en el CODIGO_UNIDAD_SKU.
function NormalizarCodigoAtb(const s: string): string;

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

// Crea un indice en el destino si aun no existe (idempotente, via
// INFORMATION_SCHEMA.STATISTICS). Util para acelerar los UPDATE masivos
// de post-proceso y evitar bloqueos largos ("Lock wait timeout").
procedure AsegurarIndice(Eng: TMigEngine; const sTabla, sIndice,
                         sColumnas: string);

// Helpers para columnas de auditoría
procedure RellenarAuditoria(Q: TUniQuery; const sUsuario: string);

implementation

uses
  System.StrUtils, System.SyncObjs;

// =========================================================================
//  TMigEngine
// =========================================================================

constructor TMigEngine.Create(ConSrv, ConDst: TUniConnection);
begin
  inherited Create;
  FConSrv              := ConSrv;
  FConDst              := ConDst;
  FItems               := TObjectList<TMigItem>.Create(True);
  FItemsCompartidos    := False;
  FUsuario             := 'MIGRADOR';
  FHilosFotos          := 4;
end;

constructor TMigEngine.CreateClone(ConSrv, ConDst: TUniConnection;
                                    Master: TMigEngine);
begin
  inherited Create;
  FConSrv              := ConSrv;
  FConDst              := ConDst;
  // Compartimos la lista de items (registrada en el maestro). El
  // flag evita que el destructor del clon libere objetos ajenos.
  FItems               := Master.FItems;
  FItemsCompartidos    := True;
  FOnLog               := Master.FOnLog;
  FOnProgress          := Master.FOnProgress;
  FUsuario             := Master.FUsuario;
  FDirFotosOrigen      := Master.FDirFotosOrigen;
  FDirFotosDestino     := Master.FDirFotosDestino;
  FHilosFotos          := Master.FHilosFotos;
  // Apuntamos al master para que Cancelar/IsCancelado lean su
  // estado compartido.
  FMaster              := Master;
end;

procedure TMigEngine.Cancelar;
begin
  if FMaster <> nil then
    FMaster.Cancelar
  else
    TInterlocked.Exchange(FCancelado, 1);
end;

procedure TMigEngine.ResetCancel;
begin
  if FMaster <> nil then
    FMaster.ResetCancel
  else
    TInterlocked.Exchange(FCancelado, 0);
end;

function TMigEngine.IsCancelado: Boolean;
begin
  if FMaster <> nil then
    Result := FMaster.IsCancelado
  else
    Result := TInterlocked.CompareExchange(FCancelado, 0, 0) = 1;
end;

destructor TMigEngine.Destroy;
begin
  if not FItemsCompartidos then
    FItems.Free;
  inherited;
end;

procedure TMigEngine.DoLog(const sMensaje: string);
begin
  if Assigned(FOnLog) then
    FOnLog(sMensaje);
end;

procedure TMigEngine.DoProgress;
begin
  if Assigned(FOnProgress) then
    FOnProgress(FCurrentDominio, FCurrentRow, FCurrentTotal);
end;

procedure TMigEngine.SetTotal(iTotal: Integer);
begin
  FCurrentTotal := iTotal;
  FCurrentRow   := 0;
  DoProgress;
end;

procedure TMigEngine.IncRow(iCount: Integer = 1);
begin
  Inc(FCurrentRow, iCount);
  // Reportamos cada 2000 filas o en la ultima. Con dominios de 1,3M+
  // filas (SKUs, movimientos) reportar cada 200 son miles de callbacks
  // marshalleados a UI por segundo que atascan el interfaz; 2000 deja
  // la barra viva sin machacar el hilo de UI.
  if (FCurrentRow mod 2000 = 0)
  or ((FCurrentTotal > 0) and (FCurrentRow >= FCurrentTotal)) then
    DoProgress;
end;

function TMigEngine.AnalizarTablasDestino: Integer;
var
  i: Integer;
  oAnalisis: TUniQuery;
  oTablas: TUniQuery;
  sTabla: string;
  slTablas: TStringList;
begin
  Result := 0;
  slTablas := TStringList.Create;
  oTablas := TUniQuery.Create(nil);
  oAnalisis := TUniQuery.Create(nil);
  try
    oTablas.Connection := FConDst;
    oTablas.SQL.Text :=
      'SELECT TABLE_NAME' +
      '  FROM INFORMATION_SCHEMA.TABLES' +
      ' WHERE TABLE_SCHEMA = DATABASE()' +
      '   AND TABLE_TYPE = ''BASE TABLE''' +
      '   AND LEFT(TABLE_NAME, 4) = ''fza_''' +
      ' ORDER BY TABLE_NAME';
    oTablas.Open;
    while not oTablas.Eof do
    begin
      slTablas.Add(oTablas.FieldByName('TABLE_NAME').AsString);
      oTablas.Next;
    end;
    oTablas.Close;
    oAnalisis.Connection := FConDst;
    for i := 0 to slTablas.Count - 1 do
    begin
      sTabla := StringReplace(slTablas[i], '`', '``', [rfReplaceAll]);
      oAnalisis.SQL.Text := Format('ANALYZE TABLE `%s`', [sTabla]);
      oAnalisis.Open;
      oAnalisis.Close;
      Inc(Result);
    end;
  finally
    FreeAndNil(oAnalisis);
    FreeAndNil(oTablas);
    FreeAndNil(slTablas);
  end;
end;

function TMigEngine.ContarOrigen(const sSelectCount: string): Integer;
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := FConSrv;
    q.SQL.Text   := sSelectCount;
    q.Open;
    if q.IsEmpty then
      Result := 0
    else
      Result := q.Fields[0].AsInteger;
  finally
    q.Free;
  end;
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
      FCurrentDominio := oItem.Nombre;
      FCurrentTotal   := -1;
      FCurrentRow     := 0;
      DoProgress;  // notifica a la UI "arranca dominio X"
      Log('--- %s ---', [oItem.Nombre]);
      FConDst.StartTransaction;
      try
        oItem.Proc(Self, Stats);
        // Empujar la barra al 100% al terminar OK. Algunos mappers cuentan
        // (COUNT) mas filas de las que su SELECT real devuelve (p.ej. un JOIN
        // que descarta filas huerfanas), y sin esto FCurrentRow nunca alcanza
        // FCurrentTotal: la barra se queda < 100% y el dominio parece colgado
        // aunque haya terminado bien.
        if not IsCancelado then
        begin
          if FCurrentTotal > 0 then
            FCurrentRow := FCurrentTotal
          else
          begin
            FCurrentTotal := 0;
            FCurrentRow := 0;
          end;
          DoProgress;
        end;
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

// =========================================================================
//  TBulkInsert + helpers SQL
// =========================================================================

function EscaparSQL(const s: string): string;
var i: Integer;
begin
  Result := '';
  for i := 1 to Length(s) do
    case s[i] of
      '''': Result := Result + '''''';
      '\':  Result := Result + '\\';
      #0:   Result := Result + '\0';
      #10:  Result := Result + '\n';
      #13:  Result := Result + '\r';
      #26:  Result := Result + '\Z';
    else
      Result := Result + s[i];
    end;
end;

function ValorOrNull(const s: string): string;
begin
  if s = '' then
    Result := 'NULL'
  else
    Result := '''' + EscaparSQL(s) + '''';
end;

function DateTimeASQL(const dt: TDateTime): string;
begin
  Result := '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', dt) + '''';
end;

constructor TBulkInsert.Create(Con: TUniConnection; const sTabla,
                                sColumnas: string; iBatchMax: Integer;
                                const sSufijoSQL: string);
begin
  inherited Create;
  FCon      := Con;
  FTabla    := sTabla;
  FColumnas := sColumnas;
  FSufijoSQL := Trim(sSufijoSQL);
  FFilas    := TStringList.Create;
  if iBatchMax <= 0 then iBatchMax := 5000;
  FBatchMax := iBatchMax;
  FTotalIns := 0;
end;

destructor TBulkInsert.Destroy;
begin
  // Si quedan filas pendientes, se vuelcan en el destructor para no
  // perderlas. Si falla aqui no relanzamos — el destructor debe ser
  // tolerante.
  try
    if FFilas.Count > 0 then Flush;
  except
    // ignoramos
  end;
  FFilas.Free;
  inherited;
end;

procedure TBulkInsert.Add(const sValores: string);
begin
  FFilas.Add('(' + sValores + ')');
  if FFilas.Count >= FBatchMax then
    Flush;
end;

procedure TBulkInsert.FlushPendiente;
begin
  if FFilas.Count > 0 then Flush;
end;

procedure TBulkInsert.Flush;
var
  sSql:  string;
  i:     Integer;
  sb:    TStringBuilder;
  iFils: Integer;
begin
  if FFilas.Count = 0 then Exit;
  // Construimos la sentencia con TStringBuilder para no penalizar
  // con concatenaciones de string en cada iteracion (batches de
  // 1000 filas pueden ser miles de chars).
  sb := TStringBuilder.Create(64 * FFilas.Count);
  try
    if FSufijoSQL = '' then
      sb.Append('INSERT IGNORE INTO `')
    else
      sb.Append('INSERT INTO `');
    sb.Append(FTabla);
    sb.Append('` (');
    sb.Append(FColumnas);
    sb.Append(') VALUES ');
    for i := 0 to FFilas.Count - 1 do
    begin
      if i > 0 then sb.Append(', ');
      sb.Append(FFilas[i]);
    end;
    if FSufijoSQL <> '' then
    begin
      sb.Append(' ');
      sb.Append(FSufijoSQL);
    end;
    sSql := sb.ToString;
  finally
    sb.Free;
  end;
  iFils := FFilas.Count;
  FFilas.Clear;
  FCon.ExecSQL(sSql);
  // RowsAffected con INSERT IGNORE puede ser menor que iFils si hay
  // duplicados; nos quedamos con el total enviado para reporting.
  Inc(FTotalIns, iFils);
end;

// =========================================================================
//  Lookups
// =========================================================================

function BuscarIdAV(Eng: TMigEngine; const sIdVa, sAv: string): Integer;
var qLook: TUniQuery;
begin
  qLook := TUniQuery.Create(nil);
  try
    qLook.Connection := Eng.ConDst;
    qLook.SQL.Text   :=
      // ORDER BY ID_AV: con valores duplicados (mismo ID_VA+AV, p.ej. tallas
      // del lote "limpio" y del "deducido") elige SIEMPRE el MIN(ID_AV) como
      // canonico, para que todos los paths (conjunto y tag de SKU) coincidan.
      'SELECT ID_AV FROM fza_atributos_valores ' +
      'WHERE ID_VA_AV = :v AND AV = :av ' +
      'ORDER BY ID_AV LIMIT 1';
    qLook.ParamByName('v').AsString  := sIdVa;
    qLook.ParamByName('av').AsString := sAv;
    qLook.Open;
    if qLook.IsEmpty then
      Result := 0
    else
      Result := qLook.FieldByName('ID_AV').AsInteger;
  finally
    qLook.Free;
  end;
end;

function BuscarIdATB(Eng: TMigEngine; const sIdVa,
                     sCodAtb: string): Integer;
var qLook: TUniQuery;
begin
  qLook := TUniQuery.Create(nil);
  try
    qLook.Connection := Eng.ConDst;
    qLook.SQL.Text   :=
      'SELECT ID_ATB FROM fza_atributos_basicos ' +
      'WHERE ID_VA_ATB = :v AND CODIGO_ATB = :c LIMIT 1';
    qLook.ParamByName('v').AsString := sIdVa;
    qLook.ParamByName('c').AsString := sCodAtb;
    qLook.Open;
    if qLook.IsEmpty then
      Result := 0
    else
      Result := qLook.FieldByName('ID_ATB').AsInteger;
  finally
    qLook.Free;
  end;
end;

function NormalizarCodigoAtb(const s: string): string;
var i: Integer; c: Char;
begin
  Result := '';
  for i := 1 to Length(s) do
  begin
    c := s[i];
    case c of
      'A'..'Z', '0'..'9', '_': Result := Result + c;
      'a'..'z':                Result := Result + UpCase(c);
      ' ', '-', '/', '.':      Result := Result + '_';
    end;
  end;
  if Result = '' then Result := 'X';
end;

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

procedure AsegurarIndice(Eng: TMigEngine; const sTabla, sIndice,
                         sColumnas: string);
var q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := Eng.ConDst;
    q.SQL.Text :=
      'SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      '  AND TABLE_NAME = :t AND INDEX_NAME = :i';
    q.ParamByName('t').AsString := sTabla;
    q.ParamByName('i').AsString := sIndice;
    q.Open;
    if q.Fields[0].AsInteger = 0 then
    begin
      q.Close;
      // DDL en MySQL hace commit implicito; el llamante debe invocarlo
      // FUERA de una transaccion en curso (en autocommit).
      Eng.ConDst.ExecSQL(Format('ALTER TABLE `%s` ADD INDEX `%s` (%s)',
        [sTabla, sIndice, sColumnas]));
      Eng.Log(Format('  indice %s creado en %s.', [sIndice, sTabla]));
    end;
  finally
    q.Free;
  end;
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
