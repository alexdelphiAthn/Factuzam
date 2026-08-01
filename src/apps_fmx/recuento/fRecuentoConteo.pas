{******************************************************************************}
{                                                                              }
{  Módulo:       fRecuentoConteo                                               }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla de conteo. Cada escaneo (Intro en el campo) genera un evento     }
{    con su día/hora y se encola en SQLite local. Botones para sincronizar     }
{    (subir la cola) y finalizar el recuento. UI por código (sin .fmx).        }
{******************************************************************************}
unit fRecuentoConteo;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.Edit, FMX.ListBox, FMX.Layouts,
  FMX.Types, FMX.DialogService,
  RecuentoModelo, RecuentoLocal, RecuentoApi, RecuentoSync;

type
  TfrmConteo = class(TForm)
  private
    FModo      : TModoRecuento;
    FIdRecuento: Int64;
    FCatalogo  : TArrCatalogo;
    FScan      : TEdit;
    FCantidad  : TEdit;
    FLista     : TListBox;
    FlblEstado : TLabel;
    function NuevoUuid: string;
    function BuscarEnCatalogo(const ACodigo: string): Integer;
    procedure Construir(const ATitulo: string);
    procedure Procesar(const ACodigo: string);
    procedure AnadirLinea(const ATexto: string);
    procedure ActualizarEstado;
    procedure OnScanKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
                            Shift: TShiftState);
    procedure OnSincronizarClick(Sender: TObject);
    procedure OnFinalizarClick(Sender: TObject);
    procedure OnVolverClick(Sender: TObject);
  public
    class procedure IniciarAsync(AOwner: TComponent; AModo: TModoRecuento;
      AIdRecuento: Int64; const ACatalogo: TArrCatalogo; const ATitulo: string);
  end;

implementation

function TfrmConteo.NuevoUuid: string;
var
  g: TGUID;
begin
  CreateGUID(g);
  // GUIDToString devuelve '{....}': nos quedamos con los 36 chars de dentro.
  Result := LowerCase(Copy(GUIDToString(g), 2, 36));
end;

function TfrmConteo.BuscarEnCatalogo(const ACodigo: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  i := 0;
  while (Result < 0) and (i <= High(FCatalogo)) do
  begin
    if SameText(FCatalogo[i].CodigoBarras, ACodigo) or
       SameText(FCatalogo[i].CodigoUnidad, ACodigo) or
       SameText(FCatalogo[i].CodigoArticulo, ACodigo) then
      Result := i;
    Inc(i);
  end;
end;

procedure TfrmConteo.Construir(const ATitulo: string);
var
  lblTitulo: TLabel;
  layBotones: TLayout;
  btnVolver, btnSync, btnFin: TButton;
begin
  Self.Caption := ATitulo;
  FCantidad := nil;
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Self;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 32;
  lblTitulo.Text := ATitulo;
  if FModo = mrCodigosCantidad then
  begin
    FCantidad := TEdit.Create(Self);
    FCantidad.Parent := Self;
    FCantidad.Align := TAlignLayout.Top;
    FCantidad.Height := 40;
    FCantidad.TextPrompt := 'Cantidad por escaneo';
    FCantidad.Text := '1';
  end;
  FScan := TEdit.Create(Self);
  FScan.Parent := Self;
  FScan.Align := TAlignLayout.Top;
  FScan.Height := 44;
  FScan.TextPrompt := 'Escanea o teclea el código y pulsa Intro';
  FScan.OnKeyDown := OnScanKeyDown;
  FlblEstado := TLabel.Create(Self);
  FlblEstado.Parent := Self;
  FlblEstado.Align := TAlignLayout.Top;
  FlblEstado.Height := 24;
  layBotones := TLayout.Create(Self);
  layBotones.Parent := Self;
  layBotones.Align := TAlignLayout.Bottom;
  layBotones.Height := 56;
  btnVolver := TButton.Create(Self);
  btnVolver.Parent := layBotones;
  btnVolver.Align := TAlignLayout.Left;
  btnVolver.Width := 100;
  btnVolver.Text := 'Volver';
  btnVolver.OnClick := OnVolverClick;
  btnSync := TButton.Create(Self);
  btnSync.Parent := layBotones;
  btnSync.Align := TAlignLayout.Left;
  btnSync.Width := 130;
  btnSync.Text := 'Sincronizar';
  btnSync.OnClick := OnSincronizarClick;
  btnFin := TButton.Create(Self);
  btnFin.Parent := layBotones;
  btnFin.Align := TAlignLayout.Right;
  btnFin.Width := 130;
  btnFin.Text := 'Finalizar';
  btnFin.OnClick := OnFinalizarClick;
  FLista := TListBox.Create(Self);
  FLista.Parent := Self;
  FLista.Align := TAlignLayout.Client;
  ActualizarEstado;
end;

procedure TfrmConteo.Procesar(const ACodigo: string);
var
  sCodigo, sSku, sArt, sDesc: string;
  iIdx: Integer;
  dCant, dTotal: Double;
  Ev: TEventoRec;
begin
  sCodigo := Trim(ACodigo);
  if sCodigo <> '' then
  begin
    iIdx := BuscarEnCatalogo(sCodigo);
    sSku := sCodigo;
    sArt := '';
    sDesc := '(no identificado)';
    if iIdx >= 0 then
    begin
      sSku := FCatalogo[iIdx].CodigoUnidad;
      sArt := FCatalogo[iIdx].CodigoArticulo;
      sDesc := FCatalogo[iIdx].Descripcion;
    end;
    dCant := 1;
    if (FModo = mrCodigosCantidad) and Assigned(FCantidad) then
      dCant := StrToFloatDef(FCantidad.Text.Replace(',', '.'), 1);
    Ev := Default(TEventoRec);
    Ev.Uuid := NuevoUuid;
    Ev.CodigoBarras := sCodigo;
    Ev.CodigoUnidad := sSku;
    Ev.CodigoArticulo := sArt;
    Ev.Cantidad := dCant;
    Ev.InstanteRecuento := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
    // TODO: si iIdx>=0 y FCatalogo[iIdx].EsTrazable, pedir lote/caducidad.
    oLocal.Encolar(FIdRecuento, Ev);
    dTotal := oLocal.ContarPorSku(FIdRecuento, sSku);
    AnadirLinea(Format('%s   +%g   (total %g)   %s',
                       [sSku, dCant, dTotal, sDesc]));
    FScan.Text := '';
    FScan.SetFocus;
    ActualizarEstado;
  end;
end;

procedure TfrmConteo.AnadirLinea(const ATexto: string);
var
  oItem: TListBoxItem;
begin
  oItem := TListBoxItem.Create(FLista);
  oItem.Parent := FLista;
  oItem.Text := ATexto;
  oItem.Index := 0;
end;

procedure TfrmConteo.ActualizarEstado;
begin
  FlblEstado.Text := Format('Pendientes de subir: %d',
                            [oLocal.ContarPendientes(FIdRecuento)]);
end;

procedure TfrmConteo.OnScanKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    Key := 0;
    Procesar(FScan.Text);
  end;
end;

procedure TfrmConteo.OnSincronizarClick(Sender: TObject);
var
  oSync: TRecuentoSync;
  iSubidos: Integer;
  sMsg: string;
begin
  // TODO: mover a un hilo (TTask) para no bloquear la UI con la red.
  oSync := TRecuentoSync.Create;
  try
    if oSync.Sincronizar(FIdRecuento, iSubidos, sMsg) then
      TDialogService.ShowMessage(Format('Subidos %d eventos', [iSubidos]))
    else
      TDialogService.ShowMessage('Error al sincronizar: ' + sMsg);
  finally
    FreeAndNil(oSync);
  end;
  ActualizarEstado;
end;

procedure TfrmConteo.OnFinalizarClick(Sender: TObject);
var
  oSync: TRecuentoSync;
  oApi: TRecuentoApi;
  iSubidos: Integer;
  sMsg: string;
begin
  // Subir lo pendiente y, si va bien, marcar el recuento como RECONTADO.
  oSync := TRecuentoSync.Create;
  oApi := TRecuentoApi.Create;
  try
    if not oSync.Sincronizar(FIdRecuento, iSubidos, sMsg) then
      TDialogService.ShowMessage('No se pudo subir todo antes de finalizar: ' +
                                 sMsg)
    else if oApi.Finalizar(FIdRecuento) then
    begin
      TDialogService.ShowMessage('Recuento finalizado y enviado');
      ModalResult := mrOk;
    end
    else
      TDialogService.ShowMessage('No se pudo finalizar: ' + oApi.UltimoError);
  finally
    FreeAndNil(oApi);
    FreeAndNil(oSync);
  end;
end;

procedure TfrmConteo.OnVolverClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

class procedure TfrmConteo.IniciarAsync(AOwner: TComponent;
  AModo: TModoRecuento; AIdRecuento: Int64; const ACatalogo: TArrCatalogo;
  const ATitulo: string);
var
  frm: TfrmConteo;
begin
  frm := TfrmConteo.CreateNew(AOwner);
  frm.FModo := AModo;
  frm.FIdRecuento := AIdRecuento;
  frm.FCatalogo := ACatalogo;
  frm.Construir(ATitulo);
  frm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      frm.Free;
    end);
end;

end.
