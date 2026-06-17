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
                inherited lblPETICION_COMPLETA: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblRESPUESTA_COMPLETA: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblQRCODE_BASE64: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblVERIFACTU_URL: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblCHAIN_HASH: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblCHAIN_NUMBER: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblISSUED_TIME: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblISSUER_IRS_ID: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblQUEUE_ID: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblREQUEST_ID: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lbl: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblFECHA_PROCESAMIENTO: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited lblESTADO: TLabel
                  StyleElements = [seFont, seClient, seBorder]
                end
                inherited spQUEUE_ID: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited txtCHAIN_HASH: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited txtCHAIN_NUMBER: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited dteISSUED_TIME: TcxDBDateEdit
                  ExplicitHeight = 25
                end
                inherited txtISSUER_IRS_ID: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited txtREQUEST_ID: TcxDBTextEdit
                  ExplicitHeight = 25
                end
                inherited spID_CONSOLIDACION: TcxDBSpinEdit
                  ExplicitHeight = 25
                end
                inherited dteFECHA_PROCESAMIENTO: TcxDBDateEdit
                  ExplicitHeight = 25
                end
                inherited txtESTADO: TcxDBTextEdit
                  ExplicitHeight = 25
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
