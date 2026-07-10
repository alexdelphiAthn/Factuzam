inherited frmMtoCajaPagosHist: TfrmMtoCajaPagosHist
  Caption = 'Hist'#243'rico de Pagos de Caja'
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
            object cxGrdDBTabPrinCODIGO_EMPRESA_PAGO: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_PAGO'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_PAGO: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_PAGO'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_CAJA_PAGO: TcxGridDBColumn
              Caption = 'Caja'
              DataBinding.FieldName = 'CODIGO_CAJA_PAGO'
              Width = 70
            end
            object cxGrdDBTabPrinSERIE_OPERACION_PAGO: TcxGridDBColumn
              Caption = 'Serie Op.'
              DataBinding.FieldName = 'SERIE_OPERACION_PAGO'
              Width = 90
            end
            object cxGrdDBTabPrinNUMERO_OPERACION_PAGO: TcxGridDBColumn
              Caption = 'N'#250'mero Op.'
              DataBinding.FieldName = 'NUMERO_OPERACION_PAGO'
              Width = 130
            end
            object cxGrdDBTabPrinNUMERO_LINEA_PAGO: TcxGridDBColumn
              Caption = 'L'#237'nea'
              DataBinding.FieldName = 'NUMERO_LINEA_PAGO'
              Width = 70
            end
            object cxGrdDBTabPrinFECHA_PAGO: TcxGridDBColumn
              Caption = 'Fecha Pago'
              DataBinding.FieldName = 'FECHA_PAGO'
              Options.Editing = False
              Width = 160
            end
            object cxGrdDBTabPrinCODIGO_FORMAP: TcxGridDBColumn
              Caption = 'Forma de Pago'
              DataBinding.FieldName = 'CODIGO_FP_CFP'
              Width = 120
            end
            object cxGrdDBTabPrinCODIGO_DIVISA_PAGO: TcxGridDBColumn
              Caption = 'Divisa'
              DataBinding.FieldName = 'CODIGO_DIVISA_PAGO'
              Width = 80
            end
            object cxGrdDBTabPrinRED_BLOCKCHAIN: TcxGridDBColumn
              Caption = 'Red Blockchain'
              DataBinding.FieldName = 'RED_BLOCKCHAIN_PAGO'
              Width = 130
            end
            object cxGrdDBTabPrinFACTOR_CAMBIO_PAGO: TcxGridDBColumn
              Caption = 'Factor Cambio'
              DataBinding.FieldName = 'FACTOR_CAMBIO_PAGO'
              Width = 110
            end
            object cxGrdDBTabPrinIMPORTE_DIVISA_PAGO: TcxGridDBColumn
              Caption = 'Importe Divisa'
              DataBinding.FieldName = 'IMPORTE_DIVISA_PAGO'
              Width = 120
            end
            object cxGrdDBTabPrinIMPORTE_ENTREGADO_PAGO: TcxGridDBColumn
              Caption = 'Importe Entregado'
              DataBinding.FieldName = 'IMPORTE_ENTREGADO_PAGO'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 130
            end
            object cxGrdDBTabPrinIMPORTE_CAMBIO_PAGO: TcxGridDBColumn
              Caption = 'Importe Cambio'
              DataBinding.FieldName = 'IMPORTE_CAMBIO_PAGO'
              Width = 120
            end
            object cxGrdDBTabPrinREFERENCIA_PAGO: TcxGridDBColumn
              Caption = 'Referencia'
              DataBinding.FieldName = 'REFERENCIA_FACPAG'
              Width = 200
            end
            object cxGrdDBTabPrinOBSERVACIONES_PAGO: TcxGridDBColumn
              Caption = 'Observaciones'
              DataBinding.FieldName = 'OBSERVACIONES_PAGO'
              Width = 200
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Options.Editing = False
              Visible = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 130
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
              TabOrder = 3
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
            object btnCargarPagos: TcxButton
              Left = 312
              Top = 4
              Width = 95
              Height = 25
              Caption = 'Cargar'
              TabOrder = 1
              OnClick = btnCargarPagosClick
            end
            object btnGuardarPrecargaCaja: TcxButton
              Left = 416
              Top = 4
              Width = 130
              Height = 25
              Caption = 'Guardar precarga'
              TabOrder = 2
              OnClick = btnGuardarPrecargaCajaClick
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
    DataSet = dmCajaPagosHist.unqryTablaG
  end
end
