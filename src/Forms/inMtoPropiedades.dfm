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
        TabVisible = False
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
      end
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
      end
      object tsArticulos: TcxTabSheet
        Caption = 'Art'#237'culos que la usan'
        ImageIndex = 3
        object cxGrdArticulos: TcxGrid
          Left = 0
          Top = 0
          Width = 947
          Height = 487
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
