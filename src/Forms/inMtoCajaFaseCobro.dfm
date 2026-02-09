object frmMtoCajaFaseCobro: TfrmMtoCajaFaseCobro
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Fase de cobro'
  ClientHeight = 667
  ClientWidth = 774
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Lucida San'#180
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 18
  object pnlPrincipal: TPanel
    Left = 0
    Top = 0
    Width = 774
    Height = 667
    Align = alClient
    BevelOuter = bvNone
    Color = clCream
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 768
    ExplicitHeight = 615
    object pnlIzquierdo: TPanel
      Left = 0
      Top = 0
      Width = 526
      Height = 667
      Align = alClient
      BevelOuter = bvNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'Lucida Sans'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
      ExplicitWidth = 520
      ExplicitHeight = 615
      object pnlFormasPago: TPanel
        Left = 0
        Top = 600
        Width = 526
        Height = 67
        Align = alBottom
        BevelOuter = bvNone
        Color = clSilver
        ParentBackground = False
        TabOrder = 0
        ExplicitTop = 548
        ExplicitWidth = 520
        object lblDescuento4: TcxLabel
          Left = 26
          Top = 23
          Caption = 'Pendiente de cobro'
          ParentColor = False
          ParentFont = False
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = [fsBold]
          Style.IsFontAssigned = True
          TabOrder = 0
        end
        object txtPendienteCobro: TcxCurrencyEdit
          Left = 357
          Top = 25
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = ',0.00 '#8364
          Properties.EditFormat = ',0.00 '#8364
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clCream
          TabOrder = 1
          Width = 171
        end
      end
      object pnl1: TPanel
        Left = 16
        Top = 1
        Width = 522
        Height = 201
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvLowered
        TabOrder = 1
        object lblDescuento1: TcxLabel
          Left = 8
          Top = 100
          Caption = 'Imp dto. Lineal'
          ParentFont = False
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = [fsBold]
          Style.IsFontAssigned = True
          TabOrder = 0
        end
        object lblDescuento2: TcxLabel
          Left = 8
          Top = 143
          Caption = 'Imp TOTAL a pagar'
          ParentFont = False
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = [fsBold]
          Style.IsFontAssigned = True
          TabOrder = 1
        end
        object lblDescuento: TcxLabel
          Left = 8
          Top = 58
          Caption = '% Descuento'
          ParentFont = False
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = [fsBold]
          Style.IsFontAssigned = True
          TabOrder = 2
        end
        object lblSuma: TcxLabel
          Left = 8
          Top = 18
          Caption = 'Suma'
          ParentFont = False
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = [fsBold]
          Style.IsFontAssigned = True
          TabOrder = 3
        end
        object txtCantidadLineas: TcxTextEdit
          Left = 280
          Top = 17
          Properties.Alignment.Horz = taCenter
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clCream
          TabOrder = 4
          Text = '1'
          Width = 64
        end
        object txtBrutoLineas: TcxCurrencyEdit
          Left = 339
          Top = 17
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = ',0.00 '#8364
          Properties.EditFormat = ',0.00 '#8364
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clCream
          TabOrder = 5
          Width = 171
        end
        object txtPorcenDtoGlobal: TcxTextEdit
          Left = 261
          Top = 57
          Style.BorderStyle = ebsOffice11
          Style.Color = clWhite
          TabOrder = 6
          Width = 83
        end
        object txtPorcenDtoLineal: TcxTextEdit
          Left = 261
          Top = 99
          Style.BorderStyle = ebsOffice11
          Style.Color = clCream
          TabOrder = 7
          Width = 83
        end
        object txtTotalDtoLineal: TcxTextEdit
          Left = 339
          Top = 99
          Style.BorderStyle = ebsOffice11
          Style.Color = clWhite
          TabOrder = 8
          Width = 171
        end
        object txtTotalPagar: TcxCurrencyEdit
          Left = 339
          Top = 142
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = ',0.00 '#8364
          Properties.EditFormat = ',0.00 '#8364
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clWhite
          TabOrder = 9
          Width = 171
        end
        object txtDtoGlobal: TcxCurrencyEdit
          Left = 339
          Top = 57
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = ',0.00 '#8364
          Properties.EditFormat = ',0.00 '#8364
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clCream
          TabOrder = 10
          Width = 171
        end
      end
      object pnl11: TPanel
        Left = 16
        Top = 198
        Width = 522
        Height = 108
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvLowered
        TabOrder = 2
        object lblDescuento3: TcxLabel
          Left = 8
          Top = 58
          Caption = 'Pendiente de cobro'
          ParentFont = False
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = [fsBold]
          Style.IsFontAssigned = True
          TabOrder = 0
        end
        object lblSuma1: TcxLabel
          Left = 8
          Top = 18
          Caption = 'Importe a dejar A CUENTA'
          ParentFont = False
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = [fsBold]
          Style.IsFontAssigned = True
          TabOrder = 1
        end
        object txtDejarCuenta: TcxCurrencyEdit
          Left = 339
          Top = 17
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = ',0.00 '#8364
          Properties.EditFormat = ',0.00 '#8364
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clCream
          TabOrder = 2
          Width = 171
        end
        object txtPendienteCuenta: TcxCurrencyEdit
          Left = 339
          Top = 57
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = ',0.00 '#8364
          Properties.EditFormat = ',0.00 '#8364
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clCream
          TabOrder = 3
          Width = 171
        end
      end
      object pnl111: TPanel
        Left = 16
        Top = 302
        Width = 522
        Height = 108
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvLowered
        TabOrder = 3
        object lblDescuento31: TcxLabel
          Left = 8
          Top = 58
          Caption = 'Vale Emitido'
          ParentFont = False
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = [fsBold]
          Style.IsFontAssigned = True
          TabOrder = 0
        end
        object lblSuma11: TcxLabel
          Left = 8
          Top = 14
          Caption = 'Vale Recogido'
          ParentFont = False
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = [fsBold]
          Style.IsFontAssigned = True
          TabOrder = 1
        end
        object txtValeRecogido: TcxCurrencyEdit
          Left = 339
          Top = 13
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = ',0.00 '#8364
          Properties.EditFormat = ',0.00 '#8364
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clWhite
          TabOrder = 2
          Width = 171
        end
        object txtValeEmitido: TcxCurrencyEdit
          Left = 339
          Top = 57
          Properties.Alignment.Horz = taRightJustify
          Properties.DisplayFormat = ',0.00 '#8364
          Properties.EditFormat = ',0.00 '#8364
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clWhite
          TabOrder = 3
          Width = 171
        end
      end
      object cxgrdFormasPago: TcxGrid
        Left = 16
        Top = 410
        Width = 512
        Height = 186
        TabOrder = 4
        object dbtvFormasPago: TcxGridDBTableView
          DataController.DataSource = dsFormasPago
          OptionsData.Deleting = False
          OptionsData.Editing = False
          OptionsData.Inserting = False
          OptionsSelection.CellSelect = False
          OptionsView.GroupByBox = False
          OptionsView.Indicator = True
          object cxgrdbclmnCodigo: TcxGridDBColumn
            Caption = 'C'#243'digo'
            DataBinding.FieldName = 'CODIGO_FORMAP'
            HeaderAlignmentHorz = taCenter
            Width = 95
          end
          object dbmDescripcion: TcxGridDBColumn
            Caption = 'Descripci'#243'n'
            HeaderAlignmentHorz = taCenter
            Width = 226
          end
          object dbmImporte: TcxGridDBColumn
            Caption = 'Importe'
            PropertiesClassName = 'TcxCurrencyEditProperties'
            Properties.EditFormat = ',0.00 '#8364';-,0.00 '#8364
            HeaderAlignmentHorz = taRightJustify
            Width = 170
          end
        end
        object cxgrdlvlFormasPago: TcxGridLevel
          GridView = dbtvFormasPago
        end
      end
    end
    object pnlDerecho: TPanel
      Left = 526
      Top = 0
      Width = 248
      Height = 667
      Align = alRight
      BevelOuter = bvNone
      Color = clCream
      ParentBackground = False
      TabOrder = 1
      ExplicitLeft = 520
      ExplicitHeight = 615
      object pnlBotones: TPanel
        Left = 0
        Top = 0
        Width = 248
        Height = 471
        Align = alClient
        BevelOuter = bvNone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -23
        Font.Name = 'Lucida Sans'
        Font.Style = []
        ParentBackground = False
        ParentFont = False
        TabOrder = 0
        ExplicitHeight = 419
        object btnSinTicket: TcxButton
          Left = 89
          Top = 0
          Width = 155
          Height = 51
          Caption = 'Si&n ticket'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 0
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnF11: TcxButton
          Left = 18
          Top = 0
          Width = 74
          Height = 51
          Caption = 'F11'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 1
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold, fsUnderline]
          ParentFont = False
        end
        object btnConTicket: TcxButton
          Left = 89
          Top = 50
          Width = 155
          Height = 51
          Caption = '&Con ticket'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 2
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnF12: TcxButton
          Left = 18
          Top = 50
          Width = 74
          Height = 51
          Caption = 'F12'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 3
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold, fsUnderline]
          ParentFont = False
        end
        object btnSinPrecios: TcxButton
          Left = 89
          Top = 100
          Width = 155
          Height = 51
          Caption = 'Sin &precios'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 4
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnF10: TcxButton
          Left = 18
          Top = 100
          Width = 74
          Height = 51
          Caption = 'F10'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 5
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold, fsUnderline]
          ParentFont = False
        end
        object btnDeposito: TcxButton
          Left = 89
          Top = 149
          Width = 155
          Height = 51
          Caption = '&Dep'#243'sito'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 6
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnF7: TcxButton
          Left = 18
          Top = 149
          Width = 74
          Height = 51
          Caption = 'F7'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 7
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold, fsUnderline]
          ParentFont = False
        end
        object btnF8: TcxButton
          Left = 18
          Top = 198
          Width = 74
          Height = 51
          Caption = 'F8'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 8
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold, fsUnderline]
          ParentFont = False
        end
        object btnFactura: TcxButton
          Left = 89
          Top = 198
          Width = 155
          Height = 51
          Caption = '&Factura'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 9
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnF6: TcxButton
          Left = 18
          Top = 248
          Width = 74
          Height = 51
          Caption = 'F6'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 10
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold, fsUnderline]
          ParentFont = False
        end
        object btnBuscarVale: TcxButton
          Left = 89
          Top = 248
          Width = 155
          Height = 51
          Caption = '&Buscar Vale'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 11
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnMasDatos: TcxButton
          Left = 89
          Top = 298
          Width = 155
          Height = 51
          Caption = '&M'#225's datos'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 12
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnF2: TcxButton
          Left = 18
          Top = 298
          Width = 74
          Height = 51
          Caption = 'F2'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 13
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold, fsUnderline]
          ParentFont = False
        end
        object btnBuscarT: TcxButton
          Left = 89
          Top = 348
          Width = 155
          Height = 51
          Caption = 'Buscar &T'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 14
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnF3: TcxButton
          Left = 18
          Top = 348
          Width = 74
          Height = 51
          Caption = 'F3'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          Enabled = False
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 15
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold, fsUnderline]
          ParentFont = False
        end
        object btnAtras: TcxButton
          Left = 89
          Top = 398
          Width = 155
          Height = 51
          Caption = 'Atr'#225's'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clSilver
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          OptionsImage.Margin = 10
          TabOrder = 16
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold]
          ParentFont = False
          OnClick = btnAtrasClick
        end
        object btnESC: TcxButton
          Left = 18
          Top = 398
          Width = 74
          Height = 51
          Caption = 'ESC'
          Colors.Default = clBtnFace
          Colors.Normal = clBtnFace
          Colors.Hot = clBtnFace
          LookAndFeel.Kind = lfUltraFlat
          LookAndFeel.NativeStyle = False
          TabOrder = 17
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -23
          Font.Name = 'Lucida Sans'
          Font.Style = [fsBold, fsUnderline]
          ParentFont = False
          OnClick = btnESCClick
        end
      end
      object pnlDocumento: TPanel
        Left = 0
        Top = 471
        Width = 248
        Height = 196
        Align = alBottom
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 1
        ExplicitTop = 419
        object lblNumDoc: TcxLabel
          Left = 86
          Top = 8
          Caption = 'N'#186' doc.'
          ParentFont = False
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clNavy
          Style.Font.Height = -27
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = []
          Style.IsFontAssigned = True
          TabOrder = 0
        end
        object edtNumeroDoc: TcxTextEdit
          Left = 30
          Top = 94
          ParentFont = False
          Properties.Alignment.Horz = taCenter
          Properties.CharCase = ecUpperCase
          Properties.MaxLength = 8
          Properties.ReadOnly = True
          Style.BorderStyle = ebsOffice11
          Style.Color = clCream
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clWindowText
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = []
          Style.IsFontAssigned = True
          TabOrder = 1
          Text = '00000000'
          Width = 217
        end
        object cbbSerie1: TcxComboBox
          Left = 62
          Top = 47
          ParentFont = False
          Style.Font.Charset = ANSI_CHARSET
          Style.Font.Color = clWindowText
          Style.Font.Height = -23
          Style.Font.Name = 'Lucida Sans'
          Style.Font.Style = []
          Style.IsFontAssigned = True
          TabOrder = 2
          Text = 'cbbSerie1'
          Width = 147
        end
      end
    end
  end
  object dsFormasPago: TDataSource
    Left = 472
    Top = 512
  end
  object vrtltbl1: TVirtualTable
    Left = 384
    Top = 328
    Data = {04000000000000000000}
  end
  object ActionList1: TActionList
    Left = 376
    Top = 336
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
  end
end
