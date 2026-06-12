inherited frmModalVerifactuDecl: TfrmModalVerifactuDecl
  Caption = 'Declaraci'#243'n Responsable - Verifactu'
  ClientHeight = 560
  ClientWidth = 720
  Position = poScreenCenter
  TextHeight = 19
  object mDeclaracion: TcxMemo [0]
    Left = 0
    Top = 0
    Align = alClient
    Properties.ReadOnly = True
    Properties.ScrollBars = ssVertical
    TabOrder = 0
    Height = 501
    Width = 720
  end
  object pnlButton: TPanel [1]
    Left = 0
    Top = 501
    Width = 720
    Height = 59
    Align = alBottom
    TabOrder = 1
    object btnAceptar: TcxButton
      Left = 272
      Top = 9
      Width = 177
      Height = 40
      Cancel = True
      Caption = '&Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
  end
end
