inherited frmMtoAtributosConjuntos: TfrmMtoAtributosConjuntos
  Caption = 'Colecciones de Atributos'
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
            object cxGrdDBTabPrinID_AC: TcxGridDBColumn
              Caption = 'ID Conjunto'
              DataBinding.FieldName = 'ID_AC'
              Options.Editing = False
              Width = 100
            end
            object cxGrdDBTabPrinNOMBRE_AC: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_AC'
              Width = 280
            end
            object cxGrdDBTabPrinID_VAR_AC: TcxGridDBColumn
              Caption = 'Variaci'#243'n'
              DataBinding.FieldName = 'ID_VAR_AC'
              Width = 130
            end
            object cxGrdDBTabPrinID_VA_AC: TcxGridDBColumn
              Caption = 'Atributo'
              DataBinding.FieldName = 'ID_VA_AC'
              Width = 130
            end
            object cxGrdDBTabPrinESACTIVO_AC: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_AC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
            object cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTE_MODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Options.Editing = False
              Visible = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 130
            end
            object cxGrdDBTabPrinUSUARIO_MODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIO_MODIF'
              Options.Editing = False
              Visible = False
              Width = 130
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
    DataSet = dmAtributosConjuntos.unqryTablaG
    OnStateChange = dsTablaGStateChange
  end
end
