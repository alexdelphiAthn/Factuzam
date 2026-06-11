inherited frmMtoRemesasCompra: TfrmMtoRemesasCompra
  Caption = 'Remesas de Pago'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcGrdDBTabPrinNUMERO_REMC: TcxGridDBColumn
              Caption = 'Número'
              DataBinding.FieldName = 'NUMERO_REMC'
              Width = 90
            end
            object dbcGrdDBTabPrinSERIE_REMC: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_REMC'
              Width = 70
            end
            object dbcGrdDBTabPrinFECHA_REMC: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_REMC'
              Width = 100
            end
            object dbcGrdDBTabPrinESTADO_REMC: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_REMC'
              Width = 100
            end
            object dbcGrdDBTabPrinCODIGO_EMP_REMC: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_REMC'
              Width = 90
            end
            object dbcGrdDBTabPrinRAZON_SOCIAL_EMPRESA_VIEW_REMC: TcxGridDBColumn
              Caption = 'Razón Social'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_VIEW_REMC'
              Width = 220
            end
            object dbcGrdDBTabPrinCONTADOR_EFECTOS_REMC: TcxGridDBColumn
              Caption = 'Nº efectos'
              DataBinding.FieldName = 'CONTADOR_EFECTOS_REMC'
              Width = 90
            end
            object dbcGrdDBTabPrinTOTAL_REMC: TcxGridDBColumn
              Caption = 'Total'
              DataBinding.FieldName = 'TOTAL_REMC'
              Width = 120
            end
            object dbcGrdDBTabPrinFECHA_CARGO_REMC: TcxGridDBColumn
              Caption = 'F. cargo'
              DataBinding.FieldName = 'FECHA_CARGO_REMC'
              Width = 100
            end
            object dbcGrdDBTabPrinIBAN_REMC: TcxGridDBColumn
              Caption = 'IBAN'
              DataBinding.FieldName = 'IBAN_REMC'
              Width = 200
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited nvNavegador: TcxDBNavigator
          Width = 252
          ExplicitWidth = 252
        end
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmRemesasCompra.unqryTablaG
  end
end
