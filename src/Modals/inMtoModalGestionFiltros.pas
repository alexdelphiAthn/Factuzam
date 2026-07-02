{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGestionFiltros                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lista los filtros guardados disponibles para el usuario actual en un      }
{    mantenimiento (propios y compartidos con el), y permite aplicar,          }
{    renombrar, borrar y compartir/descompartir con usuarios o grupos.         }
{    Compartir con un usuario concreto o con el propio grupo esta abierto a    }
{    cualquier propietario; compartir con otro grupo distinto o con Todos      }
{    los usuarios requiere pertenecer al grupo administrador                   }
{    (inLibGlobalVar.orootGroup = 'S').                                        }
{******************************************************************************}
unit inMtoModalGestionFiltros;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoFrmBase, cxClasses, cxContainer, cxEdit, cxLookAndFeels,
  cxLocalization, cxGraphics, cxControls, cxLookAndFeelPainters, cxLabel,
  cxTextEdit, cxButtons, cxListBox, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  cxGridCustomView, Data.DB, Uni, UniDataFiltros;

type
  TGestionFiltrosResult = record
    Aplicado: Boolean;
    IdFiltro: Int64;
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
  private
    FMto: string;
    FVista: string;
    FResultado: TGestionFiltrosResult;
    FDestinos: TDestinosCompartidosList;
    function IdFiltroSeleccionado: Int64;
    procedure RefrescarBotones;
    procedure RefrescarCompartidoCon;
  public
    procedure CargarDatos;
    class function Ejecutar(AOwner: TComponent;
                            const AMto, AVista: string
                            ): TGestionFiltrosResult;
  end;

implementation

{$R *.dfm}

uses
  inLibGlobalVar, inLibGenBusq, inMtoModalGuardarFiltro;

procedure ForceReferenceToClass(C: TClass);
begin
end;

class function TfrmModalGestionFiltros.Ejecutar(AOwner: TComponent;
  const AMto, AVista: string): TGestionFiltrosResult;
var
  frm: TfrmModalGestionFiltros;
begin
  frm := TfrmModalGestionFiltros.Create(AOwner);
  try
    frm.FMto := AMto;
    frm.FVista := AVista;
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
  FDestinos := nil;
end;

procedure TfrmModalGestionFiltros.FormDestroy(Sender: TObject);
begin
  inherited;
  if Assigned(FDestinos) then
  begin
    FreeAndNil(FDestinos);
  end;
end;

procedure TfrmModalGestionFiltros.CargarDatos;
begin
  if Assigned(odmFiltros) then
  begin
    odmFiltros.AbrirListadoParaGrid(FMto, FVista);
    tvFiltros.DataController.DataSource := odmFiltros.dsListado;
  end;
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
  btnRenombrar.Enabled := bHayFiltro and bEsPropio;
  btnBorrar.Enabled := bHayFiltro and bEsPropio;
  btnCompartirUsuario.Enabled := bHayFiltro and bEsPropio;
  btnCompartirGrupo.Enabled := bHayFiltro and bEsPropio;
  btnCompartirTodos.Enabled := bHayFiltro and bEsPropio and
                               (inLibGlobalVar.orootGroup = 'S');
  btnQuitarCompartido.Enabled := bHayFiltro and bEsPropio and
                                 (lbCompartidoCon.ItemIndex >= 0);
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
  RefrescarCompartidoCon;
end;

procedure TfrmModalGestionFiltros.tvFiltrosDblClick(Sender: TObject);
begin
  btnAplicarClick(Sender);
end;

procedure TfrmModalGestionFiltros.btnAplicarClick(Sender: TObject);
begin
  inherited;
  if IdFiltroSeleccionado = 0 then
  begin
    ShowMessage('Seleccione un filtro de la lista.');
  end
  else
  begin
    FResultado.Aplicado := True;
    FResultado.IdFiltro := IdFiltroSeleccionado;
    Close;
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
  Close;
end;

initialization
  ForceReferenceToClass(TfrmModalGestionFiltros);
end.
