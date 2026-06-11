inherited frmMtoFacturasCompra: TfrmMtoFacturasCompra
  Caption = 'Mantenimiento de Facturas de Compra'
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
            object dbcGrdFaccNUMERO_FACC: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_FACC'
              Width = 90
            end
            object dbcGrdFaccSERIE_FACC: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_FACC'
              Width = 80
            end
            object dbcGrdFaccFECHA_FACC: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_FACC'
              Width = 100
            end
            object dbcGrdFaccESTADO_FACC: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_FACC'
              Width = 110
            end
            object dbcGrdFaccCODIGO_EMP_FACC: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_FACC'
              Width = 100
            end
            object dbcGrdFaccCODIGO_PRV_FACC: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_FACC'
              Width = 100
            end
            object dbcGrdFaccRSPRV_FACC: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Proveedor'
              DataBinding.FieldName = 'RAZON_SOCIAL_PRV_FACC'
              Width = 220
            end
            object dbcGrdFaccREF_PROVEEDOR_FACC: TcxGridDBColumn
              Caption = 'Ref. proveedor'
              DataBinding.FieldName = 'REF_PROVEEDOR_FACC'
              Width = 130
            end
            object dbcGrdFaccCODIGO_ALM_FACC: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_FACC'
              Width = 100
            end
            object dbcGrdFaccTOTAL_LIQUIDO_FACC: TcxGridDBColumn
              Caption = 'Total l'#237'quido'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_FACC'
              Width = 120
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
              object lblNroFactura: TcxLabel
                Left = 8
                Top = 12
                Caption = 'N'#250'mero'
                TabOrder = 0
                Transparent = True
              end
              object txtNUMERO_FACC: TcxDBTextEdit
                Left = 8
                Top = 32
                DataBinding.DataField = 'NUMERO_FACC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 1
                Width = 100
              end
              object lblSerieFactura: TcxLabel
                Left = 116
                Top = 12
                Caption = 'Serie'
                TabOrder = 2
                Transparent = True
              end
              object txtSERIE_FACC: TcxDBTextEdit
                Left = 116
                Top = 32
                DataBinding.DataField = 'SERIE_FACC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 3
                Width = 80
              end
              object lblFechaFactura: TcxLabel
                Left = 204
                Top = 12
                Caption = 'Fecha'
                TabOrder = 4
                Transparent = True
              end
              object dteFECHA_FACC: TcxDBDateEdit
                Left = 204
                Top = 32
                DataBinding.DataField = 'FECHA_FACC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 5
                Width = 110
              end
              object lblEstadoFactura: TcxLabel
                Left = 320
                Top = 12
                Caption = 'Estado'
                TabOrder = 6
                Transparent = True
              end
              object txtESTADO_FACC: TcxDBTextEdit
                Left = 320
                Top = 32
                DataBinding.DataField = 'ESTADO_FACC'
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
              object btnCODIGO_EMP_FACC: TcxDBButtonEdit
                Left = 8
                Top = 92
                DataBinding.DataField = 'CODIGO_EMP_FACC'
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
              object btnCODIGO_PRV_FACC: TcxDBButtonEdit
                Left = 168
                Top = 92
                DataBinding.DataField = 'CODIGO_PRV_FACC'
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
              object txtREF_PROVEEDOR_FACC: TcxDBTextEdit
                Left = 328
                Top = 92
                DataBinding.DataField = 'REF_PROVEEDOR_FACC'
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
              object txtCODIGO_ALM_FACC: TcxDBTextEdit
                Left = 520
                Top = 92
                DataBinding.DataField = 'CODIGO_ALM_FACC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 15
                Width = 120
              end
              object lblFormaPago: TcxLabel
                Left = 680
                Top = 72
                Caption = 'Forma de pago'
                TabOrder = 16
                Transparent = True
              end
              object btnFORMA_PAGO_FACC: TcxDBButtonEdit
                Left = 680
                Top = 92
                DataBinding.DataField = 'FORMA_PAGO_FACC'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                Properties.OnButtonClick = btnFORMA_PAGO_FACCPropertiesButtonClick
                TabOrder = 17
                Width = 240
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
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 238
          Width = 937
          Height = 379
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcFactura: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 379
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasFactura
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 375
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsLineasFactura: TcxTabSheet
              Caption = 'L'#237'neas'
              object cxgrdLineasFactura: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 347
                Align = alClient
                TabOrder = 0
                OnEnter = cxgrdLineasFacturaEnter
                OnExit = cxgrdLineasFacturaExit
                object tvLineasFactura: TcxGridDBTableView
                  OnCustomDrawCell = tvLineasFacturaCustomDrawCell
                  OnEditing = tvLineasFacturaEditing
                  OnFocusedRecordChanged = tvLineasFacturaFocusedRecordChanged
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.FocusFirstCellOnNewRecord = True
                  OptionsData.Appending = True
                  OptionsView.GroupByBox = False
                  object colLineaFaccLINEA: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_FACCLIN'
                    Width = 60
                  end
                  object colLineaFaccCODIGO_ART: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_FACCLIN'
                    Width = 100
                  end
                  object colLineaFaccCODIGO_UNIDAD: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_FACCLIN'
                    Width = 120
                  end
                  object colLineaFaccREF_PRV: TcxGridDBColumn
                    Caption = 'Ref. prov.'
                    DataBinding.FieldName = 'REF_PRV_FACCLIN'
                    Width = 100
                  end
                  object colLineaFaccDESCRIPCION: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACCLIN'
                    Width = 240
                  end
                  object colLineaFaccCANTIDAD: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACCLIN'
                    Width = 80
                  end
                  object colLineaFaccPRECIO_COMPRA: TcxGridDBColumn
                    Caption = 'Precio compra'
                    DataBinding.FieldName = 'PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = ',0.00 '#8364';-,0.00 '#8364
                    Width = 110
                  end
                  object colLineaFaccPORCENTAJE_IVA: TcxGridDBColumn
                    Caption = '% IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_FACCLIN'
                    Width = 70
                  end
                  object colLineaFaccTOTAL: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_FACCLIN'
                    Width = 100
                  end
                  object colLineaFaccALMACEN: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'CODIGO_ALMACEN_FACCLIN'
                    Width = 90
                  end
                end
                object cxgrdlvlLineasFactura: TcxGridLevel
                  GridView = tvLineasFactura
                end
              end
            end
            object tsObservaciones: TcxTabSheet
              Caption = 'Observaciones'
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_FACC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 347
                Width = 929
              end
            end
            object tsEfectos: TcxTabSheet
              Caption = 'Efectos'
              object pnlEfectosTop: TPanel
                Left = 0
                Top = 0
                Width = 929
                Height = 36
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object btnGenerarEfectos: TcxButton
                  Left = 8
                  Top = 5
                  Width = 160
                  Height = 26
                  Caption = 'Generar efectos'
                  TabOrder = 0
                  OnClick = btnGenerarEfectosClick
                end
                object btnRegistrarPago: TcxButton
                  Left = 176
                  Top = 5
                  Width = 160
                  Height = 26
                  Caption = 'Registrar pago'
                  TabOrder = 1
                  OnClick = btnRegistrarPagoClick
                end
                object btnVerPagos: TcxButton
                  Left = 344
                  Top = 5
                  Width = 160
                  Height = 26
                  Caption = 'Ver pagos'
                  TabOrder = 2
                  OnClick = btnVerPagosClick
                end
              end
              object cxgrdEfectos: TcxGrid
                Left = 0
                Top = 36
                Width = 929
                Height = 311
                Align = alClient
                TabOrder = 1
                object tvEfectos: TcxGridDBTableView
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object colEfeNumero: TcxGridDBColumn
                    Caption = 'Nro'
                    DataBinding.FieldName = 'NUMERO_EFEC'
                    Width = 50
                  end
                  object colEfeTipo: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'CODIGO_TEFE_EFEC'
                    Width = 110
                  end
                  object colEfeVto: TcxGridDBColumn
                    Caption = 'Vencimiento'
                    DataBinding.FieldName = 'FECHA_VENCIMIENTO_EFEC'
                    Width = 110
                  end
                  object colEfeImporte: TcxGridDBColumn
                    Caption = 'Importe'
                    DataBinding.FieldName = 'IMPORTE_EFEC'
                    Width = 100
                  end
                  object colEfePagado: TcxGridDBColumn
                    Caption = 'Pagado'
                    DataBinding.FieldName = 'IMPORTE_PAGADO_EFEC'
                    Width = 100
                  end
                  object colEfePendiente: TcxGridDBColumn
                    Caption = 'Pendiente'
                    DataBinding.FieldName = 'IMPORTE_PENDIENTE_EFEC'
                    Width = 100
                  end
                  object colEfeEstado: TcxGridDBColumn
                    Caption = 'Estado'
                    DataBinding.FieldName = 'ESTADO_EFEC'
                    Width = 100
                  end
                end
                object lvlEfectos: TcxGridLevel
                  GridView = tvEfectos
                end
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
          object curTOTAL_BASES_FACC: TcxDBCurrencyEdit
            Left = 16
            Top = 32
            DataBinding.DataField = 'TOTAL_BASES_FACC'
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
          object curTOTAL_IMPUESTOS_FACC: TcxDBCurrencyEdit
            Left = 176
            Top = 32
            DataBinding.DataField = 'TOTAL_IMPUESTOS_FACC'
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
          object curTOTAL_LIQUIDO_FACC: TcxDBCurrencyEdit
            Left = 336
            Top = 32
            DataBinding.DataField = 'TOTAL_LIQUIDO_FACC'
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
  end
end
