{******************************************************************************}
{                                                                              }
{  Módulo:       UMigrator                                                     }
{    Tipo:       Formulario VCL                                                }
{ Versión:       1.0.0                                                         }
{                                                                              }
{  Descripción:                                                                }
{    Formulario principal del Factuzam Migrator.                               }
{    Permite:                                                                  }
{      - Configurar conexiones de origen (SQL Server) y destino (MariaDB)      }
{      - Probar conectividad                                                   }
{      - Marcar las migraciones a ejecutar                                     }
{      - Lanzarlas en orden (respetando dependencias)                          }
{      - Ver el log y un resumen final                                         }
{                                                                              }
{    El formulario carga / guarda los parámetros en %APPDATA%\Factuzam\        }
{    migrator.ini (sin contraseñas en claro: se piden cada vez).               }
{******************************************************************************}
unit UMigrator;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.IniFiles, System.IOUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst, Vcl.ComCtrls, Vcl.Mask,
  // OmniThreadLibrary para el hilo de trabajo de la migracion
  OtlCommon, OtlTask, OtlTaskControl, OtlParallel, OtlSync,
  UMigEngine;

type
  TFormMigrator = class(TForm)
    PanelTop:          TPanel;
    PanelOrigen:       TGroupBox;
    lblSrcHost:        TLabel;
    lblSrcPort:        TLabel;
    lblSrcBase:        TLabel;
    lblSrcUser:        TLabel;
    lblSrcPwd:         TLabel;
    edSrcHost:         TEdit;
    edSrcPort:         TEdit;
    edSrcBase:         TEdit;
    edSrcUser:         TEdit;
    edSrcPwd:          TEdit;
    btnProbarSrc:      TButton;
    chkSrcWinAuth:     TCheckBox;
    PanelDestino:      TGroupBox;
    lblDstHost:        TLabel;
    lblDstPort:        TLabel;
    lblDstBase:        TLabel;
    lblDstUser:        TLabel;
    lblDstPwd:         TLabel;
    edDstHost:         TEdit;
    edDstPort:         TEdit;
    edDstBase:         TEdit;
    edDstUser:         TEdit;
    edDstPwd:          TEdit;
    btnProbarDst:      TButton;
    PanelSetup:        TPanel;
    GroupSetup:        TGroupBox;
    btnDumpEsqueleto:  TButton;
    btnCrearBBDD:      TButton;
    btnCargarEsquema:  TButton;
    btnLimpiarDemo:    TButton;
    PanelCentro:       TPanel;
    lblUsuario:        TLabel;
    edUsuario:         TEdit;
    lblNivelFam:       TLabel;
    edNivelFam:        TEdit;
    lblDigitosArt:     TLabel;
    edDigitosArt:      TEdit;
    GroupListado:      TGroupBox;
    listMigs:          TCheckListBox;
    btnMarcarTodas:    TButton;
    btnDesmarcarTodas: TButton;
    btnEjecutar:       TButton;
    PanelLog:          TPanel;
    lblLog:            TLabel;
    MemoLog:           TMemo;
    PanelProgreso:     TPanel;
    lblProgreso:       TLabel;
    pbProgreso:        TProgressBar;
    StatusBar:         TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnProbarSrcClick(Sender: TObject);
    procedure btnProbarDstClick(Sender: TObject);
    procedure btnEjecutarClick(Sender: TObject);
    procedure btnMarcarTodasClick(Sender: TObject);
    procedure btnDesmarcarTodasClick(Sender: TObject);
    procedure chkSrcWinAuthClick(Sender: TObject);
    procedure btnDumpEsqueletoClick(Sender: TObject);
    procedure btnCrearBBDDClick(Sender: TObject);
    procedure btnCargarEsquemaClick(Sender: TObject);
    procedure btnLimpiarDemoClick(Sender: TObject);
  private
    FEngine:       TMigEngine;
    FTask:         IOmniTaskControl;
    FCancel:       IOmniCancellationToken;
    FEjecutando:   Boolean;
    procedure Log(const sMsg: string);
    procedure RegistrarMigraciones;
    procedure RecargarListado;
    procedure CargarConfig;
    procedure GuardarConfig;
    function  RutaIni: string;
    procedure SetEjecutando(bValue: Boolean);
    procedure EjecutarMigracionesBackground;
  public
  end;

var
  FormMigrator: TFormMigrator;

implementation

{$R *.dfm}

uses
  UMigConn,
  inLibMigDumpEsqueleto,
  inLibMigFormasPago,
  inLibMigIvasGrupos,
  inLibMigIvas,
  inLibMigEmpresas,
  inLibMigAlmacenes,
  inLibMigClientes,
  inLibMigProveedores,
  inLibMigFamilias,
  inLibMigAtributos,
  inLibMigArticulos,
  inLibMigArticulosAtributos,
  inLibMigArticulosSkus,
  inLibMigInventarios;

// =========================================================================
//  Lifecycle
// =========================================================================

procedure TFormMigrator.FormCreate(Sender: TObject);
begin
  Caption  := 'Factuzam Migrator SQL Server';
  Position := poScreenCenter;

  FEngine := TMigEngine.Create(dmMig.conSrv, dmMig.conDst);
  // Las callbacks del engine pueden invocarse desde un hilo de trabajo
  // (cuando la migracion corre en background). Pasamos al hilo de UI
  // via TThread.Queue para evitar accesos concurrentes a los TControl.
  FEngine.OnLog :=
    procedure(const s: string)
    var sCopy: string;
    begin
      sCopy := s;
      TThread.Queue(nil,
        procedure
        begin
          Log(sCopy);
        end);
    end;
  FEngine.OnProgress :=
    procedure(const sDominio: string; iRow, iTotal: Integer)
    var sD: string; iR, iT: Integer;
    begin
      sD := sDominio; iR := iRow; iT := iTotal;
      TThread.Queue(nil,
        procedure
        begin
          if iT > 0 then
          begin
            pbProgreso.Max      := iT;
            pbProgreso.Position := Min(iR, iT);
            lblProgreso.Caption := Format(
              '%s: %d / %d  (%.0f%%)',
              [sD, iR, iT, iR * 100.0 / iT]);
          end
          else
          begin
            pbProgreso.Max      := 1;
            pbProgreso.Position := 0;
            lblProgreso.Caption := Format(
              '%s: %d / ?  (contando...)', [sD, iR]);
          end;
        end);
    end;
  RegistrarMigraciones;
  RecargarListado;
  CargarConfig;
  Log('Migrator listo. Configure las conexiones y pruebe conectividad.');
end;

procedure TFormMigrator.FormDestroy(Sender: TObject);
begin
  // Si hay una migracion corriendo, pedirle que pare y esperar un
  // poco a que termine el dominio actual.
  if Assigned(FCancel) then FCancel.Signal;
  if Assigned(FTask) then
  begin
    FTask.Terminate(5000);  // espera hasta 5s al worker
    FTask := nil;
  end;
  try
    GuardarConfig;
  except
    // no podemos hacer nada en destroy, ignoramos
  end;
  FEngine.Free;
end;

// =========================================================================
//  Registro de migraciones disponibles
// =========================================================================

procedure TFormMigrator.RegistrarMigraciones;
begin
  // El ORDEN importa: el listado se ejecuta de arriba a abajo y las
  // dependencias (clientes necesita formas_pago, articulos necesita
  // familias, etc.) deben respetarse.
  FEngine.Registrar('formas_pago', 'Formas de pago',
    'dbo.octipefe → fza_formas_pago',
    MigrarFormasPago);
  FEngine.Registrar('ivas_grupos', 'Grupos de IVA',
    'dbo.ocgrpiva → fza_ivas_grupos',
    MigrarIvasGrupos);
  FEngine.Registrar('ivas', 'Tipos de IVA (histórico)',
    'dbo.octipiva → fza_ivas',
    MigrarIvas);
  FEngine.Registrar('empresas', 'Empresas',
    'dbo.ocemp → fza_empresas',
    MigrarEmpresas);
  FEngine.Registrar('almacenes', 'Almacenes',
    'dbo.ocalm → fza_almacenes (requiere empresas)',
    MigrarAlmacenes);
  FEngine.Registrar('clientes', 'Clientes',
    'dbo.occli → fza_clientes (requiere formas_pago)',
    MigrarClientes);
  FEngine.Registrar('proveedores', 'Proveedores',
    'dbo.ocpro → fza_proveedores (requiere columna NOMBRE_PRV)',
    MigrarProveedores);
  FEngine.Registrar('familias', 'Familias de artículo',
    'dbo.ocniv (Nivel 2+4) → fza_articulos_familias',
    MigrarFamilias);
  FEngine.Registrar('colores_maestros', 'Catálogo colores',
    'dbo.occolor → fza_atributos_valores + fza_atributos_basicos (CO)',
    MigrarColoresMaestros);
  FEngine.Registrar('tallas_maestras', 'Catálogo tallas',
    'DISTINCT dbo.ocarttal → fza_atributos_valores + basicos (TAL)',
    MigrarTallasMaestras);
  FEngine.Registrar('articulos', 'Artículos',
    'dbo.ocartp → fza_articulos (requiere familias)',
    MigrarArticulos);
  FEngine.Registrar('articulos_colores', 'Colores por artículo',
    'dbo.ocartcol → fza_articulos_atributos_basicos (CO)',
    MigrarArticulosColores);
  FEngine.Registrar('articulos_tallas', 'Tallas por artículo',
    'dbo.ocarttal → fza_articulos_atributos_basicos (TAL)',
    MigrarArticulosTallas);
  FEngine.Registrar('skus', 'SKUs y códigos de barras',
    'dbo.ocartbap → fza_articulos_skus + fza_atributos_sku + ' +
    'fza_codigos_barras',
    MigrarArticulosSkus);
  FEngine.Registrar('inventarios', 'Inventario inicial (stock)',
    'dbo.ocartacp → fza_inventarios + fza_inventarios_lineas',
    MigrarInventarios);
end;

procedure TFormMigrator.RecargarListado;
var
  i: Integer;
  oItem: TMigItem;
begin
  listMigs.Items.BeginUpdate;
  try
    listMigs.Items.Clear;
    for i := 0 to FEngine.Items.Count - 1 do
    begin
      oItem := FEngine.Items[i];
      listMigs.Items.Add(Format('%s   (%s)',
        [oItem.Nombre, oItem.Descripcion]));
    end;
  finally
    listMigs.Items.EndUpdate;
  end;
end;

// =========================================================================
//  Acciones UI
// =========================================================================

procedure TFormMigrator.btnMarcarTodasClick(Sender: TObject);
var i: Integer;
begin
  for i := 0 to listMigs.Items.Count - 1 do
    listMigs.Checked[i] := True;
end;

procedure TFormMigrator.btnDesmarcarTodasClick(Sender: TObject);
var i: Integer;
begin
  for i := 0 to listMigs.Items.Count - 1 do
    listMigs.Checked[i] := False;
end;

// =========================================================================
//  Acciones "Preparar destino"
// =========================================================================

procedure TFormMigrator.btnDumpEsqueletoClick(Sender: TObject);
var
  oSave:  TSaveDialog;
  iCount: Integer;
begin
  if Trim(edDstBase.Text) = '' then
  begin
    ShowMessage('Rellena primero la BBDD ORIGEN del esqueleto en el ' +
                'panel "Destino" (sera la BBDD viva de la que se extrae).');
    Exit;
  end;
  oSave := TSaveDialog.Create(Self);
  try
    oSave.Title      := 'Guardar esqueleto Factuzam (.sql)';
    oSave.Filter     := 'Scripts SQL (*.sql)|*.sql|Todos (*.*)|*.*';
    oSave.DefaultExt := 'sql';
    oSave.FileName   := Format('esqueleto_%s_%s.sql',
      [edDstBase.Text, FormatDateTime('yyyymmdd_hhnn', Now)]);
    if not oSave.Execute then Exit;

    Screen.Cursor := crHourGlass;
    try
      dmMig.ConfigurarDestino(edDstHost.Text, edDstPort.Text,
                              edDstBase.Text, edDstUser.Text,
                              edDstPwd.Text);
      dmMig.conDst.Open;
      Log('Extrayendo esqueleto de "' + edDstBase.Text + '" ...');
      iCount := DumpEsqueleto(dmMig.conDst, oSave.FileName,
                              procedure(const s: string)
                              begin
                                Log(s);
                                Application.ProcessMessages;
                              end);
      Log(Format('Esqueleto guardado: %d objetos en %s',
                 [iCount, oSave.FileName]));
      ShowMessage(Format('Esqueleto generado (%d objetos):'#13#10'%s',
                  [iCount, oSave.FileName]));
    finally
      Screen.Cursor := crDefault;
    end;
  except
    on E: Exception do
    begin
      Log('ERROR extrayendo esqueleto: ' + E.Message);
      ShowMessage('Fallo extrayendo esqueleto:'#13#10 + E.Message);
    end;
  end;
  oSave.Free;
end;

procedure TFormMigrator.btnCrearBBDDClick(Sender: TObject);
begin
  if Trim(edDstBase.Text) = '' then
  begin
    ShowMessage('Rellena el campo "Base de datos" del destino antes de ' +
                'crearla.');
    Exit;
  end;
  if MessageDlg(Format(
       'Se va a crear la BBDD "%s" en %s:%s con charset utf8mb4 y ' +
       'collation utf8mb4_spanish_ci.'#13#10'Si ya existe no se hace ' +
       'nada. ¿Continuar?',
       [edDstBase.Text, edDstHost.Text, edDstPort.Text]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    dmMig.ConfigurarDestino(edDstHost.Text, edDstPort.Text,
                            edDstBase.Text, edDstUser.Text,
                            edDstPwd.Text);
    dmMig.CrearBBDDDestino(edDstBase.Text);
    Log('BBDD "' + edDstBase.Text + '" creada (o ya existia).');
    ShowMessage('BBDD "' + edDstBase.Text + '" lista. Ahora carga el ' +
                'esqueleto.');
  except
    on E: Exception do
    begin
      Log('ERROR creando BBDD: ' + E.Message);
      ShowMessage('Fallo creando BBDD:'#13#10 + E.Message);
    end;
  end;
  Screen.Cursor := crDefault;
end;

procedure TFormMigrator.btnCargarEsquemaClick(Sender: TObject);
var
  oOpen: TOpenDialog;
  sName: string;
begin
  if Trim(edDstBase.Text) = '' then
  begin
    ShowMessage('Rellena el campo "Base de datos" del destino.');
    Exit;
  end;
  oOpen := TOpenDialog.Create(Self);
  try
    oOpen.Title  := 'Cargar esqueleto Factuzam en ' + edDstBase.Text;
    oOpen.Filter := 'Scripts SQL (*.sql)|*.sql|Todos (*.*)|*.*';
    if not oOpen.Execute then Exit;

    // Aviso si el usuario apunta a factuzam_original.sql: ese fichero
    // es el dump COMPLETO con datos demo (clientes 293-321, proveedores
    // Northwind, empresa AGRICULTOR, articulos demo...). NO es un
    // esqueleto limpio — para eso esta el boton "Extraer esqueleto".
    sName := LowerCase(ExtractFileName(oOpen.FileName));
    if Pos('factuzam_original', sName) > 0 then
      if MessageDlg(
         'OJO: "factuzam_original.sql" es el dump DEMO completo, no '#13#10 +
         'un esqueleto limpio. Incluye datos como empresa 1 = '#13#10 +
         'AGRICULTOR, clientes 293-321, proveedores Northwind, etc. '#13#10 +
         'que despues hacen colisionar al migrador.'#13#10#13#10 +
         'Recomendado: cierra este dialogo, usa "Extraer esqueleto '#13#10 +
         'de BBDD viva..." apuntando a tu Factuzam de desarrollo, '#13#10 +
         'y carga ese .sql en su lugar. Si ya lo cargaste, pulsa '#13#10 +
         'el boton "Limpiar datos demo" para borrar la basura.'#13#10#13#10 +
         '¿Cargar igualmente?',
         mtWarning, [mbYes, mbNo], 0) <> mrYes then
        Exit;

    if MessageDlg(Format(
         'Se va a cargar "%s" en la BBDD "%s".'#13#10 +
         'Si la BBDD ya tiene tablas, el script puede pisarlas.'#13#10 +
         '¿Continuar?',
         [ExtractFileName(oOpen.FileName), edDstBase.Text]),
         mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;

    Screen.Cursor := crHourGlass;
    try
      dmMig.ConfigurarDestino(edDstHost.Text, edDstPort.Text,
                              edDstBase.Text, edDstUser.Text,
                              edDstPwd.Text);
      Log('Cargando esqueleto desde ' + oOpen.FileName + ' ...');
      dmMig.CargarEsquemaDestino(oOpen.FileName);
      Log('Esqueleto cargado en "' + edDstBase.Text + '".');
      ShowMessage('Esqueleto cargado correctamente.');
    finally
      Screen.Cursor := crDefault;
    end;
  except
    on E: Exception do
    begin
      Log('ERROR cargando esqueleto: ' + E.Message);
      ShowMessage('Fallo cargando esqueleto:'#13#10 + E.Message);
    end;
  end;
  oOpen.Free;
end;

procedure TFormMigrator.btnLimpiarDemoClick(Sender: TObject);
var iBorradas: Integer;
begin
  if Trim(edDstBase.Text) = '' then
  begin
    ShowMessage('Rellena el campo "Base de datos" del destino.');
    Exit;
  end;
  if MessageDlg(Format(
       'Se van a BORRAR del destino "%s" todas las filas demo '#13#10 +
       '(USUARIO_ALTA = DEMO / Administrador / SISTEMA) de:'#13#10 +
       '  fza_empresas, fza_almacenes, fza_clientes,'#13#10 +
       '  fza_proveedores, fza_articulos, fza_articulos_familias.'#13#10#13#10 +
       'Las tablas de SISTEMA (paises, ivas_tipos, winforms...) '#13#10 +
       'NO se tocan. ¿Continuar?', [edDstBase.Text]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    dmMig.ConfigurarDestino(edDstHost.Text, edDstPort.Text,
                            edDstBase.Text, edDstUser.Text,
                            edDstPwd.Text);
    iBorradas := dmMig.LimpiarDatosDemoDestino;
    Log(Format('Datos demo limpiados: %d filas borradas en total.',
        [iBorradas]));
    ShowMessage(Format('Borradas %d filas demo en total.', [iBorradas]));
  except
    on E: Exception do
    begin
      Log('ERROR limpiando demo: ' + E.Message);
      ShowMessage('Fallo limpiando demo:'#13#10 + E.Message);
    end;
  end;
  Screen.Cursor := crDefault;
end;

procedure TFormMigrator.chkSrcWinAuthClick(Sender: TObject);
begin
  edSrcUser.Enabled := not chkSrcWinAuth.Checked;
  edSrcPwd.Enabled  := not chkSrcWinAuth.Checked;
  if chkSrcWinAuth.Checked then
  begin
    edSrcUser.Text := '';
    edSrcPwd.Text  := '';
  end;
end;

procedure TFormMigrator.btnProbarSrcClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    dmMig.ConfigurarOrigen(edSrcHost.Text, edSrcPort.Text, edSrcBase.Text,
                           edSrcUser.Text, edSrcPwd.Text,
                           chkSrcWinAuth.Checked);
    dmMig.ProbarOrigen;
    Log(Format('OK origen: %s:%s/%s',
      [edSrcHost.Text, edSrcPort.Text, edSrcBase.Text]));
    ShowMessage('Conexión a SQL Server correcta.');
  except
    on E: Exception do
    begin
      Log('ERROR origen: ' + E.Message);
      ShowMessage('No se pudo conectar al origen:'#13#10 + E.Message);
    end;
  end;
  Screen.Cursor := crDefault;
end;

procedure TFormMigrator.btnProbarDstClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    dmMig.ConfigurarDestino(edDstHost.Text, edDstPort.Text, edDstBase.Text,
                            edDstUser.Text, edDstPwd.Text);
    dmMig.ProbarDestino;
    Log(Format('OK destino: %s:%s/%s',
      [edDstHost.Text, edDstPort.Text, edDstBase.Text]));
    ShowMessage('Conexión a MariaDB correcta.');
  except
    on E: Exception do
    begin
      Log('ERROR destino: ' + E.Message);
      ShowMessage('No se pudo conectar al destino:'#13#10 + E.Message);
    end;
  end;
  Screen.Cursor := crDefault;
end;

procedure TFormMigrator.SetEjecutando(bValue: Boolean);
begin
  FEjecutando := bValue;
  if bValue then
  begin
    btnEjecutar.Caption := 'Cancelar';
    // Bloquear otras acciones mientras corre la migracion. Solo
    // dejamos el Cancelar (el propio boton Ejecutar).
    btnProbarSrc.Enabled     := False;
    btnProbarDst.Enabled     := False;
    btnDumpEsqueleto.Enabled := False;
    btnCrearBBDD.Enabled     := False;
    btnCargarEsquema.Enabled := False;
    btnLimpiarDemo.Enabled   := False;
    btnMarcarTodas.Enabled   := False;
    btnDesmarcarTodas.Enabled:= False;
    listMigs.Enabled         := False;
  end
  else
  begin
    btnEjecutar.Caption := 'Ejecutar migraciones';
    btnProbarSrc.Enabled     := True;
    btnProbarDst.Enabled     := True;
    btnDumpEsqueleto.Enabled := True;
    btnCrearBBDD.Enabled     := True;
    btnCargarEsquema.Enabled := True;
    btnLimpiarDemo.Enabled   := True;
    btnMarcarTodas.Enabled   := True;
    btnDesmarcarTodas.Enabled:= True;
    listMigs.Enabled         := True;
    pbProgreso.Position      := 0;
    lblProgreso.Caption      := 'Inactivo';
  end;
end;

procedure TFormMigrator.btnEjecutarClick(Sender: TObject);
var
  i, iSeleccionadas: Integer;
begin
  // Si ya estamos ejecutando, este click es de "Cancelar"
  if FEjecutando then
  begin
    if Assigned(FCancel) then
    begin
      FCancel.Signal;
      Log('Cancelacion solicitada — terminando dominio actual...');
    end;
    Exit;
  end;

  iSeleccionadas := 0;
  for i := 0 to listMigs.Items.Count - 1 do
    if listMigs.Checked[i] then Inc(iSeleccionadas);
  if iSeleccionadas = 0 then
  begin
    ShowMessage('Marca al menos una migración antes de ejecutar.');
    Exit;
  end;

  if MessageDlg(Format('Se van a ejecutar %d migraciones contra la BBDD ' +
                       'destino %s. ¿Continuar?',
                       [iSeleccionadas, edDstBase.Text]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  // Configuracion + apertura de conexiones SE HACE EN UI THREAD antes
  // de lanzar el hilo de trabajo. UniDAC mueve la afinidad de la
  // conexion al primer hilo que la usa, asi que en cuanto el worker
  // empiece a hacer SELECT/INSERT el ownership pasa a el.
  dmMig.ConfigurarOrigen(edSrcHost.Text, edSrcPort.Text, edSrcBase.Text,
                         edSrcUser.Text, edSrcPwd.Text,
                         chkSrcWinAuth.Checked);
  dmMig.ConfigurarDestino(edDstHost.Text, edDstPort.Text, edDstBase.Text,
                          edDstUser.Text, edDstPwd.Text);
  FEngine.Usuario := edUsuario.Text;
  if FEngine.Usuario = '' then
    FEngine.Usuario := 'MIGRADOR';
  FEngine.NivelFamiliasHoja  := StrToIntDef(edNivelFam.Text, 4);
  FEngine.DigitosContadorArt := StrToIntDef(edDigitosArt.Text, 4);

  try
    dmMig.conSrv.Open;
    dmMig.conDst.Open;
  except
    on E: Exception do
    begin
      ShowMessage('Fallo abriendo conexiones: ' + E.Message);
      Log('ERROR abriendo conexiones: ' + E.Message);
      Exit;
    end;
  end;

  SetEjecutando(True);
  EjecutarMigracionesBackground;
end;

procedure TFormMigrator.EjecutarMigracionesBackground;
var
  aCodigos: TArray<string>;
  aNombres: TArray<string>;
  i, iLen:  Integer;
begin
  // Snapshot de las migraciones marcadas (capturamos los codigos
  // antes de lanzar el hilo, asi el listado puede deshabilitarse
  // sin race).
  iLen := 0;
  SetLength(aCodigos, listMigs.Items.Count);
  SetLength(aNombres, listMigs.Items.Count);
  for i := 0 to listMigs.Items.Count - 1 do
    if listMigs.Checked[i] then
    begin
      aCodigos[iLen] := FEngine.Items[i].Codigo;
      aNombres[iLen] := FEngine.Items[i].Nombre;
      Inc(iLen);
    end;
  SetLength(aCodigos, iLen);
  SetLength(aNombres, iLen);

  FCancel := CreateOmniCancellationToken;

  FTask := CreateTask(
    procedure(const task: IOmniTask)
    var
      j:          Integer;
      Stats:      TMigStats;
      TotalStats: TMigStats;
      sCodigo:    string;
      sNombre:    string;
    begin
      TotalStats := Default(TMigStats);
      for j := 0 to High(aCodigos) do
      begin
        if task.CancellationToken.IsSignalled then
        begin
          TThread.Queue(nil,
            procedure begin Log('--- CANCELADO por el usuario ---'); end);
          Break;
        end;
        sCodigo := aCodigos[j];
        sNombre := aNombres[j];
        Stats   := Default(TMigStats);
        try
          FEngine.Ejecutar(sCodigo, Stats);
          Inc(TotalStats.Leidas,     Stats.Leidas);
          Inc(TotalStats.Insertadas, Stats.Insertadas);
          Inc(TotalStats.Saltadas,   Stats.Saltadas);
          Inc(TotalStats.Errores,    Stats.Errores);
        except
          on E: Exception do
          begin
            Inc(TotalStats.Errores);
            // Loguear y seguir con las demas (no preguntamos en hilo
            // de trabajo — la decision se toma al inicio).
            TThread.Queue(nil,
              procedure
              var sMsg: string;
              begin
                sMsg := Format('FALLO TOTAL en %s: %s',
                               [sCodigo, E.Message]);
                Log(sMsg);
              end);
          end;
        end;
      end;

      TThread.Queue(nil,
        procedure
        begin
          Log('');
          Log(Format(
            'TOTAL: %d leidas, %d insertadas, %d saltadas, %d errores.',
            [TotalStats.Leidas, TotalStats.Insertadas,
             TotalStats.Saltadas, TotalStats.Errores]));
          SetEjecutando(False);
        end);
    end)
    .CancelWith(FCancel)
    .Unobserved
    .Run;
end;

// =========================================================================
//  Log + persistencia
// =========================================================================

procedure TFormMigrator.Log(const sMsg: string);
begin
  MemoLog.Lines.Add(FormatDateTime('hh:nn:ss ', Now) + sMsg);
  StatusBar.Panels[0].Text := sMsg;
end;

function TFormMigrator.RutaIni: string;
var sDir: string;
begin
  sDir := TPath.Combine(TPath.GetHomePath, 'Factuzam');
  if not TDirectory.Exists(sDir) then
    TDirectory.CreateDirectory(sDir);
  Result := TPath.Combine(sDir, 'migrator.ini');
end;

procedure TFormMigrator.CargarConfig;
var oIni: TIniFile;
begin
  if not TFile.Exists(RutaIni) then Exit;
  oIni := TIniFile.Create(RutaIni);
  try
    edSrcHost.Text         := oIni.ReadString('Origen',  'Host', '');
    edSrcPort.Text         := oIni.ReadString('Origen',  'Port', '1433');
    edSrcBase.Text         := oIni.ReadString('Origen',  'Base', '');
    edSrcUser.Text         := oIni.ReadString('Origen',  'User', 'sa');
    chkSrcWinAuth.Checked  := oIni.ReadBool  ('Origen',  'WinAuth', False);
    chkSrcWinAuthClick(nil);  // refresca enabled de user/pwd
    edDstHost.Text := oIni.ReadString('Destino', 'Host',   '127.0.0.1');
    edDstPort.Text := oIni.ReadString('Destino', 'Port',   '3306');
    edDstBase.Text := oIni.ReadString('Destino', 'Base',   'factuzam');
    edDstUser.Text := oIni.ReadString('Destino', 'User',   'root');
    edUsuario.Text    :=
      oIni.ReadString ('General', 'Usuario', 'MIGRADOR');
    edNivelFam.Text   :=
      IntToStr(oIni.ReadInteger('General', 'NivelFamHoja', 4));
    edDigitosArt.Text :=
      IntToStr(oIni.ReadInteger('General', 'DigitosContadorArt', 4));
  finally
    oIni.Free;
  end;
end;

procedure TFormMigrator.GuardarConfig;
var oIni: TIniFile;
begin
  oIni := TIniFile.Create(RutaIni);
  try
    oIni.WriteString('Origen',  'Host',    edSrcHost.Text);
    oIni.WriteString('Origen',  'Port',    edSrcPort.Text);
    oIni.WriteString('Origen',  'Base',    edSrcBase.Text);
    oIni.WriteString('Origen',  'User',    edSrcUser.Text);
    oIni.WriteBool  ('Origen',  'WinAuth', chkSrcWinAuth.Checked);
    oIni.WriteString('Destino', 'Host', edDstHost.Text);
    oIni.WriteString('Destino', 'Port', edDstPort.Text);
    oIni.WriteString('Destino', 'Base', edDstBase.Text);
    oIni.WriteString('Destino', 'User', edDstUser.Text);
    oIni.WriteString ('General', 'Usuario',            edUsuario.Text);
    oIni.WriteInteger('General', 'NivelFamHoja',
                      StrToIntDef(edNivelFam.Text,   4));
    oIni.WriteInteger('General', 'DigitosContadorArt',
                      StrToIntDef(edDigitosArt.Text, 4));
  finally
    oIni.Free;
  end;
end;

end.
