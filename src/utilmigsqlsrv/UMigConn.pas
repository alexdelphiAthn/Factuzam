{******************************************************************************}
{                                                                              }
{  Módulo:       UMigConn                                                      }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Conexiones del programa de migración SQL Server → MariaDB.                }
{    Mantiene dos TUniConnection: una contra SQL Server (origen, lectura)      }
{    y otra contra MariaDB/MySQL (destino, escritura).                         }
{                                                                              }
{    No persiste credenciales: los parámetros (host, puerto, base, usuario,    }
{    clave) los rellena el formulario antes de conectar. Solo aquí vive la     }
{    configuración de pooling y opciones de UniDAC.                            }
{******************************************************************************}
unit UMigConn;

interface

uses
  Winapi.ActiveX,
  System.SysUtils, System.Classes,
  Data.DB,
  Uni, UniScript, UniProvider, MySQLUniProvider, SQLServerUniProvider, DBAccess;

type
  TdmMig = class(TDataModule)
    conSrv:        TUniConnection;
    conDst:        TUniConnection;
    prvSqlServer:  TSQLServerUniProvider;
    prvMySQL:      TMySQLUniProvider;
  private
    // Pone el origen (SQL Server) en READ UNCOMMITTED tras conectar, para
    // que la migracion (solo lectura) no se bloquee por escrituras de otra
    // sesion (el ERP legacy en marcha). Equivale a WITH (NOLOCK) global.
    procedure SrvAfterConnect(Sender: TObject);
  public
    procedure ConfigurarOrigen(const sHost, sPort, sBase, sUser,
                               sPwd: string; bWindowsAuth: Boolean = False);
    procedure ConfigurarDestino(const sHost, sPort, sBase, sUser,
                                sPwd: string);
    procedure ProbarOrigen;
    procedure ProbarDestino;

    // Crea una BBDD vacia en el servidor destino con charset utf8mb4 y
    // collation utf8mb4_spanish_ci. Idempotente: si ya existe no hace
    // nada. Tras la llamada, conDst queda configurado con sNombre como
    // Database (pero cerrado).
    procedure CrearBBDDDestino(const sNombre: string);

    // Carga el contenido completo de un .sql (esquema + datos seed) en
    // la BBDD destino actualmente configurada. Usa TUniScript para
    // soportar multiples sentencias separadas por ;.
    procedure CargarEsquemaDestino(const sRutaFichero: string);

    // Borra del destino los datos demo del seed factuzam_original.sql
    // de TODAS las tablas con datos en el dump (44 con audit + 6 sin
    // audit). NO toca tablas de sistema (paises, ivas*, winforms,
    // usuarios*, metadatos, config_campos, tipos_documentos,
    // contadores, valores_defecto, generadorprocesos, informes_guias,
    // ivas_zonas, variaciones_atributos).
    //
    // Filtro de usuario "demo" para las tablas con audit:
    //   USUARIO_ALTA IN ('DEMO', 'Administrador', 'Sistema', 'SISTEMA',
    //                    'Admin', 'ADMIN', 'SCRIPT_DEMO', 'SCRIPT_FIX',
    //                    'FIX_SKU_STOCK', 'MIGRACION').
    // Para las 6 tablas sin audit (stockactual, vinculos, etc.) se
    // hace DELETE FROM completo, son derivadas o hijo de tablas demo.
    //
    // Devuelve cuantas filas borro en total.
    function LimpiarDatosDemoDestino: Integer;

    // Borra del destino TODO lo que haya creado una corrida previa
    // del migrador, identificado por USUARIO_ALTA = sUsuario (por
    // defecto 'MIGRADOR'). Procesa las tablas en orden inverso de
    // dependencias (hijos primero) para evitar dejar huerfanos.
    // Devuelve cuantas filas borro en total. Permite re-ejecutar la
    // migracion desde cero sin restos.
    function ResetearMigracionAnterior(const sUsuario: string): Integer;

    // Borra COMPLETAMENTE la BBDD destino con DROP DATABASE. El
    // siguiente paso logico es volver a crearla con
    // CrearBBDDDestino y cargar el esqueleto. Pensado para empezar
    // de cero. Llamada destructiva — la UI debe pedir confirmacion
    // doble antes de invocar.
    procedure BorrarBBDDDestino(const sNombre: string);

    // Crea TUniConnection nuevas con los mismos parametros que
    // conSrv/conDst. Pensado para uso desde hilos de trabajo: cada
    // hilo necesita su propia conexion porque UniDAC no soporta uso
    // concurrente. El llamante es duenio del objeto y debe liberarlo.
    function ClonarConexionOrigen:  TUniConnection;
    function ClonarConexionDestino: TUniConnection;
  end;

var
  dmMig: TdmMig;

implementation

{$R *.dfm}

// Lectura sucia en TODO el origen: ningun SELECT/COUNT se queda bloqueado
// esperando a un lock de escritura de otra sesion. Se asigna como
// AfterConnect tanto en conSrv como en los clones de los workers.
procedure TdmMig.SrvAfterConnect(Sender: TObject);
begin
  try
    (Sender as TUniConnection).ExecSQL(
      'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED');
  except
    // Si el provider no lo soporta, seguimos con el nivel por defecto.
  end;
end;

procedure TdmMig.ConfigurarOrigen(const sHost, sPort, sBase, sUser,
                                  sPwd: string;
                                  bWindowsAuth: Boolean = False);
begin
  // COM/OLE DB del provider SQL Server: el hilo principal necesita COM
  // inicializado antes de abrir la conexion (si no: "CoInitialize has not
  // been called"). Los workers hacen su propio CoInitializeEx.
  CoInitialize(nil);
  conSrv.Close;
  conSrv.ProviderName := 'SQL Server';
  conSrv.Server       := sHost;
  if sPort <> '' then
    conSrv.Port := StrToIntDef(sPort, 1433)
  else
    conSrv.Port := 1433;
  conSrv.Database    := sBase;
  conSrv.LoginPrompt := False;
  coInitialize(nil);
  conSrv.AfterConnect := SrvAfterConnect;  // READ UNCOMMITTED al conectar
  // Provider: dejamos el default de UniDAC (en general escoge OLE DB
  // nativo si esta el cliente de SQL Server instalado, o protocolo TDS
  // interno si no). Si tu version de UniDAC necesita uno concreto se
  // puede fijar via SpecificOptions['Provider'] (ej 'MSOLEDBSQL',
  // 'SNAC11', 'OLEDB', 'Direct'...).
  if bWindowsAuth then
  begin
    // Autenticación Windows (Integrated Security): el proceso que
    // ejecuta el migrator se identifica ante SQL Server con sus
    // credenciales del SO. No se rellenan Username/Password.
    conSrv.SpecificOptions.Values['Authentication'] := 'auWindows';
    conSrv.Username := '';
    conSrv.Password := '';
  end
  else
  begin
    conSrv.SpecificOptions.Values['Authentication'] := 'auServer';
    conSrv.Username := sUser;
    conSrv.Password := sPwd;
  end;
end;

procedure TdmMig.ConfigurarDestino(const sHost, sPort, sBase, sUser,
                                   sPwd: string);
begin
  conDst.Close;
  conDst.ProviderName := 'MySQL';
  conDst.Server       := sHost;
  if sPort <> '' then
    conDst.Port := StrToIntDef(sPort, 3306)
  else
    conDst.Port := 3306;
  conDst.Database    := sBase;
  conDst.Username    := sUser;
  conDst.Password    := sPwd;
  conDst.LoginPrompt := False;
  conDst.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
end;

procedure TdmMig.ProbarOrigen;
begin
  conSrv.Open;
  // ping mínimo
  conSrv.ExecSQL('SELECT 1');
end;

procedure TdmMig.ProbarDestino;
begin
  conDst.Open;
  conDst.ExecSQL('SELECT 1');
end;

// =========================================================================
//  Crear BBDD destino vacia
// =========================================================================

procedure TdmMig.CrearBBDDDestino(const sNombre: string);
var
  i: Integer;
  c: Char;
  sDbAnterior: string;
begin
  // Validamos el nombre. Solo a-z, A-Z, 0-9, _ — sin backticks, sin
  // espacios, sin acentos. Asi prevenimos inyeccion via identificador.
  if (sNombre = '') or (Length(sNombre) > 64) then
    raise Exception.Create('Nombre de BBDD invalido (vacio o > 64 chars).');
  for i := 1 to Length(sNombre) do
  begin
    c := sNombre[i];
    if not ((c in ['a'..'z']) or (c in ['A'..'Z'])
         or (c in ['0'..'9']) or (c = '_')) then
      raise Exception.CreateFmt(
        'Nombre de BBDD invalido (caracter "%s"). ' +
        'Solo a-z, A-Z, 0-9 y _.', [c]);
  end;

  sDbAnterior := conDst.Database;
  conDst.Close;
  try
    // Conectamos a la BBDD de sistema "mysql" que siempre existe; con
    // ese contexto podemos ejecutar CREATE DATABASE.
    conDst.Database := 'mysql';
    conDst.Open;
    try
      conDst.ExecSQL(Format(
        'CREATE DATABASE IF NOT EXISTS `%s` ' +
        'CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci',
        [sNombre]));
    finally
      conDst.Close;
    end;
  finally
    // Dejamos la conexion apuntando a la nueva BBDD para que el resto
    // del programa (probar, cargar esquema, ejecutar migraciones)
    // trabaje contra ella sin pasos extra.
    conDst.Database := sNombre;
  end;
end;

// =========================================================================
//  Cargar un .sql en el destino
// =========================================================================

procedure TdmMig.CargarEsquemaDestino(const sRutaFichero: string);
var
  oScript: TUniScript;
begin
  if not FileExists(sRutaFichero) then
    raise Exception.CreateFmt('No se encuentra el fichero "%s".',
                              [sRutaFichero]);
  if not conDst.Connected then
    conDst.Open;
  oScript := TUniScript.Create(nil);
  try
    oScript.Connection := conDst;
    oScript.SQL.LoadFromFile(sRutaFichero);
    oScript.Execute;
  finally
    oScript.Free;
  end;
end;

function TdmMig.ClonarConexionOrigen: TUniConnection;
var sAuth: string;
begin
  Result := TUniConnection.Create(nil);
  Result.ProviderName := conSrv.ProviderName;
  Result.Server       := conSrv.Server;
  Result.Port         := conSrv.Port;
  Result.Database     := conSrv.Database;
  Result.Username     := conSrv.Username;
  Result.Password     := conSrv.Password;
  Result.LoginPrompt  := False;
  Result.AfterConnect := SrvAfterConnect;  // READ UNCOMMITTED tambien aqui
  // Preservar el modo de autenticacion (Windows / SQL).
  sAuth := conSrv.SpecificOptions.Values['Authentication'];
  if sAuth <> '' then
    Result.SpecificOptions.Values['Authentication'] := sAuth;
end;

function TdmMig.ClonarConexionDestino: TUniConnection;
begin
  Result := TUniConnection.Create(nil);
  Result.ProviderName := conDst.ProviderName;
  Result.Server       := conDst.Server;
  Result.Port         := conDst.Port;
  Result.Database     := conDst.Database;
  Result.Username     := conDst.Username;
  Result.Password     := conDst.Password;
  Result.LoginPrompt  := False;
  Result.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
end;

procedure TdmMig.BorrarBBDDDestino(const sNombre: string);
var
  i: Integer;
  c: Char;
begin
  // Mismo validador que CrearBBDDDestino — protege contra inyeccion
  // de identificador.
  if (sNombre = '') or (Length(sNombre) > 64) then
    raise Exception.Create('Nombre de BBDD invalido (vacio o > 64).');
  for i := 1 to Length(sNombre) do
  begin
    c := sNombre[i];
    if not ((c in ['a'..'z']) or (c in ['A'..'Z'])
         or (c in ['0'..'9']) or (c = '_')) then
      raise Exception.CreateFmt(
        'Nombre de BBDD invalido (caracter "%s").', [c]);
  end;

  conDst.Close;
  try
    conDst.Database := 'mysql';  // BBDD de sistema, siempre existe
    conDst.Open;
    try
      conDst.ExecSQL(Format('DROP DATABASE IF EXISTS `%s`', [sNombre]));
    finally
      conDst.Close;
    end;
  finally
    // Dejamos el nombre original por si el usuario quiere
    // recrearla a continuacion (no debe quedarse con 'mysql').
    conDst.Database := sNombre;
  end;
end;

function TdmMig.ResetearMigracionAnterior(
                                  const sUsuario: string): Integer;
const
  // Orden INVERSO de dependencias (hijos primero, padres despues)
  // para que los DELETE no dejen huerfanos en otras tablas.
  aTablas: array[0..24] of string = (
    'fza_inventarios_lineas',
    'fza_inventarios',
    'fza_codigos_barras',
    'fza_articulos_tarifas',
    'fza_atributos_sku',
    'fza_articulos_skus',
    'fza_articulos_atributos_basicos',
    'fza_articulos_conjuntos_asign',
    'fza_articulos_propiedades',
    'fza_articulos_proveedores',
    'fza_propiedades_valores',
    'fza_propiedades',
    'fza_atributos_conjuntos_det',
    'fza_atributos_conjuntos',
    'fza_articulos',
    'fza_articulos_familias',
    'fza_atributos_basicos',
    'fza_atributos_valores',
    'fza_clientes',
    'fza_proveedores',
    'fza_almacenes',
    'fza_empresas',
    'fza_formas_pago',
    'fza_ivas',
    'fza_ivas_grupos'
  );
var
  i, iSub: Integer;
  qDel:    TUniQuery;
  sUser:   string;
begin
  sUser := Trim(sUsuario);
  if sUser = '' then sUser := 'MIGRADOR';
  if not conDst.Connected then conDst.Open;
  Result := 0;
  qDel := TUniQuery.Create(nil);
  try
    qDel.Connection := conDst;
    for i := Low(aTablas) to High(aTablas) do
    begin
      qDel.SQL.Text := Format(
        'DELETE FROM `%s` WHERE USUARIO_ALTA = :u', [aTablas[i]]);
      qDel.ParamByName('u').AsString := sUser;
      qDel.ExecSQL;
      iSub := qDel.RowsAffected;
      if iSub > 0 then
        Inc(Result, iSub);
    end;
  finally
    qDel.Free;
  end;
end;

function TdmMig.LimpiarDatosDemoDestino: Integer;
const
  // Lista completa de usuarios "demo" detectados en
  // factuzam_original.sql. Filtra solo lo creado por el seed; respeta
  // datos migrados (USUARIO_ALTA = 'MIGRADOR' u otro custom).
  cWhereDemo =
    ' WHERE USUARIO_ALTA IN ( ' +
    '  ''DEMO'', ''Administrador'', ''Sistema'', ''SISTEMA'', ' +
    '  ''Admin'', ''ADMIN'', ''SCRIPT_DEMO'', ''SCRIPT_FIX'', ' +
    '  ''FIX_SKU_STOCK'', ''MIGRACION'' ' +
    ')';

  // Tablas con USUARIO_ALTA: DELETE por filtro de usuario demo.
  // Orden hijos -> padres para minimizar problemas de FK (aunque
  // el esquema usa FKs LOGICAS, no fisicas).
  aConAudit: array[0..43] of string = (
    // Cadena de articulos (hijos primero)
    'fza_codigos_barras',
    'fza_atributos_sku',
    'fza_articulos_atributos_basicos',
    'fza_articulos_conjuntos_asign',
    'fza_articulos_propiedades',
    'fza_articulos_proveedores',
    'fza_articulos_skus_costes',
    'fza_articulos_skus',
    'fza_articulos_tarifas',
    'fza_articulos_fotos',
    'fza_articulos',
    'fza_articulos_familias',
    // Catalogos atributos y propiedades
    'fza_atributos_conjuntos_det',
    'fza_atributos_conjuntos',
    'fza_atributos_valores',
    'fza_atributos_basicos',
    'fza_propiedades_valores',
    'fza_propiedades',
    'fza_variaciones',
    // Documentos comerciales (lineas antes que cabecera)
    'fza_facturas_pagos',
    'fza_facturas_lineas',
    'fza_facturas',
    'fza_albaranes_lineas',
    'fza_albaranes',
    'fza_pedidos_lineas',
    'fza_pedidos',
    'fza_compras_sesiones',
    // Caja
    'fza_caja_pagos',
    'fza_caja_vales',
    'fza_caja_operaciones',
    'fza_caja_formas_pago',
    // Stock / inventario / movimientos
    'fza_movimientos_almacen',
    'fza_inventarios_lineas',
    'fza_inventarios',
    // Resto
    'fza_recibos',
    'fza_depositos_cliente',
    'fza_empresas_series',
    'fza_empresas_retenciones',
    'fza_almacenes',
    'fza_clientes',
    'fza_proveedores',
    'fza_formas_pago',
    'fza_tarifas',
    'fza_empresas'
  );

  // Tablas sin USUARIO_ALTA: DELETE FROM completo. Son derivadas o
  // hijo unicamente de tablas demo (al borrar el padre quedan
  // huerfanas, asi que vaciarlas es lo correcto).
  aSinAudit: array[0..5] of string = (
    'fza_articulos_stockactual',
    'fza_articulos_vinculos',
    'fza_almacenes_cajas',
    'fza_compras_sesiones_celdas',
    'fza_compras_sesiones_lineas',
    'fza_familias_atributos'
  );
var
  i, iSub: Integer;
  qDel:    TUniQuery;
begin
  if not conDst.Connected then conDst.Open;
  Result := 0;
  qDel := TUniQuery.Create(nil);
  try
    qDel.Connection := conDst;
    // Desactivar checks FK temporalmente. Aunque el esquema no usa
    // FKs fisicas, MariaDB es estricto con ciertos hooks/triggers.
    qDel.SQL.Text := 'SET FOREIGN_KEY_CHECKS = 0';
    qDel.ExecSQL;
    try
      for i := Low(aConAudit) to High(aConAudit) do
      begin
        qDel.SQL.Text := Format('DELETE FROM `%s`%s',
          [aConAudit[i], cWhereDemo]);
        qDel.ExecSQL;
        iSub := qDel.RowsAffected;
        if iSub > 0 then Inc(Result, iSub);
      end;
      for i := Low(aSinAudit) to High(aSinAudit) do
      begin
        qDel.SQL.Text := Format('DELETE FROM `%s`', [aSinAudit[i]]);
        qDel.ExecSQL;
        iSub := qDel.RowsAffected;
        if iSub > 0 then Inc(Result, iSub);
      end;
    finally
      qDel.SQL.Text := 'SET FOREIGN_KEY_CHECKS = 1';
      qDel.ExecSQL;
    end;
  finally
    qDel.Free;
  end;
end;

end.
