inherited frmFotoArticulo: TfrmFotoArticulo
  BorderIcons = [biSystemMenu, biMinimize, biMaximize]
  BorderStyle = bsSizeable
  Caption = 'Foto del art'#237'culo / SKU'
  ClientHeight = 520
  ClientWidth = 520
  FormStyle = fsStayOnTop
  Position = poDesigned
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  ExplicitWidth = 536
  ExplicitHeight = 559
  TextHeight = 19
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 520
    Height = 36
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnToggle: TcxButton
      Left = 4
      Top = 4
      Width = 32
      Height = 28
      Caption = #9660
      Hint = 'Mostrar u ocultar controles (F11)'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = btnToggleClick
    end
    object btnDescargarNube: TcxButton
      Left = 40
      Top = 4
      Width = 32
      Height = 28
      Caption = #8595
      Hint = 'Bajar fotos del servidor'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = btnDescargarNubeClick
    end
    object lblOrigen: TcxLabel
      Left = 80
      Top = 7
      Anchors = [akLeft, akTop, akRight]
      Caption = 'Sin foto'
      Properties.WordWrap = True
      TabOrder = 2
      Visible = False
      Width = 232
      Transparent = True
    end
    object btnMarcarPredeterminada: TcxButton
      Left = 320
      Top = 4
      Width = 32
      Height = 28
      Anchors = [akTop, akRight]
      Caption = #9734
      Hint = 'Establecer esta foto como predeterminada'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = btnMarcarPredeterminadaClick
    end
    object btnFotoAnterior: TcxButton
      Left = 356
      Top = 4
      Width = 32
      Height = 28
      Anchors = [akTop, akRight]
      Caption = #8592
      Hint = 'Foto anterior'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = btnFotoAnteriorClick
    end
    object lblNumeroFoto: TcxLabel
      Left = 392
      Top = 7
      Anchors = [akTop, akRight]
      Caption = '0/0'
      Properties.Alignment.Horz = taCenter
      TabOrder = 5
      Transparent = True
      Width = 52
    end
    object btnFotoSiguiente: TcxButton
      Left = 448
      Top = 4
      Width = 32
      Height = 28
      Anchors = [akTop, akRight]
      Caption = #8594
      Hint = 'Foto siguiente'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      OnClick = btnFotoSiguienteClick
    end
    object btnAnadirFoto: TcxButton
      Left = 484
      Top = 4
      Width = 32
      Height = 28
      Anchors = [akTop, akRight]
      Caption = '+'
      Hint = 'A'#241'adir foto'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
      OnClick = btnAnadirFotoClick
    end
  end
  object pnlControles: TPanel [1]
    Left = 0
    Top = 36
    Width = 520
    Height = 94
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
    object rgResolucion: TcxRadioGroup
      Left = 4
      Top = 2
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
      Height = 52
      Width = 200
    end
    object lblNivel: TcxLabel
      Left = 212
      Top = 2
      Caption = 'Nivel:'
      TabOrder = 8
      Transparent = True
    end
    object cbbNivelSku: TcxComboBox
      Left = 212
      Top = 24
      Anchors = [akLeft, akTop, akRight]
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 1
      Width = 304
    end
    object btnCambiarArt: TcxButton
      Left = 4
      Top = 58
      Width = 44
      Height = 32
      Caption = '&A'#8230
      Hint = 'Sustituir la foto principal del art'#237'culo'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = btnCambiarArtClick
    end
    object btnCambiarSku: TcxButton
      Left = 52
      Top = 58
      Width = 44
      Height = 32
      Caption = '&G'#8230
      Hint = 'Sustituir la foto principal del nivel seleccionado'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = btnCambiarSkuClick
    end
    object btnQuitar: TcxButton
      Left = 212
      Top = 58
      Width = 44
      Height = 32
      Caption = '&Q'#215
      Hint = 'Quitar la foto visible'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      OnClick = btnQuitarClick
    end
    object btnRotarIzq: TcxButton
      Left = 108
      Top = 58
      Width = 44
      Height = 32
      Caption = '&I'#8630
      Hint = 'Rotar la foto visible a la izquierda'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = btnRotarIzqClick
    end
    object btnRotarDer: TcxButton
      Left = 156
      Top = 58
      Width = 44
      Height = 32
      Caption = '&D'#8631
      Hint = 'Rotar la foto visible a la derecha'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      OnClick = btnRotarDerClick
    end
    object btnLayout: TcxButton
      Left = 268
      Top = 58
      Width = 44
      Height = 32
      Caption = '&L'#9638
      Hint = 'Guardar posici'#243'n, tama'#241'o y resoluci'#243'n'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
      OnClick = btnLayoutClick
    end
  end
  object pnlImage: TPanel [2]
    Left = 0
    Top = 130
    Width = 520
    Height = 390
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 2
    object imgFoto: TImage
      Left = 1
      Top = 1
      Width = 518
      Height = 388
      Align = alClient
      Center = True
      Proportional = True
      Stretch = True
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 424
  end
  object dlgAbrirFoto: TOpenDialog
    Filter = 
      'Im'#225'genes|*.png;*.jpg;*.jpeg;*.gif;*.webp;*.avif;*.heic;*.bmp|PNG' +
      '|*.png|JPG|*.jpg;*.jpeg|GIF|*.gif|WebP|*.webp|AVIF|*.avif|HEIC|*' +
      '.heic;*.heif|BMP|*.bmp|Todos|*.*'
    Title = 'Seleccionar foto'
    Left = 424
    Top = 16
  end
end
