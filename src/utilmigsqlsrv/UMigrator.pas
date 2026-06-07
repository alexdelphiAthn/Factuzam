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
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX,
  System.SysUtils, System.Variants,
  System.Classes, System.IniFiles, System.IOUtils, System.Math,
  System.SyncObjs,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst, Vcl.ComCtrls, Vcl.Mask,
  // OmniThreadLibrary para el hilo de trabajo de la migracion
  OtlCommon, OtlTask, OtlTaskControl, OtlParallel, OtlSync,
  Data.DB, Uni,
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
    btnResetearMig:    TButton;
    btnBorrarBBDD:     TButton;
    PanelCentro:       TPanel;
    lblUsuario:        TLabel;
    edUsuario:         TEdit;
    lblNivelFam:       TLabel;
    edNivelFam:        TEdit;
    lblHilos:          TLabel;
    edHilos:           TEdit;
    GroupListado:      TGroupBox;
    listMigs:          TCheckListBox;
    btnMarcarTodas:    TButton;
    btnDesmarcarTodas: TButton;
    btnEjecutar:       TButton;
    PageInferior:      TPageControl;
    TabProgreso:       TTabSheet;
    MemoProgreso:      TMemo;
    TabLog:            TTabSheet;
    MemoLog:           TMemo;
    TabErrores:        TTabSheet;
    MemoErrores:       TMemo;
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
    procedure btnResetearMigClick(Sender: TObject);
    procedure btnBorrarBBDDClick(Sender: TObject);
  private
    FEngine:       TMigEngine;
    FTask:         IOmniTaskControl;
    FCancel:       IOmniCancellationToken;
    FEjecutando:   Boolean;
    // Mapa dominio → linea de progreso, accedido SOLO desde el UI
    // thread (vive en el memo MemoProgreso).
    FLineasProgreso: TStringList;
    // Rutas de los .log de la corrida actual (errores filtrados y log
    // completo). Se calculan al pulsar Ejecutar; vacias fuera de migracion.
    FRutaLogErrores: string;
    FRutaLogCompleto: string;
    procedure AnexarLinea(const sRuta, sTexto: string);
    procedure Log(const sMsg: string);
    procedure RegistrarMigraciones;
    procedure RecargarListado;
    procedure CargarConfig;
    procedure GuardarConfig;
    function  RutaIni: string;
    procedure SetEjecutando(bValue: Boolean);
    procedure EjecutarMigracionesBackground;
    procedure ActualizarProgreso(const sDominio: string;
                                  iRow, iTotal: Integer);
  public
  end;

var
  FormMigrator: TFormMigrator;

implementation

{$R *.dfm}

uses
  UMigConn,
  inLibMigDumpEsqueleto,
  inLibMigEmpresas,
  inLibMigAlmacenes,
  inLibMigClientes,
  inLibMigProveedores,
  inLibMigFamilias,
  inLibMigAtributos,
  inLibMigArticulos,
  inLibMigArticulosAtributos,
  inLibMigArticulosSkus,
  inLibMigInventarios,
  inLibMigMovimientos,
  inLibMigVentas,
  inLibMigFacturas,
  inLibMigVales,
  inLibMigArqueos,
  inLibMigTallajes,
  inLibMigArticulosTallajes,
  inLibMigArticulosProveedores,
  inLibMigArticulosPropiedades,
  inLibMigArticulosTarifas,
  inLibMigEntorno,
  inLibMigCompras;

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
          ActualizarProgreso(sD, iR, iT);
        end);
    end;
  FLineasProgreso := TStringList.Create;
  RegistrarMigraciones;
  RecargarListado;
  CargarConfig;
  Log('Migrator listo. Configure las conexiones y pruebe conectividad.');
end;

procedure TFormMigrator.FormDestroy(Sender: TObject);
var
  bTerminado: Boolean;
begin
  // Si hay una migracion corriendo, pedirle que pare y esperar un
  // poco a que termine el dominio actual.
  if Assigned(FCancel) then FCancel.Signal;
  if Assigned(FEngine) then FEngine.Cancelar;
  bTerminado := True;
  if Assigned(FTask) then
  begin
    bTerminado := FTask.Terminate(5000);  // True si termino dentro de 5s
    FTask := nil;
  end;
  try
    GuardarConfig;
  except
    // no podemos hacer nada en destroy, ignoramos
  end;
  FLineasProgreso.Free;
  // Solo liberamos el motor si el worker TERMINO. Si sigue vivo (atascado
  // en una query larga que no chequea cancelacion), liberar FEngine
  // provocaria AccessViolation cuando el clon del worker lea FMaster
  // (IsCancelado/OnLog). Preferimos una fuga inocua al cerrar la app.
  if bTerminado then
    FEngine.Free;
end;

procedure TFormMigrator.ActualizarProgreso(const sDominio: string;
                                            iRow, iTotal: Integer);
var
  i, iIdx: Integer;
  sLinea, sPrefijo: string;
  bCompletado: Boolean;
begin
  // La pestana "Progreso (dominios activos)" muestra SOLO lo que se esta
  // procesando AHORA: una linea por dominio en curso. Cuando un dominio
  // llega al 100% se quita de la lista (su resumen final queda en el
  // "Log acumulado"), asi la linea activa no se entierra bajo decenas de
  // dominios ya migrados y siempre se ve lo que corre ahora mismo.
  sPrefijo := Format('[%-22s]', [sDominio]);
  bCompletado := (iTotal > 0) and (iRow >= iTotal);
  if iTotal > 0 then
    sLinea := Format('%s  %7d / %7d  (%5.1f%%)',
      [sPrefijo, iRow, iTotal, iRow * 100.0 / iTotal])
  else
    sLinea := Format('%s  %7d / ?        (contando...)',
      [sPrefijo, iRow]);

  iIdx := -1;
  for i := 0 to FLineasProgreso.Count - 1 do
    if Copy(FLineasProgreso[i], 1, Length(sPrefijo)) = sPrefijo then
    begin
      iIdx := i;
      Break;
    end;
  if bCompletado then
  begin
    // Dominio terminado: fuera de la lista de activos.
    if iIdx >= 0 then
      FLineasProgreso.Delete(iIdx);
  end
  else if iIdx >= 0 then
    FLineasProgreso[iIdx] := sLinea
  else
    FLineasProgreso.Add(sLinea);

  MemoProgreso.Lines.BeginUpdate;
  try
    MemoProgreso.Lines.Assign(FLineasProgreso);
  finally
    MemoProgreso.Lines.EndUpdate;
  end;
end;

// =========================================================================
//  Registro de migraciones disponibles
// =========================================================================

procedure TFormMigrator.RegistrarMigraciones;
begin
  // El ORDEN importa: el listado se ejecuta de arriba a abajo y las
  // dependencias (articulos necesita familias, skus necesitan
  // articulos, etc.) deben respetarse.
  // NOTA: formas_pago, grupos de IVA y tipos de IVA NO se migran;
  // los IVAs ya estan correctamente definidos en la BBDD demo y
  // las formas de pago no son necesarias en este momento.
  FEngine.Registrar('empresas', 'Empresas',
    'dbo.ocemp → fza_empresas',
    MigrarEmpresas);
  FEngine.Registrar('almacenes', 'Almacenes',
    'dbo.ocalm → fza_almacenes (requiere empresas)',
    MigrarAlmacenes);
  FEngine.Registrar('clientes', 'Clientes',
    'dbo.occli → fza_clientes',
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
  FEngine.Registrar('tallajes', 'Sistemas de tallas (tallajes)',
    'dbo.ocgrptal + ocgrptalnor → fza_atributos_conjuntos + det',
    MigrarTallajes);
  FEngine.Registrar('articulos_tallajes_asign',
    'Asignar sistema de tallas a artículo',
    'ocartp.NroTallaje → fza_articulos_conjuntos_asign',
    MigrarArticulosTallajes);
  FEngine.Registrar('skus', 'SKUs y códigos de barras',
    'dbo.ocartbap → fza_articulos_skus + fza_atributos_sku + ' +
    'fza_codigos_barras',
    MigrarArticulosSkus);
  FEngine.Registrar('inventarios', 'Inventario inicial (stock)',
    'dbo.ocartacp → fza_inventarios + fza_inventarios_lineas',
    MigrarInventarios);
  // ALTERNATIVA a "Inventario inicial": migra el histórico de movimientos
  // y reconstruye el stock desde él. Ejecuta una u otra, no ambas.
  FEngine.Registrar('movimientos', 'Movimientos histórico (stock)',
    'dbo.ocmovarp → fza_movimientos_almacen + reconstruye stockactual',
    MigrarMovimientos);
  FEngine.Registrar('ventas', 'Ventas / Caja (occaj)',
    'dbo.occaj → fza_caja_operaciones + fza_caja_pagos + ' +
    'fza_depositos_cliente (AL→depósito, cobro→adelanto)',
    MigrarVentas);
  FEngine.Registrar('facturas', 'Facturas de venta (occajarp)',
    'dbo.occaj/occajarp → fza_facturas + fza_facturas_lineas',
    MigrarFacturas);
  FEngine.Registrar('vales', 'Vales de tienda (occajvale)',
    'dbo.occajvale → fza_caja_vales',
    MigrarVales);
  FEngine.Registrar('arqueos', 'Arqueos / cierres Z (ocarqueonew)',
    'dbo.ocarqueonew → fza_caja_arqueos + fza_caja_arqueos_recuento',
    MigrarArqueos);
  FEngine.Registrar('articulos_proveedores',
    'Proveedor y modelo por artículo',
    'ocartp.Proveedor + Modelo → fza_articulos_proveedores',
    MigrarArticulosProveedores);
  FEngine.Registrar('articulos_propiedades',
    'Propiedad TEMPORADA por artículo',
    'ocartp.Temporada → fza_propiedades + valores + ' +
    'fza_articulos_propiedades',
    MigrarArticulosPropiedades);
  FEngine.Registrar('articulos_tarifas',
    'Precios PVP por artículo',
    'dbo.ocarttap → fza_articulos_tarifas',
    MigrarArticulosTarifas);
  // Ajuste del entorno: numeración, series y cajas para dejar la instalación
  // lista para operar (ver inLibMigEntorno / migracion_entorno.md).
  FEngine.Registrar('entorno_contadores', 'Contadores (occtador)',
    'dbo.occtador → fza_contadores (numeración de documentos y globales)',
    MigrarEntornoContadores);
  FEngine.Registrar('entorno_contadores_familia',
    'Contador por familia (ocnivnro)',
    'dbo.ocnivnro → fza_articulos_familias.CONTADOR_ART_FAM',
    MigrarEntornoContadoresFamilia);
  FEngine.Registrar('entorno_cajas', 'Cajas de almacén (occajas)',
    'dbo.occajas → fza_almacenes_cajas',
    MigrarEntornoCajas);
  FEngine.Registrar('entorno_series', 'Series por empresa (ocseract)',
    'dbo.ocseract → fza_empresas_series',
    MigrarEntornoSeries);
  // Compras: pedidos y albaranes de entrada (modelo plano, sin celdas; ver
  // inLibMigCompras / migracion_compras.md).
  FEngine.Registrar('pedidos_compra', 'Pedidos de compra (ocped)',
    'dbo.ocped → fza_pedidos_compra + lineas',
    MigrarPedidosCompra);
  FEngine.Registrar('albaranes_compra', 'Albaranes de compra (ocalbpro)',
    'dbo.ocalbpro → fza_albaranes_compra + lineas',
    MigrarAlbaranesCompra);
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
       'Se van a BORRAR del destino "%s" todas las filas demo del'#13#10 +
       'seed factuzam_original.sql en 56 tablas (articulos, SKUs,'#13#10 +
       'tarifas, codigos_barras, atributos, propiedades, clientes,'#13#10 +
       'proveedores, almacenes, empresas, inventarios, facturas,'#13#10 +
       'pedidos, albaranes, compras, arqueos, caja, movimientos...).'#13#10 +
       #13#10 +
       'Filtro: USUARIO_ALTA IN (DEMO, Administrador, Sistema,'#13#10 +
       'SISTEMA, Admin, ADMIN, SCRIPT_DEMO, SCRIPT_FIX,'#13#10 +
       'FIX_SKU_STOCK, MIGRACION).'#13#10 +
       #13#10 +
       'NO se tocan tablas de SISTEMA (paises, ivas*, winforms,'#13#10 +
       'usuarios*, metadatos, contadores, tipos_documentos...).'#13#10 +
       #13#10 +
       'Util tras cargar factuzam_original.sql, ANTES de migrar.'#13#10 +
       '¿Continuar?', [edDstBase.Text]),
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

procedure TFormMigrator.btnResetearMigClick(Sender: TObject);
var
  iBorradas: Integer;
  sUser:     string;
begin
  if Trim(edDstBase.Text) = '' then
  begin
    ShowMessage('Rellena el campo "Base de datos" del destino.');
    Exit;
  end;
  sUser := Trim(edUsuario.Text);
  if sUser = '' then sUser := 'MIGRADOR';
  if MessageDlg(Format(
       'Se van a BORRAR del destino "%s" todas las filas que haya '#13#10 +
       'creado una migracion previa (USUARIO_ALTA = "%s") en las '#13#10 +
       '41 tablas que toca el migrador: facturas, movimientos, compras '#13#10 +
       '(pedidos y albaranes), caja, inventarios, skus, articulos, '#13#10 +
       'clientes, proveedores, almacenes, empresas, contadores,...).'#13#10#13#10 +
       'NO se tocan tablas de SISTEMA ni filas creadas por otros '#13#10 +
       'usuarios (demo, Administrador, etc.).'#13#10#13#10 +
       'Util para volver a ejecutar la migracion desde cero.'#13#10 +
       '¿Continuar?', [edDstBase.Text, sUser]),
       mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    dmMig.ConfigurarDestino(edDstHost.Text, edDstPort.Text,
                            edDstBase.Text, edDstUser.Text,
                            edDstPwd.Text);
    iBorradas := dmMig.ResetearMigracionAnterior(sUser);
    Log(Format('Migracion anterior reseteada: %d filas borradas ' +
               '(USUARIO_ALTA=%s).', [iBorradas, sUser]));
    ShowMessage(Format('Borradas %d filas de la migracion previa.',
      [iBorradas]));
  except
    on E: Exception do
    begin
      Log('ERROR reseteando migracion: ' + E.Message);
      ShowMessage('Fallo reseteando migracion:'#13#10 + E.Message);
    end;
  end;
  Screen.Cursor := crDefault;
end;

procedure TFormMigrator.btnBorrarBBDDClick(Sender: TObject);
var
  sBase, sConfirma: string;
begin
  sBase := Trim(edDstBase.Text);
  if sBase = '' then
  begin
    ShowMessage('Rellena el campo "Base de datos" del destino.');
    Exit;
  end;

  // Doble confirmacion: aviso fuerte y luego pedir que tecleen el
  // nombre exacto de la BBDD para evitar borrados accidentales.
  if MessageDlg(Format(
       'ATENCION: se va a EJECUTAR DROP DATABASE sobre "%s" en el '#13#10 +
       'servidor MariaDB "%s:%s".'#13#10#13#10 +
       'Esto BORRA TODOS los datos y tablas de esa BBDD, no hay '#13#10 +
       'vuelta atras. Asegurate de que es la BBDD correcta y de que '#13#10 +
       'tienes copia de seguridad si la necesitas.'#13#10#13#10 +
       '¿Seguro que quieres continuar?',
       [sBase, edDstHost.Text, edDstPort.Text]),
       mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  sConfirma := '';
  if not InputQuery('Confirmar borrado de BBDD',
       'Teclea el nombre EXACTO de la BBDD a borrar para confirmar:',
       sConfirma) then
    Exit;
  if Trim(sConfirma) <> sBase then
  begin
    ShowMessage('Nombre no coincide. Operacion cancelada.');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    dmMig.ConfigurarDestino(edDstHost.Text, edDstPort.Text,
                            sBase, edDstUser.Text, edDstPwd.Text);
    dmMig.BorrarBBDDDestino(sBase);
    Log(Format('BBDD destino "%s" BORRADA (DROP DATABASE).', [sBase]));
    ShowMessage(Format('BBDD "%s" borrada.'#13#10#13#10 +
      'Ahora puedes crearla de nuevo con "Crear BBDD destino" '#13#10 +
      'y cargar el esqueleto con "Cargar esqueleto destino".', [sBase]));
  except
    on E: Exception do
    begin
      Log('ERROR borrando BBDD: ' + E.Message);
      ShowMessage('Fallo borrando BBDD:'#13#10 + E.Message);
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
    // Saltar a la pestana de progreso en vivo al arrancar.
    PageInferior.ActivePage := TabProgreso;
    // Bloquear otras acciones mientras corre la migracion. Solo
    // dejamos el Cancelar (el propio boton Ejecutar).
    btnProbarSrc.Enabled     := False;
    btnProbarDst.Enabled     := False;
    btnDumpEsqueleto.Enabled := False;
    btnCrearBBDD.Enabled     := False;
    btnCargarEsquema.Enabled := False;
    btnLimpiarDemo.Enabled   := False;
    btnResetearMig.Enabled   := False;
    btnBorrarBBDD.Enabled    := False;
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
    btnResetearMig.Enabled   := True;
    btnBorrarBBDD.Enabled    := True;
    btnMarcarTodas.Enabled   := True;
    btnDesmarcarTodas.Enabled:= True;
    listMigs.Enabled         := True;
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
      FCancel.Signal;
    // Tambien marcamos el flag interno del engine para que los
    // mappers en mitad de un bucle largo (SKUs, articulos_atributos)
    // lo vean y salgan sin esperar a terminar.
    if Assigned(FEngine) then
      FEngine.Cancelar;
    Log('Cancelacion solicitada — los mappers en curso saldran ' +
        'en el proximo punto seguro.');
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

  // Preparar log de errores en disco para esta corrida.
  FRutaLogErrores := TPath.Combine(
    TPath.Combine(TPath.GetHomePath, 'Factuzam'),
    'migrator_errores_' +
    FormatDateTime('yyyymmdd_hhnnss', Now) + '.log');
  FRutaLogCompleto := TPath.Combine(
    TPath.Combine(TPath.GetHomePath, 'Factuzam'),
    'migrator_log_' +
    FormatDateTime('yyyymmdd_hhnnss', Now) + '.log');
  if not TDirectory.Exists(ExtractFilePath(FRutaLogErrores)) then
    TDirectory.CreateDirectory(ExtractFilePath(FRutaLogErrores));
  MemoErrores.Lines.Clear;
  Log('Log completo de esta corrida: ' + FRutaLogCompleto);
  Log('Errores de esta corrida se guardaran en: ' + FRutaLogErrores);

  SetEjecutando(True);
  EjecutarMigracionesBackground;
end;

// Tabla de dependencias entre dominios (DAG simplificado a waves):
// los dominios de la misma wave corren en paralelo entre si. Las
// waves se procesan secuencialmente, no pasamos a la siguiente
// hasta que termina la anterior. Asi respetamos:
//   - empresas antes que almacenes
//   - familias antes que articulos
//   - tallas_maestras antes que tallajes y antes que articulos_tallas
//   - articulos antes que articulos_colores/tallas/skus
//   - skus + almacenes antes que inventarios
function WaveDeDominio(const sCodigo: string): Integer;
begin
  if (sCodigo = 'empresas')         or
     (sCodigo = 'proveedores')      or
     (sCodigo = 'familias')         or
     (sCodigo = 'colores_maestros') or
     (sCodigo = 'tallas_maestras') then Exit(0);
  if (sCodigo = 'almacenes')   or
     (sCodigo = 'clientes')    or
     (sCodigo = 'articulos')   or
     (sCodigo = 'tallajes')    or
     (sCodigo = 'entorno_contadores')         or
     (sCodigo = 'entorno_contadores_familia') then Exit(1);
  if (sCodigo = 'articulos_colores')        or
     (sCodigo = 'articulos_tallas')         or
     (sCodigo = 'articulos_tallajes_asign') or
     (sCodigo = 'articulos_proveedores')    or
     (sCodigo = 'articulos_propiedades')    or
     (sCodigo = 'articulos_tarifas')        or
     (sCodigo = 'entorno_cajas')            or
     (sCodigo = 'entorno_series')           or
     (sCodigo = 'skus')                     then Exit(2);
  // Compras (pedidos/albaranes) solo necesitan empresas, almacenes,
  // proveedores y SKUs (waves 0-2); no dependen de movimientos ni facturas.
  if (sCodigo = 'inventarios')      or (sCodigo = 'movimientos')
  or (sCodigo = 'ventas')           or (sCodigo = 'pedidos_compra')
  or (sCodigo = 'albaranes_compra') then Exit(3);
  // facturas va DESPUES de movimientos: al terminar enlaza cada movimiento
  // con su factura (REF_MOV) y necesita los movimientos ya migrados.
  if (sCodigo = 'facturas') then Exit(4);
  // Default: wave 0 (conservador, sin deps conocidas)
  Result := 0;
end;

procedure TFormMigrator.EjecutarMigracionesBackground;
var
  aCodigos:           TArray<string>;
  i, iLen:            Integer;
begin
  // Snapshot de codigos marcados antes de lanzar el hilo.
  iLen := 0;
  SetLength(aCodigos, listMigs.Items.Count);
  for i := 0 to listMigs.Items.Count - 1 do
    if listMigs.Checked[i] then
    begin
      aCodigos[iLen] := FEngine.Items[i].Codigo;
      Inc(iLen);
    end;
  SetLength(aCodigos, iLen);

  FCancel := CreateOmniCancellationToken;
  // Resetear el flag de cancel del engine maestro por si quedo a 1
  // de una corrida anterior cancelada.
  FEngine.ResetCancel;
  MemoProgreso.Lines.Clear;
  FLineasProgreso.Clear;

  // Lanzamos un hilo coordinador. Dentro de cada wave creamos un task
  // por dominio (todos a la vez) pero los gateamos con un semaforo de
  // capacidad iMaxHilos. Esto da un POOL real: en cuanto un worker
  // libera el semaforo, otro pendiente entra inmediatamente. Asi no
  // se desperdicia tiempo esperando al hilo mas lento de cada lote.
  FTask := CreateTask(
    procedure(const task: IOmniTask)
    var
      iWave, iLoc, iTaskIdx:       Integer;
      iMaxHilos:                   Integer;
      aDeWave:                     TArray<string>;
      aTasksWave:                  TArray<IOmniTaskControl>;
      iTotL, iTotI, iTotS, iTotE:  Integer;
      sWaveCsv:                    string;
      semSlots:                    TSemaphore;
    begin
      iTotL := 0; iTotI := 0; iTotS := 0; iTotE := 0;
      iMaxHilos := task.Param['MaxHilos'].AsInteger;
      if iMaxHilos < 1 then iMaxHilos := 1;

      for iWave := 0 to 4 do
      begin
        if task.CancellationToken.IsSignalled then Break;

        // Filtrar codigos de esta wave
        SetLength(aDeWave, 0);
        for iLoc := 0 to High(aCodigos) do
          if WaveDeDominio(aCodigos[iLoc]) = iWave then
          begin
            SetLength(aDeWave, Length(aDeWave) + 1);
            aDeWave[High(aDeWave)] := aCodigos[iLoc];
          end;
        if Length(aDeWave) = 0 then Continue;

        // Mensaje de inicio de wave. FEngine.Log marshallea a UI via
        // su OnLog (que ya hace TThread.Queue), asi evitamos otra
        // capa de anonimos anidados.
        sWaveCsv := '';
        for iLoc := 0 to High(aDeWave) do
        begin
          if sWaveCsv <> '' then sWaveCsv := sWaveCsv + ', ';
          sWaveCsv := sWaveCsv + aDeWave[iLoc];
        end;
        FEngine.Log(Format('=== Wave %d (%d dominios): %s ===',
                           [iWave, Length(aDeWave), sWaveCsv]));

        // Semaforo que limita a iMaxHilos workers ejecutando dentro
        // del cuerpo a la vez. Lanzamos TODOS los tasks de la wave;
        // cada uno se bloquea en Acquire hasta que haya hueco. Cuando
        // un worker libera (Release), el siguiente pendiente entra.
        semSlots := TSemaphore.Create(nil, iMaxHilos, iMaxHilos, '');
        try
          SetLength(aTasksWave, Length(aDeWave));
          for iTaskIdx := 0 to High(aDeWave) do
          begin
            aTasksWave[iTaskIdx] := CreateTask(
            procedure(const t: IOmniTask)
            var
              sCodigo:    string;
              LocalSrv:   TUniConnection;
              LocalDst:   TUniConnection;
              LocalEng:   TMigEngine;
              LocalStats: TMigStats;
              bComInit:   Boolean;
              bAdquirido: Boolean;
            begin
              sCodigo := t.Param['Codigo'].AsString;
              bAdquirido := False;
              if t.CancellationToken.IsSignalled then Exit;
              // Esperar slot del pool. Si se cancela antes de
              // adquirir, salir sin trabajar.
              if semSlots.WaitFor(INFINITE) <> wrSignaled then Exit;
              bAdquirido := True;
              if t.CancellationToken.IsSignalled then
              begin
                semSlots.Release;
                Exit;
              end;
              // UniDAC SQL Server usa OLE DB → COM. En el UI thread
              // ya esta inicializado, pero los hilos de trabajo
              // necesitan llamar CoInitialize. Sin esto:
              //   EOLEDBError 800401F0h "CoInitialize has not been
              //   called".
              bComInit := Succeeded(CoInitializeEx(nil,
                                                    COINIT_MULTITHREADED));
              LocalSrv := nil;
              LocalDst := nil;
              LocalEng := nil;
              try
                LocalSrv := dmMig.ClonarConexionOrigen;
                LocalDst := dmMig.ClonarConexionDestino;
                LocalSrv.Open;
                LocalDst.Open;
                LocalEng := TMigEngine.CreateClone(LocalSrv, LocalDst,
                                                     FEngine);
                try
                  LocalEng.Ejecutar(sCodigo, LocalStats);
                  TInterlocked.Add(iTotL, LocalStats.Leidas);
                  TInterlocked.Add(iTotI, LocalStats.Insertadas);
                  TInterlocked.Add(iTotS, LocalStats.Saltadas);
                  TInterlocked.Add(iTotE, LocalStats.Errores);
                except
                  on E: Exception do
                  begin
                    TInterlocked.Increment(iTotE);
                    FEngine.Log(Format('FALLO TOTAL en %s: %s',
                                       [sCodigo, E.Message]));
                  end;
                end;
              finally
                if Assigned(LocalEng) then LocalEng.Free;
                if Assigned(LocalDst) then
                begin
                  if LocalDst.Connected then LocalDst.Close;
                  LocalDst.Free;
                end;
                if Assigned(LocalSrv) then
                begin
                  if LocalSrv.Connected then LocalSrv.Close;
                  LocalSrv.Free;
                end;
                if bComInit then CoUninitialize;
                if bAdquirido then semSlots.Release;
              end;
            end)
            .SetParameter('Codigo', aDeWave[iTaskIdx])
            .CancelWith(task.CancellationToken)
            .Unobserved
            .Run;
          end;

          // Esperar a que terminen TODOS los workers de la wave.
          // El semaforo ya garantiza que como mucho iMaxHilos
          // hayan estado activos simultaneamente.
          for iTaskIdx := 0 to High(aTasksWave) do
            aTasksWave[iTaskIdx].WaitFor(INFINITE);
          SetLength(aTasksWave, 0);
        finally
          semSlots.Free;
        end;
      end;

      FEngine.Log('');
      FEngine.Log(Format(
        'TOTAL: %d leidas, %d insertadas, %d saltadas, %d errores.',
        [iTotL, iTotI, iTotS, iTotE]));
      TThread.Queue(nil,
        procedure
        begin
          SetEjecutando(False);
        end);
    end)
    .SetParameter('MaxHilos', StrToIntDef(edHilos.Text, 4))
    .CancelWith(FCancel)
    .Unobserved
    .Run;
end;

// =========================================================================
//  Log + persistencia
// =========================================================================

procedure TFormMigrator.AnexarLinea(const sRuta, sTexto: string);
var oFile: TextFile;
begin
  // Anexa una linea a un .log (lo crea si no existe). Tolerante a fallos:
  // si el disco falla no abortamos la migracion (la copia en los memos
  // sigue visible). Sin Exit, para cumplir el libro de estilo.
  if sRuta <> '' then
  try
    AssignFile(oFile, sRuta);
    if FileExists(sRuta) then Append(oFile)
                         else Rewrite(oFile);
    try
      Writeln(oFile, sTexto);
    finally
      CloseFile(oFile);
    end;
  except
    // ignoramos el fallo de disco
  end;
end;

procedure TFormMigrator.Log(const sMsg: string);
var
  sLinea:   string;
  bEsError: Boolean;
begin
  sLinea := FormatDateTime('hh:nn:ss ', Now) + sMsg;
  MemoLog.Lines.Add(sLinea);
  StatusBar.Panels[0].Text := sMsg;
  // El log COMPLETO se persiste a disco linea a linea, para poder seguir
  // la migracion desde fuera (tail) o revisarla despues.
  AnexarLinea(FRutaLogCompleto, sLinea);
  // Detectar lineas de error / aviso por el marcador "!" del engine
  // (LogError emite "  ! ERROR ..." y los mappers viejos hacen
  // "  ! mensaje"). Tambien capturamos "FALLO TOTAL".
  bEsError := (Pos('! ERROR', sMsg) > 0)
           or (Pos('! error', sMsg) > 0)
           or (Pos('FALLO TOTAL', sMsg) > 0)
           or (Pos('  ! ', sMsg) > 0);
  if bEsError then
  begin
    // Volcar al panel de errores y al .log de errores filtrados.
    MemoErrores.Lines.Add(sLinea);
    AnexarLinea(FRutaLogErrores, sLinea);
  end;
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
    edHilos.Text      :=
      IntToStr(oIni.ReadInteger('General', 'MaxHilos', 4));
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
    oIni.WriteInteger('General', 'MaxHilos',
                      StrToIntDef(edHilos.Text, 4));
  finally
    oIni.Free;
  end;
end;

end.
