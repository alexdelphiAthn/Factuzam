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
  System.Classes, System.IniFiles, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst, Vcl.ComCtrls, Vcl.Mask,
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
    PanelCentro:       TPanel;
    lblUsuario:        TLabel;
    edUsuario:         TEdit;
    GroupListado:      TGroupBox;
    listMigs:          TCheckListBox;
    btnMarcarTodas:    TButton;
    btnDesmarcarTodas: TButton;
    btnEjecutar:       TButton;
    PanelLog:          TPanel;
    lblLog:            TLabel;
    MemoLog:           TMemo;
    StatusBar:         TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnProbarSrcClick(Sender: TObject);
    procedure btnProbarDstClick(Sender: TObject);
    procedure btnEjecutarClick(Sender: TObject);
    procedure btnMarcarTodasClick(Sender: TObject);
    procedure btnDesmarcarTodasClick(Sender: TObject);
  private
    FEngine: TMigEngine;
    procedure Log(const sMsg: string);
    procedure RegistrarMigraciones;
    procedure RecargarListado;
    procedure CargarConfig;
    procedure GuardarConfig;
    function  RutaIni: string;
  public
  end;

var
  FormMigrator: TFormMigrator;

implementation

{$R *.dfm}

uses
  UMigConn,
  inLibMigFormasPago,
  inLibMigIvasGrupos,
  inLibMigIvas,
  inLibMigEmpresas,
  inLibMigAlmacenes,
  inLibMigClientes,
  inLibMigFamilias,
  inLibMigAtributos,
  inLibMigArticulos,
  inLibMigArticulosAtributos;

// =========================================================================
//  Lifecycle
// =========================================================================

procedure TFormMigrator.FormCreate(Sender: TObject);
begin
  Caption  := 'Factuzam Migrator SQL Server';
  Position := poScreenCenter;

  FEngine       := TMigEngine.Create(dmMig.conSrv, dmMig.conDst);
  FEngine.OnLog := procedure(const s: string)
                   begin
                     Log(s);
                   end;
  RegistrarMigraciones;
  RecargarListado;
  CargarConfig;
  Log('Migrator listo. Configure las conexiones y pruebe conectividad.');
end;

procedure TFormMigrator.FormDestroy(Sender: TObject);
begin
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

procedure TFormMigrator.btnProbarSrcClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    dmMig.ConfigurarOrigen(edSrcHost.Text, edSrcPort.Text, edSrcBase.Text,
                           edSrcUser.Text, edSrcPwd.Text);
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

procedure TFormMigrator.btnEjecutarClick(Sender: TObject);
var
  i: Integer;
  Stats, TotalStats: TMigStats;
  iSeleccionadas: Integer;
begin
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

  // Asegurarse de que las conexiones estan configuradas (por si no se
  // pulsaron los botones de probar)
  dmMig.ConfigurarOrigen(edSrcHost.Text, edSrcPort.Text, edSrcBase.Text,
                         edSrcUser.Text, edSrcPwd.Text);
  dmMig.ConfigurarDestino(edDstHost.Text, edDstPort.Text, edDstBase.Text,
                          edDstUser.Text, edDstPwd.Text);
  FEngine.Usuario := edUsuario.Text;
  if FEngine.Usuario = '' then
    FEngine.Usuario := 'MIGRADOR';

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

  Screen.Cursor := crHourGlass;
  TotalStats := Default(TMigStats);
  try
    for i := 0 to listMigs.Items.Count - 1 do
    begin
      if not listMigs.Checked[i] then Continue;
      Application.ProcessMessages;
      Stats := Default(TMigStats);
      try
        FEngine.Ejecutar(FEngine.Items[i].Codigo, Stats);
        Inc(TotalStats.Leidas,     Stats.Leidas);
        Inc(TotalStats.Insertadas, Stats.Insertadas);
        Inc(TotalStats.Saltadas,   Stats.Saltadas);
      except
        on E: Exception do
        begin
          Inc(TotalStats.Errores, 1);
          Log('FALLO TOTAL en ' + FEngine.Items[i].Codigo + ': ' + E.Message);
          if MessageDlg('Fallo en migración "' + FEngine.Items[i].Nombre +
                        '". ¿Continuar con las siguientes?',
                        mtError, [mbYes, mbNo], 0) <> mrYes then
            Break;
        end;
      end;
    end;

    Log('');
    Log(Format('TOTAL: %d leidas, %d insertadas, %d saltadas, %d errores.',
        [TotalStats.Leidas, TotalStats.Insertadas, TotalStats.Saltadas,
         TotalStats.Errores]));
  finally
    Screen.Cursor := crDefault;
  end;
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
    edSrcHost.Text := oIni.ReadString('Origen',  'Host',   '');
    edSrcPort.Text := oIni.ReadString('Origen',  'Port',   '1433');
    edSrcBase.Text := oIni.ReadString('Origen',  'Base',   '');
    edSrcUser.Text := oIni.ReadString('Origen',  'User',   'sa');
    edDstHost.Text := oIni.ReadString('Destino', 'Host',   '127.0.0.1');
    edDstPort.Text := oIni.ReadString('Destino', 'Port',   '3306');
    edDstBase.Text := oIni.ReadString('Destino', 'Base',   'factuzam');
    edDstUser.Text := oIni.ReadString('Destino', 'User',   'root');
    edUsuario.Text := oIni.ReadString('General', 'Usuario', 'MIGRADOR');
  finally
    oIni.Free;
  end;
end;

procedure TFormMigrator.GuardarConfig;
var oIni: TIniFile;
begin
  oIni := TIniFile.Create(RutaIni);
  try
    oIni.WriteString('Origen',  'Host', edSrcHost.Text);
    oIni.WriteString('Origen',  'Port', edSrcPort.Text);
    oIni.WriteString('Origen',  'Base', edSrcBase.Text);
    oIni.WriteString('Origen',  'User', edSrcUser.Text);
    oIni.WriteString('Destino', 'Host', edDstHost.Text);
    oIni.WriteString('Destino', 'Port', edDstPort.Text);
    oIni.WriteString('Destino', 'Base', edDstBase.Text);
    oIni.WriteString('Destino', 'User', edDstUser.Text);
    oIni.WriteString('General', 'Usuario', edUsuario.Text);
  finally
    oIni.Free;
  end;
end;

end.
