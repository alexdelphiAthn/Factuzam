{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalVerifactuDecl                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Declaración responsable del sistema informático de facturación            }
{    (art. 15 de la Orden HAC/1177/2024). Descarga desde el servicio la        }
{    declaración aplicable y la muestra en un visor HTML embebido.             }
{******************************************************************************}
unit inMtoModalVerifactuDecl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.OleCtrls, SHDocVw,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMemo, cxButtons, cxLabel,
  inMtoFrmBase;

type
  TfrmModalVerifactuDecl = class(TfrmBase)
    mDeclaracion: TcxMemo;
    pnlInstalacion: TPanel;
    lblInstalacionTitulo: TcxLabel;
    lblInstalacionNumero: TcxLabel;
    lblInstalacionEstado: TcxLabel;
    btnGenerarInstalacion: TcxButton;
    pnlButton: TPanel;
    btnImprimir: TcxButton;
    btnAceptar: TcxButton;
    procedure btnGenerarInstalacionClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
  private
    FWebDeclaracion: TWebBrowser;
    FHtmlDeclaracion: string;
    procedure AsegurarVisorHtml;
    procedure ActualizarInstalacion;
    procedure CargarTexto;
    procedure MostrarErrorDeclaracion(const AMensaje: string);
  public
    class procedure Ejecutar(AOwner: TComponent);
  end;

implementation

uses
  System.IOUtils,
  Data.DB, Uni,
  inLibGlobalVar, inLibVerifactuInstalacion;

{$R *.dfm}

function AjustarHtmlParaVisor(const AHtml: string): string;
var
  iPosHead: Integer;
  sHtmlMin: string;
  sBase:    string;
begin
  Result   := AHtml;
  sHtmlMin := AnsiLowerCase(Result);
  if Pos('<base ', sHtmlMin) = 0 then
  begin
    iPosHead := Pos('<head>', sHtmlMin);
    if iPosHead > 0 then
    begin
      sBase := sLineBreak +
        '    <base href="https://veryverifactu.com/">';
      Insert(sBase, Result, iPosHead + Length('<head>'));
    end;
  end;
end;

function DescargarHtmlDeclaracion: string;
begin
  Result := ObtenerDeclaracionResponsableSif(oVersion);
end;

function GuardarHtmlTemporal(const AHtml: string): string;
begin
  Result := TPath.Combine(TPath.GetTempPath,
    'factuzam_declaracion_responsable.html');
  TFile.WriteAllText(Result, AHtml, TEncoding.UTF8);
end;

function GuardarHtmlTemporalImpresion(const AHtml: string): string;
begin
  Result := TPath.Combine(TPath.GetTempPath,
    'factuzam_declaracion_responsable_impresion.html');
  TFile.WriteAllText(Result, AHtml, TEncoding.UTF8);
end;

function HtmlTexto(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&#39;', [rfReplaceAll]);
end;

function CssAnexoImpresion: string;
begin
  Result :=
    '<style>' + sLineBreak +
    '@media screen {.anexo-instalaciones-sif{display:none;}}' +
    sLineBreak +
    '@media print {' + sLineBreak +
    '  .anexo-instalaciones-sif{display:block;break-before:page;' +
    'page-break-before:always;margin-top:24px;font-size:11px;}' +
    sLineBreak +
    '  .anexo-instalaciones-sif h2{font-size:18px;margin:0 0 8px;}' +
    sLineBreak +
    '  .anexo-instalaciones-sif p{margin:0 0 12px;}' + sLineBreak +
    '  .anexo-instalaciones-sif table{width:100%;border-collapse:collapse;}' +
    sLineBreak +
    '  .anexo-instalaciones-sif th,.anexo-instalaciones-sif td{' +
    'border:1px solid #777;padding:5px 6px;vertical-align:top;}' +
    sLineBreak +
    '  .anexo-instalaciones-sif th{background:#eee;text-align:left;}' +
    sLineBreak +
    '}' + sLineBreak +
    '</style>' + sLineBreak;
end;

function EstadoEmpresaInstalacion(const ANumero, AVersion,
                                  ACodigoSif: string): string;
begin
  if Trim(ANumero) = '' then
  begin
    Result := 'Pendiente';
  end
  else if not SameText(Trim(ACodigoSif), cCodigoSifFactuzam) then
  begin
    Result := 'SIF distinto';
  end
  else if not SameText(Trim(AVersion), oVersion) then
  begin
    Result := 'Requiere regenerar';
  end
  else
  begin
    Result := 'Válido';
  end;
end;

function AnexoEmpresasInstalacionHtml: string;
var
  Qry:       TUniQuery;
  sFilas:    string;
  sActivo:   string;
  sNumero:   string;
  sVersion:  string;
  sCodigoSif:string;
  sEstado:   string;
  sInstante: string;
  iTotal:    Integer;
begin
  sFilas := '';
  iTotal := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := oConn;
    Qry.SQL.Text :=
      ' SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP, NIF_EMP, ESACTIVO_EMP, ' +
      '        NUMERO_INSTALACION_EMP, VERSION_INSTALACION_EMP, ' +
      '        CODIGO_SIF_INSTALACION_EMP, INSTANTE_INSTALACION_EMP ' +
      ' FROM fza_empresas ' +
      ' ORDER BY IF(ESACTIVO_EMP = ''S'', 0, 1), ORDEN_EMP, ' +
      '          CODIGO_EMP_EMP ';
    Qry.Open;
    while not Qry.Eof do
    begin
      Inc(iTotal);
      sNumero := Trim(Qry.FieldByName('NUMERO_INSTALACION_EMP').AsString);
      sVersion := Trim(Qry.FieldByName('VERSION_INSTALACION_EMP').AsString);
      sCodigoSif :=
        Trim(Qry.FieldByName('CODIGO_SIF_INSTALACION_EMP').AsString);
      sEstado := EstadoEmpresaInstalacion(sNumero, sVersion, sCodigoSif);
      if Qry.FieldByName('ESACTIVO_EMP').AsString = 'S' then
      begin
        sActivo := 'Sí';
      end
      else
      begin
        sActivo := 'No';
      end;
      if Qry.FieldByName('INSTANTE_INSTALACION_EMP').IsNull then
      begin
        sInstante := '';
      end
      else
      begin
        sInstante := FormatDateTime('dd/mm/yyyy hh:nn',
          Qry.FieldByName('INSTANTE_INSTALACION_EMP').AsDateTime);
      end;
      if sNumero = '' then
      begin
        sNumero := '(pendiente)';
      end;
      if sVersion = '' then
      begin
        sVersion := '(pendiente)';
      end;
      if sCodigoSif = '' then
      begin
        sCodigoSif := '(pendiente)';
      end;
      sFilas := sFilas +
        '<tr>' +
        '<td>' + HtmlTexto(Qry.FieldByName('CODIGO_EMP_EMP').AsString) +
        '</td>' +
        '<td>' + HtmlTexto(Qry.FieldByName('RAZON_SOCIAL_EMP').AsString) +
        '</td>' +
        '<td>' + HtmlTexto(Qry.FieldByName('NIF_EMP').AsString) + '</td>' +
        '<td>' + HtmlTexto(sActivo) + '</td>' +
        '<td>' + HtmlTexto(sNumero) + '</td>' +
        '<td>' + HtmlTexto(sVersion) + '</td>' +
        '<td>' + HtmlTexto(sCodigoSif) + '</td>' +
        '<td>' + HtmlTexto(sInstante) + '</td>' +
        '<td>' + HtmlTexto(sEstado) + '</td>' +
        '</tr>' + sLineBreak;
      Qry.Next;
    end;
  finally
    FreeAndNil(Qry);
  end;
  if iTotal = 0 then
  begin
    sFilas :=
      '<p>No hay empresas configuradas en esta base de datos.</p>';
  end
  else
  begin
    sFilas :=
      '<table>' + sLineBreak +
      '<thead><tr>' +
      '<th>Código</th><th>Razón social</th><th>NIF</th><th>Activa</th>' +
      '<th>Nº instalación</th><th>Versión</th><th>SIF</th>' +
      '<th>Fecha generación</th><th>Estado</th>' +
      '</tr></thead>' + sLineBreak +
      '<tbody>' + sLineBreak + sFilas + '</tbody></table>';
  end;
  Result :=
    '<section class="anexo-instalaciones-sif">' + sLineBreak +
    '<h2>Anexo: empresas e instalaciones SIF</h2>' + sLineBreak +
    '<p>Relación de empresas configuradas en Factuzam para el SIF FZ ' +
    'en la versión ' + HtmlTexto(oVersion) + '.</p>' + sLineBreak +
    sFilas + sLineBreak +
    '</section>' + sLineBreak;
end;

function AgregarAnexoImpresion(const AHtml: string): string;
var
  iPosBody: Integer;
  sHtmlMin: string;
  sBloque:  string;
begin
  Result := AHtml;
  sBloque := CssAnexoImpresion + AnexoEmpresasInstalacionHtml;
  sHtmlMin := AnsiLowerCase(Result);
  iPosBody := Pos('</body>', sHtmlMin);
  if iPosBody > 0 then
  begin
    Insert(sBloque, Result, iPosBody);
  end
  else
  begin
    Result := Result + sLineBreak + sBloque;
  end;
end;

function EsperarCargaWeb(AWeb: TWebBrowser; ATiempoMaxMs: Cardinal): Boolean;
var
  iInicio: Cardinal;
begin
  Result := False;
  iInicio := GetTickCount;
  while (GetTickCount - iInicio) < ATiempoMaxMs do
  begin
    Application.ProcessMessages;
    if AWeb.ReadyState = READYSTATE_COMPLETE then
    begin
      Result := True;
    end;
    if Result then
    begin
      Break;
    end;
    Sleep(50);
  end;
end;

procedure TfrmModalVerifactuDecl.AsegurarVisorHtml;
begin
  if FWebDeclaracion = nil then
  begin
    FWebDeclaracion := TWebBrowser.Create(Self);
    InsertControl(FWebDeclaracion);
    FWebDeclaracion.Align := alClient;
    FWebDeclaracion.Silent := True;
    FWebDeclaracion.Visible := False;
  end;
end;

procedure TfrmModalVerifactuDecl.ActualizarInstalacion;
var
  oEstado: TEstadoInstalacionSif;
  sNumero: string;
begin
  try
    if ObtenerEmpresaInstalacionSifDefecto(oConn, oEstado) then
    begin
      sNumero := oEstado.Numero;
      if sNumero = '' then
        sNumero := '(pendiente)';
      lblInstalacionTitulo.Caption :=
        'Número de instalación SIF - ' + oEstado.RazonSocial +
        ' (' + oEstado.Nif + ')';
      lblInstalacionNumero.Caption :=
        'Número: ' + sNumero + ' | Versión: ' + oEstado.Version;
      lblInstalacionEstado.Caption := oEstado.Mensaje;
      btnGenerarInstalacion.Enabled := not oEstado.EsValido;
      if oEstado.EsValido then
        lblInstalacionEstado.Style.TextColor := clGreen
      else
        lblInstalacionEstado.Style.TextColor := clMaroon;
      if Trim(oEstado.Version) = '' then
        lblInstalacionNumero.Caption :=
          'Número: ' + sNumero + ' | Versión: (pendiente)';
    end
    else
    begin
      lblInstalacionTitulo.Caption := 'Número de instalación SIF';
      lblInstalacionNumero.Caption := 'No hay empresa configurada.';
      lblInstalacionEstado.Caption := '';
      lblInstalacionEstado.Style.TextColor := clMaroon;
      btnGenerarInstalacion.Enabled := False;
    end;
  except
    on E: Exception do
    begin
      lblInstalacionTitulo.Caption := 'Número de instalación SIF';
      lblInstalacionNumero.Caption := 'No se pudo leer fza_empresas.';
      lblInstalacionEstado.Caption := E.Message;
      lblInstalacionEstado.Style.TextColor := clMaroon;
      btnGenerarInstalacion.Enabled := False;
    end;
  end;
end;

procedure TfrmModalVerifactuDecl.btnImprimirClick(Sender: TObject);
var
  sArchivo:  string;
  sHtml:     string;
  vEntrada:  OleVariant;
  vSalida:   OleVariant;
begin
  btnImprimir.Enabled := False;
  try
    AsegurarVisorHtml;
    if Trim(FHtmlDeclaracion) = '' then
    begin
      FHtmlDeclaracion := AjustarHtmlParaVisor(DescargarHtmlDeclaracion);
    end;
    sHtml := AgregarAnexoImpresion(FHtmlDeclaracion);
    sArchivo := GuardarHtmlTemporalImpresion(sHtml);
    FWebDeclaracion.Navigate(sArchivo);
    if not EsperarCargaWeb(FWebDeclaracion, 15000) then
    begin
      raise Exception.Create('No se pudo preparar el documento de ' +
        'impresión.');
    end;
    vEntrada := EmptyParam;
    vSalida := EmptyParam;
    FWebDeclaracion.ExecWB(OLECMDID_PRINT, OLECMDEXECOPT_PROMPTUSER,
      vEntrada, vSalida);
    FWebDeclaracion.Navigate(GuardarHtmlTemporal(FHtmlDeclaracion));
  except
    on E: Exception do
    begin
      ShowMessage('No se pudo imprimir la declaración responsable:' +
        sLineBreak + E.Message);
    end;
  end;
  btnImprimir.Enabled := True;
end;

procedure TfrmModalVerifactuDecl.btnGenerarInstalacionClick(Sender: TObject);
var
  oEstado: TEstadoInstalacionSif;
begin
  btnGenerarInstalacion.Enabled := False;
  lblInstalacionEstado.Caption := 'Solicitando número al servicio...';
  Application.ProcessMessages;
  try
    oEstado := GenerarInstalacionSifEmpresa(oConn, '');
    lblInstalacionEstado.Caption := 'Número disponible y guardado.';
    ShowMessage('Número de instalación SIF disponible: ' + oEstado.Numero);
  except
    on E: Exception do
      ShowMessage('No se pudo generar el número de instalación SIF:' +
        sLineBreak + E.Message);
  end;
  ActualizarInstalacion;
end;

procedure TfrmModalVerifactuDecl.MostrarErrorDeclaracion(
  const AMensaje: string);
begin
  if FWebDeclaracion <> nil then
    FWebDeclaracion.Visible := False;
  mDeclaracion.Visible := True;
  mDeclaracion.BringToFront;
  mDeclaracion.Lines.Text :=
    'No se ha podido descargar la declaración responsable.' +
    sLineBreak + sLineBreak +
    'Versión solicitada: ' + oVersion +
    sLineBreak + sLineBreak +
    'Detalle: ' + AMensaje;
  mDeclaracion.SelStart := 0;
end;

class procedure TfrmModalVerifactuDecl.Ejecutar(AOwner: TComponent);
var
  frm: TfrmModalVerifactuDecl;
begin
  frm := TfrmModalVerifactuDecl.Create(AOwner);
  try
    frm.ActualizarInstalacion;
    frm.CargarTexto;
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalVerifactuDecl.CargarTexto;
var
  sArchivo: string;
begin
  mDeclaracion.Visible := True;
  mDeclaracion.Lines.Text :=
    'Descargando declaración responsable...' +
    sLineBreak + sLineBreak +
    'Versión: ' + oVersion;
  mDeclaracion.SelStart := 0;
  Application.ProcessMessages;
  try
    AsegurarVisorHtml;
    FHtmlDeclaracion := AjustarHtmlParaVisor(DescargarHtmlDeclaracion);
    sArchivo := GuardarHtmlTemporal(FHtmlDeclaracion);
    mDeclaracion.Visible := False;
    FWebDeclaracion.Visible := True;
    FWebDeclaracion.BringToFront;
    FWebDeclaracion.Navigate(sArchivo);
  except
    on E: Exception do
      MostrarErrorDeclaracion(E.Message);
  end;
end;

end.
