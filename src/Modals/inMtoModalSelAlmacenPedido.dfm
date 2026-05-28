inherited frmModalSelAlmacenPedido: TfrmModalSelAlmacenPedido
  Caption = 'Selecciona almac'#233'n para crear el albar'#225'n'
  ClientHeight = 460
  ClientWidth = 600
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnShow = FormShow
  ExplicitWidth = 616
  ExplicitHeight = 499
  TextHeight = 19
  object pnlButton: TPanel [0]
    Left = 0
    Top = 401
    Width = 600
    Height = 59
    Align = alBottom
    TabOrder = 0
    object btnCancelar: TcxButton
      Left = 40
      Top = 9
      Width = 200
      Height = 40
      Cancel = True
      Caption = '&Cancelar (ESC)'
      TabOrder = 0
    end
    object btnAceptar: TcxButton
      Left = 360
      Top = 9
      Width = 200
      Height = 40
      Caption = '&Aceptar (F12)'
      TabOrder = 1
      OnClick = btnAceptarClick
    end
  end
  object pnlBody: TPanel [1]
    Left = 0
    Top = 0
    Width = 600
    Height = 401
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblPedido: TLabel
      Left = 16
      Top = 12
      Width = 567
      Height = 19
      AutoSize = False
      Caption = 'lblPedido'
    end
    object cxgrdAlmacenes: TcxGrid
      Left = 16
      Top = 40
      Width = 568
      Height = 345
      TabOrder = 0
      OnDblClick = tvAlmacenesDblClick
      object tvAlmacenes: TcxGridTableView
        NavigatorButtons.ConfirmDelete = False
        OptionsBehavior.GoToNextCellOnEnter = True
        OptionsCustomize.ColumnFiltering = False
        OptionsData.CancelOnExit = False
        OptionsData.Editing = False
        OptionsData.Deleting = False
        OptionsData.Inserting = False
        OptionsSelection.CellSelect = False
        OptionsView.GroupByBox = False
        OptionsView.Indicator = True
        object colCodigoAlm: TcxGridColumn
          Caption = 'C'#243'digo'
          Width = 120
        end
        object colNombreAlm: TcxGridColumn
          Caption = 'Almac'#233'n'
          Width = 280
        end
        object colPendiente: TcxGridColumn
          Caption = 'Pendiente'
          Width = 140
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.###'
        end
      end
      object cxgrdlvlAlm: TcxGridLevel
        GridView = tvAlmacenes
      end
    end
  end
  object ActionList1: TActionList
    Left = 480
    Top = 16
    object actAceptar: TAction
      Caption = 'Aceptar'
      ShortCut = 123
      OnExecute = actAceptarExecute
    end
    object actCancelar: TAction
      Caption = 'Cancelar'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
end
