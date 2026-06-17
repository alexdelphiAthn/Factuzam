inherited frmMtoFacturasNormal: TfrmMtoFacturasNormal
  Caption = 'Borradores (Venta Mayor)'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 17
  inherited pButtonPage: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pcPantalla: TcxPageControl
      inherited tsFicha: TcxTabSheet
        inherited pnlVerifactu: TPanel
          StyleElements = [seFont, seClient, seBorder]
          inherited pcDetail: TcxPageControl
            inherited tsLineasFactura: TcxTabSheet
              ExplicitLeft = 4
              ExplicitTop = 28
              ExplicitWidth = 1071
              ExplicitHeight = 395
              inherited pnlRightLineas: TPanel
                StyleElements = [seFont, seClient, seBorder]
                inherited chkFechaEntrega: TcxDBCheckBox
                  ExplicitWidth = 142
                end
                inherited chkDescripcion_ampliada: TcxDBCheckBox
                  ExplicitWidth = 130
                end
                inherited chkCrearArticulos: TcxDBCheckBox
                  ExplicitWidth = 149
                end
              end
            end
            inherited tsTotales: TcxTabSheet
              inherited curTotalAPagar: TcxDBCurrencyEdit
                ExplicitHeight = 25
              end
              inherited curTOTAL_LIQUIDO_FACTURA: TcxDBCurrencyEdit
                ExplicitHeight = 25
              end
              inherited spnRetencion: TcxDBSpinEdit
                ExplicitHeight = 25
              end
              inherited curTOTAL_RETENCION_FACTURA: TcxDBCurrencyEdit
                ExplicitHeight = 25
              end
              inherited curTOTAL_BASES_FACTURA: TcxDBCurrencyEdit
                ExplicitHeight = 25
              end
              inherited cbbFORMAPAGO: TcxDBLookupComboBox
                ExplicitHeight = 25
              end
              inherited grpDesgloseImpuestos: TGroupBox
                inherited curTOTAL_BASEI_IVAN_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_BASEI_IVAR_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_BASEI_IVAS_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_BASEI_IVAE_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_IVAN_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_IVAR_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_IVAS_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_IVAE_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_REN_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_RER_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_RES_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited curTOTAL_REE_FAC: TcxDBCurrencyEdit
                  ExplicitHeight = 25
                end
                inherited spnPORCENTAJE_IVAN_FAC: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited spnPORCENTAJE_IVAR_FAC: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited spnPORCENTAJE_IVAS_FAC: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited spnPORCENTAJE_IVAE_FAC: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited spnPORCENTAJE_RER_FAC: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited spnPORCENTAJE_REN_FAC: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited spnPORCENTAJE_RES_FAC: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited spnPORCENTAJE_REE_FAC: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited chkESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TcxDBCheckBox
                  ExplicitWidth = 326
                end
                inherited chkESVENTA_ACTIVO_FIJO_FACTURA: TcxDBCheckBox
                  ExplicitWidth = 436
                end
              end
            end
            inherited tsRecibos: TcxTabSheet
              ExplicitLeft = 4
              ExplicitTop = 28
              ExplicitWidth = 1071
              ExplicitHeight = 395
              inherited pnlRightRecibos: TPanel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited pnlBodyRecibos: TPanel
                StyleElements = [seFont, seClient, seBorder]
              end
            end
            inherited tsOtros: TcxTabSheet
              ExplicitLeft = 4
              ExplicitTop = 28
              ExplicitWidth = 1071
              ExplicitHeight = 395
              inherited cbbTipoOperVerifactu: TcxDBLookupComboBox
                ExplicitHeight = 25
              end
              inherited pnlUserInstantBottom: TPanel
                StyleElements = [seFont, seClient, seBorder]
                inherited txtUSUARIOALTA: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited txtINSTANTEALTA: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited txtINSTANTEMODIF: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited txtUSUARIOMODIF: TcxDBTextEdit
                  ExplicitHeight = 25
                end
              end
            end
            inherited tsVerifactu: TcxTabSheet
              ExplicitLeft = 4
              ExplicitTop = 28
              ExplicitWidth = 1071
              ExplicitHeight = 395
              inherited scrlbxVerifactu: TScrollBox
                VertScrollBar.Position = 0
                inherited lblPETICION_COMPLETA: TLabel
                  Top = 612
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblRESPUESTA_COMPLETA: TLabel
                  Top = 60
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblQRCODE_BASE64: TLabel
                  Top = 543
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblVERIFACTU_URL: TLabel
                  Top = 476
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblCHAIN_HASH: TLabel
                  Top = 410
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblCHAIN_NUMBER: TLabel
                  Top = 361
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblISSUED_TIME: TLabel
                  Top = 313
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblISSUER_IRS_ID: TLabel
                  Top = 264
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblQUEUE_ID: TLabel
                  Top = 216
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblREQUEST_ID: TLabel
                  Top = 167
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lbl: TLabel
                  Top = 20
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblFECHA_PROCESAMIENTO: TLabel
                  Top = 224
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblESTADO: TLabel
                  Top = 20
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited spQUEUE_ID: TcxDBSpinEdit
                  Top = 208
                  ExplicitTop = 208
                  ExplicitHeight = 25
                end
                inherited cxdbmRESPUESTA_COMPLETA: TcxDBMemo
                  Top = 56
                  ExplicitTop = 56
                end
                inherited cxdbmQRCODE_BASE64: TcxDBMemo
                  Top = 517
                  ExplicitTop = 517
                end
                inherited cxdbmVERIFACTU_URL: TcxDBMemo
                  Top = 450
                  ExplicitTop = 450
                end
                inherited txtCHAIN_HASH: TcxDBTextEdit
                  Top = 402
                  ExplicitTop = 402
                  ExplicitHeight = 25
                end
                inherited txtCHAIN_NUMBER: TcxDBTextEdit
                  Top = 353
                  ExplicitTop = 353
                  ExplicitHeight = 25
                end
                inherited dteISSUED_TIME: TcxDBDateEdit
                  Top = 305
                  ExplicitTop = 305
                  ExplicitHeight = 25
                end
                inherited txtISSUER_IRS_ID: TcxDBTextEdit
                  Top = 256
                  ExplicitTop = 256
                  ExplicitHeight = 25
                end
                inherited imgQRCODE_PNG: TcxDBImage
                  Top = 17
                  ExplicitTop = 17
                end
                inherited txtREQUEST_ID: TcxDBTextEdit
                  Top = 159
                  ExplicitTop = 159
                  ExplicitHeight = 25
                end
                inherited spID_CONSOLIDACION: TcxDBSpinEdit
                  Top = 14
                  ExplicitTop = 14
                  ExplicitHeight = 25
                end
                inherited cxdbmPETICION_COMPLETA_FACCON: TcxDBMemo
                  Top = 587
                  ExplicitTop = 587
                end
                inherited dteFECHA_PROCESAMIENTO: TcxDBDateEdit
                  Top = 216
                  ExplicitTop = 216
                  ExplicitHeight = 25
                end
                inherited txtESTADO: TcxDBTextEdit
                  Top = 14
                  ExplicitTop = 14
                  ExplicitHeight = 25
                end
                inherited btnVerifactuAnular: TcxButton
                  Top = 79
                  ExplicitTop = 79
                end
                inherited btnVerifactuFacturar: TcxButton
                  Top = 119
                  ExplicitTop = 119
                end
                inherited btnVolverBorrador: TcxButton
                  Top = 38
                  ExplicitTop = 38
                end
              end
            end
            inherited tsRegistro: TcxTabSheet
              ExplicitLeft = 4
              ExplicitTop = 28
              ExplicitWidth = 1071
              ExplicitHeight = 395
            end
            inherited tsMovimientosFac: TcxTabSheet
              ExplicitLeft = 4
              ExplicitTop = 28
              ExplicitWidth = 1071
              ExplicitHeight = 395
            end
          end
        end
        inherited pnlTopFicha: TPanel
          StyleElements = [seFont, seClient, seBorder]
          inherited pnlBodyFicha: TPanel
            StyleElements = [seFont, seClient, seBorder]
            inherited pcCab: TcxPageControl
              inherited tsCabecera: TcxTabSheet
                inherited dteFECHA_FACTURA: TcxDBDateEdit
                  ExplicitHeight = 25
                end
                inherited btnCODIGO_CLIENTE: TcxDBButtonEdit
                  ExplicitHeight = 25
                end
                inherited btnCODIGO_EMPRESA_FACTURA: TcxDBButtonEdit
                  ExplicitHeight = 25
                end
                inherited txtNRO_FACTURA: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited cbbSerieFactura: TcxDBLookupComboBox
                  ExplicitHeight = 25
                end
                inherited chkConsolidada: TcxDBCheckBox
                  ExplicitWidth = 190
                end
                inherited chkMueveStock: TcxDBCheckBox
                  ExplicitWidth = 340
                end
                inherited txtINSTANTECONSOLIDACION: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited txtTIPO_FAC: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited txtCODIGO_CAJERO_FAC: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited txtFASE_FAC: TcxDBTextEdit
                  ExplicitHeight = 25
                end
              end
              inherited tsEmpresa: TcxTabSheet
                ExplicitLeft = 4
                ExplicitTop = 28
                ExplicitWidth = 1071
                ExplicitHeight = 305
                inherited grpEmpresa: TcxGroupBox
                  inherited txtDIRECCION1_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtCPOSTAL_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtPROVINCIA_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtPAIS_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtDIRECCION2_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtRAZONSOCIAL_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtNIF_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtMOVIL_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtEMAIL_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxDBCheckBox
                    ExplicitHeight = 59
                  end
                  inherited chkRETENCION_EMPRESA_FACTURA: TcxDBCheckBox
                    ExplicitWidth = 306
                    ExplicitHeight = 25
                  end
                  inherited cbbCanalIVA: TcxDBLookupComboBox
                    ExplicitHeight = 25
                  end
                  inherited txtNOMBRE_PAIS_EMPRESA_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited cbbPaisesEmp: TcxDBLookupComboBox
                    ExplicitHeight = 25
                  end
                end
              end
              inherited tsDatosCliente: TcxTabSheet
                inherited grpCliente: TcxGroupBox
                  inherited txtDIRECCION1_CLIENTE_FACTURA1: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtCPOSTAL_CLIENTE_FACTURA1: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtPOBLACION_CLIENTE_FACTURA1: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtPROVINCIA_CLIENTE_FACTURA1: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtPAIS_CLIENTE_FACTURA1: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtDIRECCION2_CLIENTE_FACTURA1: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtRAZONSOCIAL_CLIENTE_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtNIF_CLIENTE_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtMOVIL_CLIENTE_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited txtEMAIL_CLIENTE_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited chkESIVA_RECARGO_CLIENTE_FACTURA: TcxDBCheckBox
                    ExplicitWidth = 258
                    ExplicitHeight = 25
                  end
                  inherited chkREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TcxDBCheckBox
                    ExplicitWidth = 291
                    ExplicitHeight = 25
                  end
                  inherited chkRETENCIONES_EMPRESA_FACTURA3: TcxDBCheckBox
                    ExplicitWidth = 228
                    ExplicitHeight = 25
                  end
                  inherited chkEXTRANJERO: TcxDBCheckBox
                    ExplicitWidth = 104
                    ExplicitHeight = 25
                  end
                  inherited cbbTARIFA_ARTICULOS_CLIENTES: TcxDBLookupComboBox
                    ExplicitHeight = 25
                  end
                  inherited chkIVA_EXENTO_CLIENTE_FACTURA: TcxDBCheckBox
                    ExplicitWidth = 198
                    ExplicitHeight = 25
                  end
                  inherited chkImpIncl: TcxDBCheckBox
                    ExplicitWidth = 301
                  end
                  inherited txtNOMBRE_PAIS_CLIENTE_FACTURA: TcxDBTextEdit
                    ExplicitHeight = 25
                  end
                  inherited cbbPaisesCli: TcxDBLookupComboBox
                    ExplicitHeight = 25
                  end
                end
              end
              object tsParametrosEDoc: TcxTabSheet
                Caption = 'Par'#225'metros eDoc -'
                ImageIndex = 3
                object cxgrpbxParametrosEDoc: TcxGroupBox
                  AlignWithMargins = True
                  Left = 21
                  Top = 0
                  TabStop = True
                  Caption = 'Centros administrativos DIR3'
                  TabOrder = 0
                  Height = 174
                  Width = 890
                  object lblCodigoOficinaContable: TcxLabel
                    Left = 39
                    Top = 32
                    Caption = 'Oficina contable'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 0
                    Transparent = True
                    AnchorX = 163
                  end
                  object txtCODIGO_OFICINA_CONTABLE_FACTURA: TcxDBTextEdit
                    Left = 170
                    Top = 28
                    DataBinding.DataField = 'CODIGO_OFICINA_CONTABLE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 1
                    Width = 160
                  end
                  object lblCodigoOrganoGestor: TcxLabel
                    Left = 56
                    Top = 72
                    Caption = 'Organo gestor'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 2
                    Transparent = True
                    AnchorX = 163
                  end
                  object txtCODIGO_ORGANO_GESTOR_FACTURA: TcxDBTextEdit
                    Left = 170
                    Top = 68
                    DataBinding.DataField = 'CODIGO_ORGANO_GESTOR_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 3
                    Width = 160
                  end
                  object lblCodigoUnidadTramitadora: TcxLabel
                    Left = 21
                    Top = 112
                    Caption = 'Unidad tramitadora'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 4
                    Transparent = True
                    AnchorX = 163
                  end
                  object txtCODIGO_UNIDAD_TRAMITADORA_FACTURA: TcxDBTextEdit
                    Left = 170
                    Top = 108
                    DataBinding.DataField = 'CODIGO_UNIDAD_TRAMITADORA_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 5
                    Width = 160
                  end
                  object lblNombrePersonaCliente: TcxLabel
                    Left = 350
                    Top = 32
                    Caption = 'Nombre persona f'#237'sica'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 6
                    Transparent = True
                    AnchorX = 543
                  end
                  object txtNOMBRE_PERSONA_CLIENTE_FACTURA: TcxDBTextEdit
                    Left = 550
                    Top = 28
                    DataBinding.DataField = 'NOMBRE_PERSONA_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 7
                    Width = 250
                  end
                  object lblApellidosPersonaCliente: TcxLabel
                    Left = 341
                    Top = 72
                    Caption = 'Apellidos persona f'#237'sica'
                    Properties.Alignment.Horz = taRightJustify
                    TabOrder = 8
                    Transparent = True
                    AnchorX = 543
                  end
                  object txtAPELLIDOS_PERSONA_CLIENTE_FACTURA: TcxDBTextEdit
                    Left = 550
                    Top = 68
                    DataBinding.DataField = 'APELLIDOS_PERSONA_CLIENTE_FAC'
                    DataBinding.DataSource = dsTablaG
                    TabOrder = 9
                    Width = 250
                  end
                end
              end
            end
          end
        end
        inherited splSplitterFicha: TcxSplitter
          ExplicitWidth = 1079
        end
      end
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited pnlPerfilDetail: TPanel
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
    inherited pnlTopPage: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnlTopGrid: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
  end
  inherited pButtonRightBar: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pButtonGen: TPanel
      StyleElements = [seFont, seClient, seBorder]
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
    object btnEmitirEDoc: TcxButton
      Left = 1
      Top = 397
      Width = 140
      Height = 34
      Caption = 'Emitir eDoc'
      TabOrder = 6
      OnClick = btnEmitirEDocClick
    end
  end
end
