program PruebaVisualLibroDiario;

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  Vcl.Forms,
  cxCustomData,
  cxFindPanel,
  cxGridCustomTableView,
  cxGridDBTableView,
  inLibConfiguracion in
    '..\src\Lib\inLibConfiguracion.pas',
  inLibRegistroPantallas in
    '..\src\Lib\inLibRegistroPantallas.pas',
  inLibSeguridadIntf in
    '..\src\Lib\inLibSeguridadIntf.pas',
  inLibDir in
    '..\src\Lib\inLibDir.pas',
  inLibLogIntf in
    '..\src\Lib\inLibLogIntf.pas',
  inLibLog in
    '..\src\Lib\inLibLog.pas',
  inLibErroresAplicacion in
    '..\src\Lib\inLibErroresAplicacion.pas',
  inLibContadoresIntf in
    '..\src\Lib\inLibContadoresIntf.pas',
  inLibContabilidadTipos in
    '..\src\Lib\inLibContabilidadTipos.pas',
  inLibValidacionAsientos in
    '..\src\Lib\inLibValidacionAsientos.pas',
  inMtoFrmBase in
    '..\src\Core\inMtoFrmBase.pas',
  inMtoPrincipal in
    '..\src\Core\inMtoPrincipal.pas',
  inMtoLibroDiario in
    '..\src\Forms\inMtoLibroDiario.pas',
  UniDataConexion in
    '..\src\DataModules\UniDataConexion.pas',
  UniDataLibroDiario in
    '..\src\DataModules\UniDataLibroDiario.pas',
  UniDataContadoresRepositorio in
    '..\src\DataModules\UniDataContadoresRepositorio.pas',
  UniDataSeguridad in
    '..\src\DataModules\UniDataSeguridad.pas';

procedure RecorrerDataSets(AFormulario: TComponent);
var
  iComponente: Integer;
  iRegistro: Integer;
  oOrigen: TDataSource;
begin
  for iComponente := 0 to AFormulario.ComponentCount - 1 do
  begin
    if AFormulario.Components[iComponente] is TDataSource then
    begin
      oOrigen := TDataSource(AFormulario.Components[iComponente]);
      if (oOrigen.DataSet <> nil) and oOrigen.DataSet.Active then
      begin
        iRegistro := 0;
        oOrigen.DataSet.First;
        while not oOrigen.DataSet.Eof and (iRegistro < 40) do
        begin
          Application.ProcessMessages;
          oOrigen.DataSet.Next;
          Inc(iRegistro);
        end;
      end;
    end;
  end;
end;

procedure VerificarGridDevExpress(
  AComponente: TComponent;
  var ACantidad: Integer);
var
  iComponente: Integer;
  iColumna: Integer;
  oVista: TcxGridDBTableView;
begin
  if AComponente is TcxGridDBTableView then
  begin
    oVista := TcxGridDBTableView(AComponente);
    Inc(ACantidad);
    if not oVista.FilterRow.Visible then
    begin
      raise Exception.Create(
        'Una vista Developer Express no tiene fila de filtros.');
    end;
    if oVista.FilterBox.Visible <> fvAlways then
    begin
      raise Exception.Create(
        'Una vista Developer Express no muestra el filtro activo.');
    end;
    if not oVista.OptionsCustomize.ColumnFiltering then
    begin
      raise Exception.Create(
        'Una vista Developer Express no permite filtrar columnas.');
    end;
    if oVista.FindPanel.DisplayMode <> fpdmAlways then
    begin
      raise Exception.Create(
        'Una vista Developer Express no conserva la búsqueda visible.');
    end;
    if oVista.FindPanel.Behavior <> fcbFilter then
    begin
      raise Exception.Create(
        'La búsqueda global no está configurada como filtro.');
    end;
    if (oVista.DataController.DataSet <> nil) and
      oVista.DataController.DataSet.Active and
      (oVista.DataController.DataSet.FieldCount > 0) and
      (oVista.ColumnCount = 0) then
    begin
      raise Exception.Create(
        'La vista no ha creado columnas para el dataset activo.');
    end;
    for iColumna := 0 to oVista.ColumnCount - 1 do
    begin
      if oVista.Columns[iColumna].Visible and
        (oVista.Columns[iColumna].Width <= 0) then
      begin
        raise Exception.Create(
          'El BestFit no ha asignado ancho a una columna visible.');
      end;
    end;
  end;
  for iComponente := 0 to AComponente.ComponentCount - 1 do
  begin
    VerificarGridDevExpress(
      AComponente.Components[iComponente],
      ACantidad);
  end;
end;

procedure EjecutarPrueba;
var
  oConfiguracion: TConfiguracionContazam;
  oConexion: TdmConexion;
  oDiario: TfrmBase;
  oPrincipal: TfrmMtoPrincipal;
  oRegistro: TRegistroPantallasContazam;
  oRegistroLog: IRegistroLogContazam;
  oSeguridad: IServicioSeguridadContazam;
  iGridsDevExpress: Integer;
begin
  oConfiguracion := TConfiguracionContazam.Cargar;
  oConexion := TdmConexion.Create(nil, oConfiguracion);
  oRegistro := TRegistroPantallasContazam.Create;
  oRegistroLog := CrearRegistroLogContazam;
  try
    oSeguridad := CrearServicioSeguridad(
      oConexion.Conexion,
      oConfiguracion.UsuarioAplicacion);
    oRegistro.Registrar(
      PantallaLibroDiario,
      TfrmMtoLibroDiario);
    Application.CreateForm(TfrmMtoPrincipal, oPrincipal);
    oDiario := oRegistro.Crear(
      PantallaLibroDiario,
      Application,
      oConexion.Conexion,
      oConfiguracion,
      oSeguridad,
      oRegistroLog);
    try
      oDiario.Show;
      TThread.Sleep(40);
      Application.ProcessMessages;
      RecorrerDataSets(oDiario);
      iGridsDevExpress := 0;
      VerificarGridDevExpress(oDiario, iGridsDevExpress);
      if iGridsDevExpress <> 3 then
      begin
        raise Exception.CreateFmt(
          'Se esperaban 3 grids Developer Express y se encontraron %d.',
          [iGridsDevExpress]);
      end;
      TThread.Sleep(3000);
      Application.ProcessMessages;
      if not oDiario.Visible then
      begin
        raise Exception.Create(
          'El libro diario no ha quedado visible.');
      end;
      Writeln('LIBRO_DIARIO_MDI=OK');
      Writeln('GRIDS_DEVEXPRESS=3');
    finally
      FreeAndNil(oDiario);
    end;
    oSeguridad := nil;
    oRegistroLog := nil;
  finally
    FreeAndNil(oRegistro);
    FreeAndNil(oConexion);
  end;
end;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  try
    EjecutarPrueba;
    ExitCode := 0;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
