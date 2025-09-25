inherited frmMtoPedidos: TfrmMtoPedidos
  Caption = 'Mantenimiento de Pedidos'
  ClientHeight = 765
  ClientWidth = 1085
  ExplicitWidth = 1085
  ExplicitHeight = 765
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 945
    Height = 765
    ExplicitWidth = 945
    ExplicitHeight = 765
    inherited pcPantalla: TcxPageControl
      Width = 945
      Height = 725
      Properties.ActivePage = tsLista
      ExplicitWidth = 945
      ExplicitHeight = 725
      ClientRectBottom = 721
      ClientRectRight = 941
      inherited tsLista: TcxTabSheet
        ExplicitWidth = 937
        ExplicitHeight = 691
        inherited cxGrdPrincipal: TcxGrid
          Width = 937
          Height = 691
          ExplicitWidth = 937
          ExplicitHeight = 691
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcGrdDBTabPrinIDPS_PEDIDO: TcxGridDBColumn
              Caption = 'C'#243'digo PrestaShop'
              DataBinding.FieldName = 'IDPS_PEDIDO'
            end
            object dbcGrdDBTabPrinFECHAPS_PEDIDO: TcxGridDBColumn
              Caption = 'Fecha Pedido PrestaShop'
              DataBinding.FieldName = 'FECHAPS_PEDIDO'
              Width = 219
            end
            object dbcGrdDBTabPrinCODIGO_EMPRESA_PEDIDO: TcxGridDBColumn
              Caption = 'C'#243'digo Empresa Emisora'
              DataBinding.FieldName = 'CODIGO_EMPRESA_PEDIDO'
              Width = 220
            end
            object dbcGrdDBTabPrinFECHA_PEDIDO: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_PEDIDO'
              Width = 110
            end
            object dbcGrdDBTabPrinNRO_PEDIDO: TcxGridDBColumn
              Caption = 'Nro Pedido'
              DataBinding.FieldName = 'NRO_PEDIDO'
            end
            object dbcGrdDBTabPrinSERIE_PEDIDO: TcxGridDBColumn
              Caption = 'Serie Pedido'
              DataBinding.FieldName = 'SERIE_PEDIDO'
              Width = 128
            end
            object dbcGrdDBTabPrinCODIGO_CLIENTE_PEDIDO: TcxGridDBColumn
              Caption = 'C'#243'digo Cliente'
              DataBinding.FieldName = 'CODIGO_CLIENTE_PEDIDO'
              Width = 139
            end
            object dbcGrdDBTabPrinEMAIL_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'EMAIL_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinNIF_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'NIF_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinNOMBRE_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn
              Caption = 'Nombre Cliente Env'#237'o'
              DataBinding.FieldName = 'NOMBRE_CLIENTE_ENVIO_PEDIDO'
              Width = 248
            end
            object dbcGrdDBTabPrinMOVIL_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn
              Caption = 'M'#243'vil Cliente Env'#237'o'
              DataBinding.FieldName = 'MOVIL_CLIENTE_ENVIO_PEDIDO'
              Width = 182
            end
            object dbcGrdDBTabPrinDIRECCION1_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn
              Caption = 'Direcci'#243'n 1 Cliente Env'#237'o'
              DataBinding.FieldName = 'DIRECCION1_CLIENTE_ENVIO_PEDIDO'
              Width = 218
            end
            object dbcGrdDBTabPrinDIRECCION2_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn
              Caption = 'Direcci'#243'n 2 Cliente Env'#237'o'
              DataBinding.FieldName = 'DIRECCION2_CLIENTE_ENVIO_PEDIDO'
              Width = 218
            end
            object dbcGrdDBTabPrinCPOSTAL_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn
              Caption = 'C'#243'digo Postal Cliente Env'#237'o'
              DataBinding.FieldName = 'CPOSTAL_CLIENTE_ENVIO_PEDIDO'
            end
            object dbcGrdDBTabPrinPOBLACION_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn
              Caption = 'Poblaci'#243'n Cliente Env'#237'o'
              DataBinding.FieldName = 'POBLACION_CLIENTE_ENVIO_PEDIDO'
              Width = 204
            end
            object dbcGrdDBTabPrinPROVINCIA_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn
              Caption = 'Provincia Cliente Env'#237'o'
              DataBinding.FieldName = 'PROVINCIA_CLIENTE_ENVIO_PEDIDO'
              Width = 210
            end
            object dbcGrdDBTabPrinCODIGO_PAIS_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn
              Caption = 'C'#243'digo Pa'#237's Cliente Env'#237'o'
              DataBinding.FieldName = 'CODIGO_PAIS_CLIENTE_ENVIO_PEDIDO'
            end
            object dbcGrdDBTabPrinNOMBRE_PAIS_CLIENTE_ENVIO_PEDIDO: TcxGridDBColumn
              Caption = 'Pa'#237's Cliente Env'#237'o'
              DataBinding.FieldName = 'NOMBRE_PAIS_CLIENTE_ENVIO_PEDIDO'
              Width = 154
            end
            object dbcGrdDBTabPrinRAZONSOCIAL_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Cliente Fiscal'
              DataBinding.FieldName = 'RAZONSOCIAL_CLIENTE_FISCAL_PEDIDO'
              Width = 231
            end
            object dbcGrdDBTabPrinMOVIL_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              Caption = 'M'#243'vil Cliente Fiscal'
              DataBinding.FieldName = 'MOVIL_CLIENTE_FISCAL_PEDIDO'
            end
            object dbcGrdDBTabPrinEMAIL_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              Caption = 'Email Cliente Fiscal'
              DataBinding.FieldName = 'EMAIL_CLIENTE_FISCAL_PEDIDO'
              Width = 170
            end
            object dbcGrdDBTabPrinDIRECCION1_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'DIRECCION1_CLIENTE_FISCAL_PEDIDO'
              Width = 324
            end
            object dbcGrdDBTabPrinDIRECCION2_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'DIRECCION2_CLIENTE_FISCAL_PEDIDO'
              Width = 324
            end
            object dbcGrdDBTabPrinPOBLACION_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'POBLACION_CLIENTE_FISCAL_PEDIDO'
              Width = 314
            end
            object dbcGrdDBTabPrinPROVINCIA_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PROVINCIA_CLIENTE_FISCAL_PEDIDO'
              Width = 310
            end
            object dbcGrdDBTabPrinCPOSTAL_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'CPOSTAL_CLIENTE_FISCAL_PEDIDO'
            end
            object dbcGrdDBTabPrinCODIGO_PAIS_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'CODIGO_PAIS_CLIENTE_FISCAL_PEDIDO'
            end
            object dbcGrdDBTabPrinNOMBRE_PAIS_CLIENTE_FISCAL_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'NOMBRE_PAIS_CLIENTE_FISCAL_PEDIDO'
              Width = 1582
            end
            object dbcGrdDBTabPrinREFERENCIAPS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'REFERENCIAPS_PEDIDO'
            end
            object dbcGrdDBTabPrinFORMAPAGOPS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'FORMAPAGOPS_PEDIDO'
            end
            object dbcGrdDBTabPrinDESCRIPCION_FORMAPAGO: TcxGridDBColumn
              DataBinding.FieldName = 'DESCRIPCION_FORMAPAGO'
            end
            object dbcGrdDBTabPrinTRANSPORTISTAPS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TRANSPORTISTAPS_PEDIDO'
            end
            object dbcGrdDBTabPrinESTADOPEDIDOPS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESTADOPEDIDOPS_PEDIDO'
            end
            object dbcGrdDBTabPrinESTADOMENSAJEPS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESTADOMENSAJEPS_PEDIDO'
            end
            object dbcGrdDBTabPrinIDHILOPS_MENSAJES_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'IDHILOPS_MENSAJES_PEDIDO'
            end
            object dbcGrdDBTabPrinESIVA_RECARGO_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinESIVA_EXENTO_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinESREGIMENESPECIALAGRICOLA_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinESRETENCIONES_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESRETENCIONES_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinTARIFA_ARTICULO_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TARIFA_ARTICULO_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinESIMP_INCL_TARIFA_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinESINTRACOMUNITARIO_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA_PEDIDO'
            end
            object dbcGrdDBTabPrinESAPLICA_RE_ZONA_IVA_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESAPLICA_RE_ZONA_IVA_PEDIDO'
            end
            object dbcGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESIVAAGRICOLA_ZONA_IVA_PEDIDO'
            end
            object dbcGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PALABRA_REPORTS_ZONA_IVA_PEDIDO'
            end
            object dbcGrdDBTabPrinCODIGO_IVA_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'CODIGO_IVA_PEDIDO'
            end
            object dbcGrdDBTabPrinESVENTA_ACTIVO_FIJO_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESVENTA_ACTIVO_FIJO_PEDIDO'
            end
            object dbcGrdDBTabPrinPORCEN_IVAN_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PORCEN_IVAN_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_IVAN_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_IVAN_PEDIDO'
            end
            object dbcGrdDBTabPrinPORCEN_REN_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PORCEN_REN_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_REN_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_REN_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_BASEI_IVAN_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_BASEI_IVAN_PEDIDO'
            end
            object dbcGrdDBTabPrinPORCEN_IVAR_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PORCEN_IVAR_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_IVAR_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_IVAR_PEDIDO'
            end
            object dbcGrdDBTabPrinPORCEN_RER_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PORCEN_RER_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_RER_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_RER_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_BASEI_IVAR_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_BASEI_IVAR_PEDIDO'
            end
            object dbcGrdDBTabPrinPORCEN_IVAS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PORCEN_IVAS_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_IVAS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_IVAS_PEDIDO'
            end
            object dbcGrdDBTabPrinPORCEN_RES_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PORCEN_RES_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_RES_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_RES_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_BASEI_IVAS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_BASEI_IVAS_PEDIDO'
            end
            object dbcGrdDBTabPrinPORCEN_IVAE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PORCEN_IVAE_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_IVAE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_IVAE_PEDIDO'
            end
            object dbcGrdDBTabPrinPORCEN_REE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PORCEN_REE_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_REE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_REE_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_BASEI_IVAE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_BASEI_IVAE_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_BASES_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_BASES_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_IMPUESTOS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_IMPUESTOS_PEDIDO'
            end
            object dbcGrdDBTabPrinFORMA_PAGO_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'FORMA_PAGO_PEDIDO'
            end
            object dbcGrdDBTabPrinPORCEN_RETENCION_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'PORCEN_RETENCION_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_RETENCION_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_RETENCION_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_LIQUIDO_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_LIQUIDO_PEDIDO'
            end
            object dbcGrdDBTabPrinTOTAL_PAGADOREALPS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TOTAL_PAGADOREALPS_PEDIDO'
            end
            object dbcGrdDBTabPrinNRO_PEDIDO_ABONO_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'NRO_PEDIDO_ABONO_PEDIDO'
            end
            object dbcGrdDBTabPrinSERIE_PEDIDO_ABONO_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'SERIE_PEDIDO_ABONO_PEDIDO'
            end
            object dbcGrdDBTabPrinTEXTO_LEGAL_PEDIDO_CLIENTE_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TEXTO_LEGAL_PEDIDO_CLIENTE_PEDIDO'
            end
            object dbcGrdDBTabPrinTEXTO_LEGAL_PEDIDO_EMPRESA_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'TEXTO_LEGAL_PEDIDO_EMPRESA_PEDIDO'
            end
            object dbcGrdDBTabPrinDOCUMENTO_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'DOCUMENTO_PEDIDO'
            end
            object dbcGrdDBTabPrinCOMENTARIOS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'COMENTARIOS_PEDIDO'
            end
            object dbcGrdDBTabPrinCONTADOR_LINEAS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'CONTADOR_LINEAS_PEDIDO'
            end
            object dbcGrdDBTabPrinESCREARARTICULOS_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESCREARARTICULOS_PEDIDO'
            end
            object dbcGrdDBTabPrinESDESCRIPCIONES_AMP_PEDIDO: TcxGridDBColumn
              DataBinding.FieldName = 'ESDESCRIPCIONES_AMP_PEDIDO'
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitWidth = 852
        ExplicitHeight = 691
        object pnlTopPedido: TPanel
          Left = 0
          Top = 0
          Width = 937
          Height = 241
          Align = alTop
          TabOrder = 0
          ExplicitWidth = 852
          object pcCab: TcxPageControl
            Left = 1
            Top = 1
            Width = 935
            Height = 239
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsDatosCliente
            Properties.CustomButtons.Buttons = <>
            ExplicitLeft = 0
            ExplicitTop = 0
            ExplicitWidth = 1079
            ExplicitHeight = 337
            ClientRectBottom = 235
            ClientRectLeft = 4
            ClientRectRight = 931
            ClientRectTop = 30
            object tsCabecera: TcxTabSheet
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = '&Cabecera Factura '
              ImageIndex = 0
              object lblNroFactura: TcxLabel
                Left = 45
                Top = 16
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Nro Factura'
                Transparent = True
              end
              object lblFechaFactura: TcxLabel
                Left = 95
                Top = 200
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Fecha'
                Transparent = True
              end
              object dteFECHA_FACTURA: TcxDBDateEdit
                Left = 155
                Top = 196
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'FECHA_FACTURA'
                DataBinding.DataSource = dsTablaG
                Properties.DateButtons = [btnClear, btnToday]
                TabOrder = 10
                Width = 143
              end
              object lblSerieFactura: TcxLabel
                Left = 35
                Top = 154
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Serie Factura'
                Transparent = True
              end
              object btnCODIGO_CLIENTE: TcxDBButtonEdit
                Left = 159
                Top = 105
                DataBinding.DataField = 'CODIGO_CLIENTE_FACTURA'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 4
                Width = 104
              end
              object lblCodigoCliente: TcxLabel
                Left = 18
                Top = 109
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'C'#243'digo Cliente'
                Transparent = True
              end
              object cxdblblRAZONSOCIAL_EMPRESA_FACTURA: TcxDBLabel
                Left = 269
                Top = 60
                DataBinding.DataField = 'RAZONSOCIAL_EMPRESA_FACTURA'
                DataBinding.DataSource = dsTablaG
                Transparent = True
                Height = 21
                Width = 332
              end
              object cxdblblRAZONSOCIAL_CLIENTE_FACTURA: TcxDBLabel
                Left = 269
                Top = 109
                DataBinding.DataField = 'RAZONSOCIAL_CLIENTE_FACTURA'
                DataBinding.DataSource = dsTablaG
                ParentFont = False
                Style.StyleController = frmOpenApp2.EditStyleController
                Transparent = True
                Height = 21
                Width = 412
              end
              object btnCODIGO_EMPRESA_FACTURA: TcxDBButtonEdit
                Left = 155
                Top = 58
                DataBinding.DataField = 'CODIGO_EMPRESA_FACTURA'
                DataBinding.DataSource = dsTablaG
                Properties.Buttons = <
                  item
                    Default = True
                    Kind = bkEllipsis
                  end>
                TabOrder = 2
                Width = 104
              end
              object lblCodigoEmpresa: TcxLabel
                Left = 7
                Top = 62
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'C'#243'digo Empresa'
                ParentFont = False
                Style.StyleController = frmOpenApp2.EditStyleController
                Transparent = True
              end
              object txtNRO_FACTURA: TcxDBTextEdit
                Left = 155
                Top = 12
                DataBinding.DataField = 'NRO_FACTURA'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 0
                Width = 121
              end
              object cbbSerieFactura: TcxDBLookupComboBox
                Left = 155
                Top = 150
                BeepOnEnter = False
                DataBinding.DataField = 'SERIE_FACTURA'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsEditList
                Properties.ImmediateDropDownWhenKeyPressed = False
                Properties.IncrementalFiltering = False
                Properties.KeyFieldNames = 'SERIE_CONTADOR'
                Properties.ListColumns = <
                  item
                    Caption = 'Serie'
                    FieldName = 'SERIE_CONTADOR'
                  end>
                Properties.ListOptions.ColumnSorting = False
                Properties.ListOptions.ShowHeader = False
                Properties.ReadOnly = True
                TabOrder = 5
                Width = 145
              end
            end
            object tsEmpresa: TcxTabSheet
              Caption = 'Datos E&mpresa Emisora -'
              Color = clBtnFace
              ImageIndex = 2
              ParentColor = False
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxgrpbxEmpresa: TcxGroupBox
                Left = 22
                Top = 13
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Empresa'
                TabOrder = 0
                Height = 277
                Width = 770
                object txtDIRECCION1_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 14
                  Top = 55
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'DIRECCION1_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 328
                end
                object txtCPOSTAL_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 13
                  Top = 115
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'CPOSTAL_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 75
                end
                object txtPROVINCIA_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 114
                  Top = 169
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'PROVINCIA_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 228
                end
                object txtPAIS_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 177
                  Top = 202
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'NOMBRE_PAIS_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 165
                end
                object txtDIRECCION2_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 14
                  Top = 79
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'DIRECCION2_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 328
                end
                object lblProvinciaEmpresa: TcxLabel
                  Left = 23
                  Top = 173
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Provincia'
                  Transparent = True
                end
                object lblPaisEmpresa: TcxLabel
                  Left = 66
                  Top = 206
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Pa'#237's'
                  Transparent = True
                end
                object txtRAZONSOCIAL_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 14
                  Top = 22
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'RAZONSOCIAL_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 328
                end
                object txtNIF_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 505
                  Top = 29
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'NIF_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 247
                end
                object lblNIFEmpresa: TcxLabel
                  Left = 389
                  Top = 33
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'NIF Empresa'
                  ParentFont = False
                  Style.StyleController = frmOpenApp2.EditStyleController
                  Transparent = True
                end
                object lblMovilEmpresa: TcxLabel
                  Left = 369
                  Top = 66
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'M'#243'vil Empresa'
                  ParentFont = False
                  Style.StyleController = frmOpenApp2.EditStyleController
                  Transparent = True
                end
                object txtMOVIL_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 505
                  Top = 62
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'MOVIL_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 8
                  Width = 247
                end
                object txtEMAIL_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 505
                  Top = 95
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'EMAIL_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 9
                  Width = 247
                end
                object lblEmailEmpresa: TcxLabel
                  Left = 372
                  Top = 99
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Email Empresa'
                  ParentFont = False
                  Style.StyleController = frmOpenApp2.EditStyleController
                  Transparent = True
                end
                object chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxDBCheckBox
                  Left = 372
                  Top = 167
                  Caption = 'Empresa es agricultor/ganadero/pesca (S'#243'lo REAGP)'
                  DataBinding.DataField = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.MultiLine = True
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 16
                  Transparent = True
                  Width = 242
                end
                object chkRETENCION_EMPRESA_FACTURA: TcxDBCheckBox
                  Left = 372
                  Top = 138
                  Caption = 'Empresa practica retenci'#243'n en Factura'
                  DataBinding.DataField = 'ESRETENCIONES_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 14
                  Transparent = True
                end
                object cxdbmPOBLACION_EMPRESA_FACTURA: TcxDBMemo
                  Left = 91
                  Top = 115
                  DataBinding.DataField = 'POBLACION_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ScrollBars = ssVertical
                  TabOrder = 4
                  Height = 49
                  Width = 251
                end
                object cbbCanalIVA: TcxDBLookupComboBox
                  Left = 112
                  Top = 233
                  DataBinding.DataField = 'GRUPO_ZONA_IVA_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'GRUPO_ZONA_IVA'
                  Properties.ListColumns = <
                    item
                      Caption = 'Zona de IVA'
                      FieldName = 'DESCRIPCION_ZONA_IVA'
                    end>
                  Properties.ListOptions.ShowHeader = False
                  Properties.ReadOnly = True
                  TabOrder = 18
                  Width = 363
                end
                object lblCanalIVA: TcxLabel
                  Left = 20
                  Top = 237
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Canal IVA'
                  Transparent = True
                end
                object txtNOMBRE_PAIS_EMPRESA_FACTURA: TcxDBTextEdit
                  Left = 111
                  Top = 202
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'CODIGO_PAIS_EMPRESA_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 19
                  Width = 58
                end
              end
              object btnUpdateEmpresa: TcxButton
                Left = 799
                Top = 72
                Width = 142
                Height = 122
                Caption = 'Dar de Alta o &Actualizar Empresa'
                TabOrder = 1
                WordWrap = True
              end
              object btnIrAEmpresa: TcxButton
                Left = 799
                Top = 256
                Width = 142
                Height = 34
                Caption = 'I&r a Empresa'
                TabOrder = 2
              end
              object cxdblblCODIGO_EMPRESA_FACTURA: TcxDBLabel
                Left = 799
                Top = 23
                DataBinding.DataField = 'CODIGO_EMPRESA_FACTURA'
                DataBinding.DataSource = dsTablaG
                ParentFont = False
                Style.Font.Charset = ANSI_CHARSET
                Style.Font.Color = clPurple
                Style.Font.Height = -20
                Style.Font.Name = 'Lucida Sans'
                Style.Font.Style = []
                Style.IsFontAssigned = True
                Transparent = True
                Height = 26
                Width = 142
              end
            end
            object tsDatosCliente: TcxTabSheet
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Datos Cli&ente -'
              ImageIndex = 1
              object cxgrpbxCliente: TcxGroupBox
                Left = 22
                Top = 13
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Cliente'
                TabOrder = 0
                Height = 277
                Width = 763
                object txtDIRECCION1_CLIENTE_FACTURA1: TcxDBTextEdit
                  Left = 13
                  Top = 57
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'DIRECCION1_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 328
                end
                object txtCPOSTAL_CLIENTE_FACTURA1: TcxDBTextEdit
                  Left = 13
                  Top = 115
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'CPOSTAL_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 70
                end
                object txtPOBLACION_CLIENTE_FACTURA1: TcxDBTextEdit
                  Left = 92
                  Top = 114
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'POBLACION_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 247
                end
                object txtPROVINCIA_CLIENTE_FACTURA1: TcxDBTextEdit
                  Left = 113
                  Top = 147
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'PROVINCIA_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 228
                end
                object txtPAIS_CLIENTE_FACTURA1: TcxDBTextEdit
                  Left = 113
                  Top = 180
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'NOMBRE_PAIS_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 228
                end
                object txtDIRECCION2_CLIENTE_FACTURA1: TcxDBTextEdit
                  Left = 13
                  Top = 81
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'DIRECCION2_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 328
                end
                object lblcxlbl6: TcxLabel
                  Left = 26
                  Top = 148
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Provincia'
                  Transparent = True
                end
                object lblcxlbl13: TcxLabel
                  Left = 13
                  Top = 181
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Pa'#237's'
                  Transparent = True
                end
                object txtRAZONSOCIAL_CLIENTE_FACTURA: TcxDBTextEdit
                  Left = 13
                  Top = 26
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'RAZONSOCIAL_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 328
                end
                object txtNIF_CLIENTE_FACTURA: TcxDBTextEdit
                  Left = 464
                  Top = 26
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'NIF_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 289
                end
                object lblNif: TcxLabel
                  Left = 425
                  Top = 27
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'NIF'
                  Transparent = True
                end
                object lblTelefonoMovil: TcxLabel
                  Left = 359
                  Top = 59
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Tfno. M'#243'vil'
                  Transparent = True
                end
                object txtMOVIL_CLIENTE_FACTURA: TcxDBTextEdit
                  Left = 464
                  Top = 58
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'MOVIL_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 8
                  Width = 289
                end
                object txtEMAIL_CLIENTE_FACTURA: TcxDBTextEdit
                  Left = 464
                  Top = 91
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'EMAIL_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 9
                  Width = 289
                end
                object lblEmail: TcxLabel
                  Left = 407
                  Top = 92
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Email'
                  Transparent = True
                end
                object chkESIVA_RECARGO_CLIENTE_FACTURA: TcxDBCheckBox
                  Left = 378
                  Top = 151
                  Caption = 'Aplicar Recargo de Equivalencia'
                  DataBinding.DataField = 'ESIVA_RECARGO_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 16
                  Transparent = True
                end
                object chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxDBCheckBox
                  Left = 378
                  Top = 177
                  Caption = 'Cliente es agricultor/ganadero/pesca'
                  DataBinding.DataField = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 17
                  Transparent = True
                end
                object chkRETENCIONES_EMPRESA_FACTURA3: TcxDBCheckBox
                  Left = 378
                  Top = 124
                  Caption = 'Aplicar IRPF (Es profesional)'
                  DataBinding.DataField = 'ESRETENCIONES_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 15
                  Transparent = True
                end
                object chkEXTRANJERO: TcxDBCheckBox
                  Left = 13
                  Top = 217
                  Caption = 'IVA Exento'
                  DataBinding.DataField = 'ESIVA_EXENTO_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayUnchecked = 'True'
                  Properties.DisplayGrayed = 'False'
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 18
                  Transparent = True
                end
                object cbbTARIFA_ARTICULOS_CLIENTES: TcxDBLookupComboBox
                  Left = 547
                  Top = 207
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'TARIFA_ARTICULO_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'CODIGO_TARIFA'
                  Properties.ListColumns = <
                    item
                      FieldName = 'NOMBRE_TARIFA'
                    end>
                  Properties.ListOptions.ShowHeader = False
                  Properties.ReadOnly = True
                  TabOrder = 21
                  Width = 205
                end
                object lblTarifaArticulosCliente: TcxLabel
                  Left = 407
                  Top = 211
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Tarifa Art'#237'culos'
                  Style.BorderStyle = ebsNone
                  Transparent = True
                end
                object chkIVA_EXENTO_CLIENTE_FACTURA: TcxDBCheckBox
                  Left = 132
                  Top = 217
                  Caption = 'Cliente intracomunitario'
                  DataBinding.DataField = 'ESINTRACOMUNITARIO_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayUnchecked = 'True'
                  Properties.DisplayGrayed = 'False'
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 19
                  Transparent = True
                end
                object chkImpIncl: TcxDBCheckBox
                  Left = 407
                  Top = 242
                  Caption = 'Precios Venta con Impuestos Incluidos'
                  DataBinding.DataField = 'ESIMP_INCL_TARIFA_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayUnchecked = 'True'
                  Properties.DisplayGrayed = 'False'
                  Properties.ReadOnly = True
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 22
                  Transparent = True
                end
                object txtCODIGO_PAIS_CLIENTE_FACTURA: TcxDBTextEdit
                  Left = 57
                  Top = 179
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'CODIGO_PAIS_CLIENTE_FACTURA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 23
                  Width = 54
                end
              end
              object btnUpdateCliente: TcxButton
                Left = 792
                Top = 72
                Width = 142
                Height = 122
                Caption = 'Dar de Alta o &Actualizar Cliente'
                TabOrder = 1
                WordWrap = True
              end
              object btnIrACliente: TcxButton
                Left = 792
                Top = 256
                Width = 142
                Height = 34
                Caption = 'I&r a Cliente'
                TabOrder = 2
              end
              object cxdblblCODIGO_CLIENTE_FACTURA: TcxDBLabel
                Left = 803
                Top = 23
                DataBinding.DataField = 'CODIGO_CLIENTE_FACTURA'
                DataBinding.DataSource = dsTablaG
                ParentFont = False
                Style.Font.Charset = ANSI_CHARSET
                Style.Font.Color = clWindowText
                Style.Font.Height = -20
                Style.Font.Name = 'Lucida Sans'
                Style.Font.Style = []
                Style.TextColor = clPurple
                Style.IsFontAssigned = True
                Transparent = True
                Height = 27
                Width = 131
              end
            end
          end
        end
        object pcPedido: TcxPageControl
          Left = 0
          Top = 241
          Width = 937
          Height = 450
          Align = alClient
          TabOrder = 1
          Properties.ActivePage = tsLineasPedido
          Properties.CustomButtons.Buttons = <>
          ExplicitWidth = 852
          ClientRectBottom = 446
          ClientRectLeft = 4
          ClientRectRight = 933
          ClientRectTop = 30
          object tsLineasPedido: TcxTabSheet
            Caption = 'L'#237'neas de Pedido'
            ImageIndex = 1
            ExplicitLeft = 0
            ExplicitTop = 0
            ExplicitWidth = 844
            ExplicitHeight = 0
            object cxGrdPedidosLineas: TcxGrid
              Left = 0
              Top = 0
              Width = 929
              Height = 416
              Align = alClient
              TabOrder = 0
              ExplicitWidth = 844
              ExplicitHeight = 346
              object tvPedidosLineas: TcxGridDBTableView
                Navigator.Buttons.CustomButtons = <>
                ScrollbarAnnotations.CustomAnnotations = <>
                DataController.Summary.DefaultGroupSummaryItems = <>
                DataController.Summary.FooterSummaryItems = <>
                DataController.Summary.SummaryGroups = <>
              end
              object cxGrdPedidosLineasLevel1: TcxGridLevel
                GridView = tvPedidosLineas
              end
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 937
        ExplicitHeight = 691
        inherited pnlPerfilTop: TPanel
          Width = 937
          ExplicitWidth = 937
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 21
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 937
          Height = 634
          ExplicitWidth = 852
          ExplicitHeight = 634
          inherited cxgrdPerfil: TcxGrid
            Width = 937
            Height = 634
            ExplicitWidth = 852
            ExplicitHeight = 634
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 945
      ExplicitWidth = 945
      inherited pnlTopGrid: TPanel
        Width = 945
        ExplicitWidth = 945
        inherited sbExportExcel: TSpeedButton
          Left = 815
          Top = 9
          ExplicitLeft = 815
          ExplicitTop = 9
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 350
          ExplicitWidth = 350
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 945
    Height = 765
    ExplicitLeft = 945
    ExplicitHeight = 765
    inherited pButtonGen: TPanel
      Top = 567
      ExplicitTop = 567
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 544
    Top = 8
  end
  inherited dsTablaG: TDataSource
    Left = 632
    Top = 8
  end
end
