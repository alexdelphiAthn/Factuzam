inherited frmMtoCajaOperacionesHist: TfrmMtoCajaOperacionesHist
  Caption = 'Hist'#243'rico de Operaciones de Caja'
  OnDestroy = FormDestroy
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
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            object cxGrdDBTabPrinCODIGO_EMPRESA_OPCAJA: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_OPCAJA'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_OPCAJA: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_OPCAJA'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_CAJA_OPCAJA: TcxGridDBColumn
              Caption = 'Caja'
              DataBinding.FieldName = 'CODIGO_CAJA_OPCAJA'
              Width = 70
            end
            object cxGrdDBTabPrinNUMERO_OPERACION_OPCAJA: TcxGridDBColumn
              Caption = 'N'#250'mero Operaci'#243'n'
              DataBinding.FieldName = 'NUMERO_OPERACION_OPCAJA'
              Width = 160
            end
            object cxGrdDBTabPrinFECHA_OPERACION_OPCAJA: TcxGridDBColumn
              Caption = 'Fecha/Hora'
              DataBinding.FieldName = 'FECHA_OP'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy hh:nn'
              Width = 128
            end
            object cxGrdDBTabPrinTIPO_OPERACION_OPCAJA: TcxGridDBColumn
              Caption = 'Tipos'
              DataBinding.FieldName = 'TIPOS_OP'
              Width = 86
            end
            object cxGrdDBTabPrinCODIGO_EMPLEADO_OPCAJA: TcxGridDBColumn
              Caption = 'Empleado'
              DataBinding.FieldName = 'EMPLEADO'
              Width = 100
            end
            object cxGrdDBTabPrinIMPORTE_TOTAL_OPCAJA: TcxGridDBColumn
              Caption = 'Importe'
              DataBinding.FieldName = 'IMPORTE_TOTAL'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 101
            end
            object cxGrdDBTabPrinCODIGO_CLIENTE_OPCAJA: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CLIENTE'
              Width = 78
            end
            object cxGrdDBTabPrinRAZON_SOCIAL_CLI: TcxGridDBColumn
              Caption = 'Raz'#243'n social'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLI'
              Width = 226
            end
            object cxGrdDBTabPrinSERIE_FACTURA_OPCAJA: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FAC'
              Width = 78
            end
            object cxGrdDBTabPrinNRO_FACTURA_OPCAJA: TcxGridDBColumn
              Caption = 'N'#186' Borrador'
              DataBinding.FieldName = 'NUMERO_FAC'
              Width = 97
            end
            object cxGrdDBTabPrinCONCEPTO_GASTO_INGRESO_OPCAJA: TcxGridDBColumn
              Caption = 'Conceptos'
              DataBinding.FieldName = 'CONCEPTOS'
              Width = 230
            end
          end
        end
        object pnlFiltrosCaja: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 60
          Align = alTop
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
          object btnToggleFiltrosCaja: TcxButton
            Left = 0
            Top = 0
            Width = 943
            Height = 22
            Align = alTop
            Caption = #9654'  Filtros de carga'
            LookAndFeel.Kind = lfUltraFlat
            LookAndFeel.NativeStyle = False
            TabOrder = 0
            OnClick = btnToggleFiltrosCajaClick
          end
          object pnlContFiltrosCaja: TPanel
            Left = 0
            Top = 22
            Width = 943
            Height = 38
            Align = alClient
            BevelOuter = bvNone
            ParentBackground = False
            TabOrder = 1
            object lblFiltroAnyo: TcxLabel
              Left = 16
              Top = 8
              Caption = 'A'#241'os:'
              TabOrder = 2
              Transparent = True
            end
            object ccbFiltroAnyo: TcxCheckComboBox
              Left = 80
              Top = 5
              Properties.EditValueFormat = cvfStatesString
              Properties.EmptySelectionText = 'Todos'
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroAnyoPropertiesCloseUp
              TabOrder = 0
              Width = 210
            end
            object lblFiltroAlmacen: TcxLabel
              Left = 320
              Top = 8
              Caption = 'Almacenes:'
              TabOrder = 3
              Transparent = True
            end
            object ccbFiltroAlmacen: TcxCheckComboBox
              Left = 416
              Top = 5
              Properties.EditValueFormat = cvfStatesString
              Properties.EmptySelectionText = 'Todos'
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroAlmacenPropertiesCloseUp
              TabOrder = 1
              Width = 340
            end
            object btnGuardarPrecargaCaja: TcxButton
              Left = 768
              Top = 4
              Width = 130
              Height = 25
              Caption = 'Guardar precarga'
              TabOrder = 4
              OnClick = btnGuardarPrecargaCajaClick
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
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
        object btnImprimirInforme: TcxButton
          Left = 848
          Top = 2
          Width = 150
          Height = 30
          Caption = 'Imprimir Informe A4'
          TabOrder = 6
          OnClick = btnImprimirInformeClick
        end
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmCajaOperacionesHist.unqryTablaG
  end
  object alOperaciones: TActionList
    Left = 640
    Top = 16
    object actIrFacturaSimplif: TAction
      Caption = 'Ir a Borrador Simplificado'
      ShortCut = 24646
      OnExecute = actIrFacturaSimplifExecute
    end
  end
end
