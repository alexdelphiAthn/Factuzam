inherited frmFotoArticulo: TfrmFotoArticulo
  BorderIcons = [biSystemMenu]
  Caption = 'Foto del art'#237'culo / SKU'
  ClientHeight = 600
  ClientWidth = 720
  FormStyle = fsStayOnTop
  Position = poDesigned
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  ExplicitWidth = 736
  ExplicitHeight = 639
  TextHeight = 19
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 720
    Height = 38
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 722
    object btnToggle: TcxButton
      Left = 4
      Top = 4
      Width = 130
      Height = 30
      Caption = #9660' Controles'
      TabOrder = 0
      OnClick = btnToggleClick
    end
    object btnDescargarNube: TcxButton
      Left = 140
      Top = 4
      Width = 176
      Height = 30
      Caption = 'Bajar fotos del servidor'
      TabOrder = 1
      OnClick = btnDescargarNubeClick
    end
    object lblOrigen: TcxLabel
      Left = 324
      Top = 8
      Caption = 'Sin foto'
      Properties.WordWrap = True
      TabOrder = 2
      Visible = False
      Width = 69
      Transparent = True
    end
  end
  object pnlControles: TPanel [1]
    Left = 0
    Top = 38
    Width = 720
    Height = 180
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
    ExplicitWidth = 722
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
    object lblNivel: TcxLabel
      Left = 380
      Top = 4
      Caption = 'Nivel al que aplica el cambio:'
      TabOrder = 7
      Transparent = True
    end
    object cbbNivelSku: TcxComboBox
      Left = 380
      Top = 36
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 1
      Width = 332
    end
    object btnCambiarArt: TcxButton
      Left = 8
      Top = 84
      Width = 220
      Height = 40
      Caption = 'Cambiar foto del &art'#237'culo'
      TabOrder = 2
      OnClick = btnCambiarArtClick
    end
    object btnCambiarSku: TcxButton
      Left = 8
      Top = 130
      Width = 220
      Height = 40
      Caption = 'Cambiar foto del &grupo'
      TabOrder = 3
      OnClick = btnCambiarSkuClick
    end
    object btnQuitar: TcxButton
      Left = 472
      Top = 84
      Width = 240
      Height = 40
      Caption = '&Quitar foto'
      TabOrder = 4
      OnClick = btnQuitarClick
    end
    object btnRotarIzq: TcxButton
      Left = 240
      Top = 84
      Width = 220
      Height = 40
      Caption = 'Rotar &izquierda'
      TabOrder = 5
      OnClick = btnRotarIzqClick
    end
    object btnRotarDer: TcxButton
      Left = 240
      Top = 130
      Width = 220
      Height = 40
      Caption = 'Rotar &derecha'
      TabOrder = 6
      OnClick = btnRotarDerClick
    end
    object btnLayout: TcxButton
      Left = 472
      Top = 130
      Width = 240
      Height = 40
      Caption = 'Guardar &layout'
      TabOrder = 8
      OnClick = btnLayoutClick
    end
  end
  object pnlImage: TPanel [2]
    Left = 0
    Top = 218
    Width = 720
    Height = 382
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 2
    ExplicitWidth = 718
    ExplicitHeight = 374
    object imgFoto: TImage
      Left = 1
      Top = 1
      Width = 718
      Height = 380
      Align = alClient
      Center = True
      Proportional = True
      Stretch = True
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 624
  end
  object dlgAbrirFoto: TOpenDialog
    Filter = 
      'Im'#225'genes|*.png;*.jpg;*.jpeg;*.gif;*.webp;*.avif;*.heic;*.bmp|PNG' +
      '|*.png|JPG|*.jpg;*.jpeg|GIF|*.gif|WebP|*.webp|AVIF|*.avif|HEIC|*' +
      '.heic;*.heif|BMP|*.bmp|Todos|*.*'
    Title = 'Seleccionar foto'
    Left = 624
    Top = 16
  end
end
