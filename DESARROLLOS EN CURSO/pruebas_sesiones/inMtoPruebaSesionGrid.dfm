inherited frmMtoPruebaSesionGrid: TfrmMtoPruebaSesionGrid
  Caption = 'Prueba 01 - Sesion grid plano (crear articulos)'
  ClientHeight = 720
  ClientWidth = 1240
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  ExplicitWidth = 1240
  ExplicitHeight = 720
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 1100
    Height = 720
    ExplicitWidth = 1100
    ExplicitHeight = 720
    inherited pcPantalla: TcxPageControl
      Width = 1100
      Height = 680
      ExplicitWidth = 1100
      ExplicitHeight = 680
      ClientRectBottom = 676
      ClientRectRight = 1096
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 1092
        ExplicitHeight = 649
        inherited cxGrdPrincipal: TcxGrid
          Width = 1092
          Height = 649
          ExplicitWidth = 1092
          ExplicitHeight = 649
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
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 1092
        ExplicitHeight = 649
        object gbCabecera: TcxGroupBox
          Left = 4
          Top = 4
          Align = alTop
          Caption = ' Cabecera '
          TabOrder = 0
          Height = 130
          Width = 1084
          object lblSerie: TcxLabel
            Left = 12
            Top = 24
            Caption = 'Serie'
            TabOrder = 0
          end
          object txtSerie: TcxDBTextEdit
            Left = 80
            Top = 22
            DataBinding.DataField = 'SERIE_SES'
            DataBinding.DataSource = dsTablaG
            Properties.CharCase = ecUpperCase
            Properties.MaxLength = 12
            TabOrder = 1
            Width = 70
          end
          object lblNumero: TcxLabel
            Left = 164
            Top = 24
            Caption = 'N'#250'mero'
            TabOrder = 2
          end
          object txtNumero: TcxDBTextEdit
            Left = 232
            Top = 22
            DataBinding.DataField = 'NUMERO_SES'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 3
            Width = 70
          end
          object lblEstado: TcxLabel
            Left = 316
            Top = 24
            Caption = 'Estado'
            TabOrder = 4
          end
          object txtEstado: TcxDBTextEdit
            Left = 380
            Top = 22
            DataBinding.DataField = 'ESTADO_SES'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 5
            Width = 100
          end
          object lblEmpresa: TcxLabel
            Left = 12
            Top = 58
            Caption = 'Empresa'
            TabOrder = 6
          end
          object cbbEmpresa: TcxDBLookupComboBox
            Left = 80
            Top = 56
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
            Properties.ListOptions.ShowHeader = False
            TabOrder = 7
            Width = 280
          end
          object lblProveedor: TcxLabel
            Left = 380
            Top = 58
            Caption = 'Proveedor'
            TabOrder = 8
          end
          object cbbProveedor: TcxDBLookupComboBox
            Left = 470
            Top = 56
            DataBinding.DataField = 'CODIGO_PRV_SES'
            DataBinding.DataSource = dsTablaG
            Properties.KeyFieldNames = 'CODIGO_PRV_PRV'
            Properties.ListColumns = <
              item
                Caption = 'C'#243'digo'
                Width = 60
                FieldName = 'CODIGO_PRV_PRV'
              end
              item
                Caption = 'Proveedor'
                FieldName = 'RAZON_SOCIAL_PRV'
              end>
            Properties.ListOptions.ShowHeader = False
            TabOrder = 9
            Width = 280
          end
          object lblTarifa: TcxLabel
            Left = 770
            Top = 58
            Caption = 'Tarifa venta'
            TabOrder = 10
          end
          object cbbTarifa: TcxDBLookupComboBox
            Left = 870
            Top = 56
            DataBinding.DataField = 'CODIGO_TAR_SES'
            DataBinding.DataSource = dsTablaG
            Properties.KeyFieldNames = 'CODIGO_TAR_ARTTAR'
            Properties.ListColumns = <
              item
                Caption = 'Tarifa'
                FieldName = 'NOMBRE_TAR_TAR'
              end>
            Properties.ListOptions.ShowHeader = False
            TabOrder = 11
            Width = 180
          end
          object lblMargen: TcxLabel
            Left = 12
            Top = 92
            Caption = 'Margen %'
            TabOrder = 12
          end
          object spnMargen: TcxDBSpinEdit
            Left = 90
            Top = 90
            DataBinding.DataField = 'PORCENTAJE_MARGEN_SES'
            DataBinding.DataSource = dsTablaG
            Properties.Increment = 1.000000000000000000
            Properties.ValueType = vtFloat
            TabOrder = 13
            Width = 90
          end
          object lblMultiploRedondeo: TcxLabel
            Left = 200
            Top = 92
            Caption = 'M'#250'lt. redondeo'
            TabOrder = 14
          end
          object spnMultiploRedondeo: TcxDBSpinEdit
            Left = 320
            Top = 90
            DataBinding.DataField = 'MULTIPLO_REDONDEO_SES'
            DataBinding.DataSource = dsTablaG
            Properties.Increment = 0.050000000000000000
            Properties.ValueType = vtFloat
            TabOrder = 15
            Width = 90
          end
          object lblAjusteFinal: TcxLabel
            Left = 430
            Top = 92
            Caption = 'Ajuste final'
            TabOrder = 16
          end
          object spnAjusteFinal: TcxDBSpinEdit
            Left = 530
            Top = 90
            DataBinding.DataField = 'AJUSTE_FINAL_SES'
            DataBinding.DataSource = dsTablaG
            Properties.Increment = 0.010000000000000000
            Properties.MaxValue = 10.000000000000000000
            Properties.MinValue = -10.000000000000000000
            Properties.ValueType = vtFloat
            TabOrder = 17
            Width = 90
          end
        end
        object pnlLineasTop: TPanel
          Left = 4
          Top = 138
          Width = 1084
          Height = 36
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          object btnAddLinea: TcxButton
            Left = 4
            Top = 4
            Width = 110
            Height = 28
            Caption = '+ A'#241'adir l'#237'nea'
            TabOrder = 0
            OnClick = btnAddLineaClick
          end
          object btnDelLinea: TcxButton
            Left = 120
            Top = 4
            Width = 110
            Height = 28
            Caption = '- Borrar l'#237'nea'
            TabOrder = 1
            OnClick = btnDelLineaClick
          end
          object lblHint: TcxLabel
            Left = 248
            Top = 8
            Caption = 'F3 sobre Familia abre el selector. PVP se propone al teclear el coste.'
            TabOrder = 2
          end
        end
        object cxgrdLineas: TcxGrid
          Left = 4
          Top = 178
          Width = 1084
          Height = 467
          Align = alClient
          TabOrder = 2
          object tvLineas: TcxGridDBTableView
            OnFocusedRecordChanged = tvLineasFocusedRecordChanged
            OnInitEdit = tvLineasInitEdit
            OnEditKeyDown = tvLineasEditKeyDown
            OnCustomDrawCell = tvLineasCustomDrawCell
            NavigatorButtons.ConfirmDelete = False
            object dbcLinFamilia: TcxGridDBColumn
              Caption = 'Familia (F3)'
              DataBinding.FieldName = 'CODIGO_FAM_SESLIN'
              Width = 110
            end
            object dbcLinCodArt: TcxGridDBColumn
              Caption = 'C'#243'd. art'#237'culo'
              DataBinding.FieldName = 'CODIGO_ART_TENTATIVO_SESLIN'
              Options.Editing = False
              Width = 130
            end
            object dbcLinRefPrv: TcxGridDBColumn
              Caption = 'Modelo prov.'
              DataBinding.FieldName = 'REF_PRV_SESLIN'
              Width = 130
            end
            object dbcLinDescripcion: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_SESLIN'
              Width = 200
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
              Caption = 'Pr. compra'
              DataBinding.FieldName = 'PRECIO_COMPRA_SESLIN'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Properties.OnEditValueChanged = dbcLinPrecioCompraPropertiesEditValueChanged
              Width = 90
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
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.DropDownAutoSize = True
              Properties.ImmediatePost = True
              Properties.KeyFieldNames = 'ID_AC'
              Properties.ListColumns = <
                item
                  FieldName = 'NOMBRE_AC'
                end>
              Properties.ListOptions.ShowHeader = False
              Properties.OnEditValueChanged = dbcLinTallasPropertiesEditValueChanged
              Width = 170
            end
            object dbcLinTotalTallas: TcxGridDBColumn
              Caption = 'Total tallas'
              DataBinding.FieldName = 'TOTAL_UNIDADES_SESLIN'
              Options.Editing = False
              Width = 90
            end
            object dbcLinImporteTotal: TcxGridDBColumn
              Caption = 'Importe s/IVA'
              DataBinding.FieldName = 'TOTAL_LINEA_SESLIN'
              PropertiesClassName = 'TcxCurrencyEditProperties'
              Options.Editing = False
              Width = 110
            end
          end
          object glLineas: TcxGridLevel
            GridView = tvLineas
          end
        end
      end
    end
  end
end
