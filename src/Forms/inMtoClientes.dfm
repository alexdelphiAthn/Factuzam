inherited frmMtoClientes: TfrmMtoClientes
  Caption = 'Clientes'
  ClientHeight = 703
  ClientWidth = 1141
  ExplicitWidth = 1141
  ExplicitHeight = 703
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 1001
    Height = 703
    TabOrder = 0
    ExplicitWidth = 1001
    ExplicitHeight = 703
    inherited pcPantalla: TcxPageControl
      Width = 1001
      Height = 663
      TabOrder = 1
      Properties.ActivePage = tsLista
      ExplicitWidth = 1001
      ExplicitHeight = 663
      ClientRectBottom = 659
      ClientRectRight = 997
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 993
        ExplicitHeight = 629
        inherited cxGrdPrincipal: TcxGrid
          Width = 993
          Height = 629
          ParentFont = False
          ExplicitWidth = 993
          ExplicitHeight = 629
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_CLIENTE: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_CLIENTE'
              Width = 106
            end
            object cxgrdbclmnGrdDBTabPrinACTIVO_CLIENTE: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ACTIVO_CLIENTE'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 69
            end
            object cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_CLIENTE: TcxGridDBColumn
              Caption = 'Raz'#243'n Social'
              DataBinding.FieldName = 'RAZONSOCIAL_CLIENTE'
              Width = 212
            end
            object cxgrdbclmnGrdDBTabPrinNIF_CLIENTE: TcxGridDBColumn
              Caption = 'Nif Cif'
              DataBinding.FieldName = 'NIF_CLIENTE'
              PropertiesClassName = 'TcxMaskEditProperties'
              Width = 104
            end
            object cxgrdbclmnGrdDBTabPrinMOVIL_CLIENTE: TcxGridDBColumn
              Caption = 'Tel'#233'fono M'#243'vil'
              DataBinding.FieldName = 'MOVIL_CLIENTE'
              Width = 150
            end
            object cxgrdbclmnGrdDBTabPrinTELEFONO_CLIENTE: TcxGridDBColumn
              Caption = 'Tel'#233'fono fijo'
              DataBinding.FieldName = 'TELEFONO_CLIENTE'
              Width = 123
            end
            object cxgrdbclmnGrdDBTabPrinEMAIL_CLIENTE: TcxGridDBColumn
              Caption = 'Email'
              DataBinding.FieldName = 'EMAIL_CLIENTE'
              Width = 196
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION1_CLIENTE: TcxGridDBColumn
              Caption = 'Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION1_CLIENTE'
              Width = 251
            end
            object cxgrdbclmnGrdDBTabPrinDIRECCION2_CLIENTE: TcxGridDBColumn
              Caption = 'M'#225's Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION2_CLIENTE'
              Width = 173
            end
            object cxgrdbclmnGrdDBTabPrinPOBLACION_CLIENTE: TcxGridDBColumn
              Caption = 'Poblaci'#243'n'
              DataBinding.FieldName = 'POBLACION_CLIENTE'
              Width = 146
            end
            object cxgrdbclmnGrdDBTabPrinPROVINCIA_CLIENTE: TcxGridDBColumn
              Caption = 'Provincia'
              DataBinding.FieldName = 'PROVINCIA_CLIENTE'
              Width = 135
            end
            object cxgrdbclmnGrdDBTabPrinCPOSTAL_CLIENTE: TcxGridDBColumn
              Caption = 'C'#243'digo Postal'
              DataBinding.FieldName = 'CPOSTAL_CLIENTE'
              Width = 95
            end
            object cxgrdbclmnGrdDBTabPrinPAIS_CLIENTE: TcxGridDBColumn
              Caption = 'Pa'#237's'
              DataBinding.FieldName = 'PAIS_CLIENTE'
              Width = 118
            end
            object cxgrdbclmnGrdDBTabPrinOBSERVACIONES_CLIENTE: TcxGridDBColumn
              Caption = 'Observaciones'
              DataBinding.FieldName = 'OBSERVACIONES_CLIENTE'
              Width = 192
            end
            object cxgrdbclmnGrdDBTabPrinREFERENCIA_CLIENTE: TcxGridDBColumn
              Caption = 'Referencia'
              DataBinding.FieldName = 'REFERENCIA_CLIENTE'
              Width = 184
            end
            object cxgrdbclmnGrdDBTabPrinCONTACTO_CLIENTE: TcxGridDBColumn
              Caption = 'Contacto'
              DataBinding.FieldName = 'CONTACTO_CLIENTE'
              Width = 151
            end
            object cxgrdbclmnGrdDBTabPrinTELEFONO_CONTACTO_CLIENTE: TcxGridDBColumn
              Caption = 'Tel'#233'fono de Contacto'
              DataBinding.FieldName = 'TELEFONO_CONTACTO_CLIENTE'
              Width = 140
            end
            object cxgrdbclmnGrdDBTabPrinIBAN_CLIENTE: TcxGridDBColumn
              Caption = 'Nro Cuenta'
              DataBinding.FieldName = 'IBAN_CLIENTE'
              Visible = False
              Width = 50
            end
            object cxgrdbclmnGrdDBTabPrinIVA_RECARGO_CLIENTE: TcxGridDBColumn
              Caption = 'Aplicar RE'
              DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.DisplayChecked = 'False'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 109
            end
            object cxgrdbclmnGrdDBTabPrinTEXTO_LEGAL_FACTURA_CLIENTE: TcxGridDBColumn
              Caption = 'Texto Legal Factura'
              DataBinding.FieldName = 'TEXTO_LEGAL_FACTURA_CLIENTE'
              Visible = False
              Width = 100
            end
            object cxgrdbclmnGrdDBTabPrinRETENCIONES_CLIENTE: TcxGridDBColumn
              Caption = 'Aplicar Retenciones'
              DataBinding.FieldName = 'ESRETENCIONES_CLIENTE'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 184
            end
            object cxGrdDBTabPrinESIVA_EXENTO_CLIENTE: TcxGridDBColumn
              Caption = 'Tiene IVA exento'
              DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 166
            end
            object cxGrdDBTabPrinESINTRACOMUNITARIO_CLIENTE: TcxGridDBColumn
              Caption = 'Es Intracomunitario'
              DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 179
            end
            object cxGrdDBTabPrinESREGIMENESPECIALAGRICOLA_CLIENTE: TcxGridDBColumn
              Caption = 'Es Agricultor'
              DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 127
            end
            object cxGrdDBTabPrinCODIGO_FORMA_PAGO_CLIENTE: TcxGridDBColumn
              Caption = 'Forma de pago por defecto'
              DataBinding.FieldName = 'CODIGO_FORMA_PAGO_CLIENTE'
              Width = 278
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 993
        ExplicitHeight = 629
        object pnl1: TPanel
          Left = 0
          Top = 0
          Width = 993
          Height = 179
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          DesignSize = (
            993
            179)
          object cxgrpbx4: TcxGroupBox
            AlignWithMargins = True
            Left = 22
            Top = 0
            TabStop = True
            Anchors = [akLeft, akTop, akRight, akBottom]
            TabOrder = 0
            Height = 167
            Width = 885
            object lblRazonSocial: TcxLabel
              Left = 200
              Top = 10
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Raz'#243'n Social Fiscal'
              TabOrder = 0
              Transparent = True
            end
            object lblCodigoCliente: TcxLabel
              Left = 21
              Top = 10
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'C'#243'digo'
              TabOrder = 1
              Transparent = True
            end
            object txtCODIGO_CLIENTE: TcxDBTextEdit
              Left = 21
              Top = 34
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              BiDiMode = bdLeftToRight
              DataBinding.DataField = 'CODIGO_CLIENTE'
              DataBinding.DataSource = dsTablaG
              ParentBiDiMode = False
              Properties.Alignment.Horz = taRightJustify
              TabOrder = 2
              Width = 149
            end
            object txtRAZONSOCIAL_CLIENTE: TcxDBTextEdit
              Left = 200
              Top = 34
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'RAZONSOCIAL_CLIENTE'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 507
            end
            object chkActivo: TcxDBCheckBox
              Left = 21
              Top = 68
              Caption = 'Activo'
              DataBinding.DataField = 'ACTIVO_CLIENTE'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Style.TransparentBorder = False
              TabOrder = 4
              Transparent = True
            end
            object lblEmail: TcxLabel
              Left = 301
              Top = 78
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Email'
              TabOrder = 5
              Transparent = True
            end
            object txtEMAIL_CLIENTE: TcxDBTextEdit
              Left = 355
              Top = 78
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'EMAIL_CLIENTE'
              DataBinding.DataSource = dsTablaG
              TabOrder = 6
              Width = 351
            end
            object lblNif: TcxLabel
              Left = 22
              Top = 107
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'NIF/CIF'
              TabOrder = 7
              Transparent = True
            end
            object txtNIF_CLIENTE: TcxDBTextEdit
              Left = 22
              Top = 130
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'NIF_CLIENTE'
              DataBinding.DataSource = dsTablaG
              TabOrder = 8
              Width = 149
            end
            object lblTelefonos: TcxLabel
              Left = 264
              Top = 123
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Tel'#233'fonos'
              TabOrder = 9
              Transparent = True
            end
            object txtMOVIL_CLIENTE: TcxDBTextEdit
              Left = 355
              Top = 122
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'MOVIL_CLIENTE'
              DataBinding.DataSource = dsTablaG
              TabOrder = 10
              Width = 163
            end
            object txtTELEFONO_CLIENTE: TcxDBTextEdit
              Left = 526
              Top = 122
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              DataBinding.DataField = 'TELEFONO_CLIENTE'
              DataBinding.DataSource = dsTablaG
              TabOrder = 11
              Width = 180
            end
          end
        end
        object pnl2: TPanel
          Left = 0
          Top = 187
          Width = 993
          Height = 442
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcPestanas: TcxPageControl
            Left = 0
            Top = 0
            Width = 993
            Height = 442
            Margins.Left = 4
            Margins.Top = 4
            Margins.Right = 4
            Margins.Bottom = 4
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsDomicilioFiscal
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 438
            ClientRectLeft = 4
            ClientRectRight = 989
            ClientRectTop = 30
            object tsDomicilioFiscal: TcxTabSheet
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = '&1_Domicilio fiscal'
              ImageIndex = 0
              DesignSize = (
                985
                408)
              object cxgrpbx1: TcxGroupBox
                AlignWithMargins = True
                Left = 18
                Top = 0
                TabStop = True
                Anchors = [akLeft, akTop, akRight, akBottom]
                TabOrder = 0
                Height = 257
                Width = 638
                object lblDireccion1: TcxLabel
                  Left = 34
                  Top = 25
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Direcci'#243'n 1'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 0
                  Transparent = True
                  AnchorX = 135
                end
                object txtDIRECCION1_CLIENTE: TcxDBTextEdit
                  Left = 147
                  Top = 21
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'DIRECCION1_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 303
                end
                object lblDireccion2: TcxLabel
                  Left = 34
                  Top = 64
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Direcci'#243'n 2'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 2
                  Transparent = True
                  AnchorX = 135
                end
                object txtDIRECCION2_CLIENTE: TcxDBTextEdit
                  Left = 147
                  Top = 60
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'DIRECCION2_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 304
                end
                object lblCodPostal: TcxLabel
                  Left = 14
                  Top = 103
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'C'#243'digo Postal'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 4
                  Transparent = True
                  AnchorX = 135
                end
                object txtCPOSTAL_CLIENTE: TcxDBTextEdit
                  Left = 147
                  Top = 99
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'CPOSTAL_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 77
                end
                object lblPoblacion: TcxLabel
                  Left = 48
                  Top = 143
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Poblaci'#243'n'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 6
                  Transparent = True
                  AnchorX = 135
                end
                object txtPOBLACION_CLIENTE: TcxDBTextEdit
                  Left = 147
                  Top = 139
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'POBLACION_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Width = 303
                end
                object lblProvincia: TcxLabel
                  Left = 54
                  Top = 182
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Provincia'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 8
                  Transparent = True
                  AnchorX = 135
                end
                object txtPROVINCIA_CLIENTE: TcxDBTextEdit
                  Left = 147
                  Top = 178
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'PROVINCIA_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 9
                  Width = 303
                end
                object lblPais: TcxLabel
                  Left = 98
                  Top = 222
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Pa'#237's'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 10
                  Transparent = True
                  AnchorX = 135
                end
                object txtPAIS_CLIENTE: TcxDBTextEdit
                  Left = 147
                  Top = 218
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'NOMBRE_PAIS_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 11
                  Visible = False
                  Width = 237
                end
                object txtNOMBRE_PAIS_CLIENTE: TcxDBTextEdit
                  Left = 402
                  Top = 218
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'CODIGO_PAIS_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Enabled = False
                  Properties.OnChange = txtNOMBRE_PAIS_CLIENTEPropertiesChange
                  TabOrder = 12
                  Width = 48
                end
                object cbbPaises: TcxDBLookupComboBox
                  Left = 147
                  Top = 218
                  DataBinding.DataField = 'CODIGO_PAIS_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'CODIGO'
                  Properties.ListColumns = <
                    item
                      Caption = 'Nombre Pais'
                      FieldName = 'NOMBRE'
                    end>
                  Properties.ListOptions.CaseInsensitive = True
                  Properties.ListOptions.ShowHeader = False
                  Properties.ListSource = dmClientes.dsPaises
                  TabOrder = 13
                  Width = 203
                end
              end
              object cxgrpbxTratamientoFiscal: TcxGroupBox
                Left = 18
                Top = 263
                TabStop = True
                Anchors = [akLeft, akTop, akRight]
                Caption = 'Tratamiento Fiscal'
                TabOrder = 1
                Height = 85
                Width = 903
                object chkREGIMENAGRICOLA: TcxDBCheckBox
                  Left = 6
                  Top = 24
                  Hint = 
                    'S'#243'lo es importante para empresas que facturen de agricultor a ag' +
                    'ricultor'
                  Caption = 'R'#233'gimen especial agricola/ganadero/pesca'
                  DataBinding.DataField = 'ESREGIMENESPECIALAGRICOLA_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 0
                  Transparent = True
                end
                object chkINTRACOMUNITARIO: TcxDBCheckBox
                  Left = 6
                  Top = 53
                  Caption = 'Es Intracomunitario'
                  DataBinding.DataField = 'ESINTRACOMUNITARIO_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayUnchecked = 'True'
                  Properties.DisplayGrayed = 'False'
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 1
                  Transparent = True
                end
                object chkIVAEXENTO: TcxDBCheckBox
                  Left = 277
                  Top = 53
                  Caption = 'IVA Exento'
                  DataBinding.DataField = 'ESIVA_EXENTO_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayUnchecked = 'True'
                  Properties.DisplayGrayed = 'False'
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 2
                  Transparent = True
                end
                object chkRECARGO_EQUIV: TcxDBCheckBox
                  Left = 411
                  Top = 24
                  Caption = 'Factura con Recargo de Equivalencia'
                  DataBinding.DataField = 'ESIVA_RECARGO_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayUnchecked = 'True'
                  Properties.DisplayGrayed = 'False'
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 3
                  Transparent = True
                end
                object chkRETENCIONES: TcxDBCheckBox
                  Left = 411
                  Top = 53
                  Caption = 'Aplicar Retenciones (Es profesional)'
                  DataBinding.DataField = 'ESRETENCIONES_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Properties.DisplayUnchecked = 'True'
                  Properties.DisplayGrayed = 'False'
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 4
                  Transparent = True
                end
              end
            end
            object tsMasDatos: TcxTabSheet
              Caption = '&2_M'#225's datos'
              ImageIndex = 1
              DesignSize = (
                985
                408)
              object cxgrpbx3: TcxGroupBox
                AlignWithMargins = True
                Left = 21
                Top = 0
                TabStop = True
                Anchors = [akLeft, akTop, akRight, akBottom]
                TabOrder = 0
                Height = 404
                Width = 882
                object lblContacto: TcxLabel
                  Left = 84
                  Top = 23
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Contacto'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 0
                  Transparent = True
                  AnchorX = 163
                end
                object txtCONTACTO_CLIENTE: TcxDBTextEdit
                  Left = 170
                  Top = 19
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'CONTACTO_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 199
                end
                object lblTelefonoContacto: TcxLabel
                  Left = 382
                  Top = 23
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Tel'#233'fono Contacto'
                  TabOrder = 2
                  Transparent = True
                end
                object txtTELEFONO_CONTACTO_CLIENTE: TcxDBTextEdit
                  Left = 548
                  Top = 19
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'TELEFONO_CONTACTO_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 3
                  Width = 159
                end
                object lblReferencia: TcxLabel
                  Left = 73
                  Top = 66
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Referencia'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 4
                  Transparent = True
                  AnchorX = 163
                end
                object txtREFERENCIA_CLIENTE: TcxDBTextEdit
                  Left = 170
                  Top = 62
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'REFERENCIA_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 5
                  Width = 537
                end
                object lblObservaciones: TcxLabel
                  Left = 37
                  Top = 101
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Observaciones'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 6
                  Transparent = True
                  AnchorX = 163
                end
                object cxdbmOBSERVACIONES_CLIENTE: TcxDBMemo
                  Left = 170
                  Top = 101
                  DataBinding.DataField = 'OBSERVACIONES_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 7
                  Height = 68
                  Width = 537
                end
                object lblFormadePago: TcxLabel
                  Left = 34
                  Top = 187
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Forma de Pago'
                  TabOrder = 8
                  Transparent = True
                end
                object cbbFORMAPAGO: TcxDBLookupComboBox
                  Left = 170
                  Top = 183
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'CODIGO_FORMA_PAGO_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'CODIGO_FORMAPAGO'
                  Properties.ListColumns = <
                    item
                      FieldName = 'DESCRIPCION_FORMAPAGO'
                    end>
                  Properties.ListOptions.ShowHeader = False
                  Properties.ListSource = dmClientes.dsFormasPago
                  TabOrder = 9
                  Width = 263
                end
                object lblNroCuenta: TcxLabel
                  Left = 42
                  Top = 228
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'IBAN Bancario'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 10
                  Transparent = True
                  AnchorX = 163
                end
                object lblTextoLegal2: TcxLabel
                  Left = 8
                  Top = 268
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Tarifa por defecto'
                  TabOrder = 11
                  Transparent = True
                end
                object cbbTARIFA: TcxDBLookupComboBox
                  Left = 170
                  Top = 264
                  DataBinding.DataField = 'TARIFA_ARTICULO_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'CODIGO_TARIFA'
                  Properties.ListColumns = <
                    item
                      Fixed = True
                      FieldName = 'NOMBRE_TARIFA'
                    end>
                  Properties.ListOptions.ShowHeader = False
                  TabOrder = 12
                  Width = 263
                end
                object txtTARIFA_ARTICULO_CLIENTE: TcxDBTextEdit
                  Left = 308
                  Top = 266
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'TARIFA_ARTICULO_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 13
                  Visible = False
                  Width = 33
                end
                object txtIBAN_CLIENTE: TcxDBMaskEdit
                  Left = 170
                  Top = 224
                  DataBinding.DataField = 'IBAN_CLIENTE'
                  DataBinding.DataSource = dsTablaG
                  Properties.IgnoreMaskBlank = True
                  Properties.EditMask = 'aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa'
                  TabOrder = 14
                  Width = 369
                end
                object btnValidar: TcxButton
                  Left = 545
                  Top = 224
                  Width = 98
                  Height = 27
                  Caption = 'Vali&dar'
                  TabOrder = 15
                  OnClick = btnValidarClick
                end
              end
            end
            object tsHistoriaFacturacion: TcxTabSheet
              Caption = '&3_Historia Facturaci'#243'n'
              ImageIndex = 3
              object pnlFacturaCli: TPanel
                Left = 0
                Top = 0
                Width = 985
                Height = 408
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object cxgrdClientesFacturas: TcxGrid
                  Left = 0
                  Top = 0
                  Width = 868
                  Height = 408
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
                    DataController.Summary.DefaultGroupSummaryItems = <
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_LIQUIDO_FACTURA
                      end
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_RETENCION_FACTURA
                      end
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_IMPUESTOS_FACTURA
                      end
                      item
                        Kind = skSum
                        Column = tvFacturacionTOTAL_BASES_FACTURA
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
                        Column = tvFacturacionTOTAL_RETENCION_FACTURA
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_IMPUESTOS_FACTURA
                      end
                      item
                        Format = '##,##.00 '#8364
                        Kind = skSum
                        Column = tvFacturacionTOTAL_BASES_FACTURA
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
                      Width = 117
                    end
                    object tvFacturacionPORCEN_RETENCION_FACTURA: TcxGridDBColumn
                      Caption = '% IRPF'
                      DataBinding.FieldName = 'PORCEN_RETENCION_FACTURA'
                    end
                    object tvFacturacionTOTAL_RETENCION_FACTURA: TcxGridDBColumn
                      Caption = 'Total IRPF'
                      DataBinding.FieldName = 'TOTAL_RETENCION_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 99
                    end
                    object tvFacturacionTOTAL_IMPUESTOS_FACTURA: TcxGridDBColumn
                      Caption = 'Total IVA + RE'
                      DataBinding.FieldName = 'TOTAL_IMPUESTOS_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 134
                    end
                    object tvFacturacionTOTAL_BASES_FACTURA: TcxGridDBColumn
                      Caption = 'Bases Imponible'
                      DataBinding.FieldName = 'TOTAL_BASES_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 142
                    end
                    object tvFacturacionFORMA_PAGO_FACTURA: TcxGridDBColumn
                      Caption = 'Forma Pago'
                      DataBinding.FieldName = 'FORMA_PAGO_FACTURA'
                      Width = 103
                    end
                    object tvFacturacionDESCRIPCION_FORMAPAGO: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Forma Pago'
                      DataBinding.FieldName = 'DESCRIPCION_FORMAPAGO'
                      Width = 230
                    end
                    object tvFacturacionCODIGO_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'C'#243'digo Empresa'
                      DataBinding.FieldName = 'CODIGO_EMPRESA_FACTURA'
                      Width = 142
                    end
                    object tvFacturacionRAZONSOCIAL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Raz'#243'n Social Empresa'
                      DataBinding.FieldName = 'RAZONSOCIAL_EMPRESA_FACTURA'
                      Width = 188
                    end
                    object tvFacturacionNIF_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Nif Empresa'
                      DataBinding.FieldName = 'NIF_EMPRESA_FACTURA'
                      Width = 105
                    end
                    object tvFacturacionMOVIL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'M'#243'vil Empresa'
                      DataBinding.FieldName = 'MOVIL_EMPRESA_FACTURA'
                      Width = 126
                    end
                    object tvFacturacionEMAIL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Email Empresa'
                      DataBinding.FieldName = 'EMAIL_EMPRESA_FACTURA'
                      Width = 125
                    end
                    object tvFacturacionDIRECCION1_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n1 Empresa'
                      DataBinding.FieldName = 'DIRECCION1_EMPRESA_FACTURA'
                      Width = 172
                    end
                    object tvFacturacionDIRECCION2_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Direcci'#243'n2 Empresa'
                      DataBinding.FieldName = 'DIRECCION2_EMPRESA_FACTURA'
                      Width = 172
                    end
                    object tvFacturacionPOBLACION_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Poblaci'#243'n Empresa'
                      DataBinding.FieldName = 'POBLACION_EMPRESA_FACTURA'
                      Width = 175
                    end
                    object tvFacturacionPROVINCIA_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Provincia Empresa'
                      DataBinding.FieldName = 'PROVINCIA_EMPRESA_FACTURA'
                      Width = 157
                    end
                    object tvFacturacionPAIS_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Pa'#237's Empresa'
                      DataBinding.FieldName = 'PAIS_EMPRESA_FACTURA'
                      Width = 114
                    end
                    object tvFacturacionCPOSTAL_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'CPostal Empresa'
                      DataBinding.FieldName = 'CPOSTAL_EMPRESA_FACTURA'
                      Width = 156
                    end
                    object tvFacturacionESRETENCIONES_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Empresa Retiene IRPF'
                      DataBinding.FieldName = 'ESRETENCIONES_EMPRESA_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 184
                    end
                    object tvFacturacionDESCRIPCION_ZONA_IVA_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Zona IVA'
                      DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA_EMPRESA_FACTURA'
                      Visible = False
                      Width = 80
                    end
                    object tvFacturacionDESCRIPCION_ZONA_IVA: TcxGridDBColumn
                      Caption = 'Zona IVA'
                      DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA'
                      Visible = False
                      Width = 80
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxGridDBColumn
                      Caption = 'Es REAGP'
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 81
                    end
                    object tvFacturacionESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESAPLICA_RE_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESAPLICA_RE_ZONA_IVA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESIVAAGRICOLA_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVAAGRICOLA_ZONA_IVA_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionPALABRA_REPORTS_ZONA_IVA_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PALABRA_REPORTS_ZONA_IVA_FACTURA'
                      Visible = False
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
                      Properties.ValueType = vtFloat
                      Width = 115
                    end
                    object tvFacturacionTOTAL_IVAN_FACTURA: TcxGridDBColumn
                      Caption = 'Total IVA Normal'
                      DataBinding.FieldName = 'TOTAL_IVAN_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 159
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
                      Properties.ValueType = vtFloat
                      Width = 107
                    end
                    object tvFacturacionTOTAL_REN_FACTURA: TcxGridDBColumn
                      Caption = 'Total RE Normal'
                      DataBinding.FieldName = 'TOTAL_REN_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 139
                    end
                    object tvFacturacionTOTAL_BASEI_IVAN_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imponible IVA Normal'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAN_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 232
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
                      Properties.ValueType = vtFloat
                      Width = 133
                    end
                    object tvFacturacionTOTAL_IVAR_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Reducido'
                      DataBinding.FieldName = 'TOTAL_IVAR_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 129
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
                      Properties.ValueType = vtFloat
                      Width = 137
                    end
                    object tvFacturacionTOTAL_RER_FACTURA: TcxGridDBColumn
                      Caption = 'RE Reducido'
                      DataBinding.FieldName = 'TOTAL_RER_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 109
                    end
                    object tvFacturacionTOTAL_BASEI_IVAR_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imponible IVA Reducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAR_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 310
                    end
                    object tvFacturacionPORCEN_IVAS_FACTURA: TcxGridDBColumn
                      Caption = '% IVA S'#250'per Reducido'
                      DataBinding.FieldName = 'PORCEN_IVAS_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 186
                    end
                    object tvFacturacionTOTAL_IVAS_FACTURA: TcxGridDBColumn
                      Caption = 'IVA S'#250'per Reducido'
                      DataBinding.FieldName = 'TOTAL_IVAS_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 170
                    end
                    object tvFacturacionPORCEN_RES_FACTURA: TcxGridDBColumn
                      Caption = '% RE S'#250'per Reducido'
                      DataBinding.FieldName = 'PORCEN_RES_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 178
                    end
                    object tvFacturacionTOTAL_RES_FACTURA: TcxGridDBColumn
                      Caption = 'RE S'#250'per Reducido'
                      DataBinding.FieldName = 'TOTAL_RES_FACTURA'
                      Width = 162
                    end
                    object tvFacturacionTOTAL_BASEI_IVAS_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imponible IVA S'#250'per Reducido'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAS_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 298
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
                      Properties.ValueType = vtFloat
                      Width = 112
                    end
                    object tvFacturacionTOTAL_IVAE_FACTURA: TcxGridDBColumn
                      Caption = 'IVA Exento'
                      DataBinding.FieldName = 'TOTAL_IVAE_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                    end
                    object tvFacturacionPORCEN_REE_FACTURA: TcxGridDBColumn
                      Caption = '% RE Exento'
                      DataBinding.FieldName = 'PORCEN_REE_FACTURA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.DisplayFormat = '0.00 %'
                      Properties.EditFormat = '0.00 %'
                      Properties.Increment = 0.100000000000000000
                      Properties.LargeIncrement = 1.000000000000000000
                      Properties.MaxValue = 100.000000000000000000
                      Properties.ValueType = vtFloat
                      Width = 107
                    end
                    object tvFacturacionTOTAL_REE_FACTURA: TcxGridDBColumn
                      Caption = 'RE Exento'
                      DataBinding.FieldName = 'TOTAL_REE_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 100
                    end
                    object tvFacturacionTOTAL_BASEI_IVAE_FACTURA: TcxGridDBColumn
                      Caption = 'Base Imponible Exento'
                      DataBinding.FieldName = 'TOTAL_BASEI_IVAE_FACTURA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                      Width = 208
                    end
                    object tvFacturacionCODIGO_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CODIGO_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionRAZONSOCIAL_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'RAZONSOCIAL_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionNIF_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'NIF_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionMOVIL_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'MOVIL_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionEMAIL_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'EMAIL_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionDIRECCION1_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION1_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionDIRECCION2_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'DIRECCION2_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionPOBLACION_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'POBLACION_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionPROVINCIA_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PROVINCIA_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionCPOSTAL_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'CPOSTAL_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionPAIS_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'PAIS_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESIVA_RECARGO_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVA_RECARGO_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESIVA_EXENTO_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESIVA_EXENTO_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionESRETENCIONES_CLIENTE_FACTURA: TcxGridDBColumn
                      DataBinding.FieldName = 'ESRETENCIONES_CLIENTE_FACTURA'
                      Visible = False
                    end
                    object tvFacturacionNOMBRE_TARIFA_CLIENTE: TcxGridDBColumn
                      DataBinding.FieldName = 'NOMBRE_TARIFA_CLIENTE'
                      Visible = False
                    end
                    object tvFacturacionESIMP_INCL_TARIFA_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Precios incl. Impuestos'
                      DataBinding.FieldName = 'ESIMP_INCL_TARIFA_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 198
                    end
                    object tvFacturacionESINTRACOMUNITARIO_CLIENTE_FACTURA: TcxGridDBColumn
                      Caption = 'Venta Intracomunitaria'
                      DataBinding.FieldName = 'ESINTRACOMUNITARIO_CLIENTE_FACTURA'
                      PropertiesClassName = 'TcxCheckBoxProperties'
                      Properties.ValueChecked = 'S'
                      Properties.ValueUnchecked = 'N'
                      Width = 212
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
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA: TcxGridDBColumn
                      Caption = 'C'#243'digo Linea'
                      DataBinding.FieldName = 'LINEA_FACTURA_LINEA'
                      Width = 28
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'C'#243'digo Art'#237'culo'
                      DataBinding.FieldName = 'CODIGO_ARTICULO_FACTURA_LINEA'
                      Width = 164
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Descripci'#243'n Art'#237'culo'
                      DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACTURA_LINEA'
                      Width = 162
                    end
                    object tvLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Tipo Ctd'
                      DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA'
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA: TcxGridDBColumn
                      Caption = 'Cantidad'
                      DataBinding.FieldName = 'CANTIDAD_FACTURA_LINEA'
                      Width = 84
                    end
                    object tvLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Precio Sin IVA'
                      DataBinding.FieldName = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA'
                      PropertiesClassName = 'TcxCurrencyEditProperties'
                    end
                    object dbcLineasFacturacionNOMBRE_TIPO_IVA: TcxGridDBColumn
                      Caption = 'Tipo IVA'
                      DataBinding.FieldName = 'NOMBRE_TIPO_IVA'
                    end
                    object tvLineasFacturacionPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                      Caption = 'Porcentaje IVA'
                      DataBinding.FieldName = 'PORCEN_IVA_FACTURA_LINEA'
                      PropertiesClassName = 'TcxSpinEditProperties'
                      Properties.EditFormat = '0.00 %'
                    end
                    object cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA: TcxGridDBColumn
                      Caption = 'Precio Con IVA'
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
                    end
                  end
                  object cxgrdClientesFacturasgrdlvlcxgrd1Level1: TcxGridLevel
                    GridView = tvFacturacion
                    object cxgrdClientesFacturasgrdlvlcxgrd1Level2: TcxGridLevel
                      GridView = tvLineasFacturacion
                    end
                  end
                end
                object pnlFacturaOpts: TPanel
                  Left = 868
                  Top = 0
                  Width = 117
                  Height = 408
                  Align = alRight
                  BevelOuter = bvNone
                  TabOrder = 1
                  object btnIraFactura: TcxButton
                    Left = 6
                    Top = 16
                    Width = 107
                    Height = 34
                    Caption = '&Ir a Factura'
                    TabOrder = 0
                    OnClick = btnIraFacturaClick
                  end
                  object btnIraEmpresa: TcxButton
                    Left = 7
                    Top = 56
                    Width = 106
                    Height = 34
                    Caption = '&Ir a Empresa'
                    TabOrder = 1
                    OnClick = btnIraEmpresaClick
                  end
                  object btnExportar: TcxButton
                    Left = 6
                    Top = 137
                    Width = 107
                    Height = 34
                    Caption = '&Exp Excel'
                    TabOrder = 3
                    OnClick = btnExportarClick
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
            object tsPresupuestos: TcxTabSheet
              Caption = 'Historia Presupuestos'
              ImageIndex = 4
              TabVisible = False
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object cxgrd3: TcxGrid
                Left = 0
                Top = 0
                Width = 985
                Height = 408
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                object tv2: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsSelection.InvertSelect = False
                  OptionsView.NoDataToDisplayInfoText = '<No hay datos a mostrar>'
                  OptionsView.GroupByBox = False
                  object cxgrdbclmn1: TcxGridDBColumn
                    AlternateCaption = 'Fecha Presupuesto'
                    Caption = 'Fecha Presupuesto'
                    DataBinding.FieldName = 'FECHA_FACTURA'
                    PropertiesClassName = 'TcxDateEditProperties'
                    Width = 102
                  end
                  object cxgrdbclmn2: TcxGridDBColumn
                    AlternateCaption = 'Nro Presupuesto'
                    Caption = 'Nro Presupuesto'
                    DataBinding.FieldName = 'NRO_FACTURA'
                    Width = 101
                  end
                  object cxgrdbclmn3: TcxGridDBColumn
                    Caption = 'Serie'
                    DataBinding.FieldName = 'SERIE_FACTURA'
                  end
                  object cxgrdbclmn4: TcxGridDBColumn
                    Caption = 'C'#243'digo Paciente'
                    DataBinding.FieldName = 'CODIGO_CLIENTE_FACTURA'
                    Width = 104
                  end
                  object cxgrdbclmn5: TcxGridDBColumn
                    Caption = 'Raz'#243'n Social'
                    DataBinding.FieldName = 'RAZONSOCIAL_CLIENTE_FACTURA'
                    Width = 203
                  end
                  object cxgrdbclmn6: TcxGridDBColumn
                    Caption = 'Nif'
                    DataBinding.FieldName = 'NIF_CLIENTE_FACTURA'
                    Width = 144
                  end
                  object cxgrdbclmn7: TcxGridDBColumn
                    Caption = 'Tel'#233'fono1'
                    DataBinding.FieldName = 'MOVIL_CLIENTE_FACTURA'
                    Width = 164
                  end
                  object cxgrdbclmn8: TcxGridDBColumn
                    Caption = 'Email'
                    DataBinding.FieldName = 'EMAIL_CLIENTE_FACTURA'
                    Width = 179
                  end
                  object cxgrdbclmn9: TcxGridDBColumn
                    Caption = 'Direcci'#243'n1'
                    DataBinding.FieldName = 'DIRECCION1_CLIENTE_FACTURA'
                    Width = 204
                  end
                  object cxgrdbclmn10: TcxGridDBColumn
                    Caption = 'Direcci'#243'n2'
                    DataBinding.FieldName = 'DIRECCION2_CLIENTE_FACTURA'
                    Width = 190
                  end
                  object cxgrdbclmn11: TcxGridDBColumn
                    Caption = 'Poblaci'#243'n'
                    DataBinding.FieldName = 'POBLACION_CLIENTE_FACTURA'
                    Width = 185
                  end
                  object cxgrdbclmn12: TcxGridDBColumn
                    Caption = 'Provincia'
                    DataBinding.FieldName = 'PROVINCIA_CLIENTE_FACTURA'
                    Width = 183
                  end
                  object cxgrdbclmn13: TcxGridDBColumn
                    Caption = 'C'#243'digo Postal'
                    DataBinding.FieldName = 'CPOSTAL_CLIENTE_FACTURA'
                  end
                  object cxgrdbclmn14: TcxGridDBColumn
                    Caption = 'Pa'#237's'
                    DataBinding.FieldName = 'PAIS_CLIENTE_FACTURA'
                    Width = 144
                  end
                  object cxgrdbclmn15: TcxGridDBColumn
                    Caption = 'Total L'#237'quido'
                    DataBinding.FieldName = 'TOTAL_LIQUIDO_FACTURA'
                  end
                  object cxgrdbclmn16: TcxGridDBColumn
                    Caption = 'Forma de Pago'
                    DataBinding.FieldName = 'FORMA_PAGO_FACTURA'
                    Width = 151
                  end
                  object cxgrdbclmn17: TcxGridDBColumn
                    Caption = 'Comentarios'
                    DataBinding.FieldName = 'COMENTARIOS_FACTURA'
                  end
                end
                object tv3: TcxGridDBTableView
                  DataController.DetailKeyFieldNames = 'NRO_FACTURA_LINEA; SERIE_FACTURA_LINEA'
                  DataController.KeyFieldNames = 'LINEA_LINEA'
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
                  object cxgrdbclmn18: TcxGridDBColumn
                    DataBinding.FieldName = 'LINEA_LINEA'
                    Width = 28
                  end
                  object cxgrdbclmn19: TcxGridDBColumn
                    Caption = 'C'#243'digo Tratamiento'
                    DataBinding.FieldName = 'CODIGO_ARTICULO_LINEA'
                    Width = 164
                  end
                  object cxgrdbclmn20: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Tratamiento'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_LINEA'
                    Width = 804
                  end
                  object cxgrdbclmn21: TcxGridDBColumn
                    Caption = 'Nro Pieza'
                    DataBinding.FieldName = 'ZONA'
                    Width = 484
                  end
                  object cxgrdbclmn22: TcxGridDBColumn
                    Caption = 'Precio'
                    DataBinding.FieldName = 'PRECIOVENTA_ARTICULO_LINEA'
                    Width = 84
                  end
                  object cxgrdbclmn23: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_LINEA'
                    Width = 84
                  end
                  object cxgrdbclmn24: TcxGridDBColumn
                    Caption = 'Total'
                    DataBinding.FieldName = 'SUM_TOTAL_LINEA'
                    Width = 84
                  end
                  object cxgrdbclmn25: TcxGridDBColumn
                    Caption = 'Nro Odont'#243'logo'
                    DataBinding.FieldName = 'ODONTOLOGO'
                    Width = 68
                  end
                end
                object cxgrdlvl2: TcxGridLevel
                  GridView = tv2
                  object cxgrdlvl3: TcxGridLevel
                    GridView = tv3
                  end
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&4_Otros'
              ImageIndex = 4
              object pnlUserInstantBottom: TPanel
                Left = 0
                Top = 329
                Width = 985
                Height = 79
                Align = alBottom
                BevelOuter = bvNone
                TabOrder = 6
                object txtUSUARIOALTA: TcxDBTextEdit
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
                  Left = 165
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Alta'
                  TabOrder = 1
                  Transparent = True
                end
                object txtINSTANTEALTA: TcxDBTextEdit
                  Left = 165
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTEALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 196
                end
                object txtINSTANTEMODIF: TcxDBTextEdit
                  Left = 569
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTEMODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 196
                end
                object lblInstanteModif: TcxLabel
                  Left = 569
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Modificaci'#243'n'
                  TabOrder = 5
                  Transparent = True
                end
                object txtUSUARIOMODIF: TcxDBTextEdit
                  Left = 380
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIOMODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 171
                end
                object lblUsuarioModif: TcxLabel
                  Left = 380
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario '#218'lt. ModiF.'
                  TabOrder = 6
                  Transparent = True
                end
              end
              object mTEXTO_LEGAL_FACTURA_CLIENTE: TcxDBMemo
                Left = 17
                Top = 46
                DataBinding.DataField = 'TEXTO_LEGAL_FACTURA_CLIENTE'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Height = 113
                Width = 684
              end
              object lblTextoLegal: TcxLabel
                Left = 17
                Top = 19
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Texto legal en Factura de Cliente'
                TabOrder = 3
                Transparent = True
              end
              object lblSerieDefault: TcxLabel
                Left = 17
                Top = 179
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Serie por defecto en Documentos'
                TabOrder = 4
                Transparent = True
              end
              object txtSERIE_CONTADOR: TcxDBTextEdit
                Left = 302
                Top = 178
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                DataBinding.DataField = 'SERIE_CONTADOR_CLIENTE'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 109
              end
              object lblOrdenListado: TcxLabel
                Left = 435
                Top = 179
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Orden en Listados'
                TabOrder = 5
                Transparent = True
              end
              object spORDEN_CLIENTE: TcxDBSpinEdit
                Left = 593
                Top = 178
                DataBinding.DataField = 'ORDEN_CLIENTE'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 106
              end
            end
          end
        end
        object cxspltr1: TcxSplitter
          Left = 0
          Top = 179
          Width = 993
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnl1
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 993
        ExplicitHeight = 629
        inherited pnlPerfilTop: TPanel
          Width = 993
          ExplicitWidth = 993
        end
        inherited pnlPerfilDetail: TPanel
          Width = 993
          Height = 572
          ExplicitWidth = 993
          ExplicitHeight = 572
          inherited cxgrdPerfil: TcxGrid
            Width = 993
            Height = 572
            ExplicitWidth = 993
            ExplicitHeight = 572
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1001
      TabOrder = 0
      ExplicitWidth = 1001
      inherited pnlTopGrid: TPanel
        Width = 1001
        ExplicitWidth = 1001
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Top = 5
          Width = 310
          Height = 25
          TabOrder = 3
          ExplicitTop = 5
          ExplicitWidth = 310
          ExplicitHeight = 25
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
    Left = 1001
    Height = 703
    TabOrder = 1
    ExplicitLeft = 1001
    ExplicitHeight = 703
    inherited pButtonGen: TPanel
      Top = 505
      TabOrder = 2
      ExplicitTop = 505
    end
    object btnNuevoCliente: TcxButton
      Left = 1
      Top = 157
      Width = 138
      Height = 25
      Caption = '&Nuevo Cliente'
      TabOrder = 1
      OnClick = btnNuevoClienteClick
    end
    object cxButton1: TcxButton
      Left = 1
      Top = 253
      Width = 138
      Height = 25
      Caption = '&Imprimir'
      DropDownMenu = dxBarPopupMenu1
      Kind = cxbkOfficeDropDown
      TabOrder = 3
    end
  end
  object ActionListClientes: TActionList [4]
    Left = 656
    Top = 400
    object actEmpresas: TAction
      Caption = 'Empresas'
      ShortCut = 16453
      OnExecute = actEmpresasExecute
    end
    object actFacturas: TAction
      Caption = 'Facturas'
      ShortCut = 16454
      OnExecute = actFacturasExecute
    end
    object actArticulos: TAction
      Caption = 'Articulos'
      ShortCut = 16449
      OnExecute = actArticulosExecute
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmClientes.unqryTablaG
    Left = 552
  end
  object dxBarPopupMenu1: TdxBarPopupMenu
    BarManager = dxBarManager1
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Lucida Sans'
    Font.Style = []
    ItemLinks = <
      item
        Visible = True
        ItemName = 'blbEtiqueta'
      end>
    UseOwnFont = True
    Left = 1080
    Top = 304
    PixelsPerInch = 96
  end
  object dxBarManager1: TdxBarManager
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Lucida Sans'
    Font.Style = []
    Categories.Strings = (
      'Default')
    Categories.ItemsVisibles = (
      2)
    Categories.Visibles = (
      True)
    PopupMenuLinks = <>
    UseSystemFont = False
    Left = 984
    Top = 304
    PixelsPerInch = 96
    object blbEtiqueta: TdxBarLargeButton
      Caption = 'Etiqueta'
      Category = 0
      Hint = 'Etiqueta'
      Visible = ivAlways
      OnClick = blbEtiquetaClick
    end
  end
end
