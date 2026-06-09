{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFiltroArt                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Diálogo de acotado de la precarga de artículos. Se muestra cuando con     }
{    los filtros por defecto (solo activos + solo stock) salen más artículos   }
{    que el umbral admitido. Permite filtrar por temporada, proveedor y        }
{    familia, mostrando en vivo cuántos artículos se cargarían.                }
{    Se construye en código (CreateNew), sin .dfm.                            }
{******************************************************************************}
unit inMtoModalFiltroArt;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.ExtCtrls,
  Vcl.Dialogs, Data.DB, MemDS, DBAccess, Uni,
  cxGraphics, cxControls, cxContainer, cxEdit, cxLabel, cxButtons,
  cxCheckBox, cxCheckListBox;

type
  // Callback que cuenta los articulos que saldrian con una combinacion de
  // filtros (temporada/proveedor/familia en CSV ';'). Lo provee el Mto de
  // Articulos para que el dialogo muestre el conteo en vivo con el MISMO
  // WHERE que usara la carga real.
  TContarArticulosFunc = reference to function(const aTempCsv, aPrvCsv,
    aFamCsv: string): Integer;

  TfrmModalFiltroArt = class(TForm)
  private
    FConn: TUniConnection;
    FUmbral: Integer;
    FContar: TContarArticulosFunc;
    FlblCabecera: TcxLabel;
    FlblResultado: TcxLabel;
    FclbTemporada: TcxCheckListBox;
    FclbProveedor: TcxCheckListBox;
    FclbFamilia: TcxCheckListBox;
    // Codigos alineados por indice con los Items de las listas de proveedor
    // y familia (el Text muestra la descripcion; el filtro usa el codigo).
    FCodProv: TStringList;
    FCodFam: TStringList;
    FbtnCalcular: TcxButton;
    FbtnAceptar: TcxButton;
    FbtnCancelar: TcxButton;
    procedure ConstruirUI;
    function  CrearCheckList(ALeft, ATop, AWidth, AHeight: Integer;
                            const ATitulo: string): TcxCheckListBox;
    procedure CargarTemporadas(const aPreCsv: string);
    procedure CargarProveedores(const aPreCsv: string);
    procedure CargarFamilias(const aPreCsv: string);
    function  CsvMarcados(AClb: TcxCheckListBox;
                          ACodigos: TStringList): string;
    procedure ActualizarResultado;
    procedure CalcularClick(Sender: TObject);
    procedure AceptarClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Muestra el dialogo. Devuelve True si el usuario acepta (y deja en los
    // parametros out el CSV de cada filtro); False si cancela (los out
    // conservan lo recibido, para que el llamador cargue el filtro base).
    class function Ejecutar(AOwner: TComponent; AConn: TUniConnection;
      AUmbral: Integer;
      const APreTempCsv, APrePrvCsv, APreFamCsv: string;
      AContar: TContarArticulosFunc;
      out aTempCsv, aPrvCsv, aFamCsv: string): Boolean;
  end;

implementation

constructor TfrmModalFiltroArt.Create(AOwner: TComponent);
begin
  // CreateNew: sin .dfm, montamos la UI a mano en ConstruirUI.
  inherited CreateNew(AOwner);
  FCodProv := TStringList.Create;
  FCodFam  := TStringList.Create;
  ConstruirUI;
end;

destructor TfrmModalFiltroArt.Destroy;
begin
  FreeAndNil(FCodProv);
  FreeAndNil(FCodFam);
  inherited;
end;

function TfrmModalFiltroArt.CrearCheckList(ALeft, ATop, AWidth,
  AHeight: Integer; const ATitulo: string): TcxCheckListBox;
var
  lbl: TcxLabel;
begin
  lbl := TcxLabel.Create(Self);
  lbl.Parent  := Self;
  lbl.Left    := ALeft;
  lbl.Top     := ATop;
  lbl.Caption := ATitulo;
  Result := TcxCheckListBox.Create(Self);
  Result.Parent := Self;
  Result.Left   := ALeft;
  Result.Top    := ATop + 18;
  Result.Width  := AWidth;
  Result.Height := AHeight;
end;

procedure TfrmModalFiltroArt.ConstruirUI;
const
  MARGEN = 12;
  GAP    = 10;
var
  anchoCol, topListas, altoLista, topBotones: Integer;
  pnlBot: TPanel;
begin
  Caption      := 'Demasiados art' + #237 + 'culos - acotar la carga';
  BorderStyle  := bsDialog;
  Position     := poScreenCenter;
  ClientWidth  := 680;
  ClientHeight := 488;
  // Cabecera explicativa (multilinea)
  FlblCabecera := TcxLabel.Create(Self);
  FlblCabecera.Parent := Self;
  FlblCabecera.Left   := MARGEN;
  FlblCabecera.Top    := MARGEN;
  FlblCabecera.AutoSize := False;
  FlblCabecera.Width  := ClientWidth - 2 * MARGEN;
  FlblCabecera.Height := 52;
  FlblCabecera.Properties.WordWrap := True;
  // Tres columnas de seleccion (temporada / proveedor / familia)
  topListas := MARGEN + 60;
  altoLista := 300;
  anchoCol  := (ClientWidth - 2 * MARGEN - 2 * GAP) div 3;
  FclbTemporada := CrearCheckList(MARGEN, topListas, anchoCol, altoLista,
                                  'Temporada');
  FclbProveedor := CrearCheckList(MARGEN + anchoCol + GAP, topListas,
                                  anchoCol, altoLista, 'Proveedor');
  FclbFamilia   := CrearCheckList(MARGEN + 2 * (anchoCol + GAP), topListas,
                                  anchoCol, altoLista, 'Familia');
  // Linea de resultado + boton Calcular
  topBotones := topListas + 18 + altoLista + 10;
  FlblResultado := TcxLabel.Create(Self);
  FlblResultado.Parent  := Self;
  FlblResultado.Left    := MARGEN;
  FlblResultado.Top     := topBotones + 8;
  FlblResultado.Caption := '';
  FbtnCalcular := TcxButton.Create(Self);
  FbtnCalcular.Parent  := Self;
  FbtnCalcular.Left    := MARGEN + 220;
  FbtnCalcular.Top     := topBotones;
  FbtnCalcular.Width   := 150;
  FbtnCalcular.Caption := 'Calcular n' + #186;
  FbtnCalcular.OnClick := CalcularClick;
  // Panel inferior con Aceptar / Cancelar
  pnlBot := TPanel.Create(Self);
  pnlBot.Parent     := Self;
  pnlBot.Align      := alBottom;
  pnlBot.Height     := 44;
  pnlBot.BevelOuter := bvNone;
  FbtnAceptar := TcxButton.Create(Self);
  FbtnAceptar.Parent  := pnlBot;
  FbtnAceptar.Caption := 'Aceptar';
  FbtnAceptar.Width   := 110;
  FbtnAceptar.Height  := 28;
  FbtnAceptar.Top     := 8;
  FbtnAceptar.Left    := ClientWidth - 2 * 110 - MARGEN - GAP;
  FbtnAceptar.Default := True;
  FbtnAceptar.OnClick := AceptarClick;
  FbtnCancelar := TcxButton.Create(Self);
  FbtnCancelar.Parent     := pnlBot;
  FbtnCancelar.Caption    := 'Cancelar';
  FbtnCancelar.Width      := 110;
  FbtnCancelar.Height     := 28;
  FbtnCancelar.Top        := 8;
  FbtnCancelar.Left       := ClientWidth - 110 - MARGEN;
  FbtnCancelar.Cancel     := True;
  FbtnCancelar.ModalResult := mrCancel;
end;

procedure TfrmModalFiltroArt.CargarTemporadas(const aPreCsv: string);
var
  qry: TUniQuery;
  pre: TStringList;
  it: TcxCheckListBoxItem;
begin
  pre := TStringList.Create;
  qry := TUniQuery.Create(nil);
  try
    pre.Delimiter       := ';';
    pre.StrictDelimiter := True;
    pre.DelimitedText   := aPreCsv;
    qry.Connection := FConn;
    qry.SQL.Text :=
      'SELECT PV FROM fza_propiedades_valores ' +
      ' WHERE ID_PROP_PV = ''TEMPORADA'' AND ESACTIVO_PV = ''S'' ' +
      ' ORDER BY PV';
    qry.Open;
    while not qry.Eof do
    begin
      it := FclbTemporada.Items.Add;
      it.Text := qry.FieldByName('PV').AsString;
      if pre.IndexOf(it.Text) >= 0 then
        it.State := cbsChecked
      else
        it.State := cbsUnchecked;
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
    FreeAndNil(pre);
  end;
end;

procedure TfrmModalFiltroArt.CargarProveedores(const aPreCsv: string);
var
  qry: TUniQuery;
  pre: TStringList;
  it: TcxCheckListBoxItem;
  cod: string;
begin
  FCodProv.Clear;
  pre := TStringList.Create;
  qry := TUniQuery.Create(nil);
  try
    pre.Delimiter       := ';';
    pre.StrictDelimiter := True;
    pre.DelimitedText   := aPreCsv;
    qry.Connection := FConn;
    qry.SQL.Text :=
      'SELECT CODIGO_PRV_PRV, ' +
      '       COALESCE(NULLIF(RAZON_SOCIAL_PRV, ''''), NOMBRE_PRV, ' +
      '                CODIGO_PRV_PRV) AS NOM ' +
      '  FROM fza_proveedores ' +
      ' WHERE ESACTIVO_PRV = ''S'' ' +
      ' ORDER BY NOM, CODIGO_PRV_PRV';
    qry.Open;
    while not qry.Eof do
    begin
      cod := qry.FieldByName('CODIGO_PRV_PRV').AsString;
      it := FclbProveedor.Items.Add;
      it.Text := qry.FieldByName('NOM').AsString + ' (' + cod + ')';
      if pre.IndexOf(cod) >= 0 then
        it.State := cbsChecked
      else
        it.State := cbsUnchecked;
      FCodProv.Add(cod);
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
    FreeAndNil(pre);
  end;
end;

procedure TfrmModalFiltroArt.CargarFamilias(const aPreCsv: string);
var
  qry: TUniQuery;
  pre: TStringList;
  it: TcxCheckListBoxItem;
  cod: string;
begin
  FCodFam.Clear;
  pre := TStringList.Create;
  qry := TUniQuery.Create(nil);
  try
    pre.Delimiter       := ';';
    pre.StrictDelimiter := True;
    pre.DelimitedText   := aPreCsv;
    qry.Connection := FConn;
    qry.SQL.Text :=
      'SELECT CODIGO_FAM_FAM, ' +
      '       COALESCE(NULLIF(DESCRIPCION_FAM, ''''), NOMBRE_FAM_FAM, ' +
      '                CODIGO_FAM_FAM) AS NOM ' +
      '  FROM fza_articulos_familias ' +
      ' WHERE ESACTIVO_FAM = ''S'' ' +
      ' ORDER BY NOM, CODIGO_FAM_FAM';
    qry.Open;
    while not qry.Eof do
    begin
      cod := qry.FieldByName('CODIGO_FAM_FAM').AsString;
      it := FclbFamilia.Items.Add;
      it.Text := qry.FieldByName('NOM').AsString + ' (' + cod + ')';
      if pre.IndexOf(cod) >= 0 then
        it.State := cbsChecked
      else
        it.State := cbsUnchecked;
      FCodFam.Add(cod);
      qry.Next;
    end;
    qry.Close;
  finally
    FreeAndNil(qry);
    FreeAndNil(pre);
  end;
end;

function TfrmModalFiltroArt.CsvMarcados(AClb: TcxCheckListBox;
  ACodigos: TStringList): string;
var
  i: Integer;
  val: string;
begin
  // Para temporada (ACodigos=nil) el valor es el propio texto del item;
  // para proveedor/familia es el codigo alineado por indice.
  Result := '';
  for i := 0 to AClb.Items.Count - 1 do
    if AClb.Items[i].State = cbsChecked then
    begin
      if (ACodigos <> nil) and (i < ACodigos.Count) then
        val := ACodigos[i]
      else
        val := AClb.Items[i].Text;
      if Result <> '' then Result := Result + ';';
      Result := Result + val;
    end;
end;

procedure TfrmModalFiltroArt.ActualizarResultado;
var
  n: Integer;
begin
  if not Assigned(FContar) then Exit;
  Screen.Cursor := crHourGlass;
  try
    n := FContar(CsvMarcados(FclbTemporada, nil),
                 CsvMarcados(FclbProveedor, FCodProv),
                 CsvMarcados(FclbFamilia, FCodFam));
  finally
    Screen.Cursor := crDefault;
  end;
  FlblResultado.Caption := Format('Se cargar' + #225 + 'n %d art' + #237 +
                                  'culos (l' + #237 + 'mite %d).',
                                  [n, FUmbral]);
  if n > FUmbral then
    FlblResultado.Style.TextColor := clRed
  else
    FlblResultado.Style.TextColor := clGreen;
end;

procedure TfrmModalFiltroArt.CalcularClick(Sender: TObject);
begin
  ActualizarResultado;
end;

procedure TfrmModalFiltroArt.AceptarClick(Sender: TObject);
var
  n: Integer;
  bSeguir: Boolean;
begin
  bSeguir := True;
  if Assigned(FContar) then
  begin
    Screen.Cursor := crHourGlass;
    try
      n := FContar(CsvMarcados(FclbTemporada, nil),
                   CsvMarcados(FclbProveedor, FCodProv),
                   CsvMarcados(FclbFamilia, FCodFam));
    finally
      Screen.Cursor := crDefault;
    end;
    if n > FUmbral then
      bSeguir := MessageDlg(
        Format('A' + #250 + 'n se cargar' + #225 + 'n %d art' + #237 +
               'culos, por encima del l' + #237 + 'mite recomendado de %d.' +
               sLineBreak + 'La carga puede tardar. ' + #191 + 'Continuar ' +
               'igualmente?', [n, FUmbral]),
        mtWarning, [mbYes, mbNo], 0) = mrYes;
  end;
  if bSeguir then
    ModalResult := mrOk;
end;

class function TfrmModalFiltroArt.Ejecutar(AOwner: TComponent;
  AConn: TUniConnection; AUmbral: Integer;
  const APreTempCsv, APrePrvCsv, APreFamCsv: string;
  AContar: TContarArticulosFunc;
  out aTempCsv, aPrvCsv, aFamCsv: string): Boolean;
var
  frm: TfrmModalFiltroArt;
begin
  // Si cancela, devolvemos lo recibido para que el Mto cargue el filtro base.
  aTempCsv := APreTempCsv;
  aPrvCsv  := APrePrvCsv;
  aFamCsv  := APreFamCsv;
  Result := False;
  frm := TfrmModalFiltroArt.Create(AOwner);
  try
    frm.FConn   := AConn;
    frm.FUmbral := AUmbral;
    frm.FContar := AContar;
    frm.FlblCabecera.Caption :=
      'Hay demasiados art' + #237 + 'culos para cargarlos de golpe (m' + #225 +
      's de ' + IntToStr(AUmbral) + '). Marque temporada, proveedor y/o ' +
      'familia para acotar la carga; pulse "Calcular n' + #186 + '" para ver ' +
      'cu' + #225 + 'ntos quedar' + #237 + 'an. "Aceptar" carga la selecci' +
      #243 + 'n; "Cancelar" carga el filtro por defecto.';
    frm.CargarTemporadas(APreTempCsv);
    frm.CargarProveedores(APrePrvCsv);
    frm.CargarFamilias(APreFamCsv);
    frm.ActualizarResultado;
    if frm.ShowModal = mrOk then
    begin
      aTempCsv := frm.CsvMarcados(frm.FclbTemporada, nil);
      aPrvCsv  := frm.CsvMarcados(frm.FclbProveedor, frm.FCodProv);
      aFamCsv  := frm.CsvMarcados(frm.FclbFamilia, frm.FCodFam);
      Result := True;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

end.
