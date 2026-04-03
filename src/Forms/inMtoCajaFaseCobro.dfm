object frmMtoCajaFaseCobro: TfrmMtoCajaFaseCobro
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Fase de cobro'
  ClientHeight = 688
  ClientWidth = 836
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Lucida San'#180
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 18
  object pnlPrincipal: TPanel
    Left = 65
    Top = 0
    Width = 771
    Height = 688
    Align = alClient
    BevelOuter = bvNone
    Color = clCream
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 769
    ExplicitHeight = 680
    object pnlIzquierdo: TPanel
      Left = 0
      Top = 0
      Width = 523
      Height = 688
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
      ExplicitWidth = 521
      ExplicitHeight = 680
      object pnlContenedor: TPanel
        Left = 0
        Top = 0
        Width = 523
        Height = 688
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 521
        ExplicitHeight = 680
        object pnlTotales: TPanel
          Left = 6
          Top = 0
          Width = 515
          Height = 201
          BevelInner = bvRaised
          BevelKind = bkSoft
          TabOrder = 0
          object lblDescuento1: TcxLabel
            Left = 8
            Top = 61
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
            Top = 104
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
            Left = 275
            Top = 14
            Properties.Alignment.Horz = taCenter
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            Style.Color = clCream
            TabOrder = 4
            Text = '1'
            Width = 64
          end
          object txtBrutoLineas: TcxCurrencyEdit
            Left = 334
            Top = 14
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = ',0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            Style.Color = clCream
            TabOrder = 5
            Width = 171
          end
          object txtPorcenDtoLineal: TcxTextEdit
            Left = 243
            Top = 57
            Style.BorderStyle = ebsOffice11
            Style.Color = clCream
            TabOrder = 8
            Width = 96
          end
          object txtTotalPagar: TcxCurrencyEdit
            Left = 334
            Top = 139
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = ',0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            Style.Color = clWhite
            TabOrder = 10
            Width = 171
          end
          object txtDtoGlobal: TcxCurrencyEdit
            Left = 334
            Top = 100
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = ',0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            Style.Color = clCream
            TabOrder = 7
            Width = 171
          end
          object txtTotalDtoLineal: TcxCurrencyEdit
            Left = 334
            Top = 57
            Properties.Alignment.Horz = taRightJustify
            Style.Color = clCream
            TabOrder = 9
            Width = 171
          end
          object txtPorcenDtoGlobal: TcxCurrencyEdit
            Left = 243
            Top = 100
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = ',0.00 %'
            Properties.EditFormat = ',0.00 %'
            Properties.ReadOnly = False
            Properties.OnEditValueChanged = txtPorcenDtoGlobalPropertiesEditValueChanged
            Style.BorderStyle = ebsOffice11
            Style.Color = clWindow
            TabOrder = 6
            Width = 92
          end
        end
        object pnlCuenta: TPanel
          Left = 6
          Top = 196
          Width = 515
          Height = 108
          BevelInner = bvRaised
          BevelKind = bkSoft
          TabOrder = 1
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
            Left = 334
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
            Left = 334
            Top = 54
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
        object pnlCambioVales: TPanel
          Left = 6
          Top = 299
          Width = 515
          Height = 108
          BevelInner = bvRaised
          BevelKind = bkSoft
          TabOrder = 2
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
            Left = 334
            Top = 10
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
            Left = 334
            Top = 54
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = ',0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Properties.OnEditValueChanged = txtValeEmitidoPropertiesEditValueChanged
            Style.BorderStyle = ebsOffice11
            Style.Color = clWhite
            TabOrder = 3
            Width = 171
          end
        end
        object cxgrdFormasPago: TcxGrid
          Left = 5
          Top = 409
          Width = 514
          Height = 186
          BevelOuter = bvRaised
          BorderStyle = cxcbsNone
          TabOrder = 3
          object dbtvFormasPago: TcxGridDBTableView
            OnEditing = dbtvFormasPagoEditing
            OnEditChanged = dbtvFormasPagoEditChanged
            DataController.DataSource = dsFormasPago
            OptionsData.Deleting = False
            OptionsData.Inserting = False
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            Styles.Header = cxStyle1
            object cxgrdbclmnCodigo: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_FORMAP'
              Visible = False
              HeaderAlignmentHorz = taCenter
              Options.Editing = False
              Options.Focusing = False
              Width = 95
            end
            object dbmDescripcion: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_FORMAP'
              Options.Editing = False
              Options.Focusing = False
              Styles.Header = cxStyle1
              Width = 254
            end
            object dbmImporte: TcxGridDBColumn
              Caption = 'Importe Entregado'
              DataBinding.FieldName = 'IMPORTE_ENTREGADO'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.EditFormat = ',0.00 '#8364';-,0.00 '#8364
              Properties.OnEditValueChanged = dbmImportePropertiesEditValueChanged
              OnGetDisplayText = dbmImporteGetDisplayText
              HeaderAlignmentHorz = taRightJustify
              Styles.Header = cxStyle1
              Width = 249
            end
            object dbtvFormasPagoColumn1: TcxGridDBColumn
              DataBinding.FieldName = 'ESDIVISA_FORMAP'
              Visible = False
            end
            object dbtvFormasPagoColumn2: TcxGridDBColumn
              DataBinding.FieldName = 'ES_CRIPTO_FORMAP'
              Visible = False
            end
            object dbtvFormasPagoColumn3: TcxGridDBColumn
              DataBinding.FieldName = 'ESIMPORTE_DIVISA'
              Visible = False
            end
          end
          object cxgrdlvlFormasPago: TcxGridLevel
            GridView = dbtvFormasPago
          end
        end
        object pnlFormasPago: TPanel
          Left = 1
          Top = 607
          Width = 521
          Height = 80
          Align = alBottom
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 4
          ExplicitTop = 599
          ExplicitWidth = 519
          object lblDescuento4: TcxLabel
            Left = 15
            Top = 43
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
            Left = 341
            Top = 39
            Properties.Alignment.Horz = taRightJustify
            Properties.DisplayFormat = ',0.00 '#8364
            Properties.EditFormat = ',0.00 '#8364
            Properties.ReadOnly = True
            Style.BorderStyle = ebsOffice11
            Style.Color = clCream
            TabOrder = 1
            Width = 171
          end
          object cxLabel1: TcxLabel
            Left = 15
            Top = 4
            Caption = 'Devoluci'#243'n de cambio'
            ParentColor = False
            ParentFont = False
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clNavy
            Style.Font.Height = -23
            Style.Font.Name = 'Lucida Sans'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            TabOrder = 2
          end
          object txtCambio: TcxCurrencyEdit
            Left = 341
            Top = 0
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
      end
    end
    object pnlDerecho: TPanel
      Left = 523
      Top = 0
      Width = 248
      Height = 688
      Align = alRight
      BevelOuter = bvNone
      Color = clCream
      ParentBackground = False
      TabOrder = 1
      ExplicitLeft = 521
      ExplicitHeight = 680
      object pnlBotones: TPanel
        Left = 0
        Top = 0
        Width = 248
        Height = 492
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
        ExplicitHeight = 484
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
          OnClick = btnSinTicketClick
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
          OnClick = btnSinTicketClick
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
          OnClick = btnConTicketClick
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
          OnClick = btnConTicketClick
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
          OnClick = btnSinPreciosClick
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
          OnClick = btnSinPreciosClick
        end
        object btnDeposito: TcxButton
          Left = 89
          Top = 149
          Width = 155
          Height = 51
          Caption = '&Pr'#233'stamo'
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
          OnClick = btnF7Click
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
          OnClick = btnF6Click
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
          OnClick = btnBuscarValeClick
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
          Caption = 'Rellenar'
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
          OnClick = btnBuscarTClick
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
          OnClick = btnF3Click
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
        Top = 492
        Width = 248
        Height = 196
        Align = alBottom
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 1
        ExplicitTop = 484
        object lblNumDoc: TcxLabel
          Left = 30
          Top = 6
          Caption = 'N'#186' doc. venta'
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
          Left = 32
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
          Width = 209
        end
        object cbbSerie1: TcxComboBox
          Left = 32
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
          Width = 209
        end
      end
    end
  end
  object pnlLogoLeft: TPanel
    Left = 0
    Top = 0
    Width = 65
    Height = 688
    Align = alLeft
    TabOrder = 1
    ExplicitHeight = 680
    object cxLabel3: TcxLabel
      Left = 1
      Top = 172
      AutoSize = False
      Caption = 'Veri*Factu'
      ParentFont = False
      Style.BorderStyle = ebsOffice11
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clNavy
      Style.Font.Height = -36
      Style.Font.Name = 'Arial Black'
      Style.Font.Style = [fsBold]
      Style.Shadow = True
      Style.IsFontAssigned = True
      Properties.Angle = 90
      Properties.LabelStyle = cxlsLowered
      Properties.LineOptions.Alignment = cxllaTop
      Properties.LineOptions.Visible = True
      Properties.Orientation = cxoRight
      Properties.WordWrap = True
      TabOrder = 0
      Height = 220
      Width = 58
    end
    object cxLabel2: TcxLabel
      Left = 1
      Top = 398
      AutoSize = False
      Caption = 'Fzam'
      ParentFont = False
      Style.BorderStyle = ebsOffice11
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clOlive
      Style.Font.Height = -36
      Style.Font.Name = 'Arial Black'
      Style.Font.Style = [fsBold]
      Style.Shadow = True
      Style.IsFontAssigned = True
      Properties.Angle = 90
      Properties.LabelStyle = cxlsLowered
      Properties.LineOptions.Alignment = cxllaTop
      Properties.LineOptions.Visible = True
      Properties.Orientation = cxoRight
      Properties.WordWrap = True
      TabOrder = 1
      Height = 113
      Width = 58
    end
  end
  object dsFormasPago: TDataSource
    Left = 472
    Top = 512
  end
  object ActionList1: TActionList
    Left = 304
    Top = 328
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
    object actBuscarT: TAction
      Caption = 'actBuscarT'
      ShortCut = 114
      OnExecute = actBuscarTExecute
    end
    object actBuscarVale: TAction
      Caption = 'BuscarVale'
      ShortCut = 117
      OnExecute = actBuscarValeExecute
    end
    object actSinTicket: TAction
      Caption = 'SinTicket'
      ShortCut = 122
      OnExecute = actSinTicketExecute
    end
  end
  object cxStyleRepository1: TcxStyleRepository
    PixelsPerInch = 96
    object cxStyle1: TcxStyle
      AssignedValues = [svColor, svTextColor]
      Color = clSkyBlue
      TextColorType = AlphaColor
      TextColorValue = -16744448
    end
  end
end
