inherited frmModalDistribuidor: TfrmModalDistribuidor
  Caption = 'Distribuidor por almac'#233'n / talla'
  ClientHeight = 480
  ClientWidth = 900
  StyleElements = [seFont, seClient, seBorder]
  Position = poScreenCenter
  OnDestroy = FormDestroy
  ExplicitWidth = 916
  ExplicitHeight = 519
  TextHeight = 19
  object pnlCab: TPanel [0]
    Left = 0
    Top = 0
    Width = 900
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 12
      Caption = 'Distribuci'#243'n almac'#233'n / talla'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
    object lblLinea: TcxLabel
      Left = 320
      Top = 14
      Caption = 'L'#237'nea:'
      Transparent = True
    end
    object edtLinea: TcxTextEdit
      Left = 380
      Top = 12
      Enabled = False
      TabOrder = 0
      Width = 80
    end
  end
  object pnlCuadrante: TPanel [1]
    Left = 0
    Top = 50
    Width = 900
    Height = 370
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxgrdCuadr: TcxGrid
      Left = 0
      Top = 0
      Width = 900
      Height = 370
      Align = alClient
      TabOrder = 0
      object tvCuadr: TcxGridDBTableView
        DataController.DataSource = dsCuadr
        OptionsBehavior.IncSearch = True
        OptionsCustomize.ColumnHiding = True
        OptionsData.Deleting = False
        OptionsData.DeletingConfirmation = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
      end
      object cxlvlCuadr: TcxGridLevel
        GridView = tvCuadr
      end
    end
  end
  object pnlBot: TPanel [2]
    Left = 0
    Top = 420
    Width = 900
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnAceptar: TcxButton
      Left = 650
      Top = 12
      Width = 110
      Height = 38
      Caption = '&Aceptar'
      Default = True
      TabOrder = 0
      OnClick = btnAceptarClick
    end
    object btnCancelar: TcxButton
      Left = 770
      Top = 12
      Width = 110
      Height = 38
      Cancel = True
      Caption = '&Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
  object cdsCuadr: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 16
    Top = 60
  end
  object dsCuadr: TDataSource
    DataSet = cdsCuadr
    Left = 56
    Top = 60
  end
end
