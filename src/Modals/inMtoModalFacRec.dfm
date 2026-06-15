inherited frmGenFacRec: TfrmGenFacRec
  Left = 516
  Top = 286
  HorzScrollBar.Visible = False
  BorderStyle = bsSingle
  Caption = 'Duplicar/Abonar Borrador'
  ClientHeight = 351
  ClientWidth = 419
  FormStyle = fsStayOnTop
  Position = poMainFormCenter
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 435
  ExplicitHeight = 390
  TextHeight = 19
  object cxlbl1: TcxLabel [0]
    Left = 9
    Top = 4
    Caption = 'Borrador Origen N'#250'mero'
    TabOrder = 1
    Transparent = True
  end
  object edtNumFacOrigen: TcxTextEdit [1]
    Left = 135
    Top = 28
    Enabled = False
    TabOrder = 3
    Width = 129
  end
  object pnl1: TPanel [2]
    Left = 304
    Top = 0
    Width = 115
    Height = 351
    Align = alRight
    TabOrder = 0
    object btn3: TcxButton
      Left = 0
      Top = 274
      Width = 115
      Height = 25
      Caption = 'Salir'
      TabOrder = 1
      OnClick = btn3Click
    end
    object btnGenerar: TcxButton
      Left = 0
      Top = 251
      Width = 115
      Height = 25
      Caption = 'Generar'
      TabOrder = 0
      OnClick = btnGenerarClick
    end
  end
  object chkAbonar: TcxCheckBox [3]
    Left = 16
    Top = 58
    Caption = 'Generar Borrador de Abono'
    TabOrder = 4
    OnClick = chkAbonarClick
  end
  object cxgrpbx1: TcxGroupBox [4]
    Left = -2
    Top = 232
    Caption = 'Borrador Generado'
    TabOrder = 10
    Height = 67
    Width = 287
    object edtNumFacAbono: TcxTextEdit
      Left = 72
      Top = 24
      Enabled = False
      TabOrder = 1
      Width = 129
    end
    object edtSerieFacAbono: TcxTextEdit
      Left = 24
      Top = 24
      Enabled = False
      TabOrder = 0
      Width = 41
    end
  end
  object edtSerieOrigen: TcxTextEdit [5]
    Left = 8
    Top = 28
    Enabled = False
    TabOrder = 2
    Width = 114
  end
  object chkDuplicar: TcxCheckBox [6]
    Left = 16
    Top = 82
    Caption = 'Duplicar Borrador'
    TabOrder = 5
    OnClick = chkDuplicarClick
  end
  object cxlbl8: TcxLabel [7]
    Left = 9
    Top = 111
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Serie Borrador Destino'
    TabOrder = 8
    Transparent = True
  end
  object cmbSerieFactura: TcxLookupComboBox [8]
    Left = 16
    Top = 135
    Properties.KeyFieldNames = 'SERIE_CON'
    Properties.ListColumns = <
      item
        FieldName = 'SERIE_CON'
      end>
    Properties.ListOptions.ShowHeader = False
    Properties.ReadOnly = False
    TabOrder = 6
    Width = 145
  end
  object cxlbl2: TcxLabel [9]
    Left = 9
    Top = 166
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Fecha Borrador Destino'
    TabOrder = 9
    Transparent = True
  end
  object dtFecha: TcxDateEdit [10]
    Left = 16
    Top = 193
    TabOrder = 7
    Width = 121
  end
end
