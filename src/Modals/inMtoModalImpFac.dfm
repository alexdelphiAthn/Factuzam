inherited frmPrintFac: TfrmPrintFac
  Caption = 'Imprimir Factura'
  ClientHeight = 266
  ClientWidth = 426
  Position = poMainFormCenter
  ExplicitWidth = 438
  ExplicitHeight = 304
  TextHeight = 19
  inherited pnl1: TPanel
    Left = 272
    Width = 154
    Height = 266
    ExplicitLeft = 266
    ExplicitWidth = 154
    ExplicitHeight = 257
    inherited btnPDF: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
    inherited btnImprimir: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
    inherited btnVistaPreliminar: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
    inherited btnSalir: TcxButton
      Top = 240
      Width = 152
      ExplicitTop = 231
      ExplicitWidth = 152
    end
    inherited btnEditar: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
    inherited btnExcel: TcxButton
      Left = 11
      ExplicitLeft = 11
    end
  end
  object edtNroFac: TcxTextEdit [1]
    Left = 104
    Top = 24
    Enabled = False
    TabOrder = 1
    Width = 105
  end
  object lblcxlbl1: TcxLabel [2]
    Left = 8
    Top = 4
    Caption = 'Factura N'#250'mero'
    TabOrder = 2
  end
  object edtSerie: TcxTextEdit [3]
    Left = 8
    Top = 24
    Enabled = False
    TabOrder = 3
    Width = 90
  end
  object cxrdgrp1: TcxRadioGroup [4]
    Left = 8
    Top = 56
    Caption = 'Opciones'
    Properties.Items = <>
    TabOrder = 4
    Height = 137
    Width = 269
    object rbActual: TcxRadioButton
      Left = 8
      Top = 24
      Width = 223
      Height = 17
      Caption = 'Imprimir Factura actual'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbActualClick
      Transparent = True
    end
    object rbRangoFechas: TcxRadioButton
      Left = 8
      Top = 48
      Width = 258
      Height = 17
      Caption = 'Imprimir Rango de Facturas'
      Enabled = False
      TabOrder = 1
      OnClick = rbRangoFechasClick
      Transparent = True
    end
    object dedDesde: TcxDateEdit
      Left = 63
      Top = 72
      Enabled = False
      TabOrder = 2
      Width = 121
    end
    object dedHasta: TcxDateEdit
      Left = 63
      Top = 104
      Enabled = False
      TabOrder = 4
      Width = 121
    end
    object lblcxlbl2: TcxLabel
      Left = 7
      Top = 77
      Caption = 'Desde'
      Enabled = False
      TabOrder = 3
      Transparent = True
    end
    object lblcxlbl3: TcxLabel
      Left = 12
      Top = 105
      Caption = 'Hasta'
      Enabled = False
      TabOrder = 5
      Transparent = True
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 120
    Top = 200
  end
  inherited frxrprt1: TfrxReport
    ReportOptions.LastChange = 45266.651521481500000000
    ScriptText.Strings = (
      'procedure RetencionTotalOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_RETENCION_FACTURA"> <> 0 then'
      '  begin'
      '    RetencionTotal.Visible := True;'
      '    Retencion.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    RetencionTotal.Visible := False;'
      '    Retencion.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure ImpuestosTotalOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_IMPUESTOS_FACTURA"> <> 0 then'
      '  begin'
      '    ImpuestosTotal.Visible := True;'
      '    Impuestos.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    ImpuestosTotal.Visible := False;'
      '    Impuestos.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleNOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAN_FACTURA"> <> 0 then'
      '  begin'
      '    BaseImponibleN.Visible := True;'
      '    FacturasTOTAL_IVAN_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAN_FACTURA.Visible:= True;'
      '    FacturasPORCEN_REN_FACTURA.Visible := True;'
      '    FacturasTOTAL_REN_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleN.Visible := False;'
      '    FacturasTOTAL_IVAN_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAN_FACTURA.Visible:= False;'
      '    FacturasPORCEN_REN_FACTURA.Visible := False;'
      '    FacturasTOTAL_REN_FACTURA.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleROnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAR_FACTURA"> <> 0 then'
      '  begin'
      '    BaseImponibleR.Visible := True;'
      '    FacturasTOTAL_IVAR_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAR_FACTURA.Visible:= True;'
      '    FacturasPORCEN_RER_FACTURA.Visible := True;'
      '    FacturasTOTAL_RER_FACTURA1.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleR.Visible := False;'
      '    FacturasTOTAL_IVAR_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAR_FACTURA.Visible:= False;'
      '    FacturasPORCEN_RER_FACTURA.Visible := False;'
      '    FacturasTOTAL_RER_FACTURA1.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleSOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAS_FACTURA"> <> 0 then'
      '  begin'
      '    BaseImponibleS.Visible := True;'
      '    FacturasTOTAL_IVAS_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAS_FACTURA.Visible:= True;'
      '    FacturasPORCEN_RES_FACTURA.Visible := True;'
      '    FacturasTOTAL_RES_FACTURA1.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleS.Visible := False;'
      '    FacturasTOTAL_IVAS_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAS_FACTURA.Visible:= False;'
      '    FacturasPORCEN_RES_FACTURA.Visible := False;'
      '    FacturasTOTAL_RES_FACTURA1.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleEOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '    if <Facturas."TOTAL_BASEI_IVAE_FACTURA"> <> 0 then'
      '  begin'
      '    BaseImponibleE.Visible := True;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible:= True;'
      '    FacturasPORCEN_REE_FACTURA.Visible := True;'
      '    FacturasTOTAL_REE_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleE.Visible := False;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible:= False;'
      '    FacturasPORCEN_REE_FACTURA.Visible := False;'
      '    FacturasTOTAL_REE_FACTURA.Visible := False;'
      '  end;'
      
        '  if (<Facturas."TOTAL_BASEI_IVAE_FACTURA"> = <Facturas."TOTAL_B' +
        'ASES_FACTURA">) then'
      '  begin'
      '    CajaIVA.Visible := False;'
      '    CajaTitulosIVA.Visible := False;'
      '    BaseImponibleE.Visible := False;'
      '    TituloPorcenCajaIVA.Visible := False;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible := False;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := False;'
      '    BaseImponibleCajaIVA.Visible := False;'
      '    TituloTotalCajaIVA.Visible := False;'
      '  end;'
      'end;'
      ''
      
        'procedure FacturasTOTAL_REN_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_REN_FACTURA"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_REN_FACTURA.Visible := True;'
      '    FacturasTOTAL_REN_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_REN_FACTURA.Visible := False;'
      '    FacturasTOTAL_REN_FACTURA.Visible := False;'
      '  end;'
      'end;'
      ''
      
        'procedure FacturasTOTAL_RER_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_RER_FACTURA"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_RER_FACTURA.Visible := True;'
      '    FacturasTOTAL_RER_FACTURA1.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_RER_FACTURA.Visible := False;'
      '    FacturasTOTAL_RER_FACTURA1.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      
        'procedure FacturasTOTAL_RES_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_RES_FACTURA"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_RES_FACTURA.Visible := True;'
      '    FacturasTOTAL_RES_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_RES_FACTURA.Visible := False;'
      '    FacturasTOTAL_RES_FACTURA1.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      
        'procedure FacturasTOTAL_REE_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '    if <Facturas."TOTAL_REE_FACTURA"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_REE_FACTURA.Visible := True;'
      '    FacturasTOTAL_REE_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_REE_FACTURA.Visible := False;'
      '    FacturasTOTAL_REE_FACTURA.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      'procedure RetencionPorcOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If (( <Facturas."TOTAL_REE_FACTURA"> +'
      '        <Facturas."TOTAL_RES_FACTURA"> +'
      '        <Facturas."TOTAL_RER_FACTURA"> +'
      '        <Facturas."TOTAL_REN_FACTURA"> ) = 0) then'
      '  begin'
      '    RetencionPorc.Visible := False;'
      '    RetencionTot.Visible := False;'
      '  end'
      '  else'
      '  begin'
      '    RetencionPorc.Visible := True;'
      '    RetencionTot.Visible := True;'
      '  end;'
      'end;'
      ''
      'procedure PageFooter1OnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '   Engine.CurY := (20.5 * fr1cm);  '
      'end;'
      ''
      'procedure DetailData1OnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If (<Facturas."ESFECHADEENTREGA_FACTURA"> <> '#39'S'#39') then'
      '   begin              '
      
        '    // LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA.Width :=' +
        ' 76;                                                            ' +
        '                        '
      
        '    LineasFacturasFECHA_ENTREGA_FACTURA_LINEA.Visible := False; ' +
        '                                             '
      '  end'
      '  else            '
      '  begin              '
      
        '    // LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA.Width :=' +
        ' 98;        '
      
        '    LineasFacturasFECHA_ENTREGA_FACTURA_LINEA.Visible := True;  ' +
        '                                          '
      '  end;  '
      'end;'
      
        'procedure FechaEntregaTittleOnBeforePrint(Sender: TfrxComponent)' +
        ';'
      'begin'
      '  If (<Facturas."ESFECHADEENTREGA_FACTURA"> <> '#39'S'#39') then'
      '    FechaEntregaTittle.Visible := False'
      '  else'
      '    FechaEntregaTittle.Visible := True;                 '
      'end;'
      ''
      'begin                          '
      'end.')
    Left = 336
    Top = 176
    Datasets = <
      item
        DataSet = dmFacturas.fxdsPrintFac
        DataSetName = 'Facturas'
      end
      item
        DataSet = dmFacturas.fxdstPrintLinFac
        DataSetName = 'Lineas Facturas'
      end>
    Variables = <>
    Style = <>
    inherited Data: TfrxDataPage
      object FacturasTOTAL_RER_FACTURA: TfrxMemoView
        IndexTag = 1
        AllowVectorExport = True
        Left = 398.409710000000000000
        Top = 504.031540000000000000
        Width = 64.252010000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'FacturasTOTAL_RER_FACTURAOnBeforePrint'
        DataField = 'TOTAL_RER_FACTURA'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.3m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_RER_FACTURA"]')
        ParentFont = False
      end
      object FacturasTOTAL_RES_FACTURA: TfrxMemoView
        IndexTag = 1
        AllowVectorExport = True
        Left = 398.409710000000000000
        Top = 530.488250000000000000
        Width = 64.252010000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'FacturasTOTAL_RES_FACTURAOnBeforePrint'
        DataField = 'TOTAL_RES_FACTURA'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.3m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_RES_FACTURA"]')
        ParentFont = False
      end
    end
    inherited Page1: TfrxReportPage
      object Memo19: TfrxMemoView
        AllowVectorExport = True
        Left = 876.850974650000000000
        Top = 619.842920000000000000
        Width = 79.370130000000000000
        Height = 18.897650000000000000
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.2m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_LIQUIDO_FACTURA"]')
        ParentFont = False
      end
      object Memo21: TfrxMemoView
        IndexTag = 1
        AllowVectorExport = True
        Left = 876.850974650000000000
        Top = 582.047620000000000000
        Width = 79.370130000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'RetencionTotalOnBeforePrint'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.2m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[<Facturas."TOTAL_RETENCION_FACTURA"> * (-1)]')
        ParentFont = False
      end
      object Memo23: TfrxMemoView
        AllowVectorExport = True
        Left = 877.969094650000000000
        Top = 553.701145000000000000
        Width = 79.370130000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'ImpuestosTotalOnBeforePrint'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.2m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_IMPUESTOS_FACTURA"]')
        ParentFont = False
      end
      object Memo25: TfrxMemoView
        AllowVectorExport = True
        Left = 877.969094650000000000
        Top = 525.354670000000000000
        Width = 79.370130000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'ImpuestosTotalOnBeforePrint'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.2m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_BASES_FACTURA"]')
        ParentFont = False
      end
    end
  end
  inherited frxpdfxprtPedWeb: TfrxPDFExport
    FileName = 'C:\Users\34667\OneDrive\Escritorio\FACTURA KIOSCO.pdf'
    CreationTime = 45274.521397164350000000
    Author = 'FactuZam Report System'
    Left = 232
    Top = 200
  end
  inherited frxlsxprtExcel: TfrxXLSXExport
    CreationTime = 44864.742612013890000000
    Left = 400
    Top = 192
  end
  inherited unqryPerfiles: TUniQuery
    Left = 8
    Top = 200
  end
  inherited dsPerfiles: TDataSource
    Left = 64
    Top = 200
  end
  inherited frxdsgnr1: TfrxDesigner
    Left = 184
    Top = 208
  end
  inherited frxReportOrigen: TfrxReport
    EngineOptions.DoublePass = True
    PreviewOptions.AllowEdit = False
    PreviewOptions.AllowPreviewEdit = False
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbNavigator, pbExportQuick]
    ReportOptions.LastChange = 45269.385296875000000000
    ScriptText.Strings = (
      'procedure RetencionTotalOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_RETENCION_FACTURA"> <> 0 then'
      '  begin'
      '    txtRetencionTotal.Visible := True;'
      '    Retencion.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    txtRetencionTotal.Visible := False;'
      '    Retencion.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure ImpuestosTotalOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_IMPUESTOS_FACTURA"> <> 0 then'
      '  begin'
      '    ImpuestosTotal.Visible := True;'
      '    Impuestos.Visible:= True;'
      '  end'
      '  else'
      '  begin'
      '    ImpuestosTotal.Visible := False;'
      '    Impuestos.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleNOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAN_FACTURA"> <> 0 then'
      '  begin'
      '    BaseImponibleN.Visible := True;'
      '    FacturasTOTAL_IVAN_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAN_FACTURA.Visible:= True;'
      '    FacturasPORCEN_REN_FACTURA.Visible := True;'
      '    FacturasTOTAL_REN_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleN.Visible := False;'
      '    FacturasTOTAL_IVAN_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAN_FACTURA.Visible:= False;'
      '    FacturasPORCEN_REN_FACTURA.Visible := False;'
      '    FacturasTOTAL_REN_FACTURA.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleROnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAR_FACTURA"> <> 0 then'
      '  begin'
      '    BaseImponibleR.Visible := True;'
      '    FacturasTOTAL_IVAR_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAR_FACTURA.Visible:= True;'
      '    FacturasPORCEN_RER_FACTURA.Visible := True;'
      '    FacturasTOTAL_RER_FACTURA1.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleR.Visible := False;'
      '    FacturasTOTAL_IVAR_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAR_FACTURA.Visible:= False;'
      '    FacturasPORCEN_RER_FACTURA.Visible := False;'
      '    FacturasTOTAL_RER_FACTURA1.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleSOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if <Facturas."TOTAL_BASEI_IVAS_FACTURA"> <> 0 then'
      '  begin'
      '    BaseImponibleS.Visible := True;'
      '    FacturasTOTAL_IVAS_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAS_FACTURA.Visible:= True;'
      '    FacturasPORCEN_RES_FACTURA.Visible := True;'
      '    FacturasTOTAL_RES_FACTURA1.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleS.Visible := False;'
      '    FacturasTOTAL_IVAS_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAS_FACTURA.Visible:= False;'
      '    FacturasPORCEN_RES_FACTURA.Visible := False;'
      '    FacturasTOTAL_RES_FACTURA1.Visible := False;'
      '  end;'
      'end;'
      ''
      'procedure BaseImponibleEOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '    if <Facturas."TOTAL_BASEI_IVAE_FACTURA"> <> 0 then'
      '  begin'
      '    BaseImponibleE.Visible := True;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := True;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible:= True;'
      '    FacturasPORCEN_REE_FACTURA.Visible := True;'
      '    FacturasTOTAL_REE_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    BaseImponibleE.Visible := False;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := False;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible:= False;'
      '    FacturasPORCEN_REE_FACTURA.Visible := False;'
      '    FacturasTOTAL_REE_FACTURA.Visible := False;'
      '  end;'
      
        '  if (<Facturas."TOTAL_BASEI_IVAE_FACTURA"> = <Facturas."TOTAL_B' +
        'ASES_FACTURA">) then'
      '  begin'
      '    CajaIVA.Visible := False;'
      '    CajaTitulosIVA.Visible := False;'
      '    BaseImponibleE.Visible := False;'
      '    TituloPorcenCajaIVA.Visible := False;'
      '    FacturasPORCEN_IVAE_FACTURA.Visible := False;'
      '    FacturasTOTAL_IVAE_FACTURA.Visible := False;'
      '    BaseImponibleCajaIVA.Visible := False;'
      '    TituloTotalCajaIVA.Visible := False;'
      '  end;'
      'end;'
      ''
      
        'procedure FacturasTOTAL_REN_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_REN_FACTURA"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_REN_FACTURA.Visible := True;'
      '    FacturasTOTAL_REN_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_REN_FACTURA.Visible := False;'
      '    FacturasTOTAL_REN_FACTURA.Visible := False;'
      '  end;'
      'end;'
      ''
      
        'procedure FacturasTOTAL_RER_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_RER_FACTURA"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_RER_FACTURA.Visible := True;'
      '    FacturasTOTAL_RER_FACTURA1.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_RER_FACTURA.Visible := False;'
      '    FacturasTOTAL_RER_FACTURA1.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      
        'procedure FacturasTOTAL_RES_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '  if <Facturas."TOTAL_RES_FACTURA"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_RES_FACTURA.Visible := True;'
      '    FacturasTOTAL_RES_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_RES_FACTURA.Visible := False;'
      '    FacturasTOTAL_RES_FACTURA1.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      
        'procedure FacturasTOTAL_REE_FACTURAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      '    if <Facturas."TOTAL_REE_FACTURA"> <> 0 then'
      '  begin'
      '    FacturasPORCEN_REE_FACTURA.Visible := True;'
      '    FacturasTOTAL_REE_FACTURA.Visible := True;'
      '  end'
      '  else'
      '  begin'
      '    FacturasPORCEN_REE_FACTURA.Visible := False;'
      '    FacturasTOTAL_REE_FACTURA.Visible := False;'
      '  end;'
      ''
      'end;'
      ''
      'procedure RetencionPorcOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If (( <Facturas."TOTAL_REE_FACTURA"> +'
      '        <Facturas."TOTAL_RES_FACTURA"> +'
      '        <Facturas."TOTAL_RER_FACTURA"> +'
      '        <Facturas."TOTAL_REN_FACTURA"> ) = 0) then'
      '  begin'
      '    RetencionPorc.Visible := False;'
      '    RetencionTot.Visible := False;'
      '  end'
      '  else'
      '  begin'
      '    RetencionPorc.Visible := True;'
      '    RetencionTot.Visible := True;'
      '  end;'
      'end;'
      ''
      'procedure PageFooter1OnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  Engine.CurY := (20 * fr1cm);'
      '  if ((<TotalPages> > 1) and (<Page> <> <TotalPages>)) then'
      '  begin'
      '    CajaTitulosIVA.Visible := False;'
      '    BaseImponibleCajaIVA.Visible := False;'
      '    TituloPorcenCajaIVA.Visible := False;'
      '    TituloTotalCajaIVA.Visible := False;'
      '    TotalBases.Visible := False;'
      '    Impuestos.Font.Color := clWhite;'
      '    ImpuestosTotal.Font.Color := clWhite;'
      '    RetencionTot.Font.Color := clWhite;'
      '    mTotalFactura.Visible := False;'
      
        '    mTotalFacturaCtd.Visible := False;                          ' +
        '                    '
      '    txtRetencionTotal.Font.Color := clWhite;'
      '    Retencion.Font.Color := clWhite;'
      '    RetencionPorc.Font.Color := clWhite;'
      '    CajaIVA.Visible := False;'
      '    FormaPago.Visible := False;'
      
        '    Continua.Visible := True;                                   ' +
        '                       '
      '    BaseImponibleN.Font.Color := clWhite;'
      '    BaseImponibleR.Font.Color := clWhite;'
      '    BaseImponibleS.Font.Color := clWhite;'
      '    BaseImponibleE.Font.Color := clWhite;'
      '    TotalBaseImponible.Visible := False;'
      '    FacturasPORCEN_IVAN_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_IVAR_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_IVAS_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_IVAE_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_IVAN_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_IVAR_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_IVAS_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_IVAE_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_REN_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_RER_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_RES_FACTURA.Font.Color := clWhite;'
      '    FacturasPORCEN_REE_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_REN_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_RER_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_RES_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_REE_FACTURA.Font.Color := clWhite;'
      '    FacturasTOTAL_RER_FACTURA1.Font.Color := clWhite;'
      '    FacturasTOTAL_RES_FACTURA1.Font.Color := clWhite;'
      '  end'
      '  else'
      '  begin'
      
        '    Continua.Visible := False;                                  ' +
        '                                           '
      '    CajaTitulosIVA.Visible := True;'
      '    BaseImponibleCajaIVA.Visible := True;'
      '    TituloPorcenCajaIVA.Visible := True;'
      '    TituloTotalCajaIVA.Visible := True;'
      '    TotalBases.Visible := True;'
      '    Impuestos.Font.Color := clBlack;'
      '    ImpuestosTotal.Font.Color := clBlack;'
      '    RetencionTot.Font.Color := clBlack;'
      '    mTotalFactura.Visible := True;'
      
        '    mTotalFacturaCtd.Visible := True;                           ' +
        '                 '
      '    CajaIVA.Visible := True;'
      '    txtRetencionTotal.Font.Color := clBlack;'
      '    Retencion.Font.Color := clBlack;'
      '    RetencionPorc.Font.Color := clBlack;'
      '    FormaPago.Visible := True;'
      '    BaseImponibleN.Font.Color := clBlack;'
      '    BaseImponibleR.Font.Color := clBlack;'
      '    BaseImponibleS.Font.Color := clBlack;'
      '    BaseImponibleE.Font.Color := clBlack;'
      '    TotalBaseImponible.Visible := True;'
      '    FacturasPORCEN_IVAN_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_IVAR_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_IVAS_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_IVAE_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_IVAN_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_IVAR_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_IVAS_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_IVAE_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_REN_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_RER_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_RES_FACTURA.Font.Color := clBlack;'
      '    FacturasPORCEN_REE_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_REN_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_RER_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_RES_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_REE_FACTURA.Font.Color := clBlack;'
      '    FacturasTOTAL_RER_FACTURA1.Font.Color := clBlack;'
      '    FacturasTOTAL_RES_FACTURA1.Font.Color := clBlack;'
      '  end;'
      'end;'
      ''
      'procedure DetailData1OnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If (<Facturas."ESFECHADEENTREGA_FACTURA"> <> '#39'S'#39') then'
      '   begin'
      
        '    // LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA.Width :=' +
        ' 76;'
      '    LineasFacturasFECHA_ENTREGA_FACTURA_LINEA.Visible := False;'
      '  end'
      '  else'
      '  begin'
      
        '    // LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA.Width :=' +
        ' 98;'
      '    LineasFacturasFECHA_ENTREGA_FACTURA_LINEA.Visible := True;'
      '  end;'
      'end;'
      
        'procedure FechaEntregaTittleOnBeforePrint(Sender: TfrxComponent)' +
        ';'
      'begin'
      '  If (<Facturas."ESFECHADEENTREGA_FACTURA"> <> '#39'S'#39') then'
      '    FechaEntregaTittle.Visible := False'
      '  else'
      '    FechaEntregaTittle.Visible := True;'
      'end;'
      ''
      
        'procedure FacturasPROVINCIA_EMPRESA_FACTURAOnBeforePrint(Sender:' +
        ' TfrxComponent);'
      'begin'
      
        '  IF (<Facturas."POBLACION_EMPRESA_FACTURA"> = <Facturas."PROVIN' +
        'CIA_EMPRESA_FACTURA">) then'
      '    FacturasPROVINCIA_EMPRESA_FACTURA.Visible := False'
      '  else'
      '    FacturasPROVINCIA_EMPRESA_FACTURA.Visible := True;'
      'end;'
      ''
      ''
      
        'procedure FacturasPROVINCIA_CLIENTE_FACTURAOnBeforePrint(Sender:' +
        ' TfrxComponent);'
      'begin'
      
        '  IF (<Facturas."POBLACION_CLIENTE_FACTURA"> = <Facturas."PROVIN' +
        'CIA_CLIENTE_FACTURA">) then'
      '    FacturasPROVINCIA_CLIENTE_FACTURA.Visible := False'
      '  else'
      '    FacturasPROVINCIA_CLIENTE_FACTURA.Visible := True;'
      'end;'
      ''
      'procedure ImpuestosOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  If (( <Facturas."TOTAL_REE_FACTURA"> +'
      '        <Facturas."TOTAL_RES_FACTURA"> +'
      '        <Facturas."TOTAL_RER_FACTURA"> +'
      '        <Facturas."TOTAL_REN_FACTURA"> ) = 0) then'
      
        '    Impuestos.Memo.Text := '#39'Total [Facturas."PALABRA_REPORTS_ZON' +
        'A_IVA_FACTURA"]'#39
      '  else'
      
        '    Impuestos.Memo.Text := '#39'Total [Facturas."PALABRA_REPORTS_ZON' +
        'A_IVA_FACTURA"] + R.E.'#39
      'end;'
      ''
      'procedure mNumPaginasOnBeforePrint(Sender: TfrxComponent);'
      'begin'
      '  if (<TotalPages> > 1) then'
      '    mNumPaginas.Visible := True'
      '  else'
      '    mNumPaginas.Visible := False;'
      'end;'
      ''
      'procedure FormaPagoOnBeforePrint(Sender: TfrxComponent);'
      'begin           '
      '  if ((<Facturas."ESVERBANCOEMPRESA_FORMAPAGO"> = '#39'S'#39') and '
      '      (<Facturas."ESCONTADO_FORMAPAGO"> = '#39'N'#39') and '
      '      (<Facturas."IBAN_EMPRESA"> <> '#39#39'))  then'
      
        '    FormaPago.Memo.Text := Trim(FormaPago.Memo.Text) + '#39'     '#39' +' +
        ' FormatMaskText('#39'>LL00 aaaa aaaa aaaa aaaa aaaa aaaa aaaa aa;0;'#39 +
        ',<Facturas."IBAN_EMPRESA">);'
      '  if ((<Facturas."ESVERBANCOEMPRESA_FORMAPAGO"> = '#39'N'#39') and '
      '      (<Facturas."ESCONTADO_FORMAPAGO"> = '#39'N'#39') and '
      '      (<Facturas."IBAN_CLIENTE"> <> '#39#39')) then'
      
        '    FormaPago.Memo.Text := Trim(FormaPago.Memo.Text) + '#39'     '#39' +' +
        ' FormatMaskText('#39'>LL00 aaaa aaaa aaaa aaaa aaaa aaaa aaaa aa;0;'#39 +
        ',<Facturas."IBAN_CLIENTE">);'
      '  if (<Facturas."VENCIMIENTOS_RECIBOS"> <> '#39#39') then'
      
        '    FormaPago.Memo.Text := FormaPago.Memo.Text + '#39'Vencimiento/s:' +
        ' '#39' + <Facturas."VENCIMIENTOS_RECIBOS">;              '
      'end;'
      ''
      
        'procedure LineasFacturasTOTAL_LINEAOnBeforePrint(Sender: TfrxCom' +
        'ponent);'
      'begin'
      
        '  if (<Lineas Facturas."ESIMP_INCL_TARIFA_FACTURA_LINEA"> = '#39'S'#39')' +
        ' then'
      
        '    LineasFacturasTOTAL_LINEA.Memo.Text := '#39'[Lineas Facturas."TO' +
        'TAL_FACTURA_LINEA"]'#39
      '  else                      '
      
        '    LineasFacturasTOTAL_LINEA.Memo.Text := '#39'[<Lineas Facturas."C' +
        'ANTIDAD_FACTURA_LINEA"> '#39'+ '
      
        '                                           '#39'*<Lineas Facturas."P' +
        'RECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA">]'#39';'
      'end;'
      ''
      
        'procedure PrecioUnitarioLineasFacturasOnBeforePrint(Sender: Tfrx' +
        'Component);'
      'begin'
      
        '  if (<Lineas Facturas."ESIMP_INCL_TARIFA_FACTURA_LINEA"> = '#39'S'#39')' +
        ' then'
      
        '    PrecioUnitarioLineasFacturas.Memo.Text := '#39'[<Lineas Facturas' +
        '."PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA">]'#39
      '  else'
      
        '    PrecioUnitarioLineasFacturas.Memo.Text := '#39'[<Lineas Facturas' +
        '."PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA">]'#39'                 '
      'end;'
      ''
      'begin'
      'end.')
    Left = 232
    Top = 144
    Datasets = <
      item
        DataSet = dmFacturas.fxdsPrintFac
        DataSetName = 'Facturas'
      end
      item
        DataSet = dmFacturas.fxdstPrintLinFac
        DataSetName = 'Lineas Facturas'
      end>
    Variables = <>
    Style = <>
    inherited Data: TfrxDataPage
      object FacturasTOTAL_RER_FACTURA: TfrxMemoView
        IndexTag = 1
        AllowVectorExport = True
        Left = 398.409710000000000000
        Top = 504.031540000000000000
        Width = 64.252010000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'FacturasTOTAL_RER_FACTURAOnBeforePrint'
        DataField = 'TOTAL_RER_FACTURA'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.3m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_RER_FACTURA"]')
        ParentFont = False
      end
      object FacturasTOTAL_RES_FACTURA: TfrxMemoView
        IndexTag = 1
        AllowVectorExport = True
        Left = 398.409710000000000000
        Top = 530.488250000000000000
        Width = 64.252010000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'FacturasTOTAL_RES_FACTURAOnBeforePrint'
        DataField = 'TOTAL_RES_FACTURA'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.3m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_RES_FACTURA"]')
        ParentFont = False
      end
    end
    inherited Page1: TfrxReportPage
      LeftMargin = 10.000000000000000000
      object DetailData1: TfrxDetailData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 26.456710000000000000
        Top = 525.354670000000000000
        Width = 737.008350000000000000
        OnBeforePrint = 'DetailData1OnBeforePrint'
        DataSet = dmFacturas.fxdstPrintLinFac
        DataSetName = 'Lineas Facturas'
        RowCount = 0
        object LineasFacturasTOTAL_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 644.858690000000000000
          Top = 4.338590000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'LineasFacturasTOTAL_LINEAOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            ''
            
              '[<Lineas Facturas."CANTIDAD_FACTURA_LINEA">*<Lineas Facturas."PR' +
              'ECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA">]')
          ParentFont = False
        end
        object LineasFacturasCANTIDAD_FACTURA_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 386.055350000000000000
          Top = 3.779530000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            
              '[Lineas Facturas."CANTIDAD_FACTURA_LINEA"] [Lineas Facturas."TIP' +
              'O_CANTIDAD_ARTICULO_FACTURA_LINEA"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object PrecioUnitarioLineasFacturas: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 479.984540000000000000
          Top = 3.779530000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'PrecioUnitarioLineasFacturasOnBeforePrint'
          DataField = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Lineas Facturas."PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA"]')
          ParentFont = False
        end
        object LineasFacturasPORCEN_IVA_FACTURA_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 582.047620000000000000
          Top = 3.779530000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g %'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            '[Lineas Facturas."PORCEN_IVA_FACTURA_LINEA"]')
          ParentFont = False
        end
        object LineasFacturasFECHA_ENTREGA_FACTURA_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 306.126160000000000000
          Top = 3.779530000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          DataField = 'FECHA_ENTREGA_FACTURA_LINEA'
          DataSet = dmFacturas.fxdstPrintLinFac
          DataSetName = 'Lineas Facturas'
          DisplayFormat.FormatStr = 'dd/mm/yyyy'
          DisplayFormat.Kind = fkDateTime
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Lineas Facturas."FECHA_ENTREGA_FACTURA_LINEA"]')
          ParentFont = False
        end
        object LineasFacturasDESCRIPCION_ARTICULO_FACTURA_LINEA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 22.677180000000000000
          Top = 3.779530000000000000
          Width = 272.126160000000000000
          Height = 18.897650000000000000
          StretchMode = smMaxHeight
          DataField = 'DESCRIPCION_ARTICULO_FACTURA_LINEA'
          DataSet = dmFacturas.fxdstPrintLinFac
          DataSetName = 'Lineas Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          LineSpacing = 4.000000000000000000
          Memo.UTF8W = (
            '[Lineas Facturas."DESCRIPCION_ARTICULO_FACTURA_LINEA"]')
          ParentFont = False
          WordBreak = True
        end
      end
      object Memo19: TfrxMemoView
        AllowVectorExport = True
        Left = 876.850974650000000000
        Top = 619.842920000000000000
        Width = 79.370130000000000000
        Height = 18.897650000000000000
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.2m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_LIQUIDO_FACTURA"]')
        ParentFont = False
      end
      object Memo21: TfrxMemoView
        IndexTag = 1
        AllowVectorExport = True
        Left = 876.850974650000000000
        Top = 582.047620000000000000
        Width = 79.370130000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'RetencionTotalOnBeforePrint'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.2m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[<Facturas."TOTAL_RETENCION_FACTURA"> * (-1)]')
        ParentFont = False
      end
      object Memo23: TfrxMemoView
        AllowVectorExport = True
        Left = 877.969094650000000000
        Top = 553.701145000000000000
        Width = 79.370130000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'ImpuestosTotalOnBeforePrint'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.2m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_IMPUESTOS_FACTURA"]')
        ParentFont = False
      end
      object Memo25: TfrxMemoView
        AllowVectorExport = True
        Left = 877.969094650000000000
        Top = 525.354670000000000000
        Width = 79.370130000000000000
        Height = 18.897650000000000000
        OnBeforePrint = 'ImpuestosTotalOnBeforePrint'
        DisplayFormat.DecimalSeparator = ','
        DisplayFormat.FormatStr = '%2.2m'
        DisplayFormat.Kind = fkNumeric
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Frame.Typ = []
        HAlign = haRight
        Memo.UTF8W = (
          '[Facturas."TOTAL_BASES_FACTURA"]')
        ParentFont = False
      end
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 400.630180000000000000
        Top = 18.897650000000000000
        Width = 737.008350000000000000
        object Memo7: TfrxMemoView
          AllowVectorExport = True
          Left = 13.559060000000000000
          Top = 362.834880000000000000
          Width = 710.551640000000000000
          Height = 26.456710000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo1: TfrxMemoView
          AllowVectorExport = True
          Left = 319.700990000000000000
          Top = 45.354360000000000000
          Width = 109.606370000000000000
          Height = 22.677180000000000000
          AutoWidth = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -21
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsUnderline]
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            'FACTURA')
          ParentFont = False
        end
        object Memo2: TfrxMemoView
          AllowVectorExport = True
          Left = 7.559060000000000000
          Top = 207.874150000000000000
          Width = 355.275820000000000000
          Height = 136.063080000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object Memo3: TfrxMemoView
          AllowVectorExport = True
          Left = 379.512060000000000000
          Top = 207.874150000000000000
          Width = 343.937230000000000000
          Height = 136.063080000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object FacturasRAZONSOCIAL_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 211.653680000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          DataField = 'RAZONSOCIAL_EMPRESA_FACTURA'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."RAZONSOCIAL_EMPRESA_FACTURA"]')
          ParentFont = False
        end
        object FacturasDIRECCION1_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 234.330860000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."DIRECCION1_EMPRESA_FACTURA"] [Facturas."DIRECCION2_EM' +
              'PRESA_FACTURA"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object FacturasCPOSTAL_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 256.228510000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."CPOSTAL_EMPRESA_FACTURA"]   [Facturas."POBLACION_EMPR' +
              'ESA_FACTURA"]')
          ParentFont = False
        end
        object FacturasPROVINCIA_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 278.362400000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasPROVINCIA_EMPRESA_FACTURAOnBeforePrint'
          OnPreviewClick = 'FacturasPROVINCIA_EMPRESA_FACTURAOnPreviewClick'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PROVINCIA_EMPRESA_FACTURA"]')
          ParentFont = False
        end
        object FacturasMOVIL_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 301.039580000000000000
          Width = 83.149660000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."MOVIL_EMPRESA_FACTURA"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object Memo4: TfrxMemoView
          AllowVectorExport = True
          Left = 13.559060000000000000
          Top = 173.858380000000000000
          Width = 52.913420000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Emisor')
          ParentFont = False
        end
        object Memo5: TfrxMemoView
          AllowVectorExport = True
          Left = 380.173470000000000000
          Top = 173.858380000000000000
          Width = 75.590600000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Receptor')
          ParentFont = False
        end
        object FacturasRAZONSOCIAL_CLIENTE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 211.653680000000000000
          Width = 347.716760000000000000
          Height = 18.897650000000000000
          DataField = 'RAZONSOCIAL_CLIENTE_FACTURA'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."RAZONSOCIAL_CLIENTE_FACTURA"]')
          ParentFont = False
        end
        object FacturasDIRECCION1_EMPRESA_FACTURA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 234.330860000000000000
          Width = 347.716760000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."DIRECCION1_CLIENTE_FACTURA"] [Facturas."DIRECCION2_CL' +
              'IENTE_FACTURA"]')
          ParentFont = False
        end
        object FacturasCPOSTAL_CLIENTE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 256.228510000000000000
          Width = 302.362400000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."CPOSTAL_CLIENTE_FACTURA"]   [Facturas."POBLACION_CLIE' +
              'NTE_FACTURA"]')
          ParentFont = False
        end
        object FacturasPROVINCIA_CLIENTE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 278.362400000000000000
          Width = 347.716760000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasPROVINCIA_CLIENTE_FACTURAOnBeforePrint'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[Facturas."PROVINCIA_CLIENTE_FACTURA"]   [Facturas."NOMBRE_PAIS_' +
              'CLIENTE_FACTURA"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object FacturasMOVIL_CLIENTE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 322.464750000000000000
          Width = 264.567100000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'NIF: [Facturas."NIF_CLIENTE_FACTURA"]')
          ParentFont = False
        end
        object Memo6: TfrxMemoView
          AllowVectorExport = True
          Left = 13.559060000000000000
          Top = 90.708720000000000000
          Width = 340.157700000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -15
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Fecha: [Facturas."FECHA_FACTURA"]')
          ParentFont = False
        end
        object FacturasNRO_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 13.559060000000000000
          Top = 120.944960000000000000
          Width = 340.157700000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -15
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              'N'#250'mero de Factura: [Facturas."SERIE_FACTURA"].[Facturas."NRO_FAC' +
              'TURA"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object Memo8: TfrxMemoView
          AllowVectorExport = True
          Left = 17.779530000000000000
          Top = 366.614410000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Descripci'#243'n')
          ParentFont = False
        end
        object Memo9: TfrxMemoView
          AllowVectorExport = True
          Left = 635.740570000000000000
          Top = 366.614410000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Total')
          ParentFont = False
        end
        object Memo10: TfrxMemoView
          AllowVectorExport = True
          Left = 389.834880000000000000
          Top = 366.614410000000000000
          Width = 75.590600000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Cantidad')
          ParentFont = False
        end
        object Memo11: TfrxMemoView
          AllowVectorExport = True
          Left = 476.205010000000000000
          Top = 366.614410000000000000
          Width = 83.149660000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Precio')
          ParentFont = False
        end
        object TituloIvaColumna: TfrxMemoView
          AllowVectorExport = True
          Left = 572.929500000000000000
          Top = 366.614410000000000000
          Width = 75.590600000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          HAlign = haCenter
          Memo.UTF8W = (
            '% [Facturas."PALABRA_REPORTS_ZONA_IVA_FACTURA"]')
          ParentFont = False
        end
        object FechaEntregaTittle: TfrxMemoView
          AllowVectorExport = True
          Left = 306.126160000000000000
          Top = 366.614410000000000000
          Width = 90.708720000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FechaEntregaTittleOnBeforePrint'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Fecha Entrega')
          ParentFont = False
        end
        object FacturasMOVIL_CLIENTE_FACTURA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 392.953000000000000000
          Top = 301.039580000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."MOVIL_CLIENTE_FACTURA"]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object FacturasNIF_EMPRESA_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 20.779530000000000000
          Top = 322.464750000000000000
          Width = 272.126160000000000000
          Height = 18.897650000000000000
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Frame.Width = 1.500000000000000000
          Memo.UTF8W = (
            'NIF: [Facturas."NIF_EMPRESA_FACTURA"]')
          ParentFont = False
        end
        object Memo12: TfrxMemoView
          AllowVectorExport = True
          Left = 468.661720000000000000
          Top = 301.039592200000000000
          Width = 249.448980000000000000
          Height = 18.897637800000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."EMAIL_CLIENTE_FACTURA"]')
          ParentFont = False
        end
        object Memo13: TfrxMemoView
          AllowVectorExport = True
          Left = 506.457020000000000000
          Top = 94.488250000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          ParentFont = False
        end
        object Memo14: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 109.606370000000000000
          Top = 301.362400000000000000
          Width = 249.448980000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."EMAIL_EMPRESA_FACTURA"]')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 22.677180000000000000
        Top = 480.000310000000000000
        Visible = False
        Width = 737.008350000000000000
        DataSet = dmFacturas.fxdsPrintFac
        DataSetName = 'Facturas'
        RowCount = 0
        object FacturasNRO_FACTURA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 64.252010000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          DataField = 'NRO_FACTURA'
          DataSet = dmFacturas.fxdsPrintFac
          DataSetName = 'Facturas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."NRO_FACTURA"]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        FillType = ftBrush
        FillGap.Top = 0
        FillGap.Left = 0
        FillGap.Bottom = 0
        FillGap.Right = 0
        Frame.Typ = []
        Height = 249.448980000000000000
        Top = 612.283860000000000000
        Width = 737.008350000000000000
        OnBeforePrint = 'PageFooter1OnBeforePrint'
        object CajaIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 18.897650000000000000
          Top = 32.677180000000000000
          Width = 468.661417320000000000
          Height = 113.385900000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object CajaTitulosIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 18.897650000000000000
          Top = 6.220470000000000000
          Width = 468.661417320000000000
          Height = 26.456710000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          ParentFont = False
        end
        object mTotalFactura: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 507.677504650000000000
          Top = 124.724490000000000000
          Width = 215.433210000000000000
          Height = 22.677180000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Frame.Width = 1.500000000000000000
          Memo.UTF8W = (
            'Total Factura ')
          ParentFont = False
        end
        object BaseImponibleN: TfrxMemoView
          AllowVectorExport = True
          Left = 22.677194650000000000
          Top = 36.456710000000000000
          Width = 90.708720000000000000
          Height = 15.118120000000000000
          OnBeforePrint = 'BaseImponibleNOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASEI_IVAN_FACTURA"]')
          ParentFont = False
        end
        object BaseImponibleCajaIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 26.456724650000000000
          Top = 10.000000000000000000
          Width = 102.047310000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Base Imponible')
          ParentFont = False
        end
        object BaseImponibleE: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 18.897664650000000000
          Top = 115.826840000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'BaseImponibleEOnBeforePrint'
          DataField = 'TOTAL_BASEI_IVAE_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASEI_IVAE_FACTURA"]')
          ParentFont = False
        end
        object TituloPorcenCajaIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 10.000000000000000000
          Width = 68.031540000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '% [Facturas."PALABRA_REPORTS_ZONA_IVA_FACTURA"]')
          ParentFont = False
        end
        object TituloTotalCajaIVA: TfrxMemoView
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 10.000000000000000000
          Width = 86.929190000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Total [Facturas."PALABRA_REPORTS_ZONA_IVA_FACTURA"]')
          ParentFont = False
        end
        object RetencionPorc: TfrxMemoView
          AllowVectorExport = True
          Left = 313.701004650000000000
          Top = 10.000000000000000000
          Width = 71.811070000000000000
          Height = 15.118120000000000000
          OnBeforePrint = 'RetencionPorcOnBeforePrint'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '% R.E.')
          ParentFont = False
        end
        object RetencionTot: TfrxMemoView
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 10.000000000000000000
          Width = 71.811070000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Total R.E.')
          ParentFont = False
        end
        object FacturasTOTAL_IVAN_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 36.456710000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_IVAN_FACTURA"]')
          ParentFont = False
        end
        object FacturasPORCEN_IVAN_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 36.456710000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCEN_IVAN_FACTURA"]%')
          ParentFont = False
        end
        object FacturasPORCEN_IVAR_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 62.913420000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCEN_IVAR_FACTURA"]%')
          ParentFont = False
        end
        object FacturasPORCEN_IVAS_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 89.370130000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCEN_IVAS_FACTURA"]%')
          ParentFont = False
        end
        object FacturasPORCEN_IVAE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 147.401684650000000000
          Top = 115.826840000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCEN_IVAE_FACTURA"]%')
          ParentFont = False
        end
        object FacturasTOTAL_IVAR_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 62.913420000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DataField = 'TOTAL_IVAR_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_IVAR_FACTURA"]')
          ParentFont = False
        end
        object FacturasTOTAL_IVAS_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 89.370130000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DataField = 'TOTAL_IVAS_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_IVAS_FACTURA"]')
          ParentFont = False
        end
        object FacturasTOTAL_IVAE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 222.992284650000000000
          Top = 115.826840000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DataField = 'TOTAL_IVAE_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_IVAE_FACTURA"]')
          ParentFont = False
        end
        object FacturasPORCEN_REN_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 313.701004650000000000
          Top = 36.456710000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCEN_REN_FACTURA"]%')
          ParentFont = False
        end
        object FacturasPORCEN_RER_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 313.701004650000000000
          Top = 62.913420000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCEN_RER_FACTURA"]%')
          ParentFont = False
        end
        object FacturasPORCEN_REE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 313.701004650000000000
          Top = 115.826840000000000000
          Width = 56.692950000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCEN_REE_FACTURA"]%')
          ParentFont = False
        end
        object FacturasPORCEN_RES_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 313.701004650000000000
          Top = 89.370130000000000000
          Width = 52.913420000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."PORCEN_RES_FACTURA"]%')
          ParentFont = False
        end
        object FacturasTOTAL_REN_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 36.456710000000000000
          Width = 64.252010000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasTOTAL_REN_FACTURAOnBeforePrint'
          DataField = 'TOTAL_REN_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."TOTAL_REN_FACTURA"]')
          ParentFont = False
        end
        object FacturasTOTAL_REE_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 115.826840000000000000
          Width = 64.252010000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasTOTAL_REE_FACTURAOnBeforePrint'
          DataField = 'TOTAL_REE_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."TOTAL_REE_FACTURA"]')
          ParentFont = False
        end
        object BaseImponibleR: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 18.897664650000000000
          Top = 62.913420000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'BaseImponibleROnBeforePrint'
          DataField = 'TOTAL_BASEI_IVAR_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASEI_IVAR_FACTURA"]')
          ParentFont = False
        end
        object BaseImponibleS: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 18.897664650000000000
          Top = 89.370130000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'BaseImponibleSOnBeforePrint'
          DataField = 'TOTAL_BASEI_IVAS_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASEI_IVAS_FACTURA"]')
          ParentFont = False
        end
        object FacturasTOTAL_RER_FACTURA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 62.913420000000000000
          Width = 68.031540000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasTOTAL_RER_FACTURAOnBeforePrint'
          DataField = 'TOTAL_RER_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."TOTAL_RER_FACTURA"]')
          ParentFont = False
        end
        object FacturasTOTAL_RES_FACTURA1: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 394.630194650000000000
          Top = 89.370130000000000000
          Width = 68.031540000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'FacturasTOTAL_RES_FACTURAOnBeforePrint'
          DataField = 'TOTAL_RES_FACTURA'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[Facturas."TOTAL_RES_FACTURA"]')
          ParentFont = False
        end
        object Retencion: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 507.118444650000000000
          Top = 86.929190000000000000
          Width = 143.622140000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Retenci'#243'n IRPF [Facturas."PORCEN_RETENCION_FACTURA"]%')
          ParentFont = False
        end
        object txtRetencionTotal: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 641.079174650000000000
          Top = 86.929190000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'RetencionTotalOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[<Facturas."TOTAL_RETENCION_FACTURA"> * (-1)]')
          ParentFont = False
        end
        object ImpuestosTotal: TfrxMemoView
          AllowVectorExport = True
          Left = 642.197294650000000000
          Top = 58.582715000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'ImpuestosTotalOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_IMPUESTOS_FACTURA"]')
          ParentFont = False
        end
        object Impuestos: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 508.236564650000000000
          Top = 58.582715000000000000
          Width = 143.622140000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'ImpuestosOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Total IVA + RE')
          ParentFont = False
        end
        object TotalBases: TfrxMemoView
          AllowVectorExport = True
          Left = 642.197294650000000000
          Top = 30.236240000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          OnBeforePrint = 'ImpuestosTotalOnBeforePrint'
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_BASES_FACTURA"]')
          ParentFont = False
        end
        object TotalBaseImponible: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 508.236564650000000000
          Top = 30.236240000000000000
          Width = 143.622140000000000000
          Height = 18.897650000000000000
          DisplayFormat.DecimalSeparator = ','
          DisplayFormat.FormatStr = '%g'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Total Base Imponible')
          ParentFont = False
        end
        object FacturasCOMENTARIOS_FACTURA: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 19.897664650000000000
          Top = 188.401670000000000000
          Width = 710.551640000000000000
          Height = 30.236240000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            
              '[VarToStr(<Facturas."TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA">)+'#39'  '#39 +
              '+'
            
              ' VarToStr(<Facturas."TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA">) +'#39'  ' +
              #39'+'
            ' VarToStr(<Facturas."COMENTARIOS_FACTURA">)]')
          ParentFont = False
        end
        object FormaPago: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 22.677194650000000000
          Top = 157.401670000000000000
          Width = 699.213050000000000000
          Height = 37.795300000000000000
          OnBeforePrint = 'FormaPagoOnBeforePrint'
          StretchMode = smActualHeight
          AutoWidth = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Forma de Pago: [Facturas."DESCRIPCION_FORMAPAGO"]')
          ParentFont = False
        end
        object mNumPaginas: TfrxMemoView
          AllowVectorExport = True
          Left = 616.283860000000000000
          Top = 219.771800000000000000
          Width = 113.385900000000000000
          Height = 22.677180000000000000
          OnBeforePrint = 'mNumPaginasOnBeforePrint'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'P'#225'gina [<Page>] de [<TotalPages#>]')
          ParentFont = False
          Formats = <
            item
            end
            item
            end>
        end
        object Continua: TfrxMemoView
          AllowVectorExport = True
          Left = 22.677180000000000000
          Width = 309.921460000000000000
          Height = 22.677180000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          HAlign = haRight
          Memo.UTF8W = (
            'Contin'#250'a en la siguiente p'#225'gina ...')
          ParentFont = False
        end
        object mTotalFacturaCtd: TfrxMemoView
          AllowVectorExport = True
          Left = 596.606680000000000000
          Top = 124.724490000000000000
          Width = 124.724490000000000000
          Height = 22.677180000000000000
          DisplayFormat.FormatStr = '%2.2m'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Frame.Width = 1.500000000000000000
          HAlign = haRight
          Memo.UTF8W = (
            '[Facturas."TOTAL_LIQUIDO_FACTURA"]')
          ParentFont = False
        end
      end
    end
  end
end
