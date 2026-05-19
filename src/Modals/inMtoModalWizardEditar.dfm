inherited frmModalWizardEditar: TfrmModalWizardEditar
  BorderIcons = [biSystemMenu]
  Caption = 'Editar informe'
  ClientHeight = 600
  ClientWidth = 1100
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 19
  object wzWizard: TJvWizard [0]
    Left = 0
    Top = 0
    Width = 1100
    Height = 600
    ButtonBarHeight = 52
    ButtonStart.Caption = ' '
    ButtonStart.Visible = False
    ButtonStart.Width = 0
    ButtonLast.Caption = ' '
    ButtonLast.Visible = False
    ButtonLast.Width = 0
    ButtonBack.Caption = '< &Anterior'
    ButtonBack.Width = 100
    ButtonNext.Caption = '&Siguiente >'
    ButtonNext.Width = 100
    ButtonFinish.Caption = '&Finalizar'
    ButtonFinish.Width = 100
    ButtonCancel.Caption = '&Cancelar'
    ButtonCancel.Width = 100
    ButtonHelp.Caption = ' '
    ButtonHelp.Visible = False
    ButtonHelp.Width = 0
    ShowRouteMap = False
    OnFinishButtonClick = wzWizardFinishButtonClick
    OnCancelButtonClick = wzWizardCancelButtonClick
    object pgFormato: TJvWizardInteriorPage
      OnNextButtonClick = pgFormatoNextButtonClick
      object pnlPaso1: TPanel
        Left = 0
        Top = 0
        Width = 1100
        Height = 471
        Align = alClient
        BevelOuter = bvNone
        Color = clWindow
        ParentBackground = False
        TabOrder = 0
        object lblOrigen: TcxLabel
          Left = 48
          Top = 40
          Caption = 'Informe'
          Transparent = True
        end
        object edtOrigen: TcxTextEdit
          Left = 240
          Top = 37
          Enabled = False
          Properties.ReadOnly = True
          Style.Color = clBtnFace
          TabOrder = 0
          Width = 420
        end
        object lblFormato: TcxLabel
          Left = 48
          Top = 84
          Caption = 'Formato'
          Transparent = True
        end
        object cbbFormato: TcxComboBox
          Left = 240
          Top = 81
          Properties.DropDownListStyle = lsFixedList
          Properties.OnChange = cbbFormatoPropertiesChange
          TabOrder = 1
          Width = 420
        end
        object lblNombreNuevo: TcxLabel
          Left = 48
          Top = 128
          Caption = 'Nombre nuevo'
          Transparent = True
        end
        object edtNombreNuevo: TcxTextEdit
          Left = 240
          Top = 125
          TabOrder = 2
          Width = 420
        end
        object lblScope: TcxLabel
          Left = 48
          Top = 172
          Caption = 'Permiso (scope)'
          Transparent = True
        end
        object cbbScope: TcxComboBox
          Left = 240
          Top = 169
          Properties.DropDownListStyle = lsFixedList
          TabOrder = 3
          Width = 420
        end
        object lblAyudaPaso1: TcxLabel
          Left = 48
          Top = 220
          Caption = 'En el siguiente paso podr'#225's ver los datasets del informe (cabecera y detalle) y configurar las gu'#237'as de datos que se ligar'#225'n a este formato.'
          Properties.WordWrap = True
          Style.Font.Charset = DEFAULT_CHARSET
          Style.Font.Color = 6710886
          Style.Font.Height = -12
          Style.Font.Name = 'Segoe UI'
          Style.Font.Style = [fsItalic]
          Style.IsFontAssigned = True
          Transparent = True
          Width = 612
        end
      end
    end
    object pgGuias: TJvWizardInteriorPage
      OnShow = pgGuiasShow
      object pnlPaso2: TPanel
        Left = 0
        Top = 0
        Width = 1100
        Height = 471
        Align = alClient
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 0
        object pnlInfoGuias: TPanel
          Left = 0
          Top = 0
          Width = 1100
          Height = 30
          Align = alTop
          BevelOuter = bvNone
          Color = 16444393
          ParentBackground = False
          TabOrder = 0
          object lblTituloGuias: TcxLabel
            Left = 16
            Top = 4
            Caption = 'Gu'#237'as'
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = 3618615
            Style.Font.Height = -14
            Style.Font.Name = 'Segoe UI Semibold'
            Style.Font.Style = [fsBold]
            Style.IsFontAssigned = True
            Transparent = True
          end
        end
        object pnlAyudaGuias: TPanel
          Left = 0
          Top = 30
          Width = 1100
          Height = 170
          Align = alTop
          BevelOuter = bvNone
          Color = 16380385
          ParentBackground = False
          TabOrder = 1
          object lblAyudaGuias: TcxLabel
            Left = 16
            Top = 8
            Caption =
              '   Una gu'#237'a a'#241'ade al informe un dataset auxiliar (estilo Master' +
              'Source / MasterFields / DetailFields de UniDAC).'#13#10'   Cada fila:'#13#10 +
              '      '#8226' C'#243'digo (UserName) = identificador que escribir'#225's en el' +
              ' .frx, p.ej. ClienteFac.'#13#10'      '#8226' Tipo = TABLA o SQL.'#13#10'      '#8226 +
              ' Dataset master = UserName de la cabecera/detalle (ver lista a' +
              ' la derecha).'#13#10'      '#8226' Master / Detail fields = pares separad' +
              'os por '#39';'#39' (CODIGO_CLI_FAC '#8594' CODIGO_CLI).'
            Properties.WordWrap = True
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = 4210752
            Style.Font.Height = -13
            Style.Font.Name = 'Segoe UI'
            Style.IsFontAssigned = True
            Style.TransparentBorder = False
            Transparent = True
            Height = 154
            Width = 600
          end
          object mmoDatasets: TcxMemo
            Left = 624
            Top = 8
            Properties.ReadOnly = True
            Properties.ScrollBars = ssVertical
            Properties.WantReturns = False
            Properties.WordWrap = False
            Style.Font.Charset = DEFAULT_CHARSET
            Style.Font.Color = clWindowText
            Style.Font.Height = -12
            Style.Font.Name = 'Consolas'
            Style.IsFontAssigned = True
            TabOrder = 0
            Height = 154
            Width = 460
          end
        end
        object grdGuias: TcxGrid
          Left = 0
          Top = 200
          Width = 1100
          Height = 271
          Align = alClient
          TabOrder = 2
          LookAndFeel.NativeStyle = False
          object tvGuias: TcxGridDBTableView
            Navigator.Buttons.CustomButtons = <>
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
            OptionsBehavior.GoToNextCellOnEnter = True
            OptionsBehavior.IncSearch = True
            OptionsCustomize.ColumnHiding = True
            OptionsData.Deleting = True
            OptionsData.DeletingConfirmation = True
            OptionsData.Editing = True
            OptionsData.Inserting = True
            OptionsView.GroupByBox = False
            OptionsView.Indicator = True
            Styles.Header = cxsHeader
            object tvGuiasCODIGO: TcxGridDBColumn
              Caption = 'C'#243'digo (UserName)'
              DataBinding.FieldName = 'CODIGO_INFGUI'
              Options.Sorting = False
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
              Width = 140
            end
            object tvGuiasSQL: TcxGridDBColumn
              Caption = 'SQL libre'
              DataBinding.FieldName = 'SQL_INFGUI'
              Width = 170
            end
            object tvGuiasMASTER_FIELDS: TcxGridDBColumn
              Caption = 'Master fields'
              DataBinding.FieldName = 'MASTER_FIELDS_INFGUI'
              Width = 150
            end
            object tvGuiasDETAIL_FIELDS: TcxGridDBColumn
              Caption = 'Detail fields'
              DataBinding.FieldName = 'DETAIL_FIELDS_INFGUI'
              Width = 150
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
      end
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 944
    Top = 504
  end
  object unqryFormatos: TUniQuery
    SQL.Strings = (
      'select VALUE_USUPER'
      '  from fza_usuarios_perfiles'
      ' where KEY_USUPER = :KEY'
      '   and SUBKEY_USUPER <> '#39#39
      '   and VALUE_USUPER not like '#39'Predet:%'#39
      '   and (USUARIO_GRUPO_USUPER = :USU'
      '     or USUARIO_GRUPO_USUPER = :GRP'
      '     or USUARIO_GRUPO_USUPER = :ALL)'
      ' order by VALUE_USUPER')
    Left = 32
    Top = 504
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'KEY'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'USU'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'GRP'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'ALL'
        Value = nil
      end>
  end
  object unqryGuias: TUniQuery
    SQL.Strings = (
      'select *'
      '  from fza_informes_guias'
      ' where INFORME_INFGUI = :INF'
      ' order by FORMATO_INFGUI, ORDEN_INFGUI, CODIGO_INFGUI')
    BeforePost = unqryGuiasBeforePost
    Left = 112
    Top = 504
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'INF'
        Value = nil
      end>
  end
  object dsGuias: TDataSource
    DataSet = unqryGuias
    Left = 192
    Top = 504
  end
  object ActionList1: TActionList
    Left = 272
    Top = 504
    object actCancelar: TAction
      Caption = 'Cancelar'
      ShortCut = 27
      OnExecute = actCancelarExecute
    end
  end
  object cxStyleRepo: TcxStyleRepository
    Left = 352
    Top = 504
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
