{******************************************************************************}
{                                                                              }
{  Módulo:       UPrincipal                                                    }
{    Tipo:       Formulario principal (FMX, multiplataforma)                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla principal de la app FMX de fotos a la nube. Permite hacer        }
{    fotos con la cámara (o elegirlas de la galería), las reduce a la          }
{    resolución máxima configurada (por defecto 1000 px), las acumula en una   }
{    cola por lotes y las sube al webservice de Factuzam (fotosnube).          }
{******************************************************************************}
unit UPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.IOUtils, System.Actions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FMX.Objects, FMX.TabControl, FMX.ScrollBox, FMX.Memo, FMX.Memo.Types,
  FMX.ActnList, FMX.MediaLibrary.Actions, FMX.Layouts,
  UConfigFotos, UColaFotosNube, UImagenUtil;

type
  TfrmPrincipal = class(TForm)
    TabControl1: TTabControl;
    tabCapturar: TTabItem;
    tabConfig: TTabItem;
    imgPrevia: TImage;
    btnCamara: TButton;
    btnGaleria: TButton;
    lstCola: TListView;
    btnSubir: TButton;
    cajaConfig: TVertScrollBox;
    lblUrl: TLabel;
    edUrl: TEdit;
    lblApiKey: TLabel;
    edApiKey: TEdit;
    lblCliente: TLabel;
    edCliente: TEdit;
    lblSku: TLabel;
    edSku: TEdit;
    lblResolucion: TLabel;
    edResolucion: TEdit;
    btnGuardarConfig: TButton;
    lblRutaIni: TLabel;
    memoLog: TMemo;
    ActionList1: TActionList;
    actHacerFoto: TTakePhotoFromCameraAction;
    actElegirFoto: TTakePhotoFromLibraryAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCamaraClick(Sender: TObject);
    procedure btnGaleriaClick(Sender: TObject);
    procedure btnSubirClick(Sender: TObject);
    procedure btnGuardarConfigClick(Sender: TObject);
    procedure actHacerFotoDidFinishTaking(Image: TBitmap);
    procedure actElegirFotoDidFinishTaking(Image: TBitmap);
  private
    FConfig: TConfigFotos;
    FCola: TColaFotos;
    procedure Log(const S: string);
    procedure ConfigAUI;
    procedure UIAConfig;
    procedure RefrescarCola;
    procedure ProcesarImagen(const AImagen: TBitmap);
    procedure PedirPermisoCamara;
  public
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

{$IFDEF ANDROID}
uses
  System.Permissions, FMX.Helpers.Android, Androidapi.Helpers,
  Androidapi.JNI.Os, Androidapi.JNI.JavaTypes;
{$ENDIF}

const
  cVersionApp = '1.0.0.202605290000.alpha';

procedure TfrmPrincipal.Log(const S: string);
begin
  memoLog.Lines.Add(Format('[%s] %s',
    [FormatDateTime('hh:nn:ss', Now), S]));
  memoLog.GoToTextEnd;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  FConfig := TConfigFotos.Create;
  FConfig.Cargar;
  FCola := TColaFotos.Create;
  ConfigAUI;
  RefrescarCola;
  PedirPermisoCamara;
  Log('Factuzam Fotos Nube ' + cVersionApp);
  Log('Configuración: ' + FConfig.RutaIni);
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  FCola.Free;
  FConfig.Free;
end;

procedure TfrmPrincipal.ConfigAUI;
begin
  edUrl.Text := FConfig.Url;
  edApiKey.Text := FConfig.ApiKey;
  edCliente.Text := FConfig.Cliente;
  edSku.Text := FConfig.SkuPorDefecto;
  edResolucion.Text := IntToStr(FConfig.ResolucionMaxima);
  lblRutaIni.Text := 'INI: ' + FConfig.RutaIni;
end;

procedure TfrmPrincipal.UIAConfig;
var
  Resol: Integer;
begin
  FConfig.Url := Trim(edUrl.Text);
  FConfig.ApiKey := Trim(edApiKey.Text);
  FConfig.Cliente := Trim(edCliente.Text);
  FConfig.SkuPorDefecto := Trim(edSku.Text);
  // Si el texto no es un entero válido usamos el valor por defecto.
  if not TryStrToInt(Trim(edResolucion.Text), Resol) then
    Resol := cResolucionMaximaDefecto;
  FConfig.ResolucionMaxima := Resol;
end;

procedure TfrmPrincipal.btnGuardarConfigClick(Sender: TObject);
begin
  UIAConfig;
  FConfig.Guardar;
  // Reflejamos el valor ya saneado (por si se topó o corrigió).
  edResolucion.Text := IntToStr(FConfig.ResolucionMaxima);
  Log('Configuración guardada (resolución máx. ' +
    IntToStr(FConfig.ResolucionMaxima) + ' px)');
end;

procedure TfrmPrincipal.PedirPermisoCamara;
begin
  // En Android hay que pedir el permiso de cámara en tiempo de
  // ejecución; en el resto de plataformas no hace nada.
{$IFDEF ANDROID}
  PermissionsService.RequestPermissions(
    [JStringToString(TJManifest_permission.JavaClass.CAMERA)],
    procedure(const APermissions: TClassicStringDynArray;
      const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults) = 0) or
         (AGrantResults[0] <> TPermissionStatus.Granted) then
        Log('Permiso de cámara no concedido');
    end);
{$ENDIF}
end;

procedure TfrmPrincipal.btnCamaraClick(Sender: TObject);
begin
  // Limitamos la resolución ya en la captura para gastar menos memoria.
  actHacerFoto.MaxWidth := FConfig.ResolucionMaxima;
  actHacerFoto.MaxHeight := FConfig.ResolucionMaxima;
  actHacerFoto.ExecuteTarget(Self);
end;

procedure TfrmPrincipal.btnGaleriaClick(Sender: TObject);
begin
  actElegirFoto.MaxWidth := FConfig.ResolucionMaxima;
  actElegirFoto.MaxHeight := FConfig.ResolucionMaxima;
  actElegirFoto.ExecuteTarget(Self);
end;

procedure TfrmPrincipal.actHacerFotoDidFinishTaking(Image: TBitmap);
begin
  ProcesarImagen(Image);
end;

procedure TfrmPrincipal.actElegirFotoDidFinishTaking(Image: TBitmap);
begin
  ProcesarImagen(Image);
end;

procedure TfrmPrincipal.ProcesarImagen(const AImagen: TBitmap);
var
  Reducida: TBitmap;
  Ruta: string;
begin
  // Aplicamos el tope de resolución (defensivo, además del de la
  // captura) y guardamos la foto en JPG para encolarla.
  Reducida := RedimensionarMax(AImagen, FConfig.ResolucionMaxima);
  try
    imgPrevia.Bitmap.Assign(Reducida);
    Ruta := TPath.Combine(TPath.GetTempPath,
      'foto_' + FormatDateTime('yyyymmdd_hhnnsszzz', Now) + '.jpg');
    Reducida.SaveToFile(Ruta);
    FCola.Add(Ruta, Trim(edSku.Text));
    RefrescarCola;
    Log(Format('Foto encolada %dx%d: %s',
      [Reducida.Width, Reducida.Height, TPath.GetFileName(Ruta)]));
  finally
    Reducida.Free;
  end;
end;

procedure TfrmPrincipal.RefrescarCola;
var
  Item: TFotoItem;
  Fila: TListViewItem;
begin
  lstCola.BeginUpdate;
  try
    lstCola.Items.Clear;
    for Item in FCola.Items do
    begin
      Fila := lstCola.Items.Add;
      Fila.Text := TPath.GetFileName(Item.Archivo);
      Fila.Detail := EstadoTexto(Item.Estado);
    end;
  finally
    lstCola.EndUpdate;
  end;
  btnSubir.Text := Format('Subir todas (%d)', [FCola.PendientesCount]);
end;

procedure TfrmPrincipal.btnSubirClick(Sender: TObject);
begin
  UIAConfig;
  if FConfig.Url = '' then
  begin
    Log('Falta la URL del webservice (pestaña Configuración)');
  end
  else if FConfig.Cliente = '' then
  begin
    Log('Falta el identificador de cliente (pestaña Configuración)');
  end
  else if FCola.PendientesCount = 0 then
  begin
    Log('No hay fotos pendientes de subir');
  end
  else
  begin
    FCola.Url := FConfig.Url;
    FCola.ApiKey := FConfig.ApiKey;
    FCola.Cliente := FConfig.Cliente;
    btnSubir.Enabled := False;
    Log('Subiendo lote de fotos...');
    FCola.SubirTodasAsync(
      procedure(const AItem: TFotoItem)
      begin
        RefrescarCola;
        if AItem.Estado = esError then
          Log('Error en ' + TPath.GetFileName(AItem.Archivo) + ': ' +
            AItem.Mensaje)
        else if AItem.Estado = esOk then
          Log('OK ' + TPath.GetFileName(AItem.Archivo) +
            ' (hash ' + AItem.Hash + ')');
      end,
      procedure(const AOk, AError: Integer)
      begin
        btnSubir.Enabled := True;
        RefrescarCola;
        Log(Format('Lote finalizado: %d OK, %d con error',
          [AOk, AError]));
      end);
  end;
end;

end.
