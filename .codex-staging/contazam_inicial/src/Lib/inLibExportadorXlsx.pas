{******************************************************************************}
{                                                                              }
{  Módulo:       inLibExportadorXlsx                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Exportación de datasets a libros XLSX sin automatización de Excel.       }
{******************************************************************************}
unit inLibExportadorXlsx;

interface

uses
  Data.DB;

type
  TExportadorXlsx = class
  private
    class function ColumnaExcel(AIndice: Integer): string; static;
    class function CrearContenidoTipos: string; static;
    class function CrearEstilos: string; static;
    class function CrearHoja(
      ADataSet: TDataSet;
      const ATitulo: string;
      const AContexto: string): string; static;
    class function CrearRelacionesRaiz: string; static;
    class function CrearRelacionesLibro: string; static;
    class function CrearLibro: string; static;
    class function EsCampoNumerico(AField: TField): Boolean; static;
    class function EscaparXml(const AValor: string): string; static;
    class function ValorCelda(
      AField: TField;
      const ACelda: string): string; static;
    class procedure AgregarTextoZip(
      AZip: TObject;
      const ARuta: string;
      const AContenido: string); static;
  public
    class procedure Exportar(
      ADataSet: TDataSet;
      const ARuta: string;
      const ATitulo: string;
      const AContexto: string); static;
  end;

implementation

uses
  System.Classes, System.SysUtils, System.IOUtils, System.Zip;

class procedure TExportadorXlsx.AgregarTextoZip(
  AZip: TObject;
  const ARuta: string;
  const AContenido: string);
var
  oFlujo: TStringStream;
begin
  oFlujo := TStringStream.Create(AContenido, TEncoding.UTF8);
  try
    TZipFile(AZip).Add(oFlujo, ARuta);
  finally
    FreeAndNil(oFlujo);
  end;
end;

class function TExportadorXlsx.ColumnaExcel(AIndice: Integer): string;
var
  iValor: Integer;
begin
  Result := '';
  iValor := AIndice;
  while iValor > 0 do
  begin
    Dec(iValor);
    Result := Chr(Ord('A') + (iValor mod 26)) + Result;
    iValor := iValor div 26;
  end;
end;

class function TExportadorXlsx.CrearContenidoTipos: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Types xmlns="http://schemas.openxmlformats.org/package/' +
    '2006/content-types">' +
    '<Default Extension="rels" ContentType="application/vnd.' +
    'openxmlformats-package.relationships+xml"/>' +
    '<Default Extension="xml" ContentType="application/xml"/>' +
    '<Override PartName="/xl/workbook.xml" ContentType="application/' +
    'vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
    '<Override PartName="/xl/worksheets/sheet1.xml" ' +
    'ContentType="application/vnd.openxmlformats-officedocument.' +
    'spreadsheetml.worksheet+xml"/>' +
    '<Override PartName="/xl/styles.xml" ContentType="application/' +
    'vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
    '</Types>';
end;

class function TExportadorXlsx.CrearEstilos: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<styleSheet xmlns="http://schemas.openxmlformats.org/' +
    'spreadsheetml/2006/main">' +
    '<fonts count="2"><font><sz val="10"/><name val="Lucida Sans"/>' +
    '</font><font><b/><color rgb="FFFFFFFF"/><sz val="10"/>' +
    '<name val="Lucida Sans"/></font></fonts>' +
    '<fills count="3"><fill><patternFill patternType="none"/></fill>' +
    '<fill><patternFill patternType="gray125"/></fill>' +
    '<fill><patternFill patternType="solid"><fgColor rgb="FF244B74"/>' +
    '<bgColor indexed="64"/></patternFill></fill></fills>' +
    '<borders count="1"><border><left/><right/><top/><bottom/>' +
    '<diagonal/></border></borders>' +
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" ' +
    'borderId="0"/></cellStyleXfs>' +
    '<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" ' +
    'borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" ' +
    'borderId="0" xfId="0" applyFont="1" applyFill="1"/>' +
    '<xf numFmtId="4" fontId="0" fillId="0" borderId="0" xfId="0" ' +
    'applyNumberFormat="1"/></cellXfs>' +
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" ' +
    'builtinId="0"/></cellStyles></styleSheet>';
end;

class function TExportadorXlsx.CrearHoja(
  ADataSet: TDataSet;
  const ATitulo: string;
  const AContexto: string): string;
var
  oXml: TStringBuilder;
  oField: TField;
  oMarca: TBookmark;
  bTieneMarca: Boolean;
  iColumna: Integer;
  iFila: Integer;
  sCelda: string;
  sUltimaColumna: string;
begin
  oXml := TStringBuilder.Create;
  bTieneMarca := not ADataSet.IsEmpty;
  if bTieneMarca then
  begin
    oMarca := ADataSet.Bookmark;
  end;
  ADataSet.DisableControls;
  try
    sUltimaColumna := ColumnaExcel(ADataSet.FieldCount);
    oXml.Append(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    oXml.Append(
      '<worksheet xmlns="http://schemas.openxmlformats.org/' +
      'spreadsheetml/2006/main">');
    oXml.Append(
      '<sheetViews><sheetView workbookViewId="0"><pane ySplit="4" ' +
      'topLeftCell="A5" activePane="bottomLeft" state="frozen"/>' +
      '</sheetView></sheetViews>');
    oXml.Append('<cols>');
    for iColumna := 1 to ADataSet.FieldCount do
    begin
      oField := ADataSet.Fields[iColumna - 1];
      if EsCampoNumerico(oField) then
      begin
        oXml.AppendFormat(
          '<col min="%d" max="%d" width="16" customWidth="1"/>',
          [iColumna, iColumna]);
      end
      else
      begin
        oXml.AppendFormat(
          '<col min="%d" max="%d" width="28" customWidth="1"/>',
          [iColumna, iColumna]);
      end;
    end;
    oXml.Append('</cols><sheetData>');
    oXml.Append('<row r="1"><c r="A1" t="inlineStr" s="1"><is><t>');
    oXml.Append(EscaparXml(ATitulo));
    oXml.Append('</t></is></c></row>');
    oXml.Append('<row r="2"><c r="A2" t="inlineStr"><is><t>');
    oXml.Append(EscaparXml(AContexto));
    oXml.Append('</t></is></c></row><row r="4">');
    for iColumna := 1 to ADataSet.FieldCount do
    begin
      sCelda := ColumnaExcel(iColumna) + '4';
      oXml.AppendFormat(
        '<c r="%s" t="inlineStr" s="1"><is><t>%s</t></is></c>',
        [sCelda,
         EscaparXml(ADataSet.Fields[iColumna - 1].DisplayLabel)]);
    end;
    oXml.Append('</row>');
    iFila := 5;
    ADataSet.First;
    while not ADataSet.Eof do
    begin
      oXml.AppendFormat('<row r="%d">', [iFila]);
      for iColumna := 1 to ADataSet.FieldCount do
      begin
        sCelda := ColumnaExcel(iColumna) + IntToStr(iFila);
        oXml.Append(ValorCelda(
          ADataSet.Fields[iColumna - 1],
          sCelda));
      end;
      oXml.Append('</row>');
      Inc(iFila);
      ADataSet.Next;
    end;
    oXml.Append('</sheetData>');
    if ADataSet.FieldCount > 0 then
    begin
      oXml.AppendFormat(
        '<mergeCells count="1"><mergeCell ref="A1:%s1"/>' +
        '</mergeCells>',
        [sUltimaColumna]);
      oXml.AppendFormat(
        '<autoFilter ref="A4:%s%d"/>',
        [sUltimaColumna, iFila - 1]);
    end;
    oXml.Append('</worksheet>');
    Result := oXml.ToString;
  finally
    if bTieneMarca and ADataSet.BookmarkValid(oMarca) then
    begin
      ADataSet.Bookmark := oMarca;
    end;
    ADataSet.EnableControls;
    FreeAndNil(oXml);
  end;
end;

class function TExportadorXlsx.CrearLibro: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<workbook xmlns="http://schemas.openxmlformats.org/' +
    'spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.' +
    'org/officeDocument/2006/relationships"><sheets>' +
    '<sheet name="Listado" sheetId="1" r:id="rId1"/>' +
    '</sheets></workbook>';
end;

class function TExportadorXlsx.CrearRelacionesLibro: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/' +
    '2006/relationships"><Relationship Id="rId1" Type="http://schemas.' +
    'openxmlformats.org/officeDocument/2006/relationships/worksheet" ' +
    'Target="worksheets/sheet1.xml"/><Relationship Id="rId2" ' +
    'Type="http://schemas.openxmlformats.org/officeDocument/2006/' +
    'relationships/styles" Target="styles.xml"/></Relationships>';
end;

class function TExportadorXlsx.CrearRelacionesRaiz: string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/' +
    '2006/relationships"><Relationship Id="rId1" Type="http://schemas.' +
    'openxmlformats.org/officeDocument/2006/relationships/officeDocument" ' +
    'Target="xl/workbook.xml"/></Relationships>';
end;

class function TExportadorXlsx.EsCampoNumerico(AField: TField): Boolean;
begin
  Result := AField.DataType in [
    ftSmallint,
    ftInteger,
    ftWord,
    ftFloat,
    ftCurrency,
    ftBCD,
    ftAutoInc,
    ftLargeint,
    ftFMTBcd,
    ftLongWord,
    ftShortint,
    ftByte,
    ftSingle,
    ftExtended
  ];
end;

class function TExportadorXlsx.EscaparXml(
  const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

class procedure TExportadorXlsx.Exportar(
  ADataSet: TDataSet;
  const ARuta: string;
  const ATitulo: string;
  const AContexto: string);
var
  oZip: TZipFile;
begin
  if ADataSet = nil then
  begin
    raise EArgumentNilException.Create('ADataSet');
  end;
  if not ADataSet.Active then
  begin
    raise EInvalidOpException.Create(
      'El listado debe estar consultado antes de exportarlo.');
  end;
  if TFile.Exists(ARuta) then
  begin
    TFile.Delete(ARuta);
  end;
  oZip := TZipFile.Create;
  try
    oZip.Open(ARuta, zmWrite);
    AgregarTextoZip(oZip, '[Content_Types].xml', CrearContenidoTipos);
    AgregarTextoZip(oZip, '_rels/.rels', CrearRelacionesRaiz);
    AgregarTextoZip(oZip, 'xl/workbook.xml', CrearLibro);
    AgregarTextoZip(
      oZip,
      'xl/_rels/workbook.xml.rels',
      CrearRelacionesLibro);
    AgregarTextoZip(oZip, 'xl/styles.xml', CrearEstilos);
    AgregarTextoZip(
      oZip,
      'xl/worksheets/sheet1.xml',
      CrearHoja(ADataSet, ATitulo, AContexto));
    oZip.Close;
  finally
    FreeAndNil(oZip);
  end;
end;

class function TExportadorXlsx.ValorCelda(
  AField: TField;
  const ACelda: string): string;
var
  oFormato: TFormatSettings;
  sValor: string;
begin
  if AField.IsNull then
  begin
    Result := Format('<c r="%s"/>', [ACelda]);
  end
  else if EsCampoNumerico(AField) then
  begin
    oFormato := TFormatSettings.Create('en-US');
    sValor := FloatToStr(AField.AsFloat, oFormato);
    Result := Format(
      '<c r="%s" s="2"><v>%s</v></c>',
      [ACelda, sValor]);
  end
  else if AField.DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] then
  begin
    sValor := FormatDateTime('yyyy-mm-dd', AField.AsDateTime);
    Result := Format(
      '<c r="%s" t="inlineStr"><is><t>%s</t></is></c>',
      [ACelda, sValor]);
  end
  else
  begin
    Result := Format(
      '<c r="%s" t="inlineStr"><is><t xml:space="preserve">%s' +
      '</t></is></c>',
      [ACelda, EscaparXml(AField.AsString)]);
  end;
end;

end.
