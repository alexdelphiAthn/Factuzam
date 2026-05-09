inherited frmMtoPropiedades: TfrmMtoPropiedades
  Caption = 'Propiedades'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_PROP_ARTPROP'
              Width = 140
            end
            object cxgrdbclmnGrdDBTabPrinNOMBRE: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_PROP_PROP'
              Width = 240
            end
            object cxgrdbclmnGrdDBTabPrinTIPO: TcxGridDBColumn
              Caption = 'Tipo de valor'
              DataBinding.FieldName = 'TIPO_VALOR_PROP'
              Width = 130
            end
            object cxgrdbclmnGrdDBTabPrinACTIVO: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_PROP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
            object cxgrdbclmnGrdDBTabPrinNUMARTUSOS: TcxGridDBColumn
              Caption = 'Art'#237'culos asignados'
              DataBinding.FieldName = 'NUM_ART_USOS'
              HeaderAlignmentHorz = taRightJustify
              Width = 140
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Visible = False
              VisibleForCustomization = False
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Visible = False
              VisibleForCustomization = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_ALTA'
              Visible = False
              VisibleForCustomization = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIO_MODIF'
              Visible = False
              VisibleForCustomization = False
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = True
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        object pnl1: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 113
          Align = alTop
          TabOrder = 0
          object Panel1: TPanel
            Left = 1
            Top = 1
            Width = 941
            Height = 111
            Align = alClient
            TabOrder = 0
            object lblCodigo: TcxLabel
              Left = 21
              Top = 21
              Caption = 'C'#243'digo'
              TabOrder = 0
              Transparent = True
            end
            object txtCODIGO: TcxDBTextEdit
              Left = 110
              Top = 17
              DataBinding.DataField = 'CODIGO_PROP_ARTPROP'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabOrder = 1
              Width = 180
            end
            object lblNombre: TcxLabel
              Left = 21
              Top = 49
              Caption = 'Nombre'
              TabOrder = 2
              Transparent = True
            end
            object txtNOMBRE: TcxDBTextEdit
              Left = 110
              Top = 45
              DataBinding.DataField = 'NOMBRE_PROP_PROP'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 420
            end
            object lblTipo: TcxLabel
              Left = 21
              Top = 78
              Caption = 'Tipo de valor'
              TabOrder = 4
              Transparent = True
            end
            object cmbTIPO: TcxDBComboBox
              Left = 110
              Top = 75
              DataBinding.DataField = 'TIPO_VALOR_PROP'
              DataBinding.DataSource = dsTablaG
              Properties.DropDownListStyle = lsFixedList
              Properties.Items.Strings = (
                'LISTA'
                'TEXTO_LIBRE'
                'NUMERO'
                'BOOLEANO')
              TabOrder = 5
              Width = 180
            end
            object chkACTIVO: TcxDBCheckBox
              Left = 320
              Top = 78
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_PROP'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 6
              Transparent = True
              Width = 100
            end
          end
        end
        object cxspltr1: TcxSplitter
          Left = 0
          Top = 113
          Width = 943
          Height = 10
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnl1
        end
        object pnl2: TPanel
          Left = 0
          Top = 123
          Width = 943
          Height = 361
          Align = alClient
          TabOrder = 1
          object pcPestana: TcxPageControl
            Left = 1
            Top = 1
            Width = 941
            Height = 359
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsValores
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 357
            ClientRectLeft = 2
            ClientRectRight = 939
            ClientRectTop = 29
            object tsValores: TcxTabSheet
              Caption = '&1_Valores Disponibles'
              ImageIndex = 0
              object cxgrdValores: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 328
                Align = alClient
                TabOrder = 0
                object tvValores: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  DataController.DataSource = nil
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Appending = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object tvValoresPV: TcxGridDBColumn
                    Caption = 'Valor'
                    DataBinding.FieldName = 'PV'
                    Width = 240
                  end
                  object tvValoresDESCRIPCION_PV: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_PV'
                    Width = 320
                  end
                  object tvValoresESACTIVO_PV: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_PV'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 80
                  end
                  object tvValoresINSTANTEALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object tvValoresUSUARIOALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIO_ALTA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                end
                object lvValores: TcxGridLevel
                  GridView = tvValores
                end
              end
            end
            object tsArticulos: TcxTabSheet
              Caption = '&2_Art'#237'culos'
              ImageIndex = 1
              object cxgrdArticulos: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 328
                Align = alClient
                TabOrder = 0
                object tvArticulos: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  DataController.DataSource = nil
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object tvArticulosCODIGO_ART_ART: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_ART'
                    Width = 160
                  end
                  object tvArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ART'
                    Width = 280
                  end
                  object tvArticulosVALOR_LISTA: TcxGridDBColumn
                    Caption = 'Valor (lista)'
                    DataBinding.FieldName = 'VALOR_LISTA'
                    Width = 200
                  end
                  object tvArticulosVALOR_LIBRE_ARTPROP: TcxGridDBColumn
                    Caption = 'Valor libre'
                    DataBinding.FieldName = 'VALOR_LIBRE_ARTPROP'
                    Width = 200
                  end
                  object tvArticulosINSTANTEALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object tvArticulosUSUARIOALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIO_ALTA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                end
                object lvArticulos: TcxGridLevel
                  GridView = tvArticulos
                end
              end
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 240
          ExplicitWidth = 240
        end
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmPropiedades.unqryTablaG
    OnStateChange = dsTablaGStateChange
  end
  object alPropiedades: TActionList
    Left = 360
    Top = 24
    object actGoArticulo: TAction
      Category = 'Navegaci'#243'n'
      Caption = 'Ir al art'#237'culo'
      Hint = 'Abre la ficha del art'#237'culo seleccionado en la pesta'#241'a Art'#237'culos'
      ShortCut = 16449
      OnExecute = actGoArticuloExecute
      OnUpdate = actGoArticuloUpdate
    end
  end
end
