{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGestionFiltros                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.1.1                                                         }
{   Fecha:       11/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lista los filtros guardados disponibles para el usuario actual en un      }
{    mantenimiento (propios y compartidos con él), y permite aplicar,          }
{    editar, reemplazar, copiar, borrar y compartir sus condiciones.           }
{    Compartir con un usuario concreto o con el propio grupo está abierto a    }
{    cualquier propietario; compartir con otro grupo distinto o con Todos      }
{    los usuarios requiere pertenecer al grupo administrador                   }
{    (inLibGlobalVar.orootGroup = 'S').                                        }
{******************************************************************************}
unit inMtoModalGestionFiltros;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls,
  inMtoFrmBase, cxClasses, cxContainer, cxEdit, cxLookAndFeels,
  cxLocalization, cxGraphics, cxControls, cxLookAndFeelPainters, cxLabel,
  cxTextEdit, cxButtons, cxListBox, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  cxGridCustomView, cxFilterControl, Data.DB, Uni, UniDataFiltros;

type
  TGestionFiltrosResult = record
    Aplicado: Boolean;
    IdFiltro: Int64;
    FiltroBase64: string;
  end;

  TfrmModalGestionFiltros = class(TfrmBase)
    cxgrdFiltros: TcxGrid;
    tvFiltros: TcxGridDBTableView;
    lvlFiltros: TcxGridLevel;
    tvFiltrosNOMBRE_FILT: TcxGridDBColumn;
    tvFiltrosDESCRIPCION_FILT: TcxGridDBColumn;
    tvFiltrosUSUARIO_PROPIETARIO_FILT: TcxGridDBColumn;
    lblCompartidoCon: TcxLabel;
    lbCompartidoCon: TcxListBox;
    btnAplicar: TcxButton;
    btnRenombrar: TcxButton;
    btnBorrar: TcxButton;
    btnCompartirUsuario: TcxButton;
    btnCompartirGrupo: TcxButton;
    btnCompartirTodos: TcxButton;
    btnQuitarCompartido: TcxButton;
    btnCerrar: TcxButton;
    lblCondiciones: TcxLabel;
    pnlEditorFiltro: TPanel;
    btnGuardarCambios: TcxButton;
    btnReemplazarActual: TcxButton;
    btnGuardarCopia: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tvFiltrosFocusedRecordChanged(
      Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure tvFiltrosDblClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);
    procedure btnRenombrarClick(Sender: TObject);
    procedure btnBorrarClick(Sender: TObject);
    procedure btnCompartirUsuarioClick(Sender: TObject);
    procedure btnCompartirGrupoClick(Sender: TObject);
    procedure btnCompartirTodosClick(Sender: TObject);
    procedure btnQuitarCompartidoClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure btnGuardarCambiosClick(Sender: TObject);
    procedure btnReemplazarActualClick(Sender: TObject);
    procedure btnGuardarCopiaClick(Sender: TObject);
  private
    FMto: string;
    FVista: string;
    FResultado: TGestionFiltrosResult;
    FDestinos: TDestinosCompartidosList;
    FVistaComponente: TcxCustomGridTableView;
    FFiltroActualBase64: string;
    FControlFiltro: TcxFilterControl;
    function IdFiltroSeleccionado: Int64;
    function GuardarFiltroEditorBase64: string;
    function ResumirFiltro(const ABase64: string): string;
    procedure CrearEditorFiltro;
    procedure CargarFiltroEnControl(AControl: TcxFilterControl;
                                    const ABase64: string);
    procedure CargarFiltroEnEditor(const ABase64: string);
    procedure CargarFiltroSeleccionado;
    procedure RefrescarBotones;
    procedure RefrescarCompartidoCon;
  public
    procedure CargarDatos;
    class function Ejecutar(AOwner: TComponent;
                            const AMto, AVista: string;
                            AVistaComponente: TcxCustomGridTableView;
                            const AFiltroActualBase64: string
                            ): TGestionFiltrosResult;
  end;

implementation

{$R *.dfm}

uses
  System.NetEncoding, inLibGlobalVar, inLibGenBusq,
  inMtoModalGuardarFiltro;

type
  TcxFilterControlAcceso = class(TcxFilterControl)
  public
    function CopiarFiltro(ADestino: TcxFilterCriteria): Boolean;
  end;

procedure ForceReferenceToClass(C: TClass);
begin
end;

function TcxFilterControlAcceso.CopiarFiltro(
  ADestino: TcxFilterCriteria): Boolean;
begin
  ValueEditorHide(True);
  Result := IsValid;
  if Result then
  begin
    BuildFromRows;
    ADestino.AssignItems(Criteria);
  end;
end;

class function TfrmModalGestionFiltros.Ejecutar(AOwner: TComponent;
  const AMto, AVista: string;
  AVistaComponente: TcxCustomGridTableView;
  const AFiltroActualBase64: string): TGestionFiltrosResult;
var
  frm: TfrmModalGestionFiltros;
begin
  frm := TfrmModalGestionFiltros.Create(AOwner);
  try
    frm.FMto := AMto;
    frm.FVista := AVista;
    frm.FVistaComponente := AVistaComponente;
    frm.FFiltroActualBase64 := AFiltroActualBase64;
    frm.CargarDatos;
    frm.ShowModal;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalGestionFiltros.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FResultado.Aplicado := False;
  FResultado.IdFiltro := 0;
  FResultado.FiltroBase64 := '';
  FDestinos := nil;
  FVistaComponente := nil;
  FFiltroActualBase64 := '';
  CrearEditorFiltro;
end;

procedure TfrmModalGestionFiltros.FormDestroy(Sender: TObject);
begin
  inherited;
  if Assigned(FDestinos) then
  begin
    FreeAndNil(FDestinos);
  end;
  FreeAndNil(FControlFiltro);
end;

procedure TfrmModalGestionFiltros.CrearEditorFiltro;
begin
  FControlFiltro := TcxFilterControl.Create(Self);
  FControlFiltro.Parent := pnlEditorFiltro;
  FControlFiltro.Align := alClient;
  FControlFiltro.ParentFont := True;
  FControlFiltro.Enabled := False;
end;

procedure TfrmModalGestionFiltros.CargarDatos;
begin
  if Assigned(odmFiltros) then
  begin
    FControlFiltro.LinkComponent := FVistaComponente;
    odmFiltros.AbrirListadoParaGrid(FMto, FVista);
    tvFiltros.DataController.DataSource := odmFiltros.dsListado;
  end;
  CargarFiltroSeleccionado;
  RefrescarCompartidoCon;
end;

function TfrmModalGestionFiltros.IdFiltroSeleccionado: Int64;
begin
  Result := 0;
  if Assigned(odmFiltros) and
     odmFiltros.unqryListado.Active and
     (not odmFiltros.unqryListado.IsEmpty) then
  begin
    Result := odmFiltros.unqryListado.FieldByName('ID_FILT').AsLargeInt;
  end;
end;

procedure TfrmModalGestionFiltros.CargarFiltroEnControl(
  AControl: TcxFilterControl; const ABase64: string);
var
  oStreamBin: TMemoryStream;
  oStreamB64: TStringStream;
  oStreamOriginal: TMemoryStream;
begin
  if ABase64 = '' then
  begin
    AControl.Clear;
  end
  else
  begin
    oStreamB64 := TStringStream.Create(ABase64);
    oStreamBin := TMemoryStream.Create;
    oStreamOriginal := TMemoryStream.Create;
    try
      FVistaComponente.DataController.Filter.SaveToStream(
                                                    oStreamOriginal);
      oStreamB64.Position := 0;
      TNetEncoding.Base64.Decode(oStreamB64, oStreamBin);
      oStreamBin.Position := 0;
      FVistaComponente.BeginUpdate;
      try
        try
          FVistaComponente.DataController.Filter.LoadFromStream(
                                                        oStreamBin);
          AControl.UpdateFilter;
        finally
          oStreamOriginal.Position := 0;
          FVistaComponente.DataController.Filter.LoadFromStream(
                                                   oStreamOriginal);
        end;
      finally
        FVistaComponente.EndUpdate;
      end;
    finally
      FreeAndNil(oStreamOriginal);
      FreeAndNil(oStreamBin);
      FreeAndNil(oStreamB64);
    end;
  end;
end;

procedure TfrmModalGestionFiltros.CargarFiltroEnEditor(
  const ABase64: string);
begin
  CargarFiltroEnControl(FControlFiltro, ABase64);
end;

procedure TfrmModalGestionFiltros.CargarFiltroSeleccionado;
var
  sFiltroBase64: string;
begin
  sFiltroBase64 := '';
  if IdFiltroSeleccionado > 0 then
  begin
    sFiltroBase64 :=
      odmFiltros.CargarFiltroBase64(IdFiltroSeleccionado);
  end;
  CargarFiltroEnEditor(sFiltroBase64);
end;

function TfrmModalGestionFiltros.GuardarFiltroEditorBase64: string;
var
  oStreamBin: TMemoryStream;
  oStreamB64: TStringStream;
  oStreamOriginal: TMemoryStream;
begin
  Result := '';
  oStreamBin := TMemoryStream.Create;
  oStreamB64 := TStringStream.Create('');
  oStreamOriginal := TMemoryStream.Create;
  try
    FVistaComponente.DataController.Filter.SaveToStream(oStreamOriginal);
    FVistaComponente.BeginUpdate;
    try
      try
        if TcxFilterControlAcceso(FControlFiltro).CopiarFiltro(
                    FVistaComponente.DataController.Filter) then
        begin
          FVistaComponente.DataController.Filter.Active :=
            not FVistaComponente.DataController.Filter.IsEmpty;
          FVistaComponente.DataController.Filter.SaveToStream(oStreamBin);
        end;
      finally
        oStreamOriginal.Position := 0;
        FVistaComponente.DataController.Filter.LoadFromStream(
                                                 oStreamOriginal);
      end;
    finally
      FVistaComponente.EndUpdate;
    end;
    if oStreamBin.Size > 0 then
    begin
      oStreamBin.Position := 0;
      TNetEncoding.Base64.Encode(oStreamBin, oStreamB64);
      Result := oStreamB64.DataString;
    end;
  finally
    FreeAndNil(oStreamOriginal);
    FreeAndNil(oStreamB64);
    FreeAndNil(oStreamBin);
  end;
end;

function TfrmModalGestionFiltros.ResumirFiltro(
  const ABase64: string): string;
const
  MAX_CARACTERES_RESUMEN = 600;
var
  oControl: TcxFilterControl;
begin
  Result := '(sin condiciones)';
  if ABase64 <> '' then
  begin
    oControl := TcxFilterControl.Create(nil);
    try
      oControl.LinkComponent := FVistaComponente;
      CargarFiltroEnControl(oControl, ABase64);
      Result := Trim(oControl.FilterCaption);
      if Result = '' then
      begin
        Result := '(sin condiciones)';
      end
      else if Length(Result) > MAX_CARACTERES_RESUMEN then
      begin
        Result := Copy(Result, 1, MAX_CARACTERES_RESUMEN) + '...';
      end;
    finally
      FreeAndNil(oControl);
    end;
  end;
end;

procedure TfrmModalGestionFiltros.RefrescarBotones;
var
  bHayFiltro: Boolean;
  bEsPropio: Boolean;
begin
  bHayFiltro := Assigned(odmFiltros) and
                odmFiltros.unqryListado.Active and
                (not odmFiltros.unqryListado.IsEmpty);
  bEsPropio := False;
  if bHayFiltro then
  begin
    bEsPropio :=
      odmFiltros.unqryListado.FieldByName('ESPROPIO_FILT').AsString = 'S';
  end;
  btnAplicar.Enabled := bHayFiltro;
  btnGuardarCambios.Enabled := bHayFiltro and bEsPropio;
  btnReemplazarActual.Enabled := bHayFiltro and bEsPropio and
                                 (FFiltroActualBase64 <> '');
  btnGuardarCopia.Enabled := bHayFiltro;
  btnRenombrar.Enabled := bHayFiltro and bEsPropio;
  btnBorrar.Enabled := bHayFiltro and bEsPropio;
  btnCompartirUsuario.Enabled := bHayFiltro and bEsPropio;
  btnCompartirGrupo.Enabled := bHayFiltro and bEsPropio;
  btnCompartirTodos.Enabled := bHayFiltro and bEsPropio and
                               (inLibGlobalVar.orootGroup = 'S');
  btnQuitarCompartido.Enabled := bHayFiltro and bEsPropio and
                                 (lbCompartidoCon.ItemIndex >= 0);
  FControlFiltro.Enabled := bHayFiltro;
  if bHayFiltro and (not bEsPropio) then
  begin
    lblCondiciones.Caption :=
      'Condiciones del filtro compartido. Puede editarlas y guardar ' +
      'una copia propia:';
  end
  else
  begin
    lblCondiciones.Caption :=
      'Condiciones del filtro seleccionado (puede editarlas):';
  end;
end;

procedure TfrmModalGestionFiltros.RefrescarCompartidoCon;
var
  info: TDestinoCompartidoInfo;
  sLinea: string;
begin
  if Assigned(FDestinos) then
  begin
    FreeAndNil(FDestinos);
  end;
  lbCompartidoCon.Items.Clear;
  if IdFiltroSeleccionado > 0 then
  begin
    FDestinos := odmFiltros.ListarDestinosCompartidos(IdFiltroSeleccionado);
    for info in FDestinos do
    begin
      if info.TipoDestino = 'TODOS' then
      begin
        sLinea := 'Todos los usuarios';
      end
      else if info.TipoDestino = 'GRUPO' then
      begin
        sLinea := 'Grupo: ' + info.UsuarioGrupo;
      end
      else
      begin
        sLinea := 'Usuario: ' + info.UsuarioGrupo;
      end;
      lbCompartidoCon.Items.Add(sLinea);
    end;
  end;
  RefrescarBotones;
end;

procedure TfrmModalGestionFiltros.tvFiltrosFocusedRecordChanged(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  CargarFiltroSeleccionado;
  RefrescarCompartidoCon;
end;

procedure TfrmModalGestionFiltros.tvFiltrosDblClick(Sender: TObject);
begin
  btnAplicarClick(Sender);
end;

procedure TfrmModalGestionFiltros.btnAplicarClick(Sender: TObject);
var
  sFiltroBase64: string;
begin
  inherited;
  if IdFiltroSeleccionado = 0 then
  begin
    ShowMessage('Seleccione un filtro de la lista.');
  end
  else
  begin
    sFiltroBase64 := GuardarFiltroEditorBase64;
    if (sFiltroBase64 = '') or
       (Trim(FControlFiltro.FilterCaption) = '') then
    begin
      ShowMessage('El filtro no tiene condiciones para aplicar.');
    end
    else
    begin
      FResultado.Aplicado := True;
      FResultado.IdFiltro := IdFiltroSeleccionado;
      FResultado.FiltroBase64 := sFiltroBase64;
      Close;
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnGuardarCambiosClick(Sender: TObject);
var
  sFiltroBase64: string;
  sNombre: string;
  sDescripcion: string;
begin
  inherited;
  sFiltroBase64 := GuardarFiltroEditorBase64;
  if (sFiltroBase64 = '') or
     (Trim(FControlFiltro.FilterCaption) = '') then
  begin
    ShowMessage('El filtro no tiene condiciones para guardar.');
  end
  else
  begin
    sNombre := odmFiltros.unqryListado.FieldByName(
                                             'NOMBRE_FILT').AsString;
    sDescripcion := odmFiltros.unqryListado.FieldByName(
                                        'DESCRIPCION_FILT').AsString;
    odmFiltros.SobrescribirFiltro(IdFiltroSeleccionado, sNombre,
                                  sDescripcion, sFiltroBase64);
    CargarFiltroEnEditor(sFiltroBase64);
    ShowMessage('Cambios del filtro guardados correctamente.');
  end;
end;

procedure TfrmModalGestionFiltros.btnReemplazarActualClick(
  Sender: TObject);
var
  sFiltroGuardado: string;
  sMensaje: string;
  sNombre: string;
  sDescripcion: string;
begin
  inherited;
  if FFiltroActualBase64 = '' then
  begin
    ShowMessage('La pantalla no tiene ningún filtro aplicado.');
  end
  else
  begin
    sFiltroGuardado :=
      odmFiltros.CargarFiltroBase64(IdFiltroSeleccionado);
    sMensaje :=
      'Filtro guardado actualmente:' + sLineBreak +
      ResumirFiltro(sFiltroGuardado) + sLineBreak + sLineBreak +
      'Se reemplazará por el filtro actual de la pantalla:' +
      sLineBreak + ResumirFiltro(FFiltroActualBase64) +
      sLineBreak + sLineBreak + '¿Desea continuar?';
    if Application.MessageBox(PChar(sMensaje), 'Reemplazar filtro',
       MB_YESNO + MB_ICONQUESTION) = ID_YES then
    begin
      sNombre := odmFiltros.unqryListado.FieldByName(
                                               'NOMBRE_FILT').AsString;
      sDescripcion := odmFiltros.unqryListado.FieldByName(
                                          'DESCRIPCION_FILT').AsString;
      odmFiltros.SobrescribirFiltro(IdFiltroSeleccionado, sNombre,
                                    sDescripcion,
                                    FFiltroActualBase64);
      CargarFiltroEnEditor(FFiltroActualBase64);
      ShowMessage('Filtro reemplazado correctamente.');
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnGuardarCopiaClick(Sender: TObject);
var
  res: TGuardarFiltroResult;
  sFiltroBase64: string;
  sNombreInicial: string;
  sDescripcionInicial: string;
  iIdFiltro: Int64;
begin
  inherited;
  sFiltroBase64 := GuardarFiltroEditorBase64;
  if (sFiltroBase64 = '') or
     (Trim(FControlFiltro.FilterCaption) = '') then
  begin
    ShowMessage('El filtro no tiene condiciones para guardar.');
  end
  else
  begin
    sNombreInicial := odmFiltros.unqryListado.FieldByName(
                                      'NOMBRE_FILT').AsString + ' - copia';
    sDescripcionInicial := odmFiltros.unqryListado.FieldByName(
                                        'DESCRIPCION_FILT').AsString;
    res := TfrmModalGuardarFiltro.Ejecutar(Self, sNombreInicial,
                                           sDescripcionInicial);
    if res.Aceptado then
    begin
      iIdFiltro := odmFiltros.BuscarFiltroPropio(FMto, FVista,
                                                  res.Nombre);
      if iIdFiltro > 0 then
      begin
        ShowMessage('Ya existe un filtro propio con ese nombre. ' +
                    'Indique un nombre diferente.');
      end
      else
      begin
        odmFiltros.GuardarFiltroNuevo(FMto, FVista, res.Nombre,
                                      res.Descripcion, sFiltroBase64);
        CargarDatos;
        ShowMessage('Copia del filtro guardada correctamente.');
      end;
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnRenombrarClick(Sender: TObject);
var
  res: TGuardarFiltroResult;
begin
  inherited;
  if IdFiltroSeleccionado = 0 then
  begin
    ShowMessage('Seleccione un filtro de la lista.');
  end
  else
  begin
    res := TfrmModalGuardarFiltro.Ejecutar(Self,
      odmFiltros.unqryListado.FieldByName('NOMBRE_FILT').AsString,
      odmFiltros.unqryListado.FieldByName('DESCRIPCION_FILT').AsString);
    if res.Aceptado then
    begin
      odmFiltros.RenombrarFiltro(IdFiltroSeleccionado, res.Nombre,
                                 res.Descripcion);
      CargarDatos;
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnBorrarClick(Sender: TObject);
begin
  inherited;
  if IdFiltroSeleccionado = 0 then
  begin
    ShowMessage('Seleccione un filtro de la lista.');
  end
  else
  begin
    if Application.MessageBox('¿Borrar el filtro seleccionado?',
                              'Confirmar borrado',
                              MB_YESNO + MB_ICONQUESTION) = ID_YES then
    begin
      odmFiltros.BorrarFiltro(IdFiltroSeleccionado);
      CargarDatos;
    end;
  end;
end;

procedure TfrmModalGestionFiltros.btnCompartirUsuarioClick(Sender: TObject);
var
  q: TUniQuery;
  sUsuario: string;
begin
  inherited;
  q := TUniQuery.Create(nil);
  try
    q.Connection := oConn;
    q.SQL.Text :=
      'SELECT USUARIO_USU AS USUARIO ' +
      '  FROM fza_usuarios ' +
      ' WHERE COALESCE(ESACTIVO_USU, ''S'') = ''S'' ' +
      '   AND USUARIO_USU <> :USUARIOACTUAL ' +
      'ORDER BY USUARIO_USU';
    q.ParamByName('USUARIOACTUAL').AsString := oUser;
    if TBusquedaUtils.EjecutarBusqueda('Compartir filtro con usuario', q,
                                       'frmBuscarUsuarioFiltro', Self) then
    begin
      sUsuario := q.FieldByName('USUARIO').AsString;
      odmFiltros.CompartirConDestino(IdFiltroSeleccionado, 'USUARIO',
                                     sUsuario);
      RefrescarCompartidoCon;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TfrmModalGestionFiltros.btnCompartirGrupoClick(Sender: TObject);
var
  q: TUniQuery;
  sGrupo: string;
begin
  inherited;
  if inLibGlobalVar.orootGroup = 'S' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := oConn;
      q.SQL.Text :=
        'SELECT GRUPO_USUGRP AS GRUPO ' +
        '  FROM fza_usuarios_grupos ' +
        'ORDER BY GRUPO_USUGRP';
      if TBusquedaUtils.EjecutarBusqueda('Compartir filtro con grupo', q,
                                         'frmBuscarGrupoFiltro', Self) then
      begin
        sGrupo := q.FieldByName('GRUPO').AsString;
        odmFiltros.CompartirConDestino(IdFiltroSeleccionado, 'GRUPO',
                                       sGrupo);
        RefrescarCompartidoCon;
      end;
    finally
      FreeAndNil(q);
    end;
  end
  else
  begin
    odmFiltros.CompartirConDestino(IdFiltroSeleccionado, 'GRUPO', oGroup);
    RefrescarCompartidoCon;
    ShowMessage('Filtro compartido con tu grupo (' + oGroup + ').');
  end;
end;

procedure TfrmModalGestionFiltros.btnCompartirTodosClick(Sender: TObject);
begin
  inherited;
  odmFiltros.CompartirConDestino(IdFiltroSeleccionado, 'TODOS', '');
  RefrescarCompartidoCon;
  ShowMessage('Filtro compartido con todos los usuarios.');
end;

procedure TfrmModalGestionFiltros.btnQuitarCompartidoClick(Sender: TObject);
begin
  inherited;
  if (lbCompartidoCon.ItemIndex >= 0) and Assigned(FDestinos) then
  begin
    odmFiltros.QuitarDestinoCompartido(
      FDestinos[lbCompartidoCon.ItemIndex].Id);
    RefrescarCompartidoCon;
  end;
end;

procedure TfrmModalGestionFiltros.btnCerrarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aplicado := False;
  FResultado.FiltroBase64 := '';
  Close;
end;

initialization
  ForceReferenceToClass(TfrmModalGestionFiltros);
end.
