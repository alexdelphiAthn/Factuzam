inherited frmMtoModalEmpCer: TfrmMtoModalEmpCer
  BorderIcons = []
  Caption = 'Seleccionar Certificado'
  ClientHeight = 183
  ClientWidth = 1071
  OnClose = FormClose
  ExplicitWidth = 1083
  ExplicitHeight = 221
  TextHeight = 19
  object pnl1: TPanel [0]
    Left = 0
    Top = 142
    Width = 1071
    Height = 41
    Align = alBottom
    TabOrder = 1
    ExplicitTop = 141
    ExplicitWidth = 461
    object btnCancelar1: TcxButton
      Left = 10
      Top = 6
      Width = 177
      Height = 25
      Caption = '&Cancelar'
      TabOrder = 0
      OnClick = btnCancelarClick
    end
    object btnAceptar: TcxButton
      Left = 248
      Top = 6
      Width = 177
      Height = 25
      Caption = '&Aceptar'
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object lstCertificates: TcxListView [1]
    Left = 0
    Top = 0
    Width = 1071
    Height = 142
    Align = alClient
    Columns = <
      item
        Caption = 'Tipo'
        Width = 100
      end
      item
        Caption = 'Titular/Empresa'
        Width = 250
      end
      item
        Caption = 'Nombre'
        Width = 250
      end
      item
        Caption = 'Emisor'
        Width = 200
      end
      item
        Caption = 'V'#225'lido hasta'
        Width = 120
      end
      item
        Caption = 'N'#250'mero de serie'
        Width = 150
      end>
    ReadOnly = True
    SortType = stText
    TabOrder = 0
    ViewStyle = vsReport
    ExplicitWidth = 461
    ExplicitHeight = 141
  end
  inherited Localizer1: TcxLocalizer
    Left = 232
    Top = 440
  end
end
