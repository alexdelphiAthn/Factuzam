inherited frmMtoArticulosPropiedades: TfrmMtoArticulosPropiedades
  Caption = 'Propiedades de Art'#237'culos'
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
            object cxGrdDBTabPrinCODIGO_ART_ART: TcxGridDBColumn
              Caption = 'C'#243'digo Art'#237'culo'
              DataBinding.FieldName = 'CODIGO_ART_ART'
              Options.Editing = False
              Width = 160
            end
            object cxGrdDBTabPrinCODIGO_PROP_ARTPROP: TcxGridDBColumn
              Caption = 'Propiedad'
              DataBinding.FieldName = 'CODIGO_PROP_ARTPROP'
              Options.Editing = False
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.KeyFieldNames = 'CODIGO_PROP_ARTPROP'
              Properties.ListColumns = <
                item
                  FieldName = 'CODIGO_PROP_ARTPROP'
                  Caption.Text = 'C'#243'digo'
                  Width = 100
                end
                item
                  FieldName = 'NOMBRE_PROP_PROP'
                  Caption.Text = 'Nombre'
                  Width = 200
                end>
              Properties.ListSource = dmArticulosPropiedades.dsPropiedades
              Width = 180
            end
            object cxGrdDBTabPrinID_PV_ARTPROP: TcxGridDBColumn
              Caption = 'Valor (Lista)'
              DataBinding.FieldName = 'ID_PV_ARTPROP'
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.KeyFieldNames = 'ID_PV_ARTPROP'
              Properties.ListColumns = <
                item
                  FieldName = 'PV'
                  Caption.Text = 'Valor'
                  Width = 200
                end
                item
                  FieldName = 'ID_PROP_PV'
                  Caption.Text = 'Propiedad'
                  Width = 120
                end>
              Properties.ListSource = dmArticulosPropiedades.dsValores
              Width = 200
            end
            object cxGrdDBTabPrinVALOR_LIBRE_ARTPROP: TcxGridDBColumn
              Caption = 'Valor libre'
              DataBinding.FieldName = 'VALOR_LIBRE_ARTPROP'
              Width = 220
            end
            object cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn
              Caption = 'Instante de Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 160
            end
            object cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn
              Caption = 'Usuario de Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 140
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
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 240
          ExplicitWidth = 240
        end
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmArticulosPropiedades.unqryTablaG
    OnStateChange = dsTablaGStateChange
  end
end
