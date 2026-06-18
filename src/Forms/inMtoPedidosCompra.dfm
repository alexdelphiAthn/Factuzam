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
              object cbbSERIE_PEDC: TcxDBComboBox
                Left = 116
                Top = 32
                DataBinding.DataField = 'SERIE_PEDC'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 12
                Properties.OnInitPopup = cbbSERIE_PEDCPropertiesInitPopup
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
            Left = 248
            Top = 8
            Width = 162
            Height = 26
            Caption = 'Recibir fila entera'
            TabOrder = 2
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
          object btnExpandirRecibidos: TcxButton
            Left = 552
            Top = 8
            Width = 160
            Height = 26
            Caption = 'Expandir recibidos'
            TabOrder = 1
            OnClick = btnExpandirRecibidosClick
          end
          object btnRecibirTodo: TcxButton
            Left = 416
            Top = 8
            Width = 130
            Height = 26
            Caption = 'Recibir Todo'
            TabOrder = 3
            OnClick = btnRecibirTodoClick
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
          object pcPedido: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 416
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasPedido
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 412
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 28
            object tsLineasPedido: TcxTabSheet
              Caption = 'L'#237'neas'
              object cxgrdLineasPedido: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 384
                Align = alClient
                TabOrder = 0
                OnEnter = cxgrdLineasPedidoEnter
                OnExit = cxgrdLineasPedidoExit
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
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.DisplayFormat = ',0.00 '#8364';-,0.00 '#8364
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
            object tsTotales: TcxTabSheet
              Caption = '&2_Totales'
              ImageIndex = 2
              object scrTotales: TScrollBox
                Left = 0
                Top = 0
                Width = 929
                Height = 384
                Align = alClient
                BorderStyle = bsNone
                ParentBackground = True
                TabOrder = 0
                object lblTotalesTotalBase: TcxLabel
                  Left = 38
                  Top = 39
                  Caption = 'Total Base Imponible'
                  TabOrder = 0
                  Transparent = True
                end
                object curTotalesTOTAL_BASES_PEDC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 35
                  DataBinding.DataField = 'TOTAL_BASES_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DecimalPlaces = 2
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Width = 133
                end
                object lblTotalesTotalImpuestos: TcxLabel
                  Left = 79
                  Top = 77
                  Caption = 'Total Impuestos'
                  TabOrder = 2
                  Transparent = True
                end
                object curTotalesTOTAL_IMPUESTOS_PEDC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 73
                  DataBinding.DataField = 'TOTAL_IMPUESTOS_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.DecimalPlaces = 2
                  Properties.DisplayFormat = ',0.00 '#8364';-,0.00 '#8364
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 133
                end
                object lblTotalesPorcRetencion: TcxLabel
                  Left = 80
                  Top = 118
                  Caption = '% Retenci'#243'n'
                  TabOrder = 4
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_RETENCION_PEDC: TcxDBSpinEdit
                  Left = 230
                  Top = 114
                  DataBinding.DataField = 'PORCENTAJE_RETENCION_PEDC'
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
                  Top = 158
                  Caption = 'Total Retenci'#243'n'
                  TabOrder = 6
                  Transparent = True
                end
                object curTotalesTOTAL_RETENCION_PEDC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 154
                  DataBinding.DataField = 'TOTAL_RETENCION_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 133
                end
                object lblTotalesTotalPagar: TcxLabel
                  Left = 105
                  Top = 199
                  Caption = 'Total a pagar'
                  TabOrder = 8
                  Transparent = True
                end
                object curTotalesTOTAL_LIQUIDO_PEDC: TcxDBCurrencyEdit
                  Left = 230
                  Top = 195
                  DataBinding.DataField = 'TOTAL_LIQUIDO_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  Properties.UseThousandSeparator = True
                  TabOrder = 9
                  Width = 133
                end
                object lblTotalesFormaPago: TcxLabel
                  Left = 90
                  Top = 238
                  Caption = 'Forma de Pago'
                  TabOrder = 10
                  Transparent = True
                end
                object txtTotalesFORMA_PAGO_PEDC: TcxDBTextEdit
                  Left = 230
                  Top = 234
                  DataBinding.DataField = 'FORMA_PAGO_PEDC'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 11
                  Width = 133
                end
                object chkTotalesESIVA_RECARGO_COMPRAS_PEDC: TcxDBCheckBox
                  Left = 56
                  Top = 279
                  Caption = 'Recargo equivalencia compras'
                  DataBinding.DataField = 'ESIVA_RECARGO_COMPRAS_PEDC'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 12
                  Transparent = True
                end
                object grpDesgloseImpuestos: TGroupBox
                  Left = 384
                  Top = 11
                  Width = 525
                  Height = 318
                  Caption = 'Desglose Impuestos'
                  TabOrder = 13
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
                  object curTotalesTOTAL_BASEI_IVAN_PEDC: TcxDBCurrencyEdit
                    Left = 132
                    Top = 78
                    DataBinding.DataField = 'TOTAL_BASEI_IVAN_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 9
                    Width = 105
                  end
                  object spnTotalesPORCENTAJE_IVAN_PEDC: TcxDBSpinEdit
                    Left = 238
                    Top = 78
                    DataBinding.DataField = 'PORCENTAJE_IVAN_PEDC'
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
                  object curTotalesTOTAL_IVAN_PEDC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 78
                    DataBinding.DataField = 'TOTAL_IVAN_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 13
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_REN_PEDC: TcxDBSpinEdit
                    Left = 388
                    Top = 78
                    DataBinding.DataField = 'PORCENTAJE_REN_PEDC'
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
                  object curTotalesTOTAL_REN_PEDC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 78
                    DataBinding.DataField = 'TOTAL_REN_PEDC'
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
                  object curTotalesTOTAL_BASEI_IVAR_PEDC: TcxDBCurrencyEdit
                    Left = 132
                    Top = 132
                    DataBinding.DataField = 'TOTAL_BASEI_IVAR_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 10
                    Width = 105
                  end
                  object spnTotalesPORCENTAJE_IVAR_PEDC: TcxDBSpinEdit
                    Left = 238
                    Top = 132
                    DataBinding.DataField = 'PORCENTAJE_IVAR_PEDC'
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
                  object curTotalesTOTAL_IVAR_PEDC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 132
                    DataBinding.DataField = 'TOTAL_IVAR_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 14
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_RER_PEDC: TcxDBSpinEdit
                    Left = 388
                    Top = 132
                    DataBinding.DataField = 'PORCENTAJE_RER_PEDC'
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
                  object curTotalesTOTAL_RER_PEDC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 132
                    DataBinding.DataField = 'TOTAL_RER_PEDC'
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
                  object curTotalesTOTAL_BASEI_IVAS_PEDC: TcxDBCurrencyEdit
                    Left = 132
                    Top = 180
                    DataBinding.DataField = 'TOTAL_BASEI_IVAS_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 11
                    Width = 105
                  end
                  object spnTotalesPORCENTAJE_IVAS_PEDC: TcxDBSpinEdit
                    Left = 238
                    Top = 180
                    DataBinding.DataField = 'PORCENTAJE_IVAS_PEDC'
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
                  object curTotalesTOTAL_IVAS_PEDC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 180
                    DataBinding.DataField = 'TOTAL_IVAS_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 15
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_RES_PEDC: TcxDBSpinEdit
                    Left = 388
                    Top = 180
                    DataBinding.DataField = 'PORCENTAJE_RES_PEDC'
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
                  object curTotalesTOTAL_RES_PEDC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 180
                    DataBinding.DataField = 'TOTAL_RES_PEDC'
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
                  object curTotalesTOTAL_BASEI_IVAE_PEDC: TcxDBCurrencyEdit
                    Left = 132
                    Top = 228
                    DataBinding.DataField = 'TOTAL_BASEI_IVAE_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 12
                    Width = 105
                  end
                  object spnTotalesPORCENTAJE_IVAE_PEDC: TcxDBSpinEdit
                    Left = 238
                    Top = 228
                    DataBinding.DataField = 'PORCENTAJE_IVAE_PEDC'
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
                  object curTotalesTOTAL_IVAE_PEDC: TcxDBCurrencyEdit
                    Left = 296
                    Top = 228
                    DataBinding.DataField = 'TOTAL_IVAE_PEDC'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 16
                    Width = 86
                  end
                  object spnTotalesPORCENTAJE_REE_PEDC: TcxDBSpinEdit
                    Left = 388
                    Top = 228
                    DataBinding.DataField = 'PORCENTAJE_REE_PEDC'
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
                  object curTotalesTOTAL_REE_PEDC: TcxDBCurrencyEdit
                    Left = 442
                    Top = 228
                    DataBinding.DataField = 'TOTAL_REE_PEDC'
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
              Caption = 'Observaciones'
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_PEDC'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 384
                Width = 929
              end
            end
            object tsAlbaranesPedc: TcxTabSheet
              Caption = 'Albaranes'
              object cxgrdAlbaranesPedc: TcxGrid
                Left = 0
                Top = 0
                Width = 929
                Height = 384
                Align = alClient
                TabOrder = 0
                object tvAlbaranesPedc: TcxGridDBTableView
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object colAlbcPedcNUMERO: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO_ALBC'
                    Width = 90
                  end
                  object colAlbcPedcSERIE: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_ALBC'
                    Width = 80
                  end
                  object colAlbcPedcFECHA: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_ALBC'
                    Width = 100
                  end
                  object colAlbcPedcESTADO: TcxGridDBColumn
                    Caption = 'Estado'
                    DataBinding.FieldName = 'ESTADO_ALBC'
                    Width = 100
                  end
                  object colAlbcPedcREFPRV: TcxGridDBColumn
                    Caption = 'Ref. prov.'
                    DataBinding.FieldName = 'REF_PROVEEDOR_ALBC'
                    Width = 140
                  end
                  object colAlbcPedcTOTAL: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_LIQUIDO_ALBC'
                    Width = 110
                  end
                end
                object cxgrdlvlAlbaranesPedc: TcxGridLevel
                  GridView = tvAlbaranesPedc
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
    object actIrDocumento: TAction
      Caption = 'Ir a documento (Ctrl+May+A)'
      ShortCut = 24641
      OnExecute = actIrDocumentoExecute
    end
  end
end
