inherited frmMtoModalAddPreciosTar: TfrmMtoModalAddPreciosTar
  Caption = 'A'#241'adir precios a Tarifas'
  ClientHeight = 600
  ClientWidth = 550
  OnCreate = FormCreate
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 566
  ExplicitHeight = 639
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 541
    Width = 550
    ExplicitTop = 541
    ExplicitWidth = 550
    inherited btnCancelar: TcxButton
      Left = 40
      ExplicitLeft = 40
    end
    inherited btnAceptar: TcxButton
      Left = 320
      ExplicitLeft = 320
    end
  end
  inherited pnlBody: TPanel
    Width = 550
    Height = 541
    ExplicitWidth = 550
    ExplicitHeight = 541
    object pnlFechas: TPanel
      Left = 0
      Top = 0
      Width = 550
      Height = 65
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblDesde: TLabel
        Left = 12
        Top = 22
        Width = 100
        Height = 22
        Caption = 'Vigente desde:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblHasta: TLabel
        Left = 280
        Top = 22
        Width = 116
        Height = 19
        Caption = 'Hasta (opcional):'
      end
      object dtpDesde: TcxDateEdit
        Left = 150
        Top = 19
        TabOrder = 0
        Width = 120
      end
      object dtpHasta: TcxDateEdit
        Left = 410
        Top = 19
        TabOrder = 1
        Width = 120
      end
    end
    object lblSkus: TLabel
      AlignWithMargins = True
      Left = 10
      Top = 71
      Width = 530
      Height = 22
      Margins.Left = 10
      Margins.Top = 6
      Margins.Right = 10
      Margins.Bottom = 2
      Align = alTop
      Caption = ' 1. Seleccione los SKUs:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      ExplicitWidth = 206
    end
    object chkSkus: TcxCheckListBox
      AlignWithMargins = True
      Left = 10
      Top = 97
      Width = 530
      Height = 180
      Margins.Left = 10
      Margins.Top = 2
      Margins.Right = 10
      Margins.Bottom = 4
      Align = alTop
      ItemHeight = 22
      Items = <>
      TabOrder = 1
    end
    object lblTarifas: TLabel
      AlignWithMargins = True
      Left = 10
      Top = 287
      Width = 530
      Height = 22
      Margins.Left = 10
      Margins.Top = 6
      Margins.Right = 10
      Margins.Bottom = 2
      Align = alTop
      Caption = ' 2. Seleccione las Tarifas:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      ExplicitWidth = 217
    end
    object chkTarifas: TcxCheckListBox
      AlignWithMargins = True
      Left = 10
      Top = 315
      Width = 530
      Height = 222
      Margins.Left = 10
      Margins.Top = 2
      Margins.Right = 10
      Margins.Bottom = 4
      Align = alClient
      ItemHeight = 22
      Items = <>
      TabOrder = 2
    end
  end
end
