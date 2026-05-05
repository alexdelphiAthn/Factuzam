inherited frmMtoPaises: TfrmMtoPaises
  Caption = 'Paises'
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
            OptionsData.Editing = True
            object dbcGrdDBTabPrinCOD_PAIS: TcxGridDBColumn
              Caption = 'C'#243'digo Pais'
              DataBinding.FieldName = 'COD_PAIS'
              Width = 109
            end
            object dbcGrdDBTabPrinCOD_PAIS_ALPHA3: TcxGridDBColumn
              Caption = 'C'#243'digo Alpha3'
              DataBinding.FieldName = 'COD_PAIS_ALPHA3'
              Width = 148
            end
            object dbcGrdDBTabPrinNOMBRE_SPA_PAIS: TcxGridDBColumn
              Caption = 'Nombre Espa'#241'ol Pais'
              DataBinding.FieldName = 'NOMBRE_SPA_PAIS'
              Width = 290
            end
            object dbcGrdDBTabPrinNOMBRE_ENG_PAIS: TcxGridDBColumn
              Caption = 'Nombre Ingl'#233's Pais'
              DataBinding.FieldName = 'NOMBRE_ENG_PAIS'
              Width = 294
            end
            object dbcGrdDBTabPrinORDEN_PAIS: TcxGridDBColumn
              Caption = 'Orden en Listados'
              DataBinding.FieldName = 'ORDEN_PAIS'
              HeaderAlignmentHorz = taRightJustify
              Width = 171
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
    DataSet = dmPaises.unqryTablaG
  end
end
