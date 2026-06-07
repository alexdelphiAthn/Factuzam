unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls, Vcl.ExtCtrls, DBAccess, MemDS,
  XML.XMLDoc, XML.XMLIntf, UFactura, Uni, UniProvider, MySQLUniProvider,
  SynEditHighlighter, SynHighlighterXML, SynEdit;

type
  TFormMain = class(TForm)
    MySQLUniProvider1: TMySQLUniProvider;
    UniConnection1: TUniConnection;
    UniQuery1: TUniQuery;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    UniQuery2: TUniQuery;
    DBGrid2: TDBGrid;
    ButtonGenerate: TButton;
    btSaveFile: TButton;
    MemoXML: TSynEdit;
    SynXMLSyn1: TSynXMLSyn;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ButtonGenerateClick(Sender: TObject);
    procedure btSaveFileClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    //procedure btnPruebaClick(Sender: TObject);
  private
    function CargarFactura(NroFactura, SerieFactura: string): TFactura;
    function GenerateFacturaeXML(Factura: TFactura): string;
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

function TFormMain.CargarFactura(NroFactura, SerieFactura: string): TFactura;
var
  QueryCabecera, QueryLineas: TUniQuery;
  LineaFactura: TLineaFactura;
begin
  Result := TFactura.Create;
  QueryCabecera := TUniQuery.Create(nil);
  QueryLineas := TUniQuery.Create(nil);
  try
    QueryCabecera.Connection := UniConnection1;
    QueryCabecera.SQL.Text := 'SELECT * '+
                              '  FROM fza_facturas ' +
                              ' WHERE ' + fnrofac + ' = :NRO ' +
                              '   AND ' + fseriefac + ' = :SERIE';
    QueryCabecera.ParamByName('NRO').AsString := NroFactura;
    QueryCabecera.ParamByName('SERIE').AsString := SerieFactura;
    QueryCabecera.Open;
    if not QueryCabecera.IsEmpty then
    begin
      with QueryCabecera do
      begin
        // Datos del comprador (cliente)
        Result.Buyer.TaxIdentificationNumber :=
                                             FieldByName (fNifCliente).AsString;
        Result.Buyer.PartyName := FieldByName(fRazonSocialCliente).AsString;
        Result.Buyer.Address := FieldByName(fDireccion1Cliente).AsString;
        Result.Buyer.PostCode := FieldByName(fCPostalCliente).AsString;
        Result.Buyer.Town := FieldByName(fPoblacionCliente).AsString;
        Result.Buyer.Province := FieldByName(fProvinciaCliente).AsString;
        Result.Buyer.CountryCode := FieldByName(fPaisCliente).AsString;

    // Datos del vendedor (empresa)
        Result.Seller.TaxIdentificationNumber :=
                                              FieldByName(fNifEmpresa).AsString;
        Result.Seller.PartyName := FieldByName(fRazonSocialEmpresa).AsString;
        Result.Seller.Address := FieldByName(fDireccion1Empresa).AsString;
        Result.Seller.PostCode := FieldByName(fCPostalEmpresa).AsString;
        Result.Seller.Town := FieldByName(fPoblacionEmpresa).AsString;
        Result.Seller.Province := FieldByName(fProvinciaEmpresa).AsString;
        Result.Seller.CountryCode := FieldByName(fPaisEmpresa).AsString;

        //Otros datos cabecera
        Result.NroFactura := FieldByName(fnrofac).AsString;
        Result.SerieFactura := FieldByName(fseriefac).AsString;
        Result.FechaFactura := FieldByName(ffechfac).AsDateTime;
        Result.CodigoCliente := FieldByName(fcodcli).AsString;

        // IVA Normal
        Result.PorcenIvaN := FieldByName(fporivan).AsFloat;
        Result.TotalIvaN := FieldByName(ftotivan).AsFloat;
        Result.PorcenReN := FieldByName(fporren).AsFloat;
        Result.TotalReN := FieldByName(ftotren).AsFloat;
        Result.TotalBaseiIvaN := FieldByName(ftotbasen).AsFloat;
        // IVA Reducido
        Result.PorcenIvaR := FieldByName(fporivar).AsFloat;
        Result.TotalIvaR := FieldByName(ftotivar).AsFloat;
        Result.PorcenReR := FieldByName(fporrer).AsFloat;
        Result.TotalReR := FieldByName(ftotrer).AsFloat;
        Result.TotalBaseiIvaR := FieldByName(ftotbaser).AsFloat;
        // IVA Superreducido
        Result.PorcenIvaS := FieldByName(fporivas).AsFloat;
        Result.TotalIvaS := FieldByName(ftotivas).AsFloat;
        Result.PorcenReS := FieldByName(fporres).AsFloat;
        Result.TotalReS := FieldByName(ftotres).AsFloat;
        Result.TotalBaseiIvaS := FieldByName(ftotbases).AsFloat;
        // IVA Exento
        Result.PorcenIvaE := FieldByName(fporivae).AsFloat;
        Result.TotalIvaE := FieldByName(ftotivae).AsFloat;
        Result.PorcenReE := FieldByName(fporree).AsFloat;
        Result.TotalReE := FieldByName(ftotree).AsFloat;
        Result.TotalBaseiIvaE := FieldByName(ftotbasee).AsFloat;
        //Totales
        Result.TotalBases := FieldByName(ftotbasefac).AsFloat;
        Result.TotalImpuestos := FieldByName(ftotimp).AsFloat;
        Result.PorcenRetencion := FieldByName(fporirpf).AsFloat;
        Result.TotalRetencion := FieldByName(ftotirpf).AsFloat;
        Result.TotalFactura :=  FieldByName(ftotallifac).AsFloat;
      end;
      with QueryLineas do
      begin
        Connection := UniConnection1;

        SQL.Text := 'SELECT * '+
                    '  FROM fza_facturas_lineas '+
                    ' WHERE ' + fnrofaclin + ' = :NRO '+
                    '   AND ' + fserielin + ' = :SERIE';
        ParamByName('NRO').AsString := NroFactura;
        ParamByName('SERIE').AsString := SerieFactura;
        Open;

        while not Eof do
        begin
          LineaFactura := Result.AgregarLinea;
          LineaFactura.NroFacturaLinea := FieldByName(fnrofaclin).AsString;
          LineaFactura.SerieFacturaLinea := FieldByName(fserielin).AsString;
          LineaFactura.LineaFacturaLinea := FieldByName(fnrolin).AsString;
          LineaFactura.CodigoArticulo := FieldByName(fcodart).AsString;
          LineaFactura.DescripcionArticulo :=
                                             FieldByName(fdescripcion).AsString;
          LineaFactura.Cantidad := FieldByName(fcant).AsFloat;
          LineaFactura.PrecioUnitario := FieldByName(fpresiva).AsFloat;
          LineaFactura.TotalLinea := FieldByName(ftotciva).AsFloat;
          LineaFactura.PorcentajeIVA := FieldByName(fporiva).AsFloat;

          // Determinar el tipo de IVA y el recargo de equivalencia
          if LineaFactura.PorcentajeIVA = Result.PorcenIvaN then
          begin
            LineaFactura.TipoIVA := 'N';
            LineaFactura.PorcentajeRE := Result.PorcenReN;
          end
          else if LineaFactura.PorcentajeIVA = Result.PorcenIvaR then
          begin
            LineaFactura.TipoIVA := 'R';
            LineaFactura.PorcentajeRE := Result.PorcenReR;
          end
          else if LineaFactura.PorcentajeIVA = Result.PorcenIvaS then
          begin
            LineaFactura.TipoIVA := 'S';
            LineaFactura.PorcentajeRE := Result.PorcenReS;
          end
          else if LineaFactura.PorcentajeIVA = Result.PorcenIvaE then
          begin
            LineaFactura.TipoIVA := 'E';
            LineaFactura.PorcentajeRE := Result.PorcenReE;
          end
          else
          begin
            LineaFactura.TipoIVA := 'N';
            LineaFactura.PorcentajeRE := Result.PorcenReN;
          end;
          Next;
        end;
      end;
    end;
  finally
    QueryCabecera.Free;
    QueryLineas.Free;
  end;
end;

function TFormMain.GenerateFacturaeXML(Factura: TFactura): string;
var
  XMLDoc: IXMLDocument;
  RootNode,
  InvoiceNode,
  TaxesNode,
  TaxNode,
  ItemsNode,
  InvoiceLineNode: IXMLNode;
  I: Integer;
  LineaFactura: TLineaFactura;
begin
  XMLDoc := TXMLDocument.Create(nil);
  XMLDoc.Active := True;
  XMLDoc.Options := XMLDoc.Options + [doNodeAutoIndent];

  RootNode := XMLDoc.AddChild('fe:Facturae');
  RootNode.DeclareNamespace('fe',
             'http://www.facturae.gob.es/formato/Versiones/Facturaev3_2_2.xml');

  // FileHeader
  with RootNode.AddChild('FileHeader') do
  begin
    AddChild('SchemaVersion').Text := '3.2.2';
    AddChild('Modality').Text := 'I';
    AddChild('InvoiceIssuerType').Text := 'EM';
    // ... A�adir m�s nodos del FileHeader ...
  end;

  // Parties
  with RootNode.AddChild('Parties') do
  begin
    // SellerParty
    with AddChild('SellerParty') do
    begin
      // ... A�adir informaci�n del vendedor ...
    end;
    with AddChild('BuyerParty') do
    begin
      with AddChild('TaxIdentification') do
      begin
        // Asumiendo que es una persona jur�dica J
        AddChild('PersonTypeCode').Text := 'J';
        // Asumiendo que es residente R
        AddChild('ResidenceTypeCode').Text := 'R';
        AddChild('TaxIdentificationNumber').Text := Factura.NIFCliente;
      end;
      with AddChild('LegalEntity') do
      begin
        AddChild('CorporateName').Text := Factura.RazonSocialCliente;
        // ... A�adir m�s informaci�n del cliente ...
      end;
    end;
  end;

  // Invoices
  InvoiceNode := RootNode.AddChild('Invoices').AddChild('Invoice');

  // InvoiceHeader
  with InvoiceNode.AddChild('InvoiceHeader') do
  begin
    AddChild('InvoiceNumber').Text := Factura.NroFactura;
    AddChild('InvoiceSeriesCode').Text := Factura.SerieFactura;
    AddChild('InvoiceDocumentType').Text := 'FC';
    AddChild('InvoiceClass').Text := 'OO';
  end;

  // InvoiceIssueData
  with InvoiceNode.AddChild('InvoiceIssueData') do
  begin
    AddChild('IssueDate').Text := FormatDateTime('yyyy-mm-dd',
                                                          Factura.FechaFactura);
    AddChild('InvoiceCurrencyCode').Text := 'EUR';
    AddChild('TaxCurrencyCode').Text := 'EUR';
    AddChild('LanguageName').Text := 'es';
  end;

  // TaxesOutputs
  TaxesNode := InvoiceNode.AddChild('TaxesOutputs');

  // IVA Normal
  if (Factura.TotalBaseiIvaN > 0) then
  begin
    TaxNode := TaxesNode.AddChild('Tax');
    with TaxNode do
    begin
      AddChild('TaxTypeCode').Text := '01';  // IVA
      AddChild('TaxRate').Text := Factura.FPorcenIvaN.AsCur;
      with AddChild('TaxableBase') do
        AddChild('TotalAmount').Text := Factura.FTotalBaseiIvaN.AsCur;
      with AddChild('TaxAmount') do
        AddChild('TotalAmount').Text := Factura.FTotalIvaN.AsCur;
      if (Factura.PorcenReN > 0) then
      begin
        AddChild('EquivalenceSurcharge').Text := Factura.FPorcenReN.AsCur;
        with AddChild('EquivalenceSurchargeAmount') do
          AddChild('TotalAmount').Text := Factura.FTotalReN.AsCur;
      end;
    end;
  end;

  // IVA Reducido
  if (Factura.TotalBaseiIvaR > 0) then
  begin
    TaxNode := TaxesNode.AddChild('Tax');
    with TaxNode do
    begin
      AddChild('TaxTypeCode').Text := '01';  // IVA
      AddChild('TaxRate').Text := Factura.FPorcenIvaR.AsCur;
      with AddChild('TaxableBase') do
        AddChild('TotalAmount').Text := Factura.FTotalBaseiIvaR.AsCur;
      with AddChild('TaxAmount') do
        AddChild('TotalAmount').Text := Factura.FTotalIvaR.AsCur;
      if (Factura.PorcenReR > 0) then
      begin
        AddChild('EquivalenceSurcharge').Text := Factura.FPorcenReR.AsCur;
        with AddChild('EquivalenceSurchargeAmount') do
          AddChild('TotalAmount').Text := Factura.FTotalReR.AsCur;
      end;
    end;
  end;

  // IVA Superreducido
  if Factura.TotalBaseiIvaS > 0 then
  begin
    TaxNode := TaxesNode.AddChild('Tax');
    with TaxNode do
    begin
      AddChild('TaxTypeCode').Text := '01';  // IVA
      AddChild('TaxRate').Text := FormatFloat('0.00', Factura.PorcenIvaS);
      with AddChild('TaxableBase') do
        AddChild('TotalAmount').Text := FormatFloat('0.00',
                                                        Factura.TotalBaseiIvaS);
      with AddChild('TaxAmount') do
        AddChild('TotalAmount').Text := FormatFloat('0.00', Factura.TotalIvaS);
      if Factura.PorcenReS > 0 then
      begin
        AddChild('EquivalenceSurcharge').Text := FormatFloat('0.00',
                                                             Factura.PorcenReS);
        with AddChild('EquivalenceSurchargeAmount') do
          AddChild('TotalAmount').Text := FormatFloat('0.00', Factura.TotalReS);
      end;
    end;
  end;

  // IVA Exento
  if Factura.TotalBaseiIvaE > 0 then
  begin
    TaxNode := TaxesNode.AddChild('Tax');
    with TaxNode do
    begin
      AddChild('TaxTypeCode').Text := '01';  // IVA
      AddChild('TaxRate').Text := FormatFloat('0.00', Factura.PorcenIvaE);
      with AddChild('TaxableBase') do
        AddChild('TotalAmount').Text := FormatFloat('0.00',
                                                        Factura.TotalBaseiIvaE);
      with AddChild('TaxAmount') do
        AddChild('TotalAmount').Text := FormatFloat('0.00', Factura.TotalIvaE);
      if Factura.PorcenReE > 0 then
      begin
        AddChild('EquivalenceSurcharge').Text := FormatFloat('0.00',
                                                             Factura.PorcenReE);
        with AddChild('EquivalenceSurchargeAmount') do
          AddChild('TotalAmount').Text := FormatFloat('0.00', Factura.TotalReE);
      end;
    end;
  end;

  // InvoiceTotals
  with InvoiceNode.AddChild('InvoiceTotals') do
  begin
    AddChild('TotalGrossAmount').Text := FormatFloat('0.00',
                                                          Factura.TotalFactura);
    AddChild('TotalGrossAmountBeforeTaxes').Text := FormatFloat('0.00',
                                                            Factura.TotalBases);
    AddChild('TotalTaxOutputs').Text := FormatFloat('0.00',
                                                        Factura.TotalImpuestos);
    if Factura.TotalRetencion > 0 then
    begin
      AddChild('TotalTaxesWithheld').Text := FormatFloat('0.00',
                                                        Factura.TotalRetencion);
    end;
    AddChild('InvoiceTotal').Text := FormatFloat('0.00', Factura.TotalFactura);
    AddChild('TotalOutstandingAmount').Text := FormatFloat('0.00',
                                                          Factura.TotalFactura);
    AddChild('TotalExecutableAmount').Text := FormatFloat('0.00',
                                                          Factura.TotalFactura);
  end;

  // Items
  ItemsNode := InvoiceNode.AddChild('Items');
  for I := 0 to Factura.Lineas.Count - 1 do
  begin
    LineaFactura := Factura.Lineas[I];
    InvoiceLineNode := ItemsNode.AddChild('InvoiceLine');
    with InvoiceLineNode do
    begin
      AddChild('ItemDescription').Text := LineaFactura.DescripcionArticulo;
      AddChild('Quantity').Text := FormatFloat('0.000000',
                                                         LineaFactura.Cantidad);
      AddChild('UnitOfMeasure').Text := '01';  // Asumiendo unidades
      AddChild('UnitPriceWithoutTax').Text := FormatFloat('0.000000',
                                                   LineaFactura.PrecioUnitario);
      AddChild('TotalCost').Text := FormatFloat('0.00',
                                                       LineaFactura.TotalLinea);
      AddChild('GrossAmount').Text := FormatFloat('0.00',
                                                       LineaFactura.TotalLinea);

      with AddChild('TaxesOutputs').AddChild('Tax') do
      begin
        AddChild('TaxTypeCode').Text := '01';  // IVA
        AddChild('TaxRate').Text := FormatFloat('0.00',
                                                    LineaFactura.PorcentajeIVA);
        with AddChild('TaxableBase') do
          AddChild('TotalAmount').Text := FormatFloat('0.00',
                                                       LineaFactura.TotalLinea);
        if LineaFactura.PorcentajeRE > 0 then
        begin
          AddChild('EquivalenceSurcharge').Text := FormatFloat('0.00',
                                                     LineaFactura.PorcentajeRE);
        end;
      end;
    end;
  end;
  XMLDoc.Options := XMLDoc.Options + [doNodeAutoIndent];
  Result := XMLDoc.XML.Text;
end;

//procedure TFormMain.btnPruebaClick(Sender: TObject);
//var
//  TestValue: TCurrencyField;
//begin
//  TestValue := TCurrencyField.Create(3.55988744);
//  ShowMessage(TestValue.AsCurr(7));
//end;


procedure TFormMain.btSaveFileClick(Sender: TObject);
begin
  //
end;

procedure TFormMain.Button1Click(Sender: TObject);
var
  T:TCurrencyField;
  S:String;
begin
  T := TcurrencyField.Create(50225522.455667);
  S := T.AsCur(0, '.', '�', '_');
  ShowMessage(S);

end;

procedure TFormMain.ButtonGenerateClick(Sender: TObject);
var
  NroFactura, SerieFactura: string;
  Factura: TFactura;
  XML: string;
begin
  if not UniQuery1.IsEmpty then
  begin
    NroFactura := UniQuery1.FieldByName(fnrofac).AsString;
    SerieFactura := UniQuery1.FieldByName(fseriefac).AsString;
    Factura := CargarFactura(NroFactura, SerieFactura);
    try
      XML := GenerateFacturaeXML(Factura);
      MemoXML.Lines.Text := XML;
    finally
      Factura.Free;
    end;
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  //
  UniConnection1.Connected := True;
  UniQuery1.Connection := UniConnection1;
  UniQuery1.SQL.Text := 'SELECT * FROM fza_facturas';
  UniQuery1.Open;
end;

end.
