inherited frmMtoMovimientosAlmacen: TfrmMtoMovimientosAlmacen
  Caption = 'Movimientos de Almac'#233'n'
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
            object cxGrdDBTabPrinNUMERO_MOV: TcxGridDBColumn
              Caption = 'N'#250'mero Mov.'
              DataBinding.FieldName = 'NUMERO_MOV'
              Width = 130
            end
            object cxGrdDBTabPrinFECHA_MOV: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_MOV'
              Width = 140
            end
            object cxGrdDBTabPrinTIPO_MOVIMIENTO_MOV: TcxGridDBColumn
              Caption = 'E/S'
              DataBinding.FieldName = 'TIPO_MOV'
              Width = 50
            end
            object cxGrdDBTabPrinTIPO_DOC_MOV: TcxGridDBColumn
              Caption = 'Tipo Doc.'
              DataBinding.FieldName = 'TIPO_DOC_MOV'
              Width = 80
            end
            object cxGrdDBTabPrinSERIE_DOC_MOV: TcxGridDBColumn
              Caption = 'Serie Doc.'
              DataBinding.FieldName = 'SERIE_DOC_MOV'
              Width = 100
            end
            object cxGrdDBTabPrinNRO_DOC_MOV: TcxGridDBColumn
              Caption = 'Nro. Doc.'
              DataBinding.FieldName = 'NUMERO_DOC_MOV'
              Width = 100
            end
            object cxGrdDBTabPrinLINEA_MOV: TcxGridDBColumn
              Caption = 'L'#237'nea'
              DataBinding.FieldName = 'LINEA_MOV'
              Width = 60
            end
            object cxGrdDBTabPrinCODIGO_EMPRESA_MOV: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_MOV'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_MOV: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_MOV'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_ARTICULO_MOV: TcxGridDBColumn
              Caption = 'Art'#237'culo'
              DataBinding.FieldName = 'CODIGO_ART_MOV'
              Width = 130
            end
            object cxGrdDBTabPrinCODIGO_UNIDAD_MOV: TcxGridDBColumn
              Caption = 'SKU'
              DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
              Width = 160
            end
            object cxGrdDBTabPrinDESCRIPCION_ARTICULO_MOV: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_ARTICULO_MOV'
              Width = 200
            end
            object cxGrdDBTabPrinCANTIDAD_MOV: TcxGridDBColumn
              Caption = 'Cantidad'
              DataBinding.FieldName = 'CANTIDAD_MOV'
              Width = 100
            end
            object cxGrdDBTabPrinPRECIO_COSTE_UNITARIO_MOV: TcxGridDBColumn
              Caption = 'Coste Unit.'
              DataBinding.FieldName = 'PRECIO_COSTE_UNITARIO_MOV'
              Width = 110
            end
            object cxGrdDBTabPrinTOTAL_COSTE_MOV: TcxGridDBColumn
              Caption = 'Total Coste'
              DataBinding.FieldName = 'TOTAL_COSTE_MOV'
              Width = 110
            end
            object cxGrdDBTabPrinPRECIO_MEDIO_MOV: TcxGridDBColumn
              Caption = 'Precio Medio'
              DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
              Width = 110
            end
            object cxGrdDBTabPrinCODIGO_ALMACEN_CONTRA_MOV: TcxGridDBColumn
              Caption = 'Almac'#233'n Contra'
              DataBinding.FieldName = 'CODIGO_ALM_CONTRA_MOV'
              Width = 130
              Visible = False
            end
            object cxGrdDBTabPrinCODIGO_CLIENTE_MOV: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_MOV'
              Width = 120
              Visible = False
            end
            object cxGrdDBTabPrinCODIGO_PROVEEDOR_MOV: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_MOV'
              Width = 120
              Visible = False
            end
            object cxGrdDBTabPrinESACTIVO_MOV: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_MOV'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
            object cxGrdDBTabPrinTIPO_DOC_REF_MOV: TcxGridDBColumn
              Caption = 'Tipo Ref.'
              DataBinding.FieldName = 'TIPO_DOC_REF_MOV'
              Width = 90
              Visible = False
            end
            object cxGrdDBTabPrinSERIE_DOC_REF_MOV: TcxGridDBColumn
              Caption = 'Serie Ref.'
              DataBinding.FieldName = 'SERIE_DOC_REF_MOV'
              Width = 100
              Visible = False
            end
            object cxGrdDBTabPrinNRO_DOC_REF_MOV: TcxGridDBColumn
              Caption = 'Nro. Ref.'
              DataBinding.FieldName = 'NUMERO_DOC_REF_MOV'
              Width = 100
              Visible = False
            end
            object cxGrdDBTabPrinLINEA_REF_MOV: TcxGridDBColumn
              Caption = 'L'#237'nea Ref.'
              DataBinding.FieldName = 'LINEA_REF_MOV'
              Width = 90
              Visible = False
            end
            object cxGrdDBTabPrinLOTE_MOV: TcxGridDBColumn
              Caption = 'Lote'
              DataBinding.FieldName = 'LOTE_MOV'
              Width = 110
              Visible = False
            end
            object cxGrdDBTabPrinFECHA_CADUCIDAD_MOV: TcxGridDBColumn
              Caption = 'F. Caducidad'
              DataBinding.FieldName = 'FECHA_CADUCIDAD_MOV'
              Width = 120
              Visible = False
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
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmMovimientosAlmacen.unqryTablaG
  end
end
