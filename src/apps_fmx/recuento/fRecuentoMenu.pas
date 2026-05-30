{******************************************************************************}
{                                                                              }
{  Módulo:       fRecuentoMenu                                                 }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Menú principal de la app (formulario principal). Tres opciones:           }
{      1) Recontar códigos de barras (=+1)                                     }
{      2) Recontar códigos de barras + cantidad                                }
{      3) Recoger plantilla de recuento                                        }
{    Las opciones 1/2 preguntan el almacén (recuento libre); la 3 exige        }
{    plantilla. UI por código (sin .fmx); el constructor usa CreateNew.        }
{******************************************************************************}
unit fRecuentoMenu;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.Types,
  FMX.DialogService,
  RecuentoModelo, RecuentoConfig, RecuentoApi,
  fRecuentoSelector, fRecuentoConteo, fRecuentoConfig;

type
  TfrmMenu = class(TForm)
  private
    FAlmacenes : TArrAlmacen;
    FPlantillas: TArrPlantilla;
    function ComprobarConfig: Boolean;
    procedure Construir;
    function NuevoBoton(const ATexto: string; AHandler: TNotifyEvent): TButton;
    procedure AccionLibre(AModo: TModoRecuento);
    procedure IniciarLibre(AModo: TModoRecuento; const AValor: string);
    procedure IniciarPlantilla(AId: Int64);
    procedure OnModo1Click(Sender: TObject);
    procedure OnModo2Click(Sender: TObject);
    procedure OnModo3Click(Sender: TObject);
    procedure OnConfigClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  frmMenu: TfrmMenu;

implementation

constructor TfrmMenu.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Construir;
end;

function TfrmMenu.NuevoBoton(const ATexto: string;
  AHandler: TNotifyEvent): TButton;
var
  btn: TButton;
begin
  btn := TButton.Create(Self);
  btn.Parent := Self;
  btn.Align := TAlignLayout.Top;
  btn.Height := 64;
  btn.Margins.Left := 12;
  btn.Margins.Right := 12;
  btn.Margins.Top := 12;
  btn.Text := ATexto;
  btn.OnClick := AHandler;
  Result := btn;
end;

procedure TfrmMenu.Construir;
var
  lblTitulo: TLabel;
begin
  Self.Caption := 'Recuento Factuzam';
  // Creados en orden inverso al deseado: Align=Top apila el primero arriba.
  NuevoBoton('Configuración', OnConfigClick);
  NuevoBoton('3 · Recoger plantilla de recuento', OnModo3Click);
  NuevoBoton('2 · Recontar códigos de barras + cantidad', OnModo2Click);
  NuevoBoton('1 · Recontar códigos de barras', OnModo1Click);
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Self;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 48;
  lblTitulo.Text := 'Recuento de inventarios';
end;

function TfrmMenu.ComprobarConfig: Boolean;
begin
  Result := oConfig.EstaConfigurado;
  if not Result then
    TDialogService.ShowMessage('Antes configura el servidor y registra el ' +
      'dispositivo (botón Configuración).');
end;

procedure TfrmMenu.AccionLibre(AModo: TModoRecuento);
var
  oApi: TRecuentoApi;
  aCaptions, aValores: TArray<string>;
  i: Integer;
begin
  if ComprobarConfig then
  begin
    // TODO: mover la llamada de red a un hilo (TTask) para no bloquear la UI.
    oApi := TRecuentoApi.Create;
    try
      if not oApi.ListarAlmacenes(FAlmacenes) then
        TDialogService.ShowMessage('Error: ' + oApi.UltimoError)
      else if Length(FAlmacenes) = 0 then
        TDialogService.ShowMessage('No hay almacenes sincronizados en el ' +
          'servidor.')
      else
      begin
        SetLength(aCaptions, Length(FAlmacenes));
        SetLength(aValores, Length(FAlmacenes));
        for i := 0 to High(FAlmacenes) do
        begin
          aCaptions[i] := FAlmacenes[i].CodigoAlm + ' - ' +
                          FAlmacenes[i].Nombre;
          aValores[i] := FAlmacenes[i].CodigoEmp + '|' + FAlmacenes[i].CodigoAlm;
        end;
        TfrmSelector.ElegirAsync(Self, 'Elige almacén', aCaptions, aValores,
          procedure(AOk: Boolean; AValor: string)
          begin
            if AOk and (AValor <> '') then
              IniciarLibre(AModo, AValor);
          end);
      end;
    finally
      FreeAndNil(oApi);
    end;
  end;
end;

procedure TfrmMenu.IniciarLibre(AModo: TModoRecuento; const AValor: string);
var
  oApi: TRecuentoApi;
  aPartes: TArray<string>;
  sEmp, sAlm: string;
  idRec: Int64;
begin
  aPartes := AValor.Split(['|']);
  if Length(aPartes) = 2 then
  begin
    sEmp := aPartes[0];
    sAlm := aPartes[1];
    oApi := TRecuentoApi.Create;
    try
      if oApi.CrearRecuentoLibre(sEmp, sAlm, '', idRec) then
        TfrmConteo.IniciarAsync(Self, AModo, idRec, [], 'Almacén ' + sAlm)
      else
        TDialogService.ShowMessage('No se pudo crear el recuento: ' +
          oApi.UltimoError);
    finally
      FreeAndNil(oApi);
    end;
  end;
end;

procedure TfrmMenu.IniciarPlantilla(AId: Int64);
var
  oApi: TRecuentoApi;
  aCatalogo: TArrCatalogo;
begin
  oApi := TRecuentoApi.Create;
  try
    if oApi.DescargarCatalogo(AId, aCatalogo) then
      TfrmConteo.IniciarAsync(Self, mrPlantilla, AId, aCatalogo,
        'Plantilla ' + IntToStr(AId))
    else
      TDialogService.ShowMessage('No se pudo descargar la plantilla: ' +
        oApi.UltimoError);
  finally
    FreeAndNil(oApi);
  end;
end;

procedure TfrmMenu.OnModo1Click(Sender: TObject);
begin
  AccionLibre(mrCodigos);
end;

procedure TfrmMenu.OnModo2Click(Sender: TObject);
begin
  AccionLibre(mrCodigosCantidad);
end;

procedure TfrmMenu.OnModo3Click(Sender: TObject);
var
  oApi: TRecuentoApi;
  aCaptions, aValores: TArray<string>;
  i: Integer;
  sCap: string;
begin
  if ComprobarConfig then
  begin
    oApi := TRecuentoApi.Create;
    try
      if not oApi.ListarPlantillas(FPlantillas) then
        TDialogService.ShowMessage('Error: ' + oApi.UltimoError)
      else if Length(FPlantillas) = 0 then
        TDialogService.ShowMessage('No hay plantillas pendientes en el ' +
          'servidor.')
      else
      begin
        SetLength(aCaptions, Length(FPlantillas));
        SetLength(aValores, Length(FPlantillas));
        for i := 0 to High(FPlantillas) do
        begin
          sCap := FPlantillas[i].Descripcion;
          if Trim(sCap) = '' then
            sCap := FPlantillas[i].Serie + '/' + FPlantillas[i].Numero +
                    ' (' + FPlantillas[i].CodigoAlm + ')';
          aCaptions[i] := sCap;
          aValores[i] := IntToStr(FPlantillas[i].IdRecuento);
        end;
        TfrmSelector.ElegirAsync(Self, 'Elige plantilla', aCaptions, aValores,
          procedure(AOk: Boolean; AValor: string)
          begin
            if AOk and (AValor <> '') then
              IniciarPlantilla(StrToInt64Def(AValor, 0));
          end);
      end;
    finally
      FreeAndNil(oApi);
    end;
  end;
end;

procedure TfrmMenu.OnConfigClick(Sender: TObject);
begin
  TfrmConfig.EditarAsync(Self, nil);
end;

end.
