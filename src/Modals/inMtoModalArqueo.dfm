inherited frmModalArqueo: TfrmModalArqueo
  Caption = 'Arqueo de caja'
  ClientHeight = 510
  ClientWidth = 880
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  TextHeight = 17
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 880
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 0
    object lblTituloDesde: TcxLabel
      Left = 16
      Top = 6
      Caption = 'Fecha desde'
      Style.TextColor = clNavy
    end
    object dteFechaDesde: TcxDateEdit
      Left = 16
      Top = 28
      TabOrder = 0
      Width = 130
      Properties.OnChange = dteFechaDesdePropertiesChange
    end
    object lblF10: TcxLabel
      Left = 152
      Top = 32
      Caption = 'F10'
      Style.Font.Style = [fsBold]
      Style.TextColor = clBlue
      Style.IsFontAssigned = True
    end
    object lblTituloHasta: TcxLabel
      Left = 210
      Top = 6
      Caption = 'Fecha hasta'
      Style.TextColor = clNavy
    end
    object dteFechaHasta: TcxDateEdit
      Left = 210
      Top = 28
      TabOrder = 1
      Width = 130
      Properties.OnChange = dteFechaHastaPropertiesChange
    end
    object lblF6: TcxLabel
      Left = 346
      Top = 32
      Caption = 'F6'
      Style.Font.Style = [fsBold]
      Style.TextColor = clBlue
      Style.IsFontAssigned = True
    end
    object lblTituloVentas: TcxLabel
      Left = 430
      Top = 6
      Caption = 'Ventas'
      Style.TextColor = clNavy
    end
    object lblVentas: TcxLabel
      Left = 430
      Top = 28
      AutoSize = False
      Caption = '0'
      Style.Font.Height = -19
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Properties.Alignment.Horz = taRightJustify
      Height = 28
      Width = 90
    end
    object btnRecalcular: TcxButton
      Left = 700
      Top = 22
      Width = 160
      Height = 35
      Caption = 'Recalcular (F5)'
      TabOrder = 2
      OnClick = btnRecalcularClick
    end
  end
  object pnlBody: TPanel [1]
    Left = 0
    Top = 70
    Width = 880
    Height = 390
    Align = alClient
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 1
    object pnlLineas: TPanel
      Left = 8
      Top = 8
      Width = 360
      Height = 130
      BevelInner = bvLowered
      BevelOuter = bvNone
      Color = clBtnFace
      ParentBackground = False
      TabOrder = 0
      object lblLineasTitulo: TcxLabel
        Left = 10
        Top = 6
        Caption = 'L'#237'neas art'#237'culos'
        Style.Font.Style = [fsBold]
        Style.TextColor = clNavy
        Style.IsFontAssigned = True
      end
      object lblLinBrutoLbl: TcxLabel
        Left = 16
        Top = 34
        Caption = '+ Bruto'
      end
      object lblLinBruto: TcxLabel
        Left = 190
        Top = 34
        AutoSize = False
        Caption = ''
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 150
      end
      object lblLinDescuentoLbl: TcxLabel
        Left = 16
        Top = 60
        Caption = '- Descuento'
      end
      object lblLinDescuento: TcxLabel
        Left = 190
        Top = 60
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 150
      end
      object lblLinNetoLbl: TcxLabel
        Left = 16
        Top = 92
        Caption = '= Bruto'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
      end
      object lblLinNeto: TcxLabel
        Left = 190
        Top = 92
        AutoSize = False
        Caption = ''
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 150
      end
    end
    object pnlOperaciones: TPanel
      Left = 376
      Top = 8
      Width = 496
      Height = 130
      BevelInner = bvLowered
      BevelOuter = bvNone
      Color = clBtnFace
      ParentBackground = False
      TabOrder = 1
      object lblOpeTitulo: TcxLabel
        Left = 10
        Top = 6
        Caption = 'Operaciones'
        Style.Font.Style = [fsBold]
        Style.TextColor = clNavy
        Style.IsFontAssigned = True
      end
      object lblOpeDescuentosLbl: TcxLabel
        Left = 16
        Top = 34
        Caption = '- Descuentos'
      end
      object lblOpeDescuentos: TcxLabel
        Left = 175
        Top = 34
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 130
      end
      object lblOpeNetoLbl: TcxLabel
        Left = 16
        Top = 60
        Caption = '= Neto'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
      end
      object lblOpeNeto: TcxLabel
        Left = 175
        Top = 60
        AutoSize = False
        Caption = ''
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 130
      end
      object lblOpeCreditoLbl: TcxLabel
        Left = 320
        Top = 34
        Caption = '- Pr'#233'stamos'
      end
      object lblOpeCredito: TcxLabel
        Left = 410
        Top = 34
        AutoSize = False
        Caption = ''
        Style.TextColor = clRed
        Style.IsFontAssigned = True
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 76
      end
    end
    object pnlCobros: TPanel
      Left = 8
      Top = 146
      Width = 864
      Height = 230
      BevelInner = bvLowered
      BevelOuter = bvNone
      Color = clBtnFace
      ParentBackground = False
      TabOrder = 2
      object lblCobrosTitulo: TcxLabel
        Left = 10
        Top = 6
        Caption = 'Cobros'
        Style.Font.Style = [fsBold]
        Style.TextColor = clNavy
        Style.IsFontAssigned = True
      end
      object lblCobValesRecLbl: TcxLabel
        Left = 16
        Top = 34
        Caption = '- Vales recogidos'
      end
      object lblCobValesRec: TcxLabel
        Left = 190
        Top = 34
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 150
      end
      object lblCobValesEmiLbl: TcxLabel
        Left = 16
        Top = 60
        Caption = '+ Vales emitidos'
      end
      object lblCobValesEmi: TcxLabel
        Left = 190
        Top = 60
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 150
      end
      object lblCobClientesLbl: TcxLabel
        Left = 16
        Top = 86
        Caption = '+ Cobros clientes'
      end
      object lblCobClientes: TcxLabel
        Left = 190
        Top = 86
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 150
      end
      object lblCobPendienteLbl: TcxLabel
        Left = 16
        Top = 112
        Caption = '- Pendiente cobro'
      end
      object lblCobPendiente: TcxLabel
        Left = 190
        Top = 112
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 150
      end
      object lblCobIngresosLbl: TcxLabel
        Left = 16
        Top = 144
        Caption = '= Ingresos caja'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
      end
      object lblCobIngresos: TcxLabel
        Left = 190
        Top = 144
        AutoSize = False
        Caption = ''
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 150
      end
      object lblEftIngresosLbl: TcxLabel
        Left = 400
        Top = 34
        Caption = 'Eftvo. ingresos'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
      end
      object lblEftIngresos: TcxLabel
        Left = 690
        Top = 34
        AutoSize = False
        Caption = ''
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 160
      end
      object lblEftEntradasLbl: TcxLabel
        Left = 400
        Top = 60
        Caption = '+ Efectivo entradas'
      end
      object lblEftEntradas: TcxLabel
        Left = 690
        Top = 60
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 160
      end
      object lblEftSalidasLbl: TcxLabel
        Left = 400
        Top = 86
        Caption = '- Efectivo salidas'
      end
      object lblEftSalidas: TcxLabel
        Left = 690
        Top = 86
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 160
      end
      object lblEftAnteriorLbl: TcxLabel
        Left = 400
        Top = 112
        Caption = '+ Efectivo anterior'
      end
      object lblEftAnterior: TcxLabel
        Left = 690
        Top = 112
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 160
      end
      object lblEftCajaLbl: TcxLabel
        Left = 400
        Top = 138
        Caption = '= Efectivo en caja'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
      end
      object lblEftCaja: TcxLabel
        Left = 690
        Top = 138
        AutoSize = False
        Caption = ''
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 160
      end
      object lblTarjetasLbl: TcxLabel
        Left = 400
        Top = 164
        Caption = '+ Otros (tarj, bonos, divisa, cripto)'
      end
      object lblTarjetas: TcxLabel
        Left = 690
        Top = 164
        AutoSize = False
        Caption = ''
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 160
      end
      object lblSaldoLbl: TcxLabel
        Left = 400
        Top = 196
        Caption = '= Saldo efectivo + otros (a recontar)'
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
      end
      object lblSaldo: TcxLabel
        Left = 690
        Top = 196
        AutoSize = False
        Caption = ''
        Style.Font.Style = [fsBold]
        Style.IsFontAssigned = True
        Properties.Alignment.Horz = taRightJustify
        Height = 21
        Width = 160
      end
    end
  end
  object pnlBottom: TPanel [2]
    Left = 0
    Top = 460
    Width = 880
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    Color = clBtnFace
    ParentBackground = False
    TabOrder = 2
    object lblESC: TcxLabel
      Left = 600
      Top = 14
      Caption = 'ESC'
      Style.Font.Style = [fsBold]
      Style.TextColor = clBlue
      Style.IsFontAssigned = True
    end
    object btnAtras: TcxButton
      Left = 650
      Top = 8
      Width = 200
      Height = 35
      Cancel = True
      Caption = 'Atr'#225's (ESC)'
      TabOrder = 0
      OnClick = btnAtrasClick
    end
  end
  object alArqueo: TActionList
    Left = 16
    Top = 540
    object actEscape: TAction
      Caption = 'Escape'
      ShortCut = 27
      OnExecute = actEscapeExecute
    end
    object actRecalcular: TAction
      Caption = 'Recalcular'
      ShortCut = 116
      OnExecute = actRecalcularExecute
    end
  end
end
