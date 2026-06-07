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
            OptionsData.Editing = True
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
              Caption = 'Fecha Operaci'#243'n'
              DataBinding.FieldName = 'FECHA_OPERACION_OPCAJA'
              Width = 160
            end
            object cxGrdDBTabPrinTIPO_OPERACION_OPCAJA: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'TIPO_OPERACION_OPCAJA'
              Width = 70
            end
            object cxGrdDBTabPrinCODIGO_EMPLEADO_OPCAJA: TcxGridDBColumn
              Caption = 'Empleado'
              DataBinding.FieldName = 'CODIGO_EMPLEADO_OPCAJA'
              Width = 110
            end
            object cxGrdDBTabPrinIMPORTE_TOTAL_OPCAJA: TcxGridDBColumn
              Caption = 'Importe Total'
              DataBinding.FieldName = 'IMPORTE_TOTAL_OPCAJA'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Width = 130
            end
            object cxGrdDBTabPrinCODIGO_CLIENTE_OPCAJA: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_OPCAJA'
              Width = 130
            end
            object cxGrdDBTabPrinSERIE_FACTURA_OPCAJA: TcxGridDBColumn
              Caption = 'Serie Factura'
              DataBinding.FieldName = 'SERIE_FAC_OPCAJA'
              Width = 110
            end
            object cxGrdDBTabPrinNRO_FACTURA_OPCAJA: TcxGridDBColumn
              Caption = 'Nro Factura'
              DataBinding.FieldName = 'NUMERO_FAC_OPCAJA'
              Width = 110
            end
            object cxGrdDBTabPrinESTADO_DEVOLUCION_OPCAJA: TcxGridDBColumn
              Caption = 'Devuelto'
              DataBinding.FieldName = 'ESTADO_DEVOLUCION_OPCAJA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 90
            end
            object cxGrdDBTabPrinIMPORTE_DEVUELTO_ACUM_OPCAJA: TcxGridDBColumn
              Caption = 'Importe Devuelto Acum.'
              DataBinding.FieldName = 'IMPORTE_DEVUELTO_ACUM_OPCAJA'
              Width = 160
            end
            object cxGrdDBTabPrinMOTIVO_DEVOLUCION_OPCAJA: TcxGridDBColumn
              Caption = 'Motivo Devoluci'#243'n'
              DataBinding.FieldName = 'MOTIVO_DEVOLUCION_OPCAJA'
              Width = 160
            end
            object cxGrdDBTabPrinSERIE_REF_ORIGEN_OPCAJA: TcxGridDBColumn
              Caption = 'Serie Ref. Origen'
              DataBinding.FieldName = 'SERIE_REF_ORIGEN_OPCAJA'
              Width = 130
            end
            object cxGrdDBTabPrinNUMERO_REF_ORIGEN_OPCAJA: TcxGridDBColumn
              Caption = 'N'#250'mero Ref. Origen'
              DataBinding.FieldName = 'NUMERO_REF_ORIGEN_OPCAJA'
              Width = 150
            end
            object cxGrdDBTabPrinCONCEPTO_GASTO_INGRESO_OPCAJA: TcxGridDBColumn
              Caption = 'Concepto Gasto/Ingreso'
              DataBinding.FieldName = 'CONCEPTO_GASTO_INGRESO_OPCAJA'
              Width = 200
            end
            object cxGrdDBTabPrinES_TRASPASO_OPCAJA: TcxGridDBColumn
              Caption = 'Es Traspaso'
              DataBinding.FieldName = 'ESTRASPASO_OPCAJA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_EMPRESA_CONTRA_OPCAJA: TcxGridDBColumn
              Caption = 'Empresa Contra'
              DataBinding.FieldName = 'CODIGO_EMP_CONTRA_OPCAJA'
              Width = 130
              Visible = False
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_CONTRA_OPCAJA: TcxGridDBColumn
              Caption = 'Almac'#233'n Contra'
              DataBinding.FieldName = 'CODIGO_ALM_CONTRA_OPCAJA'
              Width = 130
              Visible = False
            end
            object cxGrdDBTabPrinCODIGO_ARQUEO_OPCAJA: TcxGridDBColumn
              Caption = 'C'#243'digo Arqueo'
              DataBinding.FieldName = 'CODIGO_ARQUEO_OPCAJA'
              Width = 130
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
            object cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIO_MODIF'
              Options.Editing = False
              Visible = False
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
              TabOrder = 2
              Transparent = True
            end
            object ccbFiltroAnyo: TcxCheckComboBox
              Left = 80
              Top = 5
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
              Properties.EmptySelectionText = 'Todos'
              Properties.Items = <>
              Properties.OnCloseUp = ccbFiltroAlmacenPropertiesCloseUp
              TabOrder = 1
              Width = 340
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
    DataSet = dmCajaOperacionesHist.unqryTablaG
  end
end
