inherited frmMtoAlbaranesCompra: TfrmMtoAlbaranesCompra
  Caption = 'Mantenimiento de Albaranes de Compra'
  ClientHeight = 765
  ClientWidth = 1085
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  ExplicitWidth = 1085
  ExplicitHeight = 765
  TextHeight = 17
  inherited pButtonPage: TPanel
    Width = 945
    Height = 765
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 945
    ExplicitHeight = 765
    inherited pcPantalla: TcxPageControl
      Width = 945
      Height = 725
      ExplicitWidth = 945
      ExplicitHeight = 725
      ClientRectBottom = 721
      ClientRectRight = 941
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 937
        ExplicitHeight = 693
        inherited cxGrdPrincipal: TcxGrid
          Width = 937
          Height = 693
          ExplicitWidth = 937
          ExplicitHeight = 693
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcGrdAlbcCODIGO_EMP_ALBC: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_ALBC'
              Width = 100
            end
            object dbcGrdAlbcSERIE_ALBC: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_ALBC'
              Width = 80
            end
            object dbcGrdAlbcNUMERO_ALBC: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_ALBC'
              Width = 90
            end
            object dbcGrdAlbcFECHA_ALBC: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_ALBC'
              Width = 100
            end
            object dbcGrdAlbcCODIGO_ALM_ALBC: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_ALBC'
              Width = 100
            end
            object dbcGrdAlbcTEMPORADA_ALBC: TcxGridDBColumn
              Caption = 'Temporada'
              DataBinding.FieldName = 'TEMPORADA_ALBC'
              Width = 120
            end
            object dbcGrdAlbcREF_PROVEEDOR_ALBC: TcxGridDBColumn
              Caption = 'Ref. proveedor'
              DataBinding.FieldName = 'REF_PROVEEDOR_ALBC'
              Width = 130
            end
            object dbcGrdAlbcCODIGO_PRV_ALBC: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_ALBC'
              Width = 100
            end
            object dbcGrdAlbcRSPRV_ALBC: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Proveedor'
              DataBinding.FieldName = 'RAZON_SOCIAL_PRV_ALBC'
              Width = 220
            end
            object dbcGrdAlbcTOTAL_PRENDAS_ALBC: TcxGridDBColumn
              Caption = 'Prendas'
              DataBinding.FieldName = 'TOTAL_PRENDAS_ALBC'
              Width = 90
            end
            object dbcGrdAlbcTOTAL_LINEAS_ALBC: TcxGridDBColumn
              Caption = 'Neto lineas'
              DataBinding.FieldName = 'TOTAL_LINEAS_ALBC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 110
            end
            object dbcGrdAlbcTOTAL_LIQUIDO_ALBC: TcxGridDBColumn
              Caption = 'Total l'#237'quido'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_ALBC'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.DisplayFormat = '#,##0.00 '#8364
              Width = 120
            end
            object dbcGrdAlbcNUMERO_PED_ALBC: TcxGridDBColumn
              Caption = 'Pedido origen'
              DataBinding.FieldName = 'NUMERO_PED_ALBC'
              Width = 100
            end
            object dbcGrdAlbcSERIE_PED_ALBC: TcxGridDBColumn
              Caption = 'Serie pedido'
              DataBinding.FieldName = 'SERIE_PED_ALBC'
              Width = 90
            end
            object dbcGrdAlbcNUMERO_FAC_ALBC: TcxGridDBColumn
              Caption = 'Factura creada'
              DataBinding.FieldName = 'NUMERO_FAC_ALBC'
              Width = 100
            end
            object dbcGrdAlbcSERIE_FAC_ALBC: TcxGridDBColumn
              Caption = 'Serie factura'
              DataBinding.FieldName = 'SERIE_FAC_ALBC'
              Width = 90
            end
            object dbcGrdAlbcESDEPOSITO_ALBC: TcxGridDBColumn
              Caption = 'Dep'#243'sito'
              DataBinding.FieldName = 'ESDEPOSITO_ALBC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 937
        ExplicitHeight = 693
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 937
          Height = 200
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pcCab: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 200
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsCabecera
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 196
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsCabecera: TcxTabSheet
              Caption = 'Cabecera'
              object lblNroAlbaran: TcxLabel
                Left = 8
                Top = 12
                Caption = 'N'#250'mero'
                TabOrder = 0
                Transparent = True
              end
              object txtNUMERO_ALBC: TcxDBTextEdit
                Left = 8
                Top = 32
                DataBinding.DataField = 'NUMERO_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 1
                Width = 100
              end
              object lblSerieAlbaran: TcxLabel
                Left = 116
                Top = 12
                Caption = 'Serie'
                TabOrder = 2
                Transparent = True
              end
              object cbbSERIE_ALBC: TcxDBComboBox
                Left = 116
                Top = 32
                DataBinding.DataField = 'SERIE_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 12
                Properties.OnInitPopup = cbbSERIE_ALBCPropertiesInitPopup
                TabOrder = 3
                Width = 80
              end
              object lblFechaAlbaran: TcxLabel
                Left = 204
                Top = 12
                Caption = 'Fecha'
                TabOrder = 4
                Transparent = True
              end
              object dteFECHA_ALBC: TcxDBDateEdit
                Left = 204
                Top = 32
                DataBinding.DataField = 'FECHA_ALBC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 5
                Width = 110
              end
              object lblTemporadaAlbaran: TcxLabel
                Left = 320
                Top = 12
                Caption = 'Temporada'
                TabOrder = 6
                Transparent = True
              end
              object cbbTemporadaAlbc: TcxDBLookupComboBox
                Left = 320
                Top = 32
                DataBinding.DataField = 'ID_PV_TEMPORADA_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'ID_PV_ARTPROP'
                Properties.ListColumns = <
                  item
                    Caption = 'Temporada'
                    FieldName = 'PV'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 7
                Width = 180
              end
              object lblPedidoOrigen: TcxLabel
                Left = 440
                Top = 12
                Caption = 'Pedido origen (N'#250'mero / Serie)'
                TabOrder = 25
                Transparent = True
                Visible = False
              end
              object txtNUMERO_PED_ALBC: TcxDBTextEdit
                Left = 440
                Top = 32
                DataBinding.DataField = 'NUMERO_PED_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 18
                Visible = False
                Width = 90
              end
              object txtSERIE_PED_ALBC: TcxDBTextEdit
                Left = 540
                Top = 32
                DataBinding.DataField = 'SERIE_PED_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 19
                Visible = False
                Width = 80
              end
              object btnIrDocumento: TcxButton
                Left = 440
                Top = 56
                Width = 190
                Height = 23
                Action = actIrDocumento
                Caption = 'Ir a pedido origen'
                TabOrder = 20
                Visible = False
              end
              object lblFacturaDestino: TcxLabel
                Left = 640
                Top = 12
                Caption = 'Factura creada (N'#250'mero / Serie)'
                TabOrder = 21
                Transparent = True
                Visible = False
              end
              object txtNUMERO_FAC_ALBC: TcxDBTextEdit
                Left = 640
                Top = 32
                DataBinding.DataField = 'NUMERO_FAC_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 22
                Visible = False
                Width = 90
              end
              object txtSERIE_FAC_ALBC: TcxDBTextEdit
                Left = 740
                Top = 32
                DataBinding.DataField = 'SERIE_FAC_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 23
                Visible = False
                Width = 80
              end
              object btnIrFacturaCreada: TcxButton
                Left = 640
                Top = 56
                Width = 190
                Height = 23
                Action = actIrFacturaCreada
                TabOrder = 24
                Visible = False
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 8
                Top = 80
                Caption = 'Empresa'
                TabOrder = 8
                Transparent = True
              end
              object btnCODIGO_EMP_ALBC: TcxDBButtonEdit
                Left = 8
                Top = 100
                DataBinding.DataField = 'CODIGO_EMP_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                Properties.OnButtonClick = btnCODIGO_EMP_ALBCPropertiesButtonClick
                Properties.OnEditValueChanged = btnCODIGO_EMP_ALBCPropertiesEditValueChanged
                TabOrder = 9
                OnKeyUp = btnCODIGO_EMP_ALBCKeyUp
                Width = 150
              end
              object lblCodigoProveedor: TcxLabel
                Left = 168
                Top = 80
                Caption = 'Proveedor'
                TabOrder = 10
                Transparent = True
              end
              object cbbCODIGO_PRV_ALBC: TcxDBLookupComboBox
                Left = 168
                Top = 100
                DataBinding.DataField = 'CODIGO_PRV_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsEditList
                Properties.DropDownRows = 15
                Properties.KeyFieldNames = 'CODIGO_PRV_PRV'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    FieldName = 'CODIGO_PRV_PRV'
                  end
                  item
                    Caption = 'Proveedor'
                    FieldName = 'RAZON_SOCIAL_PRV'
                  end>
                TabOrder = 11
                OnKeyUp = cbbCODIGO_PRV_ALBCKeyUp
                Width = 150
              end
              object lblRefProveedor: TcxLabel
                Left = 328
                Top = 80
                Caption = 'Ref. proveedor'
                TabOrder = 12
                Transparent = True
              end
              object txtREF_PROVEEDOR_ALBC: TcxDBTextEdit
                Left = 328
                Top = 100
                DataBinding.DataField = 'REF_PROVEEDOR_ALBC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 13
                Width = 180
              end
              object lblCodigoAlmacen: TcxLabel
                Left = 520
                Top = 80
                Caption = 'Almac'#233'n destino'
                TabOrder = 14
                Transparent = True
              end
              object cbbCODIGO_ALM_ALBC: TcxDBLookupComboBox
                Left = 520
                Top = 100
                DataBinding.DataField = 'CODIGO_ALM_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsFixedList
                Properties.DropDownRows = 15
                Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 60
                    FieldName = 'CODIGO_ALM_ALM'
                  end
                  item
                    Caption = 'Almac'#233'n'
                    FieldName = 'NOMBRE_ALM_ALM'
                  end
                  item
                    Caption = 'Empresa'
                    Width = 60
                    FieldName = 'CODIGO_EMP_ALM'
                  end>
                Properties.OnEditValueChanged = cbbCODIGO_ALM_ALBCPropertiesEditValueChanged
                TabOrder = 15
                Width = 120
              end
              object chkESDEPOSITO_ALBC: TcxDBCheckBox
                Left = 656
                Top = 100
                Caption = 'Dep'#243'sito'
                DataBinding.DataField = 'ESDEPOSITO_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 16
              end
              object lblProveedorNombreAlbc: TcxLabel
                Left = 168
                Top = 124
                ParentFont = False
                Style.Font.Charset = ANSI_CHARSET
                Style.Font.Color = clWindowText
                Style.Font.Height = -15
                Style.Font.Name = 'Lucida Sans'
                Style.Font.Style = [fsBold]
                Style.IsFontAssigned = True
                TabOrder = 17
                Transparent = True
              end
              object lblTotalesTotalPrendas: TcxLabel
                Left = 499
                Top = 131
                Caption = 'N'#186' de prendas'
                TabOrder = 26
                Transparent = True
              end
              object curTotalesTOTAL_PRENDAS_ALBC: TcxDBCurrencyEdit
                Left = 611
                Top = 131
                DataBinding.DataField = 'TOTAL_PRENDAS_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.DecimalPlaces = 0
                Properties.DisplayFormat = '#,##0'
                Properties.ReadOnly = True
                TabOrder = 27
                Width = 133
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 200
          Width = 937
          Height = 8
          Cursor = crSizeNS
          HotZoneClassName = 'TcxMediaPlayer9Style'
          HotZone.SizePercent = 50
          AlignSplitter = salTop
          Control = pnlTopFicha
        end
        object pnlBotonesAcciones: TPanel
          Left = 0
          Top = 208
          Width = 937
          Height = 38
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object btnAnadirLinea: TcxButton
            Left = 8
            Top = 6
            Width = 110
            Height = 26
            Caption = 'A'#241'adir l'#237'nea'
            TabOrder = 0
            OnClick = btnAnadirLineaClick
          end
          object btnBorrarLinea: TcxButton
            Left = 124
            Top = 6
            Width = 110
            Height = 26
            Caption = 'Borrar l'#237'nea'
            TabOrder = 1
            OnClick = btnBorrarLineaClick
          end
          object btnTallasHorizontal: TcxButton
            Left = 256
            Top = 6
            Width = 170
            Height = 26
            Caption = 'Tallas en horizontal'
            TabOrder = 2
            OnClick = btnTallasHorizontalClick
          end
          object btnAtributosColumna: TcxButton
            Left = 432
            Top = 6
            Width = 180
            Height = 26
            Caption = 'Atributo por columna'
            TabOrder = 3
            OnClick = btnAtributosColumnaClick
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 246
          Width = 937
          Height = 371
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcAlbaran: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 371
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsTotales
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 367
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsLineasAlbaran: TcxTabSheet
              Caption = '&1_L'#237'neas '
              object cxgrdLineasAlbaran: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 339
                Align = alClient
                TabOrder = 0
                OnEnter = cxgrdLineasAlbaranEnter
                OnExit = cxgrdLineasAlbaranExit
                object tvLineasAlbaran: TcxGridDBTableView
                  OnCustomDrawCell = tvLineasAlbaranCustomDrawCell
                  OnEditing = tvLineasAlbaranEditing
                  OnFocusedRecordChanged = tvLineasAlbaranFocusedRecordChanged
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.FocusFirstCellOnNewRecord = True
                  OptionsData.Appending = True
                  OptionsView.GroupByBox = False
                  object colLineaAlbcLINEA: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_ALBCLIN'
                    Width = 60
                  end
                  object colLineaAlbcCODIGO_ART: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_ALBCLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = colLineaAlbcCODIGO_ARTPropertiesButtonClick
                    Properties.OnValidate = colLineaAlbcCODIGO_ARTPropertiesValidate
                    Width = 100
                  end
                  object colLineaAlbcCODIGO_UNIDAD: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_ALBCLIN'
                    Width = 120
                  end
                  object colLineaAlbcREF_PRV: TcxGridDBColumn
                    Caption = 'Modelo prov.'
                    DataBinding.FieldName = 'REF_PRV_ALBCLIN'
                    Width = 100
                  end
                  object colLineaAlbcDESCRIPCION: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_ALBCLIN'
                    Width = 240
                  end
                  object colLineaAlbcCANTIDAD: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_ALBCLIN'
                    Width = 80
                  end
                  object colLineaAlbcPRECIO_COMPRA: TcxGridDBColumn
                    Caption = 'Precio compra'
                    DataBinding.FieldName = 'PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = ',0.00 '#8364';-,0.00 '#8364
                    Width = 110
                  end
                  object colLineaAlbcPORCENTAJE_IVA: TcxGridDBColumn
                    Caption = '% IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_ALBCLIN'
                    Width = 70
                  end
                  object colLineaAlbcTOTAL: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_ALBCLIN'
                    Width = 100
                  end
                  object colLineaAlbcALMACEN: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'CODIGO_ALMACEN_ALBCLIN'
                    Width = 90
                  end
                end
                object cxgrdlvlLineasAlbaran: TcxGridLevel
                  GridView = tvLineasAlbaran
                end
              end
            end
            object tsProveedor: TcxTabSheet
              Caption = '&2_Movimientos '
              object cxgrdMovimientosProveedor: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 339
                Align = alClient
                TabOrder = 0
                object tvMovimientosProveedor: TcxGridDBTableView
                  OptionsData.Editing = False
                  OptionsView.GroupByBox = False
                  object colMovProvAlbcNUMERO_MOV: TcxGridDBColumn
                    Caption = 'N'#250'mero Mov.'
                    DataBinding.FieldName = 'NUMERO_MOV'
                    Width = 110
                  end
                  object colMovProvAlbcFECHA_MOV: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_MOV'
                    Width = 130
                  end
                  object colMovProvAlbcLINEA_MOV: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_MOV'
                    Width = 60
                  end
                  object colMovProvAlbcALMACEN: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'NOMBRE_ALMACEN_ORIGEN'
                    Width = 140
                  end
                  object colMovProvAlbcARTICULO: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_MOV'
                    Width = 100
                  end
                  object colMovProvAlbcSKU: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
                    Width = 140
                  end
                  object colMovProvAlbcDESCRIPCION: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_MOV'
                    Width = 220
                  end
                  object colMovProvAlbcTIPO: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_MOV'
                    Width = 50
                  end
                  object colMovProvAlbcCANTIDAD: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_MOV'
                    Width = 90
                  end
                  object colMovProvAlbcPMP: TcxGridDBColumn
                    Caption = 'PMP'
                    DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
                    Width = 90
                  end
                  object colMovProvAlbcTOTAL: TcxGridDBColumn
                    Caption = 'Total coste'
                    DataBinding.FieldName = 'TOTAL_COSTE_MOV'
                    Width = 100
                  end
                end
                object cxgrdlvlMovimientosProveedor: TcxGridLevel
                  GridView = tvMovimientosProveedor
                end
              end
            end
            object tsTotales: TcxTabSheet
              Caption = '&3_Totales'
              ImageIndex = 2
              object scrTotales: TScrollBox
                Left = 0
                Top = 0
                Width = 929
                Height = 339
                VertScrollBar.Position = 32
                Align = alClient
                BorderStyle = bsNone
                ParentBackground = True
                TabOrder = 0
                object lblTotalesTotalBase: TcxLabel
                  Left = 38
                  Top = 7
                  Caption = 'Total Base Imponible'
                  TabOrder = 0
                  Transparent = True
                end
                object curTotalesTOTAL_BASES_ALBC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 3
                  DataBinding.DataField = 'TOTAL_BASES_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DecimalPlaces = 2
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Width = 133
                end
                object lblTotalesTotalImpuestos: TcxLabel
                  Left = 79
                  Top = 45
                  Caption = 'Total Impuestos'
                  TabOrder = 2
                  Transparent = True
                end
                object curTotalesTOTAL_IMPUESTOS_ALBC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 41
                  DataBinding.DataField = 'TOTAL_IMPUESTOS_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DecimalPlaces = 2
                  Properties.DisplayFormat = ',0.00 '#8364';-,0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 133
                end
                object lblTotalesPorcRetencion: TcxLabel
                  Left = 80
                  Top = 86
                  Caption = '% Retenci'#243'n'
                  TabOrder = 4
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_RETENCION_ALBC: TcxDBSpinEdit
                  Left = 230
                  Top = 82
                  DataBinding.DataField = 'PORCENTAJE_RETENCION_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 5
                  Width = 133
                end
                object lblTotalesTotalRetencion: TcxLabel
                  Left = 70
                  Top = 126
                  Caption = 'Total Retenci'#243'n'
                  TabOrder = 6
                  Transparent = True
                end
                object curTotalesTOTAL_RETENCION_ALBC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 122
                  DataBinding.DataField = 'TOTAL_RETENCION_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 133
                end
                object lblTotalesTotalPagar: TcxLabel
                  Left = 105
                  Top = 167
                  Caption = 'Total a pagar'
                  TabOrder = 8
                  Transparent = True
                end
                object curTotalesTOTAL_LIQUIDO_ALBC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 163
                  DataBinding.DataField = 'TOTAL_LIQUIDO_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  Properties.UseThousandSeparator = True
                  TabOrder = 9
                  Width = 133
                end
                object lblTotalesFormaPago: TcxLabel
                  Left = 90
                  Top = 206
                  Caption = 'Forma de Pago'
                  TabOrder = 10
                  Transparent = True
                end
                object cbbTotalesFORMA_PAGO_ALBC: TcxDBLookupComboBox
                  Left = 230
                  Top = 202
                  DataBinding.DataField = 'FORMA_PAGO_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DropDownSizeable = True
                  Properties.KeyFieldNames = 'CODIGO_FP_FP'
                  Properties.ListColumns = <
                    item
                      Caption = 'C'#243'digo'
                      MinWidth = 50
                      Width = 60
                      FieldName = 'CODIGO_FP_FP'
                    end
                    item
                      Caption = 'Descripci'#243'n'
                      MinWidth = 160
                      Width = 220
                      FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  TabOrder = 11
                  Width = 133
                end
                object chkTotalesESIVA_RECARGO_COMPRAS_ALBC: TcxDBCheckBox
                  Left = 56
                  Top = 247
                  Caption = 'Recargo equivalencia compras'
                  DataBinding.DataField = 'ESIVA_RECARGO_COMPRAS_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 12
                  Transparent = True
                end
                object lblTotalesDtoComercial: TcxLabel
                  Left = 60
                  Top = 273
                  Caption = 'Dto. comercial'
                  TabOrder = 13
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_DTO_COMERCIAL_ALBC: TcxDBSpinEdit
                  Left = 185
                  Top = 269
                  DataBinding.DataField = 'PORCENTAJE_DTO_COMERCIAL_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 14
                  Width = 86
                end
                object curTotalesTOTAL_DTO_COMERCIAL_ALBC: TcxDBCurrencyEdit
                  Left = 272
                  Top = 269
                  DataBinding.DataField = 'TOTAL_DTO_COMERCIAL_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 15
                  Width = 91
                end
                object lblTotalesDtoFinanciero: TcxLabel
                  Left = 59
                  Top = 297
                  Caption = 'Dto. financiero'
                  TabOrder = 16
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_DTO_FINANCIERO_ALBC: TcxDBSpinEdit
                  Left = 185
                  Top = 293
                  DataBinding.DataField = 'PORCENTAJE_DTO_FINANCIERO_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 17
                  Width = 86
                end
                object curTotalesTOTAL_DTO_FINANCIERO_ALBC: TcxDBCurrencyEdit
                  Left = 272
                  Top = 293
                  DataBinding.DataField = 'TOTAL_DTO_FINANCIERO_ALBC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 18
                  Width = 91
                end
                object grpDesgloseImpuestos: TGroupBox
                  Left = 384
                  Top = -21
                  Width = 525
                  Height = 318
                  Caption = 'Desglose Impuestos'
                  TabOrder = 19
                  object shpSeparador1: TShape
                    Left = 128
                    Top = 32
                    Width = 382
                    Height = 40
                    Brush.Style = bsClear
                  end
                  object shpSeparador2: TShape
                    Left = 68
                    Top = 71
                    Width = 442
                    Height = 50
                    Brush.Style = bsClear
                  end
                  object shpSeparador3: TShape
                    Left = 13
                    Top = 169
                    Width = 497
                    Height = 50
                    Brush.Style = bsClear
                  end
                  object shpSeparador4: TShape
                    Left = 68
                    Top = 120
                    Width = 442
                    Height = 50
                    Brush.Style = bsClear
                  end
                  object shpSeparador5: TShape
                    Left = 68
                    Top = 218
                    Width = 442
                    Height = 50
                    Brush.Style = bsClear
                  end
                  object lblTotalesTotalRe: TcxLabel
                    Left = 438
                    Top = 40
                    Caption = 'Total R.E.'
                    TabOrder = 0
                    Transparent = True
                  end
                  object lblTotalesPorRe: TcxLabel
                    Left = 388
                    Top = 40
                    Caption = '%R.E.'
                    TabOrder = 1
                    Transparent = True
                  end
                  object lblTotalesTotalIva: TcxLabel
                    Left = 300
                    Top = 40
                    Caption = 'Total IVA'
                    TabOrder = 2
                    Transparent = True
                  end
                  object lblTotalesPorIva: TcxLabel
                    Left = 244
                    Top = 40
                    Caption = '%IVA'
                    TabOrder = 3
                    Transparent = True
                  end
                  object lblTotalesBaseNeta: TcxLabel
                    Left = 142
                    Top = 40
                    Caption = 'BaseNeta'
                    TabOrder = 4
                    Transparent = True
                  end
                  object lblTotalesIVAN: TcxLabel
                    Left = 90
                    Top = 82
                    Caption = 'Normal'
                    TabOrder = 5
                    Transparent = True
                  end
                  object curTotalesTOTAL_BASEI_IVAN_ALBC: TcxDBCurrencyEdit
                    Left = 132
                    Top = 78
                    DataBinding.DataField = 'TOTAL_BASEI_IVAN_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 9
                    Width = 105
                  end
                  object spnTotalesPORCENTAJE_IVAN_ALBC: TcxDBSpinEdit
                    Left = 238
                    Top = 78
                    DataBinding.DataField = 'PORCENTAJE_IVAN_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 21
                    Width = 55
                  end
                  object curTotalesTOTAL_IVAN_ALBC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 78
                    DataBinding.DataField = 'TOTAL_IVAN_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 13
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_REN_ALBC: TcxDBSpinEdit
                    Left = 388
                    Top = 78
                    DataBinding.DataField = 'PORCENTAJE_REN_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 25
                    Width = 53
                  end
                  object curTotalesTOTAL_REN_ALBC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 78
                    DataBinding.DataField = 'TOTAL_REN_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 17
                    Width = 75
                  end
                  object lblTotalesIVAR: TcxLabel
                    Left = 73
                    Top = 133
                    Caption = 'Reducido'
                    TabOrder = 6
                    Transparent = True
                  end
                  object curTotalesTOTAL_BASEI_IVAR_ALBC: TcxDBCurrencyEdit
                    Left = 132
                    Top = 132
                    DataBinding.DataField = 'TOTAL_BASEI_IVAR_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 10
                    Width = 105
                  end
                  object spnTotalesPORCENTAJE_IVAR_ALBC: TcxDBSpinEdit
                    Left = 238
                    Top = 132
                    DataBinding.DataField = 'PORCENTAJE_IVAR_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 22
                    Width = 55
                  end
                  object curTotalesTOTAL_IVAR_ALBC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 132
                    DataBinding.DataField = 'TOTAL_IVAR_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 14
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_RER_ALBC: TcxDBSpinEdit
                    Left = 388
                    Top = 132
                    DataBinding.DataField = 'PORCENTAJE_RER_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 26
                    Width = 53
                  end
                  object curTotalesTOTAL_RER_ALBC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 132
                    DataBinding.DataField = 'TOTAL_RER_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 18
                    Width = 75
                  end
                  object lblTotalesIVAS: TcxLabel
                    Left = 21
                    Top = 181
                    Caption = 'S'#250'per Reducido'
                    TabOrder = 7
                    Transparent = True
                  end
                  object curTotalesTOTAL_BASEI_IVAS_ALBC: TcxDBCurrencyEdit
                    Left = 132
                    Top = 180
                    DataBinding.DataField = 'TOTAL_BASEI_IVAS_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 11
                    Width = 105
                  end
                  object spnTotalesPORCENTAJE_IVAS_ALBC: TcxDBSpinEdit
                    Left = 238
                    Top = 180
                    DataBinding.DataField = 'PORCENTAJE_IVAS_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 23
                    Width = 55
                  end
                  object curTotalesTOTAL_IVAS_ALBC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 180
                    DataBinding.DataField = 'TOTAL_IVAS_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 15
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_RES_ALBC: TcxDBSpinEdit
                    Left = 388
                    Top = 180
                    DataBinding.DataField = 'PORCENTAJE_RES_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 27
                    Width = 53
                  end
                  object curTotalesTOTAL_RES_ALBC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 180
                    DataBinding.DataField = 'TOTAL_RES_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 19
                    Width = 75
                  end
                  object lblTotalesIVAE: TcxLabel
                    Left = 94
                    Top = 229
                    Caption = 'Exento'
                    TabOrder = 8
                    Transparent = True
                  end
                  object curTotalesTOTAL_BASEI_IVAE_ALBC: TcxDBCurrencyEdit
                    Left = 132
                    Top = 228
                    DataBinding.DataField = 'TOTAL_BASEI_IVAE_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 12
                    Width = 105
                  end
                  object spnTotalesPORCENTAJE_IVAE_ALBC: TcxDBSpinEdit
                    Left = 238
                    Top = 228
                    DataBinding.DataField = 'PORCENTAJE_IVAE_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 24
                    Width = 55
                  end
                  object curTotalesTOTAL_IVAE_ALBC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 228
                    DataBinding.DataField = 'TOTAL_IVAE_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 16
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_REE_ALBC: TcxDBSpinEdit
                    Left = 388
                    Top = 228
                    DataBinding.DataField = 'PORCENTAJE_REE_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.AssignedValues.MinValue = True
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 28
                    Width = 53
                  end
                  object curTotalesTOTAL_REE_ALBC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 228
                    DataBinding.DataField = 'TOTAL_REE_ALBC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 20
                    Width = 75
                  end
                end
              end
            end
            object tsObservaciones: TcxTabSheet
              Caption = '&4_Observaciones'
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_ALBC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 339
                Width = 929
              end
            end
          end
        end
        object pnlBottomTotales: TPanel
          Left = 0
          Top = 617
          Width = 937
          Height = 76
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 3
          object lblTotalBases: TcxLabel
            Left = 16
            Top = 8
            Caption = 'Total bases'
            TabOrder = 0
            Transparent = True
          end
          object curTOTAL_BASES_ALBC: TcxDBCurrencyEdit
            Left = 16
            Top = 32
            DataBinding.DataField = 'TOTAL_BASES_ALBC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 140
          end
          object lblTotalImpuestos: TcxLabel
            Left = 176
            Top = 8
            Caption = 'Total impuestos'
            TabOrder = 2
            Transparent = True
          end
          object curTOTAL_IMPUESTOS_ALBC: TcxDBCurrencyEdit
            Left = 176
            Top = 32
            DataBinding.DataField = 'TOTAL_IMPUESTOS_ALBC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 3
            Width = 140
          end
          object lblTotalLiquido: TcxLabel
            Left = 336
            Top = 8
            Caption = 'Total l'#237'quido'
            TabOrder = 4
            Transparent = True
          end
          object curTOTAL_LIQUIDO_ALBC: TcxDBCurrencyEdit
            Left = 336
            Top = 32
            DataBinding.DataField = 'TOTAL_LIQUIDO_ALBC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 5
            Width = 160
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 937
        ExplicitHeight = 693
        inherited pnlPerfilTop: TPanel
          Width = 937
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 937
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 937
          Height = 636
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 937
          ExplicitHeight = 636
          inherited cxgrdPerfil: TcxGrid
            Width = 937
            Height = 636
            ExplicitWidth = 937
            ExplicitHeight = 636
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 945
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 945
      inherited pnlTopGrid: TPanel
        Width = 945
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 945
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 945
    Height = 765
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 945
    ExplicitHeight = 765
    inherited pButtonGen: TPanel
      Top = 567
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 567
    end
    inherited pButtonBDStat: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnStateDataSet: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited pnlDataSetName: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
    object btnImprimirH: TcxButton
      Left = 0
      Top = 307
      Width = 137
      Height = 48
      Caption = 'Imprimir hor.'
      TabOrder = 2
      OnClick = btnImprimirHClick
    end
    object btnImprimirV: TcxButton
      Left = 0
      Top = 254
      Width = 137
      Height = 46
      Caption = 'Imprimir vert.'
      TabOrder = 3
      OnClick = btnImprimirVClick
    end
    object btnPegatinas: TcxButton
      Left = 0
      Top = 204
      Width = 137
      Height = 43
      Caption = 'Etiquetas'
      TabOrder = 4
      OnClick = btnPegatinasClick
    end
  end
  inherited pmFiltros: TPopupMenu
    Left = 552
  end
  object ActionList1: TActionList
    Left = 656
    Top = 440
    object actArticulos: TAction
      Caption = 'actArticulos'
      ShortCut = 16449
      OnExecute = actArticulosExecute
    end
    object actIrDocumento: TAction
      Caption = 'Ir a documento (Ctrl+May+A)'
      ShortCut = 24641
      OnExecute = actIrDocumentoExecute
    end
    object actIrFacturaCreada: TAction
      Caption = 'Ir a factura creada'
      OnExecute = actIrFacturaCreadaExecute
    end
    object actIrProveedor: TAction
      Caption = 'Ir a proveedor'
      ShortCut = 16464
      OnExecute = actIrProveedorExecute
    end
  end
end
