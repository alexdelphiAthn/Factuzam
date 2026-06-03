inherited frmMtoFacturasNormal: TfrmMtoFacturasNormal
  Caption = 'Facturas (Venta Mayor)'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 17
  inherited pButtonPage: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited pcPantalla: TcxPageControl
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          Height = 775
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitTop = 29
        ExplicitHeight = 773
        inherited pnlVerifactu: TPanel
          StyleElements = [seFont, seClient, seBorder]
          ExplicitHeight = 426
          inherited pcDetail: TcxPageControl
            ExplicitHeight = 426
            inherited tsLineasFactura: TcxTabSheet
              inherited cxgrdLineasFactura: TcxGrid
                Height = 399
              end
              inherited pnlRightLineas: TPanel
                Height = 399
                StyleElements = [seFont, seClient, seBorder]
              end
            end
            inherited tsTotales: TcxTabSheet
              ExplicitTop = 27
              ExplicitHeight = 399
            end
            inherited tsRecibos: TcxTabSheet
              inherited pnlRightRecibos: TPanel
                Height = 399
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited pnlBodyRecibos: TPanel
                Height = 399
                StyleElements = [seFont, seClient, seBorder]
                inherited cxgrdRecibos: TcxGrid
                  Height = 399
                end
              end
            end
            inherited tsOtros: TcxTabSheet
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              inherited pnlUserInstantBottom: TPanel
                StyleElements = [seFont, seClient, seBorder]
                ExplicitTop = 320
              end
            end
            inherited tsVerifactu: TcxTabSheet
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              inherited scrlbxVerifactu: TScrollBox
                ExplicitHeight = 395
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
              end
            end
            inherited tsRegistro: TcxTabSheet
              inherited cxgrdLogVerifactu: TcxGrid
                Height = 399
              end
            end
            inherited tsMovimientosFac: TcxTabSheet
              inherited cxGrdMovimientosFac: TcxGrid
                Height = 399
              end
            end
          end
        end
        inherited pnlTopFicha: TPanel
          StyleElements = [seFont, seClient, seBorder]
          inherited pnlBodyFicha: TPanel
            StyleElements = [seFont, seClient, seBorder]
            inherited pcCab: TcxPageControl
              inherited tsCabecera: TcxTabSheet
                inherited chkMueveStock: TcxDBCheckBox
                  ExplicitWidth = 345
                end
              end
              inherited tsEmpresa: TcxTabSheet
                ExplicitLeft = 0
                ExplicitTop = 0
                ExplicitWidth = 0
                ExplicitHeight = 0
                inherited grpEmpresa: TcxGroupBox
                  inherited chkESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TcxDBCheckBox
                    ExplicitWidth = 262
                    ExplicitHeight = 55
                    Width = 262
                  end
                end
              end
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited pnlPerfilDetail: TPanel
          StyleElements = [seFont, seClient, seBorder]
          inherited cxgrdPerfil: TcxGrid
            Height = 718
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnlTopGrid: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 25
        end
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
  end
end
