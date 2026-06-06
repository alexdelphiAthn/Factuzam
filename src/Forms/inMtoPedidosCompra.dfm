inherited frmMtoPedidosCompra: TfrmMtoPedidosCompra
  Caption = 'Mantenimiento de Pedidos de Compra'
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
            object dbcGrdPedcNUMERO_PEDC: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_PEDC'
              Width = 90
            end
            object dbcGrdPedcSERIE_PEDC: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_PEDC'
              Width = 80
            end
            object dbcGrdPedcFECHA_PEDC: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_PEDC'
              Width = 100
            end
            object dbcGrdPedcFECHA_PREVISTA_PEDC: TcxGridDBColumn
              Caption = 'F.prevista'
              DataBinding.FieldName = 'FECHA_PREVISTA_PEDC'
              Width = 100
            end
            object dbcGrdPedcESTADO_PEDC: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_PEDC'
              Width = 110
            end
            object dbcGrdPedcCODIGO_EMP_PEDC: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_PEDC'
              Width = 100
            end
            object dbcGrdPedcCODIGO_PRV_PEDC: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_PEDC'
              Width = 100
            end
            object dbcGrdPedcRSPRV_PEDC: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Proveedor'
              DataBinding.FieldName = 'RAZON_SOCIAL_PRV_PEDC'
              Width = 220
            end
            object dbcGrdPedcREF_PROVEEDOR_PEDC: TcxGridDBColumn
              Caption = 'Ref. proveedor'
              DataBinding.FieldName = 'REF_PROVEEDOR_PEDC'
              Width = 130
            end
            object dbcGrdPedcCODIGO_ALM_PEDC: TcxGridDBColumn
              Caption = 'Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALM_PEDC'
              Width = 100
            end
            object dbcGrdPedcTOTAL_LIQUIDO_PEDC: TcxGridDBColumn
              Caption = 'Total l'#237'quido'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_PEDC'
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
          Height = 161
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pcCab: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 161
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsCabecera
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 157
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsCabecera: TcxTabSheet
              Caption = 'Cabecera'
              object lblNroPedido: TcxLabel
                Left = 8
                Top = 12
                Caption = 'N'#250'mero'
                TabOrder = 0
                Transparent = True
              end
              object txtNUMERO_PEDC: TcxDBTextEdit
                Left = 8
                Top = 32
                DataBinding.DataField = 'NUMERO_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 1
                Width = 100
              end
              object lblSeriePedido: TcxLabel
                Left = 116
                Top = 12
                Caption = 'Serie'
                TabOrder = 2
                Transparent = True
              end
              object txtSERIE_PEDC: TcxDBTextEdit
                Left = 116
                Top = 32
                DataBinding.DataField = 'SERIE_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 3
                Width = 80
              end
              object lblFechaPedido: TcxLabel
                Left = 204
                Top = 12
                Caption = 'Fecha'
                TabOrder = 4
                Transparent = True
              end
              object dteFECHA_PEDC: TcxDBDateEdit
                Left = 204
                Top = 32
                DataBinding.DataField = 'FECHA_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 5
                Width = 110
              end
              object lblFechaPrevista: TcxLabel
                Left = 320
                Top = 12
                Caption = 'F.prevista'
                TabOrder = 6
                Transparent = True
              end
              object dteFECHA_PREVISTA_PEDC: TcxDBDateEdit
                Left = 320
                Top = 32
                DataBinding.DataField = 'FECHA_PREVISTA_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 7
                Width = 110
              end
              object lblEstadoPedido: TcxLabel
                Left = 436
                Top = 12
                Caption = 'Estado'
                TabOrder = 8
                Transparent = True
              end
              object txtESTADO_PEDC: TcxDBTextEdit
                Left = 436
                Top = 32
                DataBinding.DataField = 'ESTADO_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 9
                Width = 110
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 8
                Top = 72
                Caption = 'Empresa'
                TabOrder = 10
                Transparent = True
              end
              object btnCODIGO_EMP_PEDC: TcxDBButtonEdit
                Left = 8
                Top = 92
                DataBinding.DataField = 'CODIGO_EMP_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 11
                Width = 150
              end
              object lblCodigoProveedor: TcxLabel
                Left = 168
                Top = 72
                Caption = 'Proveedor'
                TabOrder = 12
                Transparent = True
              end
              object btnCODIGO_PRV_PEDC: TcxDBButtonEdit
                Left = 168
                Top = 92
                DataBinding.DataField = 'CODIGO_PRV_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 13
                Width = 150
              end
              object lblRefProveedor: TcxLabel
                Left = 328
                Top = 72
                Caption = 'Ref. proveedor'
                TabOrder = 14
                Transparent = True
              end
              object txtREF_PROVEEDOR_PEDC: TcxDBTextEdit
                Left = 328
                Top = 92
                DataBinding.DataField = 'REF_PROVEEDOR_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 15
                Width = 180
              end
              object lblCodigoAlmacen: TcxLabel
                Left = 520
                Top = 72
                Caption = 'Almac'#233'n destino'
                TabOrder = 16
                Transparent = True
              end
              object txtCODIGO_ALM_PEDC: TcxDBTextEdit
                Left = 520
                Top = 92
                DataBinding.DataField = 'CODIGO_ALM_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 17
                Width = 120
              end
              object lblTemporada: TcxLabel
                Left = 656
                Top = 72
                Caption = 'Temporada'
                TabOrder = 18
                Transparent = True
              end
              object cbbTemporadaPedc: TcxDBLookupComboBox
                Left = 656
                Top = 92
                DataBinding.DataField = 'ID_PV_TEMPORADA_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'ID_PV_ARTPROP'
                Properties.ListColumns = <
                  item
                    Caption = 'Temporada'
                    FieldName = 'PV'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 19
                Width = 180
              end
            end
          end
        end
        object pnlBotonesAcciones: TPanel
          Left = 0
          Top = 161
          Width = 937
          Height = 40
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object btnRecibirFilaEntera: TcxButton
            Left = 582
            Top = 6
            Width = 180
            Height = 26
            Caption = 'Recibir fila entera'
            TabOrder = 3
            OnClick = btnRecibirFilaEnteraClick
          end
          object btnTallasHorizontal: TcxButton
            Left = 12
            Top = 8
            Width = 170
            Height = 26
            Caption = 'Tallas en horizontal'
            TabOrder = 0
            OnClick = btnTallasHorizontalClick
          end
          object btnAtributosColumna: TcxButton
            Left = 200
            Top = 8
            Width = 170
            Height = 26
            Caption = 'Atributo por columna'
            TabOrder = 1
            OnClick = btnAtributosColumnaClick
          end
          object btnExpandirRecibidos: TcxButton
            Left = 768
            Top = 6
            Width = 160
            Height = 26
            Caption = 'Expandir recibidos'
            TabOrder = 2
            OnClick = btnExpandirRecibidosClick
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 201
          Width = 937
          Height = 416
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          ExplicitTop = 202
          ExplicitHeight = 415
          object pcPedido: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 416
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasPedido
            Properties.CustomButtons.Buttons = <>
            ExplicitHeight = 415
            ClientRectBottom = 412
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsLineasPedido: TcxTabSheet
              Caption = 'L'#237'neas'
              ExplicitHeight = 383
              object cxgrdLineasPedido: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 384
                Align = alClient
                TabOrder = 0
                OnEnter = cxgrdLineasPedidoEnter
                OnExit = cxgrdLineasPedidoExit
                ExplicitHeight = 383
                object tvLineasPedido: TcxGridDBTableView
                  OnCustomDrawCell = tvLineasPedidoCustomDrawCell
                  OnEditing = tvLineasPedidoEditing
                  OnFocusedRecordChanged = tvLineasPedidoFocusedRecordChanged
                  OnInitEdit = tvLineasPedidoInitEdit
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.FocusFirstCellOnNewRecord = True
                  OptionsData.Appending = True
                  OptionsView.GroupByBox = False
                  object colLineaPedcLINEA: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_PEDCLIN'
                    Width = 60
                  end
                  object colLineaPedcCODIGO_ART: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_PEDCLIN'
                    Width = 100
                  end
                  object colLineaPedcCODIGO_UNIDAD: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_PEDCLIN'
                    Width = 120
                  end
                  object colLineaPedcREF_PRV: TcxGridDBColumn
                    Caption = 'Ref. prov.'
                    DataBinding.FieldName = 'REF_PRV_PEDCLIN'
                    Width = 100
                  end
                  object colLineaPedcDESCRIPCION: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_PEDCLIN'
                    Width = 220
                  end
                  object colLineaPedcCANTIDAD: TcxGridDBColumn
                    Caption = 'Pedida'
                    DataBinding.FieldName = 'CANTIDAD_PEDCLIN'
                    Width = 80
                  end
                  object colLineaPedcTipoCant: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_PEDCLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object colLineaPedcRECIBIDA: TcxGridDBColumn
                    Caption = 'Recibida'
                    DataBinding.FieldName = 'CANTIDAD_RECIBIDA_PEDCLIN'
                    Options.Editing = False
                    Width = 80
                  end
                  object colLineaPedcARecibir: TcxGridDBColumn
                    Caption = 'A recibir'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = '#,##0.###'
                    Width = 90
                  end
                  object colLineaPedcPRECIO_COMPRA: TcxGridDBColumn
                    Caption = 'Precio compra'
                    DataBinding.FieldName = 'PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN'
                    Width = 110
                  end
                  object colLineaPedcPORCENTAJE_IVA: TcxGridDBColumn
                    Caption = '% IVA'
                    DataBinding.FieldName = 'PORCENTAJE_IVA_PEDCLIN'
                    Width = 70
                  end
                  object colLineaPedcTOTAL: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_PEDCLIN'
                    Width = 100
                  end
                  object colLineaPedcALMACEN: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'CODIGO_ALMACEN_PEDCLIN'
                    Width = 90
                  end
                end
                object cxgrdlvlLineasPedido: TcxGridLevel
                  GridView = tvLineasPedido
                end
              end
            end
            object tsObservaciones: TcxTabSheet
              Caption = 'Observaciones'
              ExplicitHeight = 383
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                ExplicitHeight = 383
                Height = 384
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
          object curTOTAL_BASES_PEDC: TcxDBCurrencyEdit
            Left = 16
            Top = 32
            DataBinding.DataField = 'TOTAL_BASES_PEDC'
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
          object curTOTAL_IMPUESTOS_PEDC: TcxDBCurrencyEdit
            Left = 176
            Top = 32
            DataBinding.DataField = 'TOTAL_IMPUESTOS_PEDC'
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
          object curTOTAL_LIQUIDO_PEDC: TcxDBCurrencyEdit
            Left = 336
            Top = 32
            DataBinding.DataField = 'TOTAL_LIQUIDO_PEDC'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 5
            Width = 160
          end
          object lblContextoTalla: TcxLabel
            Left = 560
            Top = 8
            TabOrder = 6
            Transparent = True
            Visible = False
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
    object btnCrearAlbaran: TcxButton
      Left = 7
      Top = 290
      Width = 121
      Height = 26
      Caption = 'Crear albar'#225'n'
      TabOrder = 2
      OnClick = btnCrearAlbaranClick
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
