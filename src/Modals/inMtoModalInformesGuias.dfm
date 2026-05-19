inherited frmModalInformesGuias: TfrmModalInformesGuias
  BorderIcons = [biSystemMenu]
  Caption = 'Gu'#237'as del informe'
  ClientHeight = 380
  ClientWidth = 980
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 19
  object lblInfo: TcxLabel [0]
    Left = 8
    Top = 8
    Caption = 'Gu'#237'as'
    Transparent = True
  end
  object pnlBotones: TPanel [1]
    Left = 0
    Top = 339
    Width = 980
    Height = 41
    Align = alBottom
    TabOrder = 0
    object btnCerrar: TcxButton
      Left = 803
      Top = 8
      Width = 169
      Height = 25
      Caption = '&Cerrar'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
  object grdGuias: TcxGrid [2]
    Left = 0
    Top = 40
    Width = 980
    Height = 299
    Align = alClient
    TabOrder = 1
    object tvGuias: TcxGridDBTableView
      Navigator.Buttons.ConfirmDelete = True
      Navigator.Buttons.Insert.Visible = True
      Navigator.Buttons.Delete.Visible = True
      Navigator.Buttons.Edit.Visible = True
      Navigator.Buttons.Post.Visible = True
      Navigator.Buttons.Cancel.Visible = True
      Navigator.Buttons.Refresh.Visible = True
      Navigator.Visible = True
      DataController.DataSource = dsGuias
      DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
      OptionsBehavior.AlwaysShowEditor = False
      OptionsBehavior.GoToNextCellOnEnter = True
      OptionsBehavior.IncSearch = True
      OptionsCustomize.ColumnHiding = True
      OptionsData.CancelOnExit = False
      OptionsData.Deleting = True
      OptionsData.DeletingConfirmation = True
      OptionsData.Editing = True
      OptionsData.Inserting = True
      OptionsView.GroupByBox = False
      OptionsView.Indicator = True
      object tvGuiasCODIGO: TcxGridDBColumn
        Caption = 'C'#243'digo (UserName)'
        DataBinding.FieldName = 'CODIGO_INFGUI'
        Width = 130
      end
      object tvGuiasFORMATO: TcxGridDBColumn
        Caption = 'Formato (vac'#237'o = global)'
        DataBinding.FieldName = 'FORMATO_INFGUI'
        Width = 140
      end
      object tvGuiasMASTER_DS: TcxGridDBColumn
        Caption = 'Dataset master'
        DataBinding.FieldName = 'DATASET_MASTER_INFGUI'
        Width = 130
      end
      object tvGuiasTIPO: TcxGridDBColumn
        Caption = 'Tipo'
        DataBinding.FieldName = 'TIPO_INFGUI'
        Width = 65
      end
      object tvGuiasTABLA: TcxGridDBColumn
        Caption = 'Tabla'
        DataBinding.FieldName = 'TABLA_INFGUI'
        Width = 130
      end
      object tvGuiasSQL: TcxGridDBColumn
        Caption = 'SQL libre'
        DataBinding.FieldName = 'SQL_INFGUI'
        Width = 160
      end
      object tvGuiasMASTER_FIELDS: TcxGridDBColumn
        Caption = 'Master fields'
        DataBinding.FieldName = 'MASTER_FIELDS_INFGUI'
        Width = 140
      end
      object tvGuiasDETAIL_FIELDS: TcxGridDBColumn
        Caption = 'Detail fields'
        DataBinding.FieldName = 'DETAIL_FIELDS_INFGUI'
        Width = 140
      end
      object tvGuiasORDEN: TcxGridDBColumn
        Caption = 'Orden'
        DataBinding.FieldName = 'ORDEN_INFGUI'
        Width = 60
      end
      object tvGuiasACTIVO: TcxGridDBColumn
        Caption = 'Activo'
        DataBinding.FieldName = 'ESACTIVO_INFGUI'
        Width = 60
      end
    end
    object lvGuias: TcxGridLevel
      GridView = tvGuias
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 600
    Top = 240
  end
  object unqryGuias: TUniQuery
    SQL.Strings = (
      'select *'
      '  from fza_informes_guias'
      ' where INFORME_INFGUI = :INF'
      ' order by FORMATO_INFGUI, ORDEN_INFGUI, CODIGO_INFGUI')
    BeforePost = unqryGuiasBeforePost
    Left = 32
    Top = 96
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'INF'
        Value = nil
      end>
  end
  object dsGuias: TDataSource
    DataSet = unqryGuias
    Left = 32
    Top = 152
  end
  object ActionList1: TActionList
    Left = 32
    Top = 208
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
  end
end
