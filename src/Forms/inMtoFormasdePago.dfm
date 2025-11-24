inherited frmMtoFormasdePago: TfrmMtoFormasdePago
  Left = 5
  Top = 4
  Caption = 'Formas de pago'
  ClientHeight = 674
  ClientWidth = 894
  ExplicitWidth = 894
  ExplicitHeight = 674
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 754
    Height = 674
    TabOrder = 0
    ExplicitWidth = 754
    ExplicitHeight = 674
    inherited pcPantalla: TcxPageControl
      Width = 754
      Height = 634
      TabOrder = 1
      Properties.ActivePage = tsFicha
      ExplicitWidth = 754
      ExplicitHeight = 634
      ClientRectBottom = 630
      ClientRectRight = 750
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 3
        ExplicitTop = 32
        ExplicitWidth = 745
        ExplicitHeight = 596
        inherited cxGrdPrincipal: TcxGrid
          Width = 745
          Height = 596
          ExplicitWidth = 745
          ExplicitHeight = 596
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxGrdDBTabPrinCODIGO_FORMAPAGO: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_FORMAPAGO'
              Width = 196
            end
            object cxGrdDBTabPrinACTIVO_FORMAPAGO: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ACTIVO_FORMAPAGO'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 91
            end
            object cxGrdDBTabPrinORDEN_FORMAPAGO: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_FORMAPAGO'
              Width = 120
            end
            object cxGrdDBTabPrinDESCRIPCION_FORMAPAGO: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_FORMAPAGO'
              Width = 231
            end
            object cxGrdDBTabPrinN_PLAZOS_FORMAPAGO: TcxGridDBColumn
              Caption = 'N'#250'mero de Plazos'
              DataBinding.FieldName = 'N_PLAZOS_FORMAPAGO'
              Width = 169
            end
            object cxGrdDBTabPrinDIAS_ENTRE_PLAZOS_FORMAPAGO: TcxGridDBColumn
              Caption = 'D'#237'as entre plazos'
              DataBinding.FieldName = 'N_DIAS_ENTRE_PLAZOS_FORMAPAGO'
              Width = 165
            end
            object cxGrdDBTabPrinDEFAULT_FORMAPAGO: TcxGridDBColumn
              Caption = 'Por defecto'
              DataBinding.FieldName = 'ESDEFAULT_FORMAPAGO'
              Width = 159
            end
            object cxGrdDBTabPrinPORCEN_ANTICIPO_FORMAPAGO: TcxGridDBColumn
              Caption = '% Anticipo'
              DataBinding.FieldName = 'PORCEN_ANTICIPO_FORMAPAGO'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Properties.ValueType = vtFloat
              Width = 92
            end
            object cxGrdDBTabPrinESVERBANCOEMPRESA_FORMAPAGO: TcxGridDBColumn
              Caption = 'Ver Banco Empresa Factura'
              DataBinding.FieldName = 'ESVERBANCOEMPRESA_FORMAPAGO'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 233
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTEMODIF'
              Visible = False
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTEALTA'
              Visible = False
            end
            object cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIOALTA'
              Visible = False
            end
            object cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIOMODIF'
              Visible = False
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 746
        ExplicitHeight = 600
        object pnl1: TPanel
          Left = 0
          Top = 0
          Width = 746
          Height = 113
          Align = alTop
          TabOrder = 0
          object cxdbtxtdt1: TcxDBTextEdit
            Left = 104
            Top = 33
            DataBinding.DataField = 'CODIGO'
            DataBinding.DataSource = dsTablaG
            Enabled = False
            TabOrder = 1
            Width = 121
          end
          object cxdbtxtdt2: TcxDBTextEdit
            Left = 104
            Top = 61
            DataBinding.DataField = 'DESCRIPCION'
            DataBinding.DataSource = dsTablaG
            TabOrder = 2
            Width = 241
          end
          object cxdbtxtdt15: TcxDBTextEdit
            Left = 856
            Top = 89
            DataBinding.DataField = 'modificado'
            DataBinding.DataSource = dsTablaG
            TabOrder = 3
            Width = 57
          end
          object Panel1: TPanel
            Left = 1
            Top = 1
            Width = 744
            Height = 111
            Align = alClient
            TabOrder = 0
            object txtCODIGO_FORMAPAGO: TcxDBTextEdit
              Left = 101
              Top = 13
              DataBinding.DataField = 'CODIGO_FORMAPAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = False
              TabOrder = 0
              Width = 156
            end
            object lblCodigo: TcxLabel
              Left = 21
              Top = 17
              Caption = 'C'#243'digo'
              Transparent = True
            end
            object lblNombre: TcxLabel
              Left = 18
              Top = 51
              Caption = 'Nombre'
              Transparent = True
            end
            object txtNOMBRE_FORMAPAGO: TcxDBTextEdit
              Left = 100
              Top = 48
              DataBinding.DataField = 'DESCRIPCION_FORMAPAGO'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 429
            end
            object chkActivo: TcxDBCheckBox
              Left = 79
              Top = 78
              Caption = 'Activo'
              DataBinding.DataField = 'ACTIVO_FORMAPAGO'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 4
              Transparent = True
            end
          end
        end
        object pnl2: TPanel
          Left = 0
          Top = 121
          Width = 746
          Height = 479
          Align = alClient
          TabOrder = 1
          object pcPestana: TcxPageControl
            Left = 1
            Top = 1
            Width = 744
            Height = 477
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsMasDatos
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 473
            ClientRectLeft = 4
            ClientRectRight = 740
            ClientRectTop = 30
            object tsMasDatos: TcxTabSheet
              Caption = '&1_M'#225's Datos-'
              ImageIndex = 0
              object cxLabel1: TcxLabel
                Left = 28
                Top = 32
                Caption = 'N'#250'mero de plazos'
                Transparent = True
              end
              object cxDBSpinEdit1: TcxDBSpinEdit
                Left = 191
                Top = 31
                DataBinding.DataField = 'N_PLAZOS_FORMAPAGO'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 106
              end
              object cxLabel2: TcxLabel
                Left = 28
                Top = 88
                Caption = 'D'#237'as entre plazos'
                Transparent = True
              end
              object cxDBSpinEdit2: TcxDBSpinEdit
                Left = 191
                Top = 87
                DataBinding.DataField = 'N_DIAS_ENTRE_PLAZOS_FORMAPAGO'
                DataBinding.DataSource = dsTablaG
                TabOrder = 3
                Width = 106
              end
              object cxLabel3: TcxLabel
                Left = 79
                Top = 135
                Caption = '% Adelanto'
                Transparent = True
              end
              object cxDBSpinEdit3: TcxDBSpinEdit
                Left = 191
                Top = 135
                DataBinding.DataField = 'PORCEN_ANTICIPO_FORMAPAGO'
                DataBinding.DataSource = dsTablaG
                Properties.AssignedValues.MinValue = True
                Properties.DisplayFormat = '0.00 %'
                Properties.EditFormat = '0.00 %'
                Properties.MaxValue = 100.000000000000000000
                TabOrder = 5
                Width = 106
              end
              object cxDBCheckBox1: TcxDBCheckBox
                Left = 76
                Top = 198
                Caption = 'Ver Banco Empresa en Factura'
                DataBinding.DataField = 'ESVERBANCOEMPRESA_FORMAPAGO'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                Style.TransparentBorder = False
                TabOrder = 6
                Transparent = True
              end
            end
            object tsVentas: TcxTabSheet
              Caption = '&2_Ventas-'
              ImageIndex = 2
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object pnlFactura: TPanel
                Left = 0
                Top = 0
                Width = 734
                Height = 439
                Align = alClient
                TabOrder = 0
                object cxgrdFacturas: TcxGrid
                  Left = 1
                  Top = 1
                  Width = 615
                  Height = 437
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvFacturacion: TcxGridDBTableView
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Buttons.CustomButtons = <>
                    Navigator.Visible = True
                    ScrollbarAnnotations.CustomAnnotations = <>
                    DataController.DataModeController.SmartRefresh = True
                    DataController.DataSource = dmFormasdePago.dsFacturas
                    DataController.Summary.DefaultGroupSummaryItems = <
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_LIQUIDO_FACTURA
                      end
                      item
                        Format = '0,00 '#8364';-0,00 '#8364
                        Position = spFooter
                        Column = tvFacturacionTOTAL_LIQUIDO_FACTURA
                      end>
                    DataController.Summary.FooterSummaryItems = <
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_LIQUIDO_FACTURA
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_BASES_FACTURA
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_RETENCION_FACTURA
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_IMPUESTOS_FACTURA
                      end>
                    DataController.Summary.SummaryGroups = <>
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsCustomize.ColumnGrouping = False
                    OptionsData.Deleting = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsSelection.InvertSelect = False
                    OptionsView.NoDataToDisplayInfoText = '<No hay datos a mostrar>'
                    OptionsView.Footer = True
                    OptionsView.GroupByBox = False
                    OptionsView.GroupFooters = gfAlwaysVisible
                    object tvFacturacionFECHA_FACTURA: TcxGridDBColumn
                      Caption = 'Fecha'
                      DataBinding.FieldName = 'FECHA_FACTURA'
                    end
                    object tvFacturacionNRO_FACTURA: TcxGridDBColumn
                      Caption = 'Nro'
                      DataBinding.FieldName = 'NRO_FACTURA'
                    end
                    object tvFacturacionSERIE_FACTURA: TcxGridDBColumn
                      Caption = 'Serie'
                      DataBinding.FieldName = 'SERIE_FACTURA'
                    end
                    object tvFacturacionTOTAL_LIQUIDO_FACTURA: TcxGridDBColumn
                      Caption = 'Total a pagar'
                      DataBinding.FieldName = 'TOTAL_LIQUIDO_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 129
                    end
                    object tvFacturacionTOTAL_BASES_FACTURA: TcxGridDBColumn
                      Caption = 'Total Bases Imp'
                      DataBinding.FieldName = 'TOTAL_BASES_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 104
                    end
                    object tvFacturacionPORCEN_RETENCION_FACTURA: TcxGridDBColumn
                      Caption = '% IRPF'
                      DataBinding.FieldName = 'PORCEN_RETENCION_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                    end
                    object tvFacturacionTOTAL_RETENCION_FACTURA: TcxGridDBColumn
                      Caption = 'IRPF'
                      DataBinding.FieldName = 'TOTAL_RETENCION_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                    end
                    object tvFacturacionTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn
                      Caption = 'IVA + RE'
                      DataBinding.FieldName = 'TOTAL_IMPUESTOS_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 87
                    end
                    object tvFacturacionFORMA_PAGO_FACTURA: TcxGridDBColumn
                      Caption = 'Forma Pago'
                      DataBinding.FieldName = 'FORMA_PAGO_FACTURA'
                      Width = 110
                    end
                    object tvFacturacionDESCRIPCION_FORMAPAGO: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Forma de Pago'
                      DataBinding.FieldName = 'DESCRIPCION_FORMAPAGO'
                      Width = 234
                    end
                    object tvFacturacionCODIGO_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'C'#243'digo Empresa'
                      DataBinding.FieldName = 'CODIGO_EMPRESA_FACTURA'
                      Width = 154
                    end
                    object tvFacturacionRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Raz'#243'n Social Empresa'
                      DataBinding.FieldName = 'RAZONSOCIAL_EMPRESA_FACTURA'
                      Width = 188
                    end
                    object tvFacturacionNIF_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Nif Empresa'
                      DataBinding.FieldName = 'NIF_EMPRESA_FACTURA'
                      Width = 181
                    end
                    object tvFacturacionMOVIL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'M'#243'vil Empresa'
                      DataBinding.FieldName = 'MOVIL_EMPRESA_FACTURA'
                      Width = 241
                    end
                    object tvFacturacionEMAIL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Email Empresa'
                      DataBinding.FieldName = 'EMAIL_EMPRESA_FACTURA'
                      Width = 223
                    end
                    object tvFacturacionDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n1 Empresa'
                      DataBinding.FieldName = 'DIRECCION1_EMPRESA_FACTURA'
                      Width = 277
                    end
                    object tvFacturacionDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n2 Empresa'
                      DataBinding.FieldName = 'DIRECCION2_EMPRESA_FACTURA'
                      Width = 277
                    end
                    object tvFacturacionCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'CPostal Empresa'
                      DataBinding.FieldName = 'CPOSTAL_EMPRESA_FACTURA'
                    end
                    object tvFacturacionPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Poblaci'#243'n Empresa'
                      DataBinding.FieldName = 'POBLACION_EMPRESA_FACTURA'
                      Width = 269
                    end
                    object tvFacturacionPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Provincia Empresa'
                      DataBinding.FieldName = 'PROVINCIA_EMPRESA_FACTURA'
                      Width = 264
                    end
                    object tvFacturacionPAIS_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Pa'#237's Empresa'
                      DataBinding.FieldName = 'PAIS_EMPRESA_FACTURA'
                      Width = 208
                    end
                    object tvFacturacionESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESRETENCIONES_EMPRESA_FACTURA'
                    end
                    object tvFacturacionCODIGO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'C'#243'digo Cliente'
                      DataBinding.FieldName = 'CODIGO_CLIENTE_FACTURA'
                      Width = 131
                    end
                    object tvFacturacionRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Raz'#243'n Social Cliente'
                      DataBinding.FieldName = 'RAZONSOCIAL_CLIENTE_FACTURA'
                      Width = 177
                    end
                    object tvFacturacionNIF_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Nif Cliente'
                      DataBinding.FieldName = 'NIF_CLIENTE_FACTURA'
                      Width = 106
                    end
                    object tvFacturacionMOVIL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'M'#243'vil Cliente'
                      DataBinding.FieldName = 'MOVIL_CLIENTE_FACTURA'
                      Width = 115
                    end
                    object tvFacturacionEMAIL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Email Cliente'
                      DataBinding.FieldName = 'EMAIL_CLIENTE_FACTURA'
                      Width = 114
                    end
                    object tvFacturacionDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n1 Cliente'
                      DataBinding.FieldName = 'DIRECCION1_CLIENTE_FACTURA'
                      Width = 161
                    end
                    object tvFacturacionDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n2 Cliente'
                      DataBinding.FieldName = 'DIRECCION2_CLIENTE_FACTURA'
                      Width = 173
                    end
                    object tvFacturacionCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'CPostal Cliente'
                      DataBinding.FieldName = 'CPOSTAL_CLIENTE_FACTURA'
                      Width = 133
                    end
                    object tvFacturacionPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Poblaci'#243'n Cliente'
                      DataBinding.FieldName = 'POBLACION_CLIENTE_FACTURA'
                      Width = 164
                    end
                    object tvFacturacionPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Provincia Cliente'
                      DataBinding.FieldName = 'PROVINCIA_CLIENTE_FACTURA'
                      Width = 146
                    end
                    object tvFacturacionPAIS_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Pa'#237's Cliente'
                      DataBinding.FieldName = 'PAIS_CLIENTE_FACTURA'
                      Width = 103
                    end
                    object tvFacturacionNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn
                      Caption = 'Tarifa Cliente'
                      DataBinding.FieldName = 'NOMBRE_TARIFA_CLIENTE'
                      Width = 118
                    end
                    object tvFacturacionESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tiene RE Cliente'
                      DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 141
                    end
                    object tvFacturacionESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tiene IVA Exento Cliente'
                      DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 212
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Cliente es REAGP'
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 147
                    end
                    object tvFacturacionESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tiene IRPF Cliente'
                      DataBinding.FieldName = 'ESRETENCIONES_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 155
                    end
                    object tvFacturacionESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tarifa Cliente imp incl'
                      DataBinding.FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_FACTURA'
                      Visible = False
                      Width = 189
                    end
                    object tvFacturacionESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Cliente Intracomunitario'
                      DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 212
                    end
                    object tvFacturacionESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Visible = False
                    end
                    object tvFacturacionESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESAPLICA_RE_ZONA_IVA_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Visible = False
                    end
                    object tvFacturacionESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVAAGRICOLA_ZONA_IVA_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Visible = False
                    end
                    object tvFacturacionPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PALABRA_REPORTS_ZONA_IVA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionDESCRIPCION_ZONA_IVA: TcxGridDBColumn
                      DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA'
                      Visible = False
                    end
                    object tvFacturacionESVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESVENTA_ACTIVO_FIJO_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Visible = False
                    end
                    object tvFacturacionPORCEN_IVAN_FACTURA: TcxGridDBColumn
                      Caption = '% IVA Normal'
                      DataBinding.FieldName = 'PORCEN_IVAN_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 115
                    end
                    object tvFacturacionTOTAL_IVAN_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Normal'
                      DataBinding.FieldName = 'TOTAL_IVAN_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 111
                    end
                    object tvFacturacionPORCEN_REN_FACTURA: TcxGridDBColumn
                      Caption = '%  RE Normal'
                      DataBinding.FieldName = 'PORCEN_REN_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 124
                    end
                    object tvFacturacionTOTAL_REN_FACTURA: TcxGridDBColumn
                      Caption = 'RE Normal'
                      DataBinding.FieldName = 'TOTAL_REN_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 91
                    end
                    object tvFacturacionTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imp Normal'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAN_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 158
                    end
                    object tvFacturacionPORCEN_IVAR_FACTURA: TcxGridDBColumn
                      Caption = '% IVA Reducido'
                      DataBinding.FieldName = 'PORCEN_IVAR_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 133
                    end
                    object tvFacturacionTOTAL_IVAR_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Reducido'
                      DataBinding.FieldName = 'TOTAL_IVAR_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 117
                    end
                    object tvFacturacionPORCEN_RER_FACTURA: TcxGridDBColumn
                      Caption = '% RE Reducido'
                      DataBinding.FieldName = 'PORCEN_RER_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 137
                    end
                    object tvFacturacionTOTAL_RER_FACTURA: TcxGridDBColumn
                      Caption = 'RE Reducido'
                      DataBinding.FieldName = 'TOTAL_RER_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 121
                    end
                    object tvFacturacionTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imp Reducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAR_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 164
                    end
                    object tvFacturacionPORCEN_IVAS_FACTURA: TcxGridDBColumn
                      Caption = '% IVA S'#250'perReducido'
                      DataBinding.FieldName = 'PORCEN_IVAS_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 181
                    end
                    object tvFacturacionTOTAL_IVAS_FACTURA: TcxGridDBColumn
                      Caption = 'Total IVAS'
                      DataBinding.FieldName = 'TOTAL_IVAS_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 90
                    end
                    object tvFacturacionPORCEN_RES_FACTURA: TcxGridDBColumn
                      Caption = '%RE SuperReducido'
                      DataBinding.FieldName = 'PORCEN_RES_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 168
                    end
                    object tvFacturacionTOTAL_RES_FACTURA: TcxGridDBColumn
                      Caption = 'RE S'#250'perReducido'
                      DataBinding.FieldName = 'TOTAL_RES_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 157
                    end
                    object tvFacturacionTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imp S'#250'perReducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAS_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 212
                    end
                    object tvFacturacionPORCEN_IVAE_FACTURA: TcxGridDBColumn
                      Caption = '% IVA Exento'
                      DataBinding.FieldName = 'PORCEN_IVAE_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 112
                    end
                    object tvFacturacionTOTAL_IVAE_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Exento'
                      DataBinding.FieldName = 'TOTAL_IVAE_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 108
                    end
                    object tvFacturacionPORCEN_REE_FACTURA: TcxGridDBColumn
                      Caption = '%RE Exento'
                      DataBinding.FieldName = 'PORCEN_REE_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 99
                    end
                    object tvFacturacionTOTAL_REE_FACTURA: TcxGridDBColumn
                      Caption = 'RE Exento'
                      DataBinding.FieldName = 'TOTAL_REE_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 100
                    end
                    object tvFacturacionTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imp Exento'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAE_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 143
                    end
                    object tvFacturacionDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA_EMPRESA_FACTURA'
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                    end
                    object tvFacturacionGRUPO_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'GRUPO_ZONA_IVA_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionTARIFA_ARTICULO_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'TARIFA_ARTICULO_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionCODIGO_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_IVA_FACTURA'
                      Visible = False
                    end
                  end
                  object tvLineasFacturacion: TcxGridDBTableView
                    Navigator.Buttons.CustomButtons = <>
                    ScrollbarAnnotations.CustomAnnotations = <>
                    DataController.DataSource = dmFormasdePago.dsFacturasLineas
                    DataController.DetailKeyFieldNames = 'NRO_FACTURA_LINEA; SERIE_FACTURA_LINEA'
                    DataController.KeyFieldNames = 'LINEA_FACTURA_LINEA'
                    DataController.MasterKeyFieldNames = 'NRO_FACTURA; SERIE_FACTURA'
                    DataController.Summary.DefaultGroupSummaryItems = <>
                    DataController.Summary.FooterSummaryItems = <>
                    DataController.Summary.SummaryGroups = <>
                    OptionsBehavior.ColumnHeaderHints = False
                    OptionsCustomize.ColumnFiltering = False
                    OptionsCustomize.ColumnGrouping = False
                    OptionsCustomize.ColumnMoving = False
                    OptionsCustomize.ColumnsQuickCustomizationShowCommands = False
                    OptionsData.Deleting = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA: TcxGridDBColumn
                      Caption = 'Nro Linea'
                      DataBinding.FieldName = 'LINEA_FACTURA_LINEA'
                      Width = 28
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ARTICULO_FACTURA_LINEA'
                      Width = 164
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Descripci'#243'n'
                      DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACTURA_LINEA'
                      Width = 162
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_FACTURA_LINEA'
                      Width = 84
                    end
                    object tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Tipo Cantidad'
                      DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA'
                      Width = 64
                    end
                    object tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Precio SIVA'
                      DataBinding.FieldName = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 64
                    end
                    object tvLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Porcentaje IVA'
                      DataBinding.FieldName = 'PORCEN_IVA_FACTURA_LINEA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 127
                    end
                    object tvLineasFacturacionNOMBRE_TIPO_IVA: TcxGridDBColumn
                      Caption = 'Tipo IVA'
                      DataBinding.FieldName = 'NOMBRE_TIPO_IVA'
                      Width = 64
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Precio CIVA'
                      DataBinding.FieldName = 'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 84
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA: TcxGridDBColumn
                      Caption = 'Total'
                      DataBinding.FieldName = 'TOTAL_FACTURA_LINEA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 84
                    end
                    object tvLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Fecha de Entrega'
                      DataBinding.FieldName = 'FECHA_ENTREGA_FACTURA_LINEA'
                      PropertiesClassName = 'TcxDateEditProperties'
                      Width = 64
                    end
                  end
                  object cxgrdlvlcxgrd1Level1: TcxGridLevel
                    GridView = tvFacturacion
                    object cxgrdlvlcxgrd1Level2: TcxGridLevel
                      GridView = tvLineasFacturacion
                    end
                  end
                end
                object pnlFacturaOpts: TPanel
                  Left = 616
                  Top = 1
                  Width = 117
                  Height = 437
                  Align = alRight
                  TabOrder = 1
                  object btnIraFactura: TcxButton
                    Left = 6
                    Top = 16
                    Width = 109
                    Height = 34
                    Caption = '&Ir a Factura'
                    TabOrder = 0
                    OnClick = btnIraFacturaClick
                  end
                  object btnIraCliente: TcxButton
                    Left = 7
                    Top = 56
                    Width = 108
                    Height = 34
                    Caption = 'I&r a Cliente'
                    TabOrder = 1
                    OnClick = btnIraClienteClick
                  end
                  object btExportarExcel: TcxButton
                    Left = 7
                    Top = 176
                    Width = 108
                    Height = 34
                    Caption = 'Exp. Excel'
                    TabOrder = 2
                    OnClick = btExportarExcelClick
                  end
                  object btnIraEmpresa: TcxButton
                    Left = 7
                    Top = 96
                    Width = 108
                    Height = 34
                    Caption = 'I&r a Empresa'
                    TabOrder = 3
                    OnClick = btnIraEmpresaClick
                  end
                  object btnIraArticulo: TcxButton
                    Left = 7
                    Top = 136
                    Width = 108
                    Height = 34
                    Caption = 'I&r a Art'#237'culo'
                    TabOrder = 4
                    OnClick = btnIraArticuloClick
                  end
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&3_Otros-'
              ImageIndex = 3
              object pnl3: TPanel
                Left = 0
                Top = 364
                Width = 736
                Height = 79
                Align = alBottom
                TabOrder = 0
                object cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit
                  Left = 17
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIOALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 2
                  Width = 136
                end
                object lblUsuarioAlta: TcxLabel
                  Left = 17
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario Alta'
                  Transparent = True
                end
                object lblInstanteAlta: TcxLabel
                  Left = 160
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Alta'
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA: TcxDBTextEdit
                  Left = 160
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTEALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 195
                end
                object cxdbtxtdtINSTANTEALTA: TcxDBTextEdit
                  Left = 514
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTEMODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 201
                end
                object lblInstanteModif: TcxLabel
                  Left = 514
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Modif.'
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit
                  Left = 364
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIOALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 136
                end
                object lblUsuarioModif: TcxLabel
                  Left = 364
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario '#218'lt. Modif'
                  Transparent = True
                end
              end
              object lblOrden: TcxLabel
                Left = 20
                Top = 24
                Caption = 'Orden en Listados'
                Transparent = True
              end
              object cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit
                Left = 179
                Top = 23
                DataBinding.DataField = 'ORDEN_FORMAPAGO'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 106
              end
            end
          end
        end
        object cxspltr1: TcxSplitter
          Left = 0
          Top = 113
          Width = 746
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnl1
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 746
        ExplicitHeight = 600
        inherited pnlPerfilTop: TPanel
          Width = 746
          ExplicitWidth = 746
        end
        inherited pnlPerfilDetail: TPanel
          Width = 746
          Height = 543
          ExplicitWidth = 745
          ExplicitHeight = 539
          inherited cxgrdPerfil: TcxGrid
            Width = 745
            Height = 539
            ExplicitWidth = 745
            ExplicitHeight = 539
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 754
      TabOrder = 0
      ExplicitWidth = 754
      inherited pnlTopGrid: TPanel
        Width = 754
        ExplicitWidth = 754
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 754
    Height = 674
    TabOrder = 1
    ExplicitLeft = 754
    ExplicitHeight = 674
    inherited pButtonGen: TPanel
      Top = 476
      ExplicitTop = 476
    end
  end
  inherited dsTablaG: TDataSource
    Left = 612
    Top = 559
  end
  object ActionListFormasdePAgo: TActionList
    Left = 440
    Top = 304
    object actClientes: TAction
      Caption = 'Clientes'
      ShortCut = 16459
      OnExecute = actClientesExecute
    end
    object actArticulos: TAction
      Caption = 'actArticulos'
      ShortCut = 16449
      OnExecute = actArticulosExecute
    end
    object actFacturas: TAction
      Caption = 'actFacturas'
      ShortCut = 16454
      OnExecute = actFacturasExecute
    end
    object actEmpresas: TAction
      Caption = 'Empresas'
      ShortCut = 16453
      OnExecute = actEmpresasExecute
    end
  end
end
