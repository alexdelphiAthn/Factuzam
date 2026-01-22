inherited frmMtoSearch: TfrmMtoSearch
  BorderStyle = bsSizeable
  Caption = 'frmMtoSearch'
  ClientHeight = 519
  ClientWidth = 941
  Visible = False
  ExplicitWidth = 953
  ExplicitHeight = 557
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 801
    Height = 519
    ExplicitWidth = 795
    ExplicitHeight = 510
    inherited pcPantalla: TcxPageControl
      Width = 801
      Height = 409
      Properties.ActivePage = tsLista
      Properties.HideTabs = True
      ExplicitWidth = 795
      ExplicitHeight = 400
      ClientRectBottom = 405
      ClientRectRight = 797
      ClientRectTop = 4
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 787
        ExplicitHeight = 366
        inherited cxGrdPrincipal: TcxGrid
          Width = 793
          Height = 401
          ExplicitWidth = 787
          ExplicitHeight = 366
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OnCellDblClick = cxGrdDBTabPrinCellDblClick
            OptionsData.Appending = False
            OptionsData.CancelOnExit = False
            OptionsData.Deleting = False
            OptionsData.DeletingConfirmation = False
            OptionsData.Inserting = False
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 793
        ExplicitHeight = 375
      end
      inherited tsPerfil: TcxTabSheet
        TabVisible = False
        ExplicitWidth = 793
        ExplicitHeight = 375
        inherited pnlPerfilTop: TPanel
          Width = 793
          ExplicitWidth = 793
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 793
          Height = 344
          ExplicitWidth = 793
          ExplicitHeight = 318
          inherited cxgrdPerfil: TcxGrid
            Width = 793
            Height = 344
            ExplicitWidth = 793
            ExplicitHeight = 318
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 801
      ExplicitWidth = 795
      inherited pnlTopGrid: TPanel
        Width = 801
        ExplicitWidth = 795
        inherited sbExportExcel: TSpeedButton
          Visible = False
        end
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 240
          Visible = False
          ExplicitWidth = 240
        end
      end
    end
    object pnl1: TPanel
      Left = 0
      Top = 449
      Width = 801
      Height = 70
      Align = alBottom
      TabOrder = 2
      ExplicitTop = 440
      ExplicitWidth = 795
      object btnAceptar: TcxButton
        Left = 320
        Top = 24
        Width = 177
        Height = 25
        Caption = '&Aceptar'
        TabOrder = 0
        OnClick = btnAceptarClick
      end
      object btnCancelar1: TcxButton
        Left = 18
        Top = 24
        Width = 177
        Height = 25
        Caption = '&Cancelar'
        TabOrder = 1
        OnClick = btnCancelarClick
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 801
    Height = 519
    ExplicitLeft = 795
    ExplicitHeight = 510
    inherited pButtonGen: TPanel
      Top = 321
      ExplicitTop = 312
      inherited btnGrabar: TcxButton
        Visible = False
      end
      inherited btnCancelar: TcxButton
        Visible = False
      end
      inherited btnSalir: TcxButton
        Visible = False
      end
    end
    inherited pButtonBDStat: TPanel
      inherited pnlDataSetName: TPanel
        inherited lblTablaOrigen: TcxLabel
          ParentFont = False
          Style.Font.Height = -15
          Style.IsFontAssigned = True
          ExplicitWidth = 92
          ExplicitHeight = 21
        end
      end
    end
    object btnAltaRapida: TcxButton
      Left = 7
      Top = 96
      Width = 130
      Height = 33
      Caption = 'Alta &R'#225'pida'
      TabOrder = 2
      OnClick = btnAltaRapidaClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Top = 264
  end
  inherited dsTablaG: TDataSource
    Left = 104
    Top = 264
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 520
    Top = 256
  end
  object unqryPerfiles: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT * FROM fza_usuarios_perfiles ')
    Left = 432
    Top = 256
  end
  object dsPerfiles: TDataSource
    DataSet = unqryPerfiles
    Left = 312
    Top = 264
  end
end
