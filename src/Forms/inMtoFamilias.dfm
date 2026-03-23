inherited frmMtoFamilias: TfrmMtoFamilias
  Left = 5
  Top = 4
  Caption = 'Familias'
  ClientHeight = 592
  ClientWidth = 880
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 880
  ExplicitHeight = 592
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 740
    Height = 592
    TabOrder = 0
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 740
    ExplicitHeight = 592
    inherited pcPantalla: TcxPageControl
      Width = 740
      Height = 552
      TabOrder = 1
      Properties.ActivePage = tsFicha
      ExplicitWidth = 740
      ExplicitHeight = 552
      ClientRectBottom = 548
      ClientRectRight = 736
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 732
        ExplicitHeight = 518
        inherited cxGrdPrincipal: TcxGrid
          Width = 732
          Height = 518
          ExplicitWidth = 732
          ExplicitHeight = 518
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_FAMILIA: TcxGridDBColumn
              Caption = 'C'#243'digo Familia'
              DataBinding.FieldName = 'CODIGO_FAMILIA'
              Width = 140
            end
            object cxgrdbclmnGrdDBTabPrinACTIVO_FAMILIA: TcxGridDBColumn
              Caption = 'Es Familia activa'
              DataBinding.FieldName = 'ACTIVO_FAMILIA'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 162
            end
            object dbcGrdDBTabPrinESDEFAULT_FAMILIA: TcxGridDBColumn
              Caption = 'Por Defecto'
              DataBinding.FieldName = 'ESDEFAULT_FAMILIA'
              Width = 107
            end
            object cxgrdbclmnGrdDBTabPrinNOMBRE_FAMILIA: TcxGridDBColumn
              Caption = 'Nombre Familia'
              DataBinding.FieldName = 'NOMBRE_FAMILIA'
              Width = 191
            end
            object dbcGrdDBTabPrinCODIGO_SUBFAMILIA: TcxGridDBColumn
              Caption = 'C'#243'digo Subfamilia'
              DataBinding.FieldName = 'CODIGO_SUBFAMILIA'
              Width = 178
            end
            object dbcGrdDBTabPrinNOMBRE_SUBFAMILIA: TcxGridDBColumn
              Caption = 'Nombre Subfamilia'
              DataBinding.FieldName = 'NOMBRE_SUBFAMILIA'
              Width = 247
            end
            object cxgrdbclmnGrdDBTabPrinDESCRIPCION_FAMILIA: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_FAMILIA'
              Width = 496
            end
            object cxgrdbclmnGrdDBTabPrinORDEN_FAMILIA: TcxGridDBColumn
              Caption = 'Orden en listados'
              DataBinding.FieldName = 'ORDEN_FAMILIA'
              Width = 164
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 732
        ExplicitHeight = 518
        object pnl1: TPanel
          Left = 0
          Top = 0
          Width = 732
          Height = 165
          Align = alTop
          BevelOuter = bvNone
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
          object pnlCabFich: TPanel
            Left = 0
            Top = 0
            Width = 732
            Height = 165
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object txtCODIGO_FAMILIA: TcxDBTextEdit
              Left = 101
              Top = 13
              DataBinding.DataField = 'CODIGO_FAMILIA'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = False
              TabOrder = 0
              Width = 121
            end
            object lblCodigo: TcxLabel
              Left = 21
              Top = 17
              Caption = 'C'#243'digo'
              TabOrder = 1
              Transparent = True
            end
            object lblNombre: TcxLabel
              Left = 18
              Top = 51
              Caption = 'Nombre'
              TabOrder = 2
              Transparent = True
            end
            object txtNOMBRE_FAMILIA: TcxDBTextEdit
              Left = 100
              Top = 48
              DataBinding.DataField = 'NOMBRE_FAMILIA'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 322
            end
            object chkActivo: TcxDBCheckBox
              Left = 97
              Top = 78
              Caption = 'Activo'
              DataBinding.DataField = 'ACTIVO_FAMILIA'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 4
              Transparent = True
            end
            object cbbFamilia: TcxDBLookupComboBox
              Left = 143
              Top = 111
              DataBinding.DataField = 'CODIGO_SUBFAMILIA'
              DataBinding.DataSource = dsTablaG
              Properties.DropDownAutoSize = True
              Properties.KeyFieldNames = 'CODIGO_FAMILIA'
              Properties.ListColumns = <
                item
                  MinWidth = 50
                  Width = 150
                  FieldName = 'CODIGO_FAMILIA'
                end
                item
                  Sorting = False
                  FieldName = 'NOMBRE_FAMILIA'
                end>
              Properties.ListOptions.ShowHeader = False
              TabOrder = 5
              Width = 202
            end
            object cxlbllbl1: TcxLabel
              Left = 20
              Top = 112
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Familia Padre'
              Properties.Alignment.Horz = taRightJustify
              TabOrder = 6
              Transparent = True
              AnchorX = 136
            end
            object chkDEFAULT_FAMILIA: TcxDBCheckBox
              Left = 249
              Top = 82
              Caption = 'Familia por defecto'
              DataBinding.DataField = 'ESDEFAULT_FAMILIA'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 7
              Transparent = True
            end
          end
        end
        object pnlDetailFich: TPanel
          Left = 0
          Top = 173
          Width = 732
          Height = 345
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 1
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 732
            Height = 345
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = cxTabSheet1
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 341
            ClientRectLeft = 4
            ClientRectRight = 728
            ClientRectTop = 30
            object tsMasDatos: TcxTabSheet
              Caption = '&1_M'#225's Datos'
              ImageIndex = 0
              object lblDescripcion: TcxLabel
                Left = 33
                Top = 19
                Caption = 'Descipci'#243'n'
                TabOrder = 0
                Transparent = True
              end
              object mDESCRIPCION_FAMILIA: TcxDBMemo
                Left = 33
                Top = 45
                DataBinding.DataField = 'DESCRIPCION_FAMILIA'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Height = 89
                Width = 373
              end
            end
            object tsArticulos: TcxTabSheet
              Caption = '&2_Articulos'
              ImageIndex = 2
              object cxgrdArticulosFamilias: TcxGrid
                Left = 0
                Top = 0
                Width = 724
                Height = 311
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvArticulos: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  DataController.Summary.DefaultGroupSummaryItems = <
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end>
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
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
                  object cxgrdbclmnArticulosCODIGO_ARTICULO: TcxGridDBColumn
                    Caption = 'C'#243'digo Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ARTICULO'
                    Width = 147
                  end
                  object cxgrdbclmnArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO'
                    Width = 139
                  end
                  object cxgrdbclmnArticulosCODIGO_PROVEEDOR_PRINCIPAL: TcxGridDBColumn
                    Caption = 'C'#243'digo Proveedor Prin.'
                    DataBinding.FieldName = 'CODIGO_PROVEEDOR_PRINCIPAL'
                    Width = 206
                  end
                  object cxgrdbclmnArticulosRAZON_SOCIAL_PROVEEDOR_PRINCIPAL: TcxGridDBColumn
                    Caption = 'Raz'#243'n Social Proveedor Principal'
                    DataBinding.FieldName = 'RAZON_SOCIAL_PROVEEDOR_PRINCIPAL'
                    Width = 277
                  end
                  object cxgrdbclmnArticulosNOMBRE_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa'
                    DataBinding.FieldName = 'NOMBRE_TARIFA'
                    Width = 78
                  end
                  object cxgrdbclmnArticulosPRECIOFINAL_TARIFA: TcxGridDBColumn
                    Caption = 'Precio Salida'
                    DataBinding.FieldName = 'PRECIOFINAL_TARIFA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 127
                  end
                  object cxgrdbclmnArticulosESIMP_INCL_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa Imp Incl'
                    DataBinding.FieldName = 'ESIMP_INCL_TARIFA'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 146
                  end
                  object cxgrdbclmnArticulosNOMBRE_TIPO_IVA: TcxGridDBColumn
                    Caption = 'Tipo de IVA'
                    DataBinding.FieldName = 'NOMBRE_TIPO_IVA'
                    Width = 114
                  end
                  object cxgrdbclmnArticulosTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn
                    Caption = 'Tipo Cantidad'
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO'
                    Width = 131
                  end
                  object cxgrdbclmnArticulosESACTIVO_FIJO_ARTICULO: TcxGridDBColumn
                    Caption = 'Activo Fijo'
                    DataBinding.FieldName = 'ESACTIVO_FIJO_ARTICULO'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 102
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
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'LINEA_FACTURA_LINEA'
                    Width = 28
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA: TcxGridDBColumn
                    Caption = 'C'#243'digo Tratamiento'
                    DataBinding.FieldName = 'CODIGO_ARTICULO_FACTURA_LINEA'
                    Width = 164
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Tratamiento'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACTURA_LINEA'
                    Width = 162
                  end
                  object cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA'
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACTURA_LINEA'
                    Width = 84
                  end
                  object cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA'
                  end
                  object cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Porcentaje IVA'
                    DataBinding.FieldName = 'PORCEN_IVA_FACTURA_LINEA'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.EditFormat = '0.00 %'
                  end
                  object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn
                    Caption = 'Precio'
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
                  object cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Fecha de Entrega'
                    DataBinding.FieldName = 'FECHA_ENTREGA_FACTURA_LINEA'
                    PropertiesClassName = 'TcxDateEditProperties'
                  end
                  object cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPOIVA_ARTICULO_FACTURA_LINEA'
                  end
                end
                object cxgrdlvlArticulosFamilias: TcxGridLevel
                  GridView = tvArticulos
                end
              end
            end
            object cxTabSheet1: TcxTabSheet
              Caption = '&3_Propiedades Art'#237'culos'
              ImageIndex = 3
              object cxGrid1: TcxGrid
                Left = 0
                Top = 57
                Width = 724
                Height = 254
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tvAtributos: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  DataController.DataSource = dmFamilias.dsFamiliasAtributos
                  DataController.Summary.DefaultGroupSummaryItems = <
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end
                    item
                      Kind = skSum
                    end>
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end
                    item
                      Format = '0.00 '#8364';-0.00 '#8364
                      Kind = skSum
                    end>
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsData.Appending = True
                  OptionsSelection.InvertSelect = False
                  OptionsView.NoDataToDisplayInfoText = '<No hay datos a mostrar>'
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.GroupFooters = gfAlwaysVisible
                  object tvAtributosCODIGO_FAMILIA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_FAMILIA'
                    Visible = False
                  end
                  object tvAtributosCODIGO_PROPIEDAD: TcxGridDBColumn
                    Caption = 'Cod Propiedad'
                    DataBinding.FieldName = 'CODIGO_PROPIEDAD'
                    PropertiesClassName = 'TcxLookupComboBoxProperties'
                    Properties.DropDownAutoSize = True
                    Properties.DropDownSizeable = True
                    Properties.ImmediatePost = True
                    Properties.KeyFieldNames = 'CODIGO_PROPIEDAD'
                    Properties.ListColumns = <
                      item
                        FieldName = 'CODIGO_PROPIEDAD'
                      end
                      item
                        FieldName = 'NOMBRE_PROPIEDAD'
                      end>
                    Properties.ListOptions.ShowHeader = False
                    Properties.ListSource = dmFamilias.dsPropiedades
                    Width = 130
                  end
                  object tvAtributosNOMBRE_PROPIEDAD: TcxGridDBColumn
                    Caption = 'Nombre Propiedad'
                    DataBinding.FieldName = 'NOMBRE_PROPIEDAD'
                    Width = 193
                  end
                  object tvAtributosES_REQUERIDO: TcxGridDBColumn
                    Caption = 'Obligatorio'
                    DataBinding.FieldName = 'ES_REQUERIDO'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 109
                  end
                  object tvAtributosORDEN_MOSTRAR: TcxGridDBColumn
                    Caption = 'Orden'
                    DataBinding.FieldName = 'ORDEN_MOSTRAR'
                    HeaderAlignmentHorz = taRightJustify
                  end
                end
                object cxGridDBTableView2: TcxGridDBTableView
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
                  object cxGridDBColumn11: TcxGridDBColumn
                    DataBinding.FieldName = 'LINEA_FACTURA_LINEA'
                    Width = 28
                  end
                  object cxGridDBColumn12: TcxGridDBColumn
                    Caption = 'C'#243'digo Tratamiento'
                    DataBinding.FieldName = 'CODIGO_ARTICULO_FACTURA_LINEA'
                    Width = 164
                  end
                  object cxGridDBColumn13: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Tratamiento'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACTURA_LINEA'
                    Width = 162
                  end
                  object cxGridDBColumn14: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA'
                  end
                  object cxGridDBColumn15: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACTURA_LINEA'
                    Width = 84
                  end
                  object cxGridDBColumn16: TcxGridDBColumn
                    DataBinding.FieldName = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA'
                  end
                  object cxGridDBColumn17: TcxGridDBColumn
                    Caption = 'Porcentaje IVA'
                    DataBinding.FieldName = 'PORCEN_IVA_FACTURA_LINEA'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.EditFormat = '0.00 %'
                  end
                  object cxGridDBColumn18: TcxGridDBColumn
                    Caption = 'Precio'
                    DataBinding.FieldName = 'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 84
                  end
                  object cxGridDBColumn19: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'TOTAL_FACTURA_LINEA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 84
                  end
                  object cxGridDBColumn20: TcxGridDBColumn
                    Caption = 'Fecha de Entrega'
                    DataBinding.FieldName = 'FECHA_ENTREGA_FACTURA_LINEA'
                    PropertiesClassName = 'TcxDateEditProperties'
                  end
                  object cxGridDBColumn21: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPOIVA_ARTICULO_FACTURA_LINEA'
                  end
                end
                object cxGridLevel1: TcxGridLevel
                  GridView = tvAtributos
                end
              end
              object Panel1: TPanel
                Left = 0
                Top = 0
                Width = 724
                Height = 57
                Align = alTop
                TabOrder = 1
                object btnAddAtributo: TcxButton
                  Left = 17
                  Top = 7
                  Width = 176
                  Height = 34
                  Caption = '&Asignar Propiedad'
                  TabOrder = 0
                  Font.Charset = ANSI_CHARSET
                  Font.Color = clWindowText
                  Font.Height = -17
                  Font.Name = 'Lucida Sans'
                  Font.Style = []
                  ParentFont = False
                  OnClick = btnGrabarClick
                end
                object btnDelAtributo: TcxButton
                  Left = 233
                  Top = 7
                  Width = 168
                  Height = 34
                  Caption = '&Quitar Propiedad'
                  TabOrder = 1
                  Font.Charset = ANSI_CHARSET
                  Font.Color = clWindowText
                  Font.Height = -17
                  Font.Name = 'Lucida Sans'
                  Font.Style = []
                  ParentFont = False
                end
                object btnNuevaPropiedadGlobal: TcxButton
                  Left = 441
                  Top = 7
                  Width = 216
                  Height = 34
                  Caption = '&Crear Nueva Propiedad'
                  TabOrder = 2
                  Font.Charset = ANSI_CHARSET
                  Font.Color = clWindowText
                  Font.Height = -17
                  Font.Name = 'Lucida Sans'
                  Font.Style = []
                  ParentFont = False
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&4_Otros'
              ImageIndex = 3
              object pnl3: TPanel
                Left = 0
                Top = 232
                Width = 724
                Height = 79
                Align = alBottom
                BevelOuter = bvNone
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
                  TabOrder = 0
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
                  TabOrder = 1
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
                  TabOrder = 5
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
                  TabOrder = 6
                  Transparent = True
                end
              end
              object lblOrden: TcxLabel
                Left = 20
                Top = 24
                Caption = 'Orden en Listados'
                TabOrder = 1
                Transparent = True
              end
              object cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit
                Left = 179
                Top = 23
                DataBinding.DataField = 'ORDEN_FAMILIA'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 106
              end
            end
          end
        end
        object cxspltr1: TcxSplitter
          Left = 0
          Top = 165
          Width = 732
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnl1
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 732
        ExplicitHeight = 518
        inherited pnlPerfilTop: TPanel
          Width = 732
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 732
        end
        inherited pnlPerfilDetail: TPanel
          Width = 732
          Height = 461
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 732
          ExplicitHeight = 461
          inherited cxgrdPerfil: TcxGrid
            Width = 732
            Height = 461
            ExplicitWidth = 732
            ExplicitHeight = 461
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 740
      TabOrder = 0
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 740
      inherited pnlTopGrid: TPanel
        Width = 740
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 740
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 740
    Height = 592
    TabOrder = 1
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 740
    ExplicitHeight = 592
    inherited pButtonGen: TPanel
      Top = 394
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 394
      inherited btnGrabar: TcxButton
        ParentFont = False
      end
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
    object btnNuevaFamilia: TcxButton
      Left = 1
      Top = 157
      Width = 138
      Height = 25
      Caption = '&Nueva Familia'
      TabOrder = 2
      OnClick = btnNuevaFamiliaClick
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmFamilias.unqryTablaG
    Left = 604
    Top = 399
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 600
    Top = 344
  end
  object ActionListFamilias: TActionList
    Left = 608
    Top = 456
    object actArticulo: TAction
      Caption = 'Articulos'
      ShortCut = 16449
      OnExecute = actArticulosExecute
    end
    object actProveedores: TAction
      Caption = 'Proveedores'
      ShortCut = 16464
      OnExecute = actProveedoresExecute
    end
    object actTarifas: TAction
      Caption = 'Tarifas'
      ShortCut = 16468
      OnExecute = actTarifasExecute
    end
  end
end
