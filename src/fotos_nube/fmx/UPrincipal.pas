{******************************************************************************}
{                                                                              }
{  Módulo:       UPrincipal                                                    }
{    Tipo:       Formulario principal (FMX, Android)                           }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla principal de la app FMX de fotos a la nube. Permite hacer        }
{    fotos con la cámara (o elegirlas de la galería) asociándolas a un código  }
{    de artículo y un color, las reduce a la resolución máxima configurada     }
{    (por defecto 1000 px), las acumula en una cola por lotes y las sube al    }
{    endpoint de fotos de la API v1 de Factuzam. Si hay varias fotos del       }
{    fotos del mismo artículo+color se les asigna un índice correlativo.       }
{******************************************************************************}
unit UPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.IOUtils, System.Actions,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FMX.Objects, FMX.TabControl, FMX.ScrollBox, FMX.Memo, FMX.Memo.Types,
  FMX.ActnList, FMX.MediaLibrary.Actions, FMX.Layouts,
  UConfigFotos, UColaFotosNube, UImagenUtil, FMX.MediaLibrary, FMX.StdActns;

type
  TfrmPrincipal = class(TForm)
    TabControl1: TTabControl;
    tabCapturar: TTabItem;
    tabConfig: TTabItem;
    lblArticulo: TLabel;
    edArticulo: TEdit;
    lblColor: TLabel;
    edColor: TEdit;
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
    lblCarpetaCliente: TLabel;
    edCarpetaCliente: TEdit;
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
    // Pide el permiso de camara (Android) y, si se concede, ejecuta
    // ATrasConceder. En el resto de plataformas ejecuta directamente.
    procedure ConPermisoCamara(const ATrasConceder: TProc);
    function ValidarDatosFoto: Boolean;
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
  edCarpetaCliente.Text := FConfig.CarpetaCliente;
  edResolucion.Text := IntToStr(FConfig.ResolucionMaxima);
  lblRutaIni.Text := 'INI: ' + FConfig.RutaIni;
end;

procedure TfrmPrincipal.UIAConfig;
var
  Resol: Integer;
begin
  FConfig.Url := Trim(edUrl.Text);
  FConfig.ApiKey := Trim(edApiKey.Text);
  FConfig.CarpetaCliente := Trim(edCarpetaCliente.Text);
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

procedure TfrmPrincipal.ConPermisoCamara(const ATrasConceder: TProc);
begin
  // En Android se pide el permiso de cámara en tiempo de ejecución, justo
  // al ir a usarla, y solo si se concede se ejecuta la acción. En el resto
  // de plataformas se ejecuta directamente.
{$IFDEF ANDROID}
  PermissionsService.RequestPermissions(
    [JStringToString(TJManifest_permission.JavaClass.CAMERA)],
    procedure(const APermissions: TClassicStringDynArray;
      const AGrantResults: TClassicPermissionStatusDynArray)
    begin
      if (Length(AGrantResults) = 1) and
         (AGrantResults[0] = TPermissionStatus.Granted) then
      begin
        if Assigned(ATrasConceder) then
          ATrasConceder();
      end
      else
        Log('Permiso de cámara no concedido. Actívalo en Ajustes de Android.');
    end);
{$ELSE}
  if Assigned(ATrasConceder) then
    ATrasConceder();
{$ENDIF}
end;

function TfrmPrincipal.ValidarDatosFoto: Boolean;
begin
  // Artículo y color son obligatorios: el webservice nombra el fichero
  // como ARTICULO_COLOR_INDICE y exige los tres campos no vacíos.
  Result := True;
  if Trim(edArticulo.Text) = '' then
  begin
    Log('Indica el código de artículo antes de hacer la foto');
    edArticulo.SetFocus;
    Result := False;
  end
  else if Trim(edColor.Text) = '' then
  begin
    Log('Indica el color antes de hacer la foto');
    edColor.SetFocus;
    Result := False;
  end;
end;

procedure TfrmPrincipal.btnCamaraClick(Sender: TObject);
begin
  if ValidarDatosFoto then
    // Pedimos el permiso al ir a usar la cámara; si se concede, dispara.
    ConPermisoCamara(
      procedure
      begin
        // Limitamos la resolución ya en la captura para gastar memoria.
        actHacerFoto.MaxWidth := FConfig.ResolucionMaxima;
        actHacerFoto.MaxHeight := FConfig.ResolucionMaxima;
        actHacerFoto.ExecuteTarget(Self);
      end);
end;

procedure TfrmPrincipal.btnGaleriaClick(Sender: TObject);
begin
  if ValidarDatosFoto then
  begin
    actElegirFoto.MaxWidth := FConfig.ResolucionMaxima;
    actElegirFoto.MaxHeight := FConfig.ResolucionMaxima;
    actElegirFoto.ExecuteTarget(Self);
  end;
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
  // captura) y guardamos la foto en JPG para encolarla con su
  // artículo+color.
  Reducida := RedimensionarMax(AImagen, FConfig.ResolucionMaxima);
  try
    imgPrevia.Bitmap.Assign(Reducida);
    // Cualificamos System.IOUtils.TPath: FMX.Objects tambien declara un
    // TPath (la forma vectorial) y, al ir despues en el uses, taparia este.
    Ruta := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetTempPath,
      'foto_' + FormatDateTime('yyyymmdd_hhnnsszzz', Now) + '.jpg');
    Reducida.SaveToFile(Ruta);
    FCola.Add(Ruta, Trim(edArticulo.Text), Trim(edColor.Text));
    RefrescarCola;
    Log(Format('Foto encolada %dx%d: %s / %s',
      [Reducida.Width, Reducida.Height, Trim(edArticulo.Text),
       Trim(edColor.Text)]));
  finally
    Reducida.Free;
  end;
end;

procedure TfrmPrincipal.RefrescarCola;
var
  Item: TFotoItem;
  Fila: TListViewItem;
  Etiqueta: string;
begin
  lstCola.BeginUpdate;
  try
    lstCola.Items.Clear;
    for Item in FCola.Items do
    begin
      Etiqueta := Item.Articulo;
      if Item.Color <> '' then
        Etiqueta := Etiqueta + ' / ' + Item.Color;
      // La apariencia por defecto del TListView solo muestra Text, asi
      // que metemos el estado en la misma linea para no perderlo.
      Etiqueta := Etiqueta + '  [' + EstadoTexto(Item.Estado) + ']';
      Fila := lstCola.Items.Add;
      Fila.Text := Etiqueta;
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
  else if FConfig.CarpetaCliente = '' then
  begin
    Log('Falta la carpeta de cliente (pestaña Configuración)');
  end
  else if FCola.PendientesCount = 0 then
  begin
    Log('No hay fotos pendientes de subir');
  end
  else
  begin
    FCola.Url := FConfig.Url;
    FCola.ApiKey := FConfig.ApiKey;
    FCola.CarpetaCliente := FConfig.CarpetaCliente;
    btnSubir.Enabled := False;
    Log('Subiendo lote de fotos...');
    FCola.SubirTodasAsync(
      procedure(const AItem: TFotoItem)
      begin
        RefrescarCola;
        if AItem.Estado = esError then
          Log('Error en ' + AItem.Articulo + ': ' + AItem.Mensaje)
        else if AItem.Estado = esOk then
          Log('OK ' + AItem.Articulo + ' (sha1 ' + AItem.Hash + ')');
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
