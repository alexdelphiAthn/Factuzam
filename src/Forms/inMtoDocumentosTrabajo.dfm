inherited frmMtoDocumentosTrabajo: TfrmMtoDocumentosTrabajo
  Caption = 'Documentos de Trabajo'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          Align = alTop
          Height = 245
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object colDtrId: TcxGridDBColumn
              Caption = 'ID'
              DataBinding.FieldName = 'ID_DTR'
              Options.Editing = False
              Width = 70
            end
            object colDtrTitulo: TcxGridDBColumn
              Caption = 'Titulo'
              DataBinding.FieldName = 'TITULO_DTR'
              Width = 240
            end
            object colDtrTipo: TcxGridDBColumn
              Caption = 'Tipo'
              DataBinding.FieldName = 'TIPO_DTR'
              Width = 90
            end
            object colDtrEstado: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_DTR'
              Width = 90
            end
            object colDtrUsuario: TcxGridDBColumn
              Caption = 'Usuario'
              DataBinding.FieldName = 'USUARIO_DTR'
              Width = 110
            end
            object colDtrInstante: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'INSTANTE_DOCUMENTO_DTR'
              Width = 135
            end
            object colDtrEmpresa: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_DTR'
              Width = 90
            end
            object colDtrAlmacen: TcxGridDBColumn
              Caption = 'Almacen'
              DataBinding.FieldName = 'CODIGO_ALM_DTR'
              Width = 90
            end
          end
        end
        object splLineasDTR: TcxSplitter
          Left = 0
          Top = 245
          Width = 943
          Height = 8
          AlignSplitter = salTop
          Control = cxGrdPrincipal
        end
        object pnlLineasDTR: TPanel
          Left = 0
          Top = 253
          Width = 943
          Height = 231
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object lblLineasDTR: TcxLabel
            Left = 0
            Top = 0
            Align = alTop
            Caption = 'Lineas'
            Properties.Alignment.Vert = taVCenter
            Height = 24
            Width = 943
          end
          object cxgrdLineasDTR: TcxGrid
            Left = 0
            Top = 24
            Width = 943
            Height = 207
            Align = alClient
            TabOrder = 1
            object tvLineasDTR: TcxGridDBTableView
              Navigator.Buttons.CustomButtons = <>
              ScrollbarAnnotations.CustomAnnotations = <>
              OptionsData.Editing = True
              OptionsView.GroupByBox = False
              object colDtlLinea: TcxGridDBColumn
                Caption = 'Linea'
                DataBinding.FieldName = 'LINEA_DTL'
                Width = 70
              end
              object colDtlArticulo: TcxGridDBColumn
                Caption = 'Articulo'
                DataBinding.FieldName = 'CODIGO_ART_DTL'
                Width = 110
              end
              object colDtlSku: TcxGridDBColumn
                Caption = 'SKU'
                DataBinding.FieldName = 'CODIGO_UNIDAD_DTL'
                Width = 160
              end
              object colDtlAlmacen: TcxGridDBColumn
                Caption = 'Almacen'
                DataBinding.FieldName = 'CODIGO_ALM_DTL'
                Width = 90
              end
              object colDtlDescripcionArticulo: TcxGridDBColumn
                Caption = 'Descripcion articulo'
                DataBinding.FieldName = 'DESCRIPCION_ARTICULO_DTL'
                Width = 220
              end
              object colDtlDescripcionSku: TcxGridDBColumn
                Caption = 'Descripcion unidad'
                DataBinding.FieldName = 'DESCRIPCION_UNIDAD_DTL'
                Width = 180
              end
              object colDtlCantidadStock: TcxGridDBColumn
                Caption = 'Stock'
                DataBinding.FieldName = 'CANTIDAD_STOCK_DTL'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 80
              end
              object colDtlCantidad: TcxGridDBColumn
                Caption = 'Cantidad'
                DataBinding.FieldName = 'CANTIDAD_DTL'
                PropertiesClassName = 'TcxCurrencyEditProperties'
                Width = 90
              end
              object colDtlOrigen: TcxGridDBColumn
                Caption = 'Origen'
                DataBinding.FieldName = 'ORIGEN_DTL'
                Width = 80
              end
              object colDtlInstanteStock: TcxGridDBColumn
                Caption = 'Instante stock'
                DataBinding.FieldName = 'INSTANTE_STOCK_DTL'
                Width = 135
              end
            end
            object glLineasDTR: TcxGridLevel
              GridView = tvLineasDTR
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
      end
    end
  end
end
