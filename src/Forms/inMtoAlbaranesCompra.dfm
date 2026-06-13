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
            object dbcGrdAlbcNUMERO_ALBC: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_ALBC'
              Width = 90
            end
            object dbcGrdAlbcSERIE_ALBC: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_ALBC'
              Width = 80
            end
            object dbcGrdAlbcFECHA_ALBC: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_ALBC'
              Width = 100
            end
            object dbcGrdAlbcESTADO_ALBC: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_ALBC'
              Width = 110
            end
            object dbcGrdAlbcCODIGO_EMP_ALBC: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_ALBC'
              Width = 100
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
            object dbcGrdAlbcREF_PROVEEDOR_ALBC: TcxGridDBColumn
              Caption = 'Ref. proveedor'
              DataBinding.FieldName = 'REF_PROVEEDOR_ALBC'
              Width = 130
            end
            object dbcGrdAlbcCODIGO_ALM_ALBC: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_ALBC'
              Width = 100
            end
            object dbcGrdAlbcTOTAL_LIQUIDO_ALBC: TcxGridDBColumn
              Caption = 'Total l'#237'quido'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_ALBC'
              Width = 120
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
                Properties.DropDownListStyle = lsEditList
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
              object lblEstadoAlbaran: TcxLabel
                Left = 320
                Top = 12
                Caption = 'Estado'
                TabOrder = 6
                Transparent = True
              end
              object txtESTADO_ALBC: TcxDBTextEdit
                Left = 320
                Top = 32
                DataBinding.DataField = 'ESTADO_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 7
                Width = 110
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 8
                Top = 72
                Caption = 'Empresa'
                TabOrder = 8
                Transparent = True
              end
              object btnCODIGO_EMP_ALBC: TcxDBButtonEdit
                Left = 8
                Top = 92
                DataBinding.DataField = 'CODIGO_EMP_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 9
                Width = 150
              end
              object lblCodigoProveedor: TcxLabel
                Left = 168
                Top = 72
                Caption = 'Proveedor'
                TabOrder = 10
                Transparent = True
              end
              object btnCODIGO_PRV_ALBC: TcxDBButtonEdit
                Left = 168
                Top = 92
                DataBinding.DataField = 'CODIGO_PRV_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 11
                Width = 150
              end
              object lblRefProveedor: TcxLabel
                Left = 328
                Top = 72
                Caption = 'Ref. proveedor'
                TabOrder = 12
                Transparent = True
              end
              object txtREF_PROVEEDOR_ALBC: TcxDBTextEdit
                Left = 328
                Top = 92
                DataBinding.DataField = 'REF_PROVEEDOR_ALBC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 13
                Width = 180
              end
              object lblCodigoAlmacen: TcxLabel
                Left = 520
                Top = 72
                Caption = 'Almac'#233'n destino'
                TabOrder = 14
                Transparent = True
              end
              object txtCODIGO_ALM_ALBC: TcxDBTextEdit
                Left = 520
                Top = 92
                DataBinding.DataField = 'CODIGO_ALM_ALBC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 15
                Width = 120
              end
              object chkESDEPOSITO_ALBC: TcxDBCheckBox
                Left = 656
                Top = 92
                Caption = 'Dep'#243'sito'
                DataBinding.DataField = 'ESDEPOSITO_ALBC'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 16
                Width = 100
              end
            end
          end
        end
        object pnlBotonesAcciones: TPanel
          Left = 0
          Top = 200
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
          object btnIrDocumento: TcxButton
            Left = 620
            Top = 6
            Width = 200
            Height = 26
            Action = actIrDocumento
            TabOrder = 4
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 238
          Width = 937
          Height = 379
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcAlbaran: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 379
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasAlbaran
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 375
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsLineasAlbaran: TcxTabSheet
              Caption = 'L'#237'neas'
              object cxgrdLineasAlbaran: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 347
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
                    Width = 100
                  end
                  object colLineaAlbcCODIGO_UNIDAD: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_ALBCLIN'
                    Width = 120
                  end
                  object colLineaAlbcREF_PRV: TcxGridDBColumn
                    Caption = 'Ref. prov.'
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
            object tsObservaciones: TcxTabSheet
              Caption = 'Observaciones'
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_ALBC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 347
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
  object ActionList1: TActionList
    Left = 528
    Top = 368
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
  end
end
