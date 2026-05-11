object frmMtoModalAltaRapida: TfrmMtoModalAltaRapida
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Alta r'#225'pida'
  ClientHeight = 600
  ClientWidth = 450
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 17
  object ScrollBox: TScrollBox
    Left = 0
    Top = 0
    Width = 450
    Height = 550
    Align = alClient
    BorderStyle = bsNone
    TabOrder = 0
    object lblCod: TcxLabel
      Left = 25
      Top = 15
      Caption = 'C'#243'digo:'
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -13
      Style.Font.Name = 'Segoe UI'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object edtCod: TcxTextEdit
      Left = 25
      Top = 35
      TabOrder = 0
      Width = 150
    end
    object lblDesc: TcxLabel
      Left = 25
      Top = 70
      Caption = 'Descripci'#243'n:'
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -13
      Style.Font.Name = 'Segoe UI'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object edtDesc: TcxTextEdit
      Left = 25
      Top = 90
      TabOrder = 1
      Width = 380
    end
    object BevelSep: TBevel
      Left = 25
      Top = 125
      Width = 380
      Height = 2
      Shape = bsTopLine
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 550
    Width = 450
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnOk: TcxButton
      Left = 230
      Top = 12
      Width = 90
      Height = 30
      Caption = '&Guardar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      LookAndFeel.NativeStyle = False
    end
    object btnCancel: TcxButton
      Left = 330
      Top = 12
      Width = 90
      Height = 30
      Cancel = True
      Caption = '&Cancelar'
      ModalResult = 2
      TabOrder = 1
      LookAndFeel.NativeStyle = False
    end
  end
end
