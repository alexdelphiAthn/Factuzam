inherited frmModalInformesGuias: TfrmModalInformesGuias
  BorderIcons = [biSystemMenu]
  Caption = 'Gu'#237'as del informe'
  ClientHeight = 540
  ClientWidth = 1180
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 19
  object pnlCabecera: TPanel [0]
    Left = 0
    Top = 0
    Width = 1180
    Height = 62
    Align = alTop
    BevelOuter = bvNone
    Color = 16444393
    ParentBackground = False
    TabOrder = 0
    object lblTitulo: TcxLabel
      Left = 16
      Top = 10
      Caption = 'Gu'#237'as del informe'
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = 3618615
      Style.Font.Height = -19
      Style.Font.Name = 'Segoe UI Semibold'
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Style.TransparentBorder = False
      Transparent = True
    end
    object lblInfo: TcxLabel
      Left = 18
      Top = 36
      Caption = ' '
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = 6710886
      Style.Font.Height = -13
      Style.Font.Name = 'Segoe UI'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      Transparent = True
    end
  end
  object pnlAyuda: TPanel [1]
    Left = 0
    Top = 62
    Width = 1180
    Height = 180
    Align = alTop
    BevelOuter = bvNone
    Color = 16380385
    ParentBackground = False
    TabOrder = 1
    object lblAyuda: TcxLabel
      Left = 16
      Top = 8
      Caption =
        '   Una gu'#237'a a'#241'ade al informe un dataset auxiliar (estilo Master' +
        'Source / MasterFields / DetailFields de UniDAC).'#13#10'   Cada fila:'#13#10 +
        '      '#8226' C'#243'digo (UserName) = identificador que escribir'#225's en el' +
        ' .frx, p.ej. ClienteFac.'#13#10'      '#8226' Tipo = TABLA (usa la tabla t' +
        'al cual) o SQL (consulta libre).'#13#10'      '#8226' Dataset master = Use' +
        'rName de cabecera o detalle del informe (ver lista a la derecha' +
        ').'#13#10'      '#8226' Master / Detail fields = pares de campos separados' +
        ' por '#39';'#39' (CODIGO_CLI_FAC '#8594' CODIGO_CLI).'#13#10'      '#8226' Formato = vac'#237 +
        'o '#8594' gu'#237'a global del informe;   relleno '#8594' solo para ese .frx co' +
        'ncreto.'
      Properties.WordWrap = True
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = 4210752
      Style.Font.Height = -13
      Style.Font.Name = 'Segoe UI'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      Style.TransparentBorder = False
      Transparent = True
      Height = 164
      Width = 660
      AnchorY = 8
    end
    object mmoDatasets: TcxMemo
      Left = 684
      Top = 8
      Align = alCustom
      Properties.ReadOnly = True
      Properties.ScrollBars = ssVertical
      Properties.WantReturns = False
      Properties.WordWrap = False
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -12
      Style.Font.Name = 'Consolas'
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 0
      Height = 164
      Width = 480
    end
  end
  object pnlBotones: TPanel [2]
    Left = 0
    Top = 491
    Width = 1180
    Height = 49
    Align = alBottom
    BevelOuter = bvNone
    Color = 16513252
    ParentBackground = False
    TabOrder = 2
    object btnCerrar: TcxButton
      Left = 1011
      Top = 11
      Width = 155
      Height = 29
      Caption = '&Cerrar'
      Colors.Default = 14598878
      LookAndFeel.NativeStyle = False
      LookAndFeel.SkinName = 'Office2019Colorful'
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
  object grdGuias: TcxGrid [3]
    Left = 0
    Top = 242
    Width = 1180
    Height = 249
    Align = alClient
    TabOrder = 3
    LookAndFeel.NativeStyle = False
    object tvGuias: TcxGridDBTableView
      Navigator.Buttons.CustomButtons = <>
      Navigator.Buttons.ConfirmDelete = True
      Navigator.Buttons.First.Hint = 'Primero'
      Navigator.Buttons.PriorPage.Hint = 'P'#225'gina anterior'
      Navigator.Buttons.Prior.Hint = 'Anterior'
      Navigator.Buttons.Next.Hint = 'Siguiente'
      Navigator.Buttons.NextPage.Hint = 'P'#225'gina siguiente'
      Navigator.Buttons.Last.Hint = #218'ltimo'
      Navigator.Buttons.Insert.Hint = 'Nueva gu'#237'a'
      Navigator.Buttons.Insert.Visible = True
      Navigator.Buttons.Delete.Hint = 'Borrar gu'#237'a'
      Navigator.Buttons.Delete.Visible = True
      Navigator.Buttons.Edit.Hint = 'Editar'
      Navigator.Buttons.Edit.Visible = True
      Navigator.Buttons.Post.Hint = 'Guardar'
      Navigator.Buttons.Post.Visible = True
      Navigator.Buttons.Cancel.Hint = 'Cancelar'
      Navigator.Buttons.Cancel.Visible = True
      Navigator.Buttons.Refresh.Hint = 'Refrescar'
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
      Styles.Header = cxsHeader
      object tvGuiasCODIGO: TcxGridDBColumn
        Caption = 'C'#243'digo (UserName .frx)'
        DataBinding.FieldName = 'CODIGO_INFGUI'
        Options.Sorting = False
        Width = 170
      end
      object tvGuiasFORMATO: TcxGridDBColumn
        Caption = 'Formato (vac. = global)'
        DataBinding.FieldName = 'FORMATO_INFGUI'
        Width = 160
      end
      object tvGuiasMASTER_DS: TcxGridDBColumn
        Caption = 'Dataset master'
        DataBinding.FieldName = 'DATASET_MASTER_INFGUI'
        Width = 140
      end
      object tvGuiasTIPO: TcxGridDBColumn
        Caption = 'Tipo'
        DataBinding.FieldName = 'TIPO_INFGUI'
        PropertiesClassName = 'TcxComboBoxProperties'
        Properties.DropDownListStyle = lsFixedList
        Properties.Items.Strings = (
          'TABLA'
          'SQL')
        Width = 80
      end
      object tvGuiasTABLA: TcxGridDBColumn
        Caption = 'Tabla'
        DataBinding.FieldName = 'TABLA_INFGUI'
        Width = 150
      end
      object tvGuiasSQL: TcxGridDBColumn
        Caption = 'SQL libre'
        DataBinding.FieldName = 'SQL_INFGUI'
        Width = 180
      end
      object tvGuiasMASTER_FIELDS: TcxGridDBColumn
        Caption = 'Master fields'
        DataBinding.FieldName = 'MASTER_FIELDS_INFGUI'
        Width = 160
      end
      object tvGuiasDETAIL_FIELDS: TcxGridDBColumn
        Caption = 'Detail fields'
        DataBinding.FieldName = 'DETAIL_FIELDS_INFGUI'
        Width = 160
      end
      object tvGuiasORDEN: TcxGridDBColumn
        Caption = 'Orden'
        DataBinding.FieldName = 'ORDEN_INFGUI'
        Width = 60
      end
      object tvGuiasACTIVO: TcxGridDBColumn
        Caption = 'Activo'
        DataBinding.FieldName = 'ESACTIVO_INFGUI'
        PropertiesClassName = 'TcxComboBoxProperties'
        Properties.DropDownListStyle = lsFixedList
        Properties.Items.Strings = (
          'S'
          'N')
        Width = 60
      end
    end
    object lvGuias: TcxGridLevel
      GridView = tvGuias
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 832
    Top = 312
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
  object cxStyleRepo: TcxStyleRepository
    Left = 832
    Top = 240
    PixelsPerInch = 96
    object cxsHeader: TcxStyle
      AssignedValues = [svColor, svFont]
      Color = 14998263
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = [fsBold]
    end
  end
end
