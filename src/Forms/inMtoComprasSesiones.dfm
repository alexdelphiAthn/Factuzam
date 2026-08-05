inherited frmMtoComprasSesiones: TfrmMtoComprasSesiones
  Caption = 'Crear art'#237'culos y un pedido o un albar'#225'n'
  ClientHeight = 783
  ClientWidth = 1240
  Position = poDesigned
  StyleElements = [seFont, seClient, seBorder]
  OnDestroy = FormDestroy
  ExplicitLeft = 3
  ExplicitTop = -55
  ExplicitWidth = 1240
  ExplicitHeight = 783
  TextHeight = 17
  inherited pButtonPage: TPanel
    Width = 1100
    Height = 783
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = -32
    ExplicitWidth = 1100
    ExplicitHeight = 783
    inherited pcPantalla: TcxPageControl
      Width = 1100
      Height = 743
      ExplicitWidth = 1100
      ExplicitHeight = 680
      ClientRectBottom = 739
      ClientRectRight = 1096
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1092
        ExplicitHeight = 648
        inherited cxGrdPrincipal: TcxGrid
          Width = 1092
          Height = 711
          ExplicitWidth = 1092
          ExplicitHeight = 648
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcSerieSes: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_SES'
              Width = 60
            end
            object dbcNumeroSes: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_SES'
              Width = 80
            end
            object dbcFechaSes: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_SES'
              Width = 100
            end
            object dbcTemporadaSes: TcxGridDBColumn
              Caption = 'Temporada'
              DataBinding.FieldName = 'TEMPORADA_SES'
              Width = 120
            end
            object dbcFechaEfectoStockSes: TcxGridDBColumn
              Caption = 'Fecha y hora stock'
              DataBinding.FieldName = 'FECHA_EFECTO_STOCK_SES'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.DisplayFormat = 'dd/mm/yyyy hh:nn:ss'
              Properties.Kind = ckDateTime
              Width = 145
            end
            object dbcFechaTopeRecepcionSes: TcxGridDBColumn
              Caption = 'F.tope recep.'
              DataBinding.FieldName = 'FECHA_TOPE_RECEPCION_SES'
              Width = 110
            end
            object dbcTotalPrendasSes: TcxGridDBColumn
              Caption = 'Prendas'
              DataBinding.FieldName = 'TOTAL_PRENDAS_SES'
              Width = 90
            end
            object dbcTotalLineasSes: TcxGridDBColumn
              Caption = 'Neto lineas'
              DataBinding.FieldName = 'TOTAL_LINEAS_SES'
              Width = 110
            end
            object dbcTotalDocumentoSes: TcxGridDBColumn
              Caption = 'Total doc.'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_SES'
              Width = 110
            end
            object dbcCantidadPedidaSes: TcxGridDBColumn
              Caption = 'Pedidas'
              DataBinding.FieldName = 'CANTIDAD_PEDIDA_SES'
              Width = 90
            end
            object dbcCantidadRecibidaSes: TcxGridDBColumn
              Caption = 'Recibidas'
              DataBinding.FieldName = 'CANTIDAD_RECIBIDA_SES'
              Width = 90
            end
            object dbcCantidadPendienteSes: TcxGridDBColumn
              Caption = 'Pte. recibir'
              DataBinding.FieldName = 'CANTIDAD_PENDIENTE_RECEPCION_SES'
              Width = 95
            end
            object dbcEstadoSes: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_SES'
              Width = 80
            end
            object dbcCodigoEmpSes: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_SES'
              Width = 80
            end
            object dbcCodigoPrvSes: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_SES'
              Width = 100
            end
            object dbcRazonSocialPrvSes: TcxGridDBColumn
              Caption = 'Raz'#243'n social'
              DataBinding.FieldName = 'RAZON_SOCIAL_PRV_SES'
              Width = 200
            end
            object dbcNombrePrvSes: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_PRV_SES'
              Width = 160
            end
            object dbcCodigoTarSes: TcxGridDBColumn
              Caption = 'Tarifa'
              DataBinding.FieldName = 'CODIGO_TAR_SES'
              Width = 90
            end
            object dbcUsuarioAltaSes: TcxGridDBColumn
              Caption = 'Usuario'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Width = 100
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1092
        ExplicitHeight = 648
        object pnlBottFich: TPanel
          Left = 0
          Top = 305
          Width = 1092
          Height = 406
          Align = alClient
          TabOrder = 0
          ExplicitTop = 243
          ExplicitHeight = 405
          object cxPageControl2: TcxPageControl
            Left = 1
            Top = 1
            Width = 1090
            Height = 404
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = cxTabSheet1
            Properties.CustomButtons.Buttons = <>
            ExplicitHeight = 403
            ClientRectBottom = 400
            ClientRectLeft = 4
            ClientRectRight = 1086
            ClientRectTop = 28
            object cxTabSheet1: TcxTabSheet
              Caption = '&1_Lineas de Art'#237'culos'
              ImageIndex = 0
              ExplicitHeight = 371
              object cxgrdLineas: TcxGrid
                Left = 0
                Top = 36
                Width = 1082
                Height = 336
                Align = alClient
                TabOrder = 0
                OnEnter = cxgrdLineasEnter
                OnExit = cxgrdLineasExit
                ExplicitHeight = 335
                object tvLineas: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Append.Visible = False
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Visible = False
                  Navigator.Visible = True
                  OnCustomDrawCell = tvLineasCustomDrawCell
                  OnEditing = tvLineasEditing
                  OnEditKeyDown = tvLineasEditKeyDown
                  OnFocusedRecordChanged = tvLineasFocusedRecordChanged
                  OnInitEdit = tvLineasInitEdit
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#,##0'
                      Kind = skSum
                      Column = dbcLinTotalTallas
                    end>
                  OptionsBehavior.FocusCellOnTab = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsData.Appending = True
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  object dbcLinFamilia: TcxGridDBColumn
                    Caption = 'Familia (F3)'
                    DataBinding.FieldName = 'CODIGO_FAM_SESLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.CharCase = ecUpperCase
                    Properties.OnEditValueChanged = dbcLinFamiliaPropertiesEditValueChanged
                    Width = 110
                  end
                  object dbcLinCodArt: TcxGridDBColumn
                    Caption = 'C'#243'd. art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_TENTATIVO_SESLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.CharCase = ecUpperCase
                    Properties.OnEditValueChanged = dbcLinCodArtPropertiesEditValueChanged
                    Width = 130
                  end
                  object dbcLinRefPrv: TcxGridDBColumn
                    Caption = 'Modelo prov.'
                    DataBinding.FieldName = 'REF_PRV_SESLIN'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.OnEditValueChanged = dbcLinRefPrvPropertiesEditValueChanged
                    Width = 130
                  end
                  object dbcLinDescripcion: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_SESLIN'
                    Width = 341
                  end
                  object dbcLinTipoIva: TcxGridDBColumn
                    Caption = 'Tipo IVA'
                    DataBinding.FieldName = 'TIPO_IVA_SESLIN'
                    PropertiesClassName = 'TcxComboBoxProperties'
                    Properties.DropDownListStyle = lsFixedList
                    Properties.Items.Strings = (
                      'N'
                      'R'
                      'S'
                      'E')
                    Visible = False
                    Width = 72
                  end
                  object dbcLinColor: TcxGridDBColumn
                    Caption = 'Color'
                    DataBinding.FieldName = 'COLOR_TEXTO_SESLIN'
                    Width = 140
                  end
                  object dbcLinColorBasico: TcxGridDBColumn
                    Caption = 'C. b'#225'sico'
                    DataBinding.FieldName = 'CODIGO_ATB_COLOR_SESLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = dbcLinColorBasicoPropertiesButtonClick
                    Width = 110
                  end
                  object dbcLinPrecioCompra: TcxGridDBColumn
                    Caption = 'Pr. compra s/IVA'
                    DataBinding.FieldName = 'PRECIO_COMPRA_SESLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.OnEditValueChanged = dbcLinPrecioCompraPropertiesEditValueChanged
                    Width = 136
                  end
                  object dbcLinPrecioVenta: TcxGridDBColumn
                    Caption = 'Pr. venta'
                    DataBinding.FieldName = 'PRECIO_VENTA_SESLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 90
                  end
                  object dbcLinTallas: TcxGridDBColumn
                    Caption = 'Sistema tallas'
                    DataBinding.FieldName = 'ID_AC_PIVOT_SESLIN'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = dbcLinTallasPropertiesButtonClick
                    Width = 170
                  end
                  object dbcLinTotalTallas: TcxGridDBColumn
                    Caption = 'Total tallas'
                    DataBinding.FieldName = 'TOTAL_UNIDADES_SESLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.Alignment.Horz = taRightJustify
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 100
                  end
                  object dbcLinImporteTotal: TcxGridDBColumn
                    Caption = 'Importe s/IVA'
                    DataBinding.FieldName = 'TOTAL_LINEA_SESLIN'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.Alignment.Horz = taRightJustify
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 110
                  end
                  object dbcLinNumero: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_SESLIN'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.Increment = 10.000000000000000000
                    Properties.MinValue = 1.000000000000000000
                    Width = 70
                  end
                end
                object glLineas: TcxGridLevel
                  GridView = tvLineas
                end
              end
              object pnlLineasTop: TPanel
                Left = 0
                Top = 0
                Width = 1082
                Height = 36
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 1
                object btnAddLinea: TcxButton
                  Left = 12
                  Top = 4
                  Width = 112
                  Height = 28
                  Caption = '+ A'#241'adir l'#237'nea'
                  TabOrder = 0
                  OnClick = btnAddLineaClick
                end
                object btnDelLinea: TcxButton
                  Left = 130
                  Top = 5
                  Width = 112
                  Height = 28
                  Caption = '- Borrar l'#237'nea'
                  TabOrder = 1
                  OnClick = btnDelLineaClick
                end
                object btnNuevoColor: TcxButton
                  Left = 248
                  Top = 5
                  Width = 120
                  Height = 28
                  Caption = 'Otro color'
                  Colors.Default = 14346982
                  Colors.Normal = 14346982
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 2
                  OnClick = btnNuevoColorClick
                end
                object btnOtroPrecio: TcxButton
                  Left = 374
                  Top = 5
                  Width = 110
                  Height = 28
                  Caption = 'Otro precio'
                  Colors.Default = 14346982
                  Colors.Normal = 14346982
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 3
                  OnClick = btnOtroPrecioClick
                end
                object btnFoto: TcxButton
                  Left = 490
                  Top = 5
                  Width = 90
                  Height = 28
                  Caption = '+ Foto'
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 4
                  OnClick = btnFotoClick
                end
                object btnArbolFamilias: TcxButton
                  Left = 586
                  Top = 5
                  Width = 150
                  Height = 28
                  Caption = #193'rbol familias (F3)'
                  TabOrder = 5
                  OnClick = btnArbolFamiliasClick
                end
                object btnDescargarFotos: TcxButton
                  Left = 742
                  Top = 5
                  Width = 100
                  Height = 28
                  Caption = 'Bajar fotos'
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 6
                  OnClick = btnDescargarFotosClick
                end
                object btnAplicarKit: TcxButton
                  Left = 848
                  Top = 5
                  Width = 130
                  Height = 28
                  Caption = 'Aplicar kit'
                  Colors.Default = 12579775
                  Colors.Normal = 12579775
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 7
                  OnClick = btnAplicarKitClick
                end
                object lblHint: TcxLabel
                  Left = 986
                  Top = 7
                  Caption = 'F3 = familias. PVP se propone al teclear el coste.'
                  TabOrder = 8
                  Transparent = True
                end
              end
            end
            object tsTotales: TcxTabSheet
              Caption = '&2_Totales'
              ImageIndex = 3
              ExplicitHeight = 371
              object pnlTotales: TPanel
                Left = 0
                Top = 0
                Width = 1082
                Height = 372
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                ExplicitHeight = 371
                object lblTotalBasesSes: TcxLabel
                  Left = 47
                  Top = 77
                  Caption = 'Total base imponible'
                  TabOrder = 0
                  Transparent = True
                end
                object curTotalesTOTAL_BASES_SES: TcxDBCurrencyEdit
                  Left = 220
                  Top = 73
                  DataBinding.DataField = 'TOTAL_BASES_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Width = 130
                end
                object lblTotalImpuestosSes: TcxLabel
                  Left = 85
                  Top = 111
                  Caption = 'Total impuestos'
                  TabOrder = 2
                  Transparent = True
                end
                object curTotalesTOTAL_IMPUESTOS_SES: TcxDBCurrencyEdit
                  Left = 220
                  Top = 107
                  DataBinding.DataField = 'TOTAL_IMPUESTOS_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 130
                end
                object lblPorcRetencionSes: TcxLabel
                  Left = 111
                  Top = 145
                  Caption = '% Retenci'#243'n'
                  TabOrder = 4
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_RETENCION_SES: TcxDBSpinEdit
                  Left = 220
                  Top = 141
                  DataBinding.DataField = 'PORCENTAJE_RETENCION_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 5
                  Width = 130
                end
                object lblTotalRetencionSes: TcxLabel
                  Left = 90
                  Top = 178
                  Caption = 'Total retenci'#243'n'
                  TabOrder = 6
                  Transparent = True
                end
                object curTotalesTOTAL_RETENCION_SES: TcxDBCurrencyEdit
                  Left = 220
                  Top = 174
                  DataBinding.DataField = 'TOTAL_RETENCION_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 130
                end
                object lblTotalLiquidoSes: TcxLabel
                  Left = 107
                  Top = 209
                  Caption = 'Total a pagar'
                  TabOrder = 8
                  Transparent = True
                end
                object curTotalesTOTAL_LIQUIDO_SES: TcxDBCurrencyEdit
                  Left = 220
                  Top = 208
                  DataBinding.DataField = 'TOTAL_LIQUIDO_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  Properties.UseThousandSeparator = True
                  TabOrder = 9
                  Width = 130
                end
                object lblTotalesFormaPagoSes: TcxLabel
                  Left = 92
                  Top = 243
                  Caption = 'Forma de Pago'
                  TabOrder = 10
                  Transparent = True
                end
                object cbbTotalesFORMA_PAGO_SES: TcxDBLookupComboBox
                  Left = 220
                  Top = 239
                  DataBinding.DataField = 'FORMA_PAGO_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.DropDownSizeable = True
                  Properties.KeyFieldNames = 'CODIGO_FP_FP'
                  Properties.ListColumns = <
                    item
                      Caption = 'C'#243'digo'
                      MinWidth = 50
                      Width = 60
                      FieldName = 'CODIGO_FP_FP'
                    end
                    item
                      Caption = 'Descripci'#243'n'
                      MinWidth = 160
                      Width = 220
                      FieldName = 'DESCRIPCION_FORMA_PAGO_FP'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  TabOrder = 11
                  Width = 130
                end
                object chkTotalesESIVA_RECARGO_COMPRAS_SES: TcxDBCheckBox
                  Left = 107
                  Top = 270
                  Caption = 'Recargo equivalencia compras'
                  DataBinding.DataField = 'ESIVA_RECARGO_COMPRAS_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Properties.OnChange = chkRecargoComprasPropertiesChange
                  Style.TransparentBorder = False
                  TabOrder = 12
                  Transparent = True
                end
                object lblDtoComercialSes: TcxLabel
                  Left = 95
                  Top = 7
                  Caption = 'Dto. comercial'
                  TabOrder = 13
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_DTO_COMERCIAL_SES: TcxDBSpinEdit
                  Left = 220
                  Top = 3
                  DataBinding.DataField = 'PORCENTAJE_DTO_COMERCIAL_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 14
                  Width = 60
                end
                object curTotalesTOTAL_DTO_COMERCIAL_SES: TcxDBCurrencyEdit
                  Left = 286
                  Top = 3
                  DataBinding.DataField = 'TOTAL_DTO_COMERCIAL_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 15
                  Width = 64
                end
                object lblDtoFinancieroSes: TcxLabel
                  Left = 93
                  Top = 43
                  Caption = 'Dto. financiero'
                  TabOrder = 16
                  Transparent = True
                end
                object spnTotalesPORCENTAJE_DTO_FINANCIERO_SES: TcxDBSpinEdit
                  Left = 220
                  Top = 39
                  DataBinding.DataField = 'PORCENTAJE_DTO_FINANCIERO_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.AssignedValues.MinValue = True
                  Properties.DisplayFormat = '0.00 %'
                  Properties.EditFormat = '0.00 %'
                  Properties.MaxValue = 100.000000000000000000
                  TabOrder = 17
                  Width = 60
                end
                object curTotalesTOTAL_DTO_FINANCIERO_SES: TcxDBCurrencyEdit
                  Left = 286
                  Top = 39
                  DataBinding.DataField = 'TOTAL_DTO_FINANCIERO_SES'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 18
                  Width = 64
                end
                object grpDesgloseIvaSes: TGroupBox
                  Left = 384
                  Top = 22
                  Width = 548
                  Height = 286
                  Caption = 'Desglose IVA'
                  TabOrder = 19
                  object lblTotSesBase: TcxLabel
                    Left = 126
                    Top = 34
                    Caption = 'Base'
                    TabOrder = 0
                    Transparent = True
                  end
                  object lblTotSesPorIva: TcxLabel
                    Left = 236
                    Top = 34
                    Caption = '% IVA'
                    TabOrder = 1
                    Transparent = True
                  end
                  object lblTotSesTotalIva: TcxLabel
                    Left = 294
                    Top = 34
                    Caption = 'Total IVA'
                    TabOrder = 2
                    Transparent = True
                  end
                  object lblTotSesPorRe: TcxLabel
                    Left = 386
                    Top = 34
                    Caption = '% R.E.'
                    TabOrder = 3
                    Transparent = True
                  end
                  object lblTotSesTotalRe: TcxLabel
                    Left = 446
                    Top = 34
                    Caption = 'Total R.E.'
                    TabOrder = 4
                    Transparent = True
                  end
                  object lblTotSesIVAN: TcxLabel
                    Left = 70
                    Top = 74
                    Caption = 'Normal'
                    TabOrder = 5
                    Transparent = True
                  end
                  object lblTotSesIVAR: TcxLabel
                    Left = 53
                    Top = 122
                    Caption = 'Reducido'
                    TabOrder = 6
                    Transparent = True
                  end
                  object lblTotSesIVAS: TcxLabel
                    Left = 13
                    Top = 170
                    Caption = 'S'#250'per reducido'
                    TabOrder = 7
                    Transparent = True
                  end
                  object lblTotSesIVAE: TcxLabel
                    Left = 73
                    Top = 218
                    Caption = 'Exento'
                    TabOrder = 8
                    Transparent = True
                  end
                  object curTotSesTOTAL_BASEI_IVAN_SES: TcxDBCurrencyEdit
                    Left = 125
                    Top = 70
                    DataBinding.DataField = 'TOTAL_BASEI_IVAN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 9
                    Width = 95
                  end
                  object curTotSesTOTAL_BASEI_IVAR_SES: TcxDBCurrencyEdit
                    Left = 125
                    Top = 118
                    DataBinding.DataField = 'TOTAL_BASEI_IVAR_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 10
                    Width = 95
                  end
                  object curTotSesTOTAL_BASEI_IVAS_SES: TcxDBCurrencyEdit
                    Left = 125
                    Top = 166
                    DataBinding.DataField = 'TOTAL_BASEI_IVAS_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 11
                    Width = 95
                  end
                  object curTotSesTOTAL_BASEI_IVAE_SES: TcxDBCurrencyEdit
                    Left = 125
                    Top = 214
                    DataBinding.DataField = 'TOTAL_BASEI_IVAE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 12
                    Width = 95
                  end
                  object spnTotSesPORCENTAJE_IVAN_SES: TcxDBSpinEdit
                    Left = 226
                    Top = 70
                    DataBinding.DataField = 'PORCENTAJE_IVAN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 13
                    Width = 55
                  end
                  object spnTotSesPORCENTAJE_IVAR_SES: TcxDBSpinEdit
                    Left = 226
                    Top = 118
                    DataBinding.DataField = 'PORCENTAJE_IVAR_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 14
                    Width = 55
                  end
                  object spnTotSesPORCENTAJE_IVAS_SES: TcxDBSpinEdit
                    Left = 226
                    Top = 166
                    DataBinding.DataField = 'PORCENTAJE_IVAS_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 15
                    Width = 55
                  end
                  object spnTotSesPORCENTAJE_IVAE_SES: TcxDBSpinEdit
                    Left = 226
                    Top = 214
                    DataBinding.DataField = 'PORCENTAJE_IVAE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0 %'
                    Properties.EditFormat = '0 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 16
                    Width = 55
                  end
                  object curTotSesTOTAL_IVAN_SES: TcxDBCurrencyEdit
                    Left = 286
                    Top = 70
                    DataBinding.DataField = 'TOTAL_IVAN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 17
                    Width = 86
                  end
                  object curTotSesTOTAL_IVAR_SES: TcxDBCurrencyEdit
                    Left = 286
                    Top = 118
                    DataBinding.DataField = 'TOTAL_IVAR_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 18
                    Width = 86
                  end
                  object curTotSesTOTAL_IVAS_SES: TcxDBCurrencyEdit
                    Left = 286
                    Top = 166
                    DataBinding.DataField = 'TOTAL_IVAS_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 19
                    Width = 86
                  end
                  object curTotSesTOTAL_IVAE_SES: TcxDBCurrencyEdit
                    Left = 286
                    Top = 214
                    DataBinding.DataField = 'TOTAL_IVAE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 20
                    Width = 86
                  end
                  object spnTotSesPORCENTAJE_REN_SES: TcxDBSpinEdit
                    Left = 384
                    Top = 70
                    DataBinding.DataField = 'PORCENTAJE_REN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 21
                    Width = 55
                  end
                  object spnTotSesPORCENTAJE_RER_SES: TcxDBSpinEdit
                    Left = 384
                    Top = 118
                    DataBinding.DataField = 'PORCENTAJE_RER_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 22
                    Width = 55
                  end
                  object spnTotSesPORCENTAJE_RES_SES: TcxDBSpinEdit
                    Left = 384
                    Top = 166
                    DataBinding.DataField = 'PORCENTAJE_RES_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 23
                    Width = 55
                  end
                  object spnTotSesPORCENTAJE_REE_SES: TcxDBSpinEdit
                    Left = 384
                    Top = 214
                    DataBinding.DataField = 'PORCENTAJE_REE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.ReadOnly = True
                    Properties.SpinButtons.Visible = False
                    Style.BorderStyle = ebsNone
                    TabOrder = 24
                    Width = 55
                  end
                  object curTotSesTOTAL_REN_SES: TcxDBCurrencyEdit
                    Left = 444
                    Top = 70
                    DataBinding.DataField = 'TOTAL_REN_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 25
                    Width = 78
                  end
                  object curTotSesTOTAL_RER_SES: TcxDBCurrencyEdit
                    Left = 444
                    Top = 118
                    DataBinding.DataField = 'TOTAL_RER_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 26
                    Width = 78
                  end
                  object curTotSesTOTAL_RES_SES: TcxDBCurrencyEdit
                    Left = 444
                    Top = 166
                    DataBinding.DataField = 'TOTAL_RES_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 27
                    Width = 78
                  end
                  object curTotSesTOTAL_REE_SES: TcxDBCurrencyEdit
                    Left = 444
                    Top = 214
                    DataBinding.DataField = 'TOTAL_REE_SES'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    Style.BorderStyle = ebsNone
                    TabOrder = 28
                    Width = 78
                  end
                end
              end
            end
            object tsDocumentos: TcxTabSheet
              Caption = '&3_Documentos creados'
              ImageIndex = 1
              ExplicitHeight = 371
              object pnlDocsTop: TPanel
                Left = 0
                Top = 0
                Width = 1082
                Height = 40
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object btnIrADoc: TcxButton
                  Left = 12
                  Top = 6
                  Width = 200
                  Height = 28
                  Caption = 'Ir a documento'
                  LookAndFeel.Kind = lfFlat
                  LookAndFeel.NativeStyle = False
                  TabOrder = 0
                  OnClick = btnIrADocClick
                end
                object lblDocsInfo: TcxLabel
                  Left = 224
                  Top = 10
                  Caption = 
                    'Pedidos y albaranes generados al materializar la sesi'#243'n. Doble c' +
                    'lick o el bot'#243'n lateral "Ir a Ped / Alb" navega al documento.'
                  TabOrder = 1
                  Transparent = True
                end
              end
              object cxgrdDocs: TcxGrid
                Left = 0
                Top = 40
                Width = 1082
                Height = 332
                Align = alClient
                TabOrder = 1
                ExplicitHeight = 331
                object tvDocs: TcxGridDBTableView
                  OnDblClick = tvDocsDblClick
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object dbcDocTipo: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO'
                    Width = 80
                  end
                  object dbcDocSerie: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE'
                    Width = 80
                  end
                  object dbcDocNumero: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO'
                    Width = 120
                  end
                  object dbcDocAlmacen: TcxGridDBColumn
                    Caption = 'Almac'#233'n'
                    DataBinding.FieldName = 'ALMACEN'
                    Width = 140
                  end
                  object dbcDocInstante: TcxGridDBColumn
                    Caption = 'Fecha alta'
                    DataBinding.FieldName = 'INSTANTE'
                    Width = 150
                  end
                  object dbcDocUsuario: TcxGridDBColumn
                    Caption = 'Usuario'
                    DataBinding.FieldName = 'USUARIO'
                    Width = 120
                  end
                end
                object glDocs: TcxGridLevel
                  GridView = tvDocs
                end
              end
            end
            object tsProveedor: TcxTabSheet
              Caption = '&4_Proveedor'
              ImageIndex = 2
              ExplicitHeight = 371
              object pnlProvIzq: TPanel
                Left = 0
                Top = 0
                Width = 560
                Height = 372
                Align = alLeft
                BevelOuter = bvNone
                TabOrder = 0
                ExplicitHeight = 371
                object gbProvFicha: TcxGroupBox
                  Left = 0
                  Top = 0
                  Align = alClient
                  Caption = ' Datos del proveedor '
                  TabOrder = 0
                  ExplicitHeight = 371
                  Height = 372
                  Width = 560
                  object lblProvCodigo: TcxLabel
                    Left = 12
                    Top = 28
                    Caption = 'C'#243'digo'
                    TabOrder = 0
                    Transparent = True
                  end
                  object txtProvCodigo: TcxDBTextEdit
                    Left = 110
                    Top = 24
                    DataBinding.DataField = 'CODIGO_PRV_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 1
                    Width = 120
                  end
                  object lblProvNif: TcxLabel
                    Left = 292
                    Top = 28
                    Caption = 'NIF'
                    TabOrder = 2
                    Transparent = True
                  end
                  object txtProvNif: TcxDBTextEdit
                    Left = 392
                    Top = 24
                    DataBinding.DataField = 'NIF_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 3
                    Width = 152
                  end
                  object lblProvRazon: TcxLabel
                    Left = 12
                    Top = 56
                    Caption = 'Raz'#243'n social'
                    TabOrder = 4
                    Transparent = True
                  end
                  object txtProvRazon: TcxDBTextEdit
                    Left = 110
                    Top = 52
                    DataBinding.DataField = 'RAZON_SOCIAL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 5
                    Width = 434
                  end
                  object lblProvNombre: TcxLabel
                    Left = 12
                    Top = 84
                    Caption = 'Nombre com.'
                    TabOrder = 6
                    Transparent = True
                  end
                  object txtProvNombre: TcxDBTextEdit
                    Left = 110
                    Top = 80
                    DataBinding.DataField = 'NOMBRE_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 7
                    Width = 434
                  end
                  object lblProvTelefono: TcxLabel
                    Left = 12
                    Top = 112
                    Caption = 'Tel'#233'fono'
                    TabOrder = 8
                    Transparent = True
                  end
                  object txtProvTelefono: TcxDBTextEdit
                    Left = 110
                    Top = 108
                    DataBinding.DataField = 'TELEFONO_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 9
                    Width = 168
                  end
                  object lblProvMovil: TcxLabel
                    Left = 292
                    Top = 112
                    Caption = 'M'#243'vil'
                    TabOrder = 10
                    Transparent = True
                  end
                  object txtProvMovil: TcxDBTextEdit
                    Left = 392
                    Top = 108
                    DataBinding.DataField = 'MOVIL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 11
                    Width = 152
                  end
                  object lblProvEmail: TcxLabel
                    Left = 12
                    Top = 140
                    Caption = 'Email'
                    TabOrder = 12
                    Transparent = True
                  end
                  object txtProvEmail: TcxDBTextEdit
                    Left = 110
                    Top = 136
                    DataBinding.DataField = 'EMAIL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 13
                    Width = 434
                  end
                  object lblProvDireccion: TcxLabel
                    Left = 12
                    Top = 168
                    Caption = 'Direcci'#243'n'
                    TabOrder = 14
                    Transparent = True
                  end
                  object txtProvDireccion: TcxDBTextEdit
                    Left = 110
                    Top = 164
                    DataBinding.DataField = 'DIRECCION1_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 15
                    Width = 434
                  end
                  object lblProvPoblacion: TcxLabel
                    Left = 12
                    Top = 196
                    Caption = 'Poblaci'#243'n'
                    TabOrder = 16
                    Transparent = True
                  end
                  object txtProvPoblacion: TcxDBTextEdit
                    Left = 110
                    Top = 192
                    DataBinding.DataField = 'POBLACION_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 17
                    Width = 168
                  end
                  object lblProvProvincia: TcxLabel
                    Left = 292
                    Top = 196
                    Caption = 'Provincia'
                    TabOrder = 18
                    Transparent = True
                  end
                  object txtProvProvincia: TcxDBTextEdit
                    Left = 392
                    Top = 192
                    DataBinding.DataField = 'PROVINCIA_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 19
                    Width = 152
                  end
                  object lblProvCPostal: TcxLabel
                    Left = 12
                    Top = 224
                    Caption = 'C. Postal'
                    TabOrder = 20
                    Transparent = True
                  end
                  object txtProvCPostal: TcxDBTextEdit
                    Left = 110
                    Top = 220
                    DataBinding.DataField = 'CODIGO_POSTAL_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 21
                    Width = 168
                  end
                  object lblProvPais: TcxLabel
                    Left = 292
                    Top = 224
                    Caption = 'Pa'#237's'
                    TabOrder = 22
                    Transparent = True
                  end
                  object txtProvPais: TcxDBTextEdit
                    Left = 392
                    Top = 220
                    DataBinding.DataField = 'PAIS_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 23
                    Width = 152
                  end
                  object lblProvContacto: TcxLabel
                    Left = 12
                    Top = 252
                    Caption = 'Contacto'
                    TabOrder = 24
                    Transparent = True
                  end
                  object txtProvContacto: TcxDBTextEdit
                    Left = 110
                    Top = 248
                    DataBinding.DataField = 'CONTACTO_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 25
                    Width = 168
                  end
                  object lblProvTelContacto: TcxLabel
                    Left = 292
                    Top = 252
                    Caption = 'Tel. contacto'
                    TabOrder = 26
                    Transparent = True
                  end
                  object txtProvTelContacto: TcxDBTextEdit
                    Left = 392
                    Top = 248
                    DataBinding.DataField = 'TELEFONO_CONTACTO_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 27
                    Width = 152
                  end
                  object lblProvMargen: TcxLabel
                    Left = 12
                    Top = 284
                    Caption = 'Margen %'
                    TabOrder = 28
                    Transparent = True
                  end
                  object txtProvMargen: TcxDBTextEdit
                    Left = 110
                    Top = 280
                    DataBinding.DataField = 'PORCENTAJE_MARGEN_PRV'
                    DataBinding.DataSource = dsPrvFicha
                    Properties.ReadOnly = True
                    TabOrder = 29
                    Width = 90
                  end
                  object btnIrProveedor: TcxButton
                    Left = 110
                    Top = 316
                    Width = 200
                    Height = 28
                    Caption = 'Ir a proveedor (ficha)'
                    LookAndFeel.Kind = lfFlat
                    LookAndFeel.NativeStyle = False
                    TabOrder = 30
                    OnClick = btnIrProveedorClick
                  end
                end
              end
              object gbProvKits: TcxGroupBox
                Left = 560
                Top = 0
                Align = alClient
                Caption = ' Kits de cantidades por talla '
                TabOrder = 1
                ExplicitHeight = 371
                Height = 372
                Width = 522
                object pnlProvKitsTop: TPanel
                  Left = 2
                  Top = 22
                  Width = 518
                  Height = 36
                  Align = alTop
                  BevelOuter = bvNone
                  TabOrder = 0
                  object btnAplicarKitProv: TcxButton
                    Left = 8
                    Top = 4
                    Width = 230
                    Height = 28
                    Caption = 'Aplicar kit a la l'#237'nea actual'
                    Colors.Default = 12579775
                    Colors.Normal = 12579775
                    LookAndFeel.Kind = lfFlat
                    LookAndFeel.NativeStyle = False
                    TabOrder = 0
                    OnClick = btnAplicarKitProvClick
                  end
                  object lblProvKitsHint: TcxLabel
                    Left = 246
                    Top = 9
                    Caption = 'Doble click tambi'#233'n aplica. Se definen en Proveedores.'
                    TabOrder = 1
                    Transparent = True
                  end
                end
                object cxgrdPrvKits: TcxGrid
                  Left = 2
                  Top = 58
                  Width = 308
                  Height = 312
                  Align = alClient
                  TabOrder = 1
                  ExplicitHeight = 311
                  object tvPrvKits: TcxGridDBTableView
                    OnDblClick = tvPrvKitsDblClick
                    OptionsData.Deleting = False
                    OptionsData.DeletingConfirmation = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    object dbcPrvKitCodigo: TcxGridDBColumn
                      Caption = 'Kit'
                      DataBinding.FieldName = 'CODIGO_PRVKIT'
                      Width = 90
                    end
                    object dbcPrvKitNombre: TcxGridDBColumn
                      Caption = 'Nombre'
                      DataBinding.FieldName = 'NOMBRE_PRVKIT'
                      Width = 130
                    end
                    object dbcPrvKitSistema: TcxGridDBColumn
                      Caption = 'Sistema tallas'
                      DataBinding.FieldName = 'NOMBRE_TALLAS_PRVKIT'
                      Width = 150
                    end
                  end
                  object glPrvKits: TcxGridLevel
                    GridView = tvPrvKits
                  end
                end
                object cxgrdPrvKitsDet: TcxGrid
                  Left = 310
                  Top = 58
                  Width = 210
                  Height = 312
                  Align = alRight
                  TabOrder = 2
                  ExplicitHeight = 311
                  object tvPrvKitsDet: TcxGridDBTableView
                    OptionsData.Deleting = False
                    OptionsData.DeletingConfirmation = False
                    OptionsData.Editing = False
                    OptionsData.Inserting = False
                    OptionsView.GroupByBox = False
                    object dbcPrvKitDetValor: TcxGridDBColumn
                      Caption = 'Talla'
                      DataBinding.FieldName = 'VALOR_DESTINO_PRVKITD'
                      Width = 80
                    end
                    object dbcPrvKitDetCantidad: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_PRVKITD'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Properties.DisplayFormat = '#,##0.##'
                      Width = 80
                    end
                  end
                  object glPrvKitsDet: TcxGridLevel
                    GridView = tvPrvKitsDet
                  end
                end
              end
            end
            object tsFotosProvisionales: TcxTabSheet
              Caption = '&5_Fotos provisionales'
              ImageIndex = 4
              object cxgrdFotosProvisionales: TcxGrid
                Left = 0
                Top = 0
                Width = 1082
                Height = 372
                Align = alClient
                TabOrder = 0
                object tvFotosProvisionales: TcxGridDBTableView
                  OptionsBehavior.IncSearch = True
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object dbcFotoLinea: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_CSF'
                    Width = 65
                  end
                  object dbcFotoArticulo: TcxGridDBColumn
                    Caption = 'C'#243'd. art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ART_TENTATIVO_CSF'
                    Width = 125
                  end
                  object dbcFotoModeloProveedor: TcxGridDBColumn
                    Caption = 'Modelo prov.'
                    DataBinding.FieldName = 'REF_PRV_SESLIN'
                    Width = 120
                  end
                  object dbcFotoDescripcion: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_SESLIN'
                    Width = 230
                  end
                  object dbcFotoColor: TcxGridDBColumn
                    Caption = 'Color'
                    DataBinding.FieldName = 'COLOR_TEXTO_SESLIN'
                    Width = 110
                  end
                  object dbcFotoUnidad: TcxGridDBColumn
                    Caption = 'Asignada a'
                    DataBinding.FieldName = 'ASIGNACION_FOTO'
                    Width = 120
                  end
                  object dbcFotoFichero: TcxGridDBColumn
                    Caption = 'Fichero'
                    DataBinding.FieldName = 'NOMBRE_FOT_CSF'
                    Width = 170
                  end
                  object dbcFotoInstante: TcxGridDBColumn
                    Caption = 'Modificada'
                    DataBinding.FieldName = 'INSTANTE_MODIF'
                    Width = 130
                  end
                  object dbcFotoUsuario: TcxGridDBColumn
                    Caption = 'Usuario'
                    DataBinding.FieldName = 'USUARIO_MODIF'
                    Width = 100
                  end
                end
                object glFotosProvisionales: TcxGridLevel
                  GridView = tvFotosProvisionales
                end
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 297
          Width = 1092
          Height = 8
          Cursor = crSizeNS
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          HotZoneClassName = 'TcxMediaPlayer9Style'
          HotZone.SizePercent = 50
          AlignSplitter = salTop
          ExplicitLeft = 17
          ExplicitTop = 291
        end
        object cxPageControl1: TcxPageControl
          Left = 0
          Top = 0
          Width = 1092
          Height = 297
          Align = alTop
          TabOrder = 2
          Properties.ActivePage = cxTabSheet2
          Properties.CustomButtons.Buttons = <>
          ExplicitTop = 8
          ClientRectBottom = 293
          ClientRectLeft = 4
          ClientRectRight = 1088
          ClientRectTop = 28
          object cxTabSheet2: TcxTabSheet
            Caption = 'Datos Cabecera'
            ImageIndex = 0
            object gbCabecera: TcxGroupBox
              Left = 0
              Top = 0
              Align = alTop
              TabOrder = 0
              Height = 241
              Width = 1084
              object lblSerie: TcxLabel
                Left = 12
                Top = 24
                Caption = 'Serie'
                TabOrder = 0
                Transparent = True
              end
              object cbbSerie: TcxDBComboBox
                Left = 80
                Top = 20
                DataBinding.DataField = 'SERIE_SES'
                DataBinding.DataSource = dsTablaG
                Properties.CharCase = ecUpperCase
                Properties.MaxLength = 12
                Properties.OnInitPopup = cbbSeriePropertiesInitPopup
                TabOrder = 1
                Width = 70
              end
              object lblNumero: TcxLabel
                Left = 164
                Top = 24
                Caption = 'N'#250'mero'
                TabOrder = 2
                Transparent = True
              end
              object txtNumero: TcxDBTextEdit
                Left = 232
                Top = 20
                DataBinding.DataField = 'NUMERO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 3
                Width = 70
              end
              object lblFecha: TcxLabel
                Left = 316
                Top = 24
                Caption = 'Fecha'
                TabOrder = 4
                Transparent = True
              end
              object dteFecha: TcxDBDateEdit
                Left = 380
                Top = 20
                DataBinding.DataField = 'FECHA_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 5
                Width = 120
              end
              object lblFechaTopeRecepcion: TcxLabel
                Left = 517
                Top = 24
                Caption = 'F.tope recep.'
                TabOrder = 21
                Transparent = True
              end
              object dteFechaTopeRecepcion: TcxDBDateEdit
                Left = 627
                Top = 20
                DataBinding.DataField = 'FECHA_TOPE_RECEPCION_SES'
                DataBinding.DataSource = dsTablaG
                TabOrder = 22
                Width = 120
              end
              object lblEstado: TcxLabel
                Left = 380
                Top = 151
                Caption = 'Estado'
                TabOrder = 12
                Transparent = True
              end
              object txtEstado: TcxDBTextEdit
                Left = 440
                Top = 147
                DataBinding.DataField = 'ESTADO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ReadOnly = True
                TabOrder = 13
                Width = 100
              end
              object lblEmpresa: TcxLabel
                Left = 12
                Top = 67
                Caption = 'Empresa'
                TabOrder = 6
                Transparent = True
              end
              object cbbEmpresa: TcxDBLookupComboBox
                Left = 92
                Top = 63
                DataBinding.DataField = 'CODIGO_EMP_SES'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO_EMP_EMP'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 60
                    FieldName = 'CODIGO_EMP_EMP'
                  end
                  item
                    Caption = 'Empresa'
                    FieldName = 'RAZON_SOCIAL_EMP'
                  end>
                Properties.ListFieldIndex = 1
                Properties.ListOptions.ShowHeader = False
                TabOrder = 7
                Width = 268
              end
              object lblProveedor: TcxLabel
                Left = 380
                Top = 67
                Caption = 'Proveedor'
                TabOrder = 8
                Transparent = True
              end
              object cbbProveedor: TcxDBLookupComboBox
                Left = 470
                Top = 63
                DataBinding.DataField = 'CODIGO_PRV_SES'
                DataBinding.DataSource = dsTablaG
                Properties.DropDownListStyle = lsEditList
                Properties.DropDownRows = 15
                Properties.DropDownWidth = 480
                Properties.ImmediateDropDownWhenKeyPressed = True
                Properties.IncrementalFiltering = True
                Properties.KeyFieldNames = 'CODIGO_PRV_PRV'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 110
                    FieldName = 'CODIGO_PRV_PRV'
                  end
                  item
                    Caption = 'Proveedor'
                    Width = 350
                    FieldName = 'RAZON_SOCIAL_PRV'
                  end>
                Properties.ListFieldIndex = 1
                Properties.ListOptions.CaseInsensitive = True
                TabOrder = 9
                OnKeyUp = cbbProveedorKeyUp
                Width = 160
              end
              object lblRefPrv: TcxLabel
                Left = 7
                Top = 151
                Caption = 'Ref. prov.'
                TabOrder = 10
                Transparent = True
              end
              object txtRefPrv: TcxDBTextEdit
                Left = 92
                Top = 147
                DataBinding.DataField = 'REF_PRV_SES'
                DataBinding.DataSource = dsTablaG
                Properties.MaxLength = 100
                TabOrder = 11
                Width = 190
              end
              object lblAlmacen: TcxLabel
                Left = 12
                Top = 111
                Caption = 'Almac'#233'n'
                TabOrder = 14
                Transparent = True
              end
              object cbbAlmacen: TcxDBLookupComboBox
                Left = 92
                Top = 107
                DataBinding.DataField = 'CODIGO_ALM_SES'
                DataBinding.DataSource = dsTablaG
                Properties.KeyFieldNames = 'CODIGO_ALM_ALM'
                Properties.ListColumns = <
                  item
                    Caption = 'C'#243'digo'
                    Width = 60
                    FieldName = 'CODIGO_ALM_ALM'
                  end
                  item
                    Caption = 'Almac'#233'n'
                    FieldName = 'NOMBRE_ALM_ALM'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 15
                Width = 200
              end
              object chkFormatoDistribuido: TcxDBCheckBox
                Left = 380
                Top = 111
                Caption = 'Formato distribuido (por almac'#233'n)'
                DataBinding.DataField = 'ESFORMATO_DISTRIBUIDO_SES'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                Style.TransparentBorder = False
                TabOrder = 16
                Transparent = True
              end
              object lblProveedorNombre: TcxLabel
                Left = 639
                Top = 67
                ParentFont = False
                Style.Font.Charset = ANSI_CHARSET
                Style.Font.Color = clWindowText
                Style.Font.Height = -15
                Style.Font.Name = 'Lucida Sans'
                Style.Font.Style = [fsBold]
                Style.IsFontAssigned = True
                TabOrder = 17
                Transparent = True
              end
              object lblKitProv: TcxLabel
                Left = 12
                Top = 192
                Caption = 'Kit a aplicar'
                TabOrder = 18
                Transparent = True
              end
              object cbbKitProv: TcxLookupComboBox
                Left = 110
                Top = 188
                Properties.KeyFieldNames = 'CODIGO_PRVKIT'
                Properties.ListColumns = <
                  item
                    FieldName = 'ETIQUETA_KIT'
                  end>
                Properties.ListOptions.ShowHeader = False
                TabOrder = 19
                Width = 320
              end
              object btnAplicarKitCab: TcxButton
                Left = 440
                Top = 187
                Width = 160
                Height = 27
                Caption = 'Aplicar kit a la l'#237'nea'
                Colors.Default = 12579775
                Colors.Normal = 12579775
                LookAndFeel.Kind = lfFlat
                LookAndFeel.NativeStyle = False
                TabOrder = 20
                OnClick = btnAplicarKitCabClick
              end
            end
          end
          object cxTabSheet3: TcxTabSheet
            Caption = 'Ajustes Documento'
            ImageIndex = 1
            object lblTemporada: TcxLabel
              Left = 17
              Top = 23
              Caption = 'Temporada'
              TabOrder = 0
              Transparent = True
            end
            object cbbTemporada: TcxDBLookupComboBox
              Left = 110
              Top = 19
              DataBinding.DataField = 'ID_PV_TEMPORADA_SES'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'ID_PV_ARTPROP'
              Properties.ListColumns = <
                item
                  Caption = 'Temporada'
                  FieldName = 'PV'
                end>
              Properties.ListOptions.ShowHeader = False
              TabOrder = 1
              Width = 220
            end
            object cbbTarifa: TcxDBLookupComboBox
              Left = 112
              Top = 67
              DataBinding.DataField = 'CODIGO_TAR_SES'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
              Properties.ListColumns = <
                item
                  Caption = 'Tarifa'
                  FieldName = 'NOMBRE_TAR_TAR'
                end>
              Properties.ListOptions.ShowHeader = False
              TabOrder = 2
              Width = 186
            end
            object lblTarifa: TcxLabel
              Left = 13
              Top = 71
              Caption = 'Tarifa venta'
              TabOrder = 3
              Transparent = True
            end
            object lblMargen: TcxLabel
              Left = 20
              Top = 128
              Caption = 'Margen %'
              TabOrder = 4
              Transparent = True
            end
            object spnMargen: TcxDBSpinEdit
              Left = 110
              Top = 126
              DataBinding.DataField = 'PORCENTAJE_MARGEN_SES'
              DataBinding.DataSource = dsTablaG
              Properties.ValueType = vtFloat
              TabOrder = 5
              Width = 92
            end
            object lblMultiploRedondeo: TcxLabel
              Left = 12
              Top = 176
              Caption = 'Redondeo'
              TabOrder = 6
              Transparent = True
            end
            object spnMultiploRedondeo: TcxDBSpinEdit
              Left = 112
              Top = 173
              DataBinding.DataField = 'MULTIPLO_REDONDEO_SES'
              DataBinding.DataSource = dsTablaG
              Properties.Increment = 0.050000000000000000
              Properties.ValueType = vtFloat
              TabOrder = 7
              Width = 90
            end
            object lblAjusteFinal: TcxLabel
              Left = 10
              Top = 221
              Caption = 'Ajuste final'
              TabOrder = 8
              Transparent = True
            end
            object spnAjusteFinal: TcxDBSpinEdit
              Left = 110
              Top = 219
              DataBinding.DataField = 'AJUSTE_FINAL_SES'
              DataBinding.DataSource = dsTablaG
              Properties.Increment = 0.010000000000000000
              Properties.MaxValue = 10.000000000000000000
              Properties.MinValue = -10.000000000000000000
              Properties.ValueType = vtFloat
              TabOrder = 9
              Width = 90
            end
            object chkVariosTiposIva: TcxDBCheckBox
              Left = 272
              Top = 126
              Caption = 'Varios tipos IVA'
              DataBinding.DataField = 'ESVARIOS_TIPOS_IVA_SES'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Properties.OnChange = chkVariosTiposIvaPropertiesChange
              Style.TransparentBorder = False
              TabOrder = 10
              Transparent = True
            end
            object lblTipoIvaDefecto: TcxLabel
              Left = 432
              Top = 127
              Caption = 'IVA defecto'
              TabOrder = 11
              Transparent = True
            end
            object cbbTipoIvaDefecto: TcxDBComboBox
              Left = 529
              Top = 126
              DataBinding.DataField = 'TIPO_IVA_SES'
              DataBinding.DataSource = dsTablaG
              Properties.DropDownListStyle = lsFixedList
              Properties.Items.Strings = (
                'N'
                'R'
                'S'
                'E')
              Properties.OnChange = cbbTipoIvaDefectoPropertiesChange
              TabOrder = 12
              Width = 60
            end
          end
        end
        object gbFotoProvisional: TcxGroupBox
          Left = 770
          Top = 36
          Anchors = [akTop, akRight]
          Caption = ' Foto provisional de la l'#237'nea '
          TabOrder = 3
          Height = 250
          Width = 310
          object imgFotoProvisional: TImage
            Left = 8
            Top = 24
            Width = 294
            Height = 184
            Anchors = [akLeft, akTop, akRight, akBottom]
            Center = True
            Proportional = True
            Stretch = True
          end
          object lblFotoProvisionalAsignacion: TcxLabel
            Left = 8
            Top = 212
            Anchors = [akLeft, akRight, akBottom]
            AutoSize = False
            Caption = 'Seleccione una l'#237'nea de la sesi'#243'n.'
            Properties.Alignment.Horz = taCenter
            Properties.WordWrap = True
            TabOrder = 0
            Transparent = True
            Height = 30
            Width = 294
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 28
        ExplicitWidth = 1092
        ExplicitHeight = 648
        inherited pnlPerfilTop: TPanel
          Width = 1092
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1092
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 25
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1092
          Height = 654
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1092
          ExplicitHeight = 591
          inherited cxgrdPerfil: TcxGrid
            Width = 1092
            Height = 654
            ExplicitWidth = 1092
            ExplicitHeight = 591
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1100
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1100
      inherited pnlTopGrid: TPanel
        Width = 1100
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1100
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 1100
    Height = 783
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 1100
    ExplicitHeight = 720
    inherited pButtonGen: TPanel
      Top = 585
      TabOrder = 4
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 522
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
    object btnCrear: TcxButton
      Left = 0
      Top = 230
      Width = 137
      Height = 69
      Caption = 'Crear Art. y Docs.'
      Colors.Default = 9101247
      Colors.Normal = 9101247
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 1
      WordWrap = True
      OnClick = btnCrearClick
    end
    object btnRevertir: TcxButton
      Left = 0
      Top = 308
      Width = 137
      Height = 40
      Caption = 'Revertir materializaci'#243'n'
      Colors.Default = 11337471
      Colors.Normal = 11337471
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 2
      WordWrap = True
      OnClick = btnRevertirClick
    end
    object btnImprimir: TcxButton
      Left = 0
      Top = 358
      Width = 137
      Height = 69
      Caption = 'Imprimir horizontal'
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 3
      WordWrap = True
      OnClick = btnImprimirClick
    end
    object btnIrPedAlb: TcxButton
      Left = 0
      Top = 437
      Width = 137
      Height = 40
      Caption = 'Ir a Ped / Alb'
      LookAndFeel.Kind = lfFlat
      LookAndFeel.NativeStyle = False
      TabOrder = 5
      WordWrap = True
      OnClick = btnIrADocClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 616
    Top = 656
  end
  inherited dsTablaG: TDataSource
    Left = 392
    Top = 656
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 808
    Top = 664
  end
  inherited tmrBusqGlobal: TTimer
    Left = 504
    Top = 656
  end
  inherited alMtoGen: TActionList
    Left = 704
    Top = 656
  end
  object dlgFoto: TOpenDialog
    Filter = 
      'Imagenes (*.png;*.jpg;*.jpeg;*.webp;*.avif;*.bmp)|*.png;*.jpg;*.' +
      'jpeg;*.webp;*.avif;*.bmp'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 920
    Top = 8
  end
  object alNavegacion: TActionList
    Left = 1000
    Top = 8
    object actIrArticulos: TAction
      Caption = 'Ir a Art'#237'culos'
      ShortCut = 16449
      OnExecute = actIrArticulosExecute
    end
    object actIrAlbaranesCompra: TAction
      Caption = 'Ir a Albaranes de Compra'
      ShortCut = 24641
      OnExecute = actIrAlbaranesCompraExecute
    end
    object actIrPedidosCompra: TAction
      Caption = 'Ir a Pedidos de Compra'
      ShortCut = 24656
      OnExecute = actIrPedidosCompraExecute
    end
    object actIrProveedor: TAction
      Caption = 'Ir a Proveedor'
      ShortCut = 16464
      OnExecute = actIrProveedorExecute
    end
  end
  object dsPrvFicha: TDataSource
    Left = 1040
    Top = 8
  end
end
