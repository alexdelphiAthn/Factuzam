inherited frmMtoEmpresas: TfrmMtoEmpresas
  Left = 5
  Top = 4
  Margins.Left = 0
  Margins.Top = 0
  Margins.Right = 0
  Margins.Bottom = 0
  Caption = 'Empresas'
  ClientHeight = 715
  ClientWidth = 1085
  ExplicitWidth = 1085
  ExplicitHeight = 715
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 945
    Height = 715
    TabOrder = 0
    ExplicitWidth = 945
    ExplicitHeight = 715
    inherited pcPantalla: TcxPageControl
      Width = 945
      Height = 675
      TabOrder = 1
      Properties.ActivePage = tsLista
      ExplicitWidth = 945
      ExplicitHeight = 675
      ClientRectBottom = 671
      ClientRectRight = 941
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 937
        ExplicitHeight = 641
        inherited cxGrdPrincipal: TcxGrid
          Width = 937
          Height = 641
          ExplicitWidth = 937
          ExplicitHeight = 641
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_EMPRESA: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_EMPRESA'
              Width = 79
            end
            object cxgrdbclmnGrdDBTabPrinORDEN_EMPRESA: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_EMPRESA'
              Width = 70
            end
            object cxgrdbclmnGrdDBTabPrinACTIVA_EMPRESA: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ACTIVO_EMPRESA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 71
            end
            object cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_EMPRESA: TcxGridDBColumn
              Caption = 'Raz'#243'n Social'
              DataBinding.FieldName = 'RAZONSOCIAL_EMPRESA'
              Width = 186
            end
            object cxgrdbclmnGrdDBTabPrinNIF_EMPRESA: TcxGridDBColumn
              Caption = 'Nif'
              DataBinding.FieldName = 'NIF_EMPRESA'
              Width = 91
            end
            object cxgrdbclmnGrdDBTabPrinMOVIL_EMPRESA: TcxGridDBColumn
              Caption = 'M'#243'vil'
              DataBinding.FieldName = 'MOVIL_EMPRESA'
              Width = 115
            end
            object cxgrdbclmnGrdDBTabPrinEMAIL_EMPRESA: TcxGridDBColumn
              Caption = 'Email'
              DataBinding.FieldName = 'EMAIL_EMPRESA'
              Width = 189
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION1_EMPRESA: TcxGridDBColumn
              Caption = 'Direci'#243'n'
              DataBinding.FieldName = 'DIRECCION1_EMPRESA'
              Width = 146
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION2_EMPRESA: TcxGridDBColumn
              Caption = 'M'#225's Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION2_EMPRESA'
              Width = 138
            end
            object cxgrdbclmnGrdDBTabPrinPOBLACION_EMPRESA: TcxGridDBColumn
              Caption = 'Poblaci'#243'n'
              DataBinding.FieldName = 'POBLACION_EMPRESA'
              Width = 132
            end
            object cxgrdbclmnGrdDBTabPrinPROVINCIA_EMPRESA: TcxGridDBColumn
              Caption = 'Provincia'
              DataBinding.FieldName = 'PROVINCIA_EMPRESA'
              Width = 113
            end
            object cxgrdbclmnGrdDBTabPrinCPOSTAL_EMPRESA: TcxGridDBColumn
              Caption = 'C'#243'digo Postal'
              DataBinding.FieldName = 'CPOSTAL_EMPRESA'
              Width = 138
            end
            object cxGrdDBTabPrinDESCRIPCION_ZONA_IVA: TcxGridDBColumn
              Caption = 'Zona de IVA principal'
              DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA'
              Width = 302
            end
            object cxgrdbclmnGrdDBTabPrin_ESREGIMENESPECIALAGRICOLA_EMPRESA: TcxGridDBColumn
              Caption = 'Es REAGP'
              DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 86
            end
            object cxgrdbclmnGrdDBTabPrinESRETENCIONES_EMPRESA: TcxGridDBColumn
              Caption = 'Aplica Retenciones'
              DataBinding.FieldName = 'ESRETENCIONES_EMPRESA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 170
            end
            object cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_EMPRESA: TcxGridDBColumn
              Caption = 'Texto en Factura'
              DataBinding.FieldName = 'TEXTO_LEGAL_FACTURA_EMPRESA'
              Width = 366
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTEMODIF'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTEALTA'
              Visible = False
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIOALTA'
              Visible = False
              Width = 88
            end
            object cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIOMODIF'
              Visible = False
              Width = 96
            end
            object cxGrdDBTabPrinPAIS_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'PAIS_EMPRESA'
              Visible = False
            end
            object cxGrdDBTabPrinGRUPO_ZONA_IVA_EMPRESA: TcxGridDBColumn
              DataBinding.FieldName = 'GRUPO_ZONA_IVA_EMPRESA'
              Visible = False
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        OnEnter = tsFichaEnter
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 937
        ExplicitHeight = 641
        object pnlFichaDetail: TPanel
          Left = 0
          Top = 186
          Width = 937
          Height = 455
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcPestana: TcxPageControl
            Left = 0
            Top = 0
            Width = 937
            Height = 455
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsMasDatos
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 451
            ClientRectLeft = 4
            ClientRectRight = 933
            ClientRectTop = 30
            object tsMasDatos: TcxTabSheet
              Caption = '&1_M'#225's Datos'
              ImageIndex = 0
              DesignSize = (
                929
                421)
              object cxgrpbx1: TcxGroupBox
                AlignWithMargins = True
                Left = 19
                Top = 3
                TabStop = True
                Anchors = [akLeft, akTop, akRight, akBottom]
                PanelStyle.Active = True
                PanelStyle.BorderWidth = 2
                PanelStyle.CaptionIndent = 4
                PanelStyle.OfficeBackgroundKind = pobkGradient
                PanelStyle.WordWrap = True
                TabOrder = 0
                Transparent = True
                Height = 415
                Width = 701
                object lblMovil: TcxLabel
                  Left = 51
                  Top = 25
                  Caption = 'M'#243'vil'
                  TabOrder = 1
                  Transparent = True
                end
                object txtMOVIL_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 21
                  DataBinding.DataField = 'MOVIL_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Width = 322
                end
                object lblEmail: TcxLabel
                  Left = 51
                  Top = 63
                  Caption = 'Email'
                  TabOrder = 3
                  Transparent = True
                end
                object lblDireccion: TcxLabel
                  Left = 17
                  Top = 98
                  Caption = 'Direcci'#243'n'
                  TabOrder = 5
                  Transparent = True
                end
                object txtDIRECCION1_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 94
                  DataBinding.DataField = 'DIRECCION1_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 4
                  Width = 322
                end
                object txtEMAIL_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 59
                  DataBinding.DataField = 'EMAIL_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 2
                  Width = 322
                end
                object txtDIRECCION2_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 132
                  DataBinding.DataField = 'DIRECCION2_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 6
                  Width = 322
                end
                object txtPOBLACION_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 203
                  DataBinding.DataField = 'POBLACION_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 322
                end
                object lblPoblacion: TcxLabel
                  Left = 15
                  Top = 207
                  Caption = 'Poblaci'#243'n'
                  TabOrder = 8
                  Transparent = True
                end
                object lblProvincia: TcxLabel
                  Left = 21
                  Top = 245
                  Caption = 'Provincia'
                  TabOrder = 10
                  Transparent = True
                end
                object txtPROVINCIA_EMPRESA: TcxDBTextEdit
                  Left = 106
                  Top = 240
                  DataBinding.DataField = 'PROVINCIA_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 9
                  Width = 322
                end
                object chkRegimenEspecial: TcxDBCheckBox
                  Left = 69
                  Top = 350
                  Caption = 'R'#233'gimen especial agricola/ganadero/pesca'
                  DataBinding.DataField = 'ESREGIMENESPECIALAGRICOLA_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Properties.OnChange = chkAplicaRetencionesPropertiesChange
                  Style.TransparentBorder = False
                  TabOrder = 11
                  Transparent = True
                end
                object cxDBTextEdit1: TcxDBTextEdit
                  Left = 106
                  Top = 166
                  DataBinding.DataField = 'CPOSTAL_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 12
                  Width = 322
                end
                object cxLabel1: TcxLabel
                  Left = 6
                  Top = 171
                  Caption = 'C'#243'd Postal'
                  TabOrder = 13
                  Transparent = True
                end
                object cxLabel2: TcxLabel
                  Left = 57
                  Top = 310
                  Caption = 'IBAN'
                  TabOrder = 14
                  Transparent = True
                end
                object txtIBAN_EMPRESA: TcxDBMaskEdit
                  Left = 107
                  Top = 306
                  DataBinding.DataField = 'IBAN_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  Properties.IgnoreMaskBlank = True
                  Properties.EditMask = 'aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa'
                  TabOrder = 15
                  Width = 369
                end
                object btnValidar: TcxButton
                  Left = 482
                  Top = 306
                  Width = 98
                  Height = 27
                  Caption = 'Vali&dar'
                  TabOrder = 16
                  OnClick = btnValidarClick
                end
                object lblProvincia1: TcxLabel
                  Left = 23
                  Top = 278
                  Caption = 'Pa'#237's'
                  TabOrder = 17
                  Transparent = True
                end
                object txtNOMBRE_PAIS_EMPRESA: TcxDBTextEdit
                  Left = 176
                  Top = 273
                  DataBinding.DataField = 'NOMBRE_PAIS_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 18
                  Visible = False
                  Width = 254
                end
                object txtCODIGO_PAIS_EMPRESA: TcxDBTextEdit
                  Left = 97
                  Top = 273
                  DataBinding.DataField = 'CODIGO_PAIS_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  Enabled = False
                  Properties.OnChange = txtCODIGO_PAIS_EMPRESAPropertiesChange
                  TabOrder = 19
                  Width = 73
                end
                object cbbPaises: TcxDBLookupComboBox
                  Left = 187
                  Top = 273
                  DataBinding.DataField = 'CODIGO_PAIS_EMPRESA'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'CODIGO'
                  Properties.ListColumns = <
                    item
                      Caption = 'Nombre Pais'
                      FieldName = 'NOMBRE'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  Properties.ListOptions.ShowHeader = False
                  Properties.ListSource = dmEmpresas.dsPaises
                  TabOrder = 20
                  Width = 203
                end
              end
            end
            object tsRetenciones: TcxTabSheet
              Caption = '&2_Retenciones'
              ImageIndex = 2
              object pnlRetenOpts: TPanel
                Left = 819
                Top = 0
                Width = 110
                Height = 421
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnAddIRPF: TcxButton
                  Left = 0
                  Top = 13
                  Width = 105
                  Height = 25
                  Caption = '&A'#241'adir IRPF'
                  TabOrder = 0
                  OnClick = btnAddIRPFClick
                end
              end
              object pnlRetencionesCli: TPanel
                Left = 0
                Top = 0
                Width = 819
                Height = 421
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdRetenciones: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 819
                  Height = 421
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvRetenciones: TcxGridDBTableView
                    OnDblClick = cxGrdDBTabPrinDblClick
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Buttons.First.Hint = 'Va al primer Registro'
                    Navigator.Buttons.First.Visible = False
                    Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                    Navigator.Buttons.PriorPage.Visible = False
                    Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                    Navigator.Buttons.Prior.Visible = False
                    Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                    Navigator.Buttons.Next.Visible = False
                    Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                    Navigator.Buttons.NextPage.Visible = False
                    Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                    Navigator.Buttons.Last.Visible = False
                    Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                    Navigator.Buttons.Insert.Visible = True
                    Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                    Navigator.Buttons.Delete.Visible = True
                    Navigator.Buttons.Edit.Enabled = False
                    Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                    Navigator.Buttons.Edit.Visible = False
                    Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                    Navigator.Buttons.Post.Visible = True
                    Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                    Navigator.Buttons.Cancel.Visible = True
                    Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                    Navigator.Buttons.SaveBookmark.Enabled = False
                    Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                    Navigator.Buttons.SaveBookmark.Visible = False
                    Navigator.Buttons.GotoBookmark.Enabled = False
                    Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                    Navigator.Buttons.GotoBookmark.Visible = False
                    Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                    Navigator.Visible = True
                    DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsBehavior.IncSearch = True
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.Appending = True
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object cxgrdbclmntv1CODIGO_RETENCION: TcxGridDBColumn
                      Caption = 'C'#243'digo Retenci'#243'n'
                      DataBinding.FieldName = 'CODIGO_RETENCION'
                      Width = 163
                    end
                    object cxgrdbclmntv1CODIGO_EMPRESA_RETENCION: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_EMPRESA_RETENCION'
                      Visible = False
                      Width = 122
                    end
                    object tvRetencionesPORCENRETENCION_RETENCION: TcxGridDBColumn
                      Caption = '% Retenci'#243'n'
                      DataBinding.FieldName = 'PORCENRETENCION_RETENCION'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Width = 107
                    end
                    object cxgrdbclmntv1FECHA_DESDE_RETENCION: TcxGridDBColumn
                      Caption = 'Fecha Aplicaci'#243'n desde'
                      DataBinding.FieldName = 'FECHA_DESDE_RETENCION'
                      PropertiesClassName = 'TcxDateEditProperties'
                      Width = 151
                    end
                    object cxgrdbclmntv1FECHA_HASTA_RETENCION: TcxGridDBColumn
                      Caption = 'Fecha Aplicaci'#243'n hasta'
                      DataBinding.FieldName = 'FECHA_HASTA_RETENCION'
                      PropertiesClassName = 'TcxDateEditProperties'
                      Width = 150
                    end
                    object cxgrdbclmntv1INSTANTEMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTEMODIF'
                      Visible = False
                    end
                    object cxgrdbclmntv1INSTANTEALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTEALTA'
                      Visible = False
                    end
                    object cxgrdbclmntv1USUARIOALTA: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIOALTA'
                      Visible = False
                    end
                    object cxgrdbclmntv1USUARIOMODIF: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIOMODIF'
                      Visible = False
                    end
                  end
                  object cxgrdlvlRetenciones: TcxGridLevel
                    GridView = tvRetenciones
                  end
                end
              end
            end
            object tsHistoriaFacturacion: TcxTabSheet
              Caption = '&3_Hist'#243'rico Facturas'
              ImageIndex = 3
              object pnlFactura: TPanel
                Left = 0
                Top = 0
                Width = 929
                Height = 421
                Align = alClient
                TabOrder = 0
                object cxgrdEmpresasFacturas: TcxGrid
                  Left = 1
                  Top = 1
                  Width = 810
                  Height = 419
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvFacturacion: TcxGridDBTableView
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Visible = True
                    DataController.DataModeController.SmartRefresh = True
                    DataController.DataSource = dmEmpresas.dsFacturasEmpresas
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
                      PropertiesClassName = 'TcxDateEditProperties'
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
                      Caption = 'Total a Pagar'
                      DataBinding.FieldName = 'TOTAL_LIQUIDO_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 126
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
                      Width = 71
                    end
                    object tvFacturacionTOTAL_RETENCION_FACTURA: TcxGridDBColumn
                      Caption = 'Total IRPF'
                      DataBinding.FieldName = 'TOTAL_RETENCION_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 118
                    end
                    object tvFacturacionTOTAL_BASES_FACTURA: TcxGridDBColumn
                      Caption = 'Total Bases Imponibles'
                      DataBinding.FieldName = 'TOTAL_BASES_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 199
                    end
                    object tvFacturacionTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn
                      Caption = 'IVA + RE'
                      DataBinding.FieldName = 'TOTAL_IMPUESTOS_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 74
                    end
                    object tvFacturacionFORMA_PAGO_FACTURA: TcxGridDBColumn
                      Caption = 'Forma de Pago'
                      DataBinding.FieldName = 'FORMA_PAGO_FACTURA'
                      Width = 129
                    end
                    object tvFacturacionDESCRIPCION_FORMAPAGO: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Forma Pago'
                      DataBinding.FieldName = 'DESCRIPCION_FORMAPAGO'
                      Width = 230
                    end
                    object tvFacturacionCODIGO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'C'#243'digo Cliente'
                      DataBinding.FieldName = 'CODIGO_CLIENTE_FACTURA'
                      Width = 131
                    end
                    object tvFacturacionRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Raz'#243'n Social Clietne'
                      DataBinding.FieldName = 'RAZONSOCIAL_CLIENTE_FACTURA'
                      Width = 189
                    end
                    object tvFacturacionNIF_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Nif Cliente'
                      DataBinding.FieldName = 'NIF_CLIENTE_FACTURA'
                      Width = 94
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
                      Width = 161
                    end
                    object tvFacturacionCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'CPostal Cliente'
                      DataBinding.FieldName = 'CPOSTAL_CLIENTE_FACTURA'
                      Width = 133
                    end
                    object tvFacturacionPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Poblaci'#243'n Cliente'
                      DataBinding.FieldName = 'POBLACION_CLIENTE_FACTURA'
                      Width = 152
                    end
                    object tvFacturacionPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Provincia Cliente'
                      DataBinding.FieldName = 'PROVINCIA_CLIENTE_FACTURA'
                      Width = 146
                    end
                    object tvFacturacionPAIS_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Pa'#237's Cliente'
                      DataBinding.FieldName = 'PAIS_CLIENTE_FACTURA'
                      Width = 149
                    end
                    object tvFacturacionESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tiene RE Cliente'
                      DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 155
                    end
                    object tvFacturacionESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Exento Cliente'
                      DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 161
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'REAGP Cliente'
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 123
                    end
                    object tvFacturacionESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tiene IRPF Cliente'
                      DataBinding.FieldName = 'ESRETENCIONES_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 155
                    end
                    object tvFacturacionNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn
                      Caption = 'Tarifa Cliente'
                      DataBinding.FieldName = 'NOMBRE_TARIFA_CLIENTE'
                      Width = 118
                    end
                    object tvFacturacionESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Tarifa tiene Imp Incl'
                      DataBinding.FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_FACTURA'
                      Visible = False
                      Width = 184
                    end
                    object tvFacturacionESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Es Cliente Intracomunitario'
                      DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 235
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
                      Caption = 'IVA Agr'#237'cola'
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
                      Caption = 'Zona IVA'
                      DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA'
                      Width = 90
                    end
                    object tvFacturacionESVENTA_ACTIVO_FIJO_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESVENTA_ACTIVO_FIJO_FACTURA'
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
                      Width = 127
                    end
                    object tvFacturacionTOTAL_IVAN_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Normal'
                      DataBinding.FieldName = 'TOTAL_IVAN_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 99
                    end
                    object tvFacturacionPORCEN_REN_FACTURA: TcxGridDBColumn
                      Caption = '% RE Normal'
                      DataBinding.FieldName = 'PORCEN_REN_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 107
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
                      Width = 145
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
                      Width = 125
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
                      Width = 163
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
                      Caption = 'IVA S'#250'perReducido'
                      DataBinding.FieldName = 'TOTAL_IVAS_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 165
                    end
                    object tvFacturacionPORCEN_RES_FACTURA: TcxGridDBColumn
                      Caption = '% RE S'#250'perReducido'
                      DataBinding.FieldName = 'PORCEN_RES_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 173
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
                      Width = 224
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
                      Caption = 'RE Exento'
                      DataBinding.FieldName = 'PORCEN_REE_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Width = 88
                    end
                    object tvFacturacionTOTAL_REE_FACTURA: TcxGridDBColumn
                      Caption = 'RE Exento'
                      DataBinding.FieldName = 'TOTAL_REE_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 88
                    end
                    object tvFacturacionTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imp Exento'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAE_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 143
                    end
                    object tvFacturacionCODIGO_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'RAZONSOCIAL_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionNIF_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'NIF_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionMOVIL_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'MOVIL_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionEMAIL_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'EMAIL_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION1_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION2_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'POBLACION_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PROVINCIA_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionPAIS_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PAIS_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CPOSTAL_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESRETENCIONES_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA_EMPRESA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA'
                      Visible = False
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
                    DataController.DetailKeyFieldNames = 'NRO_FACTURA_LINEA; SERIE_FACTURA_LINEA'
                    DataController.KeyFieldNames = 'LINEA_FACTURA_LINEA'
                    DataController.MasterKeyFieldNames = 'NRO_FACTURA; SERIE_FACTURA'
                    OptionsBehavior.ColumnHeaderHints = False
                    OptionsCustomize.ColumnFiltering = False
                    OptionsCustomize.ColumnGrouping = False
                    OptionsCustomize.ColumnMoving = False
                    OptionsCustomize.ColumnsQuickCustomizationShowCommands = False
                    OptionsData.Deleting = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    object tvLineasFacturacionLINEA_LINEA: TcxGridDBColumn
                      Caption = 'Nro Linea'
                      DataBinding.FieldName = 'LINEA_FACTURA_LINEA'
                      Width = 28
                    end
                    object tvLineasFacturacionCODIGO_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ARTICULO_FACTURA_LINEA'
                      Width = 164
                    end
                    object tvLineasFacturacionDESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Descripci'#243'n'
                      DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACTURA_LINEA'
                      Width = 162
                    end
                    object tvLineasFacturacionCANTIDAD_LINEA: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_FACTURA_LINEA'
                      Width = 84
                    end
                    object tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Tipo Cantidad'
                      DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA'
                    end
                    object tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Precio SIVA'
                      DataBinding.FieldName = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
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
                    end
                    object dbcLineasFacturacionNOMBRE_TIPO_IVA: TcxGridDBColumn
                      DataBinding.FieldName = 'NOMBRE_TIPO_IVA'
                    end
                    object tvLineasFacturacionPRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Precio CIVA'
                      DataBinding.FieldName = 'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 84
                    end
                    object tvLineasFacturacionSUM_TOTAL_LINEA: TcxGridDBColumn
                      Caption = 'Total'
                      DataBinding.FieldName = 'TOTAL_FACTURA_LINEA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 84
                    end
                    object tvLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Fecha de Entrega'
                      DataBinding.FieldName = 'FECHA_ENTREGA_FACTURA_LINEA'
                      PropertiesClassName = 'TcxDateEditProperties'
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
                  Left = 811
                  Top = 1
                  Width = 117
                  Height = 419
                  Align = alRight
                  TabOrder = 1
                  object btIraFactura: TcxButton
                    Left = 6
                    Top = 16
                    Width = 106
                    Height = 34
                    Caption = '&Ir a Factura'
                    TabOrder = 0
                    OnClick = btIraFacturaClick
                  end
                  object btnIraCliente: TcxButton
                    Left = 7
                    Top = 56
                    Width = 105
                    Height = 34
                    Caption = 'I&r a Cliente'
                    TabOrder = 1
                    OnClick = btnIraClienteClick
                  end
                  object btExportarExcel: TcxButton
                    Left = 5
                    Top = 136
                    Width = 106
                    Height = 34
                    Caption = 'Exp. Excel'
                    TabOrder = 3
                    OnClick = btExportarExcelClick
                  end
                  object btnIraArticulo: TcxButton
                    Left = 7
                    Top = 96
                    Width = 105
                    Height = 34
                    Caption = 'I&r a Art'#237'culo'
                    TabOrder = 2
                    OnClick = btnIraArticuloClick
                  end
                end
              end
            end
            object tsSeries: TcxTabSheet
              Caption = '&4_Series'
              ImageIndex = 4
              object pnlSeriesOpts: TPanel
                Left = 811
                Top = 0
                Width = 118
                Height = 421
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                object btnAddSerie: TcxButton
                  Left = 6
                  Top = 13
                  Width = 108
                  Height = 25
                  Caption = 'A'#241'adir Serie'
                  TabOrder = 0
                  OnClick = btnAddSerieClick
                end
              end
              object pnlSeriesCli: TPanel
                Left = 0
                Top = 0
                Width = 811
                Height = 421
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxGrdSeries: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 811
                  Height = 421
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Align = alClient
                  TabOrder = 0
                  object tvSeries: TcxGridDBTableView
                    OnDblClick = cxGrdDBTabPrinDblClick
                    Navigator.Buttons.ConfirmDelete = True
                    Navigator.Buttons.First.Hint = 'Va al primer Registro'
                    Navigator.Buttons.First.Visible = False
                    Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                    Navigator.Buttons.PriorPage.Visible = False
                    Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                    Navigator.Buttons.Prior.Visible = False
                    Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                    Navigator.Buttons.Next.Visible = False
                    Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                    Navigator.Buttons.NextPage.Visible = False
                    Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                    Navigator.Buttons.Last.Visible = False
                    Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                    Navigator.Buttons.Insert.Visible = True
                    Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                    Navigator.Buttons.Delete.Visible = True
                    Navigator.Buttons.Edit.Enabled = False
                    Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                    Navigator.Buttons.Edit.Visible = False
                    Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                    Navigator.Buttons.Post.Visible = True
                    Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                    Navigator.Buttons.Cancel.Visible = True
                    Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                    Navigator.Buttons.SaveBookmark.Enabled = False
                    Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                    Navigator.Buttons.SaveBookmark.Visible = False
                    Navigator.Buttons.GotoBookmark.Enabled = False
                    Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                    Navigator.Buttons.GotoBookmark.Visible = False
                    Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                    Navigator.Visible = True
                    DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                    OptionsBehavior.AlwaysShowEditor = True
                    OptionsBehavior.GoToNextCellOnEnter = True
                    OptionsBehavior.IncSearch = True
                    OptionsCustomize.ColumnHiding = True
                    OptionsData.Appending = True
                    OptionsView.GroupByBox = False
                    OptionsView.Indicator = True
                    object dbcCODIGO_SERIE: TcxGridDBColumn
                      Caption = 'Serie'
                      DataBinding.FieldName = 'SERIE_SERIE'
                      Width = 163
                    end
                    object dbcCODIGO_EMPRESA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_EMPRESA_SERIE'
                      Visible = False
                      Width = 122
                    end
                    object dbccxgrdbclmntv1FECHA_DESDE_SERIE: TcxGridDBColumn
                      Caption = 'Fecha Aplicaci'#243'n desde'
                      DataBinding.FieldName = 'FECHA_DESDE_SERIE'
                      PropertiesClassName = 'TcxDateEditProperties'
                      Width = 208
                    end
                    object dbcFECHA_HASTA_SERIE: TcxGridDBColumn
                      Caption = 'Fecha Aplicaci'#243'n hasta'
                      DataBinding.FieldName = 'FECHA_HASTA_SERIE'
                      PropertiesClassName = 'TcxDateEditProperties'
                      Width = 199
                    end
                    object cxgrdbclmn2: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTEMODIF'
                      Visible = False
                    end
                    object cxgrdbclmn3: TcxGridDBColumn
                      DataBinding.FieldName = 'INSTANTEALTA'
                      Visible = False
                    end
                    object cxgrdbclmn4: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIOALTA'
                      Visible = False
                    end
                    object cxgrdbclmn5: TcxGridDBColumn
                      DataBinding.FieldName = 'USUARIOMODIF'
                      Visible = False
                    end
                  end
                  object lvSeries: TcxGridLevel
                    GridView = tvSeries
                  end
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&5_Otros'
              ImageIndex = 3
              object pnlUserInstantBottom: TPanel
                Left = 0
                Top = 342
                Width = 929
                Height = 79
                Align = alBottom
                TabOrder = 4
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
                  Width = 152
                end
                object lblUsuarioAlta: TcxLabel
                  Left = 17
                  Top = 6
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario Alta'
                  TabOrder = 0
                  Transparent = True
                end
                object lblInstanteAlta: TcxLabel
                  Left = 177
                  Top = 6
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Alta'
                  TabOrder = 1
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA: TcxDBTextEdit
                  Left = 177
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTEALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 192
                end
                object cxdbtxtdtINSTANTEALTA: TcxDBTextEdit
                  Left = 593
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTEMODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 188
                end
                object lblInstanteModif: TcxLabel
                  Left = 593
                  Top = 6
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Modificaci'#243'n'
                  TabOrder = 5
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit
                  Left = 377
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIOALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 168
                end
                object lblUsuarioModif: TcxLabel
                  Left = 337
                  Top = 6
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario '#218'ltima Modificaci'#243'n'
                  TabOrder = 6
                  Transparent = True
                end
              end
              object lblTextoLegal: TcxLabel
                Left = 29
                Top = 167
                Caption = 'Texto legal en Facturas'
                TabOrder = 2
                Transparent = True
              end
              object cxdbmTEXTO_LEGAL_FACTURA_EMPRESA: TcxDBMemo
                Left = 31
                Top = 196
                DataBinding.DataField = 'TEXTO_LEGAL_FACTURA_EMPRESA'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 89
                Width = 586
              end
              object lblOrden: TcxLabel
                Left = 22
                Top = 291
                Caption = 'Orden en Listados'
                TabOrder = 3
                Transparent = True
              end
              object cxdbspndtORDEN_EMPRESA: TcxDBSpinEdit
                Left = 183
                Top = 288
                DataBinding.DataField = 'ORDEN_EMPRESA'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 86
              end
              object lblTextoLegal1: TcxLabel
                Left = 31
                Top = 18
                Caption = 'Firma electr'#243'nica en Facturas'
                TabOrder = 5
                Transparent = True
              end
              object lblDBNumeroSerieCertificado: TcxDBLabel
                Left = 207
                Top = 47
                DataBinding.DataField = 'CODIGO_CERTIFICADO_EMPRESA'
                DataBinding.DataSource = dsTablaG
                TabOrder = 6
                Height = 21
                Width = 410
              end
              object lblNumSerie: TcxLabel
                Left = 60
                Top = 47
                Caption = 'N'#250'mero de Serie'
                TabOrder = 7
                Transparent = True
              end
              object lblTipoCertificado: TcxLabel
                Left = 37
                Top = 74
                Caption = 'Tipo de Certificado'
                TabOrder = 8
                Transparent = True
              end
              object lblDBTipoCertificado: TcxDBLabel
                Left = 207
                Top = 74
                DataBinding.DataField = 'TIPO_CERTIFICADO_EMPRESA'
                DataBinding.DataSource = dsTablaG
                TabOrder = 9
                Height = 21
                Width = 410
              end
              object lblTitular: TcxLabel
                Left = 142
                Top = 101
                Caption = 'Titular'
                TabOrder = 10
                Transparent = True
              end
              object lblDBTitularCertificado: TcxDBLabel
                Left = 207
                Top = 101
                DataBinding.DataField = 'TITULAR_CERTIFICADO_EMPRESA'
                DataBinding.DataSource = dsTablaG
                TabOrder = 11
                Height = 21
                Width = 410
              end
              object btnSeleccionarCer: TcxButton
                Left = 290
                Top = 17
                Width = 327
                Height = 23
                Caption = '&Seleccionar certificado de Almac'#233'n'
                TabOrder = 12
                WordWrap = True
                OnClick = btnSeleccionarCerClick
              end
              object lblFechaCaducidad: TcxLabel
                Left = 60
                Top = 130
                Caption = 'FechaCaducidad'
                TabOrder = 13
                Transparent = True
              end
              object txtFECHACADUCIDAD: TcxDBTextEdit
                Left = 207
                Top = 128
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'FECHA_HASTA_CERTIFICADO_EMPRESA'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 14
                Width = 192
              end
            end
          end
        end
        object spltFicha: TcxSplitter
          Left = 0
          Top = 178
          Width = 937
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlFichaDetail
        end
        object pnlFichaCab: TPanel
          Left = 0
          Top = 0
          Width = 937
          Height = 178
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          DesignSize = (
            937
            178)
          object cxgrpbx2: TcxGroupBox
            AlignWithMargins = True
            Left = 9
            Top = 5
            TabStop = True
            Anchors = [akLeft, akTop, akRight, akBottom]
            TabOrder = 0
            Transparent = True
            Height = 166
            Width = 896
            object lblCodigo: TcxLabel
              Left = 24
              Top = 17
              Caption = 'C'#243'digo'
              TabOrder = 0
              Transparent = True
            end
            object txtCODIGO_EMPRESA: TcxDBTextEdit
              Left = 102
              Top = 15
              DataBinding.DataField = 'CODIGO_EMPRESA'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = False
              TabOrder = 1
              Width = 126
            end
            object lblNif: TcxLabel
              Left = 317
              Top = 17
              Caption = 'Nif'
              TabOrder = 2
              Transparent = True
            end
            object txtNIF_EMPRESA: TcxDBTextEdit
              Left = 352
              Top = 15
              DataBinding.DataField = 'NIF_EMPRESA'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 161
            end
            object lblNombre: TcxLabel
              Left = 24
              Top = 59
              Caption = 'Raz'#243'n Social'
              TabOrder = 4
              Transparent = True
            end
            object txtRAZONSOCIAL_EMPRESA: TcxDBTextEdit
              Left = 146
              Top = 55
              DataBinding.DataField = 'RAZONSOCIAL_EMPRESA'
              DataBinding.DataSource = dsTablaG
              TabOrder = 5
              Width = 367
            end
            object chkActivo: TcxDBCheckBox
              Left = 24
              Top = 88
              Caption = 'Activo'
              DataBinding.DataField = 'ACTIVO_EMPRESA'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 6
              Transparent = True
            end
            object chkAplicaRetenciones: TcxDBCheckBox
              Left = 24
              Top = 122
              Caption = 'Retiene IRPF'
              DataBinding.DataField = 'ESRETENCIONES_EMPRESA'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Properties.OnChange = chkAplicaRetencionesPropertiesChange
              Style.TransparentBorder = False
              TabOrder = 7
              Transparent = True
            end
            object lblCanalIVA: TcxLabel
              Left = 180
              Top = 93
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Canal de IVA'
              Properties.Alignment.Horz = taRightJustify
              TabOrder = 8
              Transparent = True
              AnchorX = 289
            end
            object cbbZonaIVA: TcxDBLookupComboBox
              Left = 180
              Top = 122
              DataBinding.DataField = 'GRUPO_ZONA_IVA_EMPRESA'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'GRUPO_ZONA_IVA'
              Properties.ListColumns = <
                item
                  FieldName = 'DESCRIPCION_ZONA_IVA'
                end>
              Properties.ListOptions.ShowHeader = False
              Properties.ValidateOnEnter = False
              TabOrder = 9
              Width = 333
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 937
        ExplicitHeight = 641
        inherited pnlPerfilTop: TPanel
          Width = 937
          ExplicitWidth = 937
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 937
          Height = 584
          ExplicitWidth = 937
          ExplicitHeight = 584
          inherited cxgrdPerfil: TcxGrid
            Width = 937
            Height = 584
            ExplicitWidth = 937
            ExplicitHeight = 584
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 945
      TabOrder = 0
      ExplicitWidth = 945
      inherited pnlTopGrid: TPanel
        Width = 945
        ExplicitWidth = 945
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 308
          TabOrder = 3
          ExplicitWidth = 308
        end
        inherited lblTextoaBuscar: TcxLabel
          TabOrder = 4
        end
        inherited rbBBDD: TcxRadioButton
          TabOrder = 2
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 945
    Height = 715
    TabOrder = 1
    ExplicitLeft = 945
    ExplicitHeight = 715
    inherited pButtonGen: TPanel
      Top = 517
      TabOrder = 2
      ExplicitTop = 517
    end
    object btnNuevaEmpresa: TcxButton
      Left = 1
      Top = 154
      Width = 138
      Height = 25
      Caption = '&Nueva Empresa'
      TabOrder = 1
      OnClick = btnNuevaEmpresaClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 808
    Top = 400
  end
  object ActionListEmpresas: TActionList [4]
    Left = 808
    Top = 312
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
  end
  inherited dsTablaG: TDataSource
    DataSet = dmEmpresas.unqryTablaG
    Left = 628
    Top = 535
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 792
    Top = 496
  end
end
