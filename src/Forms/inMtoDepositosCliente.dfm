inherited frmMtoDepositosCliente: TfrmMtoDepositosCliente
  Caption = 'Dep'#243'sitos de Clientes'
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
            object cxGrdDBTabPrinID_DEPOSITO_DEP: TcxGridDBColumn
              Caption = 'ID Dep'#243'sito'
              DataBinding.FieldName = 'ID_DEPOSITO_DEP'
              Width = 130
            end
            object cxGrdDBTabPrinCODIGO_EMPRESA_DEP: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMPRESA_DEP'
              Width = 90
            end
            object cxGrdDBTabPrinCODIGO_CLIENTE_DEP: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLIENTE_DEP'
              Width = 130
            end
            object cxGrdDBTabPrinCODIGO_ARTICULO_DEP: TcxGridDBColumn
              Caption = 'Art'#237'culo'
              DataBinding.FieldName = 'CODIGO_ARTICULO_DEP'
              Width = 160
            end
            object cxGrdDBTabPrinCODIGO_UNIDAD_DEP: TcxGridDBColumn
              Caption = 'SKU/Unidad'
              DataBinding.FieldName = 'CODIGO_UNIDAD_DEP'
              Width = 180
            end
            object cxGrdDBTabPrinPRECIO_VENTA_DEP: TcxGridDBColumn
              Caption = 'Precio Venta'
              DataBinding.FieldName = 'PRECIO_VENTA_DEP'
              Width = 110
            end
            object cxGrdDBTabPrinIMPORTE_ANTICIPO_DEP: TcxGridDBColumn
              Caption = 'Anticipo'
              DataBinding.FieldName = 'IMPORTE_ANTICIPO_DEP'
              Width = 110
            end
            object cxGrdDBTabPrinESTADO_DEP: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_DEP'
              Width = 110
            end
            object cxGrdDBTabPrinFECHA_CREACION_DEP: TcxGridDBColumn
              Caption = 'F. Creaci'#243'n'
              DataBinding.FieldName = 'FECHA_CREACION_DEP'
              Width = 140
            end
            object cxGrdDBTabPrinFECHA_ENTREGA_DEP: TcxGridDBColumn
              Caption = 'F. Entrega'
              DataBinding.FieldName = 'FECHA_ENTREGA_DEP'
              Width = 120
            end
            object cxGrdDBTabPrinCANTIDAD_PENDIENTE_DEP: TcxGridDBColumn
              Caption = 'Cant. Pendiente'
              DataBinding.FieldName = 'CANTIDAD_PENDIENTE_DEP'
              Width = 130
            end
            object cxGrdDBTabPrinTIPO_IVA_DEP: TcxGridDBColumn
              Caption = 'Tipo IVA'
              DataBinding.FieldName = 'TIPO_IVA_DEP'
              Width = 80
            end
            object cxGrdDBTabPrinPORCEN_IVA_DEP: TcxGridDBColumn
              Caption = '% IVA'
              DataBinding.FieldName = 'PORCEN_IVA_DEP'
              Width = 80
            end
            object cxGrdDBTabPrinESIMP_INCL_DEP: TcxGridDBColumn
              Caption = 'IVA Incl.'
              DataBinding.FieldName = 'ESIMP_INCL_DEP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTEALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTEMODIF'
              Options.Editing = False
              Visible = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIOALTA'
              Options.Editing = False
              Width = 130
            end
            object cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIOMODIF'
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
    DataSet = dmDepositosCliente.unqryTablaG
  end
end
