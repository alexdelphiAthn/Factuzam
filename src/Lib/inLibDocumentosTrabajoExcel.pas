{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDocumentosTrabajoExcel                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exporta un Documento de Trabajo a Excel con una foto de 300 x 300 por     }
{    cada línea, resuelta por artículo y SKU.                                  }
{******************************************************************************}
unit inLibDocumentosTrabajoExcel;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections, Data.DB, Vcl.Graphics, cxGraphics,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetContainers, dxSpreadSheetGraphics, dxSpreadSheetStyles,
  dxCoreGraphics, dxHashUtils, dxGDIPlusClasses, dxSmartImage,
  inLibDevExcel, inLibFotos;

procedure ExportarDocumentoTrabajoExcel(
  ASheetControl: TdxSpreadSheet;
  const QCabecera, QLineas: TDataSet);

implementation

const
  fidDtr = 'ID_DTR';
  ftituloDtr = 'TITULO_DTR';
  ftipoDtr = 'TIPO_DTR';
  festadoDtr = 'ESTADO_DTR';
  fcodEmpDtr = 'CODIGO_EMP_DTR';
  fcodAlmDtr = 'CODIGO_ALM_DTR';
  fusuarioDtr = 'USUARIO_DTR';
  finstanteDtr = 'INSTANTE_DOCUMENTO_DTR';
  flineaDtl = 'LINEA_DTL';
  fcodArtDtl = 'CODIGO_ART_DTL';
  fcodUnidadDtl = 'CODIGO_UNIDAD_DTL';
  fcodAlmDtl = 'CODIGO_ALM_DTL';
  fdescripcionArtDtl = 'DESCRIPCION_ARTICULO_DTL';
  frefProveedor = 'REF_PROVEEDOR';
  fcodFamilia = 'CODIGO_FAM_ART';
  ffamilia = 'DESCRIPCION_FAM';
  fcodProveedor = 'CODIGO_PRV_AP';
  fproveedor = 'NOMBRE_PRV';
  ftemporada = 'TEMPORADA_ART';
  fcodTarifa = 'CODIGO_TAR_ARTTAR';
  ftarifa = 'NOMBRE_TAR_TAR';
  fprecioTarifa = 'PRECIO_FINAL_ARTTAR';
  fdescripcionUnidadDtl = 'DESCRIPCION_UNIDAD_DTL';
  fcantidadStockDtl = 'CANTIDAD_STOCK_DTL';
  fcantidadDtl = 'CANTIDAD_DTL';
  forigenDtl = 'ORIGEN_DTL';
  finstanteStockDtl = 'INSTANTE_STOCK_DTL';
  cTamanoFoto = 300;
  cFormatoCantidad = '#,##0.##;-#,##0.##;0';
  cFormatoPrecio = '#,##0.00" €"';
  cColorCabecera = $00666666;

procedure ExportarDocumentoTrabajoExcel(
  ASheetControl: TdxSpreadSheet;
  const QCabecera, QLineas: TDataSet);
const
  COL_FOTO = 0;
  COL_LINEA = 1;
  COL_ARTICULO = 2;
  COL_SKU = 3;
  COL_ALMACEN = 4;
  COL_DESCRIPCION_ART = 5;
  COL_MODELO = 6;
  COL_FAMILIA = 7;
  COL_PROVEEDOR = 8;
  COL_TEMPORADA = 9;
  COL_TARIFA = 10;
  COL_PRECIO_TARIFA = 11;
  COL_DESCRIPCION_SKU = 12;
  COL_STOCK = 13;
  COL_CANTIDAD = 14;
  COL_ORIGEN = 15;
  COL_INSTANTE_STOCK = 16;
  COL_MAX = COL_INSTANTE_STOCK;
var
  Sheet: TdxSpreadSheetTableView;
  oFotosLinea: TDictionary<string, TFotoInfo>;
  iRow: Integer;
  BmLineas: TBookmark;

  function TextoCodigoNombre(const ACodigo, ANombre: string): string;
  begin
    Result := Trim(ACodigo);
    if Trim(ANombre) <> '' then
    begin
      if Result <> '' then
      begin
        Result := Result + ' - ';
      end;
      Result := Result + Trim(ANombre);
    end;
  end;

  procedure EscribirFecha(AFila, AColumna: Integer; ACampo: TField);
  begin
    if (ACampo <> nil) and (not ACampo.IsNull) then
    begin
      W(Sheet, AFila, AColumna, ACampo.AsDateTime);
      Sheet.Cells[AFila, AColumna].Style.DataFormat.FormatCode :=
        'dd/mm/yyyy hh:mm';
    end;
  end;

  procedure IncrustarFoto(AFila: Integer; const ACodArt, ACodSku: string);
  var
    info: TFotoInfo;
    sClave: string;
    sRuta: string;
    img: TdxSmartImage;
    Pic: TdxSpreadSheetPictureContainer;
    Celda: TdxSpreadSheetCell;
    iAncho: Integer;
    iAlto: Integer;
    iIzquierda: Integer;
    iArriba: Integer;
  begin
    sClave := ACodArt + #1 + ACodSku;
    if not oFotosLinea.TryGetValue(sClave, info) then
    begin
      info := oFotos.Resolver(ACodArt, ACodSku);
      oFotosLinea.Add(sClave, info);
    end;
    sRuta := oFotos.RutaFoto(info, frPx300);
    if (sRuta <> '') and FileExists(sRuta) then
    begin
      img := TdxSmartImage.Create;
      try
        img.LoadFromFile(sRuta);
        iAncho := img.Width;
        iAlto := img.Height;
        if (iAncho > cTamanoFoto) or (iAlto > cTamanoFoto) then
        begin
          if iAncho >= iAlto then
          begin
            iAlto := Round(iAlto * cTamanoFoto / iAncho);
            iAncho := cTamanoFoto;
          end
          else
          begin
            iAncho := Round(iAncho * cTamanoFoto / iAlto);
            iAlto := cTamanoFoto;
          end;
        end;
        iIzquierda := (cTamanoFoto - iAncho) div 2;
        iArriba := (cTamanoFoto - iAlto) div 2;
        Celda := Sheet.CreateCell(AFila, COL_FOTO);
        Pic := Sheet.Containers.Add(TdxSpreadSheetPictureContainer)
          as TdxSpreadSheetPictureContainer;
        Pic.Picture.Image := img;
        Pic.RelativeResize := True;
        Pic.AnchorType := catOneCell;
        Pic.AnchorPoint1.Cell := Celda;
        Pic.AnchorPoint1.Offset := Point(iIzquierda, iArriba);
        Pic.AnchorPoint2.Cell := Celda;
        Pic.AnchorPoint2.Offset := Point(iIzquierda + iAncho,
                                         iArriba + iAlto);
      finally
        FreeAndNil(img);
      end;
    end
    else
    begin
      W(Sheet, AFila, COL_FOTO, 'Sin foto', False, ssahCenter);
    end;
  end;

  procedure EscribirCabeceraLineas;
  var
    c: Integer;
  begin
    W(Sheet, iRow, COL_FOTO, 'Foto 300 x 300', True, ssahCenter);
    W(Sheet, iRow, COL_LINEA, 'Línea', True, ssahCenter);
    W(Sheet, iRow, COL_ARTICULO, 'Artículo', True, ssahCenter);
    W(Sheet, iRow, COL_SKU, 'SKU', True, ssahCenter);
    W(Sheet, iRow, COL_ALMACEN, 'Almacén', True, ssahCenter);
    W(Sheet, iRow, COL_DESCRIPCION_ART, 'Descripción artículo',
      True, ssahCenter);
    W(Sheet, iRow, COL_MODELO, 'Modelo', True, ssahCenter);
    W(Sheet, iRow, COL_FAMILIA, 'Familia', True, ssahCenter);
    W(Sheet, iRow, COL_PROVEEDOR, 'Proveedor', True, ssahCenter);
    W(Sheet, iRow, COL_TEMPORADA, 'Temporada', True, ssahCenter);
    W(Sheet, iRow, COL_TARIFA, 'Tarifa', True, ssahCenter);
    W(Sheet, iRow, COL_PRECIO_TARIFA, 'Precio tarifa',
      True, ssahRight);
    W(Sheet, iRow, COL_DESCRIPCION_SKU, 'Descripción unidad',
      True, ssahCenter);
    W(Sheet, iRow, COL_STOCK, 'Stock', True, ssahRight);
    W(Sheet, iRow, COL_CANTIDAD, 'Cantidad', True, ssahRight);
    W(Sheet, iRow, COL_ORIGEN, 'Origen', True, ssahCenter);
    W(Sheet, iRow, COL_INSTANTE_STOCK, 'Instante stock',
      True, ssahCenter);
    for c := 0 to COL_MAX do
    begin
      Sheet.Cells[iRow, c].Style.Font.Color := clWhite;
      Sheet.Cells[iRow, c].Style.Brush.BackgroundColor := cColorCabecera;
      Sheet.Cells[iRow, c].Style.Borders[bBottom].Style := sscbsThin;
    end;
  end;

  procedure EscribirLinea;
  begin
    Sheet.CreateCell(iRow, COL_FOTO);
    Sheet.Rows[iRow].Size := cTamanoFoto;
    IncrustarFoto(iRow,
                  QLineas.FieldByName(fcodArtDtl).AsString,
                  QLineas.FieldByName(fcodUnidadDtl).AsString);
    W(Sheet, iRow, COL_LINEA,
      QLineas.FieldByName(flineaDtl).AsString, False, ssahCenter);
    W(Sheet, iRow, COL_ARTICULO,
      QLineas.FieldByName(fcodArtDtl).AsString);
    W(Sheet, iRow, COL_SKU,
      QLineas.FieldByName(fcodUnidadDtl).AsString);
    W(Sheet, iRow, COL_ALMACEN,
      QLineas.FieldByName(fcodAlmDtl).AsString);
    W(Sheet, iRow, COL_DESCRIPCION_ART,
      QLineas.FieldByName(fdescripcionArtDtl).AsString);
    if QLineas.FindField(frefProveedor) <> nil then
    begin
      W(Sheet, iRow, COL_MODELO,
        QLineas.FieldByName(frefProveedor).AsString);
    end;
    W(Sheet, iRow, COL_FAMILIA,
      TextoCodigoNombre(
        QLineas.FieldByName(fcodFamilia).AsString,
        QLineas.FieldByName(ffamilia).AsString));
    W(Sheet, iRow, COL_PROVEEDOR,
      TextoCodigoNombre(
        QLineas.FieldByName(fcodProveedor).AsString,
        QLineas.FieldByName(fproveedor).AsString));
    W(Sheet, iRow, COL_TEMPORADA,
      QLineas.FieldByName(ftemporada).AsString);
    W(Sheet, iRow, COL_TARIFA,
      TextoCodigoNombre(
        QLineas.FieldByName(fcodTarifa).AsString,
        QLineas.FieldByName(ftarifa).AsString));
    W(Sheet, iRow, COL_PRECIO_TARIFA,
      QLineas.FieldByName(fprecioTarifa).AsFloat, False, ssahRight);
    Sheet.Cells[iRow, COL_PRECIO_TARIFA].Style.DataFormat.FormatCode :=
      cFormatoPrecio;
    W(Sheet, iRow, COL_DESCRIPCION_SKU,
      QLineas.FieldByName(fdescripcionUnidadDtl).AsString);
    W(Sheet, iRow, COL_STOCK,
      QLineas.FieldByName(fcantidadStockDtl).AsFloat, False, ssahRight);
    Sheet.Cells[iRow, COL_STOCK].Style.DataFormat.FormatCode :=
      cFormatoCantidad;
    W(Sheet, iRow, COL_CANTIDAD,
      QLineas.FieldByName(fcantidadDtl).AsFloat, False, ssahRight);
    Sheet.Cells[iRow, COL_CANTIDAD].Style.DataFormat.FormatCode :=
      cFormatoCantidad;
    W(Sheet, iRow, COL_ORIGEN,
      QLineas.FieldByName(forigenDtl).AsString, False, ssahCenter);
    EscribirFecha(iRow, COL_INSTANTE_STOCK,
                  QLineas.FindField(finstanteStockDtl));
  end;

begin
  ASheetControl.ClearAll;
  Sheet := ASheetControl.AddSheet('Documento de trabajo',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  oFotosLinea := TDictionary<string, TFotoInfo>.Create;
  Sheet.BeginUpdate;
  try
    iRow := 1;
    W(Sheet, iRow, 0, 'DOCUMENTO DE TRABAJO', True);
    Sheet.Cells[iRow, 0].Style.Font.Size := 16;
    Merge(Sheet, iRow, 0, COL_MAX + 1, 1);
    Inc(iRow, 2);
    W(Sheet, iRow, 0, 'ID:', True);
    W(Sheet, iRow, 1, QCabecera.FieldByName(fidDtr).AsLargeInt);
    W(Sheet, iRow, 3, 'Título:', True);
    W(Sheet, iRow, 4, QCabecera.FieldByName(ftituloDtr).AsString);
    Merge(Sheet, iRow, 4, 4, 1);
    Inc(iRow);
    W(Sheet, iRow, 0, 'Tipo:', True);
    W(Sheet, iRow, 1, QCabecera.FieldByName(ftipoDtr).AsString);
    W(Sheet, iRow, 3, 'Estado:', True);
    W(Sheet, iRow, 4, QCabecera.FieldByName(festadoDtr).AsString);
    W(Sheet, iRow, 6, 'Propietario:', True);
    W(Sheet, iRow, 7, QCabecera.FieldByName(fusuarioDtr).AsString);
    Inc(iRow);
    W(Sheet, iRow, 0, 'Empresa:', True);
    W(Sheet, iRow, 1, QCabecera.FieldByName(fcodEmpDtr).AsString);
    W(Sheet, iRow, 3, 'Almacén:', True);
    W(Sheet, iRow, 4, QCabecera.FieldByName(fcodAlmDtr).AsString);
    W(Sheet, iRow, 6, 'Fecha:', True);
    EscribirFecha(iRow, 7, QCabecera.FindField(finstanteDtr));
    Inc(iRow, 2);
    EscribirCabeceraLineas;
    Inc(iRow);
    if (QLineas <> nil) and QLineas.Active and (not QLineas.IsEmpty) then
    begin
      BmLineas := QLineas.GetBookmark;
      QLineas.DisableControls;
      try
        QLineas.First;
        while not QLineas.Eof do
        begin
          EscribirLinea;
          Inc(iRow);
          QLineas.Next;
        end;
      finally
        if QLineas.BookmarkValid(BmLineas) then
        begin
          QLineas.GotoBookmark(BmLineas);
        end;
        QLineas.FreeBookmark(BmLineas);
        QLineas.EnableControls;
      end;
    end;
    Sheet.Columns[COL_FOTO].Size := cTamanoFoto;
    Sheet.Columns[COL_LINEA].Size := 55;
    Sheet.Columns[COL_ARTICULO].Size := 110;
    Sheet.Columns[COL_SKU].Size := 170;
    Sheet.Columns[COL_ALMACEN].Size := 80;
    Sheet.Columns[COL_DESCRIPCION_ART].Size := 220;
    Sheet.Columns[COL_MODELO].Size := 120;
    Sheet.Columns[COL_FAMILIA].Size := 160;
    Sheet.Columns[COL_PROVEEDOR].Size := 180;
    Sheet.Columns[COL_TEMPORADA].Size := 110;
    Sheet.Columns[COL_TARIFA].Size := 120;
    Sheet.Columns[COL_PRECIO_TARIFA].Size := 90;
    Sheet.Columns[COL_DESCRIPCION_SKU].Size := 180;
    Sheet.Columns[COL_STOCK].Size := 75;
    Sheet.Columns[COL_CANTIDAD].Size := 80;
    Sheet.Columns[COL_ORIGEN].Size := 80;
    Sheet.Columns[COL_INSTANTE_STOCK].Size := 125;
  finally
    Sheet.EndUpdate;
    FreeAndNil(oFotosLinea);
  end;
end;

end.
