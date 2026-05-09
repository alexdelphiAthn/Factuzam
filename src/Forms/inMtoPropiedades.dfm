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
            OptionsData.Editing = True
            object cxGrdDBTabPrinCODIGO_PROP_ARTPROP: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_PROP_ARTPROP'
              Options.Editing = False
              Width = 140
            end
            object cxGrdDBTabPrinNOMBRE_PROP_PROP: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_PROP_PROP'
              Width = 240
            end
            object cxGrdDBTabPrinTIPO_VALOR_PROP: TcxGridDBColumn
              Caption = 'Tipo de valor'
              DataBinding.FieldName = 'TIPO_VALOR_PROP'
              PropertiesClassName = 'TcxComboBoxProperties'
              Properties.DropDownListStyle = lsFixedList
              Properties.Items.Strings = (
                'LISTA'
                'TEXTO_LIBRE'
                'NUMERO'
                'BOOLEANO')
              Width = 130
            end
            object cxGrdDBTabPrinESACTIVO_PROP: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_PROP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
            object cxGrdDBTabPrinNUM_ART_USOS: TcxGridDBColumn
              Caption = 'Art'#237'culos asignados'
              DataBinding.FieldName = 'NUM_ART_USOS'
              Options.Editing = False
              HeaderAlignmentHorz = taRightJustify
              Width = 140
            end
            object cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTE_MODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Options.Editing = False
              Visible = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 130
            end
            object cxGrdDBTabPrinUSUARIO_MODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIO_MODIF'
              Options.Editing = False
              Visible = False
              Width = 130
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
        object pnlCabFicha: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 110
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object lblCodigo: TcxLabel
            Left = 18
            Top = 16
            Caption = 'C'#243'digo'
            Transparent = True
          end
          object edtCodigo: TcxDBTextEdit
            Left = 110
            Top = 13
            DataBinding.DataField = 'CODIGO_PROP_ARTPROP'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 0
            Width = 180
          end
          object lblNombre: TcxLabel
            Left = 18
            Top = 47
            Caption = 'Nombre'
            Transparent = True
          end
          object edtNombre: TcxDBTextEdit
            Left = 110
            Top = 44
            DataBinding.DataField = 'NOMBRE_PROP_PROP'
            DataBinding.DataSource = dsTablaG
            TabOrder = 1
            Width = 420
          end
          object lblTipo: TcxLabel
            Left = 18
            Top = 78
            Caption = 'Tipo de valor'
            Transparent = True
          end
          object cmbTipo: TcxDBComboBox
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
            TabOrder = 2
            Width = 180
          end
          object chkActivo: TcxDBCheckBox
            Left = 320
            Top = 78
            Caption = 'Activo'
            DataBinding.DataField = 'ESACTIVO_PROP'
            DataBinding.DataSource = dsTablaG
            Properties.ValueChecked = 'S'
            Properties.ValueUnchecked = 'N'
            TabOrder = 3
            Transparent = True
            Width = 100
          end
        end
        object splFicha: TcxSplitter
          Left = 0
          Top = 110
          Width = 943
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlCabFicha
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 118
          Width = 943
          Height = 366
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 1
          object pcDetalleFicha: TcxPageControl
            Left = 0
            Top = 0
            Width = 943
            Height = 366
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsValores
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 364
            ClientRectLeft = 2
            ClientRectRight = 941
            ClientRectTop = 29
            object tsValores: TcxTabSheet
              Caption = '&Valores Disponibles'
              ImageIndex = 0
              object cxGrdValores: TcxGrid
                Left = 0
                Top = 0
                Width = 939
                Height = 335
                Align = alClient
                TabOrder = 0
                object cxGrdValView: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  DataController.DataSource = nil
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Appending = True
                  OptionsData.Editing = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object cxGrdValPV: TcxGridDBColumn
                    Caption = 'Valor'
                    DataBinding.FieldName = 'PV'
                    Width = 240
                  end
                  object cxGrdValDESCRIPCION_PV: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_PV'
                    Width = 320
                  end
                  object cxGrdValESACTIVO_PV: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_PV'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 80
                  end
                  object cxGrdValINSTANTE_ALTA: TcxGridDBColumn
                    Caption = 'Instante Alta'
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Options.Editing = False
                    Width = 150
                  end
                  object cxGrdValUSUARIO_ALTA: TcxGridDBColumn
                    Caption = 'Usuario Alta'
                    DataBinding.FieldName = 'USUARIO_ALTA'
                    Options.Editing = False
                    Width = 130
                  end
                end
                object cxGrdValLevel: TcxGridLevel
                  GridView = cxGrdValView
                end
              end
            end
            object tsArticulos: TcxTabSheet
              Caption = '&Art'#237'culos'
              ImageIndex = 1
              object cxGrdArticulos: TcxGrid
                Left = 0
                Top = 0
                Width = 939
                Height = 335
                Align = alClient
                TabOrder = 0
                object cxGrdArtView: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  DataController.DataSource = nil
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object cxGrdArtCODIGO_ART_ART: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_ART'
                    Width = 160
                  end
                  object cxGrdArtDESCRIPCION_ARTICULO: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO'
                    Width = 280
                  end
                  object cxGrdArtVALOR_LISTA: TcxGridDBColumn
                    Caption = 'Valor (lista)'
                    DataBinding.FieldName = 'VALOR_LISTA'
                    Width = 200
                  end
                  object cxGrdArtVALOR_LIBRE_ARTPROP: TcxGridDBColumn
                    Caption = 'Valor libre'
                    DataBinding.FieldName = 'VALOR_LIBRE_ARTPROP'
                    Width = 200
                  end
                  object cxGrdArtINSTANTE_ALTA: TcxGridDBColumn
                    Caption = 'Instante Alta'
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Width = 150
                  end
                  object cxGrdArtUSUARIO_ALTA: TcxGridDBColumn
                    Caption = 'Usuario Alta'
                    DataBinding.FieldName = 'USUARIO_ALTA'
                    Width = 130
                  end
                end
                object cxGrdArtLevel: TcxGridLevel
                  GridView = cxGrdArtView
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
