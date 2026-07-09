inherited frmModalRepetirModelo: TfrmModalRepetirModelo
  Caption = 'Modelo repetido en la sesi'#243'n'
  ClientHeight = 240
  ClientWidth = 640
  StyleElements = [seFont, seClient, seBorder]
  OnShow = FormShow
  ExplicitWidth = 656
  ExplicitHeight = 279
  TextHeight = 19
  object pnlButton: TPanel [0]
    Left = 0
    Top = 181
    Width = 640
    Height = 59
    Align = alBottom
    TabOrder = 0
    object btnCancelar: TcxButton
      Left = 24
      Top = 9
      Width = 180
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      TabOrder = 2
      OnClick = btnCancelarClick
    end
    object btnOtroPrecio: TcxButton
      Left = 230
      Top = 9
      Width = 180
      Height = 40
      Caption = 'Otro rango de &precios'
      TabOrder = 1
      OnClick = btnOtroPrecioClick
    end
    object btnOtroColor: TcxButton
      Left = 436
      Top = 9
      Width = 180
      Height = 40
      Caption = 'Repetir en otro &color'
      TabOrder = 0
      OnClick = btnOtroColorClick
    end
  end
  object pnlBody: TPanel [1]
    Left = 0
    Top = 0
    Width = 640
    Height = 181
    Align = alClient
    TabOrder = 1
    object lblMensaje: TcxLabel
      Left = 24
      Top = 20
      Caption = 'El modelo ya est'#225' en otra l'#237'nea de esta sesi'#243'n.'
      Style.TextStyle = [fsBold]
      Transparent = True
      TabOrder = 0
    end
    object lblOpcionColor: TcxLabel
      Left = 24
      Top = 64
      Caption =
        '- Otro color: copia toda la l'#237'nea (cantidades por talla incluida' +
        's) y deja el color vac'#237'o.'
      Transparent = True
      TabOrder = 1
    end
    object lblOpcionPrecio: TcxLabel
      Left = 24
      Top = 94
      Caption =
        '- Otro rango de precios: copia la l'#237'nea repitiendo el color y de' +
        'ja vac'#237'os coste y PVP.'
      Transparent = True
      TabOrder = 2
    end
    object lblOpcionCancelar: TcxLabel
      Left = 24
      Top = 124
      Caption =
        '- Cancelar: la l'#237'nea solo hereda los datos del modelo, sin canti' +
        'dades ni color.'
      Transparent = True
      TabOrder = 3
    end
  end
  object ActionList1: TActionList [2]
    Left = 568
    Top = 24
    object actCancelar: TAction
      Caption = 'actCancelar'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
end
