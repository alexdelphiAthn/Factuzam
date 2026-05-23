inherited frmPrintEtiqAlb: TfrmPrintEtiqAlb
  Caption = 'Impresi'#243'n de Etiquetas de Albar'#225'n'
  ClientHeight = 426
  ClientWidth = 536
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  OnShow = FormShow
  ExplicitWidth = 552
  ExplicitHeight = 465
  TextHeight = 19
  inherited pnl1: TPanel
    Left = 392
    Height = 426
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 390
    ExplicitHeight = 418
    inherited btnSalir: TcxButton
      Top = 400
      ExplicitTop = 392
    end
  end
  object pnlOpciones: TPanel [1]
    Left = 0
    Top = 0
    Width = 392
    Height = 426
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitWidth = 390
    ExplicitHeight = 418
    object cxlblAlbaran: TcxLabel
      Left = 12
      Top = 12
      Caption = 'Albar'#225'n:'
      TabOrder = 5
      Transparent = True
    end
    object edtAlbaran: TcxTextEdit
      Left = 156
      Top = 8
      Properties.ReadOnly = True
      TabOrder = 0
      Width = 220
    end
    object cxlblTarifa: TcxLabel
      Left = 12
      Top = 44
      Caption = 'Tarifa:'
      TabOrder = 6
      Transparent = True
    end
    object cbbTarifa: TcxComboBox
      Left = 156
      Top = 40
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 1
      Width = 220
    end
    object cxlblFecha: TcxLabel
      Left = 12
      Top = 76
      Caption = 'Fecha de aplicaci'#243'n:'
      TabOrder = 7
      Transparent = True
    end
    object dtFechaAplicacion: TcxDateEdit
      Left = 193
      Top = 72
      TabOrder = 2
      Width = 183
    end
    object cxlblAlmacenes: TcxLabel
      Left = 12
      Top = 108
      Caption = 'Almacenes del albar'#225'n (marque uno o varios):'
      TabOrder = 8
      Transparent = True
    end
    object lvAlmacenes: TcxListView
      Left = 12
      Top = 132
      Width = 364
      Height = 280
      Checkboxes = True
      Columns = <
        item
          Caption = 'C'#243'digo'
          Width = 100
        end
        item
          Caption = 'Almac'#233'n'
          Width = 240
        end>
      RowSelect = True
      TabOrder = 3
      ViewStyle = vsReport
    end
  end
end
