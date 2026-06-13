inherited frmMtoPedidos: TfrmMtoPedidos
  Caption = 'Mantenimiento de Pedidos'
  ClientHeight = 765
  ClientWidth = 1085
  StyleElements = [seFont, seClient, seBorder]
  ExplicitTop = -38
  ExplicitWidth = 1085
  ExplicitHeight = 765
  TextHeight = 19
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
      ClientRectBottom = 723
      ClientRectRight = 943
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 941
        ExplicitHeight = 694
        inherited cxGrdPrincipal: TcxGrid
          Width = 941
          Height = 694
          ExplicitWidth = 941
          ExplicitHeight = 694
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcGrdPedNUMERO_PED: TcxGridDBColumn
              Caption = 'Nro Pedido'
              DataBinding.FieldName = 'NUMERO_PED'
              Width = 90
            end
            object dbcGrdPedSERIE_PED: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_PED'
              Width = 70
            end
            object dbcGrdPedFECHA_PED: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_PED'
              Width = 100
            end
            object dbcGrdPedESTADO_PED: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_PED'
              Width = 110
            end
            object dbcGrdPedCODIGO_EMP_PED: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_PED'
              Width = 90
            end
            object dbcGrdPedRSEMP_PED: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Empresa'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_PED'
              Width = 220
            end
            object dbcGrdPedCODIGO_CLI_PED: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_PED'
              Width = 90
            end
            object dbcGrdPedRSCLI_PED: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Cliente'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_FISCAL_PED'
              Width = 220
            end
            object dbcGrdPedIDPS_PED: TcxGridDBColumn
              Caption = 'ID PrestaShop'
              DataBinding.FieldName = 'IDPS_PED'
              Width = 90
            end
            object dbcGrdPedREFPS_PED: TcxGridDBColumn
              Caption = 'Ref. PrestaShop'
              DataBinding.FieldName = 'REFERENCIAPS_PED'
              Width = 110
            end
            object dbcGrdPedFECHAPS_PED: TcxGridDBColumn
              Caption = 'Fecha PrestaShop'
              DataBinding.FieldName = 'FECHAPS_PED'
              Width = 130
            end
            object dbcGrdPedTOTAL_LIQUIDO_PED: TcxGridDBColumn
              Caption = 'Total'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_PED'
              Width = 110
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 941
        ExplicitHeight = 694
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 941
          Height = 230
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pcCab: TcxPageControl
            Left = 0
            Top = 0
            Width = 941
            Height = 230
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsCabecera
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 228
            ClientRectLeft = 2
            ClientRectRight = 939
            ClientRectTop = 29
            object tsCabecera: TcxTabSheet
              Caption = 'Cabecera'
              object lblNroPedido: TcxLabel
                Left = 8
                Top = 12
                Caption = 'N'#250'mero'
                TabOrder = 9
                Transparent = True
              end
              object txtNUMERO_PED: TcxDBTextEdit
                Left = 8
                Top = 32
                DataBinding.DataField = 'NUMERO_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Width = 90
              end
              object lblSerie: TcxLabel
                Left = 106
                Top = 12
                Caption = 'Serie'
                TabOrder = 10
                Transparent = True
              end
              object txtSERIE_PED: TcxDBTextEdit
                Left = 106
                Top = 32
                DataBinding.DataField = 'SERIE_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 70
              end
              object lblFecha: TcxLabel
                Left = 184
                Top = 12
                Caption = 'Fecha'
                TabOrder = 11
                Transparent = True
              end
              object dteFECHA_PED: TcxDBDateEdit
                Left = 184
                Top = 32
                DataBinding.DataField = 'FECHA_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 110
              end
              object lblFechaEntrega: TcxLabel
                Left = 302
                Top = 12
                Caption = 'Fecha entrega'
                TabOrder = 12
                Transparent = True
              end
              object dteFECHA_ENTREGA_PED: TcxDBDateEdit
                Left = 302
                Top = 32
                DataBinding.DataField = 'FECHA_ENTREGA_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 3
                Width = 110
              end
              object lblEstado: TcxLabel
                Left = 420
                Top = 12
                Caption = 'Estado'
                TabOrder = 13
                Transparent = True
              end
              object txtESTADO_PED: TcxDBTextEdit
                Left = 420
                Top = 32
                DataBinding.DataField = 'ESTADO_PED'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 4
                Width = 110
              end
              object lblIDPS: TcxLabel
                Left = 540
                Top = 12
                Caption = 'ID PrestaShop'
                TabOrder = 14
                Transparent = True
              end
              object txtIDPS_PED: TcxDBTextEdit
                Left = 540
                Top = 32
                DataBinding.DataField = 'IDPS_PED'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 5
                Width = 90
              end
              object lblRefPS: TcxLabel
                Left = 540
                Top = 68
                Caption = 'Ref. PrestaShop'
                TabOrder = 15
                Transparent = True
              end
              object txtREFERENCIAPS_PED: TcxDBTextEdit
                Left = 540
                Top = 88
                DataBinding.DataField = 'REFERENCIAPS_PED'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 6
                Width = 110
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 8
                Top = 80
                Caption = 'Empresa Emisora'
                TabOrder = 16
                Transparent = True
              end
              object btnCODIGO_EMP: TcxDBButtonEdit
                Left = 8
                Top = 100
                DataBinding.DataField = 'CODIGO_EMP_PED'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 7
                Width = 130
              end
              object cxdblblRAZON_SOCIAL_EMPRESA_PED: TcxDBLabel
                Left = 144
                Top = 100
                DataBinding.DataField = 'RAZON_SOCIAL_EMPRESA_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 17
                Height = 21
                Width = 380
                Transparent = True
              end
              object lblCodigoCliente: TcxLabel
                Left = 8
                Top = 140
                Caption = 'Cliente'
                TabOrder = 18
                Transparent = True
              end
              object btnCODIGO_CLI: TcxDBButtonEdit
                Left = 8
                Top = 160
                DataBinding.DataField = 'CODIGO_CLI_PED'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 8
                Width = 130
              end
              object cxdblblRAZON_SOCIAL_CLIENTE_PED: TcxDBLabel
                Left = 144
                Top = 160
                DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_FISCAL_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 19
                Height = 21
                Width = 380
                Transparent = True
              end
            end
            object tsEmpresa: TcxTabSheet
              Caption = 'Empresa'
              object grpEmpresa: TcxGroupBox
                Left = 4
                Top = 4
                Caption = 'Datos Empresa Emisora'
                TabOrder = 0
                Height = 192
                Width = 920
                object lblNIFEmp: TcxLabel
                  Left = 12
                  Top = 24
                  Caption = 'NIF'
                  TabOrder = 9
                  Transparent = True
                end
                object txtNIF_EMPRESA_PED: TcxDBTextEdit
                  Left = 12
                  Top = 44
                  DataBinding.DataField = 'NIF_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 130
                end
                object lblMovEmp: TcxLabel
                  Left = 152
                  Top = 24
                  Caption = 'M'#243'vil'
                  TabOrder = 10
                  Transparent = True
                end
                object txtMOVIL_EMPRESA_PED: TcxDBTextEdit
                  Left = 152
                  Top = 44
                  DataBinding.DataField = 'MOVIL_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object lblEmailEmp: TcxLabel
                  Left = 292
                  Top = 24
                  Caption = 'Email'
                  TabOrder = 11
                  Transparent = True
                end
                object txtEMAIL_EMPRESA_PED: TcxDBTextEdit
                  Left = 292
                  Top = 44
                  DataBinding.DataField = 'EMAIL_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 220
                end
                object txtDIRECCION1_EMPRESA_PED: TcxDBTextEdit
                  Left = 12
                  Top = 84
                  DataBinding.DataField = 'DIRECCION1_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 350
                end
                object txtDIRECCION2_EMPRESA_PED: TcxDBTextEdit
                  Left = 372
                  Top = 84
                  DataBinding.DataField = 'DIRECCION2_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 250
                end
                object txtPOBLACION_EMPRESA_PED: TcxDBTextEdit
                  Left = 12
                  Top = 116
                  DataBinding.DataField = 'POBLACION_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 200
                end
                object txtPROVINCIA_EMPRESA_PED: TcxDBTextEdit
                  Left = 220
                  Top = 116
                  DataBinding.DataField = 'PROVINCIA_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 200
                end
                object txtCODIGO_POSTAL_EMPRESA_PED: TcxDBTextEdit
                  Left = 428
                  Top = 116
                  DataBinding.DataField = 'CODIGO_POSTAL_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 80
                end
                object txtNOMBRE_PAI_EMPRESA_PED: TcxDBTextEdit
                  Left = 516
                  Top = 116
                  DataBinding.DataField = 'NOMBRE_PAI_EMPRESA_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 8
                  Width = 150
                end
              end
            end
            object tsDatosCliente: TcxTabSheet
              Caption = 'Cliente Fiscal'
              object grpClienteFiscal: TcxGroupBox
                Left = 4
                Top = 4
                Caption = 'Datos Cliente Fiscal'
                TabOrder = 0
                Height = 192
                Width = 920
                object txtRAZON_SOCIAL_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 12
                  Top = 24
                  DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 320
                end
                object txtNIF_CLIENTE_PED: TcxDBTextEdit
                  Left = 342
                  Top = 24
                  DataBinding.DataField = 'NIF_CLIENTE_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object txtEMAIL_CLIENTE_PED: TcxDBTextEdit
                  Left = 482
                  Top = 24
                  DataBinding.DataField = 'EMAIL_CLIENTE_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 220
                end
                object txtMOVIL_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 712
                  Top = 24
                  DataBinding.DataField = 'MOVIL_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 130
                end
                object txtDIRECCION1_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 12
                  Top = 60
                  DataBinding.DataField = 'DIRECCION1_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 350
                end
                object txtDIRECCION2_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 372
                  Top = 60
                  DataBinding.DataField = 'DIRECCION2_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 250
                end
                object txtPOBLACION_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 12
                  Top = 96
                  DataBinding.DataField = 'POBLACION_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 200
                end
                object txtPROVINCIA_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 220
                  Top = 96
                  DataBinding.DataField = 'PROVINCIA_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 200
                end
                object txtCODIGO_POSTAL_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 428
                  Top = 96
                  DataBinding.DataField = 'CODIGO_POSTAL_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 8
                  Width = 80
                end
                object txtNOMBRE_PAI_CLIENTE_FISCAL_PED: TcxDBTextEdit
                  Left = 516
                  Top = 96
                  DataBinding.DataField = 'NOMBRE_PAI_CLIENTE_FISCAL_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 9
                  Width = 150
                end
              end
            end
            object tsEnvio: TcxTabSheet
              Caption = 'Direcci'#243'n Env'#237'o'
              object grpClienteEnvio: TcxGroupBox
                Left = 4
                Top = 4
                Caption = 'Datos Cliente Env'#237'o'
                TabOrder = 0
                Height = 192
                Width = 920
                object txtNOMBRE_CLI_ENVIO_PED: TcxDBTextEdit
                  Left = 12
                  Top = 24
                  DataBinding.DataField = 'NOMBRE_CLI_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 320
                end
                object txtMOVIL_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 342
                  Top = 24
                  DataBinding.DataField = 'MOVIL_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object txtDIRECCION1_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 12
                  Top = 60
                  DataBinding.DataField = 'DIRECCION1_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 350
                end
                object txtDIRECCION2_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 372
                  Top = 60
                  DataBinding.DataField = 'DIRECCION2_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 250
                end
                object txtPOBLACION_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 12
                  Top = 96
                  DataBinding.DataField = 'POBLACION_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 200
                end
                object txtPROVINCIA_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 220
                  Top = 96
                  DataBinding.DataField = 'PROVINCIA_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 200
                end
                object txtCODIGO_POSTAL_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 428
                  Top = 96
                  DataBinding.DataField = 'CODIGO_POSTAL_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 80
                end
                object txtNOMBRE_PAI_CLIENTE_ENVIO_PED: TcxDBTextEdit
                  Left = 516
                  Top = 96
                  DataBinding.DataField = 'NOMBRE_PAI_CLIENTE_ENVIO_PED'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 150
                end
              end
            end
          end
        end
        object pnlBotonesAcciones: TPanel
          Left = 0
          Top = 230
          Width = 941
          Height = 40
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object btnAnadirLinea: TcxButton
            Left = 4
            Top = 6
            Width = 120
            Height = 28
            Caption = 'A'#241'adir l'#237'nea'
            TabOrder = 0
            OnClick = btnAnadirLineaClick
          end
          object btnBorrarLinea: TcxButton
            Left = 130
            Top = 6
            Width = 120
            Height = 28
            Caption = 'Borrar l'#237'nea'
            TabOrder = 1
            OnClick = btnBorrarLineaClick
          end
          object btnEntregarTodo: TcxButton
            Left = 256
            Top = 6
            Width = 130
            Height = 28
            Caption = 'Marcar todo entregado'
            TabOrder = 2
            OnClick = btnEntregarTodoClick
          end
          object btnCrearAlbaran: TcxButton
            Left = 392
            Top = 6
            Width = 130
            Height = 28
            Caption = 'Crear albar'#225'n'
            TabOrder = 3
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Lucida Sans'
            Font.Style = [fsBold]
            ParentFont = False
            OnClick = btnCrearAlbaranClick
          end
          object btnImportarPS: TcxButton
            Left = 528
            Top = 6
            Width = 160
            Height = 28
            Caption = 'Importar de PrestaShop'
            TabOrder = 4
            OnClick = btnImportarPSClick
          end
          object btnImprimir: TcxButton
            Left = 694
            Top = 6
            Width = 100
            Height = 28
            Caption = 'Imprimir'
            TabOrder = 5
            OnClick = btnImprimirClick
          end
        end
        object pnlBodyFicha: TPanel
          Left = 0
          Top = 270
          Width = 941
          Height = 384
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcPedido: TcxPageControl
            Left = 0
            Top = 0
            Width = 941
            Height = 384
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasPedido
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 382
            ClientRectLeft = 2
            ClientRectRight = 939
            ClientRectTop = 29
            object tsLineasPedido: TcxTabSheet
              Caption = 'L'#237'neas Pedido'
              object cxGrdPedidosLineas: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 353
                Align = alClient
                TabOrder = 0
                object tvPedidosLineas: TcxGridDBTableView
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  object cxgrdcPedLinLINEA: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_PEDLIN'
                    Width = 65
                  end
                  object cxgrdcPedLinART: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_PEDLIN'
                    Width = 154
                  end
                  object cxgrdcPedLinDESCR: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_PEDLIN'
                    Width = 240
                  end
                  object cxgrdcPedLinCANT: TcxGridDBColumn
                    Caption = 'Pedida'
                    DataBinding.FieldName = 'CANTIDAD_PEDLIN'
                    Width = 80
                  end
                  object colTipoCantPed: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_PEDLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdcPedLinENT: TcxGridDBColumn
                    Caption = 'Entregada'
                    DataBinding.FieldName = 'CANTIDAD_ENTREGADA_PEDLIN'
                    Width = 119
                  end
                  object cxgrdcPedLinPEND: TcxGridDBColumn
                    Caption = 'Pendiente'
                    DataBinding.FieldName = 'CANTIDAD_PENDIENTE_PEDLIN'
                    Options.Editing = False
                    Width = 110
                  end
                  object cxgrdcPedLinESEN: TcxGridDBColumn
                    Caption = 'Entregada?'
                    DataBinding.FieldName = 'ESENTREGADA_PEDLIN'
                    Options.Editing = False
                    Width = 111
                  end
                  object cxgrdcPedLinPSIVA: TcxGridDBColumn
                    Caption = 'PVP S/IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_PEDLIN'
                    Width = 90
                  end
                  object cxgrdcPedLinPCIVA: TcxGridDBColumn
                    Caption = 'PVP C/IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN'
                    Width = 90
                  end
                  object cxgrdcPedLinTOT: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_PEDLIN'
                    Width = 100
                  end
                  object cxgrdcPedLinALM: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'CODIGO_ALMACEN_PEDLIN'
                    Width = 80
                  end
                end
                object cxGrdPedidosLineasLevel1: TcxGridLevel
                  GridView = tvPedidosLineas
                end
              end
            end
            object tsAlbaranes: TcxTabSheet
              Caption = 'Albaranes'
              object cxGrdAlbaranes: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 353
                Align = alClient
                TabOrder = 0
                object tvAlbaranes: TcxGridDBTableView
                  object cxgrdcAlbNUMERO_ALB: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO_ALB'
                    Width = 90
                  end
                  object cxgrdcAlbSERIE_ALB: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_ALB'
                    Width = 70
                  end
                  object cxgrdcAlbFECHA_ALB: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_ALB'
                    Width = 100
                  end
                  object cxgrdcAlbESTADO_ALB: TcxGridDBColumn
                    Caption = 'Estado'
                    DataBinding.FieldName = 'ESTADO_ALB'
                    Width = 110
                  end
                  object cxgrdcAlbTOTAL_LIQUIDO_ALB: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_LIQUIDO_ALB'
                    Width = 110
                  end
                end
                object cxGrdAlbaranesLevel: TcxGridLevel
                  GridView = tvAlbaranes
                end
              end
            end
            object tsMensajes: TcxTabSheet
              Caption = 'Mensajes con el cliente'
              object cxGrdMensajes: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 353
                Align = alClient
                TabOrder = 0
                object tvMensajes: TcxGridDBTableView
                  object cxgrdcMsgFecha: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHAPS_PEDMSG'
                    Width = 130
                  end
                  object cxgrdcMsgEmpleado: TcxGridDBColumn
                    Caption = 'Empleado'
                    DataBinding.FieldName = 'IDEMPLEADOPS_PEDMSG'
                    Width = 120
                  end
                  object cxgrdcMsgTexto: TcxGridDBColumn
                    Caption = 'Mensaje'
                    DataBinding.FieldName = 'MENSAJEPS_PEDMSG'
                    Width = 600
                  end
                end
                object cxGrdMensajesLevel: TcxGridLevel
                  GridView = tvMensajes
                end
              end
            end
            object tsObservaciones: TcxTabSheet
              Caption = 'Observaciones'
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_PED'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 353
                Width = 937
              end
            end
          end
        end
        object pnlBottomTotales: TPanel
          Left = 0
          Top = 654
          Width = 941
          Height = 40
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 3
          object lblTotalBases: TcxLabel
            Left = 380
            Top = 8
            Caption = 'Bases'
            TabOrder = 3
            Transparent = True
          end
          object curTOTAL_BASES_PED: TcxDBCurrencyEdit
            Left = 425
            Top = 8
            DataBinding.DataField = 'TOTAL_BASES_PED'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 0
            Width = 100
          end
          object lblTotalImpuestos: TcxLabel
            Left = 540
            Top = 8
            Caption = 'IVA'
            TabOrder = 4
            Transparent = True
          end
          object curTOTAL_IMPUESTOS_PED: TcxDBCurrencyEdit
            Left = 570
            Top = 8
            DataBinding.DataField = 'TOTAL_IMPUESTOS_PED'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 100
          end
          object lblTotalLiquido: TcxLabel
            Left = 690
            Top = 8
            Caption = 'TOTAL'
            TabOrder = 5
            Transparent = True
          end
          object curTOTAL_LIQUIDO_PED: TcxDBCurrencyEdit
            Left = 740
            Top = 8
            DataBinding.DataField = 'TOTAL_LIQUIDO_PED'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 2
            Width = 130
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 941
        ExplicitHeight = 694
        inherited pnlPerfilTop: TPanel
          Width = 941
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 941
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 941
          Height = 637
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 941
          ExplicitHeight = 637
          inherited cxgrdPerfil: TcxGrid
            Width = 941
            Height = 637
            ExplicitWidth = 941
            ExplicitHeight = 637
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
          ExplicitHeight = 27
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
  end
  object ActionList1: TActionList
    Left = 880
    Top = 8
    object actIrDocumento: TAction
      Caption = 'Ir a documento (Ctrl+May+A)'
      ShortCut = 24641
      OnExecute = actIrDocumentoExecute
    end
  end
end
