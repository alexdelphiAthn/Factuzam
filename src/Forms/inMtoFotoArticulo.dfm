inherited frmFotoArticulo: TfrmFotoArticulo
  Caption = 'Foto del art'#237'culo / SKU'
  ClientHeight = 720
  ClientWidth = 720
  FormStyle = fsStayOnTop
  Position = poScreenCenter
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  ExplicitWidth = 736
  ExplicitHeight = 759
  TextHeight = 19
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 720
    Height = 225
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object rgResolucion: TcxRadioGroup
      Left = 8
      Top = 4
      Caption = ' Resoluci'#243'n '
      Properties.Columns = 3
      Properties.Items = <
        item
          Caption = '300'
          Value = '300'
        end
        item
          Caption = '600'
          Value = '600'
        end
        item
          Caption = 'Real'
          Value = 'real'
        end>
      Properties.OnEditValueChanged = rgResolucionPropertiesEditValueChanged
      ItemIndex = 0
      Style.BorderStyle = ebsOffice11
      TabOrder = 0
      Height = 65
      Width = 360
    end
    object lblOrigen: TcxLabel
      Left = 380
      Top = 24
      Caption = 'Sin foto'
      Properties.WordWrap = True
      Width = 332
      AnchorY = 32
    end
    object btnCambiarArt: TcxButton
      Left = 8
      Top = 80
      Width = 220
      Height = 40
      Caption = 'Cambiar foto del &art'#237'culo'
      TabOrder = 1
      OnClick = btnCambiarArtClick
    end
    object btnCambiarSku: TcxButton
      Left = 240
      Top = 80
      Width = 220
      Height = 40
      Caption = 'Cambiar foto del &SKU / grupo'
      TabOrder = 2
      OnClick = btnCambiarSkuClick
    end
    object btnQuitar: TcxButton
      Left = 472
      Top = 80
      Width = 220
      Height = 40
      Caption = '&Quitar foto'
      TabOrder = 3
      OnClick = btnQuitarClick
    end
    object lblNivel: TcxLabel
      Left = 8
      Top = 132
      Caption = 'Nivel al que aplica el cambio:'
      Width = 220
    end
    object cbbNivelSku: TcxComboBox
      Left = 240
      Top = 130
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 4
      Width = 452
    end
    object btnRotarIzq: TcxButton
      Left = 8
      Top = 170
      Width = 220
      Height = 40
      Caption = 'Rotar &izquierda'
      TabOrder = 5
      OnClick = btnRotarIzqClick
    end
    object btnRotarDer: TcxButton
      Left = 240
      Top = 170
      Width = 220
      Height = 40
      Caption = 'Rotar &derecha'
      TabOrder = 6
      OnClick = btnRotarDerClick
    end
  end
  object pnlImage: TPanel [1]
    Left = 0
    Top = 225
    Width = 720
    Height = 495
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 1
    object imgFoto: TImage
      Left = 1
      Top = 1
      Width = 718
      Height = 493
      Align = alClient
      Center = True
      Proportional = True
      Stretch = True
    end
  end
  object dlgAbrirFoto: TOpenDialog
    Filter = 'Im'#225'genes|*.png;*.jpg;*.jpeg;*.bmp|Todos|*.*'
    Title = 'Seleccionar foto'
    Left = 624
    Top = 16
  end
  inherited Localizer1: TcxLocalizer
    Left = 624
    Top = 80
  end
end
