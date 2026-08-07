unit frmStock;

{
  Pantalla principal: consulta movil de stock de Factuzam.

  Funcionalidades:
  - Buscar stock por codigo de articulo (manual o por escaner de camara)
  - Mostrar resultados en TStringGrid con tallas como columnas
  - Tres modos de agrupacion (rotativo con un boton):
      1. Por Color    -> filas = colores, columnas = tallas
      2. Por Almacen  -> filas = almacenes, columnas = tallas
      3. Detalle      -> filas = "Color . Almacen", columnas = tallas
  - Adapta tamano de fila/fuente a movil
  - Recalcula ancho de columnas al redimensionar (rotar pantalla, etc.)
  - Boton para abrir el escaner de codigos de barras EAN-13
  - Foto representativa del articulo, con lado mayor de 300 px, en la
    esquina superior derecha
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Edit,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Grid, FMX.Grid.Style,
  FMX.ScrollBox, FMX.TextLayout, FMX.Objects, FMX.Graphics, System.Math,
  uApiClient, uSettings, System.Rtti;

type
  TAgrupacion = (agColor, agAlmacen);

  TFormStock = class(TForm)
    pnlTop: TPanel;
    edtArticulo: TEdit;
    btnEscanear: TButton;
    btnConsultar: TButton;
    btnAgrupar: TButton;
    btnSalir: TButton;
    pnlBottom: TPanel;
    lblTotal: TLabel;
    grdStock: TStringGrid;
    pnlArticulo: TPanel;
    pnlFoto: TPanel;
    imgFoto: TImage;
    lblFoto: TLabel;
    lblArticulo: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnConsultarClick(Sender: TObject);
    procedure btnAgruparClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure btnEscanearClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure grdStockCellClick(const Column: TColumn; const Row: Integer);
  private
    FUltimo: TStockResultado;
    FTieneDatos: Boolean;
    FAgrupacion: TAgrupacion;
    FNumColumnasTallas: Integer;
    FExpandidos: TList<string>;
    procedure RellenarGrid;
    procedure ActualizarTextoBotonAgrupar;
    procedure AjustarAnchoColumnas;
    procedure ConfigurarEscalaParaMovil;
    procedure LimpiarFoto;
    procedure CargarFoto300(const Stock: TStockResultado);
    /// Callback que recibe el codigo desde el formulario de escaneo
    procedure OnCodigoEscaneado(const Codigo: string);
  end;

var
  FormStock: TFormStock;

implementation

{$R *.fmx}

uses
  frmLogin,
  frmEscaner;

const
  LADO_MAXIMO_FOTO = 300;

procedure TFormStock.FormShow(Sender: TObject);
begin
  if FExpandidos = nil then
    FExpandidos := TList<string>.Create;
  FExpandidos.Clear;
  FAgrupacion := agColor;
  FTieneDatos := False;
  FNumColumnasTallas := 0;
  FUltimo := Default(TStockResultado);
  grdStock.RowCount := 0;
  grdStock.ClearColumns;
  ActualizarTextoBotonAgrupar;
  ConfigurarEscalaParaMovil;
  LimpiarFoto;
  lblArticulo.Text := 'Introduce o escanea un articulo.';
  lblTotal.Text := '';
end;

procedure TFormStock.grdStockCellClick(const Column: TColumn; const Row: Integer);
var
  TextoCelda, ClavePadre: string;
begin
  if (Column.Index = 0) and (Row < grdStock.RowCount - 1) then
  begin
    TextoCelda := grdStock.Cells[0, Row];
    if TextoCelda.StartsWith('▶ ') or TextoCelda.StartsWith('▼ ') then
    begin
      ClavePadre := TextoCelda.Substring(2);
      if FExpandidos.Contains(ClavePadre) then
        FExpandidos.Remove(ClavePadre) // Si estaba abierto, lo cerramos
      else
        FExpandidos.Add(ClavePadre);   // Si estaba cerrado, lo abrimos
      RellenarGrid;
    end;
  end;
end;

procedure TFormStock.ConfigurarEscalaParaMovil;
begin
  // Mas alto y mas grande en movil para que sea comodo al tacto
  {$IFDEF ANDROID}
  grdStock.RowHeight := 56;
  grdStock.TextSettings.Font.Size := 16;
  pnlTop.Height := 72;
  pnlBottom.Height := 56;
  edtArticulo.TextSettings.Font.Size := 16;
  lblTotal.TextSettings.Font.Size := 16;
  pnlArticulo.Height := 124;
  pnlFoto.Width := 120;
  {$ELSE}
  grdStock.RowHeight := 28;
  pnlArticulo.Height := 112;
  pnlFoto.Width := 108;
  {$ENDIF}
end;

procedure TFormStock.LimpiarFoto;
begin
  imgFoto.Bitmap.SetSize(1, 1);
  imgFoto.Bitmap.Clear(0);
  lblFoto.Text := 'Sin foto'#13#10'300 px';
  lblFoto.Visible := True;
end;

procedure TFormStock.CargarFoto300(const Stock: TStockResultado);
var
  Alto, Ancho: Integer;
  Bytes: TBytes;
  Miniatura: TBitmap;
  Stream: TBytesStream;
begin
  LimpiarFoto;
  Bytes := TApiClient.DescargarFoto300(Stock);
  if Length(Bytes) = 0 then
    Exit;

  Stream := TBytesStream.Create(Bytes);
  try
    try
      imgFoto.Bitmap.LoadFromStream(Stream);
      if Max(imgFoto.Bitmap.Width, imgFoto.Bitmap.Height) >
         LADO_MAXIMO_FOTO then
      begin
        if imgFoto.Bitmap.Width >= imgFoto.Bitmap.Height then
        begin
          Ancho := LADO_MAXIMO_FOTO;
          Alto := Max(1, Round(imgFoto.Bitmap.Height * LADO_MAXIMO_FOTO /
            imgFoto.Bitmap.Width));
        end
        else
        begin
          Alto := LADO_MAXIMO_FOTO;
          Ancho := Max(1, Round(imgFoto.Bitmap.Width * LADO_MAXIMO_FOTO /
            imgFoto.Bitmap.Height));
        end;
        Miniatura := imgFoto.Bitmap.CreateThumbnail(Ancho, Alto);
        try
          imgFoto.Bitmap.Assign(Miniatura);
        finally
          Miniatura.Free;
        end;
      end;
      lblFoto.Visible := False;
    except
      LimpiarFoto;
      lblFoto.Text := 'Foto no valida';
    end;
  finally
    Stream.Free;
  end;
end;

procedure TFormStock.FormDestroy(Sender: TObject);
begin
  if Assigned(FExpandidos) then
    FExpandidos.Free;
end;

procedure TFormStock.FormResize(Sender: TObject);
begin
  // Reajustar anchos al rotar el movil o redimensionar la ventana
  if FTieneDatos then
    AjustarAnchoColumnas;
end;

procedure TFormStock.AjustarAnchoColumnas;
var
  Layout: TTextLayout;
  i, Fila: Integer;
  AnchoCol0, AnchoTotal, AnchoDisponible, SumaAnchos: Single;
  AnchosTallas: array of Single;
  MargenCelda: Single;
begin
  if grdStock.ColumnCount = 0 then Exit;
  if FNumColumnasTallas = 0 then Exit;

  // Margen extra para que el texto y las flechas no toquen los bordes
  MargenCelda := 26;

  // Creamos el medidor de texto con la fuente de tu grid
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.Font.Assign(grdStock.TextSettings.Font);

    // --- 1. Medir la Columna 0 (Almacén / Color) ---
    AnchoCol0 := 0;
    Layout.Text := grdStock.Columns[0].Header;
    AnchoCol0 := Max(AnchoCol0, Layout.TextWidth + MargenCelda);

    for Fila := 0 to grdStock.RowCount - 1 do
    begin
      Layout.Text := grdStock.Cells[0, Fila];
      AnchoCol0 := Max(AnchoCol0, Layout.TextWidth + MargenCelda);
    end;

    // --- 2. Medir la Columna Total (Última) ---
    AnchoTotal := 0;
    Layout.Text := grdStock.Columns[FNumColumnasTallas + 1].Header;
    AnchoTotal := Max(AnchoTotal, Layout.TextWidth + MargenCelda);

    for Fila := 0 to grdStock.RowCount - 1 do
    begin
      Layout.Text := grdStock.Cells[FNumColumnasTallas + 1, Fila];
      AnchoTotal := Max(AnchoTotal, Layout.TextWidth + MargenCelda);
    end;

    // --- 3. Medir las Columnas de Tallas (una a una) ---
    SetLength(AnchosTallas, FNumColumnasTallas);
    SumaAnchos := AnchoCol0 + AnchoTotal;

    for i := 1 to FNumColumnasTallas do
    begin
      AnchosTallas[i-1] := 0;
      Layout.Text := grdStock.Columns[i].Header;
      AnchosTallas[i-1] := Max(AnchosTallas[i-1], Layout.TextWidth + MargenCelda);

      for Fila := 0 to grdStock.RowCount - 1 do
      begin
        Layout.Text := grdStock.Cells[i, Fila];
        AnchosTallas[i-1] := Max(AnchosTallas[i-1], Layout.TextWidth + MargenCelda);
      end;

      // Ancho mínimo de 50px para poder tocarlas bien con el dedo
      AnchosTallas[i-1] := Max(AnchosTallas[i-1], 50);
      SumaAnchos := SumaAnchos + AnchosTallas[i-1];
    end;

    // --- 4. Distribuir el espacio sobrante ---
    AnchoDisponible := grdStock.Width - 20; // 20px para la barra de scroll

    // Si la pantalla es ancha y sobra espacio, se lo damos TODO a la primera columna
    if SumaAnchos < AnchoDisponible then
      AnchoCol0 := AnchoCol0 + (AnchoDisponible - SumaAnchos);

    // --- 5. Aplicar los anchos finales al Grid ---
    grdStock.Columns[0].Width := AnchoCol0;
    for i := 1 to FNumColumnasTallas do
      grdStock.Columns[i].Width := AnchosTallas[i-1];
    grdStock.Columns[FNumColumnasTallas + 1].Width := AnchoTotal;

  finally
    Layout.Free;
  end;
end;

procedure TFormStock.ActualizarTextoBotonAgrupar;
begin
  if FAgrupacion = agColor then
    btnAgrupar.Text := 'Por almacén'
  else
    btnAgrupar.Text := 'Por color';
end;

procedure TFormStock.btnEscanearClick(Sender: TObject);
begin
  if not Assigned(FormEscaner) then
    Application.CreateForm(TFormEscaner, FormEscaner);

  FormEscaner.OnCodigoEscaneado := OnCodigoEscaneado;
  FormEscaner.Show;
end;

procedure TFormStock.OnCodigoEscaneado(const Codigo: string);
begin
  // Recibimos el codigo desde el escaner y lanzamos consulta
  edtArticulo.Text := Codigo;
  btnConsultarClick(nil);
end;

procedure TFormStock.btnConsultarClick(Sender: TObject);
var
  TextoArticulo: string;
begin
  if Trim(edtArticulo.Text) = '' then
  begin
    lblTotal.Text := 'Introduce un código de artículo.';
    Exit;
  end;

  lblTotal.Text := 'Consultando...';
  lblArticulo.Text := 'Consultando articulo...';
  LimpiarFoto;
  grdStock.RowCount := 0;
  grdStock.ClearColumns;
  Application.ProcessMessages;

  try
    FUltimo := TApiClient.ConsultarStock(Trim(edtArticulo.Text));
    FTieneDatos := True;
    RellenarGrid;
    lblTotal.Text := Format('Articulo %s  -  Total: %.0f uds.',
                            [FUltimo.Articulo, FUltimo.Total]);
    TextoArticulo := FUltimo.Articulo;
    if Trim(FUltimo.Descripcion) <> '' then
      TextoArticulo := TextoArticulo + sLineBreak + FUltimo.Descripcion;
    lblArticulo.Text := TextoArticulo + sLineBreak +
      Format('Total: %.0f uds.', [FUltimo.Total]);
    CargarFoto300(FUltimo);
  except
    on E: Exception do
    begin
      FTieneDatos := False;
      lblTotal.Text := 'Error: ' + E.Message;
      lblArticulo.Text := 'No se pudo consultar el articulo.';
      LimpiarFoto;
      grdStock.RowCount := 0;
      grdStock.ClearColumns;
    end;
  end;
end;

procedure TFormStock.btnAgruparClick(Sender: TObject);
begin
  // Solo alternamos entre dos modos ahora
  if FAgrupacion = agColor then
    FAgrupacion := agAlmacen
  else
    FAgrupacion := agColor;
  FExpandidos.Clear;
  ActualizarTextoBotonAgrupar;
  if FTieneDatos then
    RellenarGrid;
end;

procedure TFormStock.btnSalirClick(Sender: TObject);
begin
  TSettings.BorrarToken;
  TSettings.BorrarCredenciales;
  Close;
  if Assigned(FormLogin) then FormLogin.Show;
end;

procedure TFormStock.RellenarGrid;
var
  Tallas, Padres, Hijos: TList<string>;
  Item: TStockItem;
  Padre, Hijo, Talla, EncabezadoCol1: string;
  i, j: Integer;
  Col: TStringColumn;
  GranTotal, TotalFila, TotalCol: Double;

  // Diccionarios para acumular sumas
  SumPadres, SumHijos: TDictionary<string, TDictionary<string, Double>>;

  // Estructura para organizar las filas antes de pintarlas
  type
    TFilaVirtual = record
      EsPadre: Boolean;
      ClaveSuma: string;
      TituloVisible: string;
    end;
  var
    FilasVirtuales: TList<TFilaVirtual>;
    FilaV: TFilaVirtual;
    Sub: TDictionary<string, Double>;

  procedure Acumular(Dict: TDictionary<string, TDictionary<string, Double>>; const Clave, ATalla: string; AUnidades: Double);
  var D: TDictionary<string, Double>;
  begin
    if not Dict.TryGetValue(Clave, D) then
    begin
      D := TDictionary<string, Double>.Create;
      Dict.Add(Clave, D);
    end;
    if D.ContainsKey(ATalla) then D[ATalla] := D[ATalla] + AUnidades
    else D.Add(ATalla, AUnidades);
  end;

begin
  grdStock.BeginUpdate;
  try
    grdStock.RowCount := 0;
    grdStock.ClearColumns;
    FNumColumnasTallas := 0;

    if (not FTieneDatos) or (Length(FUltimo.Items) = 0) then Exit;

    Tallas := TList<string>.Create;
    Padres := TList<string>.Create;
    Hijos  := TList<string>.Create;
    SumPadres := TDictionary<string, TDictionary<string, Double>>.Create;
    SumHijos  := TDictionary<string, TDictionary<string, Double>>.Create;
    FilasVirtuales := TList<TFilaVirtual>.Create;

    try
      // --- 1. RECOLECTAR DATOS Y SUMAR ---
      for Item in FUltimo.Items do
      begin
        if FAgrupacion = agColor then
        begin
          Padre := Item.Color;
          Hijo  := Item.Almacen;
          EncabezadoCol1 := 'Color';
        end
        else
        begin
          Padre := Item.Almacen;
          Hijo  := Item.Color;
          EncabezadoCol1 := 'Almacen';
        end;
        Talla := Item.Talla;

        if not Tallas.Contains(Talla) then Tallas.Add(Talla);
        if not Padres.Contains(Padre) then Padres.Add(Padre);

        Acumular(SumPadres, Padre, Talla, Item.Unidades);
        Acumular(SumHijos, Padre + '|' + Hijo, Talla, Item.Unidades);
      end;

      Tallas.Sort;
      Padres.Sort;
      FNumColumnasTallas := Tallas.Count;

      // --- 2. ORDENAR JERARQUÍA (Filas visibles) ---
      for Padre in Padres do
      begin
        // Fila Padre
        FilaV.EsPadre := True;
        FilaV.ClaveSuma := Padre;
        if FExpandidos.Contains(Padre) then FilaV.TituloVisible := '▼ ' + Padre
        else FilaV.TituloVisible := '▶ ' + Padre;

        FilasVirtuales.Add(FilaV);

        // Si el padre está tocado (abierto), metemos sus hijos debajo
        if FExpandidos.Contains(Padre) then
        begin
          Hijos.Clear;
          for Item in FUltimo.Items do
          begin
            if ((FAgrupacion = agColor) and (Item.Color = Padre)) or
               ((FAgrupacion = agAlmacen) and (Item.Almacen = Padre)) then
            begin
              if FAgrupacion = agColor then Hijo := Item.Almacen else Hijo := Item.Color;
              if not Hijos.Contains(Hijo) then Hijos.Add(Hijo);
            end;
          end;
          Hijos.Sort;

          for Hijo in Hijos do
          begin
            FilaV.EsPadre := False;
            FilaV.ClaveSuma := Padre + '|' + Hijo;
            FilaV.TituloVisible := '    ↳ ' + Hijo; // Indentación visual
            FilasVirtuales.Add(FilaV);
          end;
        end;
      end;

      // --- 3. CREAR COLUMNAS ---
      Col := TStringColumn.Create(grdStock);
      Col.Parent := grdStock;
      Col.Header := EncabezadoCol1;

      for Talla in Tallas do
      begin
        Col := TStringColumn.Create(grdStock);
        Col.Parent := grdStock;
        Col.Header := Talla;
      end;

      Col := TStringColumn.Create(grdStock);
      Col.Parent := grdStock;
      Col.Header := 'Total';

      // --- 4. PINTAR EL GRID ---
      grdStock.RowCount := FilasVirtuales.Count + 1;
      GranTotal := 0;

      for i := 0 to FilasVirtuales.Count - 1 do
      begin
        FilaV := FilasVirtuales[i];
        grdStock.Cells[0, i] := FilaV.TituloVisible;
        TotalFila := 0;

        if FilaV.EsPadre then SumPadres.TryGetValue(FilaV.ClaveSuma, Sub)
        else SumHijos.TryGetValue(FilaV.ClaveSuma, Sub);

        for j := 0 to Tallas.Count - 1 do
        begin
          Talla := Tallas[j];
          if (Sub <> nil) and Sub.ContainsKey(Talla) then
          begin
            grdStock.Cells[j + 1, i] := FormatFloat('0.##', Sub[Talla]);
            TotalFila := TotalFila + Sub[Talla];
          end
          else grdStock.Cells[j + 1, i] := '';
        end;

        grdStock.Cells[Tallas.Count + 1, i] := FormatFloat('0.##', TotalFila);

        // El Gran Total final SOLO se suma con las filas padre, para no contar doble
        if FilaV.EsPadre then GranTotal := GranTotal + TotalFila;
      end;

      // --- 5. FILA TOTAL ---
      grdStock.Cells[0, FilasVirtuales.Count] := 'TOTAL';
      for j := 0 to Tallas.Count - 1 do
      begin
        TotalCol := 0;
        Talla := Tallas[j];
        for Padre in Padres do
        begin
          if SumPadres.TryGetValue(Padre, Sub) and Sub.ContainsKey(Talla) then
            TotalCol := TotalCol + Sub[Talla];
        end;
        grdStock.Cells[j + 1, FilasVirtuales.Count] :=
                                                  FormatFloat('0.##', TotalCol);
      end;
      grdStock.Cells[Tallas.Count + 1, FilasVirtuales.Count] :=
                                                 FormatFloat('0.##', GranTotal);
      AjustarAnchoColumnas;
    finally
      for Sub in SumPadres.Values do Sub.Free;
      for Sub in SumHijos.Values do Sub.Free;
      SumPadres.Free;
      SumHijos.Free;
      FilasVirtuales.Free;
      Hijos.Free;
      Padres.Free;
      Tallas.Free;
    end;
  finally
    grdStock.EndUpdate;
  end;
end;

end.
