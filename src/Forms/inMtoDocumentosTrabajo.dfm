inherited frmMtoDocumentosTrabajo: TfrmMtoDocumentosTrabajo
  Caption = 'Documentos de Trabajo'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        object pcAmbitoDTR: TcxPageControl
          Left = 0
          Top = 0
          Width = 943
          Height = 34
          Align = alTop
          TabOrder = 0
          Properties.ActivePage = tsAmbitoPropiosDTR
          Properties.CustomButtons.Buttons = <>
          OnChange = pcAmbitoDTRChange
          ClientRectBottom = 30
          ClientRectLeft = 4
          ClientRectRight = 939
          ClientRectTop = 28
          object tsAmbitoPropiosDTR: TcxTabSheet
            Caption = 'Mis documentos'
            ImageIndex = 0
          end
          object tsAmbitoCompartidosDTR: TcxTabSheet
            Caption = 'Compartidos conmigo'
            ImageIndex = 1
          end
        end
        inherited cxGrdPrincipal: TcxGrid
          Top = 34
          Align = alTop
          Height = 211
          TabOrder = 1
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
              Caption = 'Propietario'
              DataBinding.FieldName = 'USUARIO_DTR'
              Options.Editing = False
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
          object pnlAccionesDTR: TPanel
            Left = 0
            Top = 0
            Width = 943
            Height = 32
            Align = alTop
            BevelOuter = bvNone
            TabOrder = 0
            object lblLineasDTR: TcxLabel
              Left = 0
              Top = 0
              Align = alLeft
              Caption = 'Detalle'
              Properties.Alignment.Vert = taVCenter
              Height = 32
              Width = 160
            end
            object btnImprimirEtiquetasDTR: TcxButton
              Left = 763
              Top = 0
              Width = 180
              Height = 32
              Align = alRight
              Caption = 'Imprimir etiquetas'
              TabOrder = 1
              OnClick = btnImprimirEtiquetasDTRClick
            end
          end
          object pcDetalleDTR: TcxPageControl
            Left = 0
            Top = 32
            Width = 943
            Height = 199
            Align = alClient
            TabOrder = 1
            Properties.ActivePage = tsLineasDTR
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 195
            ClientRectLeft = 4
            ClientRectRight = 939
            ClientRectTop = 28
            object tsLineasDTR: TcxTabSheet
              Caption = 'Lineas'
              ImageIndex = 0
              object cxgrdLineasDTR: TcxGrid
                Left = 0
                Top = 0
                Width = 935
                Height = 167
                Align = alClient
                TabOrder = 0
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
            object tsCompartirDTR: TcxTabSheet
              Caption = 'Compartido con'
              ImageIndex = 1
              object cxgrdCompartidosDTR: TcxGrid
                Left = 0
                Top = 0
                Width = 935
                Height = 167
                Align = alClient
                TabOrder = 0
                object tvCompartidosDTR: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  ScrollbarAnnotations.CustomAnnotations = <>
                  OptionsData.Editing = True
                  OptionsView.GroupByBox = False
                  object colDtcUsuario: TcxGridDBColumn
                    Caption = 'Usuario'
                    DataBinding.FieldName = 'USUARIO_DTC'
                    Width = 180
                  end
                  object colDtcPermiso: TcxGridDBColumn
                    Caption = 'Permiso'
                    DataBinding.FieldName = 'PERMISO_DTC'
                    Width = 110
                  end
                  object colDtcAlta: TcxGridDBColumn
                    Caption = 'Alta'
                    DataBinding.FieldName = 'INSTANTE_ALTA'
                    Options.Editing = False
                    Width = 135
                  end
                end
                object glCompartidosDTR: TcxGridLevel
                  GridView = tvCompartidosDTR
                end
              end
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
