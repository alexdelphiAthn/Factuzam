inherited frmMtoAlbaranes: TfrmMtoAlbaranes
  Caption = 'Mantenimiento de Albaranes'
  ClientHeight = 765
  ClientWidth = 1085
  StyleElements = [seFont, seClient, seBorder]
  ExplicitTop = -38
  ExplicitWidth = 1085
  ExplicitHeight = 765
  TextHeight = 19
  OnCreate = FormCreate
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
            object dbcGrdAlbNUMERO_ALB: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_ALB'
              Width = 90
            end
            object dbcGrdAlbSERIE_ALB: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_ALB'
              Width = 80
            end
            object dbcGrdAlbFECHA_ALB: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_ALB'
              Width = 100
            end
            object dbcGrdAlbESTADO_ALB: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_ALB'
              Width = 110
            end
            object dbcGrdAlbCODIGO_EMP_ALB: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_ALB'
              Width = 100
            end
            object dbcGrdAlbRSEMP_ALB: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Empresa'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_ALB'
              Width = 220
            end
            object dbcGrdAlbCODIGO_CLI_ALB: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_ALB'
              Width = 100
            end
            object dbcGrdAlbRSCLI_ALB: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Cliente'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_ALB'
              Width = 220
            end
            object dbcGrdAlbNUMERO_PED_ALB: TcxGridDBColumn
              Caption = 'Pedido'
              DataBinding.FieldName = 'NUMERO_PED_ALB'
              Width = 90
            end
            object dbcGrdAlbSERIE_PED_ALB: TcxGridDBColumn
              Caption = 'Serie Pedido'
              DataBinding.FieldName = 'SERIE_PED_ALB'
              Width = 90
            end
            object dbcGrdAlbNUMERO_FAC_ALB: TcxGridDBColumn
              Caption = 'Factura'
              DataBinding.FieldName = 'NUMERO_FAC_ALB'
              Width = 90
            end
            object dbcGrdAlbSERIE_FAC_ALB: TcxGridDBColumn
              Caption = 'Serie Factura'
              DataBinding.FieldName = 'SERIE_FAC_ALB'
              Width = 90
            end
            object dbcGrdAlbTOTAL_LIQUIDO_ALB: TcxGridDBColumn
              Caption = 'Total'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_ALB'
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
              object lblNroAlbaran: TcxLabel
                Left = 8
                Top = 12
                Caption = 'N'#250'mero'
                TabOrder = 9
                Transparent = True
              end
              object txtNUMERO_ALB: TcxDBTextEdit
                Left = 8
                Top = 32
                DataBinding.DataField = 'NUMERO_ALB'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Width = 100
              end
              object lblSerieAlbaran: TcxLabel
                Left = 116
                Top = 12
                Caption = 'Serie'
                TabOrder = 10
                Transparent = True
              end
              object txtSERIE_ALB: TcxDBTextEdit
                Left = 116
                Top = 32
                DataBinding.DataField = 'SERIE_ALB'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 80
              end
              object lblFechaAlbaran: TcxLabel
                Left = 204
                Top = 12
                Caption = 'Fecha'
                TabOrder = 11
                Transparent = True
              end
              object dteFECHA_ALB: TcxDBDateEdit
                Left = 204
                Top = 32
                DataBinding.DataField = 'FECHA_ALB'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 110
              end
              object lblEstadoAlbaran: TcxLabel
                Left = 320
                Top = 12
                Caption = 'Estado'
                TabOrder = 12
                Transparent = True
              end
              object txtESTADO_ALB: TcxDBTextEdit
                Left = 320
                Top = 32
                DataBinding.DataField = 'ESTADO_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
                Width = 110
              end
              object lblPedidoOrigen: TcxLabel
                Left = 440
                Top = 12
                Caption = 'Pedido origen (N'#250'mero / Serie)'
                TabOrder = 13
                Transparent = True
              end
              object txtNUMERO_PED_ALB: TcxDBTextEdit
                Left = 440
                Top = 32
                DataBinding.DataField = 'NUMERO_PED_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 4
                Width = 90
              end
              object txtSERIE_PED_ALB: TcxDBTextEdit
                Left = 540
                Top = 32
                DataBinding.DataField = 'SERIE_PED_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 5
                Width = 80
              end
              object btnIrDocumento: TcxButton
                Left = 440
                Top = 56
                Width = 190
                Height = 23
                Action = actIrDocumento
                TabOrder = 16
              end
              object lblFacturaDestino: TcxLabel
                Left = 640
                Top = 12
                Caption = 'Factura (N'#250'mero / Serie)'
                TabOrder = 14
                Transparent = True
              end
              object txtNUMERO_FAC_ALB: TcxDBTextEdit
                Left = 640
                Top = 32
                DataBinding.DataField = 'NUMERO_FAC_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 6
                Width = 90
              end
              object txtSERIE_FAC_ALB: TcxDBTextEdit
                Left = 740
                Top = 32
                DataBinding.DataField = 'SERIE_FAC_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 7
                Width = 80
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 8
                Top = 80
                Caption = 'Empresa Emisora'
                TabOrder = 15
                Transparent = True
              end
              object btnCODIGO_EMP_ALB: TcxDBButtonEdit
                Left = 8
                Top = 100
                DataBinding.DataField = 'CODIGO_EMP_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 8
                Width = 130
              end
              object cxdblblRAZON_SOCIAL_EMPRESA_ALB: TcxDBLabel
                Left = 144
                Top = 100
                DataBinding.DataField = 'RAZON_SOCIAL_EMPRESA_ALB'
                DataBinding.DataSource = dsTablaG
                Style.Font.Style = [fsBold]
                Width = 380
                Transparent = True
              end
              object lblCodigoCliente: TcxLabel
                Left = 8
                Top = 140
                Caption = 'Cliente'
                TabOrder = 16
                Transparent = True
              end
              object btnCODIGO_CLI_ALB: TcxDBButtonEdit
                Left = 8
                Top = 160
                DataBinding.DataField = 'CODIGO_CLI_ALB'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 17
                Width = 130
              end
              object cxdblblRAZON_SOCIAL_CLIENTE_ALB: TcxDBLabel
                Left = 144
                Top = 160
                DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_ALB'
                DataBinding.DataSource = dsTablaG
                Style.Font.Style = [fsBold]
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
                  Transparent = True
                end
                object txtNIF_EMPRESA_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 44
                  DataBinding.DataField = 'NIF_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 130
                end
                object lblMovEmp: TcxLabel
                  Left = 152
                  Top = 24
                  Caption = 'M'#243'vil'
                  Transparent = True
                end
                object txtMOVIL_EMPRESA_ALB: TcxDBTextEdit
                  Left = 152
                  Top = 44
                  DataBinding.DataField = 'MOVIL_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object lblEmailEmp: TcxLabel
                  Left = 292
                  Top = 24
                  Caption = 'Email'
                  Transparent = True
                end
                object txtEMAIL_EMPRESA_ALB: TcxDBTextEdit
                  Left = 292
                  Top = 44
                  DataBinding.DataField = 'EMAIL_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 220
                end
                object txtDIRECCION1_EMPRESA_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 84
                  DataBinding.DataField = 'DIRECCION1_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 350
                end
                object txtDIRECCION2_EMPRESA_ALB: TcxDBTextEdit
                  Left = 372
                  Top = 84
                  DataBinding.DataField = 'DIRECCION2_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 250
                end
                object txtPOBLACION_EMPRESA_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 116
                  DataBinding.DataField = 'POBLACION_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 200
                end
                object txtPROVINCIA_EMPRESA_ALB: TcxDBTextEdit
                  Left = 220
                  Top = 116
                  DataBinding.DataField = 'PROVINCIA_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 200
                end
                object txtCODIGO_POSTAL_EMPRESA_ALB: TcxDBTextEdit
                  Left = 428
                  Top = 116
                  DataBinding.DataField = 'CODIGO_POSTAL_EMPRESA_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 80
                end
                object txtNOMBRE_PAI_EMPRESA_ALB: TcxDBTextEdit
                  Left = 516
                  Top = 116
                  DataBinding.DataField = 'NOMBRE_PAI_EMPRESA_ALB'
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
                object txtRAZON_SOCIAL_CLIENTE_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 24
                  DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 320
                end
                object txtNIF_CLIENTE_ALB: TcxDBTextEdit
                  Left = 342
                  Top = 24
                  DataBinding.DataField = 'NIF_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object txtEMAIL_CLIENTE_ALB: TcxDBTextEdit
                  Left = 482
                  Top = 24
                  DataBinding.DataField = 'EMAIL_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 220
                end
                object txtMOVIL_CLIENTE_ALB: TcxDBTextEdit
                  Left = 712
                  Top = 24
                  DataBinding.DataField = 'MOVIL_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 130
                end
                object txtDIRECCION1_CLIENTE_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 60
                  DataBinding.DataField = 'DIRECCION1_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 350
                end
                object txtDIRECCION2_CLIENTE_ALB: TcxDBTextEdit
                  Left = 372
                  Top = 60
                  DataBinding.DataField = 'DIRECCION2_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 250
                end
                object txtPOBLACION_CLIENTE_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 96
                  DataBinding.DataField = 'POBLACION_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 200
                end
                object txtPROVINCIA_CLIENTE_ALB: TcxDBTextEdit
                  Left = 220
                  Top = 96
                  DataBinding.DataField = 'PROVINCIA_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 200
                end
                object txtCODIGO_POSTAL_CLIENTE_ALB: TcxDBTextEdit
                  Left = 428
                  Top = 96
                  DataBinding.DataField = 'CODIGO_POSTAL_CLIENTE_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 8
                  Width = 80
                end
                object txtNOMBRE_PAI_CLIENTE_ALB: TcxDBTextEdit
                  Left = 516
                  Top = 96
                  DataBinding.DataField = 'NOMBRE_PAI_CLIENTE_ALB'
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
                object txtNOMBRE_CLI_ENVIO_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 24
                  DataBinding.DataField = 'NOMBRE_CLI_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 320
                end
                object txtMOVIL_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 342
                  Top = 24
                  DataBinding.DataField = 'MOVIL_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object txtDIRECCION1_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 60
                  DataBinding.DataField = 'DIRECCION1_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 350
                end
                object txtDIRECCION2_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 372
                  Top = 60
                  DataBinding.DataField = 'DIRECCION2_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 250
                end
                object txtPOBLACION_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 12
                  Top = 96
                  DataBinding.DataField = 'POBLACION_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 200
                end
                object txtPROVINCIA_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 220
                  Top = 96
                  DataBinding.DataField = 'PROVINCIA_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 200
                end
                object txtCODIGO_POSTAL_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 428
                  Top = 96
                  DataBinding.DataField = 'CODIGO_POSTAL_CLIENTE_ENVIO_ALB'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 80
                end
                object txtNOMBRE_PAI_CLIENTE_ENVIO_ALB: TcxDBTextEdit
                  Left = 516
                  Top = 96
                  DataBinding.DataField = 'NOMBRE_PAI_CLIENTE_ENVIO_ALB'
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
            Width = 110
            Height = 28
            Caption = 'A'#241'adir l'#237'nea'
            TabOrder = 0
            OnClick = btnAnadirLineaClick
          end
          object btnBorrarLinea: TcxButton
            Left = 118
            Top = 6
            Width = 110
            Height = 28
            Caption = 'Borrar l'#237'nea'
            TabOrder = 1
            OnClick = btnBorrarLineaClick
          end
          object btnFacturarSeleccionadas: TcxButton
            Left = 240
            Top = 6
            Width = 170
            Height = 28
            Caption = 'Facturar l'#237'neas selec.'
            TabOrder = 2
            OnClick = btnFacturarSeleccionadasClick
          end
          object btnFacturarTodo: TcxButton
            Left = 414
            Top = 6
            Width = 150
            Height = 28
            Caption = 'Facturar este albar'#225'n'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Lucida Sans'
            Font.Style = [fsBold]
            ParentFont = False
            TabOrder = 3
            OnClick = btnFacturarTodoClick
          end
          object btnFacturarPorFechas: TcxButton
            Left = 568
            Top = 6
            Width = 200
            Height = 28
            Caption = 'Facturar por fechas / serie'
            TabOrder = 4
            OnClick = btnFacturarPorFechasClick
          end
          object btnImprimir: TcxButton
            Left = 772
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
          object pcAlbaran: TcxPageControl
            Left = 0
            Top = 0
            Width = 941
            Height = 384
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsLineasAlbaran
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 382
            ClientRectLeft = 2
            ClientRectRight = 939
            ClientRectTop = 29
            object tsLineasAlbaran: TcxTabSheet
              Caption = 'L'#237'neas Albar'#225'n'
              object cxgrdLineasAlbaran: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 353
                Align = alClient
                TabOrder = 0
                object tvLineasAlbaran: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  DataController.Summary.DefaultGroupSummaryItems = <>
                  DataController.Summary.FooterSummaryItems = <>
                  DataController.Summary.SummaryGroups = <>
                  OptionsSelection.MultiSelect = True
                  OptionsSelection.CellMultiSelect = False
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  object cxgrdcLineaAlb: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_ALBLIN'
                    Width = 60
                  end
                  object cxgrdcArtAlb: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_ALBLIN'
                    Width = 130
                  end
                  object cxgrdcSkuAlb: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_ALBLIN'
                    Width = 150
                  end
                  object cxgrdcVarAlb: TcxGridDBColumn
                    Caption = 'Variaci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_VARIACION_ALBLIN'
                    Width = 160
                  end
                  object cxgrdcDescrAlb: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_ALBLIN'
                    Width = 240
                  end
                  object cxgrdcLoteAlb: TcxGridDBColumn
                    Caption = 'Lote'
                    DataBinding.FieldName = 'LOTE_ALBLIN'
                    Width = 90
                  end
                  object cxgrdcCadAlb: TcxGridDBColumn
                    Caption = 'Caducidad'
                    DataBinding.FieldName = 'FECHA_CADUCIDAD_ALBLIN'
                    Width = 100
                  end
                  object cxgrdcCantAlb: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_ALBLIN'
                    Width = 80
                  end
                  object colTipoCantAlb: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_ALBLIN'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdcPSivaAlb: TcxGridDBColumn
                    Caption = 'PVP S/IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN'
                    Width = 90
                  end
                  object cxgrdcPCivaAlb: TcxGridDBColumn
                    Caption = 'PVP C/IVA'
                    DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN'
                    Width = 90
                  end
                  object cxgrdcTotalAlb: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_ALBLIN'
                    Width = 100
                  end
                  object cxgrdcEsFactAlb: TcxGridDBColumn
                    Caption = 'Facturada?'
                    DataBinding.FieldName = 'ESFACTURADA_ALBLIN'
                    Options.Editing = False
                    Width = 90
                  end
                  object cxgrdcNumFacAlb: TcxGridDBColumn
                    Caption = 'Factura'
                    DataBinding.FieldName = 'NUMERO_FAC_ALBLIN'
                    Options.Editing = False
                    Width = 90
                  end
                  object cxgrdcSerFacAlb: TcxGridDBColumn
                    Caption = 'Serie Fac.'
                    DataBinding.FieldName = 'SERIE_FAC_ALBLIN'
                    Options.Editing = False
                    Width = 80
                  end
                  object cxgrdcPedAlb: TcxGridDBColumn
                    Caption = 'L'#237'nea Pedido'
                    DataBinding.FieldName = 'LINEA_PED_ALBLIN'
                    Width = 90
                  end
                end
                object cxgrdlvlLineasAlbaran: TcxGridLevel
                  GridView = tvLineasAlbaran
                end
              end
            end
            object tsFacturas: TcxTabSheet
              Caption = 'Facturas'
              object cxGrdFacturas: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 353
                Align = alClient
                TabOrder = 0
                object tvFacturas: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  DataController.Summary.DefaultGroupSummaryItems = <>
                  DataController.Summary.FooterSummaryItems = <>
                  DataController.Summary.SummaryGroups = <>
                  object cxgrdcFacNum: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO_FAC'
                    Width = 100
                  end
                  object cxgrdcFacSer: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_FAC'
                    Width = 80
                  end
                  object cxgrdcFacFec: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_FAC'
                    Width = 110
                  end
                  object cxgrdcFacFase: TcxGridDBColumn
                    Caption = 'Fase'
                    DataBinding.FieldName = 'FASE_FAC'
                    Width = 110
                  end
                  object cxgrdcFacTot: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_LIQUIDO_FAC'
                    Width = 110
                  end
                end
                object cxGrdFacturasLevel: TcxGridLevel
                  GridView = tvFacturas
                end
              end
            end
            object tsMovimientos: TcxTabSheet
              Caption = 'Movimientos'
              object cxGrdMovimientos: TcxGrid
                Left = 0
                Top = 0
                Width = 937
                Height = 353
                Align = alClient
                TabOrder = 0
                object tvMovimientos: TcxGridDBTableView
                  Navigator.Buttons.CustomButtons = <>
                  DataController.Summary.DefaultGroupSummaryItems = <>
                  DataController.Summary.FooterSummaryItems = <>
                  DataController.Summary.SummaryGroups = <>
                  OptionsData.Editing = False
                  object cxgrdcMovNum: TcxGridDBColumn
                    Caption = 'N'#250'mero Mov.'
                    DataBinding.FieldName = 'NUMERO_MOV'
                    Width = 110
                  end
                  object cxgrdcMovFec: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_MOV'
                    Width = 130
                  end
                  object cxgrdcMovLin: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_MOV'
                    Width = 60
                  end
                  object cxgrdcMovAlm: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'NOMBRE_ALMACEN_ORIGEN'
                    Width = 140
                  end
                  object cxgrdcMovArt: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_MOV'
                    Width = 100
                  end
                  object cxgrdcMovSku: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
                    Width = 140
                  end
                  object cxgrdcMovDescr: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_MOV'
                    Width = 200
                  end
                  object cxgrdcMovTipo: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_MOV'
                    Width = 50
                  end
                  object cxgrdcMovCant: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_MOV'
                    Width = 90
                  end
                  object cxgrdcMovPMP: TcxGridDBColumn
                    Caption = 'PMP'
                    DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
                    Width = 90
                  end
                  object cxgrdcMovTot: TcxGridDBColumn
                    Caption = 'Total Coste'
                    DataBinding.FieldName = 'TOTAL_COSTE_MOV'
                    Width = 100
                  end
                end
                object cxGrdMovimientosLevel: TcxGridLevel
                  GridView = tvMovimientos
                end
              end
            end
            object tsObservaciones: TcxTabSheet
              Caption = 'Observaciones'
              object memObservaciones: TcxDBMemo
                Left = 0
                Top = 0
                Align = alClient
                DataBinding.DataField = 'OBSERVACIONES_ALB'
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
          object curTOTAL_BASES_ALB: TcxDBCurrencyEdit
            Left = 425
            Top = 8
            DataBinding.DataField = 'TOTAL_BASES_ALB'
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
          object curTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit
            Left = 570
            Top = 8
            DataBinding.DataField = 'TOTAL_IMPUESTOS_ALB'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 100
          end
          object lblTotalLiquido: TcxLabel
            Left = 690
            Top = 8
            Caption = 'TOTAL'
            Style.Font.Style = [fsBold]
            TabOrder = 5
            Transparent = True
          end
          object curTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit
            Left = 740
            Top = 8
            DataBinding.DataField = 'TOTAL_LIQUIDO_ALB'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            Style.Font.Style = [fsBold]
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
