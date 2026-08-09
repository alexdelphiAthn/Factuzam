{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPerfilesVentana                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Captura y aplica la presentación personal de mantenimientos.              }
{******************************************************************************}
unit inLibPerfilesVentana;

interface

uses
  Vcl.Forms, cxGridDBTableView, cxPC,
  inLibPerfilesVentanaTipos, UniDataPerfilesVentana;

type
  TGestorPerfilesVentana = class
  private
    FRepositorio: TRepositorioPerfilesVentana;
    function BuscarColumna(
      AVista: TcxGridDBTableView;
      const ACampo: string): TcxGridDBColumn;
    function ClaveGrid(AVista: TcxGridDBTableView): string;
    function ClaveFormulario(AFormulario: TForm): string;
    procedure AplicarColumnas(
      AVista: TcxGridDBTableView;
      const AColumnas: TPerfilesColumnasContazam);
    procedure AplicarVentana(
      AFormulario: TForm;
      APaginas: TcxPageControl;
      const APerfil: TPerfilVentanaContazam);
    function CapturarColumnas(
      AVista: TcxGridDBTableView): TPerfilesColumnasContazam;
    function CapturarVentana(
      AFormulario: TForm;
      APaginas: TcxPageControl): TPerfilVentanaContazam;
  public
    constructor Create(
      ARepositorio: TRepositorioPerfilesVentana);
    destructor Destroy; override;
    procedure Guardar(
      AFormulario: TForm;
      AVista: TcxGridDBTableView;
      APaginas: TcxPageControl);
    function Restaurar(
      AFormulario: TForm;
      AVista: TcxGridDBTableView;
      APaginas: TcxPageControl): Boolean;
    procedure Resetear(
      AFormulario: TForm;
      AVista: TcxGridDBTableView);
  end;

implementation

uses
  System.SysUtils, System.Math, Data.DB, cxGridCustomTableView,
  cxGridTableView,
  inLibGridDevExpress;

constructor TGestorPerfilesVentana.Create(
  ARepositorio: TRepositorioPerfilesVentana);
begin
  inherited Create;
  if ARepositorio = nil then
  begin
    raise EArgumentNilException.Create('ARepositorio');
  end;
  FRepositorio := ARepositorio;
end;

destructor TGestorPerfilesVentana.Destroy;
begin
  FreeAndNil(FRepositorio);
  inherited;
end;

procedure TGestorPerfilesVentana.AplicarColumnas(
  AVista: TcxGridDBTableView;
  const AColumnas: TPerfilesColumnasContazam);
var
  iColumna: Integer;
  iOrden: Integer;
  oColumna: TcxGridDBColumn;
  sGrid: string;
begin
  sGrid := ClaveGrid(AVista);
  AVista.BeginUpdate;
  try
    for iColumna := 0 to Length(AColumnas) - 1 do
    begin
      if SameText(AColumnas[iColumna].Grid, sGrid) then
      begin
        oColumna := BuscarColumna(
          AVista,
          AColumnas[iColumna].Campo);
        if oColumna <> nil then
        begin
          oColumna.Caption := AColumnas[iColumna].Nombre;
          oColumna.Visible := AColumnas[iColumna].EsVisible;
          oColumna.Width := Max(30, AColumnas[iColumna].Ancho);
        end;
      end;
    end;
    iOrden := 0;
    for iColumna := 0 to Length(AColumnas) - 1 do
    begin
      if SameText(AColumnas[iColumna].Grid, sGrid) then
      begin
        oColumna := BuscarColumna(
          AVista,
          AColumnas[iColumna].Campo);
        if oColumna <> nil then
        begin
          oColumna.Index := iOrden;
          Inc(iOrden);
        end;
      end;
    end;
  finally
    AVista.EndUpdate;
  end;
end;

procedure TGestorPerfilesVentana.AplicarVentana(
  AFormulario: TForm;
  APaginas: TcxPageControl;
  const APerfil: TPerfilVentanaContazam);
var
  iPestana: Integer;
begin
  if (APerfil.Ancho >= 600) and (APerfil.Alto >= 400) then
  begin
    AFormulario.SetBounds(
      APerfil.PosicionIzquierda,
      APerfil.PosicionSuperior,
      APerfil.Ancho,
      APerfil.Alto);
  end;
  if SameText(APerfil.Estado, 'MAXIMIZADA') then
  begin
    AFormulario.WindowState := wsMaximized;
  end
  else
  begin
    AFormulario.WindowState := wsNormal;
  end;
  if (APaginas <> nil) and (APerfil.PestanaActiva <> '') then
  begin
    for iPestana := 0 to APaginas.PageCount - 1 do
    begin
      if SameText(
        APaginas.Pages[iPestana].Name,
        APerfil.PestanaActiva) then
      begin
        APaginas.ActivePage := APaginas.Pages[iPestana];
      end;
    end;
  end;
end;

function TGestorPerfilesVentana.BuscarColumna(
  AVista: TcxGridDBTableView;
  const ACampo: string): TcxGridDBColumn;
var
  iColumna: Integer;
  oColumna: TcxGridDBColumn;
begin
  Result := nil;
  for iColumna := 0 to AVista.ColumnCount - 1 do
  begin
    oColumna := AVista.Columns[iColumna];
    if SameText(oColumna.DataBinding.FieldName, ACampo) then
    begin
      Result := oColumna;
    end;
  end;
end;

function TGestorPerfilesVentana.CapturarColumnas(
  AVista: TcxGridDBTableView): TPerfilesColumnasContazam;
var
  iColumna: Integer;
  iOrden: Integer;
  iResultado: Integer;
  oColumna: TcxGridDBColumn;
begin
  SetLength(Result, 0);
  for iColumna := 0 to AVista.ColumnCount - 1 do
  begin
    oColumna := AVista.Columns[iColumna];
    if oColumna.DataBinding.FieldName <> '' then
    begin
      iResultado := Length(Result);
      SetLength(Result, iResultado + 1);
      Result[iResultado].Grid := ClaveGrid(AVista);
      Result[iResultado].Campo := oColumna.DataBinding.FieldName;
      Result[iResultado].Nombre := oColumna.Caption;
      iOrden := oColumna.VisibleIndex;
      if iOrden < 0 then
      begin
        iOrden := AVista.ColumnCount + oColumna.Index;
      end;
      Result[iResultado].Orden := iOrden;
      Result[iResultado].EsVisible := oColumna.Visible;
      Result[iResultado].Ancho := oColumna.Width;
    end;
  end;
end;

function TGestorPerfilesVentana.CapturarVentana(
  AFormulario: TForm;
  APaginas: TcxPageControl): TPerfilVentanaContazam;
begin
  Result := Default(TPerfilVentanaContazam);
  Result.Nombre := AFormulario.Caption;
  Result.PosicionIzquierda := AFormulario.Left;
  Result.PosicionSuperior := AFormulario.Top;
  Result.Ancho := AFormulario.Width;
  Result.Alto := AFormulario.Height;
  if AFormulario.WindowState = wsMaximized then
  begin
    Result.Estado := 'MAXIMIZADA';
  end
  else
  begin
    Result.Estado := 'NORMAL';
  end;
  if (APaginas <> nil) and (APaginas.ActivePage <> nil) then
  begin
    Result.PestanaActiva := APaginas.ActivePage.Name;
  end;
end;

function TGestorPerfilesVentana.ClaveFormulario(
  AFormulario: TForm): string;
begin
  Result := AFormulario.ClassName;
end;

function TGestorPerfilesVentana.ClaveGrid(
  AVista: TcxGridDBTableView): string;
begin
  Result := AVista.Name;
  if Result = '' then
  begin
    Result := AVista.ClassName;
  end;
end;

procedure TGestorPerfilesVentana.Guardar(
  AFormulario: TForm;
  AVista: TcxGridDBTableView;
  APaginas: TcxPageControl);
var
  aColumnas: TPerfilesColumnasContazam;
  oPerfil: TPerfilVentanaContazam;
begin
  oPerfil := CapturarVentana(AFormulario, APaginas);
  aColumnas := CapturarColumnas(AVista);
  FRepositorio.Guardar(
    ClaveFormulario(AFormulario),
    oPerfil,
    aColumnas);
end;

function TGestorPerfilesVentana.Restaurar(
  AFormulario: TForm;
  AVista: TcxGridDBTableView;
  APaginas: TcxPageControl): Boolean;
var
  aColumnas: TPerfilesColumnasContazam;
  oPerfil: TPerfilVentanaContazam;
begin
  Result := FRepositorio.Cargar(
    ClaveFormulario(AFormulario),
    oPerfil,
    aColumnas);
  if Result then
  begin
    AplicarVentana(AFormulario, APaginas, oPerfil);
    AplicarColumnas(AVista, aColumnas);
  end;
end;

procedure TGestorPerfilesVentana.Resetear(
  AFormulario: TForm;
  AVista: TcxGridDBTableView);
var
  iColumna: Integer;
  oColumna: TcxGridDBColumn;
begin
  FRepositorio.Eliminar(ClaveFormulario(AFormulario));
  AFormulario.WindowState := wsNormal;
  AFormulario.Width := 1100;
  AFormulario.Height := 700;
  AVista.BeginUpdate;
  try
    for iColumna := 0 to AVista.ColumnCount - 1 do
    begin
      oColumna := AVista.Columns[iColumna];
      if oColumna.DataBinding.Field <> nil then
      begin
        oColumna.Caption := oColumna.DataBinding.Field.DisplayLabel;
        oColumna.Visible := not (
          oColumna.DataBinding.Field.DataType in
          [ftBlob, ftGraphic, ftOraBlob]);
        if oColumna.Visible then
        begin
          oColumna.Index := iColumna;
        end;
      end;
    end;
  finally
    AVista.EndUpdate;
  end;
  AjustarColumnasContazam(AVista);
end;

end.
